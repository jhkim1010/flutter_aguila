# Requirements: Flutter Aguila

**Defined:** 2026-04-05
**Core Value:** 리포트 테이블이 정확하고 일관되게 표시되어야 한다 — 헤더와 행의 칼럼 폭/위치가 항상 완벽히 일치해야 함.

## v1 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### 테이블 칼럼 정렬

- [x] **ALIGN-01**: Stocks 리포트 헤더와 행의 칼럼 폭이 완벽히 일치하여 표시
- [x] **ALIGN-02**: 칼럼 리사이즈 후에도 헤더/행 폭이 동기화 유지
- [x] **ALIGN-03**: 가로/세로 스크롤 시 헤더 위치가 데이터 행과 정확히 동기화

### 테이블 UX

- [x] **TBL-01**: 칼럼 헤더 클릭으로 오름차순/내림차순 정렬 가능
- [x] **TBL-02**: 필터링 인터페이스가 직관적이고 사용하기 쉬움
- [x] **TBL-03**: 페이지네이션이 페이지 이동과 페이지 크기 변경을 지원

### Riverpod 전환

- [ ] **RVP-01**: 리포트 데이터 캐싱을 Riverpod provider로 관리하여 불필요한 재요청 방지

### 다중 지점 Resumen del Día

- [ ] **MSUC-01**: 지점이 2개 이상일 때 전 지점 합계(Total)가 단일 지점과 동일한 카드 레이아웃으로 먼저 표시
- [ ] **MSUC-02**: 콤보박스로 개별 sucursal 선택 시 서버 재요청 없이 해당 지점 값으로 카드 갱신
- [ ] **MSUC-03**: 카드/테이블 토글로 기존 비교 테이블 복귀 가능, 테이블 모드에서는 지점 콤보 숨김
- [ ] **MSUC-04**: Stock Resumen이 지점별 데이터가 아님(DB 전역)을 화면에 명시
- [ ] **MSUC-05**: FVentas del Mes의 대상 월 범위를 화면에 표시

### FVentas 기간 합계

- [ ] **FVT-01**: FVentas 합계 행의 금액이 조회 기간 전체를 반영 (로드된 100건이 아님)
- [ ] **FVT-02**: FVentas 합계 행에 조회 기간 전체 건수 표시

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### 테이블 칼럼 정렬 확장

- **ALIGN-04**: Ventas, Items, Gastos 리포트에도 동일 칼럼 정렬 로직 적용
- **ALIGN-05**: 칼럼 폭 자동 계산 (콘텐츠 기반)

### 테이블 UX 확장

- **TBL-04**: 칼럼 고정(freeze) 기능
- **TBL-05**: 키보드 네비게이션

### Riverpod 확장

- **RVP-02**: 리포트 데이터 로딩/에러 상태를 Riverpod provider로 관리
- **RVP-03**: 필터 상태를 Riverpod으로 관리
- **RVP-04**: 칼럼 폭/가시성 설정을 Riverpod으로 관리
- **RVP-05**: 전체 앱 Riverpod 전환

## Out of Scope

| Feature | Reason |
|---------|--------|
| 전체 앱 Riverpod 전환 | 이번 마일스톤에서는 리포트 캐싱에 한정 |
| 새로운 리포트 타입 추가 | 기존 리포트 개선에 집중 |
| 백엔드/API 변경 | 프론트엔드 개선만 진행 |
| 다른 리포트 칼럼 정렬 | Stocks에서 검증 후 v2에서 확장 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ALIGN-01 | Phase 1 | Complete |
| ALIGN-02 | Phase 1 | Complete |
| ALIGN-03 | Phase 1 | Complete |
| TBL-01 | Phase 2 | Complete |
| TBL-02 | Phase 2 | Complete |
| TBL-03 | Phase 2 | Complete |
| RVP-01 | Phase 3 | Pending |
| MSUC-01 | Phase 4 | Pending |
| MSUC-02 | Phase 4 | Pending |
| MSUC-03 | Phase 4 | Pending |
| MSUC-04 | Phase 4 | Pending |
| MSUC-05 | Phase 4 | Pending |
| FVT-01 | Phase 5 | Blocked (서버 응답 확인 대기) |
| FVT-02 | Phase 5 | Blocked (서버 응답 확인 대기) |

**Coverage:**
- v1 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-05*
*Last updated: 2026-08-03 — Phase 4 (다중 지점 Resumen del Día), Phase 5 (FVentas 기간 합계) 요구사항 추가*
