/// 웹 파일 다운로드 헬퍼 (조건부 import 파사드)
///
/// 네이티브 플랫폼에서는 스텁(UnsupportedError)이,
/// 웹에서는 브라우저 다운로드 구현이 로드됩니다.
/// 사용 전 반드시 kIsWeb으로 분기해야 합니다.
export 'web_file_saver_stub.dart'
    if (dart.library.html) 'web_file_saver_html.dart';
