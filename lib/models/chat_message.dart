class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
  });

  // Convert to map for Supabase/SharedPreferences storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_error': isError,
    };
  }

  // Create from map
  static ChatMessage fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id']?.toString() ?? '',
      role: map['role']?.toString() ?? 'user',
      content: map['content']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'].toString())
          : DateTime.now(),
      isError: map['is_error'] == true || map['isError'] == true,
    );
  }

  // Create copy with modifications
  ChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? timestamp,
    bool? isError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
    );
  }
}
