import 'package:supabase_flutter/supabase_flutter.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Add a new event to the database
  Future<Map<String, dynamic>> addEvent({
    required String title,
    required DateTime eventDate,
    required String time,
    String? description,
    String? location,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final response = await _supabase.from('events').insert({
      'user_id': user.id,
      'title': title,
      'event_date': _dateString(eventDate),
      'time': time,
      'description': description,
      'location': location,
      'created_at': DateTime.now().toIso8601String(),
    }).select();

    if (response.isEmpty) {
      throw Exception('Failed to add event');
    }

    return _normalizeEvent(response.first);
  }

  /// Get all events for a specific date
  Future<List<Map<String, dynamic>>> getEventsForDate(DateTime date) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final response = await _supabase
        .from('events')
        .select()
        .eq('user_id', user.id)
        .eq('event_date', _dateString(date))
        .order('time', ascending: true);

    return response.map((event) => _normalizeEvent(event)).toList();
  }

  /// Get all events for a date range
  Future<List<Map<String, dynamic>>> getEventsForRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final response = await _supabase
        .from('events')
        .select()
        .eq('user_id', user.id)
        .gte('event_date', _dateString(start))
        .lte('event_date', _dateString(end))
        .order('event_date', ascending: true)
        .order('time', ascending: true);

    return response.map((event) => _normalizeEvent(event)).toList();
  }

  /// Get a specific event by ID
  Future<Map<String, dynamic>?> getEventById(String eventId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final response = await _supabase
        .from('events')
        .select()
        .eq('id', eventId)
        .eq('user_id', user.id)
        .limit(1);

    if (response.isEmpty) {
      return null;
    }

    return _normalizeEvent(response.first);
  }

  /// Update an existing event
  Future<Map<String, dynamic>> updateEvent({
    required String eventId,
    required String title,
    required DateTime eventDate,
    required String time,
    String? description,
    String? location,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final response = await _supabase
        .from('events')
        .update({
          'title': title,
          'event_date': _dateString(eventDate),
          'time': time,
          'description': description,
          'location': location,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', eventId)
        .eq('user_id', user.id)
        .select();

    if (response.isEmpty) {
      throw Exception('Failed to update event');
    }

    return _normalizeEvent(response.first);
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    await _supabase
        .from('events')
        .delete()
        .eq('id', eventId)
        .eq('user_id', user.id);
  }

  /// Get all upcoming events for the current user
  Future<List<Map<String, dynamic>>> getUpcomingEvents({
    int limit = 10,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final today = _dateString(DateTime.now());
    final response = await _supabase
        .from('events')
        .select()
        .eq('user_id', user.id)
        .gte('event_date', today)
        .order('event_date', ascending: true)
        .order('time', ascending: true)
        .limit(limit);

    return response.map((event) => _normalizeEvent(event)).toList();
  }

  /// Normalize event data from database
  Map<String, dynamic> _normalizeEvent(Map<String, dynamic> raw) {
    return {
      ...raw,
      'title': raw['title'] ?? 'Event',
      'time': raw['time'] ?? 'Any time',
      'description': raw['description'] ?? '',
      'location': raw['location'] ?? '',
    };
  }

  /// Convert DateTime to date string format (YYYY-MM-DD)
  String _dateString(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
