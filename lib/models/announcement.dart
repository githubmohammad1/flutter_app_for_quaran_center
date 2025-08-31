class Announcement {
  final int? id;
  final String content;
  final DateTime createdAt;
  final DateTime date;

  Announcement({
    this.id,
    required this.content,
    required this.createdAt,
    required this.date,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'date': date.toIso8601String(),
    };
  }
}
