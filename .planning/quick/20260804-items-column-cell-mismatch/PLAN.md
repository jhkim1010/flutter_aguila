---
type: quick
slug: items-column-cell-mismatch
created: 2026-08-04
files_modified:
  - lib/widgets/items_builder.dart
---

# Quick Task: Items 리포트 칼럼/셀 개수 불일치

## 증상

Items 리포트(`themarket59`)를 열면 Productos 테이블 자리에 빨간 에러 박스:

```
'package:flutter_app/widgets/resizable_data_table.dart': Failed assertion:
line 158 pos 7: 'widget.rows.isEmpty || widget.rows.every((row) => row.length == widget.columns.length)'
```

같은 화면의 요약 카드에 `Total Empresas 0`, `Total Colores 0`, `Resumen x Color: No hay datos`.

## 근본 원인

`ItemsBuilder`에서 **칼럼 목록은 데이터에서 파생되는데 행 셀은 하드코딩**되어 있다.

`_buildRowCells` (`items_builder.dart:35`)는 조건 없이 **항상 8개 위젯**을 반환한다:
`codigo1, desc1, ProductName, totalCantidad, CategoryCode, CompanyCode, tprendas, timporte`.

반면 `activeColDefs` (`items_builder.dart:413-429`)는 **가변**이다:

```dart
final dataKeys = (productsList.first as Map<String, dynamic>).keys.toSet();
final activeColDefs = colDefs
    .where((c) => dataKeys.contains(c.key) || productsList.isEmpty)   // 줄어들 수 있음
    .toList();
for (final key in dataKeys) {                                        // 늘어날 수 있음
  if (!excludedKeys.contains(key) && !activeColDefs.any((c) => c.key == key)) {
    activeColDefs.add(TableColumnDef(key: key, label: key, defaultWidth: 120));
  }
}
```

응답의 product 객체가 정확히 그 8개 키를 갖지 않으면 개수가 어긋난다.
`Total Empresas 0`이 근거다 — 응답에 `CompanyCode`가 없어 칼럼이 7개로 줄었는데
행은 여전히 8칸이다.

**칼럼이 늘어나는 방향도 똑같이 깨진다.** 서버가 새 필드를 추가하면 칼럼은 9개가 되고
행은 8칸에 머문다. 즉 이 버그는 서버 응답 스키마가 바뀔 때마다 재발한다.

## 참조 구현

`gastos_builder.dart:55-111`은 이미 올바르다. `buildRows(data, columnKeys: ...)`가
키 목록을 받아 `keys.map((key) => _buildRowCell(item, key, ...))`로 셀을 만든다.
칼럼 목록이 곧 셀 목록이므로 구조적으로 어긋날 수 없다.

## 작업

### Task 1: 셀 생성을 칼럼 키 기준으로 전환

`lib/widgets/items_builder.dart`

- `buildRows(List<dynamic> data, {List<String>? columnKeys})` 로 시그니처 변경.
  `columnKeys`가 없으면 `buildColumnDefs()`의 키를 쓴다 (기존 동작 보존).
- `_buildRowCells(item, keys)` → `keys.map((key) => _buildRowCell(item, key)).toList()`
- `_buildRowCell(item, key)` 신설. `switch (key)`로 기존 서식 로직을 그대로 옮긴다:
  - `codigo1` — bold, fontSize 12, maxLines 1, ellipsis
  - `desc1`, `ProductName` — fontSize 10, grey[700], maxLines 2, ellipsis
  - `totalCantidad`, `tprendas` — `NumberFormat('#,##0')`, 우측 정렬
  - `timporte` — `NumberFormat('#,##0')` (`$` 및 `,` 제거 후 파싱), 우측 정렬
  - `CategoryCode`, `CompanyCode` — fontSize 10, grey[700]
  - `default` — 서버가 추가한 미지의 칼럼용 일반 Text
- 호출부(`items_builder.dart:435`)에서 `activeColDefs`의 키를 넘긴다.

### Task 2: 불일치 진단 로그

`activeColDefs` 확정 직후, 칼럼과 데이터 키의 차이를 출력한다:

- 활성 칼럼 키 목록과 개수
- 데이터에만 있는 키 (칼럼으로 승격된 것)
- 칼럼 정의에는 있으나 데이터에 없어 빠진 키
- 첫 행 셀 수와 칼럼 수 비교, 어긋나면 `⚠️` 표시

칼럼이 왜 그 개수가 됐는지 로그만 보고 알 수 있어야 한다.

## 검증

- `flutter analyze lib/widgets/items_builder.dart` — error 0건
- `_buildRowCells`가 `keys.length`와 같은 길이를 반환하는지 코드상 확인
- Items 리포트 재실행 시 assertion 미발생 (실기기 확인 필요)

## Out of Scope

- `Total Empresas 0` / `Total Colores 0` 자체 — 응답에 해당 필드가 없는 것이
  서버 문제인지 정상인지는 별개 조사다. 이번 변경은 **필드가 없어도 테이블이
  깨지지 않게** 하는 것까지다.
- `gastos_builder.dart` — 이미 올바른 패턴이라 손대지 않는다.
