import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// macOS에서 안전하고 안정적인 데이터 저장을 위한 헬퍼 클래스
/// 중요 데이터(비밀번호)는 flutter_secure_storage 사용
/// 일반 데이터는 shared_preferences 사용
class SecureStorageHelper {
  // 중요 데이터용 secure storage (비밀번호만)
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false, // macOS에서 동기화 비활성화로 안정성 향상
    ),
  );

  // 일반 데이터용 shared preferences
  static Future<SharedPreferences> get _prefs async => 
      await SharedPreferences.getInstance();

  /// 중요 데이터 저장 (비밀번호만)
  static Future<bool> saveSecure(String key, String value) async {
    try {
      print('   🔐 SecureStorage 저장 시작: key="$key", value 길이=${value.length}');
      await _secureStorage.write(key: key, value: value);
      print('   ✅ SecureStorage write() 호출 완료');
      
      // macOS에서 저장 확인
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        print('   🍎 macOS: 저장 확인 대기 중...');
        await Future.delayed(const Duration(milliseconds: 100));
        final saved = await _secureStorage.read(key: key);
        print('   📖 macOS: 읽은 값 길이=${saved?.length ?? 0}');
        
        if (saved != value) {
          print('   ⚠️ macOS secure storage 저장 확인 실패, 재시도...');
          print('   🔄 재시도 1/1: write() 재호출...');
          await Future.delayed(const Duration(milliseconds: 200));
          await _secureStorage.write(key: key, value: value);
          print('   ✅ 재시도 write() 완료');
          await Future.delayed(const Duration(milliseconds: 100));
          final retrySaved = await _secureStorage.read(key: key);
          final retrySuccess = retrySaved == value;
          print('   ${retrySuccess ? "✅" : "❌"} 재시도 결과: ${retrySuccess ? "성공" : "실패"}');
          if (!retrySuccess) {
            print('   ❌ 재시도 후에도 저장 확인 실패');
            print('   원본 길이: ${value.length}, 읽은 길이: ${retrySaved?.length ?? 0}');
          }
          return retrySuccess;
        } else {
          print('   ✅ macOS: 저장 확인 성공');
        }
      }
      return true;
    } catch (e, stackTrace) {
      print('   ❌ Secure storage 저장 실패: $e');
      print('   스택 트레이스: $stackTrace');
      return false;
    }
  }

  /// 중요 데이터 읽기 (비밀번호만)
  static Future<String?> readSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      print('❌ Secure storage 읽기 실패: $e');
      return null;
    }
  }

  /// 일반 데이터 저장 (데이터베이스 이름, 사용자 이름 등)
  static Future<bool> save(String key, String value) async {
    try {
      print('   📝 SharedPreferences 저장 시작: key="$key", value="$value"');
      final prefs = await _prefs;
      final result = await prefs.setString(key, value);
      print('   ${result ? "✅" : "❌"} SharedPreferences 저장 결과: $result');
      if (result) {
        // 저장 확인
        final saved = prefs.getString(key);
        if (saved == value) {
          print('   ✅ SharedPreferences 저장 확인 성공');
        } else {
          print('   ⚠️ SharedPreferences 저장 확인 실패: 저장된 값이 다름');
          print('   원본: "$value"');
          print('   저장된 값: "${saved ?? "(null)"}"');
        }
      }
      return result;
    } catch (e, stackTrace) {
      print('   ❌ SharedPreferences 저장 실패: $e');
      print('   스택 트레이스: $stackTrace');
      return false;
    }
  }

  /// 일반 데이터 읽기
  static Future<String?> read(String key) async {
    try {
      final prefs = await _prefs;
      return prefs.getString(key);
    } catch (e) {
      print('❌ SharedPreferences 읽기 실패: $e');
      return null;
    }
  }

  /// 데이터 삭제
  static Future<bool> delete(String key) async {
    try {
      // secure storage에서 삭제 시도
      await _secureStorage.delete(key: key);
      // shared preferences에서도 삭제 시도
      final prefs = await _prefs;
      return await prefs.remove(key);
    } catch (e) {
      print('❌ 데이터 삭제 실패: $e');
      return false;
    }
  }

  /// 모든 데이터 삭제
  static Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
      final prefs = await _prefs;
      await prefs.clear();
    } catch (e) {
      print('❌ 모든 데이터 삭제 실패: $e');
    }
  }
}

