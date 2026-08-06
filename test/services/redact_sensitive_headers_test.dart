import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/api/http_request_handler.dart';

/// 로그로 DB 비밀번호가 새지 않는지 못 박아둔다.
///
/// 이 방어가 풀리면 웹 빌드에서는 브라우저 콘솔에 비밀번호가 그대로 찍힌다.
/// 사용자가 F12 만 눌러도 보이므로, 회귀하면 즉시 알아야 한다.
void main() {
  Map<String, String> headers() => {
        'Content-Type': 'application/json',
        'x-db-name': 'themarket59',
        'x-db-user': 'kossa',
        'x-db-password': 'super-secret',
        'x-db-ssl': 'false',
        'Connection': 'keep-alive',
      };

  test('x-db-password 를 가린다', () {
    final redacted = redactSensitiveHeaders(headers());

    expect(redacted['x-db-password'], '***');
    expect(redacted.toString(), isNot(contains('super-secret')));
  });

  test('민감하지 않은 헤더는 그대로 둔다', () {
    final redacted = redactSensitiveHeaders(headers());

    expect(redacted['x-db-name'], 'themarket59');
    expect(redacted['x-db-user'], 'kossa');
    expect(redacted['Content-Type'], 'application/json');
    expect(redacted['x-db-ssl'], 'false');
    expect(redacted['Connection'], 'keep-alive');
  });

  test('원본 Map 은 건드리지 않는다 - 실제 요청에는 진짜 값이 나가야 한다', () {
    final original = headers();
    redactSensitiveHeaders(original);

    expect(original['x-db-password'], 'super-secret');
  });

  test('키 대소문자가 달라도 가린다', () {
    final redacted = redactSensitiveHeaders({
      'X-DB-Password': 'super-secret',
      'Authorization': 'Bearer token123',
      'Cookie': 'session=abc',
    });

    expect(redacted['X-DB-Password'], '***');
    expect(redacted['Authorization'], '***');
    expect(redacted['Cookie'], '***');
    expect(redacted.toString(), isNot(contains('super-secret')));
    expect(redacted.toString(), isNot(contains('token123')));
    expect(redacted.toString(), isNot(contains('session=abc')));
  });

  test('빈 Map 도 그대로 통과한다', () {
    expect(redactSensitiveHeaders({}), isEmpty);
  });

  test('키 개수는 보존한다 - 가리는 것이지 지우는 것이 아니다', () {
    final original = headers();
    final redacted = redactSensitiveHeaders(original);

    expect(redacted.keys.toSet(), original.keys.toSet());
  });
}
