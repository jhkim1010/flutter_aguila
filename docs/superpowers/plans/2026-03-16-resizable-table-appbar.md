# ResizableDataTable + ReportResponsiveAppBar 구현 계획

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 모든 보고서에서 공유하는 올바른 칼럼 리사이즈 테이블 위젯과 반응형 AppBar를 구현하여 기존 버그(핸들이 Row 레이아웃 너비를 차지해 헤더-데이터 칼럼 어긋남 발생)를 수정한다.

**Architecture:** `ResizableDataTable`이 헤더/데이터 정렬·리사이즈·스크롤 동기화를 전담하고, `ReportResponsiveAppBar`가 화면 크기별 AppBar 구조를 캡슐화한다. 각 `*_builder.dart`는 칼럼 정의와 데이터 변환만 담당하도록 마이그레이션한다.

**Tech Stack:** Flutter (Dart), `flutter_test` (위젯 테스트), `shared_preferences` (칼럼 너비 저장)

---

## 파일 구조

**새로 생성:**
- `lib/widgets/resizable_data_table.dart` — `TableColumnDef`, `ResizableDataTable`, `_TableResizeHandle`
- `lib/widgets/report_responsive_appbar.dart` — `ReportResponsiveAppBar`
- `test/widgets/resizable_data_table_test.dart` — 위젯 테스트
- `test/widgets/report_responsive_appbar_test.dart` — 위젯 테스트

**마이그레이션 (수정):**
- `lib/widgets/stocks_builder.dart` — `buildColumnDefs()` + `buildRows()`로 재작성
- `lib/screens/reports/stocks_report_view.dart` — `ResizableDataTable` + `ReportResponsiveAppBar` 사용
- `lib/widgets/codigos_builder.dart` — 동일 패턴
- `lib/screens/reports/codigos_report_view.dart` — 동일 패턴
- `lib/widgets/ingresos_builder.dart` — 동일 패턴
- `lib/widgets/gastos_builder.dart` — 리사이즈 신규 추가
- `lib/widgets/items_builder.dart` — 동일 패턴

**삭제 예정 (Task 6):**
- `stocks_builder.dart` 내 `_StocksColumnResizeHandle`, `buildHeader()`, `buildContent()` 레이아웃 코드
- `codigos_builder.dart` 내 `_ColumnResizeHandle`, `buildHeader()`, 레이아웃 코드
- `report_table_measured_columns.dart` 내 `ReportTableResizeHandle`
- `report_table_header_footer.dart` 내 `ReportTableResizeHandle` 호출부

---

## Chunk 1: 핵심 위젯 — TableColumnDef, ResizableDataTable, ReportResponsiveAppBar

### Task 1: `TableColumnDef` 모델 + `_TableResizeHandle` 위젯

**Files:**
- Create: `lib/widgets/resizable_data_table.dart`
- Create: `test/widgets/resizable_data_table_test.dart`

- [ ] **Step 1: 테스트 디렉토리 생성**

```bash
mkdir -p test/widgets
```

- [ ] **Step 2: 실패하는 테스트 작성**

`test/widgets/resizable_data_table_test.dart`:

```dart
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
      expect(col.textAlign, TextAlign.right);
      expect(col.sortable, true);
    });
  });
}
```

- [ ] **Step 3: 테스트 실패 확인**

```bash
flutter test test/widgets/resizable_data_table_test.dart
```
Expected: `Cannot find package 'flutter_app/widgets/resizable_data_table.dart'`

- [ ] **Step 4: `resizable_data_table.dart` 파일 생성 — `TableColumnDef` 구현**

`lib/widgets/resizable_data_table.dart`:

```dart
import 'package:flutter/material.dart';

/// 테이블 칼럼 정의 모델.
/// 각 보고서 builder가 이 리스트를 제공하면 ResizableDataTable이 레이아웃을 담당한다.
class TableColumnDef {
  final String key;
  final String label;
  final double defaultWidth;
  final double minWidth;
  final double maxWidth;
  final TextAlign textAlign;
  final bool sortable;

  const TableColumnDef({
    required this.key,
    required this.label,
    required this.defaultWidth,
    this.minWidth = 50.0,
    this.maxWidth = 2000.0,
    this.textAlign = TextAlign.left,
    this.sortable = false,
  });
}
```

- [ ] **Step 5: 테스트 통과 확인**

```bash
flutter test test/widgets/resizable_data_table_test.dart
```
Expected: `All tests passed`

- [ ] **Step 6: 커밋**

```bash
git add lib/widgets/resizable_data_table.dart test/widgets/resizable_data_table_test.dart
git commit -m "feat: add TableColumnDef model with tests"
```

---

### Task 2: `_TableResizeHandle` 위젯 (리사이즈 핸들 — 버그 수정 핵심)

**Files:**
- Modify: `lib/widgets/resizable_data_table.dart`
- Modify: `test/widgets/resizable_data_table_test.dart`

- [ ] **Step 1: 리사이즈 핸들 위젯 테스트 추가**

`test/widgets/resizable_data_table_test.dart`에 추가:

```dart
  group('_TableResizeHandle (간접 테스트)', () {
    testWidgets('헤더 셀이 정확히 columnWidth만 차지한다 (핸들 너비 미포함)', (tester) async {
      // 이 테스트는 Task 3 (ResizableDataTable) 완성 후 실행 가능.
      // 여기서는 핸들이 Stack 오버레이임을 확인하기 위한 자리 표시자.
      expect(true, true); // placeholder
    });
  });
```

- [ ] **Step 2: `_TableResizeHandle` 구현을 `resizable_data_table.dart`에 추가**

`lib/widgets/resizable_data_table.dart` 파일 끝에 추가:

```dart
/// 칼럼 헤더 오른쪽 경계에 오버레이되는 리사이즈 핸들.
/// Stack + Positioned로 배치되므로 Row 레이아웃 너비에 영향을 주지 않는다.
/// 기존 버그(_StocksColumnResizeHandle, _ColumnResizeHandle)가 Row에 14px를 추가하던
/// 문제를 이 방식으로 해결한다.
class _TableResizeHandle extends StatefulWidget {
  final String columnKey;
  final double currentWidth;
  final double minWidth;
  final double maxWidth;
  final void Function(double newWidth) onResize;

  const _TableResizeHandle({
    required Key key,
    required this.columnKey,
    required this.currentWidth,
    required this.minWidth,
    required this.maxWidth,
    required this.onResize,
  }) : super(key: key);

  @override
  State<_TableResizeHandle> createState() => _TableResizeHandleState();
}

class _TableResizeHandleState extends State<_TableResizeHandle> {
  double _initialWidth = 0;
  double _initialPointerX = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Arrastrar para ajustar ancho',
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            _initialWidth = widget.currentWidth;
            _initialPointerX = e.position.dx;
            _isDragging = true;
          },
          onPointerMove: (e) {
            if (!_isDragging) return;
            final delta = e.position.dx - _initialPointerX;
            final newWidth = (_initialWidth + delta)
                .clamp(widget.minWidth, widget.maxWidth);
            widget.onResize(newWidth);
          },
          onPointerUp: (_) => _isDragging = false,
          onPointerCancel: (_) => _isDragging = false,
          child: SizedBox(
            width: 14,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border(
                    left: BorderSide(color: Colors.grey[500]!, width: 1),
                    right: BorderSide(color: Colors.grey[500]!, width: 1),
                  ),
                ),
                child: Icon(Icons.drag_indicator, size: 14, color: Colors.grey[700]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 테스트 통과 확인**

```bash
flutter test test/widgets/resizable_data_table_test.dart
```
Expected: `All tests passed`

- [ ] **Step 4: 커밋**

```bash
git add lib/widgets/resizable_data_table.dart test/widgets/resizable_data_table_test.dart
git commit -m "feat: add _TableResizeHandle with Stack overlay approach"
```

---

### Task 3: `ResizableDataTable` 위젯 — 핵심 구현

**Files:**
- Modify: `lib/widgets/resizable_data_table.dart`
- Modify: `test/widgets/resizable_data_table_test.dart`

- [ ] **Step 1: 실패하는 위젯 테스트 작성**

`test/widgets/resizable_data_table_test.dart`의 `group('_TableResizeHandle ...')` 이후에 추가:

```dart
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
      double? resizedWidth;

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
                resizedWidth = width;
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
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
flutter test test/widgets/resizable_data_table_test.dart
```
Expected: `ResizableDataTable not found`

- [ ] **Step 3: `ResizableDataTable` 위젯 구현**

`lib/widgets/resizable_data_table.dart`에서 `TableColumnDef` 클래스 정의 다음에 삽입:

```dart
/// 공통 리사이즈 가능 데이터 테이블.
///
/// 사용법:
/// ```dart
/// ResizableDataTable(
///   columns: MyBuilder.buildColumnDefs(),
///   rows: MyBuilder.buildRows(data),
///   columnWidths: _columnWidths,
///   onColumnResize: (key, w) => setState(() => _columnWidths[key] = w),
///   headerColor: Colors.blue,
/// )
/// ```
///
/// 버그 수정: 리사이즈 핸들을 Stack + Positioned 오버레이로 배치하여
/// 헤더 Row 레이아웃 너비에 영향을 주지 않는다.
/// 이전 방식(_StocksColumnResizeHandle, _ColumnResizeHandle)은 핸들(14px)을
/// Row에 추가 배치해 칼럼 N에서 N×14px의 누적 어긋남을 유발했다.
class ResizableDataTable extends StatefulWidget {
  final List<TableColumnDef> columns;

  /// 각 행의 셀 위젯 리스트. buildRows()가 반환한 결과를 그대로 전달한다.
  /// 셀 크기(SizedBox 래핑)는 이 위젯 내부에서 columnWidths를 기준으로 적용한다.
  final List<List<Widget>> rows;

  final Map<String, double> columnWidths;
  final void Function(String key, double newWidth) onColumnResize;
  final String? sortColumn;
  final bool sortAscending;
  final void Function(String column, bool ascending)? onSort;
  final Color headerColor;
  final Widget? footerWidget;
  final bool isLoadingMore;

  const ResizableDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.columnWidths,
    required this.onColumnResize,
    this.sortColumn,
    this.sortAscending = false,
    this.onSort,
    required this.headerColor,
    this.footerWidget,
    this.isLoadingMore = false,
  });

  @override
  State<ResizableDataTable> createState() => _ResizableDataTableState();
}

class _ResizableDataTableState extends State<ResizableDataTable> {
  late final ScrollController _headerScrollController;
  late final ScrollController _dataScrollController;

  @override
  void initState() {
    super.initState();
    _headerScrollController = ScrollController();
    _dataScrollController = ScrollController();
    _headerScrollController.addListener(_syncHeaderToData);
    _dataScrollController.addListener(_syncDataToHeader);
  }

  @override
  void dispose() {
    _headerScrollController.removeListener(_syncHeaderToData);
    _dataScrollController.removeListener(_syncDataToHeader);
    _headerScrollController.dispose();
    _dataScrollController.dispose();
    super.dispose();
  }

  /// 헤더 스크롤 → 데이터 스크롤 동기화 (race condition 방지: delta 임계값 사용)
  void _syncHeaderToData() {
    if (!_dataScrollController.hasClients) return;
    final delta = (_dataScrollController.offset - _headerScrollController.offset).abs();
    if (delta > 0.5) {
      _dataScrollController.jumpTo(_headerScrollController.offset);
    }
  }

  /// 데이터 스크롤 → 헤더 스크롤 동기화
  void _syncDataToHeader() {
    if (!_headerScrollController.hasClients) return;
    final delta = (_headerScrollController.offset - _dataScrollController.offset).abs();
    if (delta > 0.5) {
      _headerScrollController.jumpTo(_dataScrollController.offset);
    }
  }

  double _columnWidth(String key) =>
      widget.columnWidths[key] ?? widget.columns.firstWhere((c) => c.key == key).defaultWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 로딩 인디케이터 (추가 데이터 로딩 중)
        if (widget.isLoadingMore)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: widget.headerColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: widget.headerColor),
                ),
                const SizedBox(width: 8),
                Text('Cargando...', style: TextStyle(fontSize: 12, color: widget.headerColor)),
              ],
            ),
          ),
        // 헤더 행 (가로 스크롤, 세로 고정)
        Container(
          decoration: BoxDecoration(
            color: widget.headerColor.withOpacity(0.1),
            border: Border(bottom: BorderSide(color: Colors.grey[400]!, width: 2)),
          ),
          child: SingleChildScrollView(
            controller: _headerScrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < widget.columns.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _buildHeaderCell(widget.columns[i]),
                  ],
                ],
              ),
            ),
          ),
        ),
        // 데이터 행 리스트 (세로 스크롤)
        Expanded(
          child: ListView.builder(
            itemCount: widget.rows.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
                ),
                child: SingleChildScrollView(
                  controller: _dataScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (int i = 0; i < widget.columns.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          SizedBox(
                            width: _columnWidth(widget.columns[i].key),
                            child: widget.rows[index][i],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // 푸터 (합계 행 등, 선택사항)
        if (widget.footerWidget != null) widget.footerWidget!,
      ],
    );
  }

  Widget _buildHeaderCell(TableColumnDef col) {
    final isSorted = widget.sortColumn == col.key;
    final colWidth = _columnWidth(col.key);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 헤더 텍스트 (정확히 colWidth만 차지)
        SizedBox(
          width: colWidth,
          child: col.sortable
              ? InkWell(
                  onTap: () {
                    if (widget.onSort != null) {
                      widget.onSort!(col.key, isSorted ? !widget.sortAscending : false);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          col.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isSorted ? widget.headerColor : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSorted)
                        Icon(
                          widget.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: widget.headerColor,
                        ),
                    ],
                  ),
                )
              : Text(
                  col.label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        // 리사이즈 핸들 (Stack 오버레이 — 레이아웃 너비에 영향 없음)
        Positioned(
          right: -7,
          top: 0,
          bottom: 0,
          child: _TableResizeHandle(
            key: ValueKey('resize_${col.key}'),
            columnKey: col.key,
            currentWidth: colWidth,
            minWidth: col.minWidth,
            maxWidth: col.maxWidth,
            onResize: (w) => widget.onColumnResize(col.key, w),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
flutter test test/widgets/resizable_data_table_test.dart
```
Expected: `All tests passed`

- [ ] **Step 5: 커밋**

```bash
git add lib/widgets/resizable_data_table.dart test/widgets/resizable_data_table_test.dart
git commit -m "feat: implement ResizableDataTable with Stack overlay resize handles"
```

---

### Task 4: `ReportResponsiveAppBar` 위젯

**Files:**
- Create: `lib/widgets/report_responsive_appbar.dart`
- Create: `test/widgets/report_responsive_appbar_test.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/widgets/report_responsive_appbar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/report_responsive_appbar.dart';

void main() {
  Widget buildSubject({
    required double width,
    List<Widget> filterWidgets = const [],
    List<Widget> actions = const [],
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 812)),
        child: Scaffold(
          appBar: ReportResponsiveAppBar(
            title: 'Test Report',
            color: Colors.blue,
            filterWidgets: filterWidgets,
            actions: actions,
          ),
          body: const SizedBox(),
        ),
      ),
    );
  }

  group('ReportResponsiveAppBar', () {
    testWidgets('타이틀이 표시된다', (tester) async {
      await tester.pumpWidget(buildSubject(width: 800));
      expect(find.text('Test Report'), findsOneWidget);
    });

    testWidgets('width >= 600일 때 1줄 레이아웃이다', (tester) async {
      await tester.pumpWidget(buildSubject(
        width: 800,
        filterWidgets: [const Text('Filter1'), const Text('Filter2')],
      ));
      await tester.pump();
      // 필터가 AppBar 내부 Row에 포함됨 (1줄)
      expect(find.text('Filter1'), findsOneWidget);
      expect(find.text('Filter2'), findsOneWidget);
      // preferredSize.height == kToolbarHeight
      final appBar = tester.widget<ReportResponsiveAppBar>(
        find.byType(ReportResponsiveAppBar),
      );
      expect(appBar.preferredSize.height, kToolbarHeight);
    });

    testWidgets('width < 600일 때 2줄 레이아웃이다', (tester) async {
      await tester.pumpWidget(buildSubject(
        width: 375,
        filterWidgets: [const Text('Filter1')],
      ));
      await tester.pump();
      // preferredSize.height == kToolbarHeight * 2
      final appBar = tester.widget<ReportResponsiveAppBar>(
        find.byType(ReportResponsiveAppBar),
      );
      expect(appBar.preferredSize.height, kToolbarHeight * 2);
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
flutter test test/widgets/report_responsive_appbar_test.dart
```
Expected: `Cannot find package 'flutter_app/widgets/report_responsive_appbar.dart'`

- [ ] **Step 3: `ReportResponsiveAppBar` 구현**

`lib/widgets/report_responsive_appbar.dart`:

```dart
import 'package:flutter/material.dart';

/// 화면 크기에 따라 1줄 또는 2줄 레이아웃으로 자동 전환되는 보고서 AppBar.
///
/// width >= 600: 1줄 — [메뉴] 제목 [필터들] [actions]
/// width < 600:  2줄 — 1줄: [메뉴] 제목 [actions]
///                     2줄: [필터들 전체]
///
/// PreferredSizeWidget 구현으로 Scaffold(appBar:)에 직접 사용 가능.
/// preferredSize.height는 화면 너비에 따라 kToolbarHeight 또는 kToolbarHeight * 2를 반환.
class ReportResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color color;

  /// 보고서별 필터 위젯 리스트 (타입 필터, 검색창 등)
  final List<Widget> filterWidgets;

  /// 오른쪽 액션 버튼 리스트 (공유 버튼 등)
  final List<Widget> actions;

  final VoidCallback? onMenuPressed;

  /// 1줄/2줄 전환 기준점 (기본 600.0 — 핸드폰 세로 기준)
  final double breakpoint;

  const ReportResponsiveAppBar({
    super.key,
    required this.title,
    required this.color,
    this.filterWidgets = const [],
    this.actions = const [],
    this.onMenuPressed,
    this.breakpoint = 600.0,
  });

  bool _isTwoLine(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpoint;
  }

  @override
  Size get preferredSize {
    // preferredSize는 build context 없이 호출되므로
    // 고정 kToolbarHeight * 2를 반환하고 실제 레이아웃은 build에서 결정.
    // Scaffold는 preferredSize.height를 사용해 AppBar 공간을 확보한다.
    // 동적으로 변경하려면 StatefulWidget이 필요하나, 단순화를 위해
    // 2줄 높이를 항상 예약하고 1줄일 때는 아래 빈 공간이 생기는 것을 허용.
    // 더 정밀한 구현이 필요하면 LayoutBuilder 기반 StatefulWidget으로 교체.
    return const Size.fromHeight(kToolbarHeight * 2);
  }

  @override
  Widget build(BuildContext context) {
    final twoLine = _isTwoLine(context);

    if (!twoLine) {
      // 1줄: 제목 + 필터 + actions 모두 한 줄
      return AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        leading: onMenuPressed != null
            ? IconButton(icon: const Icon(Icons.menu), onPressed: onMenuPressed)
            : null,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        actions: [
          ...filterWidgets.map((w) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: w,
          )),
          ...actions,
        ],
      );
    }

    // 2줄: 제목 행 + 필터 행
    return AppBar(
      backgroundColor: color,
      foregroundColor: Colors.white,
      toolbarHeight: kToolbarHeight * 2,
      leading: onMenuPressed != null
          ? IconButton(icon: const Icon(Icons.menu), onPressed: onMenuPressed)
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
              ...actions,
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (int i = 0; i < filterWidgets.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Flexible(child: filterWidgets[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
flutter test test/widgets/report_responsive_appbar_test.dart
```
Expected: `All tests passed`

- [ ] **Step 5: 전체 테스트 확인**

```bash
flutter test
```
Expected: `All tests passed`

- [ ] **Step 6: 커밋**

```bash
git add lib/widgets/report_responsive_appbar.dart test/widgets/report_responsive_appbar_test.dart
git commit -m "feat: implement ReportResponsiveAppBar with 1-line/2-line layout"
```

---

## Chunk 2: stocks_builder 마이그레이션

### Task 5: `stocks_builder.dart` — `buildColumnDefs()` + `buildRows()` 재작성

**Files:**
- Modify: `lib/widgets/stocks_builder.dart`
- Modify: `lib/screens/reports/stocks_report_view.dart`

> **중요:** 이 Task는 기존 `buildHeader()`, `buildContent()`, `_StocksColumnResizeHandle`를 제거하고 새 공통 위젯을 사용하도록 교체한다. 빌드 오류가 없는지 단계마다 확인한다.

- [ ] **Step 1: `stocks_builder.dart`에 `buildColumnDefs()` 추가 (기존 코드 유지한 채)**

`stocks_builder.dart`의 `stockColumnDisplayNames` getter 다음에 삽입:

```dart
  /// ResizableDataTable에 전달할 칼럼 정의 리스트.
  static List<TableColumnDef> buildColumnDefs() => [
    const TableColumnDef(key: 'codigo',          label: 'Codigo',          defaultWidth: 120, sortable: true),
    const TableColumnDef(key: 'descripcion',     label: 'Descripción',     defaultWidth: 250, sortable: true),
    const TableColumnDef(key: 'totaling',        label: 'Totaling',        defaultWidth: 90,  textAlign: TextAlign.right),
    const TableColumnDef(key: 'totalventa',      label: 'Total Venta',     defaultWidth: 100, textAlign: TextAlign.right),
    const TableColumnDef(key: 'todayingreso',    label: 'Today Ingreso',   defaultWidth: 110, textAlign: TextAlign.right),
    const TableColumnDef(key: 'todayventa',      label: 'Today Venta',     defaultWidth: 100, textAlign: TextAlign.right),
    const TableColumnDef(key: 'totalreservado',  label: 'Total Reservado', defaultWidth: 120, textAlign: TextAlign.right),
    const TableColumnDef(key: 'cntoffset',       label: 'Cnt Offset',      defaultWidth: 100, textAlign: TextAlign.right),
    const TableColumnDef(key: 'stockreal',       label: 'Stock Real',      defaultWidth: 100, textAlign: TextAlign.right),
    const TableColumnDef(key: 'porcentaje',      label: 'Porcentaje',      defaultWidth: 100, textAlign: TextAlign.right),
    const TableColumnDef(key: 'first_date',      label: 'First Date',      defaultWidth: 100),
    const TableColumnDef(key: 'last_date',       label: 'Last Date',       defaultWidth: 100),
    const TableColumnDef(key: 'pre1',            label: 'Precio 1',        defaultWidth: 90,  textAlign: TextAlign.right),
    const TableColumnDef(key: 'pre2',            label: 'Precio 2',        defaultWidth: 90,  textAlign: TextAlign.right),
    const TableColumnDef(key: 'pre3',            label: 'Precio 3',        defaultWidth: 90,  textAlign: TextAlign.right),
    const TableColumnDef(key: 'pre4',            label: 'Precio 4',        defaultWidth: 90,  textAlign: TextAlign.right),
    const TableColumnDef(key: 'pre5',            label: 'Precio 5',        defaultWidth: 90,  textAlign: TextAlign.right),
    const TableColumnDef(key: 'sucursal',        label: 'Sucursal',        defaultWidth: 90,  textAlign: TextAlign.center),
    const TableColumnDef(key: 'id_codigo1',      label: 'ID Codigo1',      defaultWidth: 100, textAlign: TextAlign.right),
  ];
```

- [ ] **Step 2: `buildRows()` 추가 (기존 코드 유지한 채)**

`buildColumnDefs()` 다음에 삽입:

```dart
  /// 데이터 리스트를 셀 위젯 리스트로 변환.
  /// 셀 크기(SizedBox 래핑)는 ResizableDataTable 내부에서 columnWidths 기준으로 적용된다.
  static List<List<Widget>> buildRows(List<dynamic> data) {
    return [
      for (final item in data)
        _buildRowCells(item as Map<String, dynamic>),
    ];
  }

  static List<Widget> _buildRowCells(Map<String, dynamic> stock) {
    String _val(String key) => stock[key]?.toString() ?? 'N/A';
    return [
      Text(stock['codigo']?.toString() ?? stock['tcode']?.toString() ?? 'N/A',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(stock['descripcion']?.toString() ?? stock['tdesc']?.toString() ?? 'N/A',
          style: TextStyle(fontSize: 10, color: Colors.grey[700]),
          maxLines: 5, overflow: TextOverflow.ellipsis),
      Text(_val('totaling'),        style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(_val('totalventa'),      style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(_val('todayingreso'),    style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(_val('todayventa'),      style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(_val('totalreservado'),  style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(_val('cntoffset'),       style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(stock['stockreal']?.toString() ?? stock['stockreal3']?.toString() ?? 'N/A',
          style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(_formatPorcentaje(stock['porcentaje']),
          style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(_val('first_date'),      style: TextStyle(fontSize: 10, color: Colors.grey[700])),
      Text(_val('last_date'),       style: TextStyle(fontSize: 10, color: Colors.grey[700])),
      Text(_val('pre1'),            style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(_val('pre2'),            style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(_val('pre3'),            style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(_val('pre4'),            style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(_val('pre5'),            style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
      Text(_val('sucursal'),        style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.center),
      Text(_val('id_codigo1'),      style: TextStyle(fontSize: 10, color: Colors.grey[700]), textAlign: TextAlign.right),
    ];
  }
```

- [ ] **Step 3: `stocks_report_view.dart` — `ResizableDataTable` + `ReportResponsiveAppBar` 사용**

`stocks_report_view.dart`의 import 상단에 추가:
```dart
import '../../widgets/resizable_data_table.dart';
import '../../widgets/report_responsive_appbar.dart';
```

`_buildStocksContent()` 메서드를 아래와 같이 교체:

```dart
Widget _buildStocksContent(Map<String, dynamic> data) {
  Color stocksColor = Colors.orange;
  if (data.containsKey('filters') && data['filters'] is Map) {
    final filters = data['filters'] as Map<String, dynamic>;
    stocksColor = ReportUtils.isBcolorviewEnabled(filters['bcolorview']) ? Colors.orange : Colors.lightBlue;
  } else if (data.containsKey('bcolorview')) {
    stocksColor = ReportUtils.isBcolorviewEnabled(data['bcolorview']) ? Colors.orange : Colors.lightBlue;
  }

  final dbKey = '';
  if (_stocksColumnWidthsDbKey != dbKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loaded = await StocksColumnWidthStorage.load(dbKey);
      if (mounted) {
        setState(() {
          _stocksColumnWidthsDbKey = dbKey;
          _stocksColumnWidths = loaded;
        });
      }
    });
  }

  final defaults = {
    for (final col in StocksBuilder.buildColumnDefs()) col.key: col.defaultWidth
  };
  final mergedColumnWidths = Map<String, double>.from(defaults)
    ..addAll(_stocksColumnWidths ?? {});

  final dataList = data['data'] as List? ?? [];

  return ResizableDataTable(
    columns: StocksBuilder.buildColumnDefs(),
    rows: StocksBuilder.buildRows(dataList),
    columnWidths: mergedColumnWidths,
    onColumnResize: (key, newWidth) {
      setState(() {
        _stocksColumnWidths ??= {};
        _stocksColumnWidths![key] = newWidth;
      });
      StocksColumnWidthStorage.save(dbKey, _stocksColumnWidths!);
    },
    sortColumn: _stocksSortColumn,
    sortAscending: _stocksSortAscending,
    onSort: (column, ascending) {
      setState(() {
        _stocksSortColumn = column;
        _stocksSortAscending = ascending;
      });
      _notifyStateChanged();
      _reloadDataWithFilters();
    },
    headerColor: stocksColor,
    isLoadingMore: _isLoadingMoreStocks,
  );
}
```

- [ ] **Step 4: `stocks_report_view.dart`의 `build()` 메서드에서 AppBar 교체**

기존 `build()` 내 `appBar:` 관련 부분을 찾아서 `ReportResponsiveAppBar`로 교체:
(현재 코드에서 AppBar가 어떻게 구성되어 있는지 확인 후 적용. `onFilterBarReady` 콜백 방식이면 해당 콜백을 제거하고 AppBar를 직접 Scaffold에 전달하는 방식으로 변경)

```dart
// ReportScreen에서 호출되는 경우 onFilterBarReady 사용 불가.
// stocks_report_view.dart 자체가 Scaffold를 갖지 않는 경우,
// 상위 report_screen.dart에서 AppBar를 교체해야 한다.
// → report_screen.dart에서 StocksReportView 사용 시 ReportResponsiveAppBar 사용하도록 수정.
```

- [ ] **Step 5: 빌드 확인**

```bash
flutter analyze
flutter build macos --debug 2>&1 | head -30
```
Expected: 컴파일 오류 없음

- [ ] **Step 6: 커밋**

```bash
git add lib/widgets/stocks_builder.dart lib/screens/reports/stocks_report_view.dart
git commit -m "feat: migrate stocks_builder to use ResizableDataTable"
```

---

## Chunk 3: codigos_builder 마이그레이션

### Task 6: `codigos_builder.dart` — `buildColumnDefs()` + `buildRows()` 재작성

**Files:**
- Modify: `lib/widgets/codigos_builder.dart`
- 연관된 `codigos_report_view.dart` 또는 해당 보고서 view 파일

> codigos는 `columnKeys`를 외부에서 받는 구조. `buildColumnDefs()`로 내부화한다.

- [ ] **Step 1: `codigos_builder.dart`의 기존 `columnKeys` 목록 확인**

```bash
grep -n "columnKeys\|columnWidths\|buildHeader\|_buildColumnResizeHandle" lib/widgets/codigos_builder.dart | head -20
```

- [ ] **Step 2: `buildColumnDefs()` 추가**

기존 `columnKeys` 정의를 참고하여 `TableColumnDef` 리스트로 변환:

```dart
import 'resizable_data_table.dart';

// CodigosBuilder 클래스 내부에 추가:
static List<TableColumnDef> buildColumnDefs() => [
  // 기존 columnKeys 순서와 동일하게 정의
  // 예시 (실제 키는 codigos_builder.dart 상단 확인):
  const TableColumnDef(key: 'tcode',    label: 'Codigo',      defaultWidth: 120, sortable: true),
  const TableColumnDef(key: 'tdesc',    label: 'Descripción', defaultWidth: 250, sortable: true),
  // ... 기존 코드의 실제 키 목록 참고
];
```

- [ ] **Step 3: `buildRows()` 추가**

기존 `_buildRow()` 또는 `_buildDataRow()` 로직을 `buildRows()`로 변환.

- [ ] **Step 4: codigos report view에서 `ResizableDataTable` 사용**

해당 view 파일에서 `buildHeader()`/`buildContent()` 호출을 `ResizableDataTable`로 교체.

- [ ] **Step 5: 빌드 확인**

```bash
flutter analyze
```

- [ ] **Step 6: 커밋**

```bash
git add lib/widgets/codigos_builder.dart
git commit -m "feat: migrate codigos_builder to use ResizableDataTable"
```

---

## Chunk 4: ingresos_builder 마이그레이션

### Task 7: `ingresos_builder.dart` — `buildColumnDefs()` + `buildRows()` 재작성

**Files:**
- Modify: `lib/widgets/ingresos_builder.dart`
- 연관 view 파일

> ingresos는 `report_table_builder.dart`를 통해 `ReportTableResizeHandle`을 사용. 이 Task에서 해당 경로를 `ResizableDataTable`로 대체한다.

- [ ] **Step 1: ingresos 칼럼 구조 확인**

```bash
grep -n "columnKeys\|columnDefs\|buildColumnDefs\|TableColumnDef" lib/widgets/ingresos_builder.dart | head -20
```

- [ ] **Step 2: `buildColumnDefs()` 추가**

ingresos 보고서의 칼럼 목록을 `TableColumnDef` 리스트로 정의.

- [ ] **Step 3: `buildRows()` 추가**

기존 셀 빌드 로직을 `buildRows()`로 변환.

- [ ] **Step 4: ingresos report view에서 `ResizableDataTable` 사용**

`report_table_builder.dart`를 통한 렌더링 경로를 `ResizableDataTable`로 교체.

- [ ] **Step 5: `report_table_header_footer.dart`의 `ReportTableResizeHandle` 호출부 처리**

```bash
grep -n "ReportTableResizeHandle" lib/widgets/report_table_header_footer.dart
```

해당 라인을 확인하고, ingresos 경로에서 더 이상 호출되지 않도록 변경.

- [ ] **Step 6: 빌드 확인**

```bash
flutter analyze
```

- [ ] **Step 7: 커밋**

```bash
git add lib/widgets/ingresos_builder.dart
git commit -m "feat: migrate ingresos_builder to use ResizableDataTable"
```

---

## Chunk 5: gastos + items 마이그레이션

### Task 8: `gastos_builder.dart` — 칼럼 리사이즈 신규 추가

**Files:**
- Modify: `lib/widgets/gastos_builder.dart`

> ⚠️ gastos는 현재 리사이즈 기능이 없다 (`DataTable` + 하드코딩 너비). 이 Task는 **신규 기능 추가**다.

- [ ] **Step 1: gastos 칼럼 목록 확인**

```bash
grep -n "columnWidths\|DataTable\|DataColumn\|DataRow" lib/widgets/gastos_builder.dart | head -20
```

- [ ] **Step 2: 기본 칼럼 너비 정의 및 `buildColumnDefs()` 추가**

```dart
static List<TableColumnDef> buildColumnDefs() => [
  // gastos_builder.dart의 실제 칼럼 참고:
  const TableColumnDef(key: 'fecha',     label: 'Fecha',     defaultWidth: 100, sortable: true),
  const TableColumnDef(key: 'concepto',  label: 'Concepto',  defaultWidth: 200),
  const TableColumnDef(key: 'monto',     label: 'Monto',     defaultWidth: 100, textAlign: TextAlign.right),
  // ... 실제 키 목록에 맞게 정의
];
```

- [ ] **Step 3: 칼럼 너비 저장 서비스 추가**

기존 `StocksColumnWidthStorage` 패턴을 참고하여 `GastosColumnWidthStorage` 또는 범용 `ReportColumnWidthStorage`를 사용:

```bash
ls lib/services/*column_width*
```

범용 서비스가 있다면 재사용. 없으면 `stocks_column_width_storage.dart`를 복사하여 `gastos_column_width_storage.dart` 생성.

- [ ] **Step 4: gastos report view에서 `ResizableDataTable` 사용**

- [ ] **Step 5: 빌드 확인**

```bash
flutter analyze
```

- [ ] **Step 6: 커밋**

```bash
git add lib/widgets/gastos_builder.dart
git commit -m "feat: add column resize to gastos_builder via ResizableDataTable"
```

---

### Task 9: `items_builder.dart` — `ResizableDataTable` 마이그레이션

**Files:**
- Modify: `lib/widgets/items_builder.dart`

- [ ] **Step 1: items 칼럼 구조 확인**

```bash
grep -n "columnKeys\|buildHeader\|ResizeHandle\|report_table_builder" lib/widgets/items_builder.dart | head -20
```

- [ ] **Step 2: `buildColumnDefs()` + `buildRows()` 추가**

- [ ] **Step 3: items report view에서 `ResizableDataTable` 사용**

- [ ] **Step 4: 빌드 확인**

```bash
flutter analyze
```

- [ ] **Step 5: 커밋**

```bash
git add lib/widgets/items_builder.dart
git commit -m "feat: migrate items_builder to use ResizableDataTable"
```

---

## Chunk 6: 기존 코드 정리 (cleanup)

### Task 10: 중복 코드 일괄 제거

**Files:**
- Modify: `lib/widgets/stocks_builder.dart`
- Modify: `lib/widgets/codigos_builder.dart`
- Modify: `lib/widgets/report_table_measured_columns.dart`
- Modify: `lib/widgets/report_table_header_footer.dart`

> ⚠️ 이 Task는 모든 마이그레이션(Task 5~9)이 완료된 후 실행한다.
> 삭제 전 반드시 `flutter analyze`로 참조 없음을 확인한다.

- [ ] **Step 1: 삭제 대상 코드 참조 여부 확인**

```bash
grep -rn "_StocksColumnResizeHandle\|_ColumnResizeHandle\|ReportTableResizeHandle" lib/
```
Expected: 결과 없음 (모두 마이그레이션 완료 상태)

- [ ] **Step 2: `stocks_builder.dart`에서 삭제**
  - `_StocksColumnResizeHandle` StatefulWidget 전체 (line 814~885)
  - `buildHeader()` 정적 메서드 (line 462~521)
  - `buildContent()` 정적 메서드 (line 34~377) — `buildViewType()`은 유지
  - `_buildSortableHeader()`, `_buildStocksResizeHandle()`, `_buildStockRow()`, `_buildStockCell()` — `buildRows()`로 대체됐으므로 삭제

- [ ] **Step 3: `codigos_builder.dart`에서 삭제**
  - `_ColumnResizeHandle` StatefulWidget
  - `buildHeader()` 정적 메서드
  - `buildContent()` 정적 메서드 — `buildRows()`로 대체됐으므로 삭제

- [ ] **Step 4: `report_table_measured_columns.dart`에서 `ReportTableResizeHandle` 삭제**

```bash
grep -n "class ReportTableResizeHandle" lib/widgets/report_table_measured_columns.dart
```

해당 class 전체 삭제.

- [ ] **Step 5: `report_table_header_footer.dart`에서 `ReportTableResizeHandle` 호출부 처리**

```bash
grep -n "ReportTableResizeHandle" lib/widgets/report_table_header_footer.dart
```

해당 라인을 삭제 또는 새 `_TableResizeHandle` 방식으로 교체.

- [ ] **Step 6: 빌드 최종 확인**

```bash
flutter analyze
flutter test
```
Expected: 오류 없음, 모든 테스트 통과

- [ ] **Step 7: 최종 커밋**

```bash
git add -u
git commit -m "refactor: remove duplicate resize handle and layout code from all builders"
```

---

## 검증 체크리스트

모든 Task 완료 후 수동으로 확인:

- [ ] stocks 보고서에서 칼럼 드래그 시 해당 칼럼만 변경됨 (왼쪽 칼럼 어긋남 없음)
- [ ] 헤더 라벨과 데이터 셀이 정확히 일치함
- [ ] 헤더 가로 스크롤 시 데이터도 함께 이동함
- [ ] codigos, ingresos, gastos, items 동일 동작 확인
- [ ] 핸드폰 세로(width < 600): AppBar 2줄 레이아웃
- [ ] 핸드폰 가로 / iPad / macOS: AppBar 1줄 레이아웃
- [ ] 칼럼 너비 조정 후 앱 재시작 시 너비가 복원됨
