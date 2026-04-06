# Phase 1: Column Alignment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-05
**Phase:** 01-column-alignment
**Areas discussed:** 구현 전략, 스크롤 동기화, 칼럼 폭 관리, 다른 리포트 영향
**Mode:** --auto (all decisions auto-selected)

---

## 구현 전략

| Option | Description | Selected |
|--------|-------------|----------|
| 기존 위젯 수정 | ReportTableMeasuredColumns, StocksBuilder 등 기존 코드 수정 — 리스크 최소화 | ✓ |
| 새 통합 위젯 교체 | 새로운 테이블 위젯을 처음부터 작성하여 교체 | |

**User's choice:** [auto] 기존 위젯 수정 (recommended default)
**Notes:** Constraints에 '기존 기능 동작에 영향 없이 개선' 명시되어 있어 기존 코드 수정이 안전

---

## 스크롤 동기화

| Option | Description | Selected |
|--------|-------------|----------|
| 단일 ScrollController 공유 | Flutter 기본 제공, 헤더-데이터 간 동일 controller 사용 | ✓ |
| LinkedScrollControllerGroup | 추가 패키지 필요, 더 정교한 동기화 가능 | |

**User's choice:** [auto] 단일 ScrollController 공유 (recommended default)
**Notes:** 추가 패키지 없이 Flutter 기본 제공으로 충분

---

## 칼럼 폭 관리

| Option | Description | Selected |
|--------|-------------|----------|
| 단일 상태 (Single source of truth) | 헤더와 데이터 행이 동일한 폭 목록 참조 — 불일치 근본 원인 제거 | ✓ |
| 각 위젯에서 개별 관리 | 헤더와 행이 각각 폭 관리, 이벤트로 동기화 | |

**User's choice:** [auto] 단일 상태 (recommended default)
**Notes:** ALIGN-01, ALIGN-02 요구사항 충족의 핵심

---

## 다른 리포트 영향

| Option | Description | Selected |
|--------|-------------|----------|
| Stocks 전용 수정 | Stocks에서만 검증, 다른 리포트는 v2에서 확장 | ✓ |
| 공용 위젯 수정 | 모든 리포트에 적용되도록 공용 위젯 수정 | |

**User's choice:** [auto] Stocks 전용 수정 (recommended default)
**Notes:** REQUIREMENTS.md에 ALIGN-04는 v2로 지연, Phase 1은 Stocks만 대상

---

## Claude's Discretion

- 기존 ReportTableMeasuredColumns vs StocksBuilder 내 리사이즈 핸들 통합/분리 판단
- ScrollController 공유 구현 세부 방식 (위젯 트리 구조)
- 기존 코드 리팩토링 범위 (최소 변경 원칙 내에서)

## Deferred Ideas

- ALIGN-04: 다른 리포트 칼럼 정렬 확장 → v2
- ALIGN-05: 칼럼 폭 자동 계산 → v2
