import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kDebugMode;
import 'dart:io' show exit, Platform;
import 'package:local_auth/local_auth.dart';

/// 생체 인증 핸들러
class BiometricAuthHandler {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// 시뮬레이터 환경인지 확인
  bool _isSimulator() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS 시뮬레이터 감지
      try {
        // 시뮬레이터에서는 특정 환경 변수가 설정되어 있음
        final simulatorId = Platform.environment['SIMULATOR_DEVICE_NAME'];
        if (simulatorId != null) {
          return true;
        }
        // 또는 디버그 모드에서 시뮬레이터로 간주
        if (kDebugMode) {
          return true;
        }
      } catch (e) {
        // 환경 변수 확인 실패 시 디버그 모드에서는 시뮬레이터로 간주
        if (kDebugMode) {
          return true;
        }
      }
    }
    return false;
  }

  /// 백그라운드에서 생체 인식 수행
  Future<bool> authenticateInBackground() async {
    // Windows 플랫폼에서는 생체 인식 생략
    if (defaultTargetPlatform == TargetPlatform.windows) {
      print('🪟 Windows 플랫폼: 생체 인식 생략');
      return true;
    }
    
    // 시뮬레이터에서는 생체 인식 생략
    if (_isSimulator()) {
      print('📱 시뮬레이터 환경: 생체 인식 생략');
      return true;
    }
    
    try {
      final bool isSupported = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      
      if (isSupported && canCheckBiometrics) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          final bool didAuthenticate = await _localAuth.authenticate(
            localizedReason: 'Se requiere autenticación biométrica para usar la aplicación',
            options: const AuthenticationOptions(
              biometricOnly: false,
              stickyAuth: true,
            ),
          );
          
          if (!didAuthenticate) {
            print('🔐 생체 인식 실패 또는 취소됨 - 앱 종료');
            exitApp();
            return false;
          }
          
          print('✅ 생체 인식 성공');
          return true;
        } on PlatformException catch (e) {
          print('🔐 생체 인식 예외 발생 - 앱 종료: ${e.code} - ${e.message}');
          exitApp();
          return false;
        } catch (e) {
          print('❌ 생체 인식 알 수 없는 오류: $e - 앱 종료');
          exitApp();
          return false;
        }
      }
      return true;
    } catch (e) {
      print('❌ 생체 인식 확인 오류: $e');
      return true; // 생체 인식이 지원되지 않아도 계속 진행
    }
  }

  /// 앱 종료
  void exitApp() {
    print('🚪 앱 종료 중...');
    if (defaultTargetPlatform == TargetPlatform.android || 
        defaultTargetPlatform == TargetPlatform.iOS) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }
}
