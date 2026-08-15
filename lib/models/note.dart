class AppNote {
  String id;
  String title;
  String content;
  bool pinned;
  DateTime createdAt;
  DateTime updatedAt;

  AppNote({
    required this.id,
    required this.title,
    required this.content,
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'pinned': pinned,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AppNote.fromJson(Map<String, dynamic> json) => AppNote(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        pinned: json['pinned'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}
