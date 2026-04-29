import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'challenge_mood_key.dart';

class PersonalizedChallenge {
  final String title;
  final String icon; // emoji or icon name
  final bool isDone;

  const PersonalizedChallenge({
    required this.title,
    required this.icon,
    this.isDone = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'icon': icon,
      'isDone': isDone,
    };
  }

  static PersonalizedChallenge fromMap(Map<String, dynamic> map) {
    return PersonalizedChallenge(
      title: map['title'] ?? 'Complete a task',
      icon: map['icon'] ?? '📝',
      isDone: map['isDone'] ?? false,
    );
  }
}

class GeminiChallengesService {
  static const _historyKey = 'personalized_challenges_history';
  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash'
  ];

  static final Map<String, Future<List<PersonalizedChallenge>>> _challengesInflight = {};

  final SupabaseClient _supabase = Supabase.instance.client;

  String _challengesInflightKey(String userId, String moodKey, String sleepHours, List<String> goals) {
    final g = List<String>.from(goals)..sort();
    return '$userId|$moodKey|$sleepHours|${g.join('\u0001')}';
  }

  Future<List<PersonalizedChallenge>> getChallenges({
    required String mood,
    required String sleepHours,
    required List<String> goals,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }

    final userId = user.id;
    final moodKey = normalizeChallengeMoodKey(mood);
    final prefs = await SharedPreferences.getInstance();
    final history = _loadHistory(prefs, userId);
    final today = _todayKey();

    // Check if we already generated challenges for today with same inputs
    if (history.isNotEmpty &&
        history.first['date'] == today &&
        normalizeChallengeMoodKey(history.first['mood'] as String? ?? '') == moodKey &&
        history.first['sleepHours'] == sleepHours &&
        _goalsMatch(history.first['goals'] as List<dynamic>?, goals)) {
      return (history.first['challenges'] as List<dynamic>)
          .map((c) => PersonalizedChallenge.fromMap(c as Map<String, dynamic>))
          .toList();
    }

    final inflightKey = _challengesInflightKey(userId, moodKey, sleepHours, goals);
    return _challengesInflight.putIfAbsent(inflightKey, () {
      final future = _generateAndPersistChallenges(
        userId: userId,
        moodKey: moodKey,
        sleepHours: sleepHours,
        goals: goals,
        prefs: prefs,
        history: history,
        today: today,
      );
      future.whenComplete(() => _challengesInflight.remove(inflightKey));
      return future;
    });
  }

  Future<List<PersonalizedChallenge>> _generateAndPersistChallenges({
    required String userId,
    required String moodKey,
    required String sleepHours,
    required List<String> goals,
    required SharedPreferences prefs,
    required List<Map<String, dynamic>> history,
    required String today,
  }) async {
    // Fetch user's recent completed challenges to avoid repetition
    final recentChallenges = await _fetchRecentChallenges(userId);

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('Missing GEMINI_API_KEY');
    }

    List<PersonalizedChallenge>? challenges;
    String? lastCombined;
    Exception? lastError;

    for (final model in _models) {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          challenges = await _generateChallenges(
            apiKey: apiKey,
            model: model,
            mood: moodKey,
            sleepHours: sleepHours,
            goals: goals,
            recentChallenges: recentChallenges,
            avoidExact: lastCombined,
          );
        } catch (error) {
          lastError = Exception('$error (model=$model)');
          challenges = null;
        }

        if (challenges == null) {
          break;
        }

        final combined = _combineChallenges(challenges);
        if (combined != lastCombined) {
          break;
        }
        lastCombined = combined;
      }

      if (challenges != null) {
        break;
      }
    }

    if (challenges == null && lastError != null) {
      throw lastError;
    }

    final resolvedChallenges = challenges ??
        [
          const PersonalizedChallenge(
            title: 'Review 2 chapters for the exam',
            icon: '📚',
          ),
          const PersonalizedChallenge(
            title: 'Drink 2L water',
            icon: '💧',
          ),
          const PersonalizedChallenge(
            title: 'Take a 5 min break',
            icon: '☕',
          ),
          const PersonalizedChallenge(
            title: 'Go for a short walk',
            icon: '🚶',
          ),
        ];

    // Save to cache
    final entry = {
      'date': today,
      'mood': moodKey,
      'sleepHours': sleepHours,
      'goals': goals,
      'challenges': resolvedChallenges.map((c) => c.toMap()).toList(),
    };
    final updated = [entry, ...history];
    await prefs.setString('${_historyKey}_$userId', jsonEncode(updated));

    // Save challenges to Supabase for tracking
    await _saveChallengeHistory(userId, today, resolvedChallenges);

    return resolvedChallenges;
  }

  Future<List<String>> _fetchRecentChallenges(String userId) async {
    try {
      final response = await _supabase
          .from('user_challenges')
          .select('title')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List<dynamic>)
          .map((item) => item['title'] as String)
          .toList();
    } catch (error) {
      // Table might not exist yet, return empty list
      return [];
    }
  }

  Future<void> _saveChallengeHistory(
    String userId,
    String date,
    List<PersonalizedChallenge> challenges,
  ) async {
    try {
      for (final challenge in challenges) {
        await _supabase.from('user_challenges').insert({
          'user_id': userId,
          'title': challenge.title,
          'icon': challenge.icon,
          'challenge_date': date,
          'completed': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (error) {
      // Silently fail if table doesn't exist yet
    }
  }

  Future<List<PersonalizedChallenge>> getTodayChallengesWithStatus({
    required String mood,
    required String sleepHours,
    required List<String> goals,
  }) async {
    final challenges = await getChallenges(
      mood: mood,
      sleepHours: sleepHours,
      goals: goals,
    );

    // Load completion status from Supabase
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return challenges;
    }

    final today = _todayKey();
    try {
      final response = await _supabase
          .from('user_challenges')
          .select('title, completed')
          .eq('user_id', user.id)
          .eq('challenge_date', today);

      final completionMap = <String, bool>{};
      for (final item in response as List<dynamic>) {
        completionMap[item['title'] as String] = item['completed'] as bool? ?? false;
      }

      return challenges.map((challenge) {
        final isCompleted = completionMap[challenge.title] ?? false;
        return PersonalizedChallenge(
          title: challenge.title,
          icon: challenge.icon,
          isDone: isCompleted,
        );
      }).toList();
    } catch (error) {
      return challenges;
    }
  }

  Future<void> updateChallengeCompletion({
    required String title,
    required bool completed,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    final today = _todayKey();
    try {
      await _supabase
          .from('user_challenges')
          .update({'completed': completed, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', user.id)
          .eq('challenge_date', today)
          .eq('title', title);
    } catch (error) {
      // Silently fail if table doesn't exist yet
    }
  }

  Future<List<PersonalizedChallenge>> _generateChallenges({
    required String apiKey,
    required String model,
    required String mood,
    required String sleepHours,
    required List<String> goals,
    required List<String> recentChallenges,
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
      recentChallenges,
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
          'temperature': 1.2, // Increased for more variety
          'topP': 0.95,
          'maxOutputTokens': 600,
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

    Map<String, dynamic> responseMap;
    try {
      responseMap = _parseJson(text);
    } catch (error) {
      if (!strictPrompt) {
        return _generateChallenges(
          apiKey: apiKey,
          model: model,
          mood: mood,
          sleepHours: sleepHours,
          goals: goals,
          recentChallenges: recentChallenges,
          avoidExact: avoidExact,
          strictPrompt: true,
        );
      }
      throw Exception('Invalid JSON response: ${_truncate(text)}');
    }

    final challengesList = responseMap['challenges'] as List<dynamic>? ?? [];
    return challengesList
        .map((c) => PersonalizedChallenge.fromMap(c as Map<String, dynamic>))
        .toList();
  }

  String _buildPrompt(
    String mood,
    String sleepHours,
    List<String> goals,
    List<String> recentChallenges,
    String? avoidExact,
    bool strictPrompt,
  ) {
    final goalsString = goals.join(', ');
    final avoidChallengesText = recentChallenges.isEmpty
        ? ''
        : 'DO NOT suggest these challenges again (recently given): ${recentChallenges.join(", ")}. Generate completely different challenges.';
    final avoidText = avoidExact == null
        ? ''
        : 'Also avoid repeating this exact set: $avoidExact.';
    final strictText = strictPrompt
        ? 'Return ONLY raw JSON. No prose, no markdown, no code fences, no extra keys.'
        : 'Return ONLY valid JSON.';

    return '''You are generating UNIQUE and VARIED daily challenges for a student wellness app. 
Create 4 NEW, DIFFERENT challenges EVERY TIME you are called, even if the user's situation is the same.

User Profile:
- Current Mood: $mood
- Sleep Last Night: $sleepHours
- Today's Goals: $goalsString

IMPORTANT RULES FOR VARIETY:
$avoidChallengesText
$avoidText
- Generate COMPLETELY DIFFERENT challenge types each time
- Vary difficulty levels (easy, medium, challenging)
- Include mix of: academic, wellness, physical, social, creative, and self-care challenges
- Make challenges specific and actionable, not generic
- Each challenge should be unique and fresh

$strictText

Create 4 personalized challenges that:
1. Match their current mood and energy level
2. Support their listed goals
3. Consider their sleep status (adapt difficulty accordingly)
4. Are encouraging and realistic to complete in a day
5. Are DIFFERENT from previous suggestions

Use this JSON schema:
{
  "challenges": [
    {
      "title": "Specific, actionable challenge (under 50 chars)",
      "icon": "Single emoji that represents the challenge"
    },
    {
      "title": "...",
      "icon": "..."
    }
  ]
}

Rules:
- Each title must be under 50 characters
- Use only ONE emoji per challenge
- Emojis should be relevant and help visualize the challenge
- Vary challenge types: don't give similar challenges
- Make challenges specific to the goals and mood
- Every call should generate fresh, different challenges''';
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

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _combineChallenges(List<PersonalizedChallenge> challenges) {
    return challenges.map((c) => '${c.title}|${c.icon}').join('||');
  }

  bool _goalsMatch(List<dynamic>? first, List<String> second) {
    if (first == null) return false;
    if (first.length != second.length) return false;
    final firstSet = first.map((g) => g.toString()).toSet();
    final secondSet = second.toSet();
    return firstSet.containsAll(secondSet) && secondSet.containsAll(firstSet);
  }
}
