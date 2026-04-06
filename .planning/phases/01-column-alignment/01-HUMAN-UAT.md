---
status: partial
phase: 01-column-alignment
source: [01-VERIFICATION.md]
started: 2026-04-05
updated: 2026-04-05
---

## Current Test

[awaiting human testing]

## Tests

### 1. ALIGN-01 — 헤더/데이터 칼럼 픽셀 정렬 확인
expected: Stocks 리포트를 열었을 때 헤더 칼럼과 데이터 행 칼럼이 픽셀 단위로 정렬되어 표시된다
result: [pending]

### 2. ALIGN-02 — 리사이즈 동기화 확인
expected: 칼럼 리사이즈 핸들을 드래그하면 헤더와 데이터 행 폭이 동시에 업데이트되어 어긋남이 없다
result: [pending]

### 3. ALIGN-03 — 스크롤 동기화 확인
expected: 가로 스크롤 시 헤더와 데이터 행이 동일한 x 오프셋으로 이동, 세로 스크롤 시 고정 헤더 유지, 무한스크롤 정상 작동
result: [pending]

### 4. Regression — 필터/칼럼 폭 persist 확인
expected: 필터 변경 시 데이터 재로드 정상, 칼럼 폭이 앱 재시작 후에도 유지됨
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
