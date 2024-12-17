enum MemberStatus {
  online,
  idle,
  doNotDisturb,
  offline,
}

class Member {
  final String id;
  final String username;
  final String? avatarUrl;
  final MemberStatus status;
  final DateTime lastSeen;

  Member({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.status,
    required this.lastSeen,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      status: _parseStatus(json['status']),
      lastSeen: DateTime.parse(json['last_seen']),
    );
  }

  static MemberStatus _parseStatus(String? status) {
    switch (status) {
      case 'online':
        return MemberStatus.online;
      case 'idle':
        return MemberStatus.idle;
      case 'dnd':
        return MemberStatus.doNotDisturb;
      default:
        return MemberStatus.offline;
    }
  }

  bool get isOnline => status != MemberStatus.offline;
}
