# Phase 4: Multi-Sucursal Resumen - Context

**Gathered:** 2026-08-03
**Status:** Ready for planning
**Source:** brainstorming 세션 (목업 검토 포함)

<domain>
## Phase Boundary

지점이 2개 이상일 때의 Resumen del Día 화면만 다룬다. 현재는 곧바로 비교 테이블이 뜨는데, 이를 카드 레이아웃(전 지점 합계)이 기본이 되도록 바꾸고 지점 선택과 테이블 복귀 수단을 붙인다.

단일 지점 화면, 다른 리포트 화면, 서버 API는 건드리지 않는다.

</domain>

<decisions>
## Implementation Decisions

### 구조 (MSUC-01)
- **D-01:** 래퍼 위젯 `ResumenDelDiaMultiSucursalView`(StatefulWidget)를 신설하고 부모 화면은 분기 한 줄만 교체한다. 모드/지점 상태는 이 래퍼가 소유한다.
- **D-02:** 부모의 기존 `_selectedSucursal`은 **재사용하지 않는다.** 이 변수는 `resumen_del_dia_screen.dart:597`과 `:657`에서 API 요청 파라미터로 전송되므로, 카드 필터용으로 겸용하면 새로고침 시 서버에도 지점 필터가 걸린다.
- **D-03:** Total 표시는 원본 `data`를 기존 `ResumenDelDiaSingleSucursalView`에 그대로 넘겨서 얻는다. 단일 뷰의 `_getAggregatedVcodes` / `_getAggregatedFventas` / `_getAggregatedFventasMes`가 이미 여러 sucursal 행을 합산하므로 카드 빌더 로직은 수정하지 않는다.

### 지점 선택 (MSUC-02)
- **D-04:** 클라이언트 필터. 서버 재호출 없음 — 응답에 이미 전 지점 데이터가 들어있고, 재호출은 왕복 지연 + PostgreSQL 커넥션 낭비를 만든다.
- **D-05:** 필터는 얕은 사본을 만든다. `data`의 각 값이 `List`면 `sucursal == 선택값`인 행만 남기고, `List`가 아니면(예: `stock_resumen` Map) 그대로 통과시킨다.
- **D-06:** 어떤 리스트의 행들이 `sucursal` 키를 아예 갖지 않으면 그 리스트도 그대로 통과시킨다. 전역 데이터를 빈 리스트로 만들지 않기 위함.
- **D-07:** 콤보박스 위치는 날짜 버튼과 같은 줄 우측 코너. 항목은 `Total` + 응답에 실제로 존재하는 sucursal 번호만.

### 모드 토글 (MSUC-03)
- **D-08:** 카드/테이블 토글은 콤보박스 옆(우측 코너). 테이블 모드에서는 지점 콤보를 숨긴다 — 비교 테이블은 전 지점 비교가 목적이므로 지점 필터가 의미를 잃는다.
- **D-09:** 카드로 돌아오면 직전에 선택했던 지점을 복원한다.
- **D-10:** 선택한 모드는 SharedPreferences에 저장해 다음 진입 시 유지한다. 지점 선택은 저장하지 않는다(진입 시 항상 Total).
- **D-11:** 테이블 모드는 기존 `ResumenDelDiaMultipleSucursalesView`를 원본 `data`로 그대로 렌더한다.

### 헤더 슬롯
- **D-12:** 두 기존 뷰(`SingleSucursalView`, `MultipleSucursalesView`) 모두에 `Widget? headerTrailing` 선택 파라미터를 추가해 날짜 버튼 줄 우측에 컨트롤을 꽂는다. 토글은 두 모드 모두에서 보여야 하므로 양쪽에 필요하다.
- **D-13:** 좁은 화면(< 600px)에서는 날짜 버튼 아래로 컨트롤을 내린다. 한 줄에 밀어넣으면 넘친다.

### Stock Resumen (MSUC-04)
- **D-14:** `stock_resumen`은 `sucursal` 키가 없는 DB 전역 Map이다(`multiple_sucursales_view.dart:414`에서 `addAll`로 통째 사용). 지점을 골라도 값이 동일하므로 섹션 제목 옆에 "DB 전역" 배지를 붙여 오해를 막는다. 단일 뷰와 비교 뷰 양쪽에 적용한다.

### FVentas del Mes 범위 (MSUC-05)
- **D-15:** 의도된 동작은 **선택 날짜가 속한 달 전체**(1일~말일)다.
- **D-16:** 앱에는 범위 로직이 없다. `reports_api.dart:20-23`은 `date`만 보내고 범위는 서버 SQL이 정한다. 따라서 라벨을 붙이기 전에 서버가 실제로 월 전체를 반환하는지 **먼저 검증해야 한다.** 검증 없이 라벨을 붙이면 값과 라벨이 어긋날 수 있다.
- **D-17:** 라벨은 선택 날짜에서 파생한다(`yyyy-MM` + 말일). 서버 응답에 의존하지 않는다.

### 범위에서 제외
- **D-18:** 비교 테이블의 Total 열은 **이미 구현되어 있다** (`multiple_sucursales_view.dart:792` 컬럼, `:982-1023` 합산). 신규 작업 없음.
- **D-19:** 부모 화면의 미사용 중복 코드(`_buildSucursalSelector`, `_buildDateSelectorInAppBar`, `_buildComparisonView` 및 그 하위 ~1200줄)는 이번 범위에서 손대지 않는다. 별도 정리 작업으로 분리한다.

### Claude's Discretion
- 콤보박스/토글 위젯의 세부 스타일(아이콘, 간격, 색상)
- SharedPreferences 키 이름
- 필터 유틸의 파일 위치와 클래스/함수 이름

</decisions>

<canonical_refs>
## Canonical References

No external specs — 결정 사항은 위에 완전히 포함됨.

### 신설 대상
- `lib/screens/resumen_del_dia_multi_sucursal_view.dart` — 래퍼 위젯 (모드/지점 상태 소유)
- `lib/utils/sucursal_data_filter.dart` — 지점 필터 + 가용 지점 목록 유틸

### 수정 대상
- `lib/screens/resumen_del_dia_screen.dart` — `_buildResumenContent()`의 다중 지점 분기(2048-2069행)를 래퍼 호출로 교체
- `lib/screens/resumen_del_dia_single_sucursal_view.dart` — `headerTrailing` 파라미터 + 날짜 줄(107-129행) 레이아웃, Stock Resumen 섹션(1762행)
- `lib/screens/resumen_del_dia_multiple_sucursales_view.dart` — `headerTrailing` 파라미터 + `_buildDateSelectorButton()`(1142행), Stock Resumen 섹션(1308행)

### 읽기 전용 참고
- `lib/services/api/reports_api.dart` — `getResumenDelDia()` 요청 본문 (date/sucursal만 전송)
- `lib/services/api/http_request_handler.dart:236` — resumen_del_dia 원본 응답 로깅 (월 범위 검증에 사용)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ResumenDelDiaSingleSucursalView`: 카드 레이아웃 전체 + 섹션별 합산 로직 내장. 여러 sucursal 행을 받아도 합산해서 하나로 표시한다.
- `ResumenDelDiaMultipleSucursalesView`: 비교 테이블 + Total 열 + Stock Resumen 분할 레이아웃 완성 상태.
- `_ResizableSplitView` (multiple_sucursales_view.dart:1529): SharedPreferences로 패널 폭을 저장하는 패턴 — 모드 저장에 같은 방식 사용 가능.

### Established Patterns
- StatefulWidget + setState() 기반 상태 관리
- 뷰 위젯은 `data` / `selectedDate` / `serverUrl` / 콜백 3종을 생성자로 받는다
- 주석은 한국어, 식별자는 영어

### Integration Points
- `resumen_del_dia_screen.dart:_hasMultipleSucursales()` — 분기 판정. 그대로 유지하고 분기 결과만 래퍼로 교체.
- 응답 구조: `vcodes` / `vdetalle` / `vcodes_mpago` / `gastos` / `ingresos` / `fventas` / `fventas_mes`는 `sucursal` 키를 가진 행들의 List. `stock_resumen`은 Map(전역). `stocks`, `fecha`는 별도.

</code_context>

<specifics>
## Specific Ideas

목업으로 레이아웃 확정: 날짜 버튼 중앙, 우측 코너에 [지점 콤보][카드|테이블 토글]. 카드 섹션 순서는 기존 단일 뷰 그대로 (Ventas → Gastos → FVentas del Día → FVentas del Mes → Stock Resumen).

</specifics>

<deferred>
## Deferred Ideas

- 부모 화면의 미사용 중복 코드 ~1200줄 정리 (D-19)
- FVentas 리포트의 100건 표시 제한 및 기간 총계 행 — 별도 작업으로 분리

</deferred>

---

*Phase: 04-multi-sucursal-resumen*
*Context gathered: 2026-08-03*
