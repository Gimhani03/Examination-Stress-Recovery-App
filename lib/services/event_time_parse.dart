import 'package:intl/intl.dart';

/// Interprets DB `event_date` (YYYY-MM-DD or ISO) as a **local calendar day** (avoids UTC-offset surprises).
DateTime? parseEventDateLocal(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) {
    return null;
  }
  final head = dateStr.trim().split('T').first;
  final p = head.split('-');
  if (p.length == 3) {
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y != null && m != null && d != null) {
      return DateTime(y, m, d);
    }
  }
  final parsed = DateTime.tryParse(dateStr.trim());
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Best-effort parse of calendar "Time" text (e.g. [1:00 PM], [14:30], [9:00]) into local [DateTime] on [eventDate].
DateTime? parseEventTimeToLocalDateTime(String time, DateTime eventDate) {
  final t = time.trim();
  if (t.isEmpty || t.toLowerCase() == 'any time') {
    return null;
  }
  // Normalize unicode dashes to hyphen for "9:00 AM — leave empty"
  final normalized = t.split(RegExp(r'[\u2014\-\u2013]')).first.trim();
  if (normalized.isEmpty) {
    return null;
  }
  // Plain 24h "9:00" / "14:30" (common when users skip AM/PM)
  final hm24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(normalized);
  if (hm24 != null) {
    final h = int.tryParse(hm24.group(1)!);
    final min = int.tryParse(hm24.group(2)!);
    if (h != null && min != null && h >= 0 && h < 24 && min >= 0 && min < 60) {
      return DateTime(eventDate.year, eventDate.month, eventDate.day, h, min);
    }
  }
  for (final pattern in ['h:mm a', 'hh:mm a', 'H:mm', 'HH:mm']) {
    try {
      final parsed = DateFormat(pattern, 'en_US').parse(normalized);
      return DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        parsed.hour,
        parsed.minute,
      );
    } catch (_) {
      // try next
    }
  }
  return null;
}

String friendlyMoodLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return 'your last';
  }
  final s = raw.trim().toLowerCase();
  if (s.length == 1) {
    return s.toUpperCase();
  }
  return s[0].toUpperCase() + s.substring(1);
}
