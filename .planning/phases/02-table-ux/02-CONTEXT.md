# Phase 2: Table UX - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Stocks 리포트의 테이블 인터랙션(정렬, 필터, 페이지네이션) UX를 개선한다. 정렬과 필터는 이미 동작하므로, 핵심 작업은 무한스크롤을 페이지 기반 네비게이션으로 전환하는 것이다.

</domain>

<decisions>
## Implementation Decisions

### 정렬 (TBL-01)
- **D-01:** 이미 완료 — `sortable: true`를 모든 칼럼에 추가하여 헤더 클릭 정렬 작동 중. 추가 작업 불필요.

### 필터 (TBL-02)
- **D-02:** 현재 필터바(tipo/temporada/텍스트검색/color-talle 체크박스) UI가 충분히 직관적 — 큰 변경 불필요.

### 페이지네이션 (TBL-03)
- **D-03:** 무한스크롤 제거 → 페이지 기반 네비게이션으로 전환
- **D-04:** 페이지네이션 컨트롤 위치: 테이블 하단
- **D-05:** 페이지 크기 옵션: 50 / 100 / 200 행
- **D-06:** 컨트롤 구성: 이전/다음 버튼 + 페이지 번호 표시 + 페이지 크기 선택기

### Claude's Discretion
- 페이지네이션 컨트롤의 세부 디자인 (아이콘, 간격, 색상 등)
- 서버 API에 page/limit 파라미터 전달 방식 (기존 maxUtime 기반 → page 기반 전환 또는 offset 기반)
- 무한스크롤 관련 코드(_onScroll, _loadNextStocksPage, _stocksHasMore, _stocksNextMaxUtime) 제거 범위

</decisions>

<canonical_refs>
## Canonical References

No external specs — 요구사항은 위 decisions에 완전히 포함됨.

### 핵심 코드 (수정 대상)
- `lib/screens/reports/stocks_report_view.dart` — 무한스크롤 로직 제거, 페이지네이션 상태 관리 추가
- `lib/widgets/resizable_data_table.dart` — 페이지네이션 컨트롤 위젯 추가 가능 위치
- `lib/widgets/stocks_builder.dart` — 정렬 sortable 설정 (이미 완료)

### API 코드
- `lib/services/api/stocks_api.dart` — getStocksReport()에 page/limit 파라미터 추가 필요
- `lib/services/database_service.dart` — Stocks API 호출 인터페이스

### 참고 (Phase 1에서 수정된 파일)
- `lib/widgets/resizable_data_table.dart` — scrollController 세로/가로 분리 완료
- `lib/services/stocks_column_width_storage.dart` — 칼럼 폭 persist

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ResizableDataTable`: 정렬 UI 내장 (sortColumn, sortAscending, onSort)
- `ReportFilterWidgets`: tipo/temporada 드롭다운 빌더
- `ReportFilters.buildFilteringWordField()`: 텍스트 검색 필드 빌더
- `StocksBuilder.buildViewType()`: sucursal 선택기

### Established Patterns
- StatefulWidget + setState() 기반 상태 관리
- 서버 API에 sort_column/sort_ascending/filtering_word 쿼리 파라미터 전달
- 현재 무한스크롤: maxUtime 기반 커서 페이지네이션 (서버에서 pagination.nextMaxUtime 반환)

### Integration Points
- `StocksReportView._scrollController` → 현재 무한스크롤용, 페이지 기반 전환 시 _onScroll 리스너 제거
- `StocksApi.getStocksReport()` → maxUtime 파라미터를 page/limit 또는 offset/limit로 전환
- `ResizableDataTable` → scrollController 파라미터는 세로 스크롤용으로 유지 (페이지 내 스크롤)

</code_context>

<specifics>
## Specific Ideas

No specific requirements — 표준 페이지네이션 패턴(이전/다음 + 페이지 크기 선택) 적용.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-table-ux*
*Context gathered: 2026-04-06*
