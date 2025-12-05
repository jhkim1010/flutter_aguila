import 'dart:convert';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // macOS에서는 SharedPreferences 사용 (Keychain 접근 문제 회피)
  bool get _isMacOS => defaultTargetPlatform == TargetPlatform.macOS;

  // 모든 연결 정보 불러오기
  Future<List<ConnectionInfo>> getAllConnections() async {
    try {
      print('📖 연결 정보 읽기 시작... (macOS: $_isMacOS)');
      String? connectionsJson;
      
      if (_isMacOS) {
        // macOS: SharedPreferences 사용
        final prefs = await SharedPreferences.getInstance();
        connectionsJson = prefs.getString(_connectionsKey);
        print('📖 SharedPreferences에서 읽기 완료');
      } else {
        // 다른 플랫폼: FlutterSecureStorage 사용
        connectionsJson = await _storage.read(key: _connectionsKey);
        print('📖 SecureStorage에서 읽기 완료');
      }
      
      if (connectionsJson == null || connectionsJson.isEmpty) {
        print('ℹ️ 저장된 연결 정보가 없음');
        return [];
      }

      print('📖 JSON 데이터 읽기 완료 (길이: ${connectionsJson.length})');
      final List<dynamic> connectionsList = json.decode(connectionsJson);
      final connections = connectionsList
          .map((json) => ConnectionInfo.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('✅ 연결 정보 파싱 완료: ${connections.length}개 연결');
      for (var conn in connections) {
        print('   - ${conn.name} (ID: ${conn.id})');
      }
      
      return connections;
    } catch (e) {
      print('❌ 연결 정보 읽기 실패: $e');
      return [];
    }
  }

  // 연결 정보 저장하기
  Future<bool> saveConnection(ConnectionInfo connection) async {
    try {
      print('💾 연결 정보 저장 시작: ${connection.name} (ID: ${connection.id})');
      final connections = await getAllConnections();
      print('📋 현재 저장된 연결 수: ${connections.length}개');
      
      // 기존 연결이 있으면 업데이트, 없으면 추가
      final index = connections.indexWhere((c) => c.id == connection.id);
      if (index >= 0) {
        print('🔄 기존 연결 업데이트: ${connections[index].name}');
        connections[index] = connection;
      } else {
        print('➕ 새 연결 추가: ${connection.name}');
        connections.add(connection);
      }

      final connectionsJson = json.encode(
        connections.map((c) => c.toJson()).toList(),
      );
      
      print('💾 JSON 데이터 저장 중... (길이: ${connectionsJson.length}, macOS: $_isMacOS)');
      
      if (_isMacOS) {
        // macOS: SharedPreferences 사용
        final prefs = await SharedPreferences.getInstance();
        final saved = await prefs.setString(_connectionsKey, connectionsJson);
        if (!saved) {
          print('❌ SharedPreferences 저장 실패');
          return false;
        }
        print('✅ SharedPreferences 저장 완료');
      } else {
        // 다른 플랫폼: FlutterSecureStorage 사용
        await _storage.write(key: _connectionsKey, value: connectionsJson);
        print('✅ SecureStorage 저장 완료');
      }
      
      // 저장 확인: 바로 다시 읽어서 확인
      String? savedJson;
      if (_isMacOS) {
        final prefs = await SharedPreferences.getInstance();
        savedJson = prefs.getString(_connectionsKey);
      } else {
        savedJson = await _storage.read(key: _connectionsKey);
      }
      if (savedJson == null || savedJson.isEmpty) {
        print('❌ 저장 실패: 저장된 데이터가 없음');
        return false;
      }
      
      final savedConnections = await getAllConnections();
      print('✅ 저장 확인 완료: ${savedConnections.length}개 연결 저장됨');
      final savedConnection = savedConnections.firstWhere(
        (c) => c.id == connection.id,
        orElse: () => ConnectionInfo(
          id: '',
          name: '',
          serverUrl: '',
          databaseName: '',
          username: '',
          password: '',
          port: 0,
        ),
      );
      
      if (savedConnection.id == connection.id) {
        print('✅ 저장된 연결 확인: ${savedConnection.name}');
        return true;
      } else {
        print('❌ 저장 확인 실패: 저장된 연결을 찾을 수 없음');
        return false;
      }
    } catch (e) {
      print('❌ 연결 정보 저장 중 오류: $e');
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
      
      if (_isMacOS) {
        // macOS: SharedPreferences 사용
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_connectionsKey, connectionsJson);
      } else {
        // 다른 플랫폼: FlutterSecureStorage 사용
        await _storage.write(key: _connectionsKey, value: connectionsJson);
      }
      return true;
    } catch (e) {
      print('❌ 연결 삭제 실패: $e');
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

