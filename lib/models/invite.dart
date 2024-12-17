class Invite {
  final String id;
  final String serverId;
  final String code;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int? maxUses;
  final int uses;

  Invite({
    required this.id,
    required this.serverId,
    required this.code,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
    this.maxUses,
    required this.uses,
  });

  factory Invite.fromJson(Map<String, dynamic> json) {
    return Invite(
      id: json['id'] as String,
      serverId: json['server_id'] as String,
      code: json['code'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      maxUses: json['max_uses'] as int?,
      uses: json['uses'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'server_id': serverId,
      'code': code,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'max_uses': maxUses,
      'uses': uses,
    };
  }

  bool get isValid {
    final now = DateTime.now();
    if (expiresAt != null && now.isAfter(expiresAt!)) {
      return false;
    }
    if (maxUses != null && uses >= maxUses!) {
      return false;
    }
    return true;
  }
}
