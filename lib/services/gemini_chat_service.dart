import 'dart:convert';

import 'package:flutter_application_1/models/chat_message.dart';
import 'package:flutter_application_1/models/chat_thread_summary.dart';
import 'package:flutter_application_1/services/mood_log_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Local id for messages stored before `conversation_id` existed (column null in DB).
const String kLegacyChatConversationId = '__legacy__';

List<Map<String, dynamic>> _mapChatRows(List<dynamic> rows) {
  return rows
      .map((item) => {
            'id': item['id']?.toString() ?? '',
            'role': item['role']?.toString() ?? 'user',
            'content': item['content']?.toString() ?? '',
            'timestamp': item['created_at']?.toString() ??
                DateTime.now().toIso8601String(),
          })
      .toList();
}

class GeminiChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const _cacheKey = 'chat_messages_cache';
  static const _prefsActiveConversationKey = 'chat_active_conversation_id_v2';
  static const _maxCachedMessages = 20;
  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash'
  ];

  static const _uuid = Uuid();

  DateTime _lastMessageTime = DateTime.now();
  static const _messageCooldownMs = 1000;

  String _cacheStorageKey(String userId, String conversationId) =>
      '${_cacheKey}_${userId}_$conversationId';

  /// Picks saved active thread, or the most recent thread, or a new empty thread.
  Future<String> ensureInitialConversationId() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _supabase.auth.currentUser;

    List<ChatThreadSummary> threads = [];
    try {
      threads = await listChatThreads();
    } catch (_) {
      threads = [];
    }

    final saved = prefs.getString(_prefsActiveConversationKey);
    if (saved != null && saved.isNotEmpty) {
      final hasSavedThread = threads.any((t) => t.id == saved);
      if (hasSavedThread) {
        return saved;
      }
      try {
        final peek = await getChatHistory(conversationId: saved, limit: 1);
        if (peek.isNotEmpty) {
          return saved;
        }
      } catch (_) {}
    }

    try {
      if (threads.isNotEmpty) {
        final id = threads.first.id;
        await prefs.setString(_prefsActiveConversationKey, id);
        return id;
      }
      if (user != null) {
        final legacyPeek = await _supabase
            .from('chat_messages')
            .select('id')
            .eq('user_id', user.id)
            .isFilter('conversation_id', null)
            .limit(1);
        if (legacyPeek.isNotEmpty) {
          await prefs.setString(
              _prefsActiveConversationKey, kLegacyChatConversationId);
          return kLegacyChatConversationId;
        }
      }
    } catch (_) {
      // Table/column mismatch — fall through to new id.
    }

    final id = _uuid.v4();
    await prefs.setString(_prefsActiveConversationKey, id);
    return id;
  }

  /// Start a fresh conversation (previous threads stay saved).
  Future<String> startNewConversation() async {
    final id = _uuid.v4();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsActiveConversationKey, id);
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await prefs.remove(_cacheStorageKey(user.id, id));
    }
    return id;
  }

  Future<void> setActiveConversationId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsActiveConversationKey, id);
  }

  /// Recent threads (newest activity first). Merges rows with null `conversation_id` as [kLegacyChatConversationId].
  Future<List<ChatThreadSummary>> listChatThreads() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    try {
      final response = await _supabase
          .from('chat_messages')
          .select('conversation_id, created_at, content')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(500);

      final seen = <String>{};
      final threads = <ChatThreadSummary>[];

      for (final row in response) {
        final rawCid = row['conversation_id'] as String?;
        final cid = (rawCid == null || rawCid.isEmpty)
            ? kLegacyChatConversationId
            : rawCid;
        if (seen.contains(cid)) continue;
        seen.add(cid);

        final content = row['content'] as String? ?? '';
        final preview = content.length > 48 ? '${content.substring(0, 48)}…' : content;

        threads.add(
          ChatThreadSummary(
            id: cid,
            preview: preview.isEmpty ? 'Chat' : preview,
            updatedAt: DateTime.parse(row['created_at'] as String),
          ),
        );
      }
      return threads;
    } catch (_) {
      return [];
    }
  }

  /// Send a message to Gemini and get a response (persists under [conversationId]).
  Future<String> sendMessage({
    required String userMessage,
    required String conversationId,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    final now = DateTime.now();
    final timeSinceLastMessage = now.difference(_lastMessageTime).inMilliseconds;
    if (timeSinceLastMessage < _messageCooldownMs) {
      await Future.delayed(
          Duration(milliseconds: _messageCooldownMs - timeSinceLastMessage));
    }
    _lastMessageTime = DateTime.now();

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('Missing GEMINI_API_KEY');
    }

    final history =
        conversationHistory ?? await _getRecentHistory(conversationId);
    final userContext = await _getUserContext();

    String? response;
    Exception? lastError;

    for (final model in _models) {
      try {
        response = await _generateResponse(
          apiKey: apiKey,
          model: model,
          userMessage: userMessage,
          conversationHistory: history,
          userContext: userContext,
        );
        if (response != null) break;
      } catch (error) {
        lastError = Exception('$error (model=$model)');
      }
    }

    if (response == null && lastError != null) {
      throw lastError;
    }

    final finalResponse =
        response ?? "I'm having trouble responding right now. Please try again.";

    await saveChatMessage(
        role: 'user', content: userMessage, conversationId: conversationId);
    await saveChatMessage(
        role: 'assistant',
        content: finalResponse,
        conversationId: conversationId);

    return finalResponse;
  }

  Future<String?> _generateResponse({
    required String apiKey,
    required String model,
    required String userMessage,
    required List<Map<String, dynamic>> conversationHistory,
    required String userContext,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=$apiKey',
    );

    final prompt = _buildChatPrompt(userMessage, conversationHistory, userContext);

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.9,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini error: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini returned no candidates');
    }

    final candidate = candidates.first as Map<String, dynamic>;
    final finishReason = candidate['finishReason'] as String?;

    if (finishReason == 'MAX_TOKENS') {
      throw Exception('Response was cut off due to token limit');
    } else if (finishReason == 'SAFETY') {
      throw Exception('Response blocked by safety filters');
    }

    final content = candidate['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts?.isNotEmpty == true ? parts!.first['text'] as String? : null;
    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini returned empty text');
    }

    return _cleanupMarkdown(text.trim());
  }

  String _cleanupMarkdown(String text) {
    var cleaned = text;
    cleaned = cleaned.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'\1');
    cleaned = cleaned.replaceAll(RegExp(r'__([^_]+)__'), r'\1');
    cleaned = cleaned.replaceAll(RegExp(r'\*([^*]+)\*'), r'\1');
    cleaned = cleaned.replaceAll(RegExp(r'_([^_]+)_'), r'\1');
    cleaned = cleaned.replaceAll(RegExp(r'`([^`]+)`'), r'\1');
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    return cleaned;
  }

  String _buildChatPrompt(
    String userMessage,
    List<Map<String, dynamic>> conversationHistory,
    String userContext,
  ) {
    final historyText = conversationHistory.take(10).map((msg) {
      final role = msg['role'] == 'user' ? 'User' : 'Assistant';
      final content = msg['content'];
      return '$role: $content';
    }).join('\n');

    return '''You are a friendly AI companion helping students manage exam stress.

FORMATTING RULES (CRITICAL - FOLLOW EXACTLY):
- Use emojis to make responses engaging (💡 ✨ 🎯 📚 💪 🌟 etc.)
- Write in short, clear paragraphs (2-3 sentences max)
- Add blank lines between paragraphs for readability
- Use simple bullet points with • or emojis (NOT ** or __ for bold)
- Be conversational and warm, like talking to a friend
- Keep total response under 150 words
- DO NOT use markdown symbols like ** or __ - just write naturally

TONE:
- Encouraging and supportive
- Practical and actionable
- Understanding and empathetic

$userContext

${historyText.isNotEmpty ? 'Conversation History:\n$historyText\n' : ''}
User: $userMessage
Assistant:''';
  }

  Future<String> _getUserContext() async {
    try {
      final moodLog = await MoodLogService().getTodayMoodLog();
      if (moodLog != null) {
        final mood = moodLog['mood'] ?? 'unknown';
        final sleepHours = moodLog['sleep_hours'] ?? 'unknown';
        final goals = moodLog['goals'] as List<dynamic>?;
        final goalsText = goals != null && goals.isNotEmpty
            ? goals.join(', ')
            : 'none specified';

        return 'User context: Today\'s mood is $mood, slept $sleepHours hours, goals: $goalsText.';
      }
    } catch (_) {}
    return '';
  }

  Future<List<Map<String, dynamic>>> _getRecentHistory(String conversationId) async {
    final history = await getChatHistory(conversationId: conversationId, limit: 10);
    return history.reversed.toList();
  }

  Future<List<Map<String, dynamic>>> getChatHistory({
    required String conversationId,
    int limit = 50,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    const columns = 'id, role, content, created_at, conversation_id';

    try {
      var query = _supabase
          .from('chat_messages')
          .select(columns)
          .eq('user_id', user.id);

      if (conversationId == kLegacyChatConversationId) {
        query = query.isFilter('conversation_id', null);
      } else {
        query = query.eq('conversation_id', conversationId);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      final mapped = _mapChatRows(response);
      if (mapped.isNotEmpty) {
        return mapped;
      }
    } catch (_) {
      // Fall through to client-side filter fallback.
    }

    // Fallback: same fetch path as listChatThreads, filter client-side.
    try {
      final response = await _supabase
          .from('chat_messages')
          .select(columns)
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(500);

      final filtered = <Map<String, dynamic>>[];
      for (final item in response) {
        final rawCid = item['conversation_id'] as String?;
        final cid = (rawCid == null || rawCid.isEmpty)
            ? kLegacyChatConversationId
            : rawCid;
        if (cid != conversationId) continue;
        filtered.add({
          'id': item['id']?.toString() ?? '',
          'role': item['role']?.toString() ?? 'user',
          'content': item['content']?.toString() ?? '',
          'timestamp': item['created_at']?.toString() ??
              DateTime.now().toIso8601String(),
        });
        if (filtered.length >= limit) break;
      }
      if (filtered.isNotEmpty) {
        return filtered;
      }
    } catch (_) {
      // Fall through to local cache.
    }

    return _loadFromCache(user.id, conversationId);
  }

  Future<void> saveChatMessage({
    required String role,
    required String content,
    required String conversationId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: role,
      content: content,
      timestamp: DateTime.now(),
    );

    final row = <String, dynamic>{
      'user_id': user.id,
      'role': role,
      'content': content,
      'created_at': message.timestamp.toIso8601String(),
    };
    if (conversationId != kLegacyChatConversationId) {
      row['conversation_id'] = conversationId;
    }

    try {
      await _supabase.from('chat_messages').insert(row);
    } catch (_) {
      try {
        await _supabase.from('chat_messages').insert({
          'user_id': user.id,
          'role': role,
          'content': content,
          'created_at': message.timestamp.toIso8601String(),
        });
      } catch (_) {}
    }

    await _saveToCache(user.id, conversationId, message);
  }

  /// Deletes every message in this conversation only.
  Future<void> clearChatHistory(String conversationId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    try {
      dynamic q = _supabase.from('chat_messages').delete().eq('user_id', user.id);
      if (conversationId == kLegacyChatConversationId) {
        q = q.isFilter('conversation_id', null);
      } else {
        q = q.eq('conversation_id', conversationId);
      }
      await q;
    } catch (_) {
      // Avoid deleting unrelated threads if the filtered delete fails.
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheStorageKey(user.id, conversationId));
  }

  Future<List<Map<String, dynamic>>> _loadFromCache(
      String userId, String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheStorageKey(userId, conversationId));
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveToCache(
    String userId,
    String conversationId,
    ChatMessage message,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = await _loadFromCache(userId, conversationId);
    final updated = [message.toMap(), ...cached];
    final trimmed = updated.take(_maxCachedMessages).toList();
    await prefs.setString(
        _cacheStorageKey(userId, conversationId), jsonEncode(trimmed));
  }
}
