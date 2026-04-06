# Phase 02: Table UX - Research

**Researched:** 2026-04-06
**Domain:** Flutter 페이지네이션 UX / 무한스크롤 → 페이지 기반 전환
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**정렬 (TBL-01)**
- D-01: 이미 완료 — `sortable: true`를 모든 칼럼에 추가하여 헤더 클릭 정렬 작동 중. 추가 작업 불필요.

**필터 (TBL-02)**
- D-02: 현재 필터바(tipo/temporada/텍스트검색/color-talle 체크박스) UI가 충분히 직관적 — 큰 변경 불필요.

**페이지네이션 (TBL-03)**
- D-03: 무한스크롤 제거 → 페이지 기반 네비게이션으로 전환
- D-04: 페이지네이션 컨트롤 위치: 테이블 하단
- D-05: 페이지 크기 옵션: 50 / 100 / 200 행
- D-06: 컨트롤 구성: 이전/다음 버튼 + 페이지 번호 표시 + 페이지 크기 선택기

### Claude's Discretion

- 페이지네이션 컨트롤의 세부 디자인 (아이콘, 간격, 색상 등)
- 서버 API에 page/limit 파라미터 전달 방식 (기존 maxUtime 기반 → page 기반 전환 또는 offset 기반)
- 무한스크롤 관련 코드(_onScroll, _loadNextStocksPage, _stocksHasMore, _stocksNextMaxUtime) 제거 범위

### Deferred Ideas (OUT OF SCOPE)

없음 — 토론이 phase 범위 내에서 종료됨.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TBL-01 | 칼럼 헤더 클릭으로 오름차순/내림차순 정렬 가능 | D-01: `sortable: true` + `onSort` 콜백이 이미 `ResizableDataTable`에 구현됨. `StocksBuilder.buildColumnDefs()`에 모든 칼럼 `sortable: true` 완료. 코드 검증 완료 — 추가 구현 불필요. |
| TBL-02 | 필터링 인터페이스가 직관적이고 사용하기 쉬움 | D-02: 기존 필터 바(tipo/temporada 드롭다운 + 텍스트 검색 + color-talle 체크박스)가 이미 충분히 구현됨. 필터 초기화 버튼만 확인 필요. |
| TBL-03 | 페이지네이션이 페이지 이동과 페이지 크기 변경을 지원 | 무한스크롤 코드 4개 제거 + 페이지네이션 상태 3개 추가 + API 파라미터 전환 + 페이지네이션 컨트롤 위젯 신규 빌드. |
</phase_requirements>

---

## Summary

이 Phase의 핵심 작업은 실질적으로 **TBL-03 하나**다. TBL-01(정렬)은 이미 완전히 구현되어 있고, TBL-02(필터)는 현재 UI가 충분해 변경이 없다.

TBL-03의 작업 범위: `StocksReportView`에서 `_onScroll`, `_loadNextStocksPage`, `_stocksHasMore`, `_stocksNextMaxUtime` 등 무한스크롤 관련 코드를 제거하고, 페이지 번호(`_currentPage`) + 페이지 크기(`_pageSize`) 상태로 교체한다. `StocksApi.getStocksReport()`에서 `maxUtime` 파라미터를 `page`/`limit` 파라미터로 전환한다. `ResizableDataTable`의 `footerWidget` 슬롯을 이용해 이전/다음 버튼 + 페이지 표시 + 크기 선택기로 구성된 페이지네이션 컨트롤을 하단에 삽입한다.

서버 API가 현재 `pagination.hasMore`와 `pagination.total`을 반환하므로, offset 기반(`page * limit`)으로 전환하면 서버 응답 구조를 크게 바꾸지 않고 `limit` 파라미터를 추가하는 방식이 가장 적은 변경으로 동작한다.

**Primary recommendation:** `maxUtime` → `offset/limit` 방식으로 API 파라미터 전환하고, `footerWidget`에 페이지네이션 컨트롤을 삽입하는 것이 최소 변경으로 최대 효과를 내는 접근이다.

---

## Standard Stack

### Core (이미 프로젝트에 있음)

| 컴포넌트 | 버전 | 역할 | 비고 |
|----------|------|------|------|
| `ResizableDataTable` | 프로젝트 내부 | 테이블 렌더링 + 정렬 UI | `footerWidget` 슬롯 이미 존재 |
| `StocksReportView` | 프로젝트 내부 | 상태 관리 + 데이터 로딩 | 무한스크롤 코드 보유 |
| `StocksApi` | 프로젝트 내부 | HTTP 요청 | `maxUtime` 파라미터 → 교체 대상 |
| `DatabaseService` | 프로젝트 내부 | API 퍼사드 | `getStocksReport()` 시그니처 변경 필요 |
| `StocksPagination` 모델 | 프로젝트 내부 | 페이지네이션 응답 파싱 | `total`, `hasMore` 필드 이미 있음 |
| Flutter Material | SDK | `DropdownButton`, `IconButton` | 페이지네이션 컨트롤 위젯에 사용 |

### 페이지네이션 컨트롤에 쓸 Flutter 위젯

| 위젯 | 용도 |
|------|------|
| `Row` | 컨트롤 수평 배치 |
| `IconButton(icon: Icon(Icons.chevron_left))` | 이전 페이지 버튼 |
| `IconButton(icon: Icon(Icons.chevron_right))` | 다음 페이지 버튼 |
| `Text` | 현재 페이지 / 전체 페이지 표시 |
| `DropdownButton<int>` | 페이지 크기 선택 (50/100/200) |

신규 패키지 설치 불필요 — 모두 Flutter SDK 기본 제공.

---

## Architecture Patterns

### 현재 무한스크롤 구조 (제거 대상)

```
StocksReportView
├── _scrollController.addListener(_onScroll)  ← 제거
├── _stocksHasMore: bool                       ← 제거
├── _stocksNextMaxUtime: String?               ← 제거
├── _isLoadingMoreStocks: bool                 ← 제거
├── _onScroll()                                ← 제거
└── _loadNextStocksPage()                      ← 제거
```

### 목표 페이지네이션 구조 (신규)

```
StocksReportView
├── _currentPage: int = 1                      ← 신규
├── _pageSize: int = 100                       ← 신규 (기본값 100)
├── _totalItems: int = 0                       ← 신규 (서버 total 저장)
├── _loadData()                                ← offset/limit 파라미터로 호출
└── _buildPaginationControls()                 ← 신규 위젯 메서드
```

### 페이지네이션 컨트롤 위젯 배치

`ResizableDataTable`의 `footerWidget` 파라미터를 사용한다. 이 슬롯은 테이블 `Column`의 마지막 자식으로 렌더링되어 정확히 테이블 하단에 위치한다.

```dart
// StocksReportView._buildStocksContent() 내부
ResizableDataTable(
  ...
  footerWidget: _buildPaginationControls(),
  isLoadingMore: false,  // 더 이상 사용 안 함 → false 고정 또는 제거
)
```

### API 파라미터 전환 패턴

```dart
// 현재 (제거)
StocksApi.getStocksReport({ String? maxUtime })
  → queryParams['max_utime'] = maxUtime

// 변경 후
StocksApi.getStocksReport({ int? offset, int? limit })
  → queryParams['offset'] = offset.toString()
  → queryParams['limit'] = limit.toString()
```

`offset` 계산: `(_currentPage - 1) * _pageSize`

### 페이지네이션 컨트롤 패턴

```dart
Widget _buildPaginationControls() {
  final totalPages = (_totalItems / _pageSize).ceil().clamp(1, 99999);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 이전 버튼
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
        ),
        // 페이지 표시
        Text('$_currentPage / $totalPages'),
        // 다음 버튼
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < totalPages ? () => _goToPage(_currentPage + 1) : null,
        ),
        const SizedBox(width: 16),
        // 페이지 크기 선택기
        DropdownButton<int>(
          value: _pageSize,
          items: [50, 100, 200].map((size) =>
            DropdownMenuItem(value: size, child: Text('$size 행'))
          ).toList(),
          onChanged: (size) {
            if (size != null) {
              setState(() {
                _pageSize = size;
                _currentPage = 1;  // 크기 변경 시 첫 페이지로
              });
              _loadData();
            }
          },
        ),
      ],
    ),
  );
}

void _goToPage(int page) {
  setState(() => _currentPage = page);
  _loadData();
}
```

### Anti-Patterns to Avoid

- **ScrollController를 페이지네이션에 재사용:** `_scrollController`는 세로 스크롤(Phase 1에서 분리 완료)에만 사용. 페이지 이동 시 `scrollController.jumpTo(0)` 호출로 상단 복귀는 허용.
- **_reloadDataWithFilters() 호출 시 페이지 초기화 누락:** 필터/정렬 변경 시 `_currentPage = 1` 리셋을 반드시 포함해야 함. 안 하면 빈 결과 페이지를 요청하게 됨.
- **isLoadingMore를 제거하지 않고 방치:** `ResizableDataTable.isLoadingMore` 파라미터는 남겨두되 `false` 고정 또는 새 로딩 인디케이터로 대체.

---

## Don't Hand-Roll

| 문제 | 손수 만들지 말 것 | 사용할 것 | 이유 |
|------|-------------------|-----------|------|
| 페이지 수 계산 | 직접 수식 작성 | `(total / pageSize).ceil()` + `.clamp(1, max)` | 0행일 때 나눗셈 예외 방지 |
| 이전/다음 버튼 비활성화 | 별도 bool 상태 | `onPressed: condition ? callback : null` | Flutter 기본 패턴, null이면 자동 비활성화 |
| 페이지 크기 드롭다운 | 커스텀 팝업 | `DropdownButton<int>` (Material) | 이미 프로젝트 전반에서 사용 중 |

---

## Common Pitfalls

### Pitfall 1: 필터/정렬 변경 시 페이지 번호 미초기화

**What goes wrong:** 사용자가 정렬 칼럼을 바꿨는데 `_currentPage`가 5 그대로이면, 서버에 `offset=400` 요청이 나가 빈 결과가 온다.

**Why it happens:** `_reloadDataWithFilters()`가 현재 `_stocksNextMaxUtime = null`과 `_stocksHasMore = false`만 초기화한다. 새 `_currentPage`는 아직 없다.

**How to avoid:** `_reloadDataWithFilters()` 내부에서 `_currentPage = 1`을 설정한다. `onSort` 콜백에서도 동일하게 처리.

**Warning signs:** 정렬/필터 후 테이블이 비어있거나 마지막 페이지 데이터가 보임.

### Pitfall 2: _scrollController dispose 타이밍

**What goes wrong:** `_scrollController.addListener(_onScroll)` 리스너를 `_onScroll` 메서드 삭제 전에 `removeListener` 없이 지우면 dispose에서 오류.

**Why it happens:** `dispose()`에서 `_scrollController.dispose()`가 호출되는데, 존재하지 않는 리스너를 참조할 수 있음.

**How to avoid:** `initState()`에서 `_scrollController.addListener(_onScroll)` 줄을 제거하는 것으로 충분. `_scrollController`는 Phase 1 분리 후 세로 스크롤용으로 유지되어야 함.

**Warning signs:** `dispose() called on widget with active listeners` 런타임 에러.

### Pitfall 3: 서버가 offset/limit 파라미터를 지원하지 않는 경우

**What goes wrong:** 서버가 `max_utime`만 이해하고 `offset`/`limit`를 무시하면, 항상 첫 페이지 데이터만 반환함.

**Why it happens:** API 스펙 변경이 프론트엔드 단독으로 완결되지 않을 수 있음.

**How to avoid:** 플래닝 단계에서 "서버가 offset/limit를 지원하는지" 확인 태스크를 Wave 0에 포함. 지원하지 않으면 `limit` 파라미터만 추가하고 클라이언트 측 슬라이싱 처리를 fallback으로 검토.

**Warning signs:** 모든 페이지에서 동일 데이터가 표시됨.

### Pitfall 4: DatabaseService.getStocksReport() 시그니처 변경 시 호출처 누락

**What goes wrong:** `StocksApi`와 `DatabaseService`의 `maxUtime` 파라미터를 제거하면, `_loadNextStocksPage()`가 `maxUtime:` named param으로 호출하던 코드가 컴파일 에러를 낸다.

**Why it happens:** `_loadNextStocksPage()` 자체가 삭제 대상이지만, 다른 곳에서도 `maxUtime`으로 호출하는 코드가 있을 수 있음.

**How to avoid:** `maxUtime` 파라미터 제거 전에 전체 codebase에서 `maxUtime` 참조 검색 (`grep -r 'maxUtime'`).

---

## Code Examples

### 현재 무한스크롤 코드 (제거할 4개 상태 + 2개 메서드)

```dart
// 제거 대상 상태 변수 (stocks_report_view.dart 69-71)
String? _stocksNextMaxUtime;
bool _stocksHasMore = false;
bool _isLoadingMoreStocks = false;

// 제거 대상 메서드
void _onScroll() { ... }                    // 223-227행
Future<void> _loadNextStocksPage() { ... }  // 230-268행

// initState에서 제거
_scrollController.addListener(_onScroll);   // 84행
```

### 서버 응답 구조 (변경 없음 — 현재 이미 total 제공)

```dart
// StocksPagination 모델이 이미 total 필드 보유
class StocksPagination {
  final int count;
  final int total;   // ← 이걸로 totalPages 계산 가능
  final bool hasMore;
  final String? nextMaxUtime;  // ← offset 전환 후 무시
}

// _loadData() 완료 후 total 저장
if (data.containsKey('pagination') && data['pagination'] is Map) {
  final pagination = data['pagination'] as Map<String, dynamic>;
  _totalItems = pagination['total'] as int? ?? 0;  // ← 신규
  // _stocksHasMore, _stocksNextMaxUtime 저장 코드 제거
}
```

### API 파라미터 전환 (stocks_api.dart)

```dart
// 변경 전
Future<Map<String, dynamic>> getStocksReport({
  String? maxUtime,  // ← 제거
  ...
}) async {
  if (maxUtime != null) queryParams['max_utime'] = maxUtime;  // ← 제거
}

// 변경 후
Future<Map<String, dynamic>> getStocksReport({
  int? offset,  // ← 신규
  int? limit,   // ← 신규
  ...
}) async {
  if (offset != null) queryParams['offset'] = offset.toString();  // ← 신규
  if (limit != null) queryParams['limit'] = limit.toString();      // ← 신규
}
```

### 페이지 이동 시 스크롤 상단 복귀

```dart
void _goToPage(int page) {
  setState(() => _currentPage = page);
  // 페이지 이동 시 테이블 상단으로 복귀
  if (_scrollController.hasClients) {
    _scrollController.jumpTo(0);
  }
  _loadData();
}
```

---

## State of the Art

| 이전 방식 | 현재 방식 | 변경 이유 |
|-----------|-----------|-----------|
| maxUtime 기반 커서 페이지네이션 | offset/limit 기반 페이지 번호 | 사용자가 특정 페이지로 직접 이동 불가 문제 |
| _scrollController 무한스크롤 | footerWidget 페이지네이션 컨트롤 | 명시적 페이지 이동 UX 요구 (D-03) |
| isLoadingMore 배너 | 일반 로딩 인디케이터 | 페이지 전환 시 전체 로딩이므로 기존 _isLoading 재사용 |

---

## Open Questions

1. **서버 offset/limit 지원 여부**
   - 무엇을 아는가: 서버가 현재 `max_utime` + `pagination.total` + `pagination.hasMore`를 반환함
   - 불확실한 점: `offset` / `limit` 쿼리 파라미터를 서버가 처리하는지 API 코드에서 확인되지 않음
   - 권장 처리: Wave 0 태스크로 "서버 offset/limit 지원 확인" 포함. 미지원 시 `limit` 파라미터만 추가하고 클라이언트 슬라이싱 fallback 사용.

2. **_reloadDataWithFilters() vs _loadData() 호출 분기**
   - 무엇을 아는가: 현재 `_reloadDataWithFilters()`가 `_stocksNextMaxUtime = null`을 초기화한다
   - 불확실한 점: 페이지네이션 전환 후 두 메서드를 통합할지 분리 유지할지
   - 권장 처리: `_reloadDataWithFilters()`에 `_currentPage = 1` 추가하고 `_loadData()` 위임 구조 유지.

---

## Environment Availability

Step 2.6: SKIPPED (코드 전용 변경 — 외부 의존성 없음. Flutter SDK와 기존 패키지만 사용.)

---

## Sources

### Primary (HIGH confidence — 직접 코드 검사)

- `lib/screens/reports/stocks_report_view.dart` — 무한스크롤 구현 전체 검토 (53-608행)
- `lib/widgets/resizable_data_table.dart` — `footerWidget` 슬롯, `isLoadingMore`, `scrollController` 파라미터 확인
- `lib/widgets/stocks_builder.dart` — `buildColumnDefs()` `sortable: true` 설정 확인 (36-55행)
- `lib/services/api/stocks_api.dart` — `maxUtime` 파라미터 구조 확인
- `lib/services/database_service.dart` — `getStocksReport()` 퍼사드 시그니처
- `lib/models/stocks_response.dart` — `StocksPagination.total` 필드 존재 확인

### Secondary (MEDIUM confidence)

- `.planning/phases/02-table-ux/02-CONTEXT.md` — 잠긴 결정 사항 (D-01 ~ D-06)
- `.planning/REQUIREMENTS.md` — TBL-01, TBL-02, TBL-03 요구사항 정의

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — 신규 패키지 없음, 기존 위젯 재사용
- Architecture: HIGH — 코드 직접 검사로 변경 범위 명확
- Pitfalls: HIGH — offset/limit 서버 지원 여부만 MEDIUM (런타임 확인 필요)

**Research date:** 2026-04-06
**Valid until:** 2026-05-06 (stable — Flutter SDK 기본 위젯만 사용)
