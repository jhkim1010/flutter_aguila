# Roadmap: Flutter Aguila

## Overview

세 단계로 리포트 테이블을 완성한다. Phase 1에서 Stocks 리포트의 헤더/행 칼럼 정렬 문제를 근본적으로 해결하고, Phase 2에서 정렬이 안정된 기반 위에 테이블 UX(정렬, 필터, 페이지네이션)를 개선하며, Phase 3에서 Riverpod 캐싱으로 불필요한 재요청을 제거한다.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Column Alignment** - Stocks 리포트 헤더/행 칼럼 폭 완벽 일치 보장
- [ ] **Phase 2: Table UX** - 칼럼 정렬, 필터, 페이지네이션 인터랙션 개선
- [ ] **Phase 3: Riverpod Caching** - 리포트 데이터 캐싱을 Riverpod provider로 관리
- [ ] **Phase 4: Multi-Sucursal Resumen** - 다중 지점 Resumen del Día를 카드 뷰(Total 우선) + 지점 선택 + 테이블 토글로 개편

## Phase Details

### Phase 1: Column Alignment
**Goal**: Stocks 리포트에서 어떤 상황(리사이즈, 스크롤, 가시성 변경)에서도 헤더와 데이터 행의 칼럼 폭/위치가 완벽히 일치한다
**Depends on**: Nothing (first phase)
**Requirements**: ALIGN-01, ALIGN-02, ALIGN-03
**Success Criteria** (what must be TRUE):
  1. Stocks 리포트를 열었을 때 헤더 칼럼과 데이터 행 칼럼이 픽셀 단위로 정렬되어 표시된다
  2. 칼럼 리사이즈 핸들을 드래그하면 헤더와 데이터 행 폭이 동시에 업데이트되어 어긋남이 없다
  3. 가로 스크롤 시 헤더와 데이터 행이 동일한 x 오프셋으로 이동하여 칼럼이 항상 정렬된 상태를 유지한다
  4. 세로 스크롤 시 고정 헤더가 데이터 행 칼럼과 항상 정렬된 상태를 유지한다
**Plans:** 1/2 plans executed

Plans:
- [x] 01-01-PLAN.md — scrollController 세로/가로 분리, 칼럼 폭 로딩 수정, 빌드 검증
- [x] 01-02-PLAN.md — 시각적 검증 checkpoint (사용자 확인)

**UI hint**: yes

### Phase 2: Table UX
**Goal**: 사용자가 Stocks 리포트 데이터를 헤더 클릭으로 정렬하고, 직관적인 필터로 좁히고, 페이지 단위로 탐색할 수 있다
**Depends on**: Phase 1
**Requirements**: TBL-01, TBL-02, TBL-03
**Success Criteria** (what must be TRUE):
  1. 칼럼 헤더를 클릭하면 해당 칼럼 기준으로 오름차순 정렬되고, 다시 클릭하면 내림차순으로 전환된다
  2. 필터 입력 후 데이터가 즉시 좁혀지며, 필터 초기화로 전체 데이터를 복원할 수 있다
  3. 페이지네이션 컨트롤에서 이전/다음 페이지 이동이 작동하고, 페이지 크기(행 수)를 변경할 수 있다
**Plans:** 2 plans

Plans:
- [x] 02-01-PLAN.md — API offset/limit 전환 + 무한스크롤 제거 + 페이지네이션 컨트롤 구현
- [ ] 02-02-PLAN.md — 시각적 검증 checkpoint (사용자 확인)

**UI hint**: yes

### Phase 3: Riverpod Caching
**Goal**: 이미 로드한 리포트 데이터를 Riverpod provider가 캐싱하여 화면 재방문 시 불필요한 서버 요청이 발생하지 않는다
**Depends on**: Phase 2
**Requirements**: RVP-01
**Success Criteria** (what must be TRUE):
  1. 리포트 화면을 떠났다가 돌아와도 동일 파라미터이면 데이터를 재요청하지 않고 캐시에서 즉시 표시한다
  2. 명시적 새로고침(pull-to-refresh 또는 새로고침 버튼) 시에만 서버에 새 요청을 보낸다
  3. 기존 setState 기반 동작이 모두 정상 작동한다(회귀 없음)
**Plans**: TBD

### Phase 4: Multi-Sucursal Resumen
**Goal**: 지점이 2개 이상일 때 Resumen del Día가 기본으로 전 지점 합계(Total)를 단일 지점과 동일한 카드 레이아웃으로 보여주고, 사용자가 콤보박스로 개별 지점을, 토글로 기존 비교 테이블을 선택할 수 있다
**Depends on**: Nothing (기존 Resumen 화면에 한정, Phase 1~3과 독립)
**Requirements**: MSUC-01, MSUC-02, MSUC-03, MSUC-04, MSUC-05
**Success Criteria** (what must be TRUE):
  1. 지점이 2개 이상인 날짜로 Resumen del Día를 열면 전 지점 합계가 카드 레이아웃으로 표시된다 (기존 비교 테이블이 첫 화면이 아니다)
  2. 우측 상단 콤보박스에서 Sucursal N을 고르면 서버 재요청 없이 해당 지점 값만으로 카드가 갱신된다
  3. 카드/테이블 토글로 기존 비교 테이블로 전환되며, 테이블 모드에서는 지점 콤보박스가 보이지 않는다
  4. Stock Resumen 섹션에 지점별 데이터가 아님(DB 전역)이 화면에 명시된다
  5. FVentas del Mes 섹션에 어느 월 범위인지가 표시된다
**Plans**: 3 plans

Plans:
- [ ] 04-01-PLAN.md — 지점 필터 유틸 + MultiSucursalView 신설 + 두 기존 뷰에 headerTrailing 슬롯 + 부모 분기 교체
- [ ] 04-02-PLAN.md — Stock Resumen "DB 전역" 배지 (단일/비교 뷰 양쪽)
- [ ] 04-03-PLAN.md — FVentas del Mes 서버 월 범위 검증 후 범위 라벨 추가 (사용자 확인 필요)

**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Column Alignment | 1/2 | In Progress|  |
| 2. Table UX | 0/2 | Not started | - |
| 3. Riverpod Caching | 0/TBD | Not started | - |
| 4. Multi-Sucursal Resumen | 0/3 | Not started | - |
