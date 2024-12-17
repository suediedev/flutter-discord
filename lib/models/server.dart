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
      id: json['id'],
      name: json['name'],
      iconUrl: json['icon_url'],
    );
  }
}
