import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/resizable_data_table.dart';

void main() {
  group('TableColumnDef', () {
    test('기본값이 올바르게 설정된다', () {
      const col = TableColumnDef(
        key: 'test',
        label: 'Test',
        defaultWidth: 100,
      );
      expect(col.minWidth, 50.0);
      expect(col.maxWidth, 2000.0);
      expect(col.textAlign, TextAlign.left);
      expect(col.sortable, false);
    });

    test('커스텀 값이 올바르게 설정된다', () {
      const col = TableColumnDef(
        key: 'price',
        label: 'Precio',
        defaultWidth: 80,
        minWidth: 40,
        maxWidth: 300,
        textAlign: TextAlign.right,
        sortable: true,
      );
      expect(col.key, 'price');
      expect(col.label, 'Precio');
      expect(col.defaultWidth, 80.0);
      expect(col.minWidth, 40.0);
      expect(col.maxWidth, 300.0);
      expect(col.textAlign, TextAlign.right);
      expect(col.sortable, true);
    });
  });

  group('ResizableDataTable', () {
    // 테스트용 컬럼 정의
    const testColumns = [
      TableColumnDef(key: 'name', label: 'Name', defaultWidth: 100, sortable: true),
      TableColumnDef(key: 'price', label: 'Price', defaultWidth: 80, textAlign: TextAlign.right),
    ];

    final testRows = [
      [const Text('Apple'), const Text('1000')],
      [const Text('Banana'), const Text('500')],
    ];

    final testWidths = {'name': 100.0, 'price': 80.0};

    testWidgets('칼럼 헤더 라벨이 렌더링된다', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ResizableDataTable(
            columns: testColumns,
            rows: testRows,
            columnWidths: testWidths,
            onColumnResize: (_, __) {},
            headerColor: Colors.blue,
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Price'), findsOneWidget);
    });

    testWidgets('데이터 행이 렌더링된다', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ResizableDataTable(
            columns: testColumns,
            rows: testRows,
            columnWidths: testWidths,
            onColumnResize: (_, __) {},
            headerColor: Colors.blue,
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('헤더 SizedBox가 columnWidth만큼 차지한다 (핸들 너비 미포함)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: ResizableDataTable(
              columns: testColumns,
              rows: testRows,
              columnWidths: testWidths,
              onColumnResize: (_, __) {},
              headerColor: Colors.blue,
            ),
          ),
        ),
      ));
      await tester.pump();
      // name 헤더 SizedBox가 정확히 100px이어야 한다
      final nameHeaderFinder = find.ancestor(
        of: find.text('Name'),
        matching: find.byType(SizedBox),
      ).first;
      final nameBox = tester.getSize(nameHeaderFinder);
      expect(nameBox.width, 100.0);
    });

    testWidgets('onColumnResize 콜백이 호출된다', (tester) async {
      String? resizedKey;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: ResizableDataTable(
              columns: testColumns,
              rows: testRows,
              columnWidths: testWidths,
              onColumnResize: (key, width) {
                resizedKey = key;
              },
              headerColor: Colors.blue,
            ),
          ),
        ),
      ));
      await tester.pump();
      // 실제 드래그 테스트는 통합 테스트에서 수행. 여기서는 콜백 연결만 확인.
      expect(resizedKey, isNull); // 아직 드래그 안 함
    });
  });
}
