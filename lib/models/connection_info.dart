class ConnectionInfo {
  final String id;
  final String name;
  final String serverUrl;
  final String databaseName;
  final String username;
  final String password;
  final int port;

  ConnectionInfo({
    required this.id,
    required this.name,
    required this.serverUrl,
    required this.databaseName,
    required this.username,
    required this.password,
    required this.port,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'serverUrl': serverUrl,
      'databaseName': databaseName,
      'username': username,
      'password': password,
      'port': port,
    };
  }

  factory ConnectionInfo.fromJson(Map<String, dynamic> json) {
    return ConnectionInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      serverUrl: json['serverUrl'] as String,
      databaseName: json['databaseName'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      port: json['port'] as int,
    );
  }

  ConnectionInfo copyWith({
    String? id,
    String? name,
    String? serverUrl,
    String? databaseName,
    String? username,
    String? password,
    int? port,
  }) {
    return ConnectionInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      serverUrl: serverUrl ?? this.serverUrl,
      databaseName: databaseName ?? this.databaseName,
      username: username ?? this.username,
      password: password ?? this.password,
      port: port ?? this.port,
    );
  }
}

