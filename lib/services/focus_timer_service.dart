import 'package:supabase_flutter/supabase_flutter.dart';

class FocusTimerSummary {
  final int sessionCount;
  final int totalSeconds;

  const FocusTimerSummary({
    required this.sessionCount,
    required this.totalSeconds,
  });
}

class FocusTimerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> logSession({
    required int durationSeconds,
    int? targetSeconds,
    DateTime? completedAt,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final completion = completedAt ?? DateTime.now();
    await _supabase.from('focus_sessions').insert({
      'user_id': user.id,
      'duration_seconds': durationSeconds,
      'target_seconds': targetSeconds ?? durationSeconds,
      'session_date': _dateString(completion),
      'completed_at': completion.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSessionsForDate(DateTime date) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final response = await _supabase
        .from('focus_sessions')
        .select()
        .eq('user_id', user.id)
        .eq('session_date', _dateString(date))
        .order('completed_at', ascending: true);

    return response.map(_normalizeSession).toList();
  }

  Future<List<Map<String, dynamic>>> getSessionsForRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final response = await _supabase
        .from('focus_sessions')
        .select()
        .eq('user_id', user.id)
        .gte('session_date', _dateString(start))
        .lt('session_date', _dateString(end))
        .order('session_date', ascending: true)
        .order('completed_at', ascending: true);

    return response.map(_normalizeSession).toList();
  }

  Future<FocusTimerSummary> getSummaryForDate(DateTime date) async {
    final sessions = await getSessionsForDate(date);
    final totalSeconds = sessions.fold<int>(
      0,
      (sum, session) => sum + _asInt(session['duration_seconds']),
    );
    return FocusTimerSummary(
      sessionCount: sessions.length,
      totalSeconds: totalSeconds,
    );
  }

  Map<String, dynamic> _normalizeSession(Map<String, dynamic> raw) {
    return {
      ...raw,
      'duration_seconds': _asInt(raw['duration_seconds']),
      'target_seconds': _asInt(raw['target_seconds']),
    };
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _dateString(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
