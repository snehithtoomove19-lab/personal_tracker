enum ChatRole { user, assistant }

class ChatMessage {
  String id;
  ChatRole role;
  String content;
  DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        role: ChatRole.values.firstWhere((e) => e.name == json['role'], orElse: () => ChatRole.user),
        content: json['content'] ?? '',
        timestamp: DateTime.parse(json['timestamp']),
      );
}
