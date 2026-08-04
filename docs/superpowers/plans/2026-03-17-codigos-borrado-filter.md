# Codigos Borrado Filter Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 기본적으로 `borrado=0` 항목만 표시하고, "Solo borrados" 체크 시 `borrado=1` 항목만 표시한다.

**Architecture:** `report_data_loader.dart`의 3개 필터 블록에서 `solo_borrados=1` 조건부 파라미터를 `borrado=0/1` 항상-전송 파라미터로 교체한다. UI 변경 없음.

**Tech Stack:** Flutter/Dart, 기존 `_databaseService.getCodigos` / `getTodocodigos` API

---

## Chunk 1: Core filter change

### Task 1: Codigos 초기 로드 블록 수정

**Files:**
- Modify: `lib/screens/helpers/report_data_loader.dart:686-688`

- [ ] **Step 1: 라인 686-688 변경**

  현재 코드 (`report_data_loader.dart:686`):
  ```dart
  if (_codigosSoloBorrados) {
    filters['solo_borrados'] = '1';
  }
  ```

  변경 후:
  ```dart
  if (_codigosSoloBorrados) {
    filters['borrado'] = '1';
  } else {
    filters['borrado'] = '0';
  }
  ```

- [ ] **Step 2: TodoCodigos 초기 로드 블록 수정 (라인 747-749)**

  현재 코드 (`report_data_loader.dart:747`):
  ```dart
  if (_codigosSoloBorrados) {
    filters['solo_borrados'] = '1';
  }
  ```

  변경 후:
  ```dart
  if (_codigosSoloBorrados) {
    filters['borrado'] = '1';
  } else {
    filters['borrado'] = '0';
  }
  ```

- [ ] **Step 3: 페이지네이션 블록 수정 (라인 1153-1155)**

  현재 코드 (`report_data_loader.dart:1153`):
  ```dart
  if (_codigosSoloBorrados) {
    filters['solo_borrados'] = '1';
  }
  ```

  변경 후:
  ```dart
  if (_codigosSoloBorrados) {
    filters['borrado'] = '1';
  } else {
    filters['borrado'] = '0';
  }
  ```

- [ ] **Step 4: Flutter 빌드 확인**

  Run: `flutter analyze lib/screens/helpers/report_data_loader.dart`
  Expected: No issues

- [ ] **Step 5: 수동 테스트**

  1. 앱 실행 후 Codigos 보고서 열기
  2. 기본 상태: `borrado=false` 항목만 표시되는지 확인
  3. "Solo borrados" 체크박스 활성화: `borrado=true` 항목만 표시되는지 확인
  4. 체크박스 비활성화: 다시 `borrado=false` 항목만 표시되는지 확인
  5. Todocodigos 보고서에서도 동일하게 확인

- [ ] **Step 6: Commit**

  ```bash
  git add lib/screens/helpers/report_data_loader.dart
  git commit -m "feat: default to borrado=0 filter in codigos report"
  ```

---

> **Note (Out of Scope):** 페이지네이션 블록(~라인 1153)은 `_selectedSucursal` 필터가 누락된 기존 버그가 있으나 이번 작업 범위 외. 별도 이슈로 처리.
