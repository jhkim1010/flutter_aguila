# Flutter Aguila — 비즈니스 리포트 앱

## What This Is

멀티플랫폼(iOS, Android, macOS, Windows, Linux) Flutter 비즈니스 리포트 앱.
원격 PostgreSQL 서버에 연결하여 판매(Ventas), 재고(Stocks), 아이템(Items), 지출(Gastos) 등의 리포트를 조회하고 PDF/Excel로 내보내기 가능.
오프라인 SQLite 캐시, 바이오메트릭 인증(iOS), 다국어(스페인어/영어/한국어) 지원.

## Core Value

리포트 테이블이 정확하고 일관되게 표시되어야 한다 — 헤더와 행의 칼럼 폭/위치가 항상 완벽히 일치해야 함.

## Requirements

### Validated

- ✓ 원격 DB 서버 연결 및 자격증명 관리 — existing
- ✓ Ventas(판매) 리포트 조회 및 필터링 — existing
- ✓ Stocks(재고) 리포트 조회 — existing
- ✓ Items 리포트 조회 — existing
- ✓ Gastos(지출) 리포트 조회 — existing
- ✓ Codigos/Todocodigos 조회 — existing
- ✓ Resumen del dia(일일 요약) — existing
- ✓ PDF/Excel 내보내기 — existing
- ✓ 오프라인 SQLite 캐시(200MB+ 최적화) — existing
- ✓ 바이오메트릭 인증(iOS) — existing
- ✓ 칼럼 리사이즈 기능 — existing
- ✓ 칼럼 가시성 설정(ConfigService) — existing
- ✓ 다중 서버 연결 관리(ConnectionManager) — existing
- ✓ 자동 재연결(AutoConnectionHandler) — existing
- ✓ 다국어 지원(es/en/ko) — existing

### Active

- [ ] Stocks 리포트 테이블 헤더/행 칼럼 정렬 완벽 일치
- [ ] 테이블 UX 전반 개선 (정렬, 필터, 페이지네이션)
- [ ] 리포트 화면 Riverpod 상태관리 전환 (setState → Riverpod)

### Out of Scope

- 전체 앱 Riverpod 전환 — 이번 마일스톤에서는 리포트 화면에 한정
- 새로운 리포트 타입 추가 — 기존 리포트 개선에 집중
- 백엔드/API 변경 — 프론트엔드 개선만 진행

## Context

- 현재 상태관리: StatefulWidget + setState() 기반, 전역 상태 관리자 없음
- 테이블 구현: ReportTableBuilder, ReportTableMeasuredColumns 등 커스텀 위젯
- Stocks 리포트에서 헤더와 행의 칼럼 폭/위치 불일치가 리사이즈, 스크롤 등 여러 상황에서 발생
- 아키텍처: Layered MVC + Service-Locator 패턴
- 칼럼 폭 저장: `*_column_width_storage.dart` 파일들로 칼럼 폭 persist
- ConfigService: 싱글톤 패턴, asset JSON + SharedPreferences로 필드 가시성 관리

## Constraints

- **Tech Stack**: Flutter + Dart, 기존 서비스 레이어 유지
- **Platform**: iOS, Android, macOS, Windows, Linux 전체 지원 유지
- **API**: 기존 백엔드 API 인터페이스 변경 없음
- **Riverpod**: flutter_riverpod 패키지 사용, 리포트 화면에 한정
- **호환성**: 기존 기능 동작에 영향 없이 개선

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Riverpod 리포트 화면 한정 적용 | 전체 전환은 리스크 큼, 점진적 접근 | — Pending |
| Stocks 리포트 칼럼 정렬 우선 해결 | 사용자가 가장 불편해하는 문제 | — Pending |
| 테이블 UX 전반 개선 포함 | 정렬 외 필터/페이지네이션 등도 개선 필요 | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-05 after initialization*
