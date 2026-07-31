import 'dart:typed_data';

/// 네이티브 플랫폼용 스텁 — 웹이 아닌 곳에서 호출되면 안 됩니다.
/// (호출부에서 kIsWeb 가드 필수)
Future<void> saveFileOnWeb(
  Uint8List bytes,
  String fileName,
  String mimeType,
) async {
  throw UnsupportedError(
    'saveFileOnWeb()은 웹 플랫폼에서만 사용할 수 있습니다. 호출 전 kIsWeb을 확인하세요.',
  );
}
