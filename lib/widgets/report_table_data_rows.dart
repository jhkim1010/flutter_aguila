// Data row, data cell and gesture helpers extracted from ReportTableBuilder.
import 'package:flutter/material.dart';
import 'report_utils.dart';
import 'report_table_column_widths.dart';
import 'report_table_header_footer.dart';
import 'report_table_builder.dart';

class ReportTableDataRows {
  /// DataTable의 rows 생성
  static List<DataRow> buildDataTableRows({
    required List<dynamic> displayedList,
    required List<String> keys,
    required ReportType reportType,
    Function(Map<String, dynamic>)? onRowDoubleTap,
    Function(Map<String, dynamic>)? onRowTap,
    String? unit,
    required List<dynamic> dataList,
    required Color color,
    bool includeTotalRow = true, // footer 포함 여부
    Map<String, double>? columnWidths,
    bool useMeasuredWidths = false, // 측정된 너비 사용 여부
    bool isLargeScreen = false,
  }) {
    // 디버깅: 함수 진입 확인
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [구문 검사] _buildDataTableRows 함수 시작');
    debugPrint('   → 파일: report_table_builder.dart');
    debugPrint('   → 라인: ${1979}');
    debugPrint('   → 함수명: _buildDataTableRows');
    debugPrint('   → 파라미터 개수: 9');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → displayedList.length: ${displayedList.length}');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → dataList.length: ${dataList.length}');
    debugPrint('   → columnWidths 전달됨: ${columnWidths != null}');
    debugPrint('   → includeTotalRow: $includeTotalRow');
    debugPrint('   → onRowDoubleTap: ${onRowDoubleTap != null}');
    debugPrint('   → onRowTap: ${onRowTap != null}');
    debugPrint('   → unit: $unit');
    
    final rows = <DataRow>[];
    
    // 디버깅: 데이터 행 생성 시작
    final isItemsOrIngresos = reportType == ReportType.items || reportType == ReportType.ingresos;
    debugPrint('   → isItemsOrIngresos: $isItemsOrIngresos');
    
    if (isItemsOrIngresos && displayedList.isNotEmpty) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📊 [_buildDataTableRows] 데이터 행 생성 시작');
      debugPrint('   → keys: $keys');
      debugPrint('   → displayedList.length: ${displayedList.length}');
      debugPrint('   → columnWidths 전달: ${columnWidths != null}');
    }
    
    // 데이터 행 생성
    debugPrint('   → [데이터 행 생성] displayedList.map 시작');
    rows.addAll(displayedList.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      debugPrint('   → [데이터 행 생성] item 타입: ${item.runtimeType}');
      if (item is Map<String, dynamic>) {
        debugPrint('   → [데이터 행 생성] Map 타입 - _buildDataRowFromMap 호출');
        debugPrint('   → [report_table_builder.dart:3016] useMeasuredWidths 전달: $useMeasuredWidths');
        debugPrint('   → 라인: 3016');
        return buildDataRowFromMap(
          item: item,
          keys: keys,
          reportType: reportType,
          onRowDoubleTap: onRowDoubleTap,
          onRowTap: onRowTap,
          unit: unit,
          columnWidths: columnWidths,
          useMeasuredWidths: useMeasuredWidths, // 측정된 너비 사용 여부 전달
          isLargeScreen: isLargeScreen,
          rowIndex: index, // 행 인덱스 전달 (5행마다 색상 변경용)
        );
      } else {
        debugPrint('   → [데이터 행 생성] Map이 아닌 타입 - _buildDataRowFromNonMap 호출');
        return buildDataRowFromNonMap(
          item: item,
          keys: keys,
          reportType: reportType,
          columnWidths: columnWidths,
          rowIndex: index, // 행 인덱스 전달 (5행마다 색상 변경용)
        );
      }
    }));
    
    debugPrint('   → [데이터 행 생성] 완료 - rows.length: ${rows.length}');
    
    // 합계 행 추가 (includeTotalRow가 true인 경우만)
    if (includeTotalRow) {
      debugPrint('   → [합계 행 추가] includeTotalRow가 true - 합계 행 추가 시작');
      final totalDataList = (reportType == ReportType.items || reportType == ReportType.ingresos) 
          ? displayedList 
          : dataList;
      debugPrint('   → [합계 행 추가] totalDataList.length: ${totalDataList.length}');
      rows.add(ReportTableHeaderFooter.buildTotalRow(keys, totalDataList, color, reportType: reportType));
      debugPrint('   → [합계 행 추가] 완료 - rows.length: ${rows.length}');
    } else {
      debugPrint('   → [합계 행 추가] includeTotalRow가 false - 합계 행 추가 스킵');
    }
    
    debugPrint('🔍 [구문 검사] _buildDataTableRows 함수 종료');
    debugPrint('   → 반환 rows.length: ${rows.length}');
    debugPrint('═══════════════════════════════════════════════════════');
    
    return rows;
  }

  /// Map 형태의 데이터에서 DataRow 생성
  static DataRow buildDataRowFromMap({
    required Map<String, dynamic> item,
    required List<String> keys,
    required ReportType reportType,
    Function(Map<String, dynamic>)? onRowDoubleTap,
    Function(Map<String, dynamic>)? onRowTap,
    String? unit,
    Map<String, double>? columnWidths,
    bool useMeasuredWidths = false, // 측정된 너비 사용 여부
    bool isLargeScreen = false,
    int rowIndex = 0, // 행 인덱스 (5행마다 색상 변경용)
  }) {
    // ventas 보고서인지 확인 (vcode, day, month, year 모두 포함)
    // isVentas는 클로저 내부에서 직접 계산하므로 여기서는 선언하지 않음
    final isVentasDayMonthYear = reportType == ReportType.ventas && 
                                 unit != null && 
                                 (unit == 'day' || unit == 'month' || unit == 'year');
    // 디버깅: 함수 진입 확인 및 columnWidths 상세 확인
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [report_table_builder.dart:3032] _buildDataRowFromMap 함수 시작');
    debugPrint('   → 라인: 3032');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → unit: $unit');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → keys: $keys');
    debugPrint('   → columnWidths 전달됨: ${columnWidths != null}');
    if (columnWidths != null) {
      debugPrint('   → columnWidths 내용: $columnWidths');
      debugPrint('   → columnWidths 개수: ${columnWidths.length}');
      debugPrint('   → 각 키별 columnWidths 값:');
      for (final key in keys) {
        final width = columnWidths[key] ?? 
                     columnWidths[key.toLowerCase()] ??
                     (key.toLowerCase() == 'eventcount' ? columnWidths['eventCount'] : null) ??
                     (key.toLowerCase() == 'tvents' ? columnWidths['tVents'] : null) ??
                     (key.toLowerCase() == 'tventas' ? columnWidths['tVentas'] : null) ??
                     (key.toLowerCase() == 'tcntropas' ? columnWidths['tCntRopas'] : null);
        debugPrint('     → $key: $width');
      }
      debugPrint('   → ⚠️ [중요] 이 columnWidths가 헤더의 columnWidths와 동일한지 확인 필요');
    } else {
      debugPrint('   → ⚠️ [경고] columnWidths가 null! 기본값 사용됨');
    }
    debugPrint('═══════════════════════════════════════════════════════');
    
    // items/ingresos/alertas 보고서는 칼럼 너비를 설정하여 헤더와 일치시킴
    final isItemsOrIngresos = reportType == ReportType.items || reportType == ReportType.ingresos;
    final isAlertas = reportType == ReportType.alertas;
    
    debugPrint('      → isItemsOrIngresos: $isItemsOrIngresos');
    debugPrint('      → isAlertas: $isAlertas');
    final defaultColumnWidths = kReportDefaultColumnWidths;
    
    final finalColumnWidths = columnWidths ?? defaultColumnWidths;
    
    // 디버깅: 데이터 행 칼럼 너비 정보 출력 (1번만 출력)
    if ((isItemsOrIngresos || isAlertas) && ReportTableBuilder.debugRowCount == 0) {
      final actualPadding = isAlertas ? 1 : 16;
      final actualColumnSpacing = isAlertas ? 1 : 8;
      
        debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📊 [데이터 행] _buildDataRowFromMap 칼럼 너비 정보');
                  debugPrint('   → keys: $keys');
                  debugPrint('   → keys.length: ${keys.length}');
                  debugPrint('   → isItemsOrIngresos: $isItemsOrIngresos');
      debugPrint('   → isAlertas: $isAlertas');
                  debugPrint('   → columnWidths 전달됨: ${columnWidths != null}');
                  debugPrint('   → finalColumnWidths: $finalColumnWidths');
      debugPrint('   → 실제 DataCell padding: $actualPadding (alertas: $isAlertas)');
      debugPrint('   → 실제 columnSpacing: $actualColumnSpacing (alertas: $isAlertas)');
      double dataRowCumulativeX = 0.0;
                  for (int i = 0; i < keys.length; i++) {
        final key = keys[i];
        final columnWidth = finalColumnWidths[key] ?? 150.0;
        debugPrint('   → [데이터 행] 칼럼 #$i: key="$key", width=$columnWidth, x=$dataRowCumulativeX, DataCell padding=$actualPadding');
        dataRowCumulativeX += columnWidth;
                    if (i < keys.length - 1) {
          dataRowCumulativeX += actualColumnSpacing; // alertas는 1, 다른 보고서는 8
          debugPrint('      → columnSpacing($actualColumnSpacing) 추가 후 x=$dataRowCumulativeX');
        }
      }
      debugPrint('   → [데이터 행] 총 너비: $dataRowCumulativeX');
      ReportTableBuilder.debugRowCount++;
    }
    
    var cells = keys.map((key) {
      final cell = buildDataCell(
        key: key,
        value: item[key],
        reportType: reportType,
      );
      
      // items/ingresos/alertas 보고서 또는 useMeasuredWidths가 true이거나 ventas 보고서(vcode, day, month, year 모두)인 경우 각 셀의 너비를 설정하여 헤더와 일치시킴
      // 클로저 내부에서 직접 계산하여 변수 스코프 문제 방지
      final isVentasInClosure = reportType == ReportType.ventas;
      if (isItemsOrIngresos || isAlertas || useMeasuredWidths || isVentasInClosure) {
        debugPrint('🔍 [report_table_builder.dart:3170] 데이터 행 칼럼 너비 설정');
        debugPrint('   → 라인: 3170');
        debugPrint('   → key: $key');
        debugPrint('   → isItemsOrIngresos: $isItemsOrIngresos');
        debugPrint('   → isAlertas: $isAlertas');
        debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
        debugPrint('   → isVentasInClosure: $isVentasInClosure');
        debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
        debugPrint('   → reportType: $reportType');
        // 헤더와 정확히 일치시키기 위해 baseColumnWidth를 그대로 사용 (padding은 DataCell이 자동 추가)
        final columnWidth = resolveColumnWidth(key, finalColumnWidths, fallback: 75.0);

        // 헤더와 정확히 일치시키기 위해 공유 헬퍼로 계산
        final dataRowColumnWidth = dataCellWidth(
          columnWidth,
          isAlertas: isAlertas,
          isVentas: isVentasInClosure,
          isItemsOrIngresos: isItemsOrIngresos,
          useMeasuredWidths: useMeasuredWidths,
        );
        
        // 디버깅: 데이터 행 칼럼 너비 계산 (숨김)
        // debugPrint('🔍 [report_table_builder.dart:3350] 데이터 행 칼럼 너비 계산');
        // debugPrint('   → 라인: 3350');
        // debugPrint('   → key: $key');
        // debugPrint('   → columnWidth (base 픽셀값): $columnWidth');
        // debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
        // debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
        // debugPrint('   → dataRowColumnWidth (최종 SizedBox 너비): $dataRowColumnWidth');
        // debugPrint('   → finalColumnWidths[$key]: ${finalColumnWidths[key]}');
        // if (isVentasInClosure) {
        //   debugPrint('   → ⚠️ [매칭 확인] 헤더의 headerSizedBoxWidth ($dataRowColumnWidth)와 일치해야 함');
        //   debugPrint('   → ⚠️ [매칭 확인] 헤더의 headerSizedBoxWidth는 ${useMeasuredWidths ? columnWidth : columnWidth + 32.0}이어야 함');
        //   debugPrint('   → ⚠️ [매칭 확인] 데이터 행의 SizedBox 너비는 $columnWidth (DataCell padding 32px 자동 추가)');
        // }
        // print('🔍 [report_table_builder.dart:3184] 데이터 행 칼럼 너비 가져오기');
        // print('   → 라인: 3184');
        // print('   → key: $key');
        // print('   → columnWidth (픽셀값): $columnWidth');
        // print('   → useMeasuredWidths: $useMeasuredWidths');
        // print('   → isVentasDayMonthYear: $isVentasDayMonthYear');
        // alertas 보고서는 padding이 1px이므로 다르게 처리
        if (isAlertas) {
          // alertasColumnWidth is already computed as dataRowColumnWidth above (_dataCellWidth)
          debugPrint('🔍 [Alertas _buildDataRowFromMap] DataCell 생성 - key: $key, columnWidth: $columnWidth, alertasColumnWidth: $dataRowColumnWidth, padding: 1px');
          debugPrint('   → 라인: 3367');
          // cell.child가 Align인 경우 Align의 child를 SizedBox로 감싸기
          if (cell.child is Align) {
            final align = cell.child as Align;
            debugPrint('   → cell.child는 Align 타입');
            return DataCell(
              Stack(
                children: [
                  SizedBox(
                    width: dataRowColumnWidth,  // 헤더와 동일하게 padding 추가
                    child: Align(
                      alignment: align.alignment,
                      child: align.child,
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
              ),
            );
          }
          // cell.child가 다른 타입인 경우 SizedBox로 감싸기
          debugPrint('   → cell.child는 ${cell.child.runtimeType} 타입');
          return DataCell(
            Stack(
              children: [
                SizedBox(
                  width: dataRowColumnWidth,  // 헤더와 동일하게 padding 추가
                  child: cell.child,
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
            ),
          );
        }
        // items/ingresos 보고서 또는 useMeasuredWidths가 true인 경우 기존대로
        // cell.child가 Align인 경우 Align의 child를 SizedBox로 감싸기
        if (cell.child is Align) {
          final align = cell.child as Align;
          debugPrint('   → [report_table_builder.dart:3205] cell.child는 Align 타입, SizedBox로 감싸기');
          debugPrint('   → 라인: 3205');
          debugPrint('   → columnWidth: $columnWidth');
          print('   → [report_table_builder.dart:3205] cell.child는 Align 타입, SizedBox로 감싸기');
          print('   → 라인: 3205');
          print('   → columnWidth: $columnWidth');
          // 디버깅: 데이터 행 칼럼에 수직선 추가 및 위치 측정 (라인 번호 포함)
          debugPrint('🔍 [report_table_builder.dart:3247] 데이터 행 칼럼 수직선 추가');
          debugPrint('   → 라인: 3247');
          debugPrint('   → key: $key');
          debugPrint('   → columnWidth (픽셀값): $columnWidth');
          debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
          debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
          print('🔍 [report_table_builder.dart:3247] 데이터 행 칼럼 수직선 추가');
          print('   → 라인: 3247');
          print('   → key: $key');
          print('   → columnWidth (픽셀값): $columnWidth');
          
          return DataCell(
            Builder(
              builder: (context) {
                // 디버깅: 데이터 행 칼럼 위치 및 너비 측정 (숨김)
                // WidgetsBinding.instance.addPostFrameCallback((_) {
                //   final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                //   if (renderBox != null) {
                //     debugPrint('═══════════════════════════════════════════════════════');
                //     debugPrint('🔍 [report_table_builder.dart:3255] 데이터 행 칼럼 위치 및 너비 측정');
                //     debugPrint('   → 라인: 3255');
                //     debugPrint('   → key: $key');
                //     debugPrint('   → columnWidth (설정된 픽셀값): $columnWidth');
                //     debugPrint('   → 실제 렌더링 위치: ${renderBox.localToGlobal(Offset.zero).dx}');
                //     debugPrint('   → 실제 렌더링 너비: ${renderBox.size.width}');
                //     debugPrint('   → 실제 칼럼 너비 (width + padding): ${renderBox.size.width}');
                //     print('🔍 [report_table_builder.dart:3255] 데이터 행 칼럼 위치 및 너비 측정');
                //     print('   → 라인: 3255');
                //     print('   → key: $key');
                //     print('   → columnWidth (설정된 픽셀값): $columnWidth');
                //     print('   → 실제 렌더링 위치: ${renderBox.localToGlobal(Offset.zero).dx}');
                //     print('   → 실제 렌더링 너비: ${renderBox.size.width}');
                //     debugPrint('═══════════════════════════════════════════════════════');
                //   }
                // });
                
                // 수직선을 별도로 추가하여 칼럼 너비에 영향 없도록 함
                return Stack(
                  children: [
                    SizedBox(
                      width: dataRowColumnWidth,  // 헤더의 headerSizedBoxWidth와 일치 (baseColumnWidth + 32.0)
                      child: Align(
                        alignment: align.alignment,
                        child: align.child,
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
        }
        // cell.child가 다른 타입인 경우 그대로 SizedBox로 감싸기
        debugPrint('   → [report_table_builder.dart:3290] cell.child는 ${cell.child.runtimeType} 타입, SizedBox로 감싸기');
        debugPrint('   → 라인: 3290');
        debugPrint('   → columnWidth: $columnWidth');
        print('   → [report_table_builder.dart:3290] cell.child는 ${cell.child.runtimeType} 타입, SizedBox로 감싸기');
        print('   → 라인: 3290');
        print('   → columnWidth: $columnWidth');
        
        // 디버깅: 데이터 행 칼럼에 수직선 추가 및 위치 측정 (라인 번호 포함)
        debugPrint('🔍 [report_table_builder.dart:3295] 데이터 행 칼럼 수직선 추가 (다른 타입)');
        debugPrint('   → 라인: 3295');
        debugPrint('   → key: $key');
        debugPrint('   → columnWidth (픽셀값): $columnWidth');
        print('🔍 [report_table_builder.dart:3295] 데이터 행 칼럼 수직선 추가 (다른 타입)');
        print('   → 라인: 3295');
        print('   → key: $key');
        print('   → columnWidth (픽셀값): $columnWidth');
        
        return DataCell(
          Builder(
            builder: (context) {
              // 디버깅: 데이터 행 칼럼 위치 및 너비 측정 (다른 타입) (숨김)
              // WidgetsBinding.instance.addPostFrameCallback((_) {
              //   final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
              //   if (renderBox != null) {
              //     debugPrint('═══════════════════════════════════════════════════════');
              //     debugPrint('🔍 [report_table_builder.dart:3303] 데이터 행 칼럼 위치 및 너비 측정 (다른 타입)');
              //     debugPrint('   → 라인: 3303');
              //     debugPrint('   → key: $key');
              //     debugPrint('   → columnWidth (설정된 픽셀값): $columnWidth');
              //     debugPrint('   → 실제 렌더링 위치: ${renderBox.localToGlobal(Offset.zero).dx}');
              //     debugPrint('   → 실제 렌더링 너비: ${renderBox.size.width}');
              //     print('🔍 [report_table_builder.dart:3303] 데이터 행 칼럼 위치 및 너비 측정 (다른 타입)');
              //     print('   → 라인: 3303');
              //     print('   → key: $key');
              //     print('   → columnWidth (설정된 픽셀값): $columnWidth');
              //     print('   → 실제 렌더링 위치: ${renderBox.localToGlobal(Offset.zero).dx}');
              //     print('   → 실제 렌더링 너비: ${renderBox.size.width}');
              //     debugPrint('═══════════════════════════════════════════════════════');
              //   }
              // });
              
              // 수직선을 별도로 추가하여 칼럼 너비에 영향 없도록 함
              // 공유 헬퍼로 계산 — outer scope의 dataRowColumnWidth와 동일한 값
              final dataRowColumnWidthForCell = dataRowColumnWidth;
              
              return Stack(
                children: [
                  SizedBox(
                    width: dataRowColumnWidthForCell,  // 헤더의 headerSizedBoxWidth와 일치 (items/ingresos는 padding 보정)
                    child: cell.child,
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
      }
      
      // useMeasuredWidths가 false이고 items/ingresos/alertas/ventas day/month/year도 아닌 경우
      debugPrint('🔍 [report_table_builder.dart:3250] 칼럼 너비 설정하지 않음');
      debugPrint('   → 라인: 3250');
      debugPrint('   → key: $key');
      debugPrint('   → isItemsOrIngresos: $isItemsOrIngresos');
      debugPrint('   → isAlertas: $isAlertas');
      debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
      debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
      debugPrint('   → ⚠️ [경고] 칼럼 너비가 설정되지 않아 헤더와 일치하지 않을 수 있음');
      print('🔍 [report_table_builder.dart:3250] 칼럼 너비 설정하지 않음');
      print('   → 라인: 3250');
      print('   → key: $key');
      print('   → useMeasuredWidths: $useMeasuredWidths');
      print('   → isVentasDayMonthYear: $isVentasDayMonthYear');
      
      return cell;
    }).toList();
    
    assert(cells.length == keys.length, 
      'Row cells count (${cells.length}) must match keys count (${keys.length})');
    
    // 제스처 추가 (ventas 또는 clientes 보고서)
    if ((onRowDoubleTap != null || onRowTap != null) && 
        (reportType == ReportType.ventas || reportType == ReportType.clientes) && 
        cells.isNotEmpty) {
      cells = addGesturesToCells(
        cells: cells,
        item: item,
        reportType: reportType,
        onRowDoubleTap: onRowDoubleTap,
        onRowTap: onRowTap,
        unit: unit,
      );
    }
    
    return DataRow(cells: cells);
  }

  /// Map이 아닌 데이터에서 DataRow 생성
  static DataRow buildDataRowFromNonMap({
    required dynamic item,
    required List<String> keys,
    required ReportType reportType,
    Map<String, double>? columnWidths,
    int rowIndex = 0, // 행 인덱스 (5행마다 색상 변경용)
  }) {
    // 디버깅: 함수 진입 확인
    debugPrint('   → [구문 검사] _buildDataRowFromNonMap 함수 시작');
    debugPrint('      → 파일: report_table_builder.dart');
    debugPrint('      → 라인: ${2192}');
    debugPrint('      → 함수명: _buildDataRowFromNonMap');
    debugPrint('      → 파라미터 개수: 4');
    debugPrint('      → reportType: $reportType');
    debugPrint('      → keys.length: ${keys.length}');
    debugPrint('      → item 타입: ${item.runtimeType}');
    debugPrint('      → columnWidths 전달됨: ${columnWidths != null}');
    
    final formattedValue = ReportUtils.formatValue(item);
    final isNumeric = ReportUtils.isNumeric(item);
    
    debugPrint('      → formattedValue: $formattedValue');
    debugPrint('      → isNumeric: $isNumeric');
    
    final cells = List.generate(keys.length, (index) {
      debugPrint('      → [셀 생성] index: $index, keys.length: ${keys.length}');
      return DataCell(
        Align(
          alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            index == 0 ? formattedValue : '',
            style: TextStyle(
              fontSize: 14, // ventas 보고서도 14px로 통일
              height: reportType == ReportType.ventas ? 1.0 : 1.2,
            ),
          ),
        ),
      );
    });
    
    debugPrint('   → [구문 검사] _buildDataRowFromNonMap 함수 종료');
    debugPrint('      → 반환 cells.length: ${cells.length}');
    
    // 매 5번째 행마다 색상 변경 (ventas, items, ingresos, fventas, gastos, clientes 보고서)
    final shouldApplyRowColor = reportType == ReportType.ventas ||
                                reportType == ReportType.items ||
                                reportType == ReportType.ingresos ||
                                reportType == ReportType.fventas ||
                                reportType == ReportType.gastos ||
                                reportType == ReportType.clientes;
    
    MaterialStateProperty<Color?>? rowColor;
    if (shouldApplyRowColor && rowIndex % 5 == 4) {
      // 매 5번째 행 (0-based index이므로 4, 9, 14, ...)에 약간 다른 색상 적용
      rowColor = MaterialStateProperty.all(Colors.grey.withOpacity(0.05));
    }
    
    return DataRow(
      cells: cells,
      color: rowColor,
    );
  }

  /// DataCell 생성
  static DataCell buildDataCell({
    required String key,
    required dynamic value,
    required ReportType reportType,
  }) {
    // 디버깅: 함수 진입 확인 (너무 많이 출력되지 않도록 제한)
    if (ReportTableBuilder.debugCellCount < 10) {
      debugPrint('   → [구문 검사] _buildDataCell 함수 시작');
      debugPrint('      → 파일: report_table_builder.dart');
      debugPrint('      → 라인: ${2218}');
      debugPrint('      → 함수명: _buildDataCell');
      debugPrint('      → 파라미터 개수: 3');
      debugPrint('      → key: $key');
      debugPrint('      → value 타입: ${value.runtimeType}');
      debugPrint('      → value: $value');
      debugPrint('      → reportType: $reportType');
      ReportTableBuilder.debugCellCount++;
    }
    
    String formattedValue;
    final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1' || key == 'vcode';
    final keyLower = key.toLowerCase();
    
    if (ReportTableBuilder.debugCellCount <= 10) {
      debugPrint('      → isCodigoColumn: $isCodigoColumn');
      debugPrint('      → keyLower: $keyLower');
    }
    
    // year 필드 포맷팅
    if (keyLower == 'year' && value != null) {
      final yearStr = value.toString();
      formattedValue = yearStr.contains('-') ? yearStr.split('-')[0] : yearStr;
    }
    // month 필드 포맷팅
    else if (keyLower == 'month' && value != null) {
      final monthStr = value.toString();
      formattedValue = (monthStr.length >= 7 && monthStr.contains('-')) 
          ? monthStr.substring(0, 7) 
          : monthStr;
    } else {
      formattedValue = isCodigoColumn 
          ? (value?.toString() ?? 'N/A')
          : ReportUtils.formatValue(value, fieldName: key, reportType: reportType);
    }
    
    // 숫자 컬럼 체크
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
    
    final isAlertas = reportType == ReportType.alertas;
    final isEventoColumn = keyLower == 'evento';
    
    // ventas 보고서에서 cntropas 칼럼은 가운데 정렬
    final isCntropasColumn = reportType == ReportType.ventas && 
                             (keyLower == 'cntropas' || keyLower == 'tcntropas' || keyLower == 'tcntropas');
    
    // 정렬 결정: cntropas는 가운데, 숫자는 오른쪽, 그 외는 왼쪽
    final alignment = isCntropasColumn 
        ? Alignment.center 
        : (isNumeric ? Alignment.centerRight : Alignment.centerLeft);
    
    return DataCell(
      Align(
        alignment: alignment,
        child: isAlertas
            ? Wrap(
                children: [
                  Text(
                    formattedValue,
                    style: TextStyle(
                      fontSize: 14,
                      height: isEventoColumn ? 1.3 : 1.2,
                    ),
                    maxLines: null,
                    overflow: TextOverflow.visible,
                  ),
                ],
              )
            : Text(
                formattedValue,
                style: TextStyle(
                  fontSize: 14, // ventas 보고서도 14px로 통일
                  height: reportType == ReportType.ventas ? 1.0 : 1.2,
                ),
              ),
      ),
    );
  }

  /// 셀에 제스처 추가
  static List<DataCell> addGesturesToCells({
    required List<DataCell> cells,
    required Map<String, dynamic> item,
    required ReportType reportType,
    Function(Map<String, dynamic>)? onRowDoubleTap,
    Function(Map<String, dynamic>)? onRowTap,
    String? unit,
  }) {
    // 디버깅: 제스처 추가 함수 진입 확인
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [구문 검사] _addGesturesToCells 함수 시작');
    debugPrint('   → 파일: report_table_builder.dart');
    debugPrint('   → 라인: ${2296}');
    debugPrint('   → 함수명: _addGesturesToCells');
    debugPrint('   → 파라미터 개수: 6');
    debugPrint('   → cells.length: ${cells.length}');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → onRowDoubleTap: ${onRowDoubleTap != null}');
    debugPrint('   → onRowTap: ${onRowTap != null}');
    debugPrint('   → unit: $unit');
    
    return cells.map((cell) {
      // 디버깅: 각 셀 처리 시작
      debugPrint('   → [제스처 추가] 셀 처리 시작 - cell.child 타입: ${cell.child.runtimeType}');
      
      Widget? childWidget;
      AlignmentGeometry? alignment;
      
      // Align 타입인 경우
      if (cell.child is Align) {
        final align = cell.child as Align;
        childWidget = align.child;
        alignment = align.alignment;
        debugPrint('   → [제스처 추가] Align 타입 셀 처리');
      }
      // SizedBox로 감싸진 경우 (items/ingresos/alertas 보고서)
      else if (cell.child is SizedBox) {
        final sizedBox = cell.child as SizedBox;
        if (sizedBox.child is Align) {
          final align = sizedBox.child as Align;
          childWidget = align.child;
          alignment = align.alignment;
          debugPrint('   → [제스처 추가] SizedBox > Align 타입 셀 처리');
        } else {
          childWidget = sizedBox.child;
          alignment = Alignment.centerLeft; // 기본 정렬
          debugPrint('   → [제스처 추가] SizedBox 타입 셀 처리 (Align 없음)');
        }
      }
      // 기타 위젯 타입
      else {
        childWidget = cell.child;
        alignment = Alignment.centerLeft; // 기본 정렬
        debugPrint('   → [제스처 추가] 기타 타입 셀 처리: ${cell.child.runtimeType}');
      }
      
      if (childWidget == null) {
        debugPrint('   → [제스처 추가] childWidget이 null - 그대로 반환');
        return cell;
      }
      
      // clientes 보고서는 항상 onTap 설정
      // ventas 보고서는 day/month/year 단위일 때 onTap 설정 (sucursal 필터링용)
      final shouldAddOnTap = onRowTap != null && 
          (reportType == ReportType.clientes || 
           (reportType == ReportType.ventas && unit != null && unit != 'vcode'));
      
      // ventas 보고서는 모든 unit에서 더블 클릭 지원 (year, month, day, vcode)
      final shouldAddOnDoubleTap = onRowDoubleTap != null && 
          (reportType == ReportType.ventas || reportType == ReportType.clientes);
      
      debugPrint('   → [제스처 추가] 제스처 설정');
      debugPrint('      → shouldAddOnTap: $shouldAddOnTap');
      debugPrint('      → shouldAddOnDoubleTap: $shouldAddOnDoubleTap');
      debugPrint('      → onRowDoubleTap != null: ${onRowDoubleTap != null}');
      debugPrint('      → onRowTap != null: ${onRowTap != null}');
      debugPrint('      → reportType: $reportType');
      debugPrint('      → unit: $unit');
      
      return DataCell(
        GestureDetector(
          onTap: shouldAddOnTap ? () {
            debugPrint('🔍 [report_table_builder] _addGesturesToCells - 단일클릭 감지됨!');
            debugPrint('→ reportType: $reportType');
            debugPrint('→ unit: $unit');
            debugPrint('→ item: $item');
            onRowTap!(item);
          } : null,
          onDoubleTap: shouldAddOnDoubleTap ? () {
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('🔍 [report_table_builder] _addGesturesToCells - 더블클릭 감지됨!');
            debugPrint('   → reportType: $reportType');
            debugPrint('   → unit: $unit');
            debugPrint('   → item keys: ${item.keys.toList()}');
            debugPrint('   → item: $item');
            debugPrint('   → onRowDoubleTap 콜백 호출 시작');
            onRowDoubleTap!(item);
            debugPrint('   → onRowDoubleTap 콜백 호출 완료');
            debugPrint('═══════════════════════════════════════════════════════');
          } : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            alignment: alignment ?? Alignment.centerLeft,
            child: childWidget,
          ),
        ),
      );
    }).toList();
  }
}
