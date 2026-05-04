import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedMotivation {
  final String id;
  final String motivationText;
  final String? mood;
  final DateTime sourceDate;
  final DateTime createdAt;

  const SavedMotivation({
    required this.id,
    required this.motivationText,
    required this.mood,
    required this.sourceDate,
    required this.createdAt,
  });

  factory SavedMotivation.fromRow(Map<String, dynamic> row) {
    return SavedMotivation(
      id: row['id']?.toString() ?? '',
      motivationText: row['motivation_text'] as String? ?? '',
      mood: row['mood'] as String?,
      sourceDate: _parseDate(row['source_date']),
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    final s = value.toString();
    final parsed = DateTime.tryParse(s);
    if (parsed != null) return parsed;
    return DateTime.now();
  }
}

class SavedMotivationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Calendar date in the user's local timezone, `YYYY-MM-DD`.
  static String localDateString([DateTime? date]) {
    final d = date ?? DateTime.now();
    final local = DateTime(d.year, d.month, d.day);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  Future<bool> hasSavedExact({
    required String sourceDate,
    required String motivationText,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }
    final trimmed = motivationText.trim();
    if (trimmed.isEmpty) return false;

    final rows = await _supabase
        .from('saved_motivations')
        .select('id')
        .eq('user_id', user.id)
        .eq('source_date', sourceDate)
        .eq('motivation_text', trimmed)
        .limit(1);

    return rows.isNotEmpty;
  }

  Future<void> saveMotivation({
    required String motivationText,
    String? mood,
    String? sourceDate,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }
    final trimmed = motivationText.trim();
    if (trimmed.isEmpty) {
      throw Exception('Nothing to save');
    }

    final date = sourceDate ?? localDateString();
    if (await hasSavedExact(sourceDate: date, motivationText: trimmed)) {
      return;
    }

    await _supabase.from('saved_motivations').insert({
      'user_id': user.id,
      'motivation_text': trimmed,
      'mood': mood?.trim().isEmpty == true ? null : mood?.trim(),
      'source_date': date,
    });
  }

  Future<List<SavedMotivation>> listNewestFirst({int limit = 200}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final rows = await _supabase
        .from('saved_motivations')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List<dynamic>)
        .map((r) => SavedMotivation.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteById(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }
    await _supabase
        .from('saved_motivations')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }

  static String formatDisplayDate(DateTime date, {String? pattern}) {
    return DateFormat(pattern ?? 'EEE d MMM yyyy').format(date.toLocal());
  }
}
