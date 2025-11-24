import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/connection_info.dart';

class ConnectionStorageService {
  static const String _connectionsKey = 'database_connections';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // 모든 연결 정보 불러오기
  Future<List<ConnectionInfo>> getAllConnections() async {
    try {
      final connectionsJson = await _storage.read(key: _connectionsKey);
      
      if (connectionsJson == null || connectionsJson.isEmpty) {
        return [];
      }

      final List<dynamic> connectionsList = json.decode(connectionsJson);
      return connectionsList
          .map((json) => ConnectionInfo.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // 연결 정보 저장하기
  Future<bool> saveConnection(ConnectionInfo connection) async {
    try {
      final connections = await getAllConnections();
      
      // 기존 연결이 있으면 업데이트, 없으면 추가
      final index = connections.indexWhere((c) => c.id == connection.id);
      if (index >= 0) {
        connections[index] = connection;
      } else {
        connections.add(connection);
      }

      final connectionsJson = json.encode(
        connections.map((c) => c.toJson()).toList(),
      );
      
      await _storage.write(key: _connectionsKey, value: connectionsJson);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 연결 정보 삭제하기
  Future<bool> deleteConnection(String id) async {
    try {
      final connections = await getAllConnections();
      connections.removeWhere((c) => c.id == id);

      final connectionsJson = json.encode(
        connections.map((c) => c.toJson()).toList(),
      );
      
      await _storage.write(key: _connectionsKey, value: connectionsJson);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ID로 연결 정보 가져오기
  Future<ConnectionInfo?> getConnectionById(String id) async {
    try {
      final connections = await getAllConnections();
      return connections.firstWhere(
        (c) => c.id == id,
        orElse: () => throw Exception('Connection not found'),
      );
    } catch (e) {
      return null;
    }
  }
}

