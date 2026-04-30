import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecoveryTips {
  final String relaxationTitle;
  final String relaxationInstruction;
  final int relaxationMinutes;
  final bool isBreathingExercise;
  /// '4-7-8' | 'box' | null — only set when [isBreathingExercise] is true
  final String? breathingType;
  final String recoveryTip;
  final String motivation;

  const RecoveryTips({
    required this.relaxationTitle,
    required this.relaxationInstruction,
    required this.relaxationMinutes,
    required this.isBreathingExercise,
    this.breathingType,
    required this.recoveryTip,
    required this.motivation,
  });

  Map<String, dynamic> toMap() {
    return {
      'relaxationTitle': relaxationTitle,
      'relaxationInstruction': relaxationInstruction,
      'relaxationMinutes': relaxationMinutes,
      'isBreathingExercise': isBreathingExercise,
      'breathingType': breathingType,
      'recoveryTip': recoveryTip,
      'motivation': motivation,
    };
  }

  static RecoveryTips fromMap(Map<String, dynamic> map) {
    return RecoveryTips(
      relaxationTitle: map['relaxationTitle'] ?? 'Relaxation',
      relaxationInstruction: map['relaxationInstruction'] ?? 'Take a short breathing break.',
      relaxationMinutes: map['relaxationMinutes'] ?? 2,
      isBreathingExercise: map['isBreathingExercise'] == true,
      breathingType: map['breathingType'] as String?,
      recoveryTip: map['recoveryTip'] ?? 'Break the task into smaller steps and do one at a time.',
      motivation: map['motivation'] ?? 'You are making progress, even if it feels small.',
    );
  }
}

class GeminiTipsService {
  static const _historyKey = 'recovery_tips_history';
  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash'
  ];

  static final Map<String, Future<RecoveryTips>> _inflightByKey = {};

  final SupabaseClient _supabase = Supabase.instance.client;

  String _normalizeMoodKey(String? mood) {
    final t = mood?.trim().toLowerCase() ?? '';
    if (t.isEmpty) return 'calm';
    return t;
  }

  String _tipsInflightKey(
    String userId,
    String moodKey,
    String sleepHours,
    List<String> goals,
  ) {
    final g = List<String>.from(goals)..sort();
    return '$userId|$moodKey|$sleepHours|${g.join('\u0001')}';
  }

  Future<RecoveryTips> getTips({
    required String mood,
    required String sleepHours,
    required List<String> goals,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }

    final userId = user.id;
    final m = _normalizeMoodKey(mood);
    final sleep = sleepHours.trim();
    final goalsList = List<String>.from(goals);

    final prefs = await SharedPreferences.getInstance();
    final history = _loadHistory(prefs, userId);
    final today = _todayKey();

    if (history.isNotEmpty &&
        history.first['date'] == today &&
        _normalizeMoodKey(history.first['mood'] as String?) == m &&
        (history.first['sleepHours'] as String? ?? '') == sleep &&
        _goalsMatch(history.first['goals'] as List<dynamic>?, goalsList)) {
      return RecoveryTips.fromMap(history.first['tips'] as Map<String, dynamic>);
    }

    final inflightKey = _tipsInflightKey(userId, m, sleep, goalsList);
    return _inflightByKey.putIfAbsent(inflightKey, () {
      final future = _fetchTipsForMood(
        userId: userId,
        moodKey: m,
        sleepHours: sleep,
        goals: goalsList,
        prefs: prefs,
        history: history,
        today: today,
      );
      future.whenComplete(() => _inflightByKey.remove(inflightKey));
      return future;
    });
  }

  Future<RecoveryTips> _fetchTipsForMood({
    required String userId,
    required String moodKey,
    required String sleepHours,
    required List<String> goals,
    required SharedPreferences prefs,
    required List<Map<String, dynamic>> history,
    required String today,
  }) async {
    final recentSummaries = history.take(7).map((entry) {
      final tips = entry['tips'] as Map<String, dynamic>;
      return {
        'relaxationTitle': tips['relaxationTitle'],
        'relaxationInstruction': tips['relaxationInstruction'],
        'recoveryTip': tips['recoveryTip'],
        'motivation': tips['motivation'],
      };
    }).toList();

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('Missing GEMINI_API_KEY');
    }

    RecoveryTips? tips;
    String? lastCombined;
    Exception? lastError;

    for (final model in _models) {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          tips = await _generateTips(
            apiKey: apiKey,
            model: model,
            mood: moodKey,
            sleepHours: sleepHours,
            goals: goals,
            recentSummaries: recentSummaries,
            avoidExact: lastCombined,
          );
        } catch (error) {
          lastError = Exception('$error (model=$model)');
          tips = null;
        }

        if (tips == null) {
          break;
        }

        final combined = _combineTips(tips);
        if (combined != lastCombined) {
          break;
        }
        lastCombined = combined;
      }

      if (tips != null) {
        break;
      }
    }

    if (tips == null && lastError != null) {
      throw lastError;
    }

    final resolvedTips = tips ??
        RecoveryTips(
          relaxationTitle: 'Relaxation',
          relaxationInstruction: 'Take a short breathing break.',
          relaxationMinutes: 2,
          isBreathingExercise: true,
          recoveryTip: 'Break the task into smaller steps and do one at a time.',
          motivation: 'You are making progress, even if it feels small.',
        );

    final entry = {
      'date': today,
      'mood': moodKey,
      'sleepHours': sleepHours,
      'goals': goals,
      'tips': resolvedTips.toMap(),
    };
    final updated = [entry, ...history];
    await prefs.setString('${_historyKey}_$userId', jsonEncode(updated));

    return resolvedTips;
  }

  Future<RecoveryTips> _generateTips({
    required String apiKey,
    required String model,
    required String mood,
    required String sleepHours,
    required List<String> goals,
    required List<Map<String, dynamic>> recentSummaries,
    String? avoidExact,
    bool strictPrompt = false,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=$apiKey',
    );

    final prompt = _buildPrompt(
      mood,
      sleepHours,
      goals,
      recentSummaries,
      avoidExact,
      strictPrompt,
    );
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
          'maxOutputTokens': 450,
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

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts?.isNotEmpty == true ? parts!.first['text'] as String? : null;
    if (text == null) {
      throw Exception('Gemini returned empty text');
    }

    Map<String, dynamic> tipsMap;
    try {
      tipsMap = _parseJson(text);
    } catch (error) {
      if (!strictPrompt) {
        return _generateTips(
          apiKey: apiKey,
          model: model,
          mood: mood,
          sleepHours: sleepHours,
          goals: goals,
          recentSummaries: recentSummaries,
          avoidExact: avoidExact,
          strictPrompt: true,
        );
      }
      throw Exception('Invalid JSON response: ${_truncate(text)}');
    }

    final isBreathing = tipsMap['relaxation']?['isBreathing'] == true;
    final rawType = tipsMap['relaxation']?['breathingType'] as String?;
    final breathingType = isBreathing ? _normaliseBreathingType(rawType) : null;

    return RecoveryTips(
      relaxationTitle: tipsMap['relaxation']?['title'] ?? 'Relaxation',
      relaxationInstruction: tipsMap['relaxation']?['instruction'] ?? 'Take a short breathing break.',
      relaxationMinutes: tipsMap['relaxation']?['minutes'] ?? 2,
      isBreathingExercise: isBreathing,
      breathingType: breathingType,
      recoveryTip: tipsMap['recoveryTip'] ?? 'Break the task into smaller steps and do one at a time.',
      motivation: tipsMap['motivation'] ?? 'You are making progress, even if it feels small.',
    );
  }

  String _buildPrompt(
    String mood,
    String sleepHours,
    List<String> goals,
    List<Map<String, dynamic>> recentSummaries,
    String? avoidExact,
    bool strictPrompt,
  ) {
    final recentJson = jsonEncode(recentSummaries);
    final avoidText = avoidExact == null ? '' : 'Avoid repeating this exact set: $avoidExact.';
    final strictText = strictPrompt
        ? 'Return ONLY raw JSON. No prose, no markdown, no code fences, no extra keys.'
        : 'Return ONLY valid JSON.';
    final sleepLine = sleepHours.isEmpty
        ? 'Sleep hours: not logged today (give general recovery guidance).'
        : 'Sleep hours (as logged): $sleepHours.';
    final goalsLine = goals.isEmpty
        ? 'Goals today: none listed (keep advice generally useful for students).'
        : 'Goals today: ${goals.join(', ')}.';

    return '''You are generating short, student-friendly recovery tips for a wellness app.
Mood today: $mood.
$sleepLine
$goalsLine
Recent tips shown (do not repeat these): $recentJson.
$avoidText
$strictText Use this schema:
{
  "relaxation": {
    "title": "Relaxation",
    "instruction": "Try 2 min 4-7-8 breathing exercise",
    "minutes": 2,
    "isBreathing": true,
    "breathingType": "4-7-8"
  },
  "recoveryTip": "...",
  "motivation": "..."
}
Rules:
- Keep each text under 140 characters, be supportive and concise, vary wording from recent tips.
- Tie the recovery tip and motivation lightly to sleep and goals when provided; stay practical and non-medical.
- Set "isBreathing" to true ONLY when the relaxation tip is a breathing exercise, otherwise false.
- When "isBreathing" is true, set "breathingType" to exactly "4-7-8" (for anxiety/stress relief) or "box" (for focus/calm/tiredness). When "isBreathing" is false, omit "breathingType" or set it to null.
- Choose "4-7-8" for anxious/stressed moods and "box" for tired/sad/calm moods.''';
  }

  Map<String, dynamic> _parseJson(String text) {
    final trimmed = text.trim();
    try {
      return jsonDecode(trimmed) as Map<String, dynamic>;
    } catch (_) {
      final cleaned = _stripLeadingNoise(trimmed);
      final sanitized = _escapeNewlinesInStrings(cleaned);
      try {
        return jsonDecode(sanitized) as Map<String, dynamic>;
      } catch (_) {
        final fenced = _extractFencedJson(sanitized);
        if (fenced != null) {
          return jsonDecode(fenced) as Map<String, dynamic>;
        }
        final jsonText = _extractJson(sanitized);
        return jsonDecode(jsonText) as Map<String, dynamic>;
      }
    }
  }

  String _stripLeadingNoise(String text) {
    var cleaned = text.trimLeft();
    if (cleaned.startsWith('"json')) {
      cleaned = cleaned.substring(5).trimLeft();
    } else if (cleaned.startsWith('json')) {
      cleaned = cleaned.substring(4).trimLeft();
    }
    if (cleaned.startsWith('```')) {
      return cleaned;
    }
    return cleaned;
  }

  String _escapeNewlinesInStrings(String text) {
    final buffer = StringBuffer();
    bool inString = false;
    bool isEscaped = false;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (inString) {
        if (isEscaped) {
          isEscaped = false;
          buffer.write(char);
          continue;
        }
        if (char == '\\') {
          isEscaped = true;
          buffer.write(char);
          continue;
        }
        if (char == '"') {
          inString = false;
          buffer.write(char);
          continue;
        }
        if (char == '\n') {
          buffer.write('\\n');
          continue;
        }
        if (char == '\r') {
          continue;
        }
        buffer.write(char);
        continue;
      }

      if (char == '"') {
        inString = true;
      }
      buffer.write(char);
    }

    return buffer.toString();
  }

  String? _extractFencedJson(String text) {
    final fenceStart = text.indexOf('```');
    if (fenceStart == -1) return null;
    final fenceEnd = text.indexOf('```', fenceStart + 3);
    if (fenceEnd == -1) return null;
    final block = text.substring(fenceStart + 3, fenceEnd).trim();
    if (block.startsWith('json')) {
      return block.substring(4).trim();
    }
    if (block.startsWith('"json')) {
      return block.substring(5).trim();
    }
    return block;
  }

  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw Exception('Invalid JSON response');
    }
    return text.substring(start, end + 1);
  }

  String _truncate(String text, {int max = 300}) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}…';
  }

  List<Map<String, dynamic>> _loadHistory(SharedPreferences prefs, String userId) {
    final raw = prefs.getString('${_historyKey}_$userId');
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

  bool _goalsMatch(List<dynamic>? first, List<String> second) {
    if (first == null) return false;
    if (first.length != second.length) return false;
    final firstSet = first.map((g) => g.toString()).toSet();
    final secondSet = second.toSet();
    return firstSet.containsAll(secondSet) && secondSet.containsAll(firstSet);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Normalises Gemini's free-text breathingType to either '4-7-8' or 'box'.
  /// Falls back to null if the value is unrecognisable.
  String? _normaliseBreathingType(String? raw) {
    if (raw == null) return null;
    final lower = raw.toLowerCase().trim();
    if (lower.contains('4') || lower.contains('478') || lower.contains('4-7-8')) {
      return '4-7-8';
    }
    if (lower.contains('box')) {
      return 'box';
    }
    return null;
  }

  String _combineTips(RecoveryTips tips) {
    return '${tips.relaxationTitle}|${tips.relaxationInstruction}|${tips.recoveryTip}|${tips.motivation}';
  }
}
