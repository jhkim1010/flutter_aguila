// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// 웹 전용 파일 다운로드 구현
/// Blob + AnchorElement 방식으로 브라우저 다운로드를 트리거합니다.
Future<void> saveFileOnWeb(
  Uint8List bytes,
  String fileName,
  String mimeType,
) async {
  String? objectUrl;
  try {
    final blob = html.Blob([bytes], mimeType);
    objectUrl = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: objectUrl)
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    print('✅ 웹 다운로드 트리거 완료: $fileName (${bytes.length} bytes)');
  } catch (e) {
    print('❌ 웹 파일 다운로드 실패: $e');
    rethrow;
  } finally {
    // Blob URL 해제 — 메모리 누수 방지
    if (objectUrl != null) {
      html.Url.revokeObjectUrl(objectUrl);
    }
  }
}
