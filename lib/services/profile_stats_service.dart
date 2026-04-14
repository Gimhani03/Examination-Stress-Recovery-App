import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileStats {
  final int moodLogsCount;
  final int totalFocusSeconds;
  final int goalsCount;

  const ProfileStats({
    required this.moodLogsCount,
    required this.totalFocusSeconds,
    required this.goalsCount,
  });
}

class ProfileStatsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<ProfileStats> getStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final moodLogs = await _supabase
        .from('mood_logs')
        .select('id, goals')
        .eq('user_id', user.id);

    final focusSessions = await _supabase
        .from('focus_sessions')
        .select('duration_seconds')
        .eq('user_id', user.id);

    final moodLogsCount = moodLogs.length;
    final goalsCount = _countGoals(moodLogs);
    final totalFocusSeconds = _sumFocusSeconds(focusSessions);

    return ProfileStats(
      moodLogsCount: moodLogsCount,
      totalFocusSeconds: totalFocusSeconds,
      goalsCount: goalsCount,
    );
  }

  int _countGoals(List<dynamic> moodLogs) {
    var total = 0;
    for (final log in moodLogs) {
      if (log is Map<String, dynamic>) {
        final goals = log['goals'];
        if (goals is List) {
          total += goals.length;
        }
      }
    }
    return total;
  }

  int _sumFocusSeconds(List<dynamic> sessions) {
    var total = 0;
    for (final session in sessions) {
      if (session is Map<String, dynamic>) {
        total += _asInt(session['duration_seconds']);
      }
    }
    return total;
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
