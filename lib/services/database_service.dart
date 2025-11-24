import 'dart:convert';
import 'package:http/http.dart' as http;

class DatabaseConnectionRequest {
  final String databaseName;
  final String username;
  final String password;
  final int port;

  DatabaseConnectionRequest({
    required this.databaseName,
    required this.username,
    required this.password,
    required this.port,
  });

  Map<String, dynamic> toJson() {
    return {
      'databaseName': databaseName,
      'username': username,
      'password': password,
      'port': port,
    };
  }
}

class DatabaseService {
  final String serverUrl;

  DatabaseService({required this.serverUrl});

  Future<bool> connectToDatabase(DatabaseConnectionRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/api/connect'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to connect: ${e.toString()}');
    }
  }

  /// resumen_del_dia 데이터 가져오기
  Future<Map<String, dynamic>> getResumenDelDia() async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/api/resumen_del_dia'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map) {
          return decoded as Map<String, dynamic>;
        } else if (decoded is List) {
          return {'data': decoded};
        } else {
          return {'result': decoded};
        }
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get resumen_del_dia: ${e.toString()}');
    }
  }
}

