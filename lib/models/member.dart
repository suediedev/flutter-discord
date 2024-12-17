enum MemberStatus {
  online,
  idle,
  doNotDisturb,
  offline,
}

class Member {
  final String id;
  final String userId;
  final String serverId;
  final String? username;
  final String? avatarUrl;
  final MemberStatus status;
  final DateTime lastSeen;
  final String role;

  Member({
    required this.id,
    required this.userId,
    required this.serverId,
    this.username,
    this.avatarUrl,
    required this.status,
    required this.lastSeen,
    required this.role,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      serverId: json['server_id'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      status: _parseStatus(json['status'] as String?),
      lastSeen: DateTime.parse(json['last_seen'] ?? DateTime.now().toIso8601String()),
      role: json['role'] as String? ?? 'member',
    );
  }

  static MemberStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'online':
        return MemberStatus.online;
      case 'idle':
        return MemberStatus.idle;
      case 'donotdisturb':
      case 'dnd':
        return MemberStatus.doNotDisturb;
      default:
        return MemberStatus.offline;
    }
  }

  bool get isOnline => status != MemberStatus.offline;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'server_id': serverId,
      'username': username,
      'avatar_url': avatarUrl,
      'status': status.toString().split('.').last.toLowerCase(),
      'last_seen': lastSeen.toIso8601String(),
      'role': role,
    };
  }
}
