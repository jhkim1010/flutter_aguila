import 'package:flutter/material.dart';
import '../report_utils.dart';
import 'report_table_column_manager.dart';
import '../report_table_data_rows.dart';
import '../report_table_builder.dart';

/// 리포트 테이블 렌더링 관련 로직을 관리하는 클래스
/// report_table_builder.dart에서 추출된 테이블 렌더링 메서드를 포함
class ReportTableRenderer {
  // 디버깅: 괄호/구문 오류 확인을 위한 헬퍼 함수
  static void checkBracketBalance(String functionName, int startLine) {
    debugPrint('🔍 [구문 검사] $functionName 함수 괄호 균형 확인');
    debugPrint('   → 파일: report_table_builder.dart');
    debugPrint('   → 시작 라인: $startLine');
    debugPrint('   → 함수명: $functionName');
  }

  /// 테이블 콘텐츠 빌드 (수평 스크롤 여부 결정)
  static Widget buildTableContent({
    required BoxConstraints constraints,
    ScrollController? horizontalScrollController,
    required ReportType reportType,
    required List<dynamic> displayedList,
    required List<String> keys,
    required List<DataColumn> columns,
    required List<dynamic> dataList,
    required Color color,
    Function(Map<String, dynamic>)? onRowDoubleTap,
    Function(Map<String, dynamic>)? onRowTap,
    String? unit,
    Map<String, double>? columnWidths,
    String? sortColumn,
    bool sortAscending = true,
  }) {
    // 디버깅: 괄호/구문 오류 확인을 위한 로깅
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [구문 검사] _buildTableContent 함수 시작');
    debugPrint('   → 파일: report_table_builder.dart');
    debugPrint('   → 라인: ${1493}');
    debugPrint('   → 함수명: _buildTableContent');
    debugPrint('   → 파라미터 개수: 11');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
    debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
    debugPrint('   → constraints.minWidth: ${constraints.minWidth}');
    debugPrint('   → constraints.minHeight: ${constraints.minHeight}');
    debugPrint('   → horizontalScrollController: ${horizontalScrollController != null}');
    debugPrint('   → displayedList.length: ${displayedList.length}');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columns.length: ${columns.length}');
    debugPrint('   → dataList.length: ${dataList.length}');
    debugPrint('   → columnWidths: ${columnWidths != null}');

    final needsHorizontalScroll = horizontalScrollController != null ||
                                  reportType == ReportType.ventas ||
                                  reportType == ReportType.fventas ||
                                  reportType == ReportType.clientes;

    debugPrint('   → [ReportTableBuilder:1522] needsHorizontalScroll: $needsHorizontalScroll');

    // items 및 ingresos 보고서는 항상 전체 폭을 차지하도록 처리
    if (reportType == ReportType.items || reportType == ReportType.ingresos) {
      debugPrint('   → [ReportTableBuilder:1527] Items/Ingresos 보고서: 전체 폭 차지 모드');
      debugPrint('   → [ReportTableBuilder:1528] _buildTableWithoutHorizontalScroll 호출 시작');
      final tableWidget = buildTableWithoutHorizontalScroll(
        constraints: constraints,
        reportType: reportType,
        displayedList: displayedList,
        keys: keys,
        columns: columns,
        dataList: dataList,
        color: color,
        onRowDoubleTap: onRowDoubleTap,
        onRowTap: onRowTap,
        unit: unit,
        columnWidths: columnWidths,
        sortColumn: sortColumn,
        sortAscending: sortAscending,
      );

      debugPrint('   → [ReportTableBuilder:1608] _buildTableWithoutHorizontalScroll 호출 완료, Builder로 감싸기');
      return Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              debugPrint('═══════════════════════════════════════════════════════');
              debugPrint('📊 [ReportTableBuilder:1610] _buildTableContent 실제 렌더링 크기 (PostFrameCallback)');
              debugPrint('   → 파일: report_table_builder.dart');
              debugPrint('   → 라인: 1610');
              debugPrint('   → width: ${renderBox.size.width}');
              debugPrint('   → height: ${renderBox.size.height}');
              debugPrint('   → 예상 width: ${constraints.maxWidth}');
              debugPrint('   → 차이: ${renderBox.size.width - constraints.maxWidth}');
            } else {
              debugPrint('   ⚠️ [ReportTableBuilder:1610] RenderBox를 찾을 수 없습니다!');
            }
          });
          debugPrint('   → [ReportTableBuilder:1618] tableWidget 반환');
          return tableWidget;
        },
      );
    }

    if (needsHorizontalScroll) {
      return buildTableWithHorizontalScroll(
        constraints: constraints,
        horizontalScrollController: horizontalScrollController,
        reportType: reportType,
        displayedList: displayedList,
        keys: keys,
        columns: columns,
        dataList: dataList,
        color: color,
        onRowDoubleTap: onRowDoubleTap,
        onRowTap: onRowTap,
        unit: unit,
        columnWidths: columnWidths,
        sortColumn: sortColumn,
        sortAscending: sortAscending,
      );
    } else {
      return buildTableWithoutHorizontalScroll(
        constraints: constraints,
        reportType: reportType,
        displayedList: displayedList,
        keys: keys,
        columns: columns,
        dataList: dataList,
        color: color,
        onRowDoubleTap: onRowDoubleTap,
        onRowTap: onRowTap,
        unit: unit,
        columnWidths: columnWidths,
        sortColumn: sortColumn,
        sortAscending: sortAscending,
      );
    }
  }

  /// 수평 스크롤이 있는 테이블 빌드
  static Widget buildTableWithHorizontalScroll({
    required BoxConstraints constraints,
    ScrollController? horizontalScrollController,
    required ReportType reportType,
    required List<dynamic> displayedList,
    required List<String> keys,
    required List<DataColumn> columns,
    required List<dynamic> dataList,
    required Color color,
    Function(Map<String, dynamic>)? onRowDoubleTap,
    Function(Map<String, dynamic>)? onRowTap,
    String? unit,
    Map<String, double>? columnWidths,
    String? sortColumn,
    bool sortAscending = true,
  }) {
    // 테이블의 실제 너비 계산 (ReportTableColumnManager로 추출됨)
    final tableWidth = ReportTableColumnManager.calculateTableWidth(keys, columnWidths, constraints.maxWidth, unit: unit);

    // 디버깅: 괄호/구문 오류 확인을 위한 로깅
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [구문 검사] _buildTableWithHorizontalScroll 함수 본문 시작');
    debugPrint('   → 파일: report_table_builder.dart');
    debugPrint('   → 라인: ${1601}');
    debugPrint('   → calculateTableWidth() 호출 완료: $tableWidth');

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [_buildTableWithHorizontalScroll] 테이블 생성');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → horizontalScrollController: ${horizontalScrollController != null}');
    debugPrint('   → tableWidth: $tableWidth');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columnWidths: ${columnWidths != null}');
    if (horizontalScrollController != null) {
      debugPrint('   → horizontalScrollController.hasClients: ${horizontalScrollController.hasClients}');
      if (horizontalScrollController.hasClients) {
        try {
          debugPrint('   → horizontalScrollController.position.pixels: ${horizontalScrollController.position.pixels}');
          debugPrint('   → horizontalScrollController.position.maxScrollExtent: ${horizontalScrollController.position.maxScrollExtent}');
        } catch (e) {
          debugPrint('   ⚠️ horizontalScrollController.position 접근 오류: $e');
        }
      }
    }
    debugPrint('═══════════════════════════════════════════════════════');

    // 테이블의 수평 스크롤을 감지하여 헤더와 동기화
    // ScrollController가 여러 스크롤 뷰에 연결되는 것을 방지하기 위해
    // 테이블의 스크롤 이벤트를 NotificationListener로 감지하고 헤더를 동기화
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // 테이블의 수평 스크롤 이벤트를 헤더에 전달
        if (notification is ScrollUpdateNotification && notification.metrics.axis == Axis.horizontal) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [Ventas 테이블] 수평 스크롤 이벤트 감지');
          debugPrint('   → reportType: $reportType');
          debugPrint('   → unit: $unit');
          debugPrint('   → 테이블 스크롤 위치: ${notification.metrics.pixels}');
          debugPrint('   → horizontalScrollController: ${horizontalScrollController != null}');

          if (horizontalScrollController != null) {
            // ScrollController가 여러 스크롤 뷰에 연결되어 있는지 확인
            if (horizontalScrollController.hasClients) {
              try {
                final tableScrollPosition = notification.metrics.pixels;
                // 여러 position이 있는 경우 첫 번째 것만 사용
                if (horizontalScrollController.positions.length == 1) {
                  final headerScrollPosition = horizontalScrollController.position.pixels;
                  final difference = (tableScrollPosition - headerScrollPosition).abs();

                  debugPrint('   → 헤더 스크롤 위치: $headerScrollPosition');
                  debugPrint('   → 위치 차이: $difference');

                  if (difference > 0.1) {
                    debugPrint('   ✅ 위치 차이 > 0.1, 헤더 동기화: jumpTo($tableScrollPosition)');
                    horizontalScrollController.jumpTo(tableScrollPosition);
                  } else {
                    debugPrint('   ⚠️ 위치 차이 <= 0.1, 동기화 스킵');
                  }
                } else {
                  debugPrint('   ⚠️ ScrollController가 ${horizontalScrollController.positions.length}개의 스크롤 뷰에 연결됨');
                  // 여러 position이 있는 경우, 첫 번째 position에 동기화
                  final firstPosition = horizontalScrollController.positions.first;
                  final headerScrollPosition = firstPosition.pixels;
                  final difference = (tableScrollPosition - headerScrollPosition).abs();

                  debugPrint('   → 첫 번째 position 스크롤 위치: $headerScrollPosition');
                  debugPrint('   → 위치 차이: $difference');

                  if (difference > 0.1) {
                    debugPrint('   ✅ 위치 차이 > 0.1, 첫 번째 position 동기화: jumpTo($tableScrollPosition)');
                    firstPosition.jumpTo(tableScrollPosition);
                  }
                }
              } catch (e) {
                debugPrint('   ⚠️ 스크롤 동기화 오류: $e');
              }
            } else {
              debugPrint('   ⚠️ horizontalScrollController가 아직 클라이언트에 연결되지 않음');
            }
          }
          debugPrint('═══════════════════════════════════════════════════════');
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: buildDataTable(
            reportType: reportType,
            displayedList: displayedList,
            keys: keys,
            columns: columns,
            dataList: dataList,
            color: color,
            onRowDoubleTap: onRowDoubleTap,
            onRowTap: onRowTap,
            unit: unit,
            columnWidths: columnWidths,
            sortColumn: sortColumn,
            sortAscending: sortAscending,
          ),
        ),
      ),
    );
  }

  /// 수평 스크롤이 없는 테이블 빌드
  static Widget buildTableWithoutHorizontalScroll({
    required BoxConstraints constraints,
    required ReportType reportType,
    required List<dynamic> displayedList,
    required List<String> keys,
    required List<DataColumn> columns,
    required List<dynamic> dataList,
    required Color color,
    Function(Map<String, dynamic>)? onRowDoubleTap,
    Function(Map<String, dynamic>)? onRowTap,
    String? unit,
    Map<String, double>? columnWidths,
    String? sortColumn,
    bool sortAscending = true,
  }) {
    // 디버깅: 괄호/구문 오류 확인을 위한 로깅
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [구문 검사] _buildTableWithoutHorizontalScroll 함수 시작');
    debugPrint('   → 파일: report_table_builder.dart');
    debugPrint('   → 라인: ${1681}');
    debugPrint('   → 함수명: _buildTableWithoutHorizontalScroll');
    debugPrint('   → 파라미터 개수: 11');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
    debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
    debugPrint('   → displayedList.length: ${displayedList.length}');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columns.length: ${columns.length}');
    debugPrint('   → dataList.length: ${dataList.length}');
    debugPrint('   → columnWidths: ${columnWidths != null}');

    // 디버깅: constraints 정보 출력
    debugPrint('📊 [ReportTableBuilder:1706] _buildTableWithoutHorizontalScroll 시작');
    debugPrint('   → 파일: report_table_builder.dart');
    debugPrint('   → 라인: 1706');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
    debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
    debugPrint('   → constraints.minWidth: ${constraints.minWidth}');
    debugPrint('   → constraints.minHeight: ${constraints.minHeight}');

    // items 및 ingresos 보고서는 항상 전체 폭을 차지하도록 강제
    final hasValidWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0;
    final tableWidth = hasValidWidth ? constraints.maxWidth : null;

    debugPrint('   → [ReportTableBuilder:1716] 계산된 tableWidth: ${tableWidth ?? "Infinity (제약 없음)"}');
    debugPrint('   → [ReportTableBuilder:1722] ConstrainedBox 생성 시작');
    debugPrint('      → minWidth: ${tableWidth ?? "없음"}');
    debugPrint('      → maxWidth: ${tableWidth ?? "없음"}');

    final tableWidget = Builder(
      builder: (context) {
        // 디버깅: Builder 내부 시작
        debugPrint('   → [ReportTableBuilder:1725] Builder 내부 시작');

        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: tableWidth ?? 0,
            maxWidth: tableWidth ?? double.infinity,
          ),
          child: buildDataTable(
          reportType: reportType,
          displayedList: displayedList,
          keys: keys,
          columns: columns,
          dataList: dataList,
          color: color,
          onRowDoubleTap: onRowDoubleTap,
          onRowTap: onRowTap,
          unit: unit,
          columnWidths: columnWidths,
          sortColumn: sortColumn,
          sortAscending: sortAscending,
          ),
        );
      },
    );

    debugPrint('   → [ReportTableBuilder:1608] _buildTableWithoutHorizontalScroll 호출 완료, Builder로 감싸기');
    return Builder(
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('📊 [ReportTableBuilder:1610] _buildTableContent 실제 렌더링 크기 (PostFrameCallback)');
            debugPrint('   → 파일: report_table_builder.dart');
            debugPrint('   → 라인: 1610');
            debugPrint('   → width: ${renderBox.size.width}');
            debugPrint('   → height: ${renderBox.size.height}');
            debugPrint('   → 예상 width: ${constraints.maxWidth}');
            debugPrint('   → 차이: ${renderBox.size.width - constraints.maxWidth}');
                                } else {
            debugPrint('   ⚠️ [ReportTableBuilder:1610] RenderBox를 찾을 수 없습니다!');
          }
        });
        debugPrint('   → [ReportTableBuilder:1618] tableWidget 반환');
        return tableWidget;
      },
    );
  }

  /// DataTable 위젯 빌드
  static Widget buildDataTable({
    required ReportType reportType,
    required List<dynamic> displayedList,
    required List<String> keys,
    required List<DataColumn> columns,
    required List<dynamic> dataList,
    required Color color,
    Function(Map<String, dynamic>)? onRowDoubleTap,
    Function(Map<String, dynamic>)? onRowTap,
    String? unit,
    Map<String, double>? columnWidths,
    String? sortColumn,
    bool sortAscending = true,
    bool isLargeScreen = false, // 대형 화면 여부 (칼럼 간격 조정용)
    bool useMeasuredWidths = false, // _ItemsTableWithMeasuredColumns에서 측정된 너비인지 여부
    bool hideHeadingRow = false, // true면 items/ingresos에서 DataTable 헤더 숨김 (커스텀 헤더+리사이즈 사용 시)
  }) {
    // 디버깅: buildDataTable 파라미터 확인
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [report_table_builder.dart:2421] buildDataTable 함수 시작');
    debugPrint('   → 라인: 2421');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → unit: $unit');
    debugPrint('   → isLargeScreen: $isLargeScreen');
    debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
    debugPrint('   → columnWidths 전달됨: ${columnWidths != null}');
    if (columnWidths != null) {
      debugPrint('   → columnWidths 내용: $columnWidths');
      debugPrint('   → columnWidths 개수: ${columnWidths.length}');
      debugPrint('   → 각 키별 columnWidths 값:');
      columnWidths.forEach((key, value) {
        debugPrint('     → columnWidths["$key"] = $value');
      });
      debugPrint('   → ⚠️ [중요] 이 columnWidths가 _buildDataRowFromMap에 전달되어야 함');
    } else {
      debugPrint('   → ⚠️ [경고] columnWidths가 null! _buildDataRowFromMap에서 기본값 사용됨');
    }
    debugPrint('   → onRowDoubleTap: ${onRowDoubleTap != null}');
    debugPrint('   → onRowTap: ${onRowTap != null}');
    debugPrint('═══════════════════════════════════════════════════════');
    // 디버깅: 괄호/구문 오류 확인을 위한 로깅
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [구문 검사] buildDataTable 함수 시작');
    debugPrint('   → 파일: report_table_builder.dart');
    debugPrint('   → 라인: ${1788}');
    debugPrint('   → 함수명: buildDataTable');
    debugPrint('   → 파라미터 개수: 12');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → displayedList.length: ${displayedList.length}');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columns.length: ${columns.length}');
    debugPrint('   → dataList.length: ${dataList.length}');
    debugPrint('   → columnWidths: ${columnWidths != null}');
    debugPrint('   → unit: $unit');
    debugPrint('   → onRowDoubleTap: ${onRowDoubleTap != null}');
    debugPrint('   → onRowTap: ${onRowTap != null}');
    debugPrint('   → sortColumn: $sortColumn');
    debugPrint('   → sortAscending: $sortAscending');

    // 디버깅: 괄호 균형 확인
    checkBracketBalance('buildDataTable', 1788);

    // 정렬 적용: displayedList를 정렬
    List<dynamic> sortedDisplayedList = List.from(displayedList);
    if (sortColumn != null && keys.contains(sortColumn)) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔍 [buildDataTable] 정렬 적용');
      debugPrint('   → sortColumn: $sortColumn');
      debugPrint('   → sortAscending: $sortAscending');
      debugPrint('   → 정렬 전 displayedList.length: ${displayedList.length}');

      sortedDisplayedList.sort((a, b) {
        if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) {
          return 0;
        }

        dynamic aValue = a[sortColumn];
        dynamic bValue = b[sortColumn];

        // null 처리
        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return sortAscending ? -1 : 1;
        if (bValue == null) return sortAscending ? 1 : -1;

        // 숫자 필드 감지: totalCantidad, tcant, timporte, tIngreso, tingreso, cntEvent, cntevent 등
        final isNumericField = sortColumn.toLowerCase().contains('cantidad') ||
                              sortColumn.toLowerCase().contains('cant') ||
                              sortColumn.toLowerCase().contains('importe') ||
                              sortColumn.toLowerCase().contains('ingreso') ||
                              sortColumn.toLowerCase().contains('event') ||
                              sortColumn.toLowerCase().contains('prendas') ||
                              sortColumn.toLowerCase().contains('total') ||
                              sortColumn.toLowerCase().startsWith('t') &&
                                (sortColumn.toLowerCase().contains('cant') ||
                                 sortColumn.toLowerCase().contains('importe') ||
                                 sortColumn.toLowerCase().contains('ingreso'));

        // 숫자 처리 (숫자 타입이거나 숫자 필드인 경우)
        if (aValue is num && bValue is num) {
          final comparison = aValue.compareTo(bValue);
          return sortAscending ? comparison : -comparison;
        } else if (isNumericField) {
          // 숫자 필드인 경우 문자열을 숫자로 파싱
          final aNum = num.tryParse(aValue.toString().replaceAll(',', '').replaceAll('\$', '').trim()) ?? 0;
          final bNum = num.tryParse(bValue.toString().replaceAll(',', '').replaceAll('\$', '').trim()) ?? 0;
          final comparison = aNum.compareTo(bNum);
          debugPrint('   → [숫자 정렬] $sortColumn: $aNum vs $bNum, comparison: $comparison');
          return sortAscending ? comparison : -comparison;
        }

        // 문자열 처리
        final aStr = aValue.toString().toLowerCase();
        final bStr = bValue.toString().toLowerCase();
        final comparison = aStr.compareTo(bStr);
        return sortAscending ? comparison : -comparison;
      });

      debugPrint('   → 정렬 후 sortedDisplayedList.length: ${sortedDisplayedList.length}');
      debugPrint('═══════════════════════════════════════════════════════');
    } else {
      debugPrint('   → 정렬 없음: sortColumn이 null이거나 keys에 없음');
    }

    // alertas 보고서는 Table 위젯 사용
    if (reportType == ReportType.alertas) {
      debugPrint('   → [Alertas] Table 위젯 사용');
      // Table 위젯을 사용하는 코드는 buildTableFromList에 있으므로,
      // 여기서는 DataTable을 사용합니다.
    }

    // ============================================================
    // 🔍 Items 보고서 헤더 중복 및 정렬 기능 디버깅
    // ============================================================
    final isItems = reportType == ReportType.items;
    final isIngresos = reportType == ReportType.ingresos;
    final isItemsOrIngresos = isItems || isIngresos;

    // items/ingresos: hideHeadingRow이면 커스텀 헤더 사용(0), 아니면 DataTable 기본 헤더(37)
    // ventas: 별도 헤더 사용하므로 DataTable 헤더 숨김(0)
    final isVentas = reportType == ReportType.ventas;
    final headingRowHeight = isVentas ? 0.0 : (isItemsOrIngresos && hideHeadingRow ? 0.0 : (isItemsOrIngresos ? 37.0 : 56.0));

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [Items/Ingresos/Ventas DataTable] buildDataTable 호출 - 헤더 중복 및 정렬 디버깅');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → isItems: $isItems');
    debugPrint('   → isIngresos: $isIngresos');
    debugPrint('   → isItemsOrIngresos: $isItemsOrIngresos');
    debugPrint('   → isVentas: $isVentas');
    debugPrint('   → unit: $unit');
    debugPrint('   → headingRowHeight: $headingRowHeight');
    if (isVentas) {
      debugPrint('   → [Ventas $unit] headingRowHeight=0 (buildTableFromList에서 별도 헤더 사용)');
    } else if (isItemsOrIngresos) {
      debugPrint('   → [Items/Ingresos] headingRowHeight=0 (별도 헤더 사용)');
    } else {
      debugPrint('   → [기타 보고서] headingRowHeight=56 (기본 헤더 사용)');
    }
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columns.length: ${columns.length}');
    debugPrint('   → displayedList.length: ${displayedList.length}');

    // 각 칼럼의 정렬 기능 확인
    debugPrint('   → [정렬 기능 확인] 각 칼럼의 onSort 상태:');
    for (int i = 0; i < columns.length; i++) {
      final column = columns[i];
      final key = i < keys.length ? keys[i] : 'unknown';
      final hasOnSort = column.onSort != null;
      debugPrint('      칼럼 #$i ($key): onSort=${hasOnSort ? "있음" : "없음"}');
      if (hasOnSort) {
        debugPrint('         → 정렬 가능: ✅');
      } else {
        debugPrint('         → 정렬 불가: ❌');
      }
    }

    if (isItemsOrIngresos) {
      debugPrint('   ⚠️ [Items/Ingresos] headingRowHeight가 0이므로 DataTable 기본 헤더가 숨겨짐');
      debugPrint('   ⚠️ [Items/Ingresos] 별도 헤더 행(buildHeaderRow)이 생성되어야 함');
      debugPrint('   ⚠️ [문제 확인] 헤더가 중복되면: buildHeaderRow와 DataTable 헤더가 동시에 표시됨');
      debugPrint('   ⚠️ [문제 확인] 정렬이 안 되면: column.onSort가 null이거나 제대로 전달되지 않음');
    }

    debugPrint('═══════════════════════════════════════════════════════');

    // ventas day/month/year 유닛의 경우 대형 화면에서 칼럼 간격을 줄여서 더 많은 공간 확보
    final isVentasDayMonthYear = reportType == ReportType.ventas &&
                                 unit != null &&
                                 unit != 'vcode';
    // 헤더의 headerColumnSpacing과 일치시켜야 함
    // alertas: 1px, ventas day/month/year + 대형 화면: 2px, ventas day/month/year + 일반 화면: 4px, 그 외: 8px
    final columnSpacing = reportType == ReportType.alertas
        ? 1.0
        : (isVentasDayMonthYear ? (isLargeScreen ? 2.0 : 4.0) : 8.0);

    // 수직 라인 숨기기: Theme으로 dividerColor를 transparent로 설정
    return Builder(
      builder: (context) {
        return Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent, // 수직 및 수평 라인 숨기기
          ),
          child: DataTable(
            horizontalMargin: 0,
            columnSpacing: columnSpacing,
            dataRowMinHeight: reportType == ReportType.alertas ? 72 : 48,
            dataRowMaxHeight: reportType == ReportType.alertas ? 84 : 56,
            headingRowHeight: headingRowHeight,
            headingRowColor: WidgetStateProperty.all(
              isItemsOrIngresos ? color.withOpacity(0.1) : Colors.transparent,
            ),
            dividerThickness: 0.0, // 수평 라인 두께 0으로 설정
            sortColumnIndex: sortColumn != null && keys.contains(sortColumn)
                ? keys.indexOf(sortColumn)
                : null,
            sortAscending: sortAscending,
            columns: columns,
            rows: sortedDisplayedList.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        // 디버깅: DataRow 생성 시작
        debugPrint('   → [buildDataTable] DataRow 생성 - item 타입: ${item.runtimeType}');

        // onRowDoubleTap 또는 onRowTap이 있으면 _buildDataRowFromMap 사용 (제스처 지원)
        if ((onRowDoubleTap != null || onRowTap != null) && item is Map<String, dynamic>) {
          debugPrint('   → [buildDataTable:2613] 제스처 지원 - _buildDataRowFromMap 호출');
          debugPrint('      → 라인: 2613');
          debugPrint('      → columnWidths 전달: ${columnWidths != null}');
          if (columnWidths != null) {
            debugPrint('      → columnWidths 내용: $columnWidths');
          }
          return ReportTableDataRows.buildDataRowFromMap(
            item: item,
            keys: keys,
            reportType: reportType,
            onRowDoubleTap: onRowDoubleTap,
            onRowTap: onRowTap,
            unit: unit,
            columnWidths: columnWidths, // null 대신 전달받은 columnWidths 사용 (헤더와 일치시키기 위함)
            useMeasuredWidths: useMeasuredWidths, // 측정된 너비 사용 여부 전달
            isLargeScreen: isLargeScreen,
            rowIndex: index, // 행 인덱스 전달 (5행마다 색상 변경용)
          );
        }

        if (item is Map<String, dynamic>) {
          // ventas 보고서의 day/month/year 유닛은 칼럼 너비를 명시적으로 제어해야 함
          final isVentasDayMonthYear = reportType == ReportType.ventas &&
                                       unit != null &&
                                       unit != 'vcode';

          var cells = keys.map((key) {
            final value = item[key];
            String formattedValue;

            // codigo 관련 칼럼은 문자로 처리
            final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1' || key == 'vcode';

            // year 필드 포맷팅
            final keyLower = key.toLowerCase();
            if (keyLower == 'year' && value != null) {
              final yearStr = value.toString();
              if (yearStr.contains('-')) {
                formattedValue = yearStr.split('-')[0];
              } else {
                formattedValue = yearStr;
              }
            }
            // month 필드 포맷팅
            else if (keyLower == 'month' && value != null) {
              final monthStr = value.toString();
              if (monthStr.length >= 7 && monthStr.contains('-')) {
                formattedValue = monthStr.substring(0, 7);
              } else {
                formattedValue = monthStr;
              }
            } else {
              formattedValue = isCodigoColumn
                  ? (value?.toString() ?? 'N/A')
                  : ReportUtils.formatValue(value, fieldName: key, reportType: reportType);
            }

            // 숫자 컬럼 확인
            final isAmountColumn = keyLower.contains('costo') ||
                                   keyLower.contains('importe') ||
                                   keyLower.contains('ingreso') ||
                                   keyLower.contains('precio') ||
                                   keyLower.contains('pre') ||
                                   keyLower.contains('venta') ||
                                   keyLower.contains('cantidad') ||
                                   keyLower.contains('count') ||
                                   keyLower.contains('total') ||
                                   keyLower == 'sucursal' ||
                                   (keyLower.startsWith('t') &&
                                    (keyLower.contains('cant') ||
                                     keyLower.contains('event') ||
                                     keyLower.contains('prendas')));

            final isNumeric = (key != 'codigo' && key != 'codigo1' && key != 'tcode' && key != 'id_codigo1' && key != 'vcode')
                ? (ReportUtils.isNumeric(value) || isAmountColumn)
                : false;

            // alertas 보고서 또는 ventas day/month/year 유닛은 내용이 잘리지 않도록 설정
            final isAlertas = reportType == ReportType.alertas;
            if (isAlertas || isVentasDayMonthYear) {
              // columnWidths에서 칼럼 너비 가져오기 (대소문자 구분 없이)
              double? cellWidth;
              if (columnWidths != null) {
                // 디버깅: columnWidths에서 키 찾기 시도 (숨김)
                // debugPrint('   → [데이터 행] columnWidths에서 키 찾기: key=$key, keyLower=$keyLower');
                // debugPrint('   → columnWidths[$key]: ${columnWidths[key]}');
                // debugPrint('   → columnWidths[$keyLower]: ${columnWidths[keyLower]}');

                cellWidth = columnWidths[key] ??
                           columnWidths[keyLower] ??
                           (keyLower == 'eventcount' ? columnWidths['eventCount'] : null) ??
                           (keyLower == 'tvents' ? columnWidths['tVents'] : null) ??
                           (keyLower == 'tventas' ? columnWidths['tVentas'] : null) ??
                           (keyLower == 'tcntropas' ? columnWidths['tCntRopas'] : null);

                // debugPrint('   → 찾은 cellWidth: $cellWidth');
                // if (cellWidth == null) {
                //   debugPrint('   → ⚠️ [경고] columnWidths에서 키를 찾지 못함! 기본값 150.0 사용');
                // }
              } else {
                // debugPrint('   → ⚠️ [경고] columnWidths가 null! 기본값 150.0 사용');
              }
              // 측정된 칼럼 너비는 전체 칼럼 너비(SizedBox 너비 + padding)이므로,
              // useMeasuredWidths가 true인 경우: 측정값을 그대로 사용 (이미 전체 너비 포함)
              // 중요: 헤더의 headerSizedBoxWidth와 동일한 값이어야 함
              // 헤더: headerSizedBoxWidth = useMeasuredWidths ? baseColumnWidth : (isAlertas ? baseColumnWidth + 2.0 : (isVentas ? baseColumnWidth + 32.0 : baseColumnWidth))
              // 데이터 행: finalCellWidth를 헤더의 headerSizedBoxWidth와 동일하게 설정
              // ventas 보고서의 모든 유닛(vcode 포함)은 DataCell padding을 고려해야 함
              final baseCellWidth = cellWidth ?? 150.0;
              final isAlertasForCell = reportType == ReportType.alertas;
              final isVentasForCell = reportType == ReportType.ventas;
              final finalCellWidth = (useMeasuredWidths)
                  ? baseCellWidth  // 측정된 너비는 이미 전체 너비를 포함하므로 그대로 사용 - 헤더와 동일
                  : (isAlertasForCell
                      ? baseCellWidth + 2.0  // alertas는 padding 1px * 2
                      : (isVentasForCell)
                          ? baseCellWidth + 32.0  // ventas 보고서(vcode, day, month, year 모두)는 헤더와 동일하게 padding 추가
                          : baseCellWidth);

              debugPrint('   → [데이터 행] finalCellWidth 계산: useMeasuredWidths=$useMeasuredWidths, baseCellWidth=$baseCellWidth, finalCellWidth=$finalCellWidth (헤더와 일치해야 함)');

              debugPrint('═══════════════════════════════════════════════════════');
              debugPrint('🔍 [buildDataTable:2728] DataCell 칼럼 너비 설정');
              debugPrint('   → 라인: 2728');
              debugPrint('   → reportType: $reportType');
              debugPrint('   → unit: $unit');
              debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
              debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
              debugPrint('   → key: $key');
              debugPrint('   → keyLower: $keyLower');
              debugPrint('   → [데이터 행] 칼럼 #${keys.indexOf(key)} ($key):');
              debugPrint('     → cellWidth (columnWidths에서 찾은 값): $cellWidth');
              debugPrint('     → baseCellWidth: $baseCellWidth (cellWidth 또는 기본값 150.0)');
              debugPrint('     → finalCellWidth: $finalCellWidth (SizedBox 너비)');
              final actualDataColumnWidth = useMeasuredWidths ? finalCellWidth : finalCellWidth + 32.0;
              debugPrint('     → 실제 칼럼 너비 (useMeasuredWidths면 finalCellWidth, 아니면 finalCellWidth + 32px): $actualDataColumnWidth');
              debugPrint('   → columnWidths: ${columnWidths != null}');
              if (columnWidths != null) {
                debugPrint('   → columnWidths[$key]: ${columnWidths[key]}');
                debugPrint('   → columnWidths[$keyLower]: ${columnWidths[keyLower]}');
                debugPrint('   → ⚠️ [중요] columnWidths[$key]가 2배로 증가된 값인지 확인 필요');
                debugPrint('   → ⚠️ [중요] useMeasuredWidths=$useMeasuredWidths이므로 ${useMeasuredWidths ? "전체 너비 그대로 사용" : "padding 제외"}');
                debugPrint('   → ⚠️ [매칭 확인] 헤더의 headerSizedBoxWidth와 일치해야 함');
                debugPrint('   → ⚠️ [매칭 확인] 헤더의 headerSizedBoxWidth = 데이터 행의 실제 칼럼 너비 ($actualDataColumnWidth)');
              }
              debugPrint('═══════════════════════════════════════════════════════');
              print('🔍 [buildDataTable:2728] 데이터 행 칼럼 너비 설정');
              print('   → 라인: 2728');
              print('   → key: $key');
              print('   → baseCellWidth: $baseCellWidth');
              print('   → finalCellWidth: $finalCellWidth');
              print('   → 실제 칼럼 너비: $actualDataColumnWidth');
              print('   → useMeasuredWidths: $useMeasuredWidths');

              // ventas 보고서에서 cntropas 칼럼은 가운데 정렬
              final isCntropasColumn = reportType == ReportType.ventas &&
                                       (keyLower == 'cntropas' || keyLower == 'tcntropas' || keyLower == 'tcntropas');

              // 정렬 결정: cntropas는 가운데, 숫자는 오른쪽, 그 외는 왼쪽
              final alignment = isCntropasColumn
                  ? Alignment.center
                  : (isNumeric ? Alignment.centerRight : Alignment.centerLeft);

              final cellWidget = Align(
                alignment: alignment,
                child: Text(
                  formattedValue,
                  style: const TextStyle(
                    fontSize: 14, // ventas 보고서도 14px로 통일
                  ),
                  maxLines: null,
                  overflow: TextOverflow.visible,
                ),
              );

              // DataCell은 기본적으로 horizontal padding이 16px씩 양쪽에 있습니다.
              // 하지만 ConstrainedBox로 명시적으로 너비를 설정하면,
              // DataTable이 각 칼럼의 실제 너비를 계산할 때 ConstrainedBox 너비 + padding을 사용합니다.
              // 따라서 헤더의 SizedBox 너비는 ConstrainedBox 너비 + padding (32px)과 일치해야 합니다.
              // 데이터 행 칼럼 위치 계산 (디버깅용)
              int cellIndex = keys.indexOf(key);
              double dataCellColumnX = 0.0;
              // buildDataTable의 columnSpacing과 일치시켜야 함
              final dataColumnSpacing = reportType == ReportType.alertas
                  ? 1.0
                  : (isVentasDayMonthYear ? (isLargeScreen ? 2.0 : 4.0) : 8.0);

              for (int j = 0; j < cellIndex; j++) {
                final prevKey = keys[j];
                final prevKeyLower = prevKey.toLowerCase();
                double? prevCellWidth;
                if (columnWidths != null) {
                  prevCellWidth = columnWidths[prevKey] ??
                                 columnWidths[prevKeyLower] ??
                                 (prevKeyLower == 'eventcount' ? columnWidths['eventCount'] : null) ??
                                 (prevKeyLower == 'tvents' ? columnWidths['tVents'] : null) ??
                                 (prevKeyLower == 'tventas' ? columnWidths['tVentas'] : null) ??
                                 (prevKeyLower == 'tcntropas' ? columnWidths['tCntRopas'] : null);
                }
                final prevBaseCellWidth = prevCellWidth ?? 150.0;
                final prevFinalCellWidth = (useMeasuredWidths)
                    ? prevBaseCellWidth  // 측정된 너비는 이미 전체 너비를 포함하므로 그대로 사용
                    : (isVentasDayMonthYear && columnWidths != null && prevCellWidth != null)
                        ? (prevBaseCellWidth - 32.0).clamp(50.0, double.infinity)
                        : prevBaseCellWidth;
                // DataCell의 실제 칼럼 너비 = useMeasuredWidths가 true면 finalCellWidth (전체 너비), false면 finalCellWidth + padding (32px)
                // 헤더의 headerSizedBoxWidth와 일치해야 함
                final prevActualCellWidth = useMeasuredWidths ? prevFinalCellWidth : prevFinalCellWidth + 32.0;
                dataCellColumnX += prevActualCellWidth;
                if (j < cellIndex - 1) {
                  dataCellColumnX += dataColumnSpacing;
                }
              }

              // DataCell의 실제 칼럼 너비 = SizedBox 너비 + padding (32px)
              final actualCellWidth = finalCellWidth + 32.0;

              // 디버깅: 데이터 행 칼럼 위치 계산 (숨김)
              // if (cellIndex == 0 && isVentasDayMonthYear) {
              //   debugPrint('═══════════════════════════════════════════════════════');
              //   debugPrint('🔍 [데이터 행 칼럼 위치] 계산된 위치');
              //   debugPrint('   → 칼럼 #$cellIndex ($key)');
              //   debugPrint('   → 계산된 x 위치: $dataCellColumnX');
              //   debugPrint('   → SizedBox 너비: $finalCellWidth');
              //   debugPrint('   → 실제 칼럼 너비 (SizedBox + padding): $actualCellWidth');
              //   debugPrint('   → columnSpacing: $dataColumnSpacing');
              //   debugPrint('═══════════════════════════════════════════════════════');
              // }

              // 디버깅: 데이터 행 칼럼에 수직선 추가 및 위치 측정 (숨김)
              // debugPrint('🔍 [report_table_builder.dart:2830] 데이터 행 칼럼 수직선 추가 (alertas/ventas day/month/year)');
              // debugPrint('   → 라인: 2830');
              // debugPrint('   → key: $key');
              // debugPrint('   → finalCellWidth (픽셀값): $finalCellWidth');
              // debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
              // debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
              // print('🔍 [report_table_builder.dart:2830] 데이터 행 칼럼 수직선 추가 (alertas/ventas day/month/year)');
              // print('   → 라인: 2830');
              // print('   → key: $key');
              // print('   → finalCellWidth (픽셀값): $finalCellWidth');

              final dataCell = DataCell(
                Builder(
                  builder: (context) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      // 디버깅: 데이터 행 칼럼 위치 및 너비 측정 (숨김)
                      // final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                      // if (renderBox != null) {
                      //   debugPrint('═══════════════════════════════════════════════════════');
                      //   debugPrint('🔍 [report_table_builder.dart:2838] 데이터 행 칼럼 위치 및 너비 측정 (alertas/ventas day/month/year)');
                      //   debugPrint('   → 라인: 2838');
                      //   debugPrint('   → key: $key');
                      //   debugPrint('   → finalCellWidth (설정된 픽셀값): $finalCellWidth');
                      //   debugPrint('   → 실제 렌더링 위치: ${renderBox.localToGlobal(Offset.zero).dx}');
                      //   debugPrint('   → 실제 렌더링 너비: ${renderBox.size.width}');
                      //   debugPrint('   → 실제 칼럼 너비 (width + padding): ${renderBox.size.width}');
                      //   print('🔍 [report_table_builder.dart:2838] 데이터 행 칼럼 위치 및 너비 측정 (alertas/ventas day/month/year)');
                      //   print('   → 라인: 2838');
                      //   print('   → key: $key');
                      //   print('   → finalCellWidth (설정된 픽셀값): $finalCellWidth');
                      //   print('   → 실제 렌더링 위치: ${renderBox.localToGlobal(Offset.zero).dx}');
                      //   print('   → 실제 렌더링 너비: ${renderBox.size.width}');
                      //   debugPrint('═══════════════════════════════════════════════════════');
                      // }
                    });

                    return Container(
                      // decoration: BoxDecoration(
                      //   border: Border(
                      //     right: BorderSide(
                      //       color: Colors.blue.withOpacity(0.5),  // 디버깅용 파란색 수직선 (숨김)
                      //       width: 1.0,
                      //     ),
                      //   ),
                      // ),
                      child: SizedBox(
                        width: finalCellWidth,  // 정확한 픽셀값으로 설정
                        child: cellWidget,
                      ),
                    );
                  },
                ),
              );

              // 디버깅: 실제 렌더링 위치 측정 (첫 번째 칼럼만) (숨김)
              // if (cellIndex == 0 && isVentasDayMonthYear) {
              //   WidgetsBinding.instance.addPostFrameCallback((_) {
              //     debugPrint('═══════════════════════════════════════════════════════');
              //     debugPrint('🔍 [데이터 행 칼럼 위치] 첫 번째 칼럼 렌더링 완료');
              //     debugPrint('   → 칼럼 #$cellIndex ($key)');
              //     debugPrint('   → 계산된 x 위치: $dataCellColumnX');
              //     debugPrint('   → SizedBox 너비: $finalCellWidth');
              //     debugPrint('   → 실제 칼럼 너비 (계산): $actualCellWidth');
              //     debugPrint('   → columnSpacing: $dataColumnSpacing');
              //     debugPrint('═══════════════════════════════════════════════════════');
              //   });
              // }

              return dataCell;
            } else {
              // 다른 보고서는 기본 DataCell 사용
              // 단, ventas 보고서의 day/month/year 유닛은 칼럼 너비를 명시적으로 제어
              if (isVentasDayMonthYear) {
                // columnWidths에서 칼럼 너비 가져오기 (대소문자 구분 없이)
                double? cellWidth;
                if (columnWidths != null) {
                  cellWidth = columnWidths[key] ??
                             columnWidths[keyLower] ??
                             (keyLower == 'eventcount' ? columnWidths['eventCount'] : null) ??
                             (keyLower == 'tvents' ? columnWidths['tVents'] : null) ??
                             (keyLower == 'tventas' ? columnWidths['tVentas'] : null) ??
                             (keyLower == 'tcntropas' ? columnWidths['tCntRopas'] : null);
                }
                // 헤더와 데이터 행의 칼럼 너비를 일치시키기 위해:
                // useMeasuredWidths가 false인 경우 (ventas day/month/year):
                // - 헤더: headerSizedBoxWidth = baseColumnWidth + 32.0 (고정 픽셀 값 + padding)
                // - 데이터 행: SizedBox 너비 = baseCellWidth (고정 픽셀 값), DataCell이 자동으로 padding 32px 추가
                // - 따라서 실제 칼럼 너비는 동일: baseCellWidth + 32 = baseColumnWidth + 32
                // useMeasuredWidths가 true인 경우 (items/ingresos productos):
                // - 헤더: headerSizedBoxWidth = baseColumnWidth (측정값 전체)
                // - 데이터 행: DataCell padding 32 있으므로 SizedBox 너비 = baseCellWidth - 32 로 해야 열 너비 일치
                final baseCellWidth = cellWidth ?? 75.0;  // 기본값도 절반으로 줄임 (150 -> 75)
                final isItemsOrIngresosInline = reportType == ReportType.items || reportType == ReportType.ingresos;
                final finalCellWidth = useMeasuredWidths
                    ? (isItemsOrIngresosInline
                        ? (baseCellWidth - 32.0).clamp(20.0, double.infinity)  // items/ingresos: DataCell padding 보정
                        : baseCellWidth)  // 측정된 너비는 이미 전체 너비를 포함하므로 그대로 사용
                    : baseCellWidth;  // 고정 픽셀 값을 그대로 사용 (DataCell이 padding 추가)

                debugPrint('═══════════════════════════════════════════════════════');
                debugPrint('🔍 [buildDataTable:2858] DataCell 칼럼 너비 설정 (else 블록)');
                debugPrint('   → 라인: 2858');
                debugPrint('   → reportType: $reportType');
                debugPrint('   → unit: $unit');
                debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
                debugPrint('   → key: $key');
                debugPrint('   → keyLower: $keyLower');
                debugPrint('   → baseCellWidth: $baseCellWidth');
                debugPrint('   → finalCellWidth: $finalCellWidth (SizedBox 너비)');
                final actualDataColumnWidthElse = useMeasuredWidths
                    ? finalCellWidth  // 측정값은 전체 너비
                    : finalCellWidth + 32.0;  // 고정 픽셀 값 + DataCell padding
                debugPrint('   → 실제 칼럼 너비: $actualDataColumnWidthElse (SizedBox + padding)');
                debugPrint('   → ⚠️ [매칭 확인] 헤더의 headerSizedBoxWidth ($baseCellWidth + 32 = ${baseCellWidth + 32.0})와 일치해야 함');
                debugPrint('═══════════════════════════════════════════════════════');
                print('🔍 [buildDataTable:2858] 데이터 행 칼럼 너비 설정 (else 블록)');
                print('   → 라인: 2858');
                print('   → key: $key');
                print('   → baseCellWidth: $baseCellWidth');
                print('   → finalCellWidth: $finalCellWidth');
                print('   → 실제 칼럼 너비: $actualDataColumnWidthElse');
                print('   → useMeasuredWidths: $useMeasuredWidths');

                // DataCell은 기본적으로 horizontal padding이 16px씩 양쪽에 있습니다.
                // 하지만 SizedBox로 명시적으로 너비를 설정하면,
                // DataTable이 각 칼럼의 실제 너비를 계산할 때 SizedBox 너비 + padding을 사용합니다.
                // 따라서 헤더의 SizedBox 너비는 SizedBox 너비 + padding (32px)과 일치해야 합니다.

                // 디버깅: 데이터 행 칼럼에 수직선 추가 및 위치 측정 (숨김)
                // debugPrint('🔍 [report_table_builder.dart:2907] 데이터 행 칼럼 수직선 추가 (buildDataTable else 블록)');
                // debugPrint('   → 라인: 2907');
                // debugPrint('   → key: $key');
                // debugPrint('   → finalCellWidth (픽셀값): $finalCellWidth');
                // debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
                // debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
                // print('🔍 [report_table_builder.dart:2907] 데이터 행 칼럼 수직선 추가 (buildDataTable else 블록)');
                // print('   → 라인: 2907');
                // print('   → key: $key');
                // print('   → finalCellWidth (픽셀값): $finalCellWidth');

                return DataCell(
                  Builder(
                    builder: (context) {
                      // 디버깅: 데이터 행 칼럼 위치 및 너비 측정 (숨김)
                      // WidgetsBinding.instance.addPostFrameCallback((_) {
                      //   final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                      //   if (renderBox != null) {
                      //     debugPrint('═══════════════════════════════════════════════════════');
                      //     debugPrint('🔍 [report_table_builder.dart:2915] 데이터 행 칼럼 위치 및 너비 측정 (buildDataTable else 블록)');
                      //     debugPrint('   → 라인: 2915');
                      //     debugPrint('   → key: $key');
                      //     debugPrint('   → finalCellWidth (설정된 픽셀값): $finalCellWidth');
                      //     debugPrint('   → 실제 렌더링 위치: ${renderBox.localToGlobal(Offset.zero).dx}');
                      //     debugPrint('   → 실제 렌더링 너비: ${renderBox.size.width}');
                      //     debugPrint('   → 실제 칼럼 너비 (width + padding): ${renderBox.size.width}');
                      //     print('🔍 [report_table_builder.dart:2915] 데이터 행 칼럼 위치 및 너비 측정 (buildDataTable else 블록)');
                      //     print('   → 라인: 2915');
                      //     print('   → key: $key');
                      //     print('   → finalCellWidth (설정된 픽셀값): $finalCellWidth');
                      //     print('   → 실제 렌더링 위치: ${renderBox.localToGlobal(Offset.zero).dx}');
                      //     print('   → 실제 렌더링 너비: ${renderBox.size.width}');
                      //     debugPrint('═══════════════════════════════════════════════════════');
                      //   }
                      // });

                      // 수직선을 별도로 추가하여 칼럼 너비에 영향 없도록 함
                      return Stack(
                        children: [
                          SizedBox(
                            width: finalCellWidth,  // 정확한 픽셀값으로 설정 (헤더의 baseColumnWidth와 일치)
                            child: Align(
                              alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                              child: Text(
                                formattedValue,
                                style: const TextStyle(
                                  fontSize: 14, // ventas 보고서도 14px로 통일
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // ventas/fventas 보고서가 아닐 때만 수직선 표시 (ventas·fventas는 수직선 숨김)
                          if (reportType != ReportType.ventas && reportType != ReportType.fventas)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 1.0,
                                color: Colors.blue.withOpacity(0.5),  // 디버깅용 파란색 수직선
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              } else {
                // ventas day/month/year 유닛이 아닌 경우에도 수직선 추가 (디버깅용, ventas 제외)
                debugPrint('🔍 [report_table_builder.dart:3015] 데이터 행 칼럼 수직선 추가 (else 블록 - ventas day/month/year 아님)');
                debugPrint('   → 라인: 3015');
                debugPrint('   → key: $key');
                debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
                print('🔍 [report_table_builder.dart:3015] 데이터 행 칼럼 수직선 추가 (else 블록 - ventas day/month/year 아님)');
                print('   → 라인: 3015');
                print('   → key: $key');

                return DataCell(
                  Builder(
                    builder: (context) {
                      // ventas/fventas 보고서가 아닐 때만 수직선 표시 (ventas·fventas는 수직선 숨김)
                      // items/ingresos에서 useMeasuredWidths일 때 DataCell padding 32 보정으로 열 너비 헤더와 일치
                      final isItemsOrIngresosElse = reportType == ReportType.items || reportType == ReportType.ingresos;
                      final mapForWidth = columnWidths;
                      final cellWidthElse = mapForWidth == null
                          ? null
                          : (mapForWidth[key] ??
                              mapForWidth[keyLower] ??
                              (keyLower == 'eventcount' ? mapForWidth['eventCount'] : null) ??
                              (keyLower == 'tvents' ? mapForWidth['tVents'] : null) ??
                              (keyLower == 'tventas' ? mapForWidth['tVentas'] : null) ??
                              (keyLower == 'tcntropas' ? mapForWidth['tCntRopas'] : null));
                      // items/ingresos는 측정/기본 여부와 관계없이 columnWidths가 있으면 DataCell padding(32) 보정 적용해 헤더와 열 맞춤
                      final contentWidthElse = (isItemsOrIngresosElse && cellWidthElse != null)
                          ? (cellWidthElse - 32.0).clamp(20.0, double.infinity)
                          : null;
                      if (isItemsOrIngresosElse && index == 0 && contentWidthElse == null && mapForWidth != null) {
                        debugPrint('📐 [정렬디버그:데이터] ($key) contentWidthElse=null (useMeasuredWidths=$useMeasuredWidths cellWidthElse=$cellWidthElse) → 셀 너비 미제한, 정렬 틀어질 수 있음');
                      }
                      // items/ingresos 칼럼 정렬 디버깅: 데이터 셀 실제 렌더 위치·너비 (첫 행 최대 5칼럼, 테이블당 1회)
                      if (index == 0 && isItemsOrIngresosElse && contentWidthElse != null) {
                        final k = key;
                        final expectedContentW = contentWidthElse;
                        final expectedTotalW = contentWidthElse + 32.0;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (ReportTableBuilder.alignmentDataLoggedCount >= 5) return;
                          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                          if (renderBox != null && context.mounted) {
                            final actualX = renderBox.localToGlobal(Offset.zero).dx;
                            final actualW = renderBox.size.width;
                            // DataCell 자식=SizedBox: actualX가 콘텐츠 영역 왼쪽, actualW가 콘텐츠 너비. 셀 왼쪽=actualX-16, 셀 너비=actualW+32
                            ReportTableBuilder.alignmentDataDebugList.add({
                              'key': k,
                              'contentLeft': actualX,
                              'contentWidth': actualW,
                              'cellLeft': actualX - 16.0,
                              'cellWidth': actualW + 32.0,
                            });
                            debugPrint('📐 [정렬디버그:데이터] report_table_builder.dart ($k) expectedContentW=${expectedContentW.toStringAsFixed(1)} expectedTotalW=${expectedTotalW.toStringAsFixed(1)} actualX=${actualX.toStringAsFixed(1)} actualW=${actualW.toStringAsFixed(1)} (DataCell자식=SizedBox 기준)');
                            print('📐 [정렬디버그:데이터] $k expectedContentW=$expectedContentW expectedTotalW=$expectedTotalW actualX=$actualX actualW=$actualW');
                            ReportTableBuilder.alignmentDataLoggedCount++;
                            // 5칼럼 모두 수집 시 헤더 vs 데이터 칼럼 위치·크기 비교 출력 (report_table_builder.dart)
                            if (ReportTableBuilder.alignmentDataDebugList.length >= 5 &&
                                ReportTableBuilder.alignmentHeaderDebugList.length >= 5) {
                              ReportTableBuilder.printAlignmentComparison();
                            }
                          }
                        });
                      }
                      final content = Container(
                        decoration: (reportType == ReportType.ventas || reportType == ReportType.fventas)
                            ? null
                            : BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.green.withOpacity(0.5),  // 디버깅용 초록색 수직선 (ventas day/month/year 아님)
                                    width: 1.0,
                                  ),
                                ),
                              ),
                        child: Align(
                          alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                          child: Text(
                            formattedValue,
                            style: const TextStyle(
                              fontSize: 14, // ventas 보고서도 14px로 통일
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                      return contentWidthElse != null
                          ? SizedBox(width: contentWidthElse, child: content)
                          : content;
                    },
                  ),
                );
              }
            }
          }).toList();

          // 셀 개수 확인
          assert(cells.length == keys.length,
            'Row cells count (${cells.length}) must match keys count (${keys.length})');

          // 매 5번째 행마다 색상 변경 (ventas, items, ingresos, fventas, gastos, clientes 보고서)
          final shouldApplyRowColor = reportType == ReportType.ventas ||
                                      reportType == ReportType.items ||
                                      reportType == ReportType.ingresos ||
                                      reportType == ReportType.fventas ||
                                      reportType == ReportType.gastos ||
                                      reportType == ReportType.clientes;

          WidgetStateProperty<Color?>? rowColor;
          if (shouldApplyRowColor && index % 5 == 4) {
            // 매 5번째 행 (0-based index이므로 4, 9, 14, ...)에 약간 다른 색상 적용
            rowColor = WidgetStateProperty.all(Colors.grey.withOpacity(0.05));
          }

          return DataRow(
            cells: cells,
            color: rowColor,
          );
        } else {
          // Map이 아닌 경우
          final formattedValue = ReportUtils.formatValue(item);
          final isNumeric = ReportUtils.isNumeric(item);
          final cells = List.generate(keys.length, (index) {
            return DataCell(
              Align(
                alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  index == 0 ? formattedValue : '',
                  style: const TextStyle(
                    fontSize: 14, // ventas 보고서도 14px로 통일
                  ),
                ),
              ),
            );
          });

          // 매 5번째 행마다 색상 변경 (ventas, items, ingresos, fventas, gastos, clientes 보고서)
          final shouldApplyRowColor = reportType == ReportType.ventas ||
                                      reportType == ReportType.items ||
                                      reportType == ReportType.ingresos ||
                                      reportType == ReportType.fventas ||
                                      reportType == ReportType.gastos ||
                                      reportType == ReportType.clientes;

          WidgetStateProperty<Color?>? rowColor;
          if (shouldApplyRowColor && index % 5 == 4) {
            // 매 5번째 행 (0-based index이므로 4, 9, 14, ...)에 약간 다른 색상 적용
            rowColor = WidgetStateProperty.all(Colors.grey.withOpacity(0.05));
          }

          return DataRow(
            cells: cells,
            color: rowColor,
          );
        }
      }).toList(),
          ),
        );
      },
    );

    // 디버깅: 괄호/구문 오류 확인을 위한 로깅
    debugPrint('🔍 [구문 검사] buildDataTable 함수 종료');
    debugPrint('   → 파일: report_table_builder.dart');
    debugPrint('   → 라인: ${1927}');
    debugPrint('   → 함수명: buildDataTable');
    debugPrint('   → 반환 타입: Widget');
    debugPrint('   → 괄호 닫힘 확인: OK');
  }
}
