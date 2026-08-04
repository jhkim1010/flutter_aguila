# Codigos Borrado Filter — Design Spec

Date: 2026-03-17

## Summary

기본적으로 `borrado=false` 항목만 표시하고, AppBar의 "Solo borrados" 체크박스를 활성화하면 `borrado=true` 항목만 표시한다.

## Problem

현재 Codigos/Todocodigos 보고서는 삭제 여부와 무관하게 모든 항목을 표시한다. "Solo borrados" 체크 시 삭제된 항목만 표시하는 기능은 이미 있으나, 기본 상태에서 삭제되지 않은 항목만 걸러내는 기능이 없다.

## Design

### Filter Logic Change

파일: `lib/screens/helpers/report_data_loader.dart`
수정 위치: 3곳 (라인 686, 747, 1153)

**Before:**
```dart
if (_codigosSoloBorrados) {
  filters['solo_borrados'] = '1';
}
```

**After:**
```dart
if (_codigosSoloBorrados) {
  filters['borrado'] = '1';
} else {
  filters['borrado'] = '0';
}
```

### Behavior

| `_codigosSoloBorrados` | API 파라미터 | 표시 항목 |
|---|---|---|
| `false` (기본) | `borrado=0` | 삭제 안 된 항목만 |
| `true` | `borrado=1` | 삭제된 항목만 |

### Unchanged

- AppBar 체크박스 UI (`_buildCodigosSoloBorradosCheckbox`)
- 상태 변수 `_codigosSoloBorrados`
- 체크박스 레이블 "Solo borrados"
- codigos_builder.dart, codigos_report_section.dart 등 모든 UI 파일

## Scope

- 수정 파일: `report_data_loader.dart` 1개
- 수정 행: 3개 블록 (codigos 초기 로드, todocodigos 초기 로드, 페이지네이션 공통)
- 백엔드: `borrado=0` 쿼리 파라미터 지원 확인됨

## Known Pre-existing Issue (Out of Scope)

페이지네이션 블록(라인 ~1153)은 이미 `_selectedSucursal` 필터가 누락된 상태이나, 이는 이번 변경의 범위 밖이다. `borrado` 필터만 추가하고 sucursal 누락은 별도 이슈로 처리한다.
