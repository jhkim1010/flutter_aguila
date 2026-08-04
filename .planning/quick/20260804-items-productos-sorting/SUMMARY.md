---
type: quick
slug: items-productos-sorting
status: complete
created: 2026-08-04
completed: 2026-08-04
files_modified:
  - lib/widgets/items_builder.dart
---

# Summary: Items Productos 정렬

**Productos 목록이 기본으로 Total Cantidad 내림차순으로 나오고, 헤더 클릭 정렬이 실제로 동작한다**

## 근본 원인

정렬 상태만 저장되고 **아무도 데이터를 정렬하지 않았다.**

`report_screen_legacy.dart:5581-5586`의 `onSort` 콜백:

```dart
onSort: (column, ascending) {
  setState(() {
    _sortColumn = column;
    _sortAscending = ascending;
  });
},
```

`setState`로 리빌드는 일어나고 `ItemsBuilder`가 `sortColumn`/`sortAscending`을 받지만,
그 값은 **`ResizableDataTable`에 넘겨 헤더 화살표를 그리는 데만** 쓰였다.
`productsList`는 서버가 준 순서 그대로 `buildRows`에 들어갔다.

즉 헤더를 클릭하면 화살표만 바뀌고 행 순서는 그대로였다.

## 수정

### 1. `sortProducts()` 신설

`displayedItemsCount`로 **자르기 전에** 호출한다. 자른 뒤 정렬하면 "먼저 로드된
100건 중 상위"가 나오지 사용자가 기대하는 "전체 중 상위"가 아니다.

- 기본값: `totalCantidad` **내림차순** (요청 사항)
- `totalCantidad` / `tprendas` / `timporte` 는 숫자 비교.
  문자열로 비교하면 `"9" > "16"` 이 된다.
- 값이 없는 행은 정렬 방향과 무관하게 항상 아래로. 그러지 않으면
  오름차순에서 빈 행이 목록 맨 위를 차지한다.
- 원본 리스트는 변형하지 않는다.

### 2. `resolveSortColumn()` 가드

`_sortColumn`은 보고서 화면 전체가 공유하는 상태다. FVentas에서 `monto`로 정렬한 뒤
Items로 오면 그 키가 그대로 넘어온다. Items 데이터에 없는 키로 정렬하면 전 행이
"값 없음"이 되어 순서가 사실상 무작위가 된다.

데이터에 없는 키면 기본 정렬로 떨어지고 경고를 남긴다.

### 3. 헤더 화살표를 실제 상태와 일치

`sortColumn`이 null인 기본 상태에서 그대로 넘기면, `totalCantidad` 내림차순으로
정렬돼 있는데도 화살표가 어디에도 안 붙어 **정렬이 안 된 것처럼 보인다.**
정렬과 화살표가 모두 `resolveSortColumn()`을 거치도록 통일했다.

## 검증

| 항목 | 결과 |
|---|---|
| `flutter analyze lib/` | error **0건** |
| 정렬이 `.take(displayedItemsCount)` 앞인지 | 코드상 확인 (453행 → 이후 buildRows) |
| 숫자 칼럼 비교 | `_numericKeys` 집합으로 분기 |

**미검증:** 실기기에서 헤더 클릭 시 순서가 바뀌는지, 기본 진입 시 수량 내림차순으로
나오는지 확인하지 못했다.

## 참고

같은 `onSort → 상태만 저장` 구조가 다른 보고서에도 있는지는 확인하지 않았다.
이번 변경은 Items Productos 테이블에 한정된다.
