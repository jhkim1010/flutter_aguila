import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/secure_storage_helper.dart';

/// SharedPreferences 저장 로그로 비밀번호가 새지 않는지 못 박아둔다.
///
/// macOS 와 웹은 비밀번호도 SharedPreferences 로 간다. 웹에서는 print 가
/// 브라우저 콘솔로 나가므로, 이 방어가 풀리면 사용자가 F12 만 눌러도 자기 DB
/// 비밀번호를 읽을 수 있다. 실제로 배포본에서 이렇게 새고 있었다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secret = 'super-secret-value';

  /// save() 를 부르면서 print 출력을 전부 모은다.
  Future<List<String>> captureSaveLog(String key, String value) async {
    final lines = <String>[];
    await runZoned(
      () => SecureStorageHelper.save(key, value),
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) => lines.add(line),
      ),
    );
    return lines;
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('password 저장 로그에 평문이 남지 않는다', () async {
    final lines = await captureSaveLog('password', secret);

    expect(lines, isNotEmpty, reason: '로그 자체가 안 나오면 검증이 무의미하다');
    expect(lines.join('\n'), isNot(contains(secret)));
  });

  test('password 저장 로그는 길이만 남긴다', () async {
    final lines = await captureSaveLog('password', secret);

    expect(lines.join('\n'), contains('*** (길이: ${secret.length})'));
  });

  test('민감하지 않은 키는 값을 그대로 찍는다 - 디버깅 흐름을 죽이지 않는다', () async {
    final lines = await captureSaveLog('database_name', 'themarket59');

    expect(lines.join('\n'), contains('themarket59'));
  });

  test('저장된 값은 여전히 원본이다 - 로그만 가릴 뿐이다', () async {
    await captureSaveLog('password', secret);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('password'), secret);
  });

  test('키 대소문자가 달라도 가린다', () async {
    final lines = await captureSaveLog('PASSWORD', secret);

    expect(lines.join('\n'), isNot(contains(secret)));
  });
}
