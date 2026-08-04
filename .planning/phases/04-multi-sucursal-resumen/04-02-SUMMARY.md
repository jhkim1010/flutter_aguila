---
phase: 04-multi-sucursal-resumen
plan: 02
subsystem: ui
tags: [flutter, resumen-del-dia, stock-resumen, badge]

requires:
  - phase: 04-01
    provides: headerTrailing 슬롯 / 지점 콤보박스 (배지가 필요해진 이유)
provides:
  - Stock Resumen 섹션의 "DB 전역" 배지 (카드 뷰 + 비교 테이블 뷰 양쪽)
  - _buildSection의 titleBadge 슬롯
affects: [04-03, resumen-del-dia]

tech-stack:
  added: []
  patterns:
    - "titleBadge 슬롯: 섹션 제목 Row에서 Expanded(Text) 뒤, onTap 화살표 앞에 배지 삽입"

key-files:
  created: []
  modified:
    - lib/screens/resumen_del_dia_single_sucursal_view.dart
    - lib/screens/resumen_del_dia_multiple_sucursales_view.dart

key-decisions:
  - "배지 헬퍼를 두 파일에 각각 둔다 — 두 뷰는 서로 import하지 않는다"
  - "배지는 Stock Resumen에만 붙인다 — 다른 섹션은 지점별로 정상 분리된다"

patterns-established:
  - "전역(지점 무관) 데이터 섹션에 amber 'DB 전역' 배지로 오독 방지"

requirements-completed: [MSUC-04]

duration: unknown (retroactive close-out)
completed: 2026-08-03
---

# Phase 04 Plan 02: Stock Resumen "DB 전역" 배지 Summary

**`stock_resumen`이 지점별 값이 아니라 DB 전역 값임을 amber 배지로 명시 — 카드 뷰 1곳, 비교 테이블 뷰 2곳(넓은/좁은 화면)**

## Performance

- **Duration:** 측정 불가 (retroactive close-out)
- **Completed:** 2026-08-03T23:30:32-03:00
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `_buildSection`에 선택 파라미터 `Widget? titleBadge` 추가 — 제목 `Expanded` 뒤, `onTap` 화살표 앞에 렌더.
- `_buildGlobalDataBadge()` 헬퍼를 두 뷰 파일에 각각 추가 (amber 배경 / amber 테두리 / `'DB 전역'`).
- 카드 뷰: Stock Resumen `_buildSection` 호출에만 배지 부착.
- 비교 테이블 뷰: 넓은 화면 우측 패널(461행)과 좁은 화면 하단(571행) 두 제목 모두 `Row`로 감싸 배지 부착.

## Task Commits

1. **Task 1 + Task 2** — `49d5785` (04-01과 합쳐진 단일 커밋)

## Files Created/Modified

- `lib/screens/resumen_del_dia_single_sucursal_view.dart` — `titleBadge` 파라미터(646행), 배지 렌더(670~672행), `_buildGlobalDataBadge()`(627행), Stock Resumen 호출부(504행)
- `lib/screens/resumen_del_dia_multiple_sucursales_view.dart` — `_buildGlobalDataBadge()`(1162행), 배지 호출 2곳(461, 571행)

## Decisions Made

계획대로. 배지 헬퍼 중복은 의도적 — 두 뷰 사이에 공유 모듈을 새로 만들 만한 크기가 아니다.

## Deviations from Plan

**코드 이탈:** 없음 — 계획된 acceptance criteria 전부 정확히 일치.

**프로세스 이탈:** 04-01과 동일 (원자 커밋 누락, SUMMARY 사후 작성). 04-01-SUMMARY 참고.

## Issues Encountered

없음.

## Verification

계획의 `<verification>` 4개 항목 실측:

| 검사 | 기대 | 실측 |
|---|---|---|
| `grep -c 'Widget? titleBadge'` (single) | 1 | 1 |
| `grep -c 'titleBadge: _buildGlobalDataBadge()'` (single) | 1 | 1 |
| `grep -c '_buildGlobalDataBadge(),'` (multiple) | 2 | 2 |
| `grep -c 'DB 전역'` (각 파일) | ≥1 | 1 / 1 |
| `flutter analyze lib/` | error 0 | error 0 |

**미검증 (실기기 UAT 필요):** 좁은 화면에서 배지가 제목 줄을 넘치지 않는지.

## User Setup Required

없음.

## Next Phase Readiness

04-03의 FVentas del Mes 라벨이 동일한 `titleBadge` 슬롯을 재사용한다 — 슬롯 준비 완료.

---
*Phase: 04-multi-sucursal-resumen*
*Completed: 2026-08-03 (문서 클로즈아웃: 2026-08-03)*
