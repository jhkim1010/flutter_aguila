---
type: quick
slug: items-column-cell-mismatch
status: complete
created: 2026-08-04
completed: 2026-08-04
files_modified:
  - lib/widgets/items_builder.dart
---

# Summary: Items 리포트 칼럼/셀 개수 불일치

**셀 목록을 하드코딩하는 대신 칼럼 키에서 파생시켜, 응답 스키마가 바뀌어도 assertion 이 깨지지 않게 했다**

## 근본 원인

`ItemsBuilder`에서 칼럼은 데이터에서 파생되는데 행 셀은 고정이었다.

- `_buildRowCells` — 조건 없이 **항상 8개 위젯** 반환
- `activeColDefs` — 응답 키에 따라 **줄거나 늘어남**

`themarket59` 응답에 `CompanyCode`가 없어 칼럼이 7개로 줄었고, 행은 8칸 그대로라
`resizable_data_table.dart:158`의 `row.length == columns.length` assertion 이 터졌다.

화면의 `Total Empresas 0`이 그 증거였다.

**늘어나는 방향도 같은 문제였다.** 서버가 새 필드를 추가하면 칼럼이 9개가 되는데
행은 8칸에 머문다. 즉 스키마가 바뀔 때마다 재발하는 구조였다.

## 수정

`gastos_builder.dart:55-111`의 패턴을 그대로 따랐다 — 그 빌더는 이미 올바르게
`keys.map((key) => _buildRowCell(item, key))` 로 셀을 만들고 있었다.

```dart
static List<List<Widget>> buildRows(List<dynamic> data, {List<String>? columnKeys})
static List<Widget> _buildRowCells(Map<String, dynamic> item, List<String> keys)
static Widget _buildRowCell(Map<String, dynamic> item, String key)   // 신설
```

`_buildRowCell`은 `switch (key)`로 기존 서식을 보존한다:

| 키 | 서식 |
|---|---|
| `codigo1` | bold 12, 1줄, ellipsis |
| `desc1`, `ProductName` | 10 grey, 2줄, ellipsis |
| `totalCantidad`, `tprendas`, `timporte` | `#,##0`, 우측 정렬 |
| `default` | 일반 Text — `CategoryCode`/`CompanyCode` 및 서버가 새로 내린 키 |

호출부는 `columnKeys: activeKeys` 를 넘긴다. 셀이 칼럼에서 파생되므로
**개수가 구조적으로 어긋날 수 없다.**

부수 효과: 행마다 키가 달라도 안전해졌다. `item[key]`가 null 이면 빈 문자열이 되고
셀 개수는 그대로다. 이전에는 `productsList.first` 의 키만 보고 칼럼을 정했으므로
뒤쪽 행의 스키마가 다르면 무슨 일이 날지 정의되지 않았다.

## 추가한 진단 로그

`activeColDefs` 확정 직후 출력:

```
🧮 [ItemsBuilder] 칼럼 구성 진단
   → 활성 칼럼 7개: [codigo1, desc1, ProductName, totalCantidad, CategoryCode, tprendas, timporte]
   → 응답 키 9개: [...]
   → ➕ 응답에만 있어 칼럼으로 추가된 키: [...]
   → ➖ 응답에 없어 빠진 칼럼: [CompanyCode]
   → ✅ 행 셀 7개 = 칼럼 7개
```

칼럼이 왜 그 개수가 됐는지 로그만 보고 판단할 수 있다. 불일치 시 `⚠️` 로
assertion 보다 먼저 잡힌다.

## 검증

| 항목 | 결과 |
|---|---|
| `flutter analyze lib/` | error **0건** |
| `buildRows` 호출부 전수 확인 | items 1곳뿐, `columnKeys` 전달됨 |
| 빈 테이블 분기 (`rows: const []`) | assertion 대상 아님 (isEmpty 통과) |

**미검증:** 실기기에서 Items 리포트를 다시 열어 assertion 이 사라졌는지,
로그가 `➖ CompanyCode` 를 실제로 찍는지는 확인하지 못했다.

## 범위 밖 — 별도 조사 필요

`Total Empresas 0`, `Total Colores 0`, `Resumen x Color: No hay datos` 는 그대로다.
응답에 `CompanyCode` / 색상 필드가 없는 것이 서버 쿼리 문제인지 이 DB 의 정상 상태인지는
확인하지 않았다. 이번 변경은 **필드가 없어도 테이블이 깨지지 않게** 하는 데까지다.
새 로그의 `➖ 응답에 없어 빠진 칼럼` 줄이 그 조사의 출발점이 된다.
