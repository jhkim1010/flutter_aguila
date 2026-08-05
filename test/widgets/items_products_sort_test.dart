import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/items_builder.dart';
import 'package:flutter_app/widgets/resizable_data_table.dart';

/// Items 보고서 오른쪽 패널(Productos) 정렬/렌더링 테스트
///
/// 기본 정렬이 totalCantidad 내림차순인지, 헤더 클릭이 실제로 행 순서를 바꾸는지,
/// 서버 응답에 칼럼이 빠져도 셀 수가 어긋나지 않는지 확인한다.
void main() {
  /// products 한 행. 실제 서버 응답과 같은 5개 키만 채운다.
  /// (desc1 / tprendas / timporte 는 응답에 없다)
  Map<String, dynamic> product({
    required String codigo,
    required dynamic cantidad,
  }) {
    return {
      'codigo1': codigo,
      'ProductName': 'producto-$codigo',
      'totalCantidad': cantidad,
      'CategoryCode': '61',
      'CompanyCode': 'E1',
    };
  }

  Map<String, dynamic> buildData(List<Map<String, dynamic>> products) {
    return {
      'data': {
        // 좌우 분할 레이아웃을 태우려면 summary 테이블이 하나는 있어야 한다
        'summary_by_company': [
          {'CompanyCode': 'E1', 'CompanyName': 'Empresa 1', 'totalCantidad': 10},
        ],
        'products': products,
      },
    };
  }

  /// 화면에 그려진 Productos 행의 codigo1 순서
  List<String> renderedCodigos(WidgetTester tester) {
    final table = tester.widget<ResizableDataTable>(
      find.byType(ResizableDataTable),
    );
    return table.rows.map((cells) => (cells.first as Text).data!).toList();
  }

  /// Productos 테이블 안의 헤더만 찾는다.
  /// ('Código', 'Total Cantidad'는 요약 테이블/요약 카드에도 있어 중복 매칭된다)
  Finder productsHeader(String label) => find.descendant(
        of: find.byType(ResizableDataTable),
        matching: find.text(label),
      );

  Future<void> tapHeader(WidgetTester tester, String label) async {
    final header = productsHeader(label);
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tester.tap(header);
    await tester.pumpAndSettle();
  }

  /// 데스크톱(좌우 분할) 레이아웃으로 본문을 실행한다.
  ///
  /// debugDefaultTargetPlatformOverride 는 테스트 본문이 끝나기 전에 되돌려야 한다.
  /// (tearDown 은 프레임워크의 debug 변수 검사보다 늦게 실행된다)
  Future<void> runOnDesktop(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    tester.view.physicalSize = const Size(3200, 1400);
    tester.view.devicePixelRatio = 1.0;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.reset();
    }
  }

  group('Productos 패널', () {
    testWidgets('서버 응답에 없는 칼럼은 빠지고 셀 수와 칼럼 수가 일치한다', (tester) async {
      await runOnDesktop(tester, () async {
        await tester.pumpWidget(_Harness(
          data: buildData([
            product(codigo: 'A', cantidad: 5),
            product(codigo: 'B', cantidad: 50),
          ]),
        ));
        await tester.pump();

        // 셀 수 != 칼럼 수이면 ResizableDataTable 의 assertion 이 터진다
        expect(tester.takeException(), isNull);

        final table = tester.widget<ResizableDataTable>(
          find.byType(ResizableDataTable),
        );
        expect(table.columns.length, 5);
        expect(table.rows.every((r) => r.length == 5), isTrue);
      });
    });

    testWidgets('초기 정렬은 totalCantidad 내림차순이다', (tester) async {
      await runOnDesktop(tester, () async {
        await tester.pumpWidget(_Harness(
          data: buildData([
            product(codigo: 'A', cantidad: 5),
            product(codigo: 'B', cantidad: 50),
            product(codigo: 'C', cantidad: 12),
          ]),
        ));
        await tester.pumpAndSettle();

        // 많이 팔린 순: B(50) → C(12) → A(5)
        expect(renderedCodigos(tester), ['B', 'C', 'A']);
      });
    });

    testWidgets('정렬은 페이지네이션보다 먼저 적용된다 (전체 중 상위 N)', (tester) async {
      await runOnDesktop(tester, () async {
        // 서버가 준 순서에서는 큰 값이 뒤쪽에 있다
        await tester.pumpWidget(_Harness(
          data: buildData([
            product(codigo: 'A', cantidad: 1),
            product(codigo: 'B', cantidad: 2),
            product(codigo: 'C', cantidad: 99),
            product(codigo: 'D', cantidad: 98),
          ]),
          displayedItemsCount: 2,
        ));
        await tester.pumpAndSettle();

        // 자르기가 정렬 후에 적용되어야 C, D 가 나온다 (A, B 가 아니라)
        expect(renderedCodigos(tester), ['C', 'D']);
      });
    });

    testWidgets('값이 빈 행은 정렬 방향과 무관하게 아래로 간다', (tester) async {
      await runOnDesktop(tester, () async {
        await tester.pumpWidget(_Harness(
          data: buildData([
            product(codigo: 'A', cantidad: 5),
            product(codigo: 'EMPTY', cantidad: ''),
            product(codigo: 'B', cantidad: 50),
          ]),
        ));
        await tester.pumpAndSettle();
        expect(renderedCodigos(tester).last, 'EMPTY');

        // 오름차순으로 뒤집어도 빈 값이 맨 위로 올라오면 안 된다
        await tapHeader(tester, 'Total Cantidad');
        expect(renderedCodigos(tester).last, 'EMPTY');
      });
    });

    testWidgets('totalCantidad 헤더를 누르면 오름차순으로 토글된다', (tester) async {
      await runOnDesktop(tester, () async {
        await tester.pumpWidget(_Harness(
          data: buildData([
            product(codigo: 'A', cantidad: 5),
            product(codigo: 'B', cantidad: 50),
            product(codigo: 'C', cantidad: 12),
          ]),
        ));
        await tester.pumpAndSettle();
        expect(renderedCodigos(tester), ['B', 'C', 'A']);

        await tapHeader(tester, 'Total Cantidad');

        // 이미 정렬된 칼럼 재클릭 → 방향 반전
        expect(renderedCodigos(tester), ['A', 'C', 'B']);
      });
    });

    testWidgets('다른 칼럼 헤더를 누르면 그 칼럼 기준 내림차순으로 정렬된다', (tester) async {
      await runOnDesktop(tester, () async {
        await tester.pumpWidget(_Harness(
          data: buildData([
            product(codigo: 'A', cantidad: 5),
            product(codigo: 'B', cantidad: 50),
            product(codigo: 'C', cantidad: 12),
          ]),
        ));
        await tester.pumpAndSettle();

        await tapHeader(tester, 'Código');

        // 새 칼럼 첫 클릭 → 내림차순
        expect(renderedCodigos(tester), ['C', 'B', 'A']);
      });
    });
  });
}

/// report_screen_legacy 와 같은 방식으로 정렬 상태를 들고 되먹이는 테스트 하네스.
///
/// ItemsBuilder 는 정렬 상태를 스스로 갖지 않고 onSort 로 올려보낸 뒤 부모가
/// 내려주는 값으로 정렬한다. 하네스가 이 왕복을 흉내내지 않으면 헤더를 눌러도
/// 화면이 그대로여서, 실제로는 동작하는 정렬이 실패로 보인다.
class _Harness extends StatefulWidget {
  final Map<String, dynamic> data;
  final int displayedItemsCount;

  const _Harness({
    required this.data,
    this.displayedItemsCount = 100,
  });

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String? _sortColumn;
  bool _sortAscending = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ItemsBuilder.buildContent(
            data: widget.data,
            context: context,
            scrollController: _scrollController,
            onSort: (column, ascending) {
              setState(() {
                _sortColumn = column;
                _sortAscending = ascending;
              });
            },
            sortColumn: _sortColumn,
            sortAscending: _sortAscending,
            displayedItemsCount: widget.displayedItemsCount,
          ),
        ),
      ),
    );
  }
}
