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
      id: json['id']?.toString() ?? '',
      channelId: json['channel_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userDisplayName: json['user_display_name']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
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
