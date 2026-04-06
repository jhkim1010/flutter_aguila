---
phase: 02-table-ux
plan: 01
subsystem: stocks-report
tags: [pagination, stocks, api, infinite-scroll-removal]
dependency_graph:
  requires: []
  provides: [offset-limit-stocks-api, stocks-pagination-ui]
  affects: [lib/services/api/stocks_api.dart, lib/services/database_service.dart, lib/screens/reports/stocks_report_view.dart]
tech_stack:
  added: []
  patterns: [offset/limit pagination, footerWidget slot]
key_files:
  created: []
  modified:
    - lib/services/api/stocks_api.dart
    - lib/services/database_service.dart
    - lib/screens/reports/stocks_report_view.dart
    - lib/screens/helpers/report_data_loader.dart
decisions:
  - "offset/limit 파라미터로 Stocks API 전환 — maxUtime 기반 무한스크롤 완전 제거"
  - "페이지 크기 기본값 100, 선택 옵션 50/100/200"
metrics:
  duration: ~15min
  completed_date: "2026-04-06"
  tasks_completed: 2
  files_modified: 4
requirements: [TBL-01, TBL-02, TBL-03]
---

# Phase 02 Plan 01: Stocks 무한스크롤 제거 및 페이지네이션 전환 Summary

offset/limit 기반 Stocks API 전환과 테이블 하단 페이지네이션 컨트롤(이전/다음 + 페이지 번호 + 크기 선택기) 구현.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | API 레이어 offset/limit 파라미터 전환 | db2c98b | stocks_api.dart, database_service.dart, report_data_loader.dart |
| 2 | StocksReportView 무한스크롤 제거 + 페이지네이션 구현 | e87f395 | stocks_report_view.dart |

## What Was Built

### Task 1: API 레이어 변경
- `stocks_api.dart`: `getStocksReport()` 및 `getStocksReportTyped()` 시그니처에서 `String? maxUtime` → `int? offset, int? limit` 교체
- `database_service.dart`: facade 시그니처 동일하게 교체
- `report_data_loader.dart`: 레거시 파일의 `maxUtime:` 호출 제거 (컴파일 에러 수정 — Rule 3)

### Task 2: StocksReportView 페이지네이션
- **제거된 무한스크롤 코드**: `_stocksNextMaxUtime`, `_stocksHasMore`, `_isLoadingMoreStocks` 상태 변수 + `_onScroll()` + `_loadNextStocksPage()` 메서드
- **추가된 페이지네이션 상태**: `_currentPage = 1`, `_pageSize = 100`, `_totalItems = 0`
- **`_loadData()`**: `offset: (_currentPage - 1) * _pageSize, limit: _pageSize` 전달, pagination.total 파싱
- **`_reloadDataWithFilters()`**: 필터/정렬 변경 시 `_currentPage = 1` 초기화
- **`_buildPaginationControls()`**: 이전/다음 버튼 + 페이지 번호 표시 + 페이지 크기 DropdownButton (50/100/200)
- **`_goToPage()`**: 스크롤 상단 복귀 + 데이터 로드
- **ResizableDataTable**: `isLoadingMore: false`, `footerWidget: _buildPaginationControls()` 삽입

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] report_data_loader.dart 레거시 파일 maxUtime 호출 수정**
- **Found during:** Task 1
- **Issue:** `lib/screens/helpers/report_data_loader.dart:1260`에서 `_databaseService.getStocksReport(maxUtime: _stocksNextMaxUtime, ...)` 호출 — API 시그니처 변경으로 컴파일 에러 발생
- **Fix:** `maxUtime: _stocksNextMaxUtime` 파라미터 제거 (레거시 무한스크롤 호출이므로 offset/limit 전달 불필요)
- **Files modified:** `lib/screens/helpers/report_data_loader.dart`
- **Commit:** db2c98b

## Verification Results

```
flutter analyze lib/screens/reports/stocks_report_view.dart \
  lib/services/api/stocks_api.dart lib/services/database_service.dart
→ 0 errors (19 pre-existing avoid_print infos only)

grep -rn "maxUtime" lib/services/api/stocks_api.dart lib/services/database_service.dart
→ 결과 없음 ✓

grep -rn "_onScroll|_loadNextStocksPage|_stocksHasMore|_stocksNextMaxUtime|_isLoadingMoreStocks" \
  lib/screens/reports/stocks_report_view.dart
→ 결과 없음 ✓

grep -n "footerWidget.*_buildPaginationControls" lib/screens/reports/stocks_report_view.dart
→ 467: footerWidget: _buildPaginationControls() ✓
```

## Known Stubs

None — `_totalItems`는 서버 응답의 `pagination.total`에서 읽어오고, 페이지네이션 컨트롤은 실제 데이터에 연결되어 있음.

## Self-Check: PASSED

- [x] `lib/services/api/stocks_api.dart` — 수정됨, commit db2c98b
- [x] `lib/services/database_service.dart` — 수정됨, commit db2c98b
- [x] `lib/screens/reports/stocks_report_view.dart` — 수정됨, commit e87f395
- [x] `lib/screens/helpers/report_data_loader.dart` — 수정됨, commit db2c98b
- [x] `int? offset` 2회 in stocks_api.dart ✓
- [x] `int? limit` 2회 in stocks_api.dart ✓
- [x] `maxUtime` 없음 in stocks_api.dart, database_service.dart ✓
- [x] `_currentPage`, `_pageSize`, `_totalItems` in stocks_report_view.dart ✓
- [x] `_buildPaginationControls()`, `_goToPage()` in stocks_report_view.dart ✓
- [x] `footerWidget: _buildPaginationControls()` in stocks_report_view.dart ✓
- [x] 무한스크롤 코드 5개 완전 제거 ✓
- [x] flutter analyze: 0 errors ✓
