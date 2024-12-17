class Message {
  final String id;
  final String channelId;
  final String content;
  final String userId;
  final String? userDisplayName;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.channelId,
    required this.content,
    required this.userId,
    this.userDisplayName,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      content: json['content'] as String,
      userId: json['user_id'] as String,
      userDisplayName: json['user_display_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel_id': channelId,
      'content': content,
      'user_id': userId,
      'user_display_name': userDisplayName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? channelId,
    String? content,
    String? userId,
    String? userDisplayName,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
