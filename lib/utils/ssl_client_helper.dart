import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// SSL 인증서 검증을 처리하는 HTTP Client 헬퍼
/// 자체 서명 인증서(self-signed certificate)를 허용합니다.
class SslClientHelper {
  /// SSL 인증서 검증을 우회하는 HTTP Client를 생성합니다.
  ///
  /// 주의: 개발 환경에서만 사용하고, 프로덕션에서는 적절한 인증서를 사용해야 합니다.
  static http.Client createUnsafeClient() {
    // 웹: 브라우저가 TLS를 직접 처리하므로 인증서 우회가 불가능함
    // → 기본 클라이언트 반환 (서버에 유효한 인증서 필요)
    if (kIsWeb) {
      print('🌐 웹 플랫폼: 브라우저 기본 HTTP Client 사용 (SSL 우회 불가)');
      return http.Client();
    }

    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // 자체 서명 인증서를 허용합니다.
        // 개발 환경에서만 사용하세요.
        print('⚠️ SSL 인증서 검증 우회: $host:$port');
        print('   인증서 정보: ${cert.subject}');
        print('   발급자: ${cert.issuer}');
        // 모든 인증서를 허용 (자체 서명 인증서 포함)
        return true;
      }
      // 연결 타임아웃 설정
      ..connectionTimeout = const Duration(seconds: 30)
      // 읽기 타임아웃 설정
      ..idleTimeout = const Duration(seconds: 30);

    return IOClient(httpClient);
  }

  /// 기본 HTTP Client를 반환합니다 (인증서 검증 활성화).
  static http.Client createDefaultClient() {
    return http.Client();
  }
}
