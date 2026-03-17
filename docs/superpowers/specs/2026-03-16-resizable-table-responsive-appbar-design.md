# 설계 문서: ResizableDataTable + ReportResponsiveAppBar

**날짜:** 2026-03-16
**프로젝트:** flutter_aguila
**범위:** 보고서 테이블 공통 위젯 재설계 + AppBar 반응형 구조

---

## 배경 및 문제

### 현재 버그: 칼럼 리사이즈 시 레이아웃 붕괴

`stocks_builder.dart`, `codigos_builder.dart`, `ingresos_builder.dart` 등 각 보고서 builder가 독립적으로 리사이즈 핸들을 구현하고 있으며, 동일한 구조적 버그를 공유한다.

**버그 원인:** 리사이즈 핸들(14px)이 헤더 Row 안에 나란히 배치되어 있어 레이아웃 너비를 차지한다. 데이터 행에는 핸들이 없으므로 칼럼 N에서 `N × 14px`의 누적 어긋남이 발생한다.

```
헤더: [Header_0 (120px)][Handle_0 (14px)][8px][Header_1 (250px)][Handle_1 (14px)]
데이터: [Cell_0 (120px)][8px][Cell_1 (250px)]
                                  ↑ 14px씩 어긋남 누적
```

로그에서도 확인됨: `Row 실제 width: 1885.8, expected: 1865.8` → 20px 초과 (핸들 2개 × 14px ≈ 20px).

### 추가 문제

1. **코드 중복:** 리사이즈 핸들 StatefulWidget이 세 곳에 복제됨:
   - `_StocksColumnResizeHandle` — `stocks_builder.dart`
   - `_ColumnResizeHandle` — `codigos_builder.dart`
   - `ReportTableResizeHandle` (public) — `report_table_measured_columns.dart` (items/ingresos용, 이미 Stack/Positioned 방식에 가깝지만 독립적으로 존재)
2. **헤더-데이터 스크롤 미동기화:** 헤더의 `SingleChildScrollView`와 데이터 행의 스크롤이 연동되지 않음
3. **AppBar 레이아웃 분기:** 각 `*_report_view.dart`에서 화면 크기별 분기 로직이 중복됨
4. **파일 비대화:** `report_table_builder.dart` 3,438줄, `items_builder.dart` 2,009줄 등 단일 책임 원칙 위반

---

## 목표

1. 리사이즈 버그를 한 곳에서 수정하여 모든 보고서에 적용
2. 헤더와 데이터 행의 칼럼 너비 완벽 일치
3. 가로/세로 스크롤 올바른 동기화
4. 화면 크기(대형화면, 핸드폰 가로, 핸드폰 세로)별 AppBar 캡슐화
5. 각 builder 파일을 "칼럼 정의 + 데이터 변환"만 담당하도록 경량화

---

## 설계

### 새로 생성할 파일

```
lib/widgets/
  resizable_data_table.dart       ← 공통 테이블 위젯
  report_responsive_appbar.dart   ← 공통 AppBar 위젯
```

### 책임 분리

| 담당 | 역할 |
|---|---|
| `ResizableDataTable` | 헤더/데이터 정렬, 리사이즈 핸들(Stack 오버레이), 가로+세로 스크롤 동기화 |
| `ReportResponsiveAppBar` | 화면 크기에 따른 1줄/2줄/3줄 AppBar 자동 전환 |
| 각 `*_builder.dart` | `TableColumnDef` 리스트 제공, 데이터를 셀 위젯 리스트로 변환 |
| 각 `*_report_view.dart` | 데이터 로딩, 필터 상태, 칼럼 너비 저장/불러오기 |

---

## 컴포넌트 상세

### 1. `TableColumnDef` — 칼럼 정의 모델

```dart
class TableColumnDef {
  final String key;           // 저장/정렬 키
  final String label;         // 헤더 표시 텍스트
  final double defaultWidth;  // 기본 너비
  final double minWidth;      // 최소 너비 (기본 50.0)
  final double maxWidth;      // 최대 너비 (기본 2000.0)
  final TextAlign textAlign;  // 셀 정렬 (기본 TextAlign.left)
  final bool sortable;        // 정렬 가능 여부 (기본 false)
}
```

### 2. `ResizableDataTable` — 공통 테이블 위젯

**인터페이스:**

```dart
class ResizableDataTable extends StatefulWidget {
  final List<TableColumnDef> columns;
  final List<List<Widget>> rows;        // columnWidths를 받지 않음 — 셀 내용은 너비와 무관
  final Map<String, double> columnWidths;
  final void Function(String key, double newWidth) onColumnResize;
  final String? sortColumn;
  final bool sortAscending;
  final void Function(String column, bool ascending)? onSort;
  final Color headerColor;
  final Widget? footerWidget;
  final bool isLoadingMore;
}
```

> **참고:** `buildRows()`는 `columnWidths`를 파라미터로 받지 않는다. 셀 위젯의 크기 적용은 `ResizableDataTable` 내부에서 `SizedBox(width: columnWidths[col.key])` 래퍼로 처리한다. 셀 내용이 너비 값을 직접 필요로 하는 특수한 경우(예: 동적 truncation)만 예외적으로 builder에서 처리한다.

**내부 레이아웃 구조:**

```
ResizableDataTable (StatefulWidget)
├── Column
│   ├── _HeaderRow (세로 고정, 가로 스크롤)
│   │   └── SingleChildScrollView (headerScrollController)
│   │       └── Row
│   │           └── [Stack(헤더텍스트 + Positioned 핸들), 8px 간격, ...]
│   │
│   ├── Expanded
│   │   └── ListView.builder (세로 스크롤)
│   │       └── 각 행: SingleChildScrollView (dataScrollController)
│   │           └── Row: [SizedBox(width) > Cell, 8px, ...]
│   │
│   └── footerWidget (선택, 고정 최하단)
```

**라이프사이클 관리:**

```dart
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
```

**리사이즈 핸들 — Stack 오버레이 방식 (버그 수정 핵심):**

```dart
Stack(
  clipBehavior: Clip.none,
  children: [
    SizedBox(
      width: columnWidth,
      child: headerCell,           // 레이아웃 너비 = columnWidth 만 차지
    ),
    Positioned(
      right: -7,                   // 오른쪽 경계에 걸쳐 표시
      top: 0, bottom: 0,
      child: _ResizeHandle(        // 레이아웃에 영향 없음
        width: 14,
        onResize: ...,
      ),
    ),
  ],
)
```

이로써 헤더 Row의 각 칼럼이 정확히 `columnWidth`만 차지하여 데이터 행과 일치.

**헤더-데이터 가로 스크롤 동기화 (race condition 방지):**

bool 플래그 방식은 `jumpTo`가 같은 call stack에서 반대 리스너를 즉시 실행해 가드가 무력화되는 문제가 있다.
대신 **오프셋 차이 임계값** 방식을 사용한다:

```dart
void _syncHeaderToData() {
  if (!_dataScrollController.hasClients) return;
  final delta = (_dataScrollController.offset - _headerScrollController.offset).abs();
  if (delta > 0.5) {
    _dataScrollController.jumpTo(_headerScrollController.offset);
  }
}

void _syncDataToHeader() {
  if (!_headerScrollController.hasClients) return;
  final delta = (_headerScrollController.offset - _dataScrollController.offset).abs();
  if (delta > 0.5) {
    _headerScrollController.jumpTo(_dataScrollController.offset);
  }
}
```

임계값 0.5px는 기존 `report_table_builder.dart`의 0.1px 가드 방식을 참고하되, 더 보수적인 값으로 설정하여 불필요한 재동기화를 줄인다.

### 3. `ReportResponsiveAppBar` — 반응형 AppBar

**인터페이스:**

```dart
class ReportResponsiveAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final Color color;
  final List<Widget> filterWidgets;  // 필터 위젯 리스트 (각 보고서 제공)
  final List<Widget> actions;        // 공유 버튼 등
  final VoidCallback? onMenuPressed;
  final double largeScreenBreakpoint; // 기본 800.0 (기존 코드와 일치)
}
```

**레이아웃 동작 (3단계):**

```
width ≥ 800 (대형화면 / iPad):
┌──────────────────────────────────────────────────┐
│ [메뉴] 보고서 제목   [필터A] [필터B] [검색창] [공유] │
└──────────────────────────────────────────────────┘
preferredSize.height = kToolbarHeight

600 ≤ width < 800 (핸드폰 가로):
┌──────────────────────────────────────────────────┐
│ [메뉴] 보고서 제목   [필터A] [필터B] [검색창] [공유] │
└──────────────────────────────────────────────────┘
preferredSize.height = kToolbarHeight  (1줄, 공간 좁아짐)

width < 600 (핸드폰 세로):
┌──────────────────────────────────────────────────┐
│ [메뉴] 보고서 제목                           [공유] │
│ [필터A] [필터B]  [──────────검색창──────────]       │
└──────────────────────────────────────────────────┘
preferredSize.height = kToolbarHeight * 2
```

> 기존 코드(`report_screen.dart`, `stocks_report_view.dart`)의 800px 기준을 유지한다. 600px 미만만 2줄로 전환. `largeScreenBreakpoint` 기본값 = 800.0.

`PreferredSizeWidget` 구현으로 `Scaffold(appBar:)` 에 직접 사용 가능. `preferredSize.height`는 현재 화면 너비에 따라 `kToolbarHeight` 또는 `kToolbarHeight * 2`를 반환한다 (`LayoutBuilder` 또는 `MediaQuery` 사용).

---

## 마이그레이션 전략

### 단계별 순서

| 단계 | 작업 | 성격 |
|---|---|---|
| 1 | `TableColumnDef`, `ResizableDataTable`, `ReportResponsiveAppBar` 신규 작성 | 신규 (기존 코드 무변경) |
| 2 | `stocks_builder` → `buildColumnDefs()` + `buildRows()` 재작성, `StocksReportView` AppBar 교체 | 리팩토링 |
| 3 | `codigos_builder` 마이그레이션 | 리팩토링 |
| 4 | `ingresos_builder` 마이그레이션 (`ReportTableResizeHandle` 대체 포함) | 리팩토링 |
| 5a | `gastos_builder` 마이그레이션 — **칼럼 리사이즈 신규 기능 추가** (기본 너비 정의 필요) | 신규 기능 |
| 5b | `items_builder` 마이그레이션 (`report_table_builder.dart`의 관련 코드 대체) | 리팩토링 |
| 6 | 기존 중복 코드 일괄 제거 | 정리 |

> **5a 주의:** `gastos_builder`는 현재 리사이즈 기능이 없다(`DataTable` + 하드코딩 너비). 마이그레이션 시 칼럼 기본 너비와 저장 키를 새로 정의해야 한다. 이는 리팩토링이 아닌 **신규 기능 추가**다.

각 단계는 독립적이며, 한 보고서씩 검증하며 진행 가능.

### 마이그레이션 후 각 builder의 구조 (stocks 예시)

```dart
class StocksBuilder {
  // 칼럼 정의만 담당
  static List<TableColumnDef> buildColumnDefs() => [
    TableColumnDef(key: 'codigo',   label: 'Código',  defaultWidth: 120, sortable: true),
    TableColumnDef(key: 'descrip',  label: 'Descrip', defaultWidth: 200, sortable: true),
    TableColumnDef(key: 'stock_s1', label: 'S1',      defaultWidth: 60,  textAlign: TextAlign.right),
    // ...
  ];

  // 데이터를 셀 위젯 리스트로 변환 (너비 적용은 ResizableDataTable이 담당)
  static List<List<Widget>> buildRows(List<Map<String, dynamic>> data) => [
    for (final item in data) [
      Text(item['codigo'] ?? ''),
      Text(item['descrip'] ?? ''),
      Text('${item['stock_s1'] ?? 0}'),
      // ...
    ]
  ];
}
```

### 삭제될 코드 (정리 효과 예상)

- `_StocksColumnResizeHandle` StatefulWidget — `stocks_builder.dart`
- `_ColumnResizeHandle` StatefulWidget — `codigos_builder.dart`
- `ReportTableResizeHandle` (public) — `report_table_measured_columns.dart`
- `ReportTableResizeHandle` 호출부 — `report_table_header_footer.dart` (해당 라인 제거 또는 교체)
- 각 builder의 `buildHeader()` 정적 메서드
- 각 builder의 `SingleChildScrollView` + Row 레이아웃 코드
- 각 `*_report_view.dart`의 AppBar 크기별 분기 로직

예상 결과: `stocks_builder.dart` 885줄 → ~250줄, `codigos_builder.dart` 1,008줄 → ~300줄

---

## 데이터 흐름

```
*_report_view.dart
  ├── 데이터 로딩 (API)
  ├── 필터 상태 관리
  ├── columnWidths 상태 (load/save via *ColumnWidthStorage)
  ├── ReportResponsiveAppBar(filterWidgets: [...], actions: [...])
  └── ResizableDataTable(
        columns: XxxBuilder.buildColumnDefs(),
        rows: XxxBuilder.buildRows(data),       // columnWidths 미전달
        columnWidths: columnWidths,             // 너비는 테이블이 내부 적용
        onColumnResize: (key, w) => setState + save,
      )
```

---

## 에러 처리

- 칼럼 너비 저장 실패 시 기본값으로 조용히 폴백 (기존 `StocksColumnWidthStorage` 방식 유지)
- 데이터 행 수가 0인 경우 빈 상태 위젯 표시 (각 report view가 담당)
- 리사이즈 중 최소/최대 너비 클램핑은 `ResizableDataTable` 내부에서 처리
- `ScrollController`가 아직 클라이언트에 연결되지 않은 경우 `hasClients` 가드로 방어

---

## 테스트 전략

- `ResizableDataTable` 위젯 테스트: 칼럼 너비 변경 시 헤더/데이터 너비 일치 확인
- `ReportResponsiveAppBar` 위젯 테스트: 800px / 600px 기준 레이아웃 전환 확인
- 각 보고서 마이그레이션 후 수동 검증: 리사이즈, 정렬, 스크롤 동기화
- `gastos_builder` 마이그레이션 후 칼럼 너비 저장/불러오기 동작 확인
