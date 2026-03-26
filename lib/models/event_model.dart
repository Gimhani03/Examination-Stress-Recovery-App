class Event {
  final String? id;
  final String userId;
  final String title;
  final DateTime eventDate;
  final String time;
  final String? description;
  final String? location;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Event({
    this.id,
    required this.userId,
    required this.title,
    required this.eventDate,
    required this.time,
    this.description,
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  /// Create an Event from a Supabase database response
  factory Event.fromDatabase(Map<String, dynamic> data) {
    return Event(
      id: data['id'] as String?,
      userId: data['user_id'] as String,
      title: data['title'] as String,
      eventDate: DateTime.parse(data['event_date'] as String),
      time: data['time'] as String? ?? 'Any time',
      description: data['description'] as String?,
      location: data['location'] as String?,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
    );
  }

  /// Convert Event to a Supabase-compatible map
  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'event_date': _formatDate(eventDate),
      'time': time,
      'description': description,
      'location': location,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Create a copy of this Event with some fields replaced
  Event copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? eventDate,
    String? time,
    String? description,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      time: time ?? this.time,
      description: description ?? this.description,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title &&
          eventDate == other.eventDate &&
          time == other.time &&
          description == other.description &&
          location == other.location;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      title.hashCode ^
      eventDate.hashCode ^
      time.hashCode ^
      description.hashCode ^
      location.hashCode;

  @override
  String toString() {
    return 'Event(id: $id, title: $title, eventDate: $eventDate, time: $time)';
  }

  /// Format DateTime to date string (YYYY-MM-DD)
  static String _formatDate(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
