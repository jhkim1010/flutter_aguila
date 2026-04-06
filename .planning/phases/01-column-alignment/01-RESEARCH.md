# Phase 1: Column Alignment - Research

**Researched:** 2026-04-05
**Domain:** Flutter 테이블 칼럼 정렬 — ScrollController 동기화, 단일 상태 칼럼 폭 관리, 리사이즈 핸들
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** 기존 테이블 위젯(ReportTableMeasuredColumns, StocksBuilder, ReportTableHeaderFooter, ReportTableDataRows) 수정 — 새로운 통합 위젯으로 교체하지 않음
- **D-02:** Stocks 리포트 전용 수정 — 공용 테이블 위젯에서 수정하되 Stocks에서만 검증. 다른 리포트 확장은 ALIGN-04(v2)
- **D-03:** 칼럼 폭을 단일 상태(Single source of truth)로 관리 — 헤더와 데이터 행이 동일한 폭 목록을 참조하여 불일치 근본 원인 제거
- **D-04:** StocksColumnWidthStorage를 통한 폭 persist 유지 — 기존 저장 메커니즘 활용
- **D-05:** 가로 스크롤: 헤더와 데이터 행이 동일한 ScrollController를 공유하여 x 오프셋 동기화
- **D-06:** 세로 스크롤: 고정 헤더 패턴 유지 — 데이터 행만 세로 스크롤, 헤더는 상단 고정
- **D-07:** 칼럼 리사이즈 시 헤더와 데이터 행 폭이 단일 상태를 통해 동시 업데이트 — setState 또는 동등한 상태 전파 메커니즘 사용

### Claude's Discretion

- 기존 ReportTableMeasuredColumns vs StocksBuilder 내 리사이즈 핸들 통합/분리 판단
- ScrollController 공유 구현 세부 방식 (위젯 트리 구조)
- 기존 코드 리팩토링 범위 (최소 변경 원칙 내에서)

### Deferred Ideas (OUT OF SCOPE)

- ALIGN-04: Ventas, Items, Gastos 리포트에도 동일 칼럼 정렬 로직 적용 → v2
- ALIGN-05: 칼럼 폭 자동 계산 (콘텐츠 기반) → v2
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ALIGN-01 | Stocks 리포트 헤더와 행의 칼럼 폭이 완벽히 일치하여 표시 | ResizableDataTable이 이미 단일 columnWidths 맵을 헤더·행 양쪽에 적용하는 구조 확인. 현재 코드가 이 요구사항을 구조적으로 지원하고 있으나 실제 일치 여부 검증 필요 |
| ALIGN-02 | 칼럼 리사이즈 후에도 헤더/행 폭이 동기화 유지 | onColumnResize → setState(_stocksColumnWidths) → ResizableDataTable rebuild → 헤더·행 모두 같은 columnWidths 사용 경로 확인. 단일 상태 구조 이미 존재 |
| ALIGN-03 | 가로/세로 스크롤 시 헤더 위치가 데이터 행과 정확히 동기화 | ResizableDataTable 내부에 _headerScrollController + _dataScrollController 리스너 쌍 존재. 그러나 StocksReportView._scrollController와의 연동 누락 확인 |
</phase_requirements>

---

## Summary

이 Phase의 핵심 도전은 새로운 아키텍처 구축이 아니라 **이미 존재하는 ResizableDataTable의 정렬 메커니즘이 실제로 올바르게 작동하고 있는지 진단하고 빠진 연결고리를 찾아 수정하는 것**이다.

코드 분석 결과: `ResizableDataTable` (`lib/widgets/resizable_data_table.dart`)은 이미 D-03, D-05, D-06, D-07의 요구사항을 구조적으로 지원한다. 헤더와 데이터 행 모두 동일한 `columnWidths` 맵을 참조하고, `_headerScrollController`와 `_dataScrollController` 간 listener 기반 동기화가 구현되어 있으며, 리사이즈 핸들은 Stack + Positioned 오버레이로 레이아웃 폭에 영향을 주지 않는 구조다. 그러나 `StocksReportView`에서 외부 `_scrollController`를 `ResizableDataTable.scrollController`에 전달하지 않아 세로 스크롤 제어가 분리된 상태일 수 있다.

**Primary recommendation:** `ResizableDataTable`의 현재 구현이 이미 올바른 구조를 갖추고 있으므로, 실제 정렬 불일치 재현 → 원인 진단 → 최소 수정 순서로 접근한다. 주요 수정 지점은 (1) `_totalContentWidth()`가 헤더와 데이터 영역에 동일하게 적용되는지 확인, (2) `StocksReportView`가 `scrollController`를 `ResizableDataTable`에 전달하는지 확인, (3) 리사이즈 후 `_totalContentWidth()`가 즉시 재계산되는지 확인이다.

---

## Standard Stack

### Core (이미 프로젝트에 설치됨)

| 라이브러리 | 버전 | 목적 | 비고 |
|---------|---------|---------|--------------|
| Flutter SDK | latest stable | UI 프레임워크 | 이미 설치 |
| Dart SDK | 3.0.0+ | 언어 런타임 | 이미 설치 |
| shared_preferences | 2.2.2 | 칼럼 폭 persist | StocksColumnWidthStorage에서 사용 중 |

새 패키지 설치 불필요 — 이 Phase는 순수 코드 수정이다.

---

## Architecture Patterns

### 현재 구조 (코드에서 확인된 실제 상태)

```
StocksReportView (StatefulWidget)
├── _stocksColumnWidths: Map<String, double>?  ← 단일 상태 (D-03 충족)
├── _scrollController: ScrollController         ← 세로 스크롤용
└── _buildStocksContent()
    └── ResizableDataTable
        ├── columns: StocksBuilder.buildColumnDefs()
        ├── rows: StocksBuilder.buildRows(dataList)
        ├── columnWidths: mergedColumnWidths     ← 헤더·행 공유
        ├── onColumnResize: setState + persist   ← D-07 충족
        └── scrollController: null              ← 주의: 전달 안 됨
            └── _ResizableDataTableState
                ├── _headerScrollController      ← 내부 생성
                ├── _dataScrollController        ← widget.scrollController 없으면 내부 생성
                └── listener 쌍 동기화          ← D-05 충족 (내부)
```

### Pattern 1: 단일 상태 칼럼 폭 관리 (D-03)

**What:** `_stocksColumnWidths`가 단일 진실 공급원. `mergedColumnWidths`는 defaults에 user 조정치를 오버레이한 계산값.

**현재 구현 (stocks_report_view.dart:423-427):**
```dart
final defaults = {
  for (final col in StocksBuilder.buildColumnDefs()) col.key: col.defaultWidth
};
final mergedColumnWidths = Map<String, double>.from(defaults)
  ..addAll(_stocksColumnWidths ?? {});
```

**주의:** `mergedColumnWidths`는 `build()` 내에서 매번 새로 계산된다. `ResizableDataTable`은 이 값을 `widget.columnWidths`로 받아 `_columnWidth()` 메서드에서 참조한다. 이 흐름은 D-03을 올바르게 구현한다.

### Pattern 2: 가로 스크롤 동기화 (D-05)

**현재 구현 (resizable_data_table.dart:130-145):**
```dart
// 헤더 → 데이터 동기화 (race condition 방지: delta 0.5px 임계값)
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

**상태:** 이 코드는 올바른 구조다. 두 SingleChildScrollView(헤더·데이터)가 각각 분리된 컨트롤러를 가지되 listener로 동기화한다. 이 패턴이 제대로 작동하지 않는 경우는 두 ScrollView의 `content width`가 다를 때다.

### Pattern 3: 총 콘텐츠 폭 계산 (핵심 주의 지점)

**헤더 영역 폭:** `Padding(horizontal: 16)` + Row의 children 합계. 각 칼럼 `SizedBox(width: colWidth)` + `SizedBox(width: 8)` 간격. 패딩 32px 포함.

**데이터 영역 폭:** `SizedBox(width: _totalContentWidth())`. `_totalContentWidth()`는 `colWidths + gaps + 32.0`.

**잠재적 불일치:** 헤더 Row의 실제 폭은 Flutter 레이아웃 엔진이 계산하지만, 데이터 영역의 SizedBox 폭은 `_totalContentWidth()`로 명시 지정된다. 두 값이 수식적으로 동일하다면 정렬된다. 수식 확인:
- 헤더: `16(left padding) + sum(colWidths) + (n-1)*8(gaps) + 16(right padding)` = `sum(colWidths) + (n-1)*8 + 32`
- 데이터: `_totalContentWidth()` = `sum(colWidths) + (n-1)*8 + 32`

수식은 동일하다. **따라서 정렬 불일치가 발생한다면 `columnWidths`가 헤더와 데이터 빌드 시점 사이에 달라지거나, 칼럼 가시성 필터링이 한쪽에만 적용되는 경우다.**

### Pattern 4: 리사이즈 핸들 (D-07)

**현재 구현:** Stack + Positioned 오버레이로 `right: -7` 위치에 14px 핸들 배치. 헤더 Row 레이아웃 폭에 영향 없음. `onResize` 콜백이 `widget.onColumnResize(col.key, w)`를 호출하고, `StocksReportView.onColumnResize`에서 `setState(() { _stocksColumnWidths![key] = newWidth; })`로 상태 업데이트 후 `ResizableDataTable` rebuild 트리거.

**이 경로는 D-07을 올바르게 구현한다.** 리사이즈 후 `_totalContentWidth()`가 새 폭을 반영하여 데이터 영역 SizedBox 폭이 업데이트된다.

### Anti-Patterns to Avoid

- **별도 ScrollController 인스턴스를 헤더/데이터에 각각 연결 후 listener 없이 사용:** 스크롤 불일치 발생. 현재 코드는 이를 올바르게 listener로 해결.
- **칼럼 폭을 헤더·데이터 위젯 각각의 로컬 상태로 관리:** 리사이즈 시 한쪽만 업데이트됨. 현재 구조는 단일 `mergedColumnWidths`로 올바르게 구현.
- **GlobalKey를 리사이즈 핸들 위젯의 key로 사용:** 매 빌드마다 리사이즈 핸들 상태가 리셋됨. 코드 주석에 이미 경고 있음 (stocks_builder.dart:154).
- **`addPostFrameCallback` 내에서 `setState` 호출 남용:** 불필요한 rebuild 유발. 현재 `_stocksColumnWidthsDbKey` 체크 로직이 이 패턴을 사용 중이나 최소화 필요.

---

## Don't Hand-Roll

| 문제 | 직접 구현하지 말 것 | 사용할 것 | 이유 |
|---------|-------------|-------------|-----|
| 가로 스크롤 동기화 | 타이머/SchedulerBinding 기반 폴링 | ScrollController + addListener + jumpTo | 이미 ResizableDataTable에 구현됨, listener 패턴이 표준 Flutter 방식 |
| 칼럼 폭 측정 | RenderBox.findRenderObject() 탐색 | 명시적 width 지정 (SizedBox(width: colWidth)) | 렌더 트리 탐색은 취약하고 타이밍 의존. 현재 ItemsTableWithMeasuredColumns의 복잡한 측정 코드가 이 anti-pattern을 보여줌 |
| 폭 persist | 자체 파일 시스템 저장 | StocksColumnWidthStorage (SharedPreferences) | 이미 구현됨, DB명별 키 지원 |

---

## Common Pitfalls

### Pitfall 1: 두 SingleChildScrollView의 content width 불일치

**What goes wrong:** 헤더 Row와 데이터 SizedBox의 실제 픽셀 폭이 다르면 스크롤을 동일 offset으로 맞춰도 칼럼이 어긋난다.

**Why it happens:** 헤더는 Row(mainAxisSize: min)로 자연 크기를 가지고, 데이터는 명시적 `_totalContentWidth()`를 가진다. 두 계산이 동일 수식을 사용하지만 칼럼 가시성(숨긴 칼럼 등)이 한쪽에만 적용되면 불일치 발생.

**How to avoid:** `_totalContentWidth()`와 헤더 Row children이 완전히 동일한 칼럼 집합을 같은 순서로 참조하는지 확인. 가시성 필터링이 있다면 양쪽에 동일 적용.

**Warning signs:** 가로 스크롤 끝에서 헤더가 데이터보다 먼저 또는 늦게 멈춤.

### Pitfall 2: StocksReportView._scrollController와 ResizableDataTable 연결 누락

**What goes wrong:** `StocksReportView`의 `_scrollController`는 무한스크롤(`_onScroll`)에 사용되지만 `ResizableDataTable`에 `scrollController`로 전달되지 않는다. `ResizableDataTable`은 내부적으로 자체 `_dataScrollController`를 생성한다. 이 두 컨트롤러가 분리되어 있으면 외부에서 세로 스크롤 위치를 제어할 수 없고, 무한스크롤 트리거가 작동하지 않을 수 있다.

**코드 확인:** `stocks_report_view.dart:431` — `ResizableDataTable(scrollController: null)` (전달 없음).

**How to avoid:** `_scrollController`를 `ResizableDataTable(scrollController: _scrollController)`로 전달. `ResizableDataTable`은 이 경우 `_ownsDataScrollController = false`로 설정하여 dispose하지 않는다.

**Warning signs:** 세로 스크롤이 끝에 가도 `_onScroll`이 호출되지 않음, 무한스크롤이 작동 안 함.

### Pitfall 3: 리사이즈 핸들 드래그 중 setState 과다 호출

**What goes wrong:** `onPointerMove`가 매 픽셀마다 `widget.onResize` → 상위 setState 호출. 수백 번의 rebuild 발생으로 성능 저하.

**Why it happens:** Listener.onPointerMove는 포인터 이동마다 호출됨.

**How to avoid:** 현재 구현(`_TableResizeHandle`)은 `widget.onResize(newWidth)`를 직접 호출한다. `StocksReportView.onColumnResize`가 `setState`를 즉시 호출하므로 드래그 중 잦은 rebuild 발생. 이는 허용 가능한 수준이나, 성능 문제 시 내부 임시 상태로 드래그 값을 추적하고 `onPointerUp`에서만 상위에 전달하는 방식 고려.

**Warning signs:** 리사이즈 드래그 중 UI가 끊김.

### Pitfall 4: `_stocksColumnWidthsDbKey` 체크의 addPostFrameCallback 루프

**What goes wrong:** `_buildStocksContent()`가 `build()` 내에서 `addPostFrameCallback`을 등록하고 그 안에서 `setState` 호출. `build()`가 호출될 때마다 새 callback이 등록됨.

**Why it happens:** `stocks_report_view.dart:412-421`의 패턴이 `build()` 내에 있어 모든 rebuild 시 실행됨.

**How to avoid:** 이 로직은 `initState` 또는 `didUpdateWidget`으로 이동해야 함. 단, D-01(최소 변경)에 따라 영향 범위를 신중히 판단.

---

## Code Examples

### 현재 ResizableDataTable 스크롤 동기화 패턴 (검증됨)

```dart
// lib/widgets/resizable_data_table.dart
// 두 ScrollController를 listener로 연결하는 표준 패턴
_headerScrollController.addListener(_syncHeaderToData);
_dataScrollController.addListener(_syncDataToHeader);

void _syncHeaderToData() {
  if (!_dataScrollController.hasClients) return;
  final delta = (_dataScrollController.offset - _headerScrollController.offset).abs();
  if (delta > 0.5) {
    _dataScrollController.jumpTo(_headerScrollController.offset);
  }
}
```

### 올바른 scrollController 전달 패턴

```dart
// stocks_report_view.dart — 수정 후 목표 상태
ResizableDataTable(
  columns: StocksBuilder.buildColumnDefs(),
  rows: StocksBuilder.buildRows(dataList),
  columnWidths: mergedColumnWidths,
  onColumnResize: (key, newWidth) { ... },
  scrollController: _scrollController,  // 세로 스크롤 외부 제어 연결
  ...
)
```

### 단일 상태 칼럼 폭 — onColumnResize 패턴 (현재 올바름)

```dart
// stocks_report_view.dart:435-440
onColumnResize: (key, newWidth) {
  setState(() {
    _stocksColumnWidths ??= {};
    _stocksColumnWidths![key] = newWidth;
  });
  StocksColumnWidthStorage.save(dbKey, _stocksColumnWidths!);
},
```

---

## State of the Art

| 구 접근법 | 현재 접근법 | 변경 시점 | 영향 |
|--------------|------------------|--------------|--------|
| Row에 리사이즈 핸들 추가 (14px 누적 어긋남 발생) | Stack + Positioned 오버레이로 핸들 배치 | 현재 ResizableDataTable | 헤더 Row 폭에 영향 없음 |
| RenderBox 탐색으로 칼럼 폭 측정 (ItemsTableWithMeasuredColumns 방식) | 명시적 SizedBox(width: colWidth) 지정 | ResizableDataTable 도입 시 | 취약한 측정 코드 불필요 |
| 리포트별 별도 리사이즈 핸들 구현 | 공용 _TableResizeHandle | ResizableDataTable | 코드 중복 제거 |

---

## Open Questions

1. **실제 정렬 불일치의 정확한 재현 조건**
   - What we know: CONTEXT.md에서 "어떤 상황(리사이즈, 스크롤, 가시성 변경)에서도" 불일치가 발생한다고 명시
   - What's unclear: ResizableDataTable 코드 분석상 구조는 올바르다. 실제로 어떤 경로에서 불일치가 발생하는지 실기기/시뮬레이터 재현 필요
   - Recommendation: 실행 단계에서 가장 먼저 불일치를 재현하고 debugPrint로 헤더/데이터 폭을 측정하여 어느 경로가 깨지는지 확인

2. **칼럼 가시성(visibility) 기능의 존재 여부**
   - What we know: ALIGN-03 성공 기준에 "가시성 변경" 언급. ConfigService에 shouldShowField() 있음
   - What's unclear: StocksReportView/ResizableDataTable에서 칼럼 가시성 필터링이 실제로 적용되는지, 헤더와 데이터 행에 동일하게 적용되는지 확인 안 됨
   - Recommendation: `StocksBuilder.buildColumnDefs()`와 `buildRows()`가 가시성 필터링을 동일하게 적용하는지 실행 단계에서 확인

3. **StocksBuilder.buildContent() vs _buildStocksContent() 공존**
   - What we know: `stocks_builder.dart`에 `buildContent()`가 있고 `stocks_report_view.dart`에 `_buildStocksContent()`도 있음. 두 경로가 모두 사용되는지 불명확
   - What's unclear: `buildContent()`는 `headerWidget` 파라미터를 받으며 내부에 별도 `horizontalScrollController`를 생성한다. 이 경로가 활성화되면 ResizableDataTable의 scroll 동기화와 충돌할 수 있음
   - Recommendation: `StocksReportView.build()`에서 `_buildStocksContent()` 경로만 사용하는지, `StocksBuilder.buildContent()`도 어딘가에서 호출되는지 추적

---

## Environment Availability

Step 2.6: SKIPPED (외부 도구 의존성 없음 — 순수 Flutter/Dart 코드 수정)

---

## Project Constraints (from CLAUDE.md)

- **Flutter + Dart:** null safety 준수, Riverpod 상태관리(이 Phase는 해당 없음), dart 스타일 가이드
- **에러 핸들링:** try-catch 항상 포함
- **주석:** 한국어로 작성
- **함수/변수명:** 영어로 작성
- **플랫폼:** iOS, Android, macOS, Windows, Linux 전체 지원 유지
- **API 인터페이스:** 백엔드 API 변경 없음
- **기존 기능:** 동작에 영향 없이 개선
- **const 생성자:** 위젯에 const 사용
- **final 선호:** var보다 final 사용
- **기존 서비스 레이어 유지:** DatabaseService, ConfigService 등 변경 없음

---

## Sources

### Primary (HIGH confidence)

- `lib/widgets/resizable_data_table.dart` — 전체 소스 코드 직접 분석. ScrollController 동기화, 리사이즈 핸들, 칼럼 폭 적용 경로 확인
- `lib/screens/reports/stocks_report_view.dart` — 전체 소스 코드 직접 분석. 상태 관리, scrollController 전달 여부, columnWidths 흐름 확인
- `lib/widgets/stocks_builder.dart` — 칼럼 정의, buildRows(), buildContent() 확인
- `lib/services/stocks_column_width_storage.dart` — persist 메커니즘 확인
- `lib/widgets/report_table_measured_columns.dart` — ItemsTableWithMeasuredColumns 구조 및 RenderBox 측정 패턴 확인

### Secondary (MEDIUM confidence)

- Flutter 공식 ScrollController 동기화 패턴 — listener 기반 jumpTo 방식은 Flutter 커뮤니티 표준 접근법 (training data 기반, 2024 기준 유효)

---

## Metadata

**Confidence breakdown:**
- 현재 코드 구조 파악: HIGH — 소스 파일 직접 분석
- 정렬 불일치 근본 원인: MEDIUM — 코드로 추론했으나 실제 재현 미확인
- 수정 범위: HIGH — D-01~D-07 결정에 따라 최소 변경 경로 명확

**Research date:** 2026-04-05
**Valid until:** 2026-05-05 (코드베이스 변경 없을 시)
