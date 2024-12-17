class Server {
  final String id;
  final String name;
  final String? iconUrl;

  Server({
    required this.id,
    required this.name,
    this.iconUrl,
  });

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Server',
      iconUrl: json['icon_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_url': iconUrl,
    };
  }
}
