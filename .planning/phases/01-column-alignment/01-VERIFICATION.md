---
phase: 01-column-alignment
verified: 2026-04-05T06:00:00Z
status: human_needed
score: 4/5 must-haves verified
re_verification: false
human_verification:
  - test: "Stocks 리포트 열기 — 헤더 칼럼과 데이터 행 칼럼이 픽셀 단위로 정렬되는지 확인"
    expected: "모든 칼럼(Codigo, Descripcion, Totaling 등)에서 헤더와 데이터 행이 수직으로 완벽히 정렬됨"
    why_human: "Flutter UI 픽셀 정렬은 시각적으로만 확인 가능. _totalContentWidth() 수식이 코드상 일치하더라도 실제 렌더링 환경에서 서브픽셀 차이가 발생할 수 있음."
  - test: "칼럼 리사이즈 핸들 드래그 — 헤더와 데이터 행 폭이 동시에 업데이트되는지 확인"
    expected: "드래그 중과 드래그 후 모두 헤더/행 폭이 어긋남 없이 동시 변경됨"
    why_human: "GestureDetector/Listener 이벤트 흐름과 setState 타이밍은 실기기에서만 검증 가능"
  - test: "가로 스크롤 끝까지 이동 — 헤더와 데이터 행이 동일 x 오프셋으로 이동하는지 확인"
    expected: "오른쪽 끝까지 스크롤해도 헤더/데이터 칼럼이 정렬 유지됨"
    why_human: "_syncHeaderToData / _syncDataToHeader 리스너 동기화는 실제 스크롤 이벤트 타이밍에서만 검증 가능"
  - test: "세로 스크롤 + 무한스크롤 — 하단 도달 시 추가 데이터가 로딩되는지 확인"
    expected: "세로 스크롤 80% 지점에서 _loadNextStocksPage() 호출되어 추가 데이터 표시됨"
    why_human: "_onScroll 트리거가 실기기 ListView 스크롤 위치 감지에 의존함"
  - test: "앱 재시작 후 칼럼 폭 복원 확인"
    expected: "리사이즈한 칼럼 폭이 다음 앱 시작 시 동일하게 복원됨"
    why_human: "SharedPreferences 영속성은 실기기에서만 검증 가능"
---

# Phase 01: Column Alignment Verification Report

**Phase Goal:** Stocks 리포트에서 어떤 상황(리사이즈, 스크롤, 가시성 변경)에서도 헤더와 데이터 행의 칼럼 폭/위치가 완벽히 일치한다
**Verified:** 2026-04-05T06:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (from ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Stocks 리포트를 열었을 때 헤더 칼럼과 데이터 행 칼럼이 픽셀 단위로 정렬되어 표시된다 | ? UNCERTAIN | `_totalContentWidth()` 수식이 헤더 Row와 데이터 Row에 동일하게 적용됨 (horizontal padding 16px, 8px gap 일치). 시각적 확인 필요. |
| 2 | 칼럼 리사이즈 핸들을 드래그하면 헤더와 데이터 행 폭이 동시에 업데이트되어 어긋남이 없다 | ? UNCERTAIN | `_TableResizeHandle` → `onResize` → `widget.onColumnResize` → `setState` 체인 구조적으로 올바름. 실기기 검증 필요. |
| 3 | 가로 스크롤 시 헤더와 데이터 행이 동일한 x 오프셋으로 이동하여 칼럼이 항상 정렬된 상태를 유지한다 | ? UNCERTAIN | `_syncHeaderToData` / `_syncDataToHeader` 양방향 리스너가 delta > 0.5 임계값으로 구현됨. 실기기 스크롤 검증 필요. |
| 4 | 세로 스크롤 시 고정 헤더가 데이터 행 칼럼과 항상 정렬된 상태를 유지한다 | ? UNCERTAIN | 헤더는 Column 최상단에 고정, 데이터는 `Expanded` → `ListView.builder`로 세로 스크롤. 헤더 가로/데이터 가로 동기화로 정렬 유지 구조. 실기기 확인 필요. |
| 5 | 무한스크롤이 정상 작동함 (하단 도달 시 추가 데이터 로딩) | ✓ VERIFIED | `_scrollController` → `ListView.builder controller: widget.scrollController` 연결 확인. `_onScroll()` 80% 임계값에서 `_loadNextStocksPage()` 호출. `scrollController: _scrollController` 코드 레벨 WIRED. |

**Score:** 1/5 truths programmatically verified (4/5 structurally verified, 4/5 need human visual confirmation)

**Note:** 성공 기준 1-4는 코드 구조가 올바르게 구현되었지만 Flutter UI 픽셀 정렬 특성상 시각적 검증 없이는 완전히 확인 불가. 진정한 목표 달성은 실기기 테스트에서만 판단 가능.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/widgets/resizable_data_table.dart` | 가로/세로 스크롤 분리, 헤더-데이터 동기화 | ✓ VERIFIED | 406줄. `_headerScrollController`, `_dataHorizontalScrollController` 내부 쌍. `controller: widget.scrollController` ListView에 연결. assert 추가. |
| `lib/screens/reports/stocks_report_view.dart` | scrollController 전달, initState 칼럼 폭 로딩 | ✓ VERIFIED | 609줄. `scrollController: _scrollController` 전달 확인. `_loadColumnWidths()` initState에서 호출. `_stocksColumnWidthDbKey` 클래스 상수. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `stocks_report_view.dart` | `resizable_data_table.dart` | `scrollController: _scrollController` | ✓ WIRED | line 449: `scrollController: _scrollController,` |
| `resizable_data_table.dart` (header) | `resizable_data_table.dart` (data) | `_syncHeaderToData` / `_syncDataToHeader` listener | ✓ WIRED | lines 111-112, 126-139: 양방향 동기화, delta > 0.5 임계값 |
| `stocks_report_view.dart` | `stocks_column_width_storage.dart` | `initState` → `_loadColumnWidths()` | ✓ WIRED | line 95: `_loadColumnWidths()` in initState. line 120: `StocksColumnWidthStorage.load(_stocksColumnWidthDbKey)` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `resizable_data_table.dart` ListView | `widget.rows` | `StocksBuilder.buildRows(dataList)` in `_buildStocksContent()` | dataList from `_data['data']` (API response) | ✓ FLOWING |
| `resizable_data_table.dart` header | `widget.columns` | `StocksBuilder.buildColumnDefs()` | Static column definitions (correct — not dynamic data) | ✓ FLOWING |
| `_stocksColumnWidths` | `StocksColumnWidthStorage.load()` | SharedPreferences | Persisted widths loaded in initState | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `scrollController: _scrollController` 전달 여부 | `grep -n "scrollController: _scrollController"` | line 449 매치 | ✓ PASS |
| `_dataHorizontalScrollController` 이름 변경 확인 | `grep -n "_dataHorizontalScrollController"` | 10개 매치 (initState, dispose, sync 메서드, build) | ✓ PASS |
| `_ownsDataScrollController` 플래그 제거 확인 | `grep "_ownsDataScrollController"` | NOT FOUND | ✓ PASS |
| `addPostFrameCallback` + `StocksColumnWidthStorage` 루프 제거 확인 | `grep -n "addPostFrameCallback.*StocksColumnWidthStorage"` | NOT FOUND | ✓ PASS |
| 잔여 `addPostFrameCallback` 정당성 확인 | lines 390, 510 | 필터 텍스트 clear, 필터바 AppBar 전달 — 칼럼 폭과 무관한 정당한 용도 | ✓ PASS |
| `_stocksColumnWidthDbKey` 클래스 상수 통일 | `grep "_stocksColumnWidthDbKey"` | line 55(선언), 120(load), 447(save) — 3곳 모두 동일 상수 | ✓ PASS |
| `_loadColumnWidths()` initState 호출 확인 | `grep "_loadColumnWidths"` | line 95 (initState), 118 (정의) | ✓ PASS |
| dart analyze 오류 확인 | `dart analyze` | 1 info (`avoid_print` — 기존 코드 컨벤션, 에러 아님) | ✓ PASS |
| assert 칼럼/행 수 일치 확인 | `grep "assert" resizable_data_table.dart` | line 157: `widget.rows.every((row) => row.length == widget.columns.length)` | ✓ PASS |
| 헤더/데이터 행 horizontal padding 동일성 | `grep "horizontal: 16"` | header: line 192 `horizontal: 16, vertical: 12` / data: line 233 `horizontal: 16, vertical: 5` — 가로 패딩 동일 | ✓ PASS |
| 3개 태스크 커밋 존재 확인 | `git show 2ca6766 5a5eabd ce38649 --stat` | 3개 커밋 모두 존재 및 올바른 파일 수정 확인 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| ALIGN-01 | 01-01-PLAN.md, 01-02-PLAN.md | Stocks 리포트 헤더와 행의 칼럼 폭이 완벽히 일치하여 표시 | ? NEEDS HUMAN | 코드 구조: `_totalContentWidth()` 동일 수식, horizontal padding 일치. 픽셀 정렬은 시각적 확인 필요. |
| ALIGN-02 | 01-01-PLAN.md, 01-02-PLAN.md | 칼럼 리사이즈 후에도 헤더/행 폭이 동기화 유지 | ? NEEDS HUMAN | 코드 구조: `_TableResizeHandle` → `onColumnResize` → `setState` 체인. 드래그 동작은 실기기 확인 필요. |
| ALIGN-03 | 01-01-PLAN.md, 01-02-PLAN.md | 가로/세로 스크롤 시 헤더 위치가 데이터 행과 정확히 동기화 | ? NEEDS HUMAN | 코드 구조: `_syncHeaderToData` / `_syncDataToHeader` 양방향 동기화, `widget.scrollController` → ListView. 실기기 확인 필요. |

**REQUIREMENTS.md Traceability 교차 확인:**
- REQUIREMENTS.md에 ALIGN-01, ALIGN-02, ALIGN-03 모두 Phase 1으로 매핑됨 (Traceability 테이블 확인)
- 두 PLAN 파일(`requirements: [ALIGN-01, ALIGN-02, ALIGN-03]`) 모두 동일 ID 선언
- 고아(ORPHANED) 요구사항 없음

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `stocks_report_view.dart` | 128 | `print('⚠️ 칼럼 폭 로딩 실패: $e')` | ℹ️ Info | `avoid_print` 린트 경고. 기존 코드베이스 전체 컨벤션(CLAUDE.md에 명시). 기능 동작에 영향 없음. |

**스텁 패턴 없음:** 두 파일 모두 실제 구현 코드 존재. 빈 핸들러, 플레이스홀더, 하드코딩된 빈 데이터 반환 없음.

### Human Verification Required

#### 1. ALIGN-01: 픽셀 단위 칼럼 정렬 확인

**Test:** Stocks 리포트를 열고 헤더 텍스트(Codigo, Descripcion, Totaling 등)와 데이터 행의 해당 칼럼이 수직으로 정렬되는지 육안 확인. 특히 오른쪽 끝 칼럼에서 어긋남이 없는지 확인.
**Expected:** 모든 칼럼에서 헤더와 데이터 행이 픽셀 단위로 정렬됨
**Why human:** Flutter UI 픽셀 정렬은 시각적으로만 확인 가능. 코드 수식 동일성은 확인되었으나 렌더링 결과는 실기기에서만 판단 가능.

#### 2. ALIGN-02: 리사이즈 동기화 확인

**Test:** 칼럼 헤더의 리사이즈 핸들(drag indicator 아이콘)을 드래그하여 폭을 변경. 드래그 중과 드래그 후 모두 헤더와 데이터 행 폭이 동시에 업데이트되는지 확인. 리사이즈 후 좌우 인접 칼럼과의 정렬 유지 확인.
**Expected:** 드래그 중 및 완료 후 헤더/행 폭이 어긋남 없이 동시 변경됨
**Why human:** GestureDetector Listener 이벤트와 setState 리빌드 타이밍은 실기기에서만 검증 가능.

#### 3. ALIGN-03: 가로/세로 스크롤 동기화 확인

**Test:**
- 가로 스크롤: 오른쪽 끝까지 스크롤 → 헤더와 데이터가 동일 속도로 이동하는지 확인. 왼쪽으로 되돌아가며 중간 위치에서 정렬 확인.
- 세로 스크롤: 아래로 스크롤하면서 고정 헤더가 데이터 칼럼과 정렬 유지되는지 확인.
- 무한스크롤: 하단 도달 시 추가 데이터가 로딩되는지 확인.

**Expected:** 가로/세로 어떤 스크롤 방향에서도 헤더-데이터 정렬 유지. 하단 도달 시 추가 데이터 로딩.
**Why human:** ScrollController 리스너 동기화 타이밍과 ListView 세로 스크롤 연동은 실기기에서만 검증 가능.

#### 4. 회귀 검증

**Test:** 필터(tipo, temporada, filtering word)를 변경한 후 데이터 리로딩이 정상 작동하는지 확인. 앱을 다시 시작한 후 리사이즈한 칼럼 폭이 복원되는지 확인.
**Expected:** 필터 변경 시 데이터 갱신, 앱 재시작 시 칼럼 폭 복원.
**Why human:** SharedPreferences 영속성과 필터 연동 동작은 실기기에서만 확인 가능.

### Gaps Summary

자동화 검증에서 발견된 구조적 갭은 없다. 코드 레벨에서 모든 수정 사항이 올바르게 구현되었다:

- `scrollController: _scrollController` 전달 — WIRED
- `_dataHorizontalScrollController` 가로 스크롤 분리 — WIRED
- `_syncHeaderToData` / `_syncDataToHeader` 양방향 동기화 — WIRED
- `_loadColumnWidths()` initState 1회 실행 — WIRED
- `addPostFrameCallback` 칼럼 폭 루프 제거 — 확인됨
- `_stocksColumnWidthDbKey` 클래스 상수 통일 — 확인됨
- `assert` 칼럼/행 수 일치 확인 — 추가됨
- dart analyze: 에러 0건 (info 1건 — 기존 컨벤션)

**중요 참고:** Plan 02 (시각적 검증 checkpoint)는 `auto-mode`에서 자동 승인되었으며 실제 사용자 시각적 검증이 수행되지 않았다. Phase 목표인 "완벽한 칼럼 폭/위치 일치"는 Flutter UI 특성상 코드 분석만으로 완전히 검증할 수 없다. 위 Human Verification 항목들의 실기기 확인이 필요하다.

---

_Verified: 2026-04-05T06:00:00Z_
_Verifier: Claude (gsd-verifier)_
