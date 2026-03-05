import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import '../../services/database_service.dart';
import '../../services/connection_storage_service.dart';
import '../../services/secure_storage_helper.dart';
import '../../models/connection_info.dart';
import '../../l10n/app_localizations.dart';

/// 연결 관리자
class ConnectionManager {
  final ConnectionStorageService _connectionStorageService = ConnectionStorageService();

  /// 연결 상태 확인
  static Future<ConnectionStatus> checkConnectionStatus() async {
    try {
      final connectionSuccess = await SecureStorageHelper.read('connection_success');
      final serverUrl = await SecureStorageHelper.read('server_url');
      final databaseName = await SecureStorageHelper.read('database_name');
      
      if (connectionSuccess == 'true' && serverUrl != null && databaseName != null) {
        return ConnectionStatus(
          isConnected: true,
          serverUrl: serverUrl,
          databaseName: databaseName,
        );
      }
      return ConnectionStatus(isConnected: false);
    } catch (e) {
      print('❌ 연결 상태 확인 오류: $e');
      return ConnectionStatus(isConnected: false);
    }
  }

  /// 저장된 연결 목록 불러오기
  Future<List<ConnectionInfo>> loadSavedConnections() async {
    try {
      print('🔄 저장된 연결 리스트 로드 시작...');
      final connections = await _connectionStorageService.getAllConnections();
      print('✅ 저장된 연결 리스트 로드 완료: ${connections.length}개 연결');
      
      for (var conn in connections) {
        print('   - ${conn.name} (ID: ${conn.id}, DB: ${conn.databaseName})');
      }
      
      return connections;
    } catch (e) {
      print('❌ 연결 리스트 로드 실패: $e');
      return [];
    }
  }

  /// 연결 삭제하기
  Future<bool> deleteConnection(
    BuildContext context,
    ConnectionInfo connection,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConnection),
        content: Text(l10n.deleteConnectionConfirm(connection.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        print('🗑️ 연결 삭제 시작: ${connection.name} (ID: ${connection.id})');
        await _connectionStorageService.deleteConnection(connection.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.connectionDeleted)),
          );
        }
        print('✅ 연결 삭제 완료: ${connection.name}');
        return true;
      } catch (e) {
        print('❌ 연결 삭제 실패: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 실패: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    }
    return false;
  }

  /// 저장된 연결로 연결 시도
  Future<ConnectionResult> connectWithSavedConnection(
    ConnectionInfo connection,
  ) async {
    final service = DatabaseService(serverUrl: connection.serverUrl);
    try {
      final request = DatabaseConnectionRequest(
        databaseName: connection.databaseName,
        username: connection.username,
        password: connection.password,
      );

      // 연결 변경 시 기존 캐시 초기화
      service.clearTiposTemporadasCache();
      
      final success = await service.connectToDatabase(request);
      
      // 데이터베이스 연결 성공 시 tipos와 temporadas 새로 로드
      if (success) {
        try {
          final tipos = await service.getTipos(forceRefresh: true);
          final temporadas = await service.getTemporadas(forceRefresh: true);
        } catch (e) {
          print('⚠️ Tipos/Temporadas 로드 실패 (계속 진행): $e');
        }
        
        // 연결 정보를 하이브리드 저장소에 저장
        await SecureStorageHelper.save('database_name', connection.databaseName);
        await SecureStorageHelper.save('username', connection.username);
        if (defaultTargetPlatform == TargetPlatform.macOS) {
          await SecureStorageHelper.save('password', connection.password);
        } else {
          await SecureStorageHelper.saveSecure('password', connection.password);
        }
        await SecureStorageHelper.save('server_url', connection.serverUrl);
        await SecureStorageHelper.save('connection_success', 'true');
        await SecureStorageHelper.save('profile_name', connection.name);

        print('✅ 저장된 연결로 연결 성공');
        return ConnectionResult.success(connection.serverUrl);
      } else {
        return ConnectionResult.failed('연결에 실패했습니다.');
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      return ConnectionResult.failed(errorMessage);
    } finally {
      service.dispose(); // HTTP 클라이언트 정리, 연결 풀 낭비 방지
    }
  }

  /// 연결 정보 저장
  Future<void> saveConnectionInfo({
    required String profileName,
    required String serverUrl,
    required String databaseName,
    required String username,
    required String password,
    required String serverType,
    String? localIp,
  }) async {
    await SecureStorageHelper.save('profile_name', profileName);
    await SecureStorageHelper.save('server_type', serverType);
    await SecureStorageHelper.save('server_url', serverUrl);
    await SecureStorageHelper.save('database_name', databaseName);
    await SecureStorageHelper.save('username', username);
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      await SecureStorageHelper.save('password', password);
    } else {
      await SecureStorageHelper.saveSecure('password', password);
    }
    if (localIp != null) {
      await SecureStorageHelper.save('local_ip', localIp);
    }
    await SecureStorageHelper.save('connection_success', 'true');
  }

  /// 연결 목록에 저장하기
  Future<void> saveToConnectionList({
    required String connectionName,
    required String serverUrl,
    required String databaseName,
    required String username,
    required String password,
    required int port,
  }) async {
    try {
      final existingConnections = await _connectionStorageService.getAllConnections();
      
      final isDuplicate = existingConnections.any((conn) =>
        conn.serverUrl == serverUrl &&
        conn.databaseName == databaseName &&
        conn.username == username
      );
      
      if (isDuplicate) {
        print('⚠️ 중복된 연결이 이미 존재합니다. 추가하지 않습니다.');
        return;
      }
      
      final connectionId = DateTime.now().millisecondsSinceEpoch.toString();
      final connection = ConnectionInfo(
        id: connectionId,
        name: connectionName,
        serverUrl: serverUrl,
        databaseName: databaseName,
        username: username,
        password: password,
        port: port,
      );
      
      await _connectionStorageService.saveConnection(connection);
      print('✅ 연결 목록에 저장 완료: ${connection.name}');
    } catch (e) {
      print('❌ 연결 목록 저장 실패: $e');
    }
  }
}

/// 연결 상태
class ConnectionStatus {
  final bool isConnected;
  final String? serverUrl;
  final String? databaseName;

  ConnectionStatus({
    required this.isConnected,
    this.serverUrl,
    this.databaseName,
  });
}

/// 연결 결과
class ConnectionResult {
  final bool isSuccess;
  final String? serverUrl;
  final String? errorMessage;

  ConnectionResult({
    required this.isSuccess,
    this.serverUrl,
    this.errorMessage,
  });

  factory ConnectionResult.success(String serverUrl) {
    return ConnectionResult(isSuccess: true, serverUrl: serverUrl);
  }

  factory ConnectionResult.failed(String error) {
    return ConnectionResult(isSuccess: false, errorMessage: error);
  }
}
