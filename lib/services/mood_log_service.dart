import 'package:supabase_flutter/supabase_flutter.dart';

class MoodLogExistsException implements Exception {
  final String message;
  const MoodLogExistsException(this.message);
}

class MoodLogService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> logMood({
    required String mood,
    required String moodImage,
    required String sleepHours,
    required List<String> goals,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final existing = await getTodayMoodLog();
    if (existing != null) {
      throw const MoodLogExistsException('You already logged your mood today.');
    }

    await _supabase.from('mood_logs').insert({
      'user_id': user.id,
      'mood': mood,
      'mood_image': moodImage,
      'sleep_hours': sleepHours,
      'goals': goals,
      'log_date': _todayDateString(),
    });
  }

  Future<Map<String, dynamic>?> getTodayMoodLog() async {
    return getMoodLogForDate(DateTime.now());
  }

  /// Most recent mood log (any day), for reminder copy tied to the latest check-in.
  Future<Map<String, dynamic>?> getLatestMoodLog() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final response = await _supabase
        .from('mood_logs')
        .select()
        .eq('user_id', user.id)
        .order('log_date', ascending: false)
        .limit(1);

    if (response.isEmpty) {
      return null;
    }

    return _normalizeMoodLog(response.first);
  }

  Future<Map<String, dynamic>?> getMoodLogForDate(DateTime date) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final response = await _supabase
        .from('mood_logs')
        .select()
        .eq('user_id', user.id)
        .eq('log_date', _dateString(date))
        .order('created_at', ascending: false)
        .limit(1);

    if (response.isEmpty) {
      return null;
    }

    return _normalizeMoodLog(response.first);
  }

  Future<List<Map<String, dynamic>>> getMoodLogsForRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final response = await _supabase
        .from('mood_logs')
        .select()
        .eq('user_id', user.id)
        .gte('log_date', _dateString(start))
        .lt('log_date', _dateString(end))
        .order('log_date', ascending: true);

    return response.map(_normalizeMoodLog).toList();
  }

  Map<String, dynamic> _normalizeMoodLog(Map<String, dynamic> raw) {
    final goalsRaw = raw['goals'];
    final goals = goalsRaw is List
        ? goalsRaw.map((goal) => goal.toString()).toList()
        : <String>[];

    return {
      ...raw,
      'goals': goals,
    };
  }

  String _todayDateString() => _dateString(DateTime.now());

  String _dateString(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
