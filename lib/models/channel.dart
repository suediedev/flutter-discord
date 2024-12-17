enum ChannelType {
  text,
  voice,
}

class Channel {
  final String id;
  final String name;
  final String serverId;
  final ChannelType type;
  final int position;

  Channel({
    required this.id,
    required this.name,
    required this.serverId,
    required this.type,
    required this.position,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'],
      name: json['name'],
      serverId: json['server_id'],
      type: json['type'] == 'voice' ? ChannelType.voice : ChannelType.text,
      position: json['position'] ?? 0,
    );
  }
}
