# Phase 2: Table UX - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-06
**Phase:** 02-table-ux
**Areas discussed:** 필터 UX, 페이지네이션

---

## 논의 영역 선택

| Option | Description | Selected |
|--------|-------------|----------|
| 필터 UX 개선 | 필터바 사용성 개선 | ✓ |
| 페이지네이션 전환 | 무한스크롤 → 페이지 기반 | |
| 정렬 UX 보완 | 시각적 피드백 세부 조정 | |

**User's choice:** 필터 UX 개선만 선택 (나머지는 논의 중 자연스럽게 다룸)

---

## 필터 UX

| Option | Description | Selected |
|--------|-------------|----------|
| 필터 초기화 버튼 없음 | 리셋 버튼 추가 필요 | |
| 텍스트 검색이 Enter 후에만 작동 | 즉시 필터링 전환 | |
| 필터바가 좋다 | 현재 UI 충분 | ✓ |

**User's choice:** 필터바가 좋다 — 현재 상태로 충분
**Notes:** 필터 관련 큰 개선 불필요

---

## 페이지네이션

### 방식 선택

| Option | Description | Selected |
|--------|-------------|----------|
| 무한스크롤 유지 | 현재 방식 유지 | |
| 페이지 기반으로 전환 | 이전/다음 + 페이지 크기 변경 | ✓ |
| 둘 다 지원 | 모드 전환 옵션 | |

**User's choice:** 페이지 기반으로 전환

### UI 배치

| Option | Description | Selected |
|--------|-------------|----------|
| 테이블 하단 | ◀ 1 2 3 ... ▶ + 크기 선택기 | ✓ |
| 테이블 상단 | 필터바 옆/아래 | |
| 상하 모두 | 상단: 정보/크기, 하단: 이전/다음 | |

**User's choice:** 테이블 하단

### 페이지 크기

| Option | Description | Selected |
|--------|-------------|----------|
| 25 / 50 / 100 | 소/중/대 3단계 | |
| 50 / 100 / 200 | 대용량 데이터 기준 | ✓ |
| Claude 판단 | Claude가 결정 | |

**User's choice:** 50 / 100 / 200

---

## Claude's Discretion

- 페이지네이션 컨트롤 세부 디자인
- 서버 API 파라미터 전환 방식
- 무한스크롤 코드 제거 범위

## Deferred Ideas

None
