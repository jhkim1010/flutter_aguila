import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/fventas_summary.dart';

/// FVentas 푸터 요약: 서버 summary 블록 파싱과, summary 가 없을 때의 대체 계산.
///
/// 아래 JSON 은 백엔드가 실제로 보내는 응답 모양이다.
void main() {
  Map<String, dynamic> amount(int count, num monto, num neto, num iva) => {
        'count': count,
        'monto': monto,
        'neto': neto,
        'iva': iva,
      };

  /// 서버가 보내주는 summary 블록 (실제 응답 예시)
  Map<String, dynamic> serverSummary() => {
        'iva_rate': 0.21,
        'monto_incluye_iva': true,
        'facturas': {
          'subtotal': amount(463, 71450500, 59050000, 12400500),
          'A': amount(48, 18150000, 15000000, 3150000),
          'B': amount(412, 52393000, 43300000, 9093000),
          'C': amount(0, 0, 0, 0),
          'M': amount(3, 907500, 750000, 157500),
        },
        'notas_debito': {
          'subtotal': amount(14, 762300, 630000, 132300),
          'A': amount(5, 423500, 350000, 73500),
          'B': amount(9, 338800, 280000, 58800),
          'C': amount(0, 0, 0, 0),
          'M': amount(0, 0, 0, 0),
        },
        'notas_credito': {
          'subtotal': amount(21, 3509000, 2900000, 609000),
          'A': amount(4, 1210000, 1000000, 210000),
          'B': amount(17, 2299000, 1900000, 399000),
          'C': amount(0, 0, 0, 0),
          'M': amount(0, 0, 0, 0),
        },
        'otros': <dynamic>[],
        'total': amount(498, 68703800, 56780000, 11923800),
      };

  Map<String, dynamic> row(String tipo, num monto) => {
        'tipofactura': tipo,
        'monto': monto,
        'numfactura': '0001',
      };

  group('FventasSummary.fromJson (서버 summary)', () {
    test('그룹별 letra 건수와 금액을 읽는다', () {
      final s = FventasSummary.fromJson(serverSummary())!;

      expect(s.fromServer, isTrue);
      expect(s.ivaRate, 0.21);
      expect(s.montoIncluyeIva, isTrue);

      expect(s.facturas.byLetra['A']!.count, 48);
      expect(s.facturas.byLetra['B']!.count, 412);
      expect(s.facturas.byLetra['M']!.count, 3);
      expect(s.facturas.subtotal.count, 463);
      expect(s.facturas.subtotal.monto, 71450500);

      expect(s.notasDebito.subtotal.count, 14);
      expect(s.notasCredito.subtotal.count, 21);
    });

    test('subtotal 은 letra 칸으로 잘못 섞이지 않는다', () {
      final s = FventasSummary.fromJson(serverSummary())!;

      expect(s.facturas.byLetra.containsKey('SUBTOTAL'), isFalse);
      expect(s.facturas.letras, ['A', 'B', 'C', 'M']);
    });

    test('건수 0 인 letra 도 버리지 않는다 (0 과 없음은 다르다)', () {
      final s = FventasSummary.fromJson(serverSummary())!;

      expect(s.facturas.byLetra.containsKey('C'), isTrue);
      expect(s.facturas.byLetra['C']!.count, 0);
    });

    test('total 은 서버 값을 그대로 쓴다', () {
      final s = FventasSummary.fromJson(serverSummary())!;

      expect(s.total.count, 498);
      expect(s.total.monto, 68703800);
      expect(s.total.neto, 56780000);
      expect(s.total.iva, 11923800);
    });

    test('서버 total 은 "Factura + ND - NC" 규칙과 맞는다', () {
      final s = FventasSummary.fromJson(serverSummary())!;

      // 이 규칙이 깨지면 푸터의 TOTAL 이 그룹 줄들과 안 맞게 보인다.
      expect(
        s.facturas.subtotal.monto +
            s.notasDebito.subtotal.monto -
            s.notasCredito.subtotal.monto,
        s.total.monto,
      );
      expect(
        s.facturas.subtotal.neto +
            s.notasDebito.subtotal.neto -
            s.notasCredito.subtotal.neto,
        s.total.neto,
      );
      // 건수는 NC 도 발행된 comprobante 이므로 더한다.
      expect(
        s.facturas.subtotal.count +
            s.notasDebito.subtotal.count +
            s.notasCredito.subtotal.count,
        s.total.count,
      );
    });

    test('total 이 없으면 규칙대로 직접 만든다', () {
      final json = serverSummary()..remove('total');
      final s = FventasSummary.fromJson(json)!;

      expect(s.total.monto, 71450500 + 762300 - 3509000);
      expect(s.total.count, 463 + 14 + 21);
    });

    test('otros 는 담아서 드러내되 총합에는 넣지 않는다', () {
      final json = serverSummary()
        ..remove('total')
        ..['otros'] = [
          {
            'tipofactura': '99',
            'count': 2,
            'monto': 1000,
            'neto': 826.45,
            'iva': 173.55,
          },
        ];
      final s = FventasSummary.fromJson(json)!;

      expect(s.otros, hasLength(1));
      expect(s.otros.first.label, '99');
      expect(s.otros.first.amount.count, 2);
      // 모르는 코드는 더할지 뺄지 알 수 없어 총합에 넣지 않는다.
      // 서버 buildFventasSummary 도 같은 규칙이다.
      expect(s.total.monto, 71450500 + 762300 - 3509000);
    });

    test('summary 블록이 없거나 모양이 다르면 null', () {
      expect(FventasSummary.fromJson(null), isNull);
      expect(FventasSummary.fromJson('nope'), isNull);
      expect(FventasSummary.fromJson(<dynamic>[]), isNull);
    });

    test('빈 summary 도 터지지 않는다', () {
      final s = FventasSummary.fromJson(<String, dynamic>{})!;

      expect(s.total.count, 0);
      expect(s.facturas.letras, isEmpty);
      expect(s.ivaRate, FventasSummary.defaultIvaRate);
    });
  });

  group('FventasSummary.fromRows (서버 summary 가 없을 때)', () {
    test('AFIP 숫자 코드를 그룹과 letra 로 나눈다', () {
      // 01=Factura A, 06=Factura B, 02=ND A, 03=NC A, 08=NC B, 51=Factura M
      final s = FventasSummary.fromRows([
        row('01', 1210),
        row('06', 1210),
        row('51', 1210),
        row('02', 1210),
        row('03', 1210),
        row('08', 1210),
      ]);

      expect(s.fromServer, isFalse);
      expect(s.facturas.letras, ['A', 'B', 'M']);
      expect(s.notasDebito.letras, ['A']);
      expect(s.notasCredito.letras, ['A', 'B']);
      expect(s.otros, isEmpty);
    });

    test('총합은 Factura + ND - NC 이다', () {
      final s = FventasSummary.fromRows([
        row('01', 1000), // Factura A
        row('06', 500), // Factura B
        row('02', 200), // ND A
        row('03', 300), // NC A
      ]);

      expect(s.facturas.subtotal.monto, 1500);
      expect(s.notasDebito.subtotal.monto, 200);
      expect(s.notasCredito.subtotal.monto, 300);
      expect(s.total.monto, 1400); // 1500 + 200 - 300
      expect(s.total.count, 4); // 건수는 다 더한다
    });

    test('IVA 는 포함 금액에서 역산한다 (0.21 / 1.21)', () {
      final s = FventasSummary.fromRows([row('01', 1210)]);

      expect(s.total.monto, 1210);
      expect(s.total.neto, closeTo(1000, 0.01));
      expect(s.total.iva, closeTo(210, 0.01));
    });

    test('레거시 문자 코드도 받는다', () {
      final s = FventasSummary.fromRows([
        row('A', 100),
        row('B', 100),
        row('NCA', 50),
        row('NDB', 20),
        row('C', 10), // resumen_del_dia 의 레거시 'C' = Nota de Crédito
      ]);

      expect(s.facturas.letras, ['A', 'B']);
      expect(s.notasCredito.letras, ['A', 'C']);
      expect(s.notasDebito.letras, ['B']);
      expect(s.otros, isEmpty);
    });

    test('모르는 코드는 Factura 로 넘기지 않고 otros 로 드러낸다', () {
      final s = FventasSummary.fromRows([
        row('01', 1000),
        row('99', 777), // AFIP 표에 없는 코드
      ]);

      expect(s.facturas.subtotal.monto, 1000);
      expect(s.otros, hasLength(1));
      expect(s.otros.first.label, '99');
      // 부호를 모르므로 총합에는 넣지 않는다. 대신 Otros 줄로 드러난다.
      expect(s.total.monto, 1000);
    });

    test('tipofactura 가 비었거나 Map 이 아닌 행은 건너뛴다', () {
      final s = FventasSummary.fromRows([
        row('01', 100),
        {'tipofactura': '', 'monto': 999},
        {'tipofactura': null, 'monto': 999},
        'not a map',
      ]);

      expect(s.total.count, 1);
      expect(s.total.monto, 100);
    });

    test('공백과 대소문자가 섞여도 같은 칸으로 묶인다', () {
      final s = FventasSummary.fromRows([
        row(' 01 ', 100),
        row('nca', 10),
        row(' NCA', 10),
      ]);

      expect(s.facturas.byLetra['A']!.count, 1);
      expect(s.notasCredito.byLetra['A']!.count, 2);
    });

    test('한 자리로 온 숫자 코드도 0 을 채워 인식한다', () {
      final s = FventasSummary.fromRows([row('1', 100), row('6', 100)]);

      expect(s.facturas.letras, ['A', 'B']);
      expect(s.otros, isEmpty);
    });
  });
}
