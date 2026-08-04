---
phase: 04-multi-sucursal-resumen
plan: 01
subsystem: ui
tags: [flutter, resumen-del-dia, sucursal, shared-preferences, dropdown, toggle-buttons]

requires:
  - phase: (none)
    provides: 기존 단일/비교 Resumen del Día 뷰
provides:
  - 지점별 얕은 필터 유틸 (SucursalDataFilter)
  - 다중 지점 진입 래퍼 위젯 (ResumenDelDiaMultiSucursalView)
  - 두 기존 뷰의 headerTrailing 헤더 슬롯
affects: [04-02, 04-03, resumen-del-dia]

tech-stack:
  added: []
  patterns:
    - "응답 재요청 없이 클라이언트 얕은 필터로 지점 전환"
    - "뷰 상태(모드/지점)를 래퍼 위젯이 소유하고 하위 뷰는 무상태 유지"
    - "headerTrailing 슬롯으로 하위 뷰 헤더에 컨트롤 주입"

key-files:
  created:
    - lib/utils/sucursal_data_filter.dart
    - lib/screens/resumen_del_dia_multi_sucursal_view.dart
  modified:
    - lib/screens/resumen_del_dia_single_sucursal_view.dart
    - lib/screens/resumen_del_dia_multiple_sucursales_view.dart
    - lib/screens/resumen_del_dia_screen.dart

key-decisions:
  - "지점 선택 상태를 부모 화면의 _selectedSucursal과 분리 — 부모 값은 getResumenDelDia() 요청 파라미터라 겸용하면 새로고침 시 서버 쿼리까지 좁혀진다"
  - "availableSucursales는 sucursal > 0만 센다 — resumen_del_dia_screen._hasMultipleSucursales()와 판정 기준 일치"
  - "sucursal 키가 없는 리스트는 필터를 통과시킨다 — 필터하면 빈 리스트가 되어 섹션이 통째로 사라진다"
  - "Total(null 선택)은 원본 맵을 그대로 반환 — 단일 뷰 집계 함수가 이미 여러 지점 행을 합산한다"
  - "보기 형식만 SharedPreferences에 저장하고 선택 지점은 저장하지 않는다 — 재진입 시 항상 Total로 시작"

patterns-established:
  - "SucursalDataFilter: 원본 맵/행 객체 비변형 얕은 사본 필터"
  - "headerTrailing: 하위 뷰가 헤더 우측 위젯 슬롯을 노출하는 주입 패턴"

requirements-completed: [MSUC-01, MSUC-02, MSUC-03]

duration: unknown (retroactive close-out)
completed: 2026-08-03
---

# Phase 04 Plan 01: 다중 지점 카드 진입 Summary

**다중 지점 Resumen del Día 진입 화면을 비교 테이블에서 Total 카드로 바꾸고, 서버 재요청 없는 지점 콤보박스 + 카드/테이블 토글을 붙였다**

## Performance

- **Duration:** 측정 불가 (retroactive close-out — 실행 당시 SUMMARY 미작성)
- **Completed:** 2026-08-03T23:30:32-03:00
- **Tasks:** 3 (필터 유틸 / 래퍼 위젯 / 헤더 슬롯+분기 교체)
- **Files modified:** 5 (신설 2, 수정 3)

## Accomplishments

- `SucursalDataFilter.filterBySucursal()` — 응답 재요청 없이 지점별 얕은 필터. 원본 비변형.
- `ResumenDelDiaMultiSucursalView` — 모드(카드/테이블)와 선택 지점을 소유하는 래퍼. 기본 카드 + Total.
- 두 기존 뷰에 `headerTrailing` 슬롯 추가 — 날짜 버튼 우측에 콤보/토글 주입.
- `resumen_del_dia_screen.dart` 다중 지점 분기를 래퍼로 교체.
- 보기 형식을 `SharedPreferences` 키 `resumen_del_dia_multi_view_mode`에 저장/복원.

## Task Commits

전 계획(04-01/02/03)이 단일 커밋으로 합쳐져 있다:

1. **04-01 전체** — `49d5785` (feat: open multi-branch Resumen del Día on cards instead of the table)

_원자적 태스크 커밋 프로토콜을 따르지 않았다 — 아래 Deviations 참고._

## Files Created/Modified

- `lib/utils/sucursal_data_filter.dart` — 지점별 얕은 필터 + 가용 지점 목록 (신설)
- `lib/screens/resumen_del_dia_multi_sucursal_view.dart` — 모드/지점 상태 래퍼 위젯 (신설)
- `lib/screens/resumen_del_dia_single_sucursal_view.dart` — `headerTrailing` 슬롯 수신
- `lib/screens/resumen_del_dia_multiple_sucursales_view.dart` — `headerTrailing` 슬롯 수신
- `lib/screens/resumen_del_dia_screen.dart` — 다중 지점 분기를 래퍼로 교체 (2048~2056행)

## Decisions Made

frontmatter `key-decisions` 참고. 핵심은 지점 상태를 부모 화면의 서버 요청 파라미터와 분리한 것 —
겸용했다면 지점 선택 후 새로고침에서 서버 쿼리까지 그 지점으로 좁혀졌을 것이다.

## Deviations from Plan

### 프로세스 이탈 (코드 이탈 아님)

**1. 태스크별 원자 커밋 누락**
- **Issue:** 04-01/02/03 코드가 단일 커밋 `49d5785`에 합쳐졌다. 계획은 태스크별 원자 커밋을 요구한다.
- **Impact:** 코드 자체는 계획대로다. 커밋 단위로 되돌리기가 불가능해진 것이 유일한 손실.
- **Fix:** 이 SUMMARY로 사후 기록. 커밋 재작성은 하지 않는다 (이미 반영된 이력).

**2. SUMMARY 미작성 상태로 다음 작업 진행**
- **Issue:** SUMMARY / ROADMAP 체크박스 / STATE.md가 커밋 시점에 갱신되지 않았다.
- **Fix:** 본 문서 및 동반 04-02/04-03 SUMMARY로 사후 클로즈아웃.

**코드 이탈:** 없음 — must_haves truths 10개 모두 구현으로 확인.

## Issues Encountered

없음.

## Verification

- `flutter analyze lib/` — error 0건 (info/warning는 기존 코드베이스 잔존분)
- `SucursalDataFilter.filterBySucursal` / `availableSucursales` 존재 확인
- `ResumenDelDiaMultiSucursalView` 클래스 및 `headerTrailing: _buildHeaderControls()` 배선 확인
- `resumen_del_dia_screen.dart:2056` 래퍼 호출 확인

**미검증 (실기기 UAT 필요):** 카드↔테이블 토글 후 지점 복원, SharedPreferences 재진입 유지,
다중 지점 실제 응답에서의 콤보 항목 구성.

## User Setup Required

없음.

## Next Phase Readiness

04-02(Stock Resumen 배지)는 동일 커밋에 이미 포함. 04-03은 서버 검증 미완 상태로 축소 구현됨.

---
*Phase: 04-multi-sucursal-resumen*
*Completed: 2026-08-03 (문서 클로즈아웃: 2026-08-03)*
