import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _eventService = EventService();

  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _selectedDate;

  // Getters
  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get selectedDate => _selectedDate;

  /// Get events for a specific date
  Future<List<Event>> getEventsForDate(DateTime date) async {
    _setLoading(true);
    _clearError();

    try {
      final eventMaps = await _eventService.getEventsForDate(date);
      _events = eventMaps.map((map) => Event.fromDatabase(map)).toList();
      _selectedDate = date;
      notifyListeners();
      return _events;
    } catch (e) {
      _setError('Failed to load events: ${e.toString()}');
      _events = [];
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get events for a date range (e.g., a month)
  Future<Map<DateTime, List<Event>>> getEventsForMonth(DateTime month) async {
    _setLoading(true);
    _clearError();

    try {
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);

      final eventMaps = await _eventService.getEventsForRange(
        start: firstDay,
        end: lastDay,
      );

      final eventsByDate = <DateTime, List<Event>>{};
      for (final map in eventMaps) {
        final event = Event.fromDatabase(map);
        final dateKey = DateTime(
          event.eventDate.year,
          event.eventDate.month,
          event.eventDate.day,
        );
        eventsByDate.putIfAbsent(dateKey, () => []);
        eventsByDate[dateKey]!.add(event);
      }

      _events = eventMaps.map((map) => Event.fromDatabase(map)).toList();
      notifyListeners();
      return eventsByDate;
    } catch (e) {
      _setError('Failed to load events: ${e.toString()}');
      return {};
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new event
  Future<bool> addEvent({
    required String title,
    required DateTime eventDate,
    required String time,
    String? description,
    String? location,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final newEvent = await _eventService.addEvent(
        title: title,
        eventDate: eventDate,
        time: time,
        description: description,
        location: location,
      );

      _events.add(Event.fromDatabase(newEvent));
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add event: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing event
  Future<bool> updateEvent({
    required String eventId,
    required String title,
    required DateTime eventDate,
    required String time,
    String? description,
    String? location,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedEvent = await _eventService.updateEvent(
        eventId: eventId,
        title: title,
        eventDate: eventDate,
        time: time,
        description: description,
        location: location,
      );

      final index = _events.indexWhere((e) => e.id == eventId);
      if (index >= 0) {
        _events[index] = Event.fromDatabase(updatedEvent);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update event: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete an event
  Future<bool> deleteEvent(String eventId) async {
    _setLoading(true);
    _clearError();

    try {
      await _eventService.deleteEvent(eventId);
      _events.removeWhere((e) => e.id == eventId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete event: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get upcoming events
  Future<List<Event>> getUpcomingEvents({int limit = 10}) async {
    _setLoading(true);
    _clearError();

    try {
      final eventMaps = await _eventService.getUpcomingEvents(limit: limit);
      final upcomingEvents = eventMaps.map((map) => Event.fromDatabase(map)).toList();
      notifyListeners();
      return upcomingEvents;
    } catch (e) {
      _setError('Failed to load upcoming events: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Filter events by date
  List<Event> getEventsByDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return _events
        .where((e) => DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day) == dateKey)
        .toList();
  }

  /// Helper method to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Helper method to set error message
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  /// Helper method to clear error message
  void _clearError() {
    _error = null;
  }

  /// Clear all events
  void clearEvents() {
    _events = [];
    _selectedDate = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
