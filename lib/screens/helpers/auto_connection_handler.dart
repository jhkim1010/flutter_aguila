import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import '../../services/database_service.dart';
import '../../services/secure_storage_helper.dart';

/// 자동 연결 핸들러
class AutoConnectionHandler {
  /// 저장된 연결 정보 확인 후 자동 연결
  static Future<AutoConnectionResult> checkAndAutoConnect({
    required bool skipAutoConnect,
    required Function(String serverUrl) onSuccess,
  }) async {
    if (skipAutoConnect) {
      return AutoConnectionResult.skipped();
    }
    
    try {
      final serverUrl = await SecureStorageHelper.read('server_url');
      final databaseName = await SecureStorageHelper.read('database_name');
      final username = await SecureStorageHelper.read('username');
      final password = defaultTargetPlatform == TargetPlatform.macOS
          ? await SecureStorageHelper.read('password')
          : await SecureStorageHelper.readSecure('password');
      final connectionSuccess = await SecureStorageHelper.read('connection_success');
      
      if (serverUrl != null && 
          serverUrl.isNotEmpty &&
          databaseName != null && 
          databaseName.isNotEmpty &&
          username != null && 
          username.isNotEmpty &&
          password != null && 
          password.isNotEmpty &&
          connectionSuccess == 'true') {
        
        return await autoConnectToDatabase(
          serverUrl: serverUrl,
          databaseName: databaseName,
          username: username,
          password: password,
          onSuccess: onSuccess,
        );
      } else {
        return AutoConnectionResult.noSavedInfo();
      }
    } catch (e) {
      return AutoConnectionResult.error(e.toString());
    }
  }
  
  /// 자동 연결 시도
  static Future<AutoConnectionResult> autoConnectToDatabase({
    required String serverUrl,
    required String databaseName,
    required String username,
    required String password,
    required Function(String serverUrl) onSuccess,
  }) async {
    final service = DatabaseService(serverUrl: serverUrl);
    try {
      final request = DatabaseConnectionRequest(
        databaseName: databaseName,
        username: username,
        password: password,
      );

      // 연결 변경 시 기존 캐시 초기화
      service.clearTiposTemporadasCache();
      
      final success = await service.connectToDatabase(request);
      
      // 데이터베이스 연결 성공 시
      if (success) {
        print('✅ 자동 연결 성공');
        onSuccess(serverUrl);
        try {
          await service.getTipos(forceRefresh: true);
          await service.getTemporadas(forceRefresh: true);
        } catch (e) {
          print('⚠️ Tipos/Temporadas 로드 실패 (계속 진행): $e');
        }
        return AutoConnectionResult.success(serverUrl);
      } else {
        return AutoConnectionResult.failed('연결에 실패했습니다.');
      }
    } catch (e) {
      return AutoConnectionResult.failed(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      service.dispose(); // HTTP 클라이언트 정리, 연결 풀 낭비 방지
    }
  }
}

/// 자동 연결 결과
class AutoConnectionResult {
  final bool isSuccess;
  final bool isSkipped;
  final bool hasNoSavedInfo;
  final String? serverUrl;
  final String? errorMessage;

  AutoConnectionResult({
    required this.isSuccess,
    required this.isSkipped,
    required this.hasNoSavedInfo,
    this.serverUrl,
    this.errorMessage,
  });

  factory AutoConnectionResult.success(String serverUrl) {
    return AutoConnectionResult(
      isSuccess: true,
      isSkipped: false,
      hasNoSavedInfo: false,
      serverUrl: serverUrl,
    );
  }

  factory AutoConnectionResult.failed(String error) {
    return AutoConnectionResult(
      isSuccess: false,
      isSkipped: false,
      hasNoSavedInfo: false,
      errorMessage: error,
    );
  }

  factory AutoConnectionResult.skipped() {
    return AutoConnectionResult(
      isSuccess: false,
      isSkipped: true,
      hasNoSavedInfo: false,
    );
  }

  factory AutoConnectionResult.noSavedInfo() {
    return AutoConnectionResult(
      isSuccess: false,
      isSkipped: false,
      hasNoSavedInfo: true,
    );
  }

  factory AutoConnectionResult.error(String error) {
    return AutoConnectionResult(
      isSuccess: false,
      isSkipped: false,
      hasNoSavedInfo: false,
      errorMessage: error,
    );
  }
}
