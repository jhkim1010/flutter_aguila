# FVentas Period Totals — Design Spec

Date: 2026-08-04
Requirements: FVT-01, FVT-02 (ROADMAP Phase 5)

## Problem

FVentas 보고서 맨 아래 합계 행은 **화면에 로드된 행만** 더한다. 기간을 길게 잡아도
그 값은 첫 페이지 분량에 대한 합계라, 사용자가 기대하는 "기간 전체"와 다르다.

`report_data_loader.dart:571` 이 `getFVentasReport` 를 **커서 없이 1회만** 호출한다.
`reports_api.dart:327` 에 `lastIdFventa` 파라미터가 있으나 호출부가 없다.

추가로, 현재 합계는 칼럼별 단순 합이라 문서 유형 구분이 없다. 사용자는 유형별로
나뉜 값을 원한다.

## Goal

보고서 맨 아래 한 줄에, **기간 전체 기준으로** 다음 9개 문서 유형 각각의
**건수 · 총액 · IVA** 를 표시한다.

| 그룹 | 유형 |
|---|---|
| Factura | A, B, M |
| Nota de crédito | NCA, NCB, NCM |
| Nota de débito | NDA, NDB, NDM |

마지막에 전체 총계를 붙인다.

## Decisions

사용자 확인을 거친 결정:

1. **합계 출처** — 클라이언트가 `last_id_fventa` 커서로 전 페이지를 순회한 뒤 합산한다.
   서버 변경이 필요 없고 항상 정확하다. 대가는 긴 기간에서 요청이 여러 번 나가는 것.
2. **레이아웃** — 요청대로 맨 아래 **한 줄**. 숫자가 27개라 화면을 넘치므로 가로 스크롤한다.
3. **IVA** — 전 유형에 `monto × 0.173553719` (= 21/121) 역산. 기존 Resumen 코드와 동일한 상수.
4. **Nota de crédito 부호** — 음수로 표시한다.

## Unknown, and how the design absorbs it

실제 DB 의 `tipofactura` 값 목록을 확인하지 못했다. 코드에서 발견된 값은
`A`, `B`, `C`, `NCA`, `NCB`, `NCM` 뿐이고 (`resumen_del_dia_screen.dart:2492`),
요청된 `M` / `NDA` / `NDB` / `NDM` 은 코드 어디에도 없다. `C` 의 의미도 불명확하다.

**설계로 흡수한다:**

- 9개 유형은 **항상 고정으로 표시**한다. 데이터에 없으면 0 으로 나온다.
  사용자가 "이 기간에 ND 가 없다"는 것을 볼 수 있어야 한다.
- 9개에 없는 코드(`C` 등)가 데이터에 나타나면 **`Otros` 칸에 합산**하고,
  어떤 코드였는지 로그로 남긴다. 조용히 버리지 않는다.
- 총계는 `Otros` 를 포함한다. 그래야 총계가 실제 데이터와 일치한다.

로그에서 실제 코드가 확인되면 상수 목록만 고치면 된다.

## Architecture

세 조각으로 나눈다. 각각 독립적으로 이해·테스트 가능하다.

### 1. 집계 — `lib/utils/fventas_period_totals.dart` (신설)

순수 함수. 네트워크도 위젯도 모른다.

```dart
class FVentasTypeTotal {
  final String code;      // 'A', 'NCA', 'Otros' ...
  final String label;     // 'Factura A', 'NC A' ...
  final int count;
  final double monto;     // NC 는 음수
  final double iva;       // monto * ivaRate, 부호는 monto 를 따른다
}

class FVentasPeriodTotals {
  final List<FVentasTypeTotal> byType;   // 항상 9개 + Otros
  final FVentasTypeTotal grand;          // 전체 총계
  final Set<String> unknownCodes;        // 로깅·후속 조사용

  static FVentasPeriodTotals from(List<dynamic> rows);
}
```

**부호 규칙.** DB 의 `monto` 가 NC 에서 이미 음수인지 확인하지 못했다. 어느 쪽이든
결과가 같도록 `NC*` 는 `-monto.abs()` 로 정규화한다. 그러면 DB 가 양수를 주든 음수를
주든 화면에는 항상 음수로 나온다. 원본 부호는 로그에 남겨 나중에 확인할 수 있게 한다.

`IVA` 는 `monto` 에서 파생되므로 부호가 자동으로 따라간다.

### 2. 전 기간 수집 — `report_data_loader.dart` 에 메서드 추가

```dart
Future<List<dynamic>> _fetchAllFVentasRows(Map<String, dynamic> filters)
```

- 첫 페이지는 이미 화면용으로 받은 응답을 재사용한다. 같은 데이터를 두 번 받지 않는다.
- 이후 마지막 행의 `id_fventa` 를 `lastIdFventa` 로 넘겨 반복한다.
- 종료 조건: `pagination.hasMore == false`, 또는 빈 응답, 또는 **직전 페이지와 같은
  커서**(서버가 커서를 무시할 때 무한 루프 방지).
- **안전 상한 200 페이지.** 도달하면 중단하고, 합계가 불완전함을 화면과 로그에
  명시한다. 조용히 잘린 합계를 정확한 값처럼 보여주지 않는다.
- 진행 상황을 콜백으로 알려 UI 가 "Calculando totales… N" 을 띄운다.

**이 단계는 느리다.** 표 자체는 첫 페이지가 오면 바로 그린다. 합계 줄만 나중에 채운다.
사용자가 표를 보는 동안 뒤에서 나머지를 받는다.

### 3. 표시 — `lib/widgets/fventas_totals_strip.dart` (신설)

기존 칼럼 정렬 합계 행(`buildFixedTotalRow`) **아래**에 별도 줄로 붙인다.
칼럼 그리드와 무관하므로 자체 가로 스크롤 컨트롤러를 갖는다.

```
TOTAL │ FA 12  1.234.567  IVA 214.286 │ FB 45  2.345.678  IVA 407.135 │ FM 3 … →
```

- 유형별 블록. 건수·총액·IVA 를 한 블록에 묶어 어느 숫자가 어느 유형인지 붙어 보이게 한다.
- 음수는 빨간색으로 구분한다.
- 수집 중에는 진행 표시, 상한에 걸렸으면 경고 아이콘.

## Data Flow

```
사용자가 기간 선택
   → getFVentasReport(filters)            ← 1회, 기존 경로
   → 표 렌더 (첫 페이지)                    ← 즉시
   → _fetchAllFVentasRows(filters)        ← 백그라운드, 커서 반복
   → FVentasPeriodTotals.from(전체 행)
   → setState → FVentasTotalsStrip 갱신
```

## Error Handling

| 상황 | 처리 |
|---|---|
| 중간 페이지 요청 실패 | 중단. 그때까지 모은 값으로 합계를 내되 **"불완전" 표시**를 켠다 |
| 200 페이지 상한 도달 | 위와 동일. 로그에 실제 수집 행 수 기록 |
| `pagination` 자체가 없음 | 응답이 빈 리스트일 때까지 반복. 커서가 안 움직이면 중단 |
| 미지의 `tipofactura` | `Otros` 에 합산 + 로그 |
| 기간 변경/화면 이탈 | 진행 중이던 수집을 취소해 낡은 합계가 덮어쓰지 않게 한다 |

**불완전한 합계를 정확한 값처럼 보이게 하지 않는다.** 이것이 이 기능의 핵심이다 —
지금 버그도 "틀린 합계가 맞는 것처럼 보이는" 문제다.

## Testing

`FVentasPeriodTotals.from()` 은 순수 함수라 단위 테스트가 쉽다:

- 9개 유형이 데이터에 하나도 없어도 9칸이 0 으로 나온다
- `NCA` 의 `monto` 가 양수로 와도 결과는 음수다
- `NCA` 의 `monto` 가 음수로 와도 결과는 음수다 (이중 부호 반전 없음)
- 미지 코드는 `Otros` 로 가고 `unknownCodes` 에 기록된다
- 총계 = 9개 + `Otros` 의 합
- IVA 부호가 `monto` 부호를 따른다

수집 루프는 `hasMore` / 빈 응답 / 커서 정체 / 상한 도달을 가짜 응답으로 검증한다.

## Out of Scope

- 서버측 집계 필드 추가 — 백엔드 작업이라 이번 범위 밖. 나중에 추가되면
  수집 루프만 걷어내고 집계 함수는 그대로 쓸 수 있다.
- `Total Empresas 0` 등 Items 보고서 문제 — 별개 사안.
- FVentas 표 자체의 페이지네이션 UI — 표시 행 수는 지금 그대로 둔다.
