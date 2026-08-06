import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/fventas_summary.dart';
import 'package:flutter_app/widgets/report_table_header_footer.dart';
import 'package:flutter_app/widgets/report_utils.dart';

/// FVentas 푸터 밴드가 summary 의 값을 실제로 그려내는지 확인한다.
///
/// 모델 계산은 fventas_footer_summary_test.dart 가 맡고, 여기서는 "계산된 값이
/// 맞는 칸에 실제로 붙었는가"(= 배선)만 본다.
void main() {
  const keys = ['fecha', 'clientenombre', 'monto', 'tipofactura'];

  Map<String, dynamic> amount(int count, num monto, num neto, num iva) => {
        'count': count,
        'monto': monto,
        'neto': neto,
        'iva': iva,
      };

  final summaryJson = <String, dynamic>{
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
    },
    'notas_credito': {
      'subtotal': amount(21, 3509000, 2900000, 609000),
      'A': amount(4, 1210000, 1000000, 210000),
      'B': amount(17, 2299000, 1900000, 399000),
    },
    'otros': <dynamic>[],
    'total': amount(498, 68703800, 56780000, 11923800),
  };

  Future<void> pumpFooter(
    WidgetTester tester, {
    FventasSummary? summary,
    List<dynamic> rows = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: ReportTableHeaderFooter.buildFixedTotalRow(
              keys,
              rows,
              Colors.teal,
              dataList: rows,
              reportType: ReportType.fventas,
              fventasSummary: summary,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  String money(num v) => ReportUtils.formatValueForTotalRow(v, 'monto');

  testWidgets('서버 summary 의 그룹 라벨과 총계를 그린다', (tester) async {
    await pumpFooter(tester, summary: FventasSummary.fromJson(summaryJson));

    expect(find.text('Facturas'), findsOneWidget);
    expect(find.text('Notas de Débito'), findsOneWidget);
    expect(find.text('Notas de Crédito'), findsOneWidget);

    // 총계 줄: 건수 / 순액 / IVA / 총액이 각각 제 자리에 붙어야 한다.
    expect(find.text('498'), findsOneWidget);
    expect(find.textContaining(money(56780000)), findsWidgets); // Neto
    expect(find.textContaining(money(11923800)), findsWidgets); // IVA
    expect(find.textContaining(money(68703800)), findsWidgets); // TOTAL
  });

  testWidgets('letra 마다 건수와 금액을 함께 그린다', (tester) async {
    await pumpFooter(tester, summary: FventasSummary.fromJson(summaryJson));

    // Factura A: 48건 18.150.000 / Factura B: 412건 52.393.000
    expect(find.text('48'), findsOneWidget);
    expect(find.text(money(18150000)), findsOneWidget);
    expect(find.text('412'), findsOneWidget);
    expect(find.text(money(52393000)), findsOneWidget);

    // Nota de Crédito A: 4건 1.210.000 / B: 17건 2.299.000
    expect(find.text('4'), findsOneWidget);
    expect(find.text(money(1210000)), findsOneWidget);
    expect(find.text('17'), findsOneWidget);
    expect(find.text(money(2299000)), findsOneWidget);
  });

  testWidgets('건수 0 인 letra 도 금액과 함께 남긴다', (tester) async {
    await pumpFooter(tester, summary: FventasSummary.fromJson(summaryJson));

    // Facturas C 는 0건이지만 칸 자체는 사라지지 않는다.
    expect(find.text('C'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('IVA 라벨에 서버가 준 세율을 표시한다', (tester) async {
    await pumpFooter(tester, summary: FventasSummary.fromJson(summaryJson));

    expect(find.textContaining('IVA 21%'), findsOneWidget);
  });

  testWidgets('세율이 소수여도 라벨이 깨지지 않는다', (tester) async {
    final json = Map<String, dynamic>.from(summaryJson)..['iva_rate'] = 0.105;
    await pumpFooter(tester, summary: FventasSummary.fromJson(json));

    expect(find.textContaining('IVA 10.5%'), findsOneWidget);
  });

  testWidgets('Nota de Crédito 소계는 빼는 값이므로 − 를 붙인다', (tester) async {
    await pumpFooter(tester, summary: FventasSummary.fromJson(summaryJson));

    expect(find.textContaining('−${money(3509000)}'), findsOneWidget);
  });

  testWidgets('otros 가 비어 있으면 Otros 줄을 그리지 않는다', (tester) async {
    await pumpFooter(tester, summary: FventasSummary.fromJson(summaryJson));

    expect(find.text('Otros'), findsNothing);
  });

  testWidgets('otros 가 있으면 감추지 않고 드러낸다', (tester) async {
    final json = Map<String, dynamic>.from(summaryJson)
      ..['otros'] = [
        {'tipofactura': '99', 'count': 2, 'monto': 1000, 'neto': 826, 'iva': 174},
      ];
    await pumpFooter(tester, summary: FventasSummary.fromJson(json));

    expect(find.text('Otros'), findsOneWidget);
    expect(find.text('99'), findsOneWidget);
  });

  testWidgets('summary 가 없으면 받아둔 행으로 계산해서 그린다', (tester) async {
    // 옛 서버 대비 경로: 푸터가 비어버리면 안 된다.
    await pumpFooter(tester, rows: [
      {'tipofactura': '01', 'monto': 1210},
      {'tipofactura': '06', 'monto': 1210},
      {'tipofactura': '03', 'monto': 1210}, // NC A → 빠진다
    ]);

    expect(find.text('Facturas'), findsOneWidget);
    // 1210 + 1210 - 1210
    expect(find.textContaining(money(1210)), findsWidgets);
    expect(find.text('3'), findsOneWidget); // Comprobantes
  });
}
