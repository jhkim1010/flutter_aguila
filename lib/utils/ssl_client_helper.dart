import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// SSL 인증서 검증을 처리하는 HTTP Client 헬퍼
/// 자체 서명 인증서(self-signed certificate)를 허용합니다.
class SslClientHelper {
  /// SSL 인증서 검증을 우회하는 HTTP Client를 생성합니다.
  /// 
  /// 주의: 개발 환경에서만 사용하고, 프로덕션에서는 적절한 인증서를 사용해야 합니다.
  static http.Client createUnsafeClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // 자체 서명 인증서를 허용합니다.
        // 개발 환경에서만 사용하세요.
        print('⚠️ SSL 인증서 검증 우회: $host:$port');
        return true;
      };

    return IOClient(httpClient);
  }

  /// 기본 HTTP Client를 반환합니다 (인증서 검증 활성화).
  static http.Client createDefaultClient() {
    return http.Client();
  }
}
