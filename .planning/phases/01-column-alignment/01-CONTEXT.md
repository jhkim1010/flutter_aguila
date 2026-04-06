# Phase 1: Column Alignment - Context

**Gathered:** 2026-04-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Stocks 리포트에서 어떤 상황(리사이즈, 스크롤, 가시성 변경)에서도 헤더와 데이터 행의 칼럼 폭/위치가 완벽히 일치하도록 보장한다. 다른 리포트(Ventas, Items, Gastos) 정렬 확장은 v2에서 진행한다.

</domain>

<decisions>
## Implementation Decisions

### 구현 전략
- **D-01:** 기존 테이블 위젯(ReportTableMeasuredColumns, StocksBuilder, ReportTableHeaderFooter, ReportTableDataRows) 수정 — 새로운 통합 위젯으로 교체하지 않음
- **D-02:** Stocks 리포트 전용 수정 — 공용 테이블 위젯에서 수정하되 Stocks에서만 검증. 다른 리포트 확장은 ALIGN-04(v2)

### 칼럼 폭 관리
- **D-03:** 칼럼 폭을 단일 상태(Single source of truth)로 관리 — 헤더와 데이터 행이 동일한 폭 목록을 참조하여 불일치 근본 원인 제거
- **D-04:** StocksColumnWidthStorage를 통한 폭 persist 유지 — 기존 저장 메커니즘 활용

### 스크롤 동기화
- **D-05:** 가로 스크롤: 헤더와 데이터 행이 동일한 ScrollController를 공유하여 x 오프셋 동기화
- **D-06:** 세로 스크롤: 고정 헤더 패턴 유지 — 데이터 행만 세로 스크롤, 헤더는 상단 고정

### 리사이즈 동기화
- **D-07:** 칼럼 리사이즈 시 헤더와 데이터 행 폭이 단일 상태를 통해 동시 업데이트 — setState 또는 동등한 상태 전파 메커니즘 사용

### Claude's Discretion
- 기존 ReportTableMeasuredColumns vs StocksBuilder 내 리사이즈 핸들 통합/분리 판단
- ScrollController 공유 구현 세부 방식 (위젯 트리 구조)
- 기존 코드 리팩토링 범위 (최소 변경 원칙 내에서)

</decisions>

<specifics>
## Specific Ideas

No specific requirements — 요구사항(ALIGN-01/02/03)이 명확하고 기술적 해결 과제임. 표준 Flutter 테이블 정렬 접근법 적용.

</specifics>

<canonical_refs>
## Canonical References

No external specs — 요구사항은 위 decisions와 아래 파일들에 완전히 포함됨.

### 핵심 위젯 코드 (수정 대상)
- `lib/widgets/report_table_measured_columns.dart` — 메인 테이블 위젯, 리사이즈 핸들 포함 (881줄)
- `lib/widgets/stocks_builder.dart` — Stocks 전용 칼럼 정의, 행 빌딩, 자체 리사이즈 핸들
- `lib/widgets/report_table_header_footer.dart` — 테이블 헤더/푸터 빌더
- `lib/widgets/report_table_data_rows.dart` — 데이터 행 빌더
- `lib/widgets/report_table_builder.dart` — 리포트 테이블 조립 빌더
- `lib/widgets/report_table_column_widths.dart` — 칼럼 폭 정의

### 화면 코드 (사용 지점)
- `lib/screens/reports/stocks_report_view.dart` — Stocks 리포트 화면, ScrollController 관리
- `lib/screens/reports/stocks_report_section.dart` — Stocks 리포트 섹션 컴포넌트

### 데이터/서비스 코드
- `lib/services/stocks_column_width_storage.dart` — 칼럼 폭 persist
- `lib/models/stocks_response.dart` — Stocks 응답 모델

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ReportTableMeasuredColumns` (report_table_measured_columns.dart): 메인 테이블 위젯 — 칼럼 측정 및 리사이즈 핸들 포함
- `ReportTableHeaderFooter`: 헤더/푸터 빌딩 유틸리티
- `ReportTableDataRows`: 데이터 행 빌딩 유틸리티
- `StocksColumnWidthStorage`: 칼럼 폭 영속 저장소
- `StocksBuilder.buildColumnDefs()`: Stocks 칼럼 정의 (TableColumnDef 목록)

### Established Patterns
- StatefulWidget + setState() 기반 상태 관리 (전역 상태 관리자 없음)
- Builder 클래스 패턴: UI 구성을 별도 클래스로 분리 (StocksBuilder, ItemsBuilder 등)
- `*_column_width_storage.dart` 패턴: 리포트별 칼럼 폭 저장소
- ConfigService 싱글톤: 칼럼 가시성 설정 관리

### Integration Points
- `StocksReportView` → `StocksBuilder` → `ReportTableMeasuredColumns` 위젯 체인
- `StocksReportView._scrollController`: 현재 단일 ScrollController 사용
- `StocksColumnWidthStorage`: 리사이즈된 폭 저장/복원

</code_context>

<deferred>
## Deferred Ideas

- ALIGN-04: Ventas, Items, Gastos 리포트에도 동일 칼럼 정렬 로직 적용 → v2
- ALIGN-05: 칼럼 폭 자동 계산 (콘텐츠 기반) → v2

</deferred>

---

*Phase: 01-column-alignment*
*Context gathered: 2026-04-05*
