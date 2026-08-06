import 'package:flutter/material.dart';
import '../models/fventas_summary.dart';
import 'report_utils.dart';
import '../utils/mobile_layout_helper.dart';
import 'report_table_header_footer.dart';
import 'report_table_measured_columns.dart';
import 'report_table/report_table_column_manager.dart';
import 'report_table/report_table_renderer.dart';

class ReportTableBuilder {
  // 디버깅용 카운터 (public so extracted data-row helpers can access them)
  static int debugRowCount = 0;
  static int debugCellCount = 0;
  // items/ingresos 헤더·데이터 셀 실제 렌더 위치/너비 디버깅 (칼럼 정렬 분석용)
  // ignore: library_private_types_in_public_api
  static int alignmentHeaderLoggedCount = 0;
  // ignore: library_private_types_in_public_api
  static int alignmentDataLoggedCount = 0;
  // ignore: library_private_types_in_public_api
  static final List<Map<String, dynamic>> alignmentHeaderDebugList = [];
  // ignore: library_private_types_in_public_api
  static final List<Map<String, dynamic>> alignmentDataDebugList = [];


  /// items/ingresos 헤더 vs 데이터 칼럼 위치·크기 비교 (정렬 불일치 원인 분석용). report_table_builder.dart
  static void printAlignmentComparison() {
    final headers = ReportTableBuilder.alignmentHeaderDebugList;
    final datas = ReportTableBuilder.alignmentDataDebugList;
    if (headers.length != datas.length || headers.isEmpty) return;
    const tol = 1.0; // 1px 오차 허용
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📐 [정렬디버그:비교] report_table_builder.dart 헤더 vs 데이터 칼럼 위치·크기');
    print('═══════════════════════════════════════════════════════');
    print('📐 [정렬디버그:비교] 헤더 vs 데이터 칼럼 위치·크기 (같으면 정렬 일치)');
    for (int i = 0; i < headers.length && i < datas.length; i++) {
      final h = headers[i];
      final d = datas[i];
      final key = h['key'] ?? d['key'] ?? 'col$i';
      final hContentLeft = (h['contentLeft'] as num).toDouble();
      final hContentWidth = (h['contentWidth'] as num).toDouble();
      final dContentLeft = (d['contentLeft'] as num).toDouble();
      final dContentWidth = (d['contentWidth'] as num).toDouble();
      final hCellLeft = (h['cellLeft'] as num).toDouble();
      final hCellWidth = (h['cellWidth'] as num).toDouble();
      final dCellLeft = (d['cellLeft'] as num).toDouble();
      final dCellWidth = (d['cellWidth'] as num).toDouble();
      final contentLeftOk = (hContentLeft - dContentLeft).abs() <= tol;
      final contentWidthOk = (hContentWidth - dContentWidth).abs() <= tol;
      final cellLeftOk = (hCellLeft - dCellLeft).abs() <= tol;
      final cellWidthOk = (hCellWidth - dCellWidth).abs() <= tol;
      debugPrint('   칼럼$i ($key) 헤더 contentLeft=${hContentLeft.toStringAsFixed(1)} contentWidth=${hContentWidth.toStringAsFixed(1)} | 데이터 contentLeft=${dContentLeft.toStringAsFixed(1)} contentWidth=${dContentWidth.toStringAsFixed(1)} | content일치=${contentLeftOk && contentWidthOk}');
      debugPrint('         헤더 cellLeft=${hCellLeft.toStringAsFixed(1)} cellWidth=${hCellWidth.toStringAsFixed(1)} | 데이터 cellLeft=${dCellLeft.toStringAsFixed(1)} cellWidth=${dCellWidth.toStringAsFixed(1)} | cell일치=${cellLeftOk && cellWidthOk}');
      print('   칼럼$i ($key) contentLeft H=${hContentLeft.toStringAsFixed(1)} D=${dContentLeft.toStringAsFixed(1)} ${contentLeftOk ? "OK" : "MISMATCH"} contentWidth H=${hContentWidth.toStringAsFixed(1)} D=${dContentWidth.toStringAsFixed(1)} ${contentWidthOk ? "OK" : "MISMATCH"}');
      print('         cellLeft H=${hCellLeft.toStringAsFixed(1)} D=${dCellLeft.toStringAsFixed(1)} ${cellLeftOk ? "OK" : "MISMATCH"} cellWidth H=${hCellWidth.toStringAsFixed(1)} D=${dCellWidth.toStringAsFixed(1)} ${cellWidthOk ? "OK" : "MISMATCH"}');
    }
    final anyMismatch = headers.asMap().entries.any((e) {
      final i = e.key;
      if (i >= datas.length) return false;
      final h = e.value;
      final d = datas[i];
      final hContentLeft = (h['contentLeft'] as num).toDouble();
      final dContentLeft = (d['contentLeft'] as num).toDouble();
      final hContentWidth = (h['contentWidth'] as num).toDouble();
      final dContentWidth = (d['contentWidth'] as num).toDouble();
      return (hContentLeft - dContentLeft).abs() > tol || (hContentWidth - dContentWidth).abs() > tol;
    });
    if (anyMismatch) {
      debugPrint('📐 [정렬디버그:원인] MISMATCH 시 의심: (1) DataCell 실제 padding이 16이 아님 (2) 헤더 Row와 DataTable columnSpacing 불일치 (3) FixedColumnWidth 미적용 (4) contentWidthElse=columnWidth-32 보정 불일치');
      print('📐 [정렬디버그:원인] MISMATCH 시 의심: DataCell padding, columnSpacing, FixedColumnWidth, contentWidthElse 보정');
    }
    debugPrint('═══════════════════════════════════════════════════════');
    print('═══════════════════════════════════════════════════════');
    ReportTableBuilder.alignmentHeaderDebugList.clear();
    ReportTableBuilder.alignmentDataDebugList.clear();
  }
  
  
  /// 화면에 표시되는 컬럼 목록을 반환 (PDF 생성용)
  static List<String> getDisplayedColumns(
    List<dynamic> dataList,
    ReportType reportType, {
    String? unit,
  }) {
    if (dataList.isEmpty) {
      return [];
    }

    final displayedList = dataList;
    final firstItem = displayedList.first as Map<String, dynamic>;
    List<String> keys;
    
    if (reportType == ReportType.ventas) {
      // vcode unit용 컬럼 목록 (응답 순서대로)
      final vcodeColumns = <String>[
        'vcode', 'tpago', 'cntropas', 'clientenombre',
        'tefectivo', 'tcredito', 'tbanco', 'treservado', 'tfavor',
        'vendedor', 'tipo', 'dni', 'hora', 'fecha',
        'resiva', 'casoesp', 'nencargado', 'cretmp',
        'sucursal', 'ntiqrepetir', 'b_mercadopago',
        'd_num_caja', 'd_num_terminal', 'id',
      ];
      
      // unit 파라미터 기반 판단
      final isDayMonthYearUnitFromParam = unit != null && unit != 'vcode';
      // 데이터 구조 기반 판단 (unit 파라미터가 vcode여도 실제 데이터가 day/month/year 유닛이면 true)
      // vcode 필드가 없고, fecha/month/year 중 하나가 있으면 day/month/year 유닛
      final hasVcodeField = firstItem.containsKey('vcode');
      final hasFechaField = firstItem.containsKey('fecha');
      final hasMonthField = firstItem.containsKey('month');
      final hasYearField = firstItem.containsKey('year');
      final hasDayMonthYearKey = hasFechaField || hasMonthField || hasYearField;
      // vcode 유닛 전용 필드들 (day/month/year 유닛에는 없음)
      final hasVcodeOnlyFields = firstItem.containsKey('tpago') || 
                                 firstItem.containsKey('cntropas') ||
                                 firstItem.containsKey('d_num_caja') ||
                                 firstItem.containsKey('d_num_terminal') ||
                                 firstItem.containsKey('clientenombre') ||
                                 firstItem.containsKey('vendedor') ||
                                 firstItem.containsKey('tipo') ||
                                 firstItem.containsKey('dni') ||
                                 firstItem.containsKey('hora') ||
                                 firstItem.containsKey('resiva') ||
                                 firstItem.containsKey('casoesp') ||
                                 firstItem.containsKey('cretmp') ||
                                 firstItem.containsKey('ntiqrepetir') ||
                                 firstItem.containsKey('b_mercadopago');
      // vcode 필드가 없고, day/month/year 키가 있으면 day/month/year 유닛
      // hasVcodeOnlyFields는 참고용으로만 사용 (vcode 필드가 없으면 우선순위가 높음)
      final isDayMonthYearUnitFromData = !hasVcodeField && hasDayMonthYearKey;
      // 최종 판단: unit 파라미터 또는 데이터 구조 중 하나라도 day/month/year 유닛이면 true
      final isDayMonthYearUnit = isDayMonthYearUnitFromParam || isDayMonthYearUnitFromData;
      
      final isDayUnit = unit == 'day' || (isDayMonthYearUnitFromData && firstItem.containsKey('fecha'));
      final isMonthUnit = unit == 'month' || (isDayMonthYearUnitFromData && firstItem.containsKey('month'));
      final isYearUnit = unit == 'year' || (isDayMonthYearUnitFromData && firstItem.containsKey('year'));
      
      debugPrint('🔍 [getDisplayedColumns] unit 판단');
      debugPrint('   → unit 파라미터: $unit');
      debugPrint('   → firstItem keys: ${firstItem.keys.toList()}');
      debugPrint('   → hasVcodeField: $hasVcodeField');
      debugPrint('   → hasFechaField: $hasFechaField');
      debugPrint('   → hasMonthField: $hasMonthField');
      debugPrint('   → hasYearField: $hasYearField');
      debugPrint('   → hasDayMonthYearKey: $hasDayMonthYearKey');
      debugPrint('   → hasVcodeOnlyFields: $hasVcodeOnlyFields');
      debugPrint('   → isDayMonthYearUnitFromParam: $isDayMonthYearUnitFromParam');
      debugPrint('   → isDayMonthYearUnitFromData: $isDayMonthYearUnitFromData');
      debugPrint('   → isDayMonthYearUnit (최종): $isDayMonthYearUnit');
      debugPrint('   → isDayUnit: $isDayUnit');
      debugPrint('   → isMonthUnit: $isMonthUnit');
      debugPrint('   → isYearUnit: $isYearUnit');
      
      // 모든 행에서 공통으로 존재하는 컬럼 확인
      final commonKeys = <String>{};
      final allKeys = <String>{};
      for (var item in displayedList) {
        if (item is Map<String, dynamic>) {
          allKeys.addAll(item.keys);
          if (commonKeys.isEmpty) {
            commonKeys.addAll(item.keys);
          } else {
            commonKeys.removeWhere((key) => !item.containsKey(key));
          }
        }
      }
      
      if (isDayMonthYearUnit) {
        // day/month/year unit용 컬럼
        final dayMonthYearColumns = <String>[
          'fecha', 'month', 'year', 'eventCount',
          'tVents', 'tVentas', 'tCntRopas',
          'tefectivo', 'tcredito', 'tbanco', 'treservado', 'tfavor',
          'nencargado', 'sucursal',
        ];
        
        final requiredFields = <String>[];
        final actualEventCountKey = allKeys.firstWhere(
          (key) => key.toLowerCase() == 'eventcount',
          orElse: () => '',
        );
        final actualTVentsKey = allKeys.firstWhere(
          (key) => key.toLowerCase() == 'tvents',
          orElse: () => '',
        );
        final actualTVentasKey = allKeys.firstWhere(
          (key) => key.toLowerCase() == 'tventas',
          orElse: () => '',
        );
        final actualTCntRopasKey = allKeys.firstWhere(
          (key) => key.toLowerCase() == 'tcntropas',
          orElse: () => '',
        );
        
        if (isDayUnit || isMonthUnit) {
          if (actualEventCountKey.isNotEmpty) requiredFields.add(actualEventCountKey);
          if (actualTVentsKey.isNotEmpty) requiredFields.add(actualTVentsKey);
          if (actualTVentasKey.isNotEmpty) requiredFields.add(actualTVentasKey);
          if (actualTCntRopasKey.isNotEmpty) requiredFields.add(actualTCntRopasKey);
        }
        
        keys = dayMonthYearColumns.where((key) {
          final keyLower = key.toLowerCase();
          return commonKeys.any((k) => k.toLowerCase() == keyLower) ||
                 requiredFields.any((k) => k.toLowerCase() == keyLower);
        }).toList();
        
        // 실제 키 이름으로 교체
        final keyMap = <String, String>{};
        for (var key in keys) {
          final actualKey = allKeys.firstWhere(
            (k) => k.toLowerCase() == key.toLowerCase(),
            orElse: () => key,
          );
          if (actualKey != key) {
            keyMap[key] = actualKey;
          }
        }
        keys = keys.map((key) => keyMap[key] ?? key).toList();
        
        // day unit일 때 fecha를 첫 번째로
        if (isDayUnit) {
          final actualFechaKey = allKeys.firstWhere(
            (k) => k.toLowerCase() == 'fecha',
            orElse: () => 'fecha',
          );
          if (keys.contains(actualFechaKey)) {
            keys.remove(actualFechaKey);
            keys.insert(0, actualFechaKey);
          }
          if (actualEventCountKey.isNotEmpty && keys.contains(actualEventCountKey)) {
            keys.remove(actualEventCountKey);
            keys.insert(1, actualEventCountKey);
          }
        }
        
        // month unit일 때 month를 첫 번째로
        if (isMonthUnit) {
          final actualMonthKey = allKeys.firstWhere(
            (k) => k.toLowerCase() == 'month',
            orElse: () => 'month',
          );
          if (keys.contains(actualMonthKey)) {
            keys.remove(actualMonthKey);
            keys.insert(0, actualMonthKey);
          }
          if (actualEventCountKey.isNotEmpty && keys.contains(actualEventCountKey)) {
            keys.remove(actualEventCountKey);
            keys.insert(1, actualEventCountKey);
          }
        }
        
        // day unit일 때는 nencargado 제외
        if (isDayUnit) {
          keys.removeWhere((key) => key == 'nencargado');
        }
        
        // vcode unit 전용 필드 제거
        final vcodeOnlyFields = ['vcode', 'tpago', 'cntropas', 'd_num_caja', 'd_num_terminal', 
                                 'id', 'hora', 'clientenombre', 'vendedor', 'tipo', 'dni', 
                                 'resiva', 'casoesp', 'cretmp', 'ntiqrepetir', 'b_mercadopago'];
        keys.removeWhere((key) => vcodeOnlyFields.contains(key));
      } else {
        // vcode unit: vcodeColumns 순서 유지
        final commonKeysVcode = <String>{};
        for (var item in displayedList) {
          if (item is Map<String, dynamic>) {
            if (commonKeysVcode.isEmpty) {
              commonKeysVcode.addAll(vcodeColumns.where((key) => item.containsKey(key)));
            } else {
              commonKeysVcode.removeWhere((key) => !item.containsKey(key));
            }
          }
        }
        // vcodeColumns의 순서를 유지하면서 commonKeysVcode에 있는 키만 선택
        keys = vcodeColumns.where((key) => commonKeysVcode.contains(key)).toList();
        print('📊 Ventas vcode columns 순서 (getDisplayedColumns): $keys');
      }
    } else if (reportType == ReportType.items || reportType == ReportType.ingresos) {
      // Items 및 Ingresos 보고서: start_date, end_date, startDate, endDate, sucursal 제외
      keys = firstItem.keys
          .where((key) => 
              key != 'start_date' && 
              key != 'end_date' && 
              key != 'startDate' && 
              key != 'endDate' && 
              key != 'sucursal')
          .toList();
    } else {
      keys = firstItem.keys.toList();
    }
    
    return keys;
  }

  static Widget buildTableFromList(
    List<dynamic> dataList,
    int displayedItemsCount,
    int itemsPerPage,
    ScrollController scrollController,
    ReportType reportType, {
    String? sortColumn,
    bool sortAscending = true,
    Function(int columnIndex, bool ascending)? onSort,
    ScrollController? horizontalScrollController,
    Color? reportColor, // 선택적 색상 파라미터 추가
    String? unit, // ventas report의 unit (vcode, day, month, year)
    Function(Map<String, dynamic>)? onRowDoubleTap, // 행 더블 클릭 콜백
    Function(Map<String, dynamic>)? onRowTap, // 행 단일 클릭 콜백
    Map<String, double>? externalColumnWidths, // Items/Ingresos/Gastos 칼럼 리사이즈용
    void Function(String columnKey, double newWidth)? onColumnResize,
    FventasSummary? fventasSummary, // fventas 푸터용 기간 전체 집계 (서버 summary 블록)
  }) {
    // 디버깅: buildTableFromList 시작
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [report_table_builder.dart:246] [${reportType.name}] buildTableFromList 시작');
    debugPrint('   → 라인: 246');
    debugPrint('   → unit 파라미터 (raw): $unit');
    debugPrint('   → unit 파라미터 타입: ${unit.runtimeType}');
    debugPrint('   → unit == "day": ${unit == "day"}');
    debugPrint('   → unit == "month": ${unit == "month"}');
    debugPrint('   → unit == "year": ${unit == "year"}');
    debugPrint('   → unit == "vcode": ${unit == "vcode"}');
    debugPrint('   → unit != null: ${unit != null}');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → horizontalScrollController: ${horizontalScrollController != null}');
    print('🔍 [report_table_builder.dart:246] [${reportType.name}] buildTableFromList 시작');
    print('   → 라인: 246');
    print('   → unit 파라미터 (raw): $unit');
    print('   → unit == "year": ${unit == "year"}');
    if (horizontalScrollController != null) {
      debugPrint('   → horizontalScrollController.hasClients: ${horizontalScrollController.hasClients}');
      if (horizontalScrollController.hasClients) {
        try {
          // 여러 스크롤 뷰에 연결된 경우를 처리
          if (horizontalScrollController.positions.length == 1) {
        debugPrint('   → horizontalScrollController.position.pixels: ${horizontalScrollController.position.pixels}');
        debugPrint('   → horizontalScrollController.position.maxScrollExtent: ${horizontalScrollController.position.maxScrollExtent}');
          } else {
            debugPrint('   ⚠️ horizontalScrollController가 ${horizontalScrollController.positions.length}개의 스크롤 뷰에 연결됨');
          }
        } catch (e) {
          debugPrint('   ⚠️ horizontalScrollController.position 접근 오류: $e');
        }
      }
    }
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📊 [ReportTableBuilder:176] buildTableFromList 함수 시작');
    debugPrint('   → 파일: report_table_builder.dart');
    debugPrint('   → 라인: 176');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → dataList.length: ${dataList.length}');
    debugPrint('   → displayedItemsCount: $displayedItemsCount');
    debugPrint('   → itemsPerPage: $itemsPerPage');
    
    if (dataList.isEmpty) {
      debugPrint('   ⚠️ [ReportTableBuilder:191] dataList가 비어있습니다!');
      return const Center(child: Text('No hay datos'));
    }

    final displayedList = dataList.take(displayedItemsCount).toList();
    final totalCount = dataList.length;
    final color = reportColor ?? ReportUtils.getReportColor(reportType);
    
    debugPrint('   → displayedList.length: ${displayedList.length}');
    debugPrint('   → totalCount: $totalCount');
    

    if (displayedList.isEmpty) {
      return const Center(child: Text('No hay elementos para mostrar'));
    }

    // 칼럼 키 선택 (ReportTableColumnManager로 추출됨)
    final keys = ReportTableColumnManager.getKeysForReportType(
      displayedList: displayedList,
      reportType: reportType,
      unit: unit,
    );
    // 칼럼별 기본 너비 설정 (ReportTableColumnManager로 추출됨)
    final columnWidths = ReportTableColumnManager.getDefaultColumnWidths(reportType, unit: unit, keys: keys);
    if (externalColumnWidths != null && externalColumnWidths.isNotEmpty) {
      columnWidths.addAll(externalColumnWidths);
    }
    
    final columns = keys.asMap().entries.map((entry) {
      final index = entry.key;
      final key = entry.value;
      final isSorted = sortColumn == key;
      // Items 및 Ingresos 보고서는 모든 컬럼 정렬 가능 (이전에는 특정 키만 허용했지만, 모든 칼럼 정렬 가능하도록 변경)
      final isSortable = reportType == ReportType.items || 
                         reportType == ReportType.ingresos ||
                         reportType == ReportType.ventas || // ventas 보고서는 모든 컬럼 정렬 가능
                         reportType == ReportType.clientes; // clientes 보고서는 모든 컬럼 정렬 가능
      
      // 디버깅: items/ingresos 보고서의 정렬 가능 여부 확인
      if (reportType == ReportType.items || reportType == ReportType.ingresos) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [Items/Ingresos] 칼럼 정렬 가능 여부 확인');
        debugPrint('   → 칼럼 #$index ($key)');
        debugPrint('   → isSortable: $isSortable');
        debugPrint('   → onSort != null: ${onSort != null}');
        debugPrint('   → 최종 정렬 가능: ${isSortable && onSort != null}');
        if (!isSortable) {
          debugPrint('   ⚠️ 정렬 불가: key가 허용 목록에 없음');
          debugPrint('   → 허용된 키: codigo, codigo1, descripcion, desc1, tprendas, timporte, tIngreso, tingreso, tevent, tcant, cntEvent, cntevent');
        }
        if (isSortable && onSort == null) {
          debugPrint('   ⚠️ 정렬 불가: onSort 콜백이 null');
        }
        debugPrint('═══════════════════════════════════════════════════════');
      }
      
      return DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              key.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14, // ventas 보고서도 14px로 통일
              ),
            ),
            if (isSorted && isSortable)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: reportType == ReportType.ventas ? 14 : 16,
                color: color,
              ),
          ],
        ),
        onSort: isSortable && onSort != null
            ? (columnIndex, ascending) {
                debugPrint('═══════════════════════════════════════════════════════');
                debugPrint('🔍 [ReportTableBuilder] DataColumn onSort 콜백 호출');
                debugPrint('   → reportType: $reportType');
                debugPrint('   → key: $key');
                debugPrint('   → columnIndex: $columnIndex');
                debugPrint('   → ascending: $ascending');
                debugPrint('   → isSortable: $isSortable');
                debugPrint('   → onSort != null: ${onSort != null}');
                debugPrint('   → keys.length: ${keys.length}');
                debugPrint('   → keys: $keys');
                
                // DataTable이 전달하는 columnIndex는 columns 리스트의 인덱스이므로
                // keys 리스트의 인덱스와 동일합니다
                if (columnIndex >= 0 && columnIndex < keys.length) {
                  debugPrint('   → 유효한 columnIndex, onSort 호출');
                  onSort(columnIndex, ascending);
                  debugPrint('   ✅ onSort 호출 완료');
                } else {
                  debugPrint('   ⚠️ 경고: columnIndex($columnIndex)가 유효 범위를 벗어남 (0~${keys.length - 1})');
                }
                debugPrint('═══════════════════════════════════════════════════════');
              }
            : null,
      );
    }).toList();

    // items 및 ingresos 보고서는 전체 폭을 차지하도록 다른 구조 사용 (먼저 확인)
    final isItemsOrIngresos = reportType == ReportType.items || reportType == ReportType.ingresos;
    
    // 디버깅 카운터 리셋 (매번 테이블이 빌드될 때마다)
    if (isItemsOrIngresos) {
      debugRowCount = 0;
    }
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📊 [ReportTableBuilder] buildTableFromList 시작');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → reportType.name: ${reportType.name}');
    debugPrint('   → reportType == ReportType.alertas: ${reportType == ReportType.alertas}');
    debugPrint('   → ReportType.alertas: ${ReportType.alertas}');
    debugPrint('   → ReportType.alertas.name: ${ReportType.alertas.name}');
    debugPrint('   → keys: $keys');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → displayedList.length: ${displayedList.length}');
    debugPrint('═══════════════════════════════════════════════════════');
    
    debugPrint('   → [ReportTableBuilder:593] isItemsOrIngresos 계산 (조기 확인)');
    debugPrint('      → reportType == ReportType.items: ${reportType == ReportType.items}');
    debugPrint('      → reportType == ReportType.ingresos: ${reportType == ReportType.ingresos}');
    debugPrint('      → isItemsOrIngresos: $isItemsOrIngresos');
    debugPrint('   → [ReportTableBuilder:593] alertas 체크');
    debugPrint('      → reportType == ReportType.alertas: ${reportType == ReportType.alertas}');
    debugPrint('      → reportType.runtimeType: ${reportType.runtimeType}');
    debugPrint('      → ReportType.alertas.runtimeType: ${ReportType.alertas.runtimeType}');
    
    // Alertas 보고서는 Table 위젯을 사용하여 칼럼 너비를 명시적으로 제어
    if (reportType == ReportType.alertas) {
      debugPrint('✅ [Alertas 체크] 조건 통과 - alertas 전용 경로 실행');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔍 [Alertas 전용 경로] 실행 시작');
      debugPrint('   → reportType: $reportType');
      debugPrint('   → keys: $keys');
      debugPrint('   → keys.length: ${keys.length}');
      debugPrint('═══════════════════════════════════════════════════════');
      
      // Alertas 보고서의 경우 화면 너비에 맞춰 컬럼 너비 동적 계산
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          // Alertas 전용 동적 칼럼 너비 계산 (ReportTableColumnManager로 추출됨)
          final dynamicColumnWidths = ReportTableColumnManager.getAlertasColumnWidths(keys, screenWidth);
          
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('📊 [Alertas 보고서] 테이블 빌드 시작');
          debugPrint('   → keys: $keys');
          debugPrint('   → keys.length: ${keys.length}');
          debugPrint('   → displayedList.length: ${displayedList.length}');
          debugPrint('   → dataList.length: ${dataList.length}');
          debugPrint('   → dynamicColumnWidths: $dynamicColumnWidths');
          debugPrint('   → screenWidth: $screenWidth');
          debugPrint('   → availableWidth: ${screenWidth - (1 * (keys.length - 1) + 32)}');
          debugPrint('═══════════════════════════════════════════════════════');
          
          // alertas 보고서는 Table 위젯 내부에 헤더가 포함되어 있으므로 별도 헤더 생성 불필요
          debugPrint('📊 [Alertas 보고서] Table 위젯 사용 (헤더는 Table 내부에 포함됨)');
          debugPrint('   → keys: $keys');
          debugPrint('   → columns.length: ${columns.length}');
          debugPrint('   → dynamicColumnWidths: $dynamicColumnWidths');
          
          return Column(
            children: [
              Expanded(
                child: Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    scrollDirection: Axis.vertical,
                    child: Builder(
                      builder: (context) {
                        // alertas 보고서는 DataTable의 칼럼 너비를 명시적으로 제어하기 위해
                        // 전체 너비를 계산하여 SizedBox로 감싸기
                        final totalTableWidth = keys.fold<double>(0.0, (sum, key) {
                          final width = dynamicColumnWidths[key] ?? 150.0;
                          return sum + width + 1; // columnSpacing 1 추가
                        });
                        
                        debugPrint('═══════════════════════════════════════════════════════');
                        debugPrint('🔍 [Alertas DataTable] 총 너비 계산 시작');
                        debugPrint('   → keys: $keys');
                        debugPrint('   → dynamicColumnWidths: $dynamicColumnWidths');
                        debugPrint('   → 총 너비 계산: $totalTableWidth');
                        debugPrint('   → 칼럼별 너비: ${keys.map((k) => '$k=${dynamicColumnWidths[k] ?? 150.0}').join(', ')}');
                        debugPrint('═══════════════════════════════════════════════════════');
                        
                        // DataTable이 칼럼 너비를 자동으로 계산하므로, Table 위젯을 사용하여
                        // 각 칼럼의 너비를 명시적으로 제어
                        return SizedBox(
                          width: totalTableWidth,
                          child: Table(
                            columnWidths: keys.asMap().map((index, key) {
                              final columnWidth = dynamicColumnWidths[key] ?? 150.0;
                              return MapEntry(index, FixedColumnWidth(columnWidth));
                            }),
                            border: TableBorder(
                              horizontalInside: BorderSide(color: Colors.grey.shade300, width: 0.5),
                              verticalInside: BorderSide(color: Colors.grey.shade300, width: 0.5),
                            ),
                            children: [
                              // 헤더 행
                              TableRow(
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                ),
                                children: columns.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final col = entry.value;
                                  final key = keys[index];
                                  final columnWidth = dynamicColumnWidths[key] ?? 150.0;
                                  debugPrint('📊 [Alertas Table] 헤더 셀 생성 - index: $index, key: $key, width: $columnWidth');
                                  
                                  // 대형 화면 감지 (1200px 이상)
                                  final isLargeScreen = screenWidth >= 1200;
                                  // 대형 화면에서는 헤더 행 높이도 2/3로 줄임 (vertical padding: 8 -> 5.33, 약 5)
                                  final headerVerticalPadding = isLargeScreen ? 5.33 : 8.0;
                                  
                                  return Container(
                                    padding: EdgeInsets.symmetric(horizontal: 1, vertical: headerVerticalPadding),
                                    child: GestureDetector(
                                      onTap: col.onSort != null ? () {
                                        if (sortColumn == key) {
                                          col.onSort!(index, !sortAscending);
                                        } else {
                                          col.onSort!(index, false);
                                        }
                                      } : null,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: col.label,
                                          ),
                                          if (col.onSort != null && sortColumn == key)
                                            Icon(
                                              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                              size: 16,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              // 데이터 행
                              ...displayedList.map((item) {
                                if (item is Map<String, dynamic>) {
                                  return TableRow(
                                    children: keys.map((key) {
                                      // 키 이름 대소문자 구분 없이 찾기
                                      final actualKey = item.keys.firstWhere(
                                        (k) => k.toLowerCase() == key.toLowerCase(),
                                        orElse: () => key,
                                      );
                                      final value = item[actualKey];
                                      
                                      final keyLower = key.toLowerCase();
                                      final isEventoColumn = keyLower == 'evento';
                                      
                                      // evento 컬럼은 formatValue에서 자르지 않음 (2줄 표시를 위해)
                                      String formattedValue;
                                      if (isEventoColumn && value is String) {
                                        formattedValue = value.replaceAll('\$', '').trim();
                                      } else {
                                        formattedValue = ReportUtils.formatValue(value, fieldName: key, reportType: reportType);
                                      }
                                      
                                      final isAmountColumn = keyLower == 'sucursal';
                                      final isNumeric = ReportUtils.isNumeric(value) || isAmountColumn;
                                      
                                      final cellWidth = dynamicColumnWidths[key] ?? 150.0;
                                      
                                      debugPrint('🔍 [Alertas Table] 데이터 셀 생성 - key: $key, width: $cellWidth, value: $formattedValue');
                                      
                                      // 대형 화면 감지 (1200px 이상)
                                      final isLargeScreen = screenWidth >= 1200;
                                      // 대형 화면에서는 행 높이를 2/3로 줄임 (vertical padding: 4 -> 2.67, 약 3)
                                      final verticalPadding = isLargeScreen ? 2.67 : 4.0;
                                      
                                      debugPrint('   → [행 높이] isLargeScreen: $isLargeScreen, verticalPadding: $verticalPadding');
                                      
                                      return Container(
                                        padding: EdgeInsets.symmetric(horizontal: 1, vertical: verticalPadding),
                                        child: Align(
                                          alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                                          child: Text(
                                            formattedValue,
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: isEventoColumn ? 1.3 : 1.2,
                                            ),
                                            maxLines: null,
                                            overflow: TextOverflow.visible,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                }
                                // 대형 화면 감지 (1200px 이상)
                                final isLargeScreen = screenWidth >= 1200;
                                // 대형 화면에서는 행 높이를 2/3로 줄임 (vertical padding: 4 -> 2.67, 약 3)
                                final verticalPadding = isLargeScreen ? 2.67 : 4.0;
                                
                                return TableRow(
                                  children: keys.map((key) => Container(
                                    padding: EdgeInsets.symmetric(horizontal: 1, vertical: verticalPadding),
                                    child: const Text(''),
                                  )).toList(),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Footer: 총 데이터 개수만 표시
              Builder(
                builder: (context) {
                  debugPrint('📊 [Alertas 보고서] Footer 빌드 시작');
                  debugPrint('   → dataList.length: ${dataList.length}');
                  debugPrint('   → displayedList.length: ${displayedList.length}');
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      border: Border(top: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: buildFixedTotalRow(
                      keys,
                      displayedList,
                      color,
                      columnWidths: dynamicColumnWidths,
                      dataList: dataList,
                      fventasSummary: fventasSummary,
                      reportType: reportType,
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    }
    
    // ventas 보고서의 day/month/year 유닛인지 확인
    // unit 파라미터가 day/month/year이면 우선 적용
    // unit 파라미터가 vcode이거나 null이어도 실제 데이터 구조를 확인하여 판단
    bool isVentasDayMonthYearFromUnit = reportType == ReportType.ventas && 
                                        unit != null && 
                                        (unit == 'day' || unit == 'month' || unit == 'year');
    
    // 데이터 구조 기반 판단 (unit 파라미터가 vcode여도 실제 데이터가 day/month/year 유닛이면 true)
    bool isVentasDayMonthYearFromData = false;
    if (reportType == ReportType.ventas && displayedList.isNotEmpty) {
      final firstItem = displayedList.first;
      if (firstItem is Map<String, dynamic>) {
        final hasVcodeField = firstItem.containsKey('vcode');
        final hasFechaField = firstItem.containsKey('fecha');
        final hasMonthField = firstItem.containsKey('month');
        final hasYearField = firstItem.containsKey('year');
        final hasDayMonthYearKey = hasFechaField || hasMonthField || hasYearField;
        // vcode 필드가 없고, day/month/year 키가 있으면 day/month/year 유닛
        isVentasDayMonthYearFromData = !hasVcodeField && hasDayMonthYearKey;
      }
    }
    
    final isVentasDayMonthYear = isVentasDayMonthYearFromUnit || isVentasDayMonthYearFromData;
    
    debugPrint('🔍 [report_table_builder.dart:1080] [buildTableFromList] ventas day/month/year 유닛 판단 (조기 처리)');
    debugPrint('   → 라인: 1080');
    debugPrint('   → [report_table_builder.dart:1081] unit 파라미터: $unit');
    debugPrint('   → [report_table_builder.dart:1082] isVentasDayMonthYearFromUnit: $isVentasDayMonthYearFromUnit');
    debugPrint('   → [report_table_builder.dart:1083] isVentasDayMonthYearFromData: $isVentasDayMonthYearFromData');
    debugPrint('   → [report_table_builder.dart:1078] isVentasDayMonthYear (최종): $isVentasDayMonthYear');
    print('🔍 [report_table_builder.dart:1080] [buildTableFromList] ventas day/month/year 유닛 판단 (조기 처리)');
    print('   → 라인: 1080');
    print('   → unit 파라미터: $unit');
    print('   → isVentasDayMonthYearFromUnit: $isVentasDayMonthYearFromUnit');
    print('   → isVentasDayMonthYearFromData: $isVentasDayMonthYearFromData');
    print('   → isVentasDayMonthYear (최종): $isVentasDayMonthYear');
    
    // items 및 ingresos 보고서는 LayoutBuilder로 전체 폭 강제 (먼저 처리)
    // ventas day/month/year 유닛도 실제 칼럼 너비를 측정하여 헤더에 적용
    if (isItemsOrIngresos || isVentasDayMonthYear) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📊 [report_table_builder.dart:1088] buildTableFromList - ${isItemsOrIngresos ? "Items/Ingresos" : "Ventas Day/Month/Year"} 모드 진입 (조기 처리)');
      debugPrint('   → 라인: 1088');
      debugPrint('   → 파일: report_table_builder.dart');
      debugPrint('   → [report_table_builder.dart:1093] reportType: $reportType');
      debugPrint('   → [report_table_builder.dart:1094] isItemsOrIngresos: $isItemsOrIngresos');
      debugPrint('   → [report_table_builder.dart:1095] isVentasDayMonthYear: $isVentasDayMonthYear');
      debugPrint('   → [report_table_builder.dart:1096] unit: $unit');
      print('📊 [report_table_builder.dart:1088] buildTableFromList - ${isItemsOrIngresos ? "Items/Ingresos" : "Ventas Day/Month/Year"} 모드 진입 (조기 처리)');
      print('   → 라인: 1088');
      print('   → unit: $unit');
      print('   → isVentasDayMonthYear: $isVentasDayMonthYear');
      
      debugPrint('✅ [${isItemsOrIngresos ? "Items/Ingresos" : "Ventas Day/Month/Year"} 체크] 조건 통과 - 전용 경로 실행');
      debugPrint('   → reportType: $reportType');
      print('✅ [${isItemsOrIngresos ? "Items/Ingresos" : "Ventas Day/Month/Year"} 체크] 조건 통과 - 전용 경로 실행');
      print('   → reportType: $reportType');
      print('   → unit: $unit');
      
      // DataTable의 실제 칼럼 너비를 측정하여 헤더와 푸터에 적용하기 위한 StatefulWidget
      // unit이나 keys가 변경되면 위젯을 재생성하도록 key를 추가
      final widgetKey = ValueKey('${reportType}_${unit}_${keys.join('_')}');
      debugPrint('🔍 [report_table_builder.dart:1122] _ItemsTableWithMeasuredColumns 생성');
      debugPrint('   → 라인: 1122');
      debugPrint('   → widgetKey: $widgetKey');
      debugPrint('   → unit: $unit');
      debugPrint('   → keys: $keys');
      debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
      print('🔍 [report_table_builder.dart:1122] _ItemsTableWithMeasuredColumns 생성');
      print('   → 라인: 1122');
      print('   → widgetKey: $widgetKey');
      print('   → unit: $unit');
      print('   → keys: $keys');
      print('   → isVentasDayMonthYear: $isVentasDayMonthYear');
      return ItemsTableWithMeasuredColumns(
        key: widgetKey,
        keys: keys,
        columns: columns,
        color: color,
        sortColumn: sortColumn,
        sortAscending: sortAscending,
        onSort: onSort,
        columnWidths: columnWidths,
        displayedList: displayedList,
        dataList: dataList,
        fventasSummary: fventasSummary,
        reportType: reportType,
        onRowDoubleTap: onRowDoubleTap,
        onRowTap: onRowTap,
        unit: unit,
        scrollController: scrollController,
        horizontalScrollController: horizontalScrollController,
        onColumnResize: onColumnResize,
      );
    }
    
    // 기존 코드 (다른 보고서들)
    return LayoutBuilder(
        builder: (context, constraints) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('📊 [ReportTableBuilder:610] buildTableFromList Column LayoutBuilder 시작');
          debugPrint('   → 파일: report_table_builder.dart');
          debugPrint('   → 라인: 610');
          debugPrint('   → reportType: $reportType');
          debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
          debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
          debugPrint('   → constraints.minWidth: ${constraints.minWidth}');
          debugPrint('   → constraints.minHeight: ${constraints.minHeight}');
          
          debugPrint('   → [ReportTableBuilder:620] ConstrainedBox 생성 시작');
          debugPrint('      → minWidth: ${constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity}');
          debugPrint('      → maxWidth: ${constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity}');
          
          return ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity,
              maxWidth: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity,
            ),
            child: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    debugPrint('═══════════════════════════════════════════════════════');
                    debugPrint('📊 [ReportTableBuilder:625] ConstrainedBox 실제 렌더링 크기 (PostFrameCallback)');
                    debugPrint('   → 파일: report_table_builder.dart');
                    debugPrint('   → 라인: 625');
                    debugPrint('   → ConstrainedBox width: ${renderBox.size.width}');
                    debugPrint('   → ConstrainedBox height: ${renderBox.size.height}');
                    debugPrint('   → 예상 width: ${constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity}');
                  }
                });
                
                return SizedBox(
                  width: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity,
                  child: Builder(
                    builder: (context) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                        if (renderBox != null) {
                          debugPrint('   → [ReportTableBuilder:640] SizedBox 실제 렌더링 크기 (PostFrameCallback)');
                          debugPrint('      → 파일: report_table_builder.dart');
                          debugPrint('      → 라인: 640');
                          debugPrint('      → SizedBox width: ${renderBox.size.width}');
                          debugPrint('      → SizedBox height: ${renderBox.size.height}');
                        }
                      });
                      
                      // ============================================================
                      // 📱 헤더 생성 - 핸드폰에서 ventas 헤더가 안 보이는 문제 디버깅
                      // ============================================================
                      // ventas 보고서는 모든 unit에서 헤더를 표시해야 함 (더블 클릭 기능과 헤더 표시는 충돌하지 않음)
                      // clientes/fventas는 별도 헤더 행을 사용하지 않음
                      final isVentas = reportType == ReportType.ventas;
                      final isClientesOrFventas = reportType == ReportType.clientes || reportType == ReportType.fventas;
                      final shouldHideHeaderRow = isClientesOrFventas;
                      
                      // 핸드폰 화면 구성 정보 확인
                      final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
                      final isMobilePhone = layoutInfo.isMobilePhone;
                      final isMobilePhonePortrait = layoutInfo.isMobilePhonePortrait;
                      final isMobilePhoneLandscape = layoutInfo.isMobilePhoneLandscape;
                      
                      debugPrint('═══════════════════════════════════════════════════════');
                      debugPrint('📱 [Ventas 헤더 디버깅] 헤더 생성 시작');
                      debugPrint('   → reportType: $reportType');
                      debugPrint('   → unit: $unit');
                      debugPrint('   → isVentas: $isVentas');
                      debugPrint('   → isClientesOrFventas: $isClientesOrFventas');
                      debugPrint('   → shouldHideHeaderRow: $shouldHideHeaderRow');
                      debugPrint('   → isMobilePhone: $isMobilePhone');
                      debugPrint('   → isMobilePhonePortrait: $isMobilePhonePortrait');
                      debugPrint('   → isMobilePhoneLandscape: $isMobilePhoneLandscape');
                      debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
                      debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
                      debugPrint('   → keys.length: ${keys.length}');
                      debugPrint('   → columns.length: ${columns.length}');
                      debugPrint('   → horizontalScrollController: ${horizontalScrollController != null}');
                      
                      // Builder 내부에서 displayedList를 기반으로 실제 keys를 다시 계산 (데이터가 업데이트되었을 수 있음)
                      debugPrint('🔍 [buildTableFromList Builder] displayedList 상태 확인');
                      debugPrint('   → displayedList.length: ${displayedList.length}');
                      if (displayedList.isNotEmpty && displayedList.first is Map<String, dynamic>) {
                        final firstItemInBuilder = displayedList.first as Map<String, dynamic>;
                        debugPrint('   → displayedList 첫 번째 항목 keys: ${firstItemInBuilder.keys.toList()}');
                        debugPrint('   → displayedList 첫 번째 항목: $firstItemInBuilder');
                      }
                      final actualKeysFromData = ReportTableBuilder.getDisplayedColumns(
                        displayedList,
                        reportType,
                        unit: unit,
                      );
                      debugPrint('🔍 [buildTableFromList Builder] 실제 데이터 기반 keys 재계산');
                      debugPrint('   → 함수 시작 시 keys: $keys');
                      debugPrint('   → 실제 데이터 기반 keys: $actualKeysFromData');
                      debugPrint('   → keys가 일치하는가: ${keys.toString() == actualKeysFromData.toString()}');
                      debugPrint('   → unit 파라미터: $unit');
                      
                      // ventas day/month/year 유닛 + 대형 화면인 경우 칼럼 너비를 2배로 증가
                      // unit 파라미터가 day/month/year이면 무조건 적용 (가장 확실한 방법)
                      debugPrint('🔍 [buildTableFromList Builder] unit 파라미터 상세 확인');
                      debugPrint('   → unit 파라미터 (raw): $unit');
                      debugPrint('   → unit 파라미터 타입: ${unit.runtimeType}');
                      debugPrint('   → unit == "day": ${unit == "day"}');
                      debugPrint('   → unit == "month": ${unit == "month"}');
                      debugPrint('   → unit == "year": ${unit == "year"}');
                      debugPrint('   → unit == "vcode": ${unit == "vcode"}');
                      debugPrint('   → unit != null: ${unit != null}');
                      final isVentasDayMonthYearFromUnit = reportType == ReportType.ventas && 
                                                           unit != null && 
                                                           (unit == 'day' || unit == 'month' || unit == 'year');
                      debugPrint('   → isVentasDayMonthYearFromUnit 계산 결과: $isVentasDayMonthYearFromUnit');
                      debugPrint('   → 계산 과정: reportType == ReportType.ventas: ${reportType == ReportType.ventas}, unit != null: ${unit != null}, (unit == "day" || unit == "month" || unit == "year"): ${unit != null && (unit == "day" || unit == "month" || unit == "year")}');
                      // 실제 데이터 기반 keys를 사용하여 day/month/year 유닛인지 확인 (백업)
                      final hasDayMonthYearKeys = actualKeysFromData.contains('fecha') || 
                                                  actualKeysFromData.contains('month') || 
                                                  actualKeysFromData.contains('year') ||
                                                  actualKeysFromData.contains('eventcount') ||
                                                  actualKeysFromData.contains('eventCount') ||
                                                  actualKeysFromData.contains('tvents') ||
                                                  actualKeysFromData.contains('tVents') ||
                                                  actualKeysFromData.contains('tventas') ||
                                                  actualKeysFromData.contains('tVentas') ||
                                                  actualKeysFromData.contains('tcntropas') ||
                                                  actualKeysFromData.contains('tCntRopas');
                      final hasVcodeKeys = actualKeysFromData.contains('vcode') || 
                                         actualKeysFromData.contains('tpago') || 
                                         actualKeysFromData.contains('cntropas') ||
                                         actualKeysFromData.contains('d_num_caja') ||
                                         actualKeysFromData.contains('d_num_terminal') ||
                                         actualKeysFromData.contains('clientenombre');
                      // hasVcodeKeys가 true여도 실제 데이터에 vcode 필드가 없으면 day/month/year 유닛일 수 있음
                      // 따라서 vcode 필드 존재 여부를 직접 확인하는 것이 더 정확함
                      final actualHasVcodeField = actualKeysFromData.contains('vcode');
                      final isVentasDayMonthYearFromKeys = reportType == ReportType.ventas && 
                                                            hasDayMonthYearKeys && 
                                                            !actualHasVcodeField;
                      // 데이터 구조를 기반으로 day/month/year 유닛인지 확인 (백업)
                      final firstItemForCheck = displayedList.isNotEmpty && displayedList.first is Map<String, dynamic>
                          ? displayedList.first as Map<String, dynamic>
                          : <String, dynamic>{};
                      // vcode 필드가 없고, fecha/month/year 중 하나가 있으면 day/month/year 유닛
                      final hasVcodeFieldCheck = firstItemForCheck.containsKey('vcode');
                      final hasFechaFieldCheck = firstItemForCheck.containsKey('fecha');
                      final hasMonthFieldCheck = firstItemForCheck.containsKey('month');
                      final hasYearFieldCheck = firstItemForCheck.containsKey('year');
                      final hasDayMonthYearKeyCheck = hasFechaFieldCheck || hasMonthFieldCheck || hasYearFieldCheck;
                      // vcode 유닛 전용 필드들 (day/month/year 유닛에는 없음)
                      // 주의: tcntropas, tcredito, tbanco 등은 day/month/year 유닛에도 존재할 수 있으므로
                      // vcode 필드가 있는지 확인하는 것이 가장 확실한 방법입니다.
                      final hasVcodeOnlyFieldsCheck = firstItemForCheck.containsKey('tpago') || 
                                                     firstItemForCheck.containsKey('cntropas') ||
                                                     firstItemForCheck.containsKey('d_num_caja') ||
                                                     firstItemForCheck.containsKey('d_num_terminal') ||
                                                     firstItemForCheck.containsKey('clientenombre') ||
                                                     firstItemForCheck.containsKey('vendedor') ||
                                                     firstItemForCheck.containsKey('tipo') ||
                                                     firstItemForCheck.containsKey('dni') ||
                                                     firstItemForCheck.containsKey('hora') ||
                                                     firstItemForCheck.containsKey('resiva') ||
                                                     firstItemForCheck.containsKey('casoesp') ||
                                                     firstItemForCheck.containsKey('cretmp') ||
                                                     firstItemForCheck.containsKey('ntiqrepetir') ||
                                                     firstItemForCheck.containsKey('b_mercadopago');
                      // vcode 필드가 없고, day/month/year 키가 있으면 day/month/year 유닛
                      // hasVcodeOnlyFieldsCheck는 참고용으로만 사용 (vcode 필드가 없으면 우선순위가 높음)
                      final isVentasDayMonthYearFromData = reportType == ReportType.ventas && 
                                                            !hasVcodeFieldCheck && 
                                                            hasDayMonthYearKeyCheck;
                      // unit 파라미터가 day/month/year이면 우선 적용 (가장 확실)
                      // 하지만 unit 파라미터가 vcode여도 실제 데이터가 day/month/year 유닛이면 적용
                      // displayedList의 첫 번째 항목을 확인하여 실제 데이터 구조 기반으로 최종 판단
                      final finalIsVentasDayMonthYear = isVentasDayMonthYearFromUnit || 
                                                       isVentasDayMonthYearFromKeys || 
                                                       isVentasDayMonthYearFromData;
                      
                      debugPrint('🔍 [buildTableFromList Builder] 최종 판단 (line ~1270)');
                      debugPrint('   → isVentasDayMonthYearFromUnit: $isVentasDayMonthYearFromUnit');
                      debugPrint('   → isVentasDayMonthYearFromKeys: $isVentasDayMonthYearFromKeys');
                      debugPrint('   → isVentasDayMonthYearFromData: $isVentasDayMonthYearFromData');
                      debugPrint('   → finalIsVentasDayMonthYear: $finalIsVentasDayMonthYear');
                      
                      final hasValidWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0;
                      final isLargeScreen = constraints.maxWidth.isFinite && constraints.maxWidth >= 800;
                      final shouldDoubleColumnWidths = finalIsVentasDayMonthYear && isLargeScreen && hasValidWidth;
                      
                      debugPrint('   → shouldDoubleColumnWidths 계산 (line ~1278): $shouldDoubleColumnWidths');
                      debugPrint('      → finalIsVentasDayMonthYear: $finalIsVentasDayMonthYear');
                      debugPrint('      → isLargeScreen: $isLargeScreen');
                      debugPrint('      → hasValidWidth: $hasValidWidth');
                      
                      debugPrint('🔍 [buildTableFromList] 칼럼 너비 2배 증가 조건 확인');
                      debugPrint('   → reportType: $reportType');
                      debugPrint('   → unit: $unit');
                      debugPrint('   → 함수 시작 시 keys: $keys');
                      debugPrint('   → 실제 데이터 기반 keys: $actualKeysFromData');
                      debugPrint('   → isVentasDayMonthYearFromUnit: $isVentasDayMonthYearFromUnit');
                      debugPrint('   → isVentasDayMonthYearFromKeys: $isVentasDayMonthYearFromKeys');
                      debugPrint('   → hasDayMonthYearKeys (actualKeysFromData 기반): $hasDayMonthYearKeys');
                      debugPrint('   → hasVcodeKeys (actualKeysFromData 기반): $hasVcodeKeys');
                      debugPrint('   → isVentasDayMonthYearFromData: $isVentasDayMonthYearFromData');
                      debugPrint('   → hasVcodeFieldCheck: $hasVcodeFieldCheck');
                      debugPrint('   → hasFechaFieldCheck: $hasFechaFieldCheck');
                      debugPrint('   → hasMonthFieldCheck: $hasMonthFieldCheck');
                      debugPrint('   → hasYearFieldCheck: $hasYearFieldCheck');
                      debugPrint('   → hasDayMonthYearKeyCheck: $hasDayMonthYearKeyCheck');
                      debugPrint('   → hasVcodeOnlyFieldsCheck: $hasVcodeOnlyFieldsCheck');
                      debugPrint('   → firstItemForCheck keys: ${firstItemForCheck.keys.toList()}');
                      debugPrint('   → displayedList.length: ${displayedList.length}');
                      debugPrint('   → finalIsVentasDayMonthYear: $finalIsVentasDayMonthYear');
                      debugPrint('   → hasValidWidth: $hasValidWidth');
                      debugPrint('   → isLargeScreen: $isLargeScreen (constraints.maxWidth: ${constraints.maxWidth})');
                      debugPrint('   → shouldDoubleColumnWidths: $shouldDoubleColumnWidths');
                      debugPrint('   → columnWidths != null: ${columnWidths != null}');
                      
                      // columnWidths를 복사하여 수정 (원본은 유지)
                      var finalColumnWidths = columnWidths;
                      if (shouldDoubleColumnWidths) {
                        final doubledWidths = <String, double>{};
                        // actualKeysFromData를 사용하여 실제 데이터에 맞는 키들만 2배 증가
                        for (final key in actualKeysFromData) {
                          if (key == 'ProductName') {
                            doubledWidths[key] = columnWidths[key] ?? 450.0;
                          } else {
                            final currentWidth = columnWidths[key] ?? 150.0;
                            doubledWidths[key] = currentWidth * 2.0;
                          }
                        }
                        // 기존 columnWidths의 다른 키들도 유지 (actualKeysFromData에 없는 키들)
                        columnWidths.forEach((key, value) {
                          if (!doubledWidths.containsKey(key)) {
                            doubledWidths[key] = value;
                          }
                        });
                        finalColumnWidths = doubledWidths;
                        
                        debugPrint('✅✅✅ [buildTableFromList] 대형 화면 칼럼 너비 2배 증가 적용됨! (line ~1330)');
                        debugPrint('   → isVentasDayMonthYear: $finalIsVentasDayMonthYear');
                        debugPrint('   → isLargeScreen: $isLargeScreen');
                        debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
                        debugPrint('   → 함수 시작 시 keys 개수: ${keys.length}');
                        debugPrint('   → 실제 데이터 기반 actualKeysFromData 개수: ${actualKeysFromData.length}');
                        debugPrint('   → actualKeysFromData: $actualKeysFromData');
                        debugPrint('   → 2배 증가된 키들: ${doubledWidths.keys.toList()}');
                        debugPrint('   → 원본 칼럼 너비 샘플: ${columnWidths.entries.take(5).map((e) => '${e.key}=${e.value}').join(', ')}');
                        debugPrint('   → 2배 증가된 칼럼 너비 샘플: ${doubledWidths.entries.take(5).map((e) => '${e.key}=${e.value}').join(', ')}');
                      } else {
                        debugPrint('❌❌❌ [buildTableFromList] 칼럼 너비 2배 증가 적용 안 됨 (line ~1340)');
                        debugPrint('   → shouldDoubleColumnWidths: $shouldDoubleColumnWidths');
                        debugPrint('   → finalIsVentasDayMonthYear: $finalIsVentasDayMonthYear');
                        debugPrint('   → isLargeScreen: $isLargeScreen');
                        debugPrint('   → hasValidWidth: $hasValidWidth');
                        debugPrint('   → columnWidths != null: ${columnWidths != null}');
                      }
                      
                      final headerRow = shouldHideHeaderRow
                          ? null 
                          : buildHeaderRow(keys, columns, color, sortColumn, sortAscending, onSort, columnWidths: finalColumnWidths, reportType: reportType, unit: unit);
                      
                      // ventas 보고서 디버깅 (핸드폰에서 헤더가 안 보이는 문제 분석)
                      if (reportType == ReportType.ventas) {
                        debugPrint('═══════════════════════════════════════════════════════');
                        debugPrint('📱 [Ventas Report] 헤더 처리 디버깅');
                        debugPrint('   → keys.length: ${keys.length}');
                        debugPrint('   → keys: $keys');
                        debugPrint('   → displayedList.length: ${displayedList.length}');
                        debugPrint('   → unit: $unit');
                        debugPrint('   → headerRow: ${headerRow != null ? "생성됨" : "null"}');
                        if (isVentas) {
                          debugPrint('   → [Ventas $unit] headerRow=${headerRow != null ? "생성됨" : "null"} (모든 unit에서 헤더 표시)');
                        }
                        debugPrint('   → horizontalScrollController: ${horizontalScrollController != null}');
                        debugPrint('   → isMobilePhone: $isMobilePhone');
                        debugPrint('   → isMobilePhonePortrait: $isMobilePhonePortrait');
                        debugPrint('   → isMobilePhoneLandscape: $isMobilePhoneLandscape');
                        debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
                        debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
                        debugPrint('═══════════════════════════════════════════════════════');
                      }
                      
                      // fventas 디버깅
                      if (reportType == ReportType.fventas) {
                        debugPrint('═══════════════════════════════════════════════════════');
                        debugPrint('🔍 [FVentas Report] report_table_builder.dart에서 처리');
                        debugPrint('   → keys.length: ${keys.length}');
                        debugPrint('   → keys: $keys');
                        debugPrint('   → displayedList.length: ${displayedList.length}');
                        debugPrint('   → headerRow: ${headerRow != null ? "생성됨" : "null (fventas는 헤더 없음)"}');
                        debugPrint('   → horizontalScrollController: ${horizontalScrollController != null}');
                        debugPrint('═══════════════════════════════════════════════════════');
                      }
                      
                      debugPrint('   → [ReportTableBuilder:650] Column 생성 시작');
                      debugPrint('   → headerRow != null: ${headerRow != null}');
                      debugPrint('   → reportType: $reportType');
                      if (reportType == ReportType.ventas) {
                        debugPrint('   ⚠️ [Ventas] headerRow가 null이므로 헤더가 Column children에 포함되지 않음');
                        debugPrint('   ⚠️ [Ventas] 결과: 헤더가 전혀 표시되지 않음');
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 헤더 (수평 스크롤 동기화)
                          // ventas/clientes/fventas는 headerRow가 null이므로 헤더가 표시되지 않음
                          if (headerRow != null)
                            Builder(
                              builder: (context) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                                  if (renderBox != null) {
                                    debugPrint('═══════════════════════════════════════════════════════');
                                    debugPrint('📊 [헤더] 실제 렌더링 위치 측정');
                                    debugPrint('   → 헤더 전체 width: ${renderBox.size.width}');
                                    debugPrint('   → 헤더 전체 height: ${renderBox.size.height}');
                                    debugPrint('   → 헤더 localToGlobal(0,0): ${renderBox.localToGlobal(Offset.zero)}');
                                    
                                    // 구조 파악: 모든 자식 출력
                                    debugPrint('   → [헤더] 구조 파악 시작');
                                    void printStructure(RenderBox? box, int depth, String prefix) {
                                      if (box == null || depth > 8) return;
                                      final typeName = box.runtimeType.toString();
                                      debugPrint('   $prefix[depth=$depth] 타입=$typeName, width=${box.size.width}, height=${box.size.height}');
                                      
                                      int childIdx = 0;
                                      box.visitChildren((child) {
                                        if (child is RenderBox) {
                                          printStructure(child, depth + 1, '$prefix  ');
                                          childIdx++;
                                        }
                                      });
                                      if (childIdx == 0 && depth < 3) {
                                        debugPrint('   $prefix  → 자식 없음');
                                      }
                                    }
                                    printStructure(renderBox, 0, '');
                                    
                                    // Row 찾기 (재귀적으로 탐색, 더 깊이)
                                    RenderBox? rowBox;
                                    void findRow(RenderBox? box, int depth) {
                                      if (box == null || depth > 10) return;
                                      
                                      final typeName = box.runtimeType.toString();
                                      // RenderFlex 또는 실제 Row 위젯
                                      if (typeName.contains('RenderFlex')) {
                                        // Row는 가로로 배치되므로 width가 큰 경우
                                        if (box.size.width > 500) {
                                          rowBox = box;
                                          debugPrint('   → [헤더] Row 찾음 (depth=$depth): width=${box.size.width}, 타입=$typeName');
                                          return;
                                        }
                                      }
                                      
                                      box.visitChildren((child) {
                                        if (child is RenderBox && rowBox == null) {
                                          findRow(child, depth + 1);
                                        }
                                      });
                                    }
                                    
                                    findRow(renderBox, 0);
                                    
                                    if (rowBox != null) {
                                      debugPrint('   → [헤더] Row 찾음: width=${rowBox!.size.width}');
                                      final rowPosition = rowBox!.localToGlobal(Offset.zero);
                                      int columnIndex = 0;
                                      double cumulativeX = 0.0;
                                      
                                      // Row의 모든 자식 출력
                                      debugPrint('   → [헤더] Row 자식 탐색 시작');
                                      int childCount = 0;
                                      rowBox!.visitChildren((child) {
                                        if (child is RenderBox) {
                                          debugPrint('   → [헤더] Row 자식 #$childCount: 타입=${child.runtimeType}, width=${child.size.width}');
                                          childCount++;
                                        }
                                      });
                                      
                                      // SizedBox를 찾기 위해 더 깊이 탐색
                                      void findSizedBoxes(RenderBox? box, int depth) {
                                        if (box == null || depth > 5 || columnIndex >= keys.length) return;
                                        
                                        final typeName = box.runtimeType.toString();
                                        // RenderConstrainedBox (SizedBox) 또는 적절한 크기의 RenderFlex
                                        if (typeName.contains('RenderConstrainedBox') && box.size.width > 50 && box.size.width < 1000) {
                                          final childGlobalPosition = box.localToGlobal(Offset.zero);
                                          final childX = childGlobalPosition.dx - rowPosition.dx;
                                          debugPrint('   → [헤더] 칼럼 #$columnIndex: 실제 x=$childX, width=${box.size.width}, 예상 x=$cumulativeX, 차이=${childX - cumulativeX}, 타입=$typeName');
                                          cumulativeX += box.size.width;
                                          if (columnIndex < keys.length - 1) {
                                            cumulativeX += 8; // columnSpacing
                                          }
                                          columnIndex++;
                                          return;
                                        }
                                        
                                        box.visitChildren((grandChild) {
                                          if (grandChild is RenderBox && columnIndex < keys.length) {
                                            findSizedBoxes(grandChild, depth + 1);
                                          }
                                        });
                                      }
                                      
                                      rowBox!.visitChildren((child) {
                                        if (child is RenderBox && columnIndex < keys.length) {
                                          findSizedBoxes(child, 0);
                                        }
                                      });
                                      
                                      if (columnIndex == 0) {
                                        debugPrint('   ⚠️ [헤더] 칼럼을 찾을 수 없습니다');
                                      }
                                    } else {
                                      debugPrint('   ⚠️ [헤더] Row를 찾을 수 없습니다');
                                    }
                                  }
                                });
                                debugPrint('═══════════════════════════════════════════════════════');
                                debugPrint('🔍 [Ventas 헤더] SingleChildScrollView 생성');
                                debugPrint('   → reportType: $reportType');
                                debugPrint('   → unit: $unit');
                                debugPrint('   → horizontalScrollController: ${horizontalScrollController != null}');
                                if (horizontalScrollController != null) {
                                  debugPrint('   → horizontalScrollController.hasClients: ${horizontalScrollController.hasClients}');
                                  if (horizontalScrollController.hasClients) {
                                    try {
                                      debugPrint('   → horizontalScrollController.positions.length: ${horizontalScrollController.positions.length}');
                                      if (horizontalScrollController.positions.length == 1) {
                                        debugPrint('   → horizontalScrollController.position.pixels: ${horizontalScrollController.position.pixels}');
                                        debugPrint('   → horizontalScrollController.position.maxScrollExtent: ${horizontalScrollController.position.maxScrollExtent}');
                                      } else {
                                        debugPrint('   ⚠️ ScrollController가 ${horizontalScrollController.positions.length}개의 스크롤 뷰에 연결됨');
                                      }
                                    } catch (e) {
                                      debugPrint('   ⚠️ horizontalScrollController.position 접근 오류: $e');
                                    }
                                  }
                                }
                                debugPrint('═══════════════════════════════════════════════════════');
                                
                                if (horizontalScrollController != null) {
                                  // 헤더와 테이블이 같은 스크롤 컨트롤러를 공유하도록 설정
                                  // NeverScrollableScrollPhysics()는 사용자 제스처를 막지만, 프로그래밍 방식 스크롤은 허용
                                  // ScrollController가 여러 스크롤 뷰에 연결되는 것을 방지하기 위해
                                  // 헤더는 별도의 ScrollController를 사용하지 않고 테이블의 스크롤을 따라가도록 함
                                  return NotificationListener<ScrollNotification>(
                                    onNotification: (notification) {
                                      // 테이블의 스크롤 이벤트를 감지하여 헤더를 동기화
                                      // 하지만 헤더는 NeverScrollableScrollPhysics()로 사용자 제스처를 막으므로
                                      // 여기서는 테이블의 스크롤을 따라가기만 함
                                      return false;
                                    },
                                    child: SingleChildScrollView(
                                      controller: horizontalScrollController,
                                      scrollDirection: Axis.horizontal,
                                      physics: const NeverScrollableScrollPhysics(), // 사용자 제스처는 막지만, 프로그래밍 방식 스크롤은 허용
                                      child: headerRow,
                                    ),
                                  );
                                } else {
                                  return headerRow;
                                }
                              },
                            ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, innerConstraints) {
                                debugPrint('═══════════════════════════════════════════════════════');
                                debugPrint('📊 [ReportTableBuilder:680] buildTableFromList 내부 LayoutBuilder 시작');
                                debugPrint('   → 파일: report_table_builder.dart');
                                debugPrint('   → 라인: 680');
                                debugPrint('   → reportType: $reportType');
                                debugPrint('   → innerConstraints.maxWidth: ${innerConstraints.maxWidth}');
                                debugPrint('   → innerConstraints.maxHeight: ${innerConstraints.maxHeight}');
                                debugPrint('   → innerConstraints.minWidth: ${innerConstraints.minWidth}');
                                debugPrint('   → innerConstraints.minHeight: ${innerConstraints.minHeight}');
                                
                                // items 및 ingresos 보고서는 수직 스크롤 추가
                                debugPrint('   → [ReportTableBuilder:690] Items/Ingresos: SingleChildScrollView로 수직 스크롤 추가');
                                debugPrint('   → [ReportTableBuilder:691] _buildTableContent 호출 시작');
                                final tableContent = _buildTableContent(
                                  constraints: innerConstraints,
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
                                  columnWidths: finalColumnWidths, // 2배 증가된 칼럼 너비 사용
                                  sortColumn: sortColumn,
                                  sortAscending: sortAscending,
                                );
                                
                                debugPrint('   → [ReportTableBuilder:705] _buildTableContent 호출 완료, Scrollbar + SingleChildScrollView로 감싸기');
                                return Scrollbar(
                                  controller: scrollController,
                                  thumbVisibility: true,
                                  child: NotificationListener<ScrollNotification>(
                                    onNotification: (notification) {
                                      // 디버깅: items/ingresos 스크롤 이벤트 감지
                                      debugPrint('🔍 [${reportType.name}] Items/Ingresos NotificationListener 스크롤 이벤트');
                                      debugPrint('   → notification 타입: ${notification.runtimeType}');
                                      debugPrint('   → notification.depth: ${notification.depth}');
                                      
                                      // 테이블의 수평 스크롤 이벤트를 헤더와 푸터에 전달
                                      if (notification is ScrollUpdateNotification) {
                                        debugPrint('   → ScrollUpdateNotification 감지');
                                        debugPrint('   → metrics.axis: ${notification.metrics.axis}');
                                        debugPrint('   → metrics.pixels: ${notification.metrics.pixels}');
                                        debugPrint('   → metrics.maxScrollExtent: ${notification.metrics.maxScrollExtent}');
                                        debugPrint('   → horizontalScrollController: ${horizontalScrollController != null}');
                                        
                                        if (notification.metrics.axis == Axis.horizontal) {
                                          debugPrint('   ✅ 수평 스크롤 이벤트 확인');
                                          debugPrint('   → horizontalScrollController.hasClients: ${horizontalScrollController?.hasClients ?? false}');
                                          
                                          if (horizontalScrollController != null && horizontalScrollController.hasClients) {
                                            try {
                                              if (horizontalScrollController.positions.length == 1) {
                                            final tableScrollPosition = notification.metrics.pixels;
                                            final headerScrollPosition = horizontalScrollController.position.pixels;
                                            final difference = (tableScrollPosition - headerScrollPosition).abs();
                                            
                                            debugPrint('   → 테이블 스크롤 위치: $tableScrollPosition');
                                            debugPrint('   → 헤더/푸터 스크롤 위치: $headerScrollPosition');
                                            debugPrint('   → 위치 차이: $difference');
                                            
                                            if (difference > 0.1) {
                                              debugPrint('   ✅ 위치 차이 > 0.1, jumpTo 호출: $tableScrollPosition');
                                              horizontalScrollController.jumpTo(tableScrollPosition);
                                            } else {
                                              debugPrint('   ⚠️ 위치 차이 <= 0.1, 동기화 스킵');
                                                }
                                              }
                                            } catch (e) {
                                              debugPrint('   ⚠️ 스크롤 동기화 오류: $e');
                                            }
                                          } else {
                                            debugPrint('   ⚠️ horizontalScrollController가 없거나 클라이언트가 없음');
                                          }
                                        } else {
                                          debugPrint('   ⚠️ 수직 스크롤 이벤트 (무시)');
                                        }
                                      } else if (notification is ScrollStartNotification) {
                                        debugPrint('   → ScrollStartNotification 감지');
                                        debugPrint('   → metrics.axis: ${notification.metrics.axis}');
                                      } else if (notification is ScrollEndNotification) {
                                        debugPrint('   → ScrollEndNotification 감지');
                                        debugPrint('   → metrics.axis: ${notification.metrics.axis}');
                                      }
                                      return false;
                                    },
                                    child: SingleChildScrollView(
                                      controller: scrollController,
                                      scrollDirection: Axis.vertical,
                                      child: Builder(
                                        builder: (context) {
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                                            if (renderBox != null) {
                                              debugPrint('═══════════════════════════════════════════════════════');
                                              debugPrint('📊 [ReportTableBuilder:708] buildTableFromList 실제 렌더링 크기 (PostFrameCallback)');
                                              debugPrint('   → 파일: report_table_builder.dart');
                                              debugPrint('   → 라인: 708');
                                              debugPrint('   → width: ${renderBox.size.width}');
                                              debugPrint('   → height: ${renderBox.size.height}');
                                              debugPrint('   → 예상 width: ${innerConstraints.maxWidth}');
                                              debugPrint('   → 차이: ${renderBox.size.width - innerConstraints.maxWidth}');
                                              
                                              // 자식 위젯 크기 확인
                                              int childIndex = 0;
                                              renderBox.visitChildren((child) {
                                                if (child is RenderBox) {
                                                  debugPrint('   → [ReportTableBuilder:720] 자식 RenderBox #$childIndex');
                                                  debugPrint('      → width: ${child.size.width}');
                                                  debugPrint('      → height: ${child.size.height}');
                                                  childIndex++;
                                                }
                                              });
                                              
                                              if (childIndex == 0) {
                                                debugPrint('   ⚠️ [ReportTableBuilder:720] 자식 RenderBox가 없습니다!');
                                              }
                                            } else {
                                              debugPrint('   ⚠️ [ReportTableBuilder:708] RenderBox를 찾을 수 없습니다!');
                                            }
                                          });
                                          debugPrint('   → [ReportTableBuilder:730] tableContent 반환');
                                          return tableContent;
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Footer (화면 하단에 고정, 수평 스크롤 동기화)
                          Builder(
                            builder: (context) {
                              // 디버깅: items/ingresos 푸터 생성 시점 로깅
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                debugPrint('🔍 [${reportType.name}] Items/Ingresos 푸터 생성 완료');
                                debugPrint('   → horizontalScrollController: ${horizontalScrollController != null}');
                                if (horizontalScrollController != null) {
                                  debugPrint('   → horizontalScrollController.hasClients: ${horizontalScrollController.hasClients}');
                                  if (horizontalScrollController.hasClients) {
                                    try {
                                      // 여러 스크롤 뷰에 연결된 경우를 처리
                                      if (horizontalScrollController.positions.length == 1) {
                                    debugPrint('   → horizontalScrollController.position.pixels: ${horizontalScrollController.position.pixels}');
                                    debugPrint('   → horizontalScrollController.position.maxScrollExtent: ${horizontalScrollController.position.maxScrollExtent}');
                                      } else {
                                        debugPrint('   ⚠️ horizontalScrollController가 ${horizontalScrollController.positions.length}개의 스크롤 뷰에 연결됨');
                                      }
                                    } catch (e) {
                                      debugPrint('   ⚠️ horizontalScrollController.position 접근 오류: $e');
                                    }
                                  }
                                }
                              });
                              
                              debugPrint('═══════════════════════════════════════════════════════');
                              debugPrint('📊 [buildTableFromList] 푸터 생성 시작');
                              debugPrint('   → keys: $keys');
                              debugPrint('   → columnWidths 전달: ${columnWidths != null}');
                              debugPrint('   → horizontalScrollController: ${horizontalScrollController != null}');
                              
                              // fventas/ventas/clientes/alertas의 경우 테이블 너비 계산
                              double? footerWidth;
                              if (reportType == ReportType.fventas || reportType == ReportType.ventas || reportType == ReportType.clientes || reportType == ReportType.alertas) {
                                // 푸터 전용 기본 칼럼 너비 (ReportTableColumnManager로 추출됨)
                                final defaultColumnWidths = ReportTableColumnManager.getFooterColumnWidths(unit: unit);
                                final finalColumnWidths = columnWidths ?? defaultColumnWidths;
                                double calculatedWidth = 0.0;
                                for (int i = 0; i < keys.length; i++) {
                                  final key = keys[i];
                                  final columnWidth = finalColumnWidths[key] ?? 150.0;
                                  calculatedWidth += columnWidth;
                                  if (i < keys.length - 1) {
                                    // alertas 보고서는 columnSpacing을 1로 설정
                                    final actualColumnSpacing = (reportType == ReportType.alertas) ? 1 : 8;
                                    calculatedWidth += actualColumnSpacing;
                                  }
                                }
                                footerWidth = calculatedWidth;
                                debugPrint('   → [${reportType.name}] 계산된 footerWidth: $footerWidth');
                              }
                              
                              final footer = buildFixedTotalRow(
                                keys, 
                                displayedList, 
                                color, 
                                columnWidths: finalColumnWidths, // 2배 증가된 칼럼 너비 사용
                                dataList: dataList,
                                fventasSummary: fventasSummary,
                                reportType: reportType,
                                explicitWidth: footerWidth, // fventas/ventas/clientes/alertas의 경우 명시적 너비 전달
                              );
                              debugPrint('   → 푸터 생성 완료');
                              
                              // horizontalScrollController가 있으면 SingleChildScrollView로 감싸기
                              if (horizontalScrollController != null) {
                                return SingleChildScrollView(
                                  controller: horizontalScrollController,
                                  scrollDirection: Axis.horizontal,
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: footer,
                                );
                              }
                              
                              return footer;
                              
                              // 푸터의 실제 렌더링 위치 측정
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                                if (renderBox != null) {
                                  debugPrint('═══════════════════════════════════════════════════════');
                                  debugPrint('📊 [푸터] 실제 렌더링 위치 측정');
                                  debugPrint('   → 푸터 전체 width: ${renderBox.size.width}');
                                  debugPrint('   → 푸터 전체 height: ${renderBox.size.height}');
                                  debugPrint('   → 푸터 localToGlobal(0,0): ${renderBox.localToGlobal(Offset.zero)}');
                                  
                                  // 구조 파악: 모든 자식 출력
                                  debugPrint('   → [푸터] 구조 파악 시작');
                                  void printStructure(RenderBox? box, int depth, String prefix) {
                                    if (box == null || depth > 8) return;
                                    final typeName = box.runtimeType.toString();
                                    debugPrint('   $prefix[depth=$depth] 타입=$typeName, width=${box.size.width}, height=${box.size.height}');
                                    
                                    int childIdx = 0;
                                    box.visitChildren((child) {
                                      if (child is RenderBox) {
                                        printStructure(child, depth + 1, '$prefix  ');
                                        childIdx++;
                                      }
                                    });
                                    if (childIdx == 0 && depth < 3) {
                                      debugPrint('   $prefix  → 자식 없음');
                                    }
                                  }
                                  printStructure(renderBox, 0, '');
                                  
                                  // SingleChildScrollView 내부의 Row 찾기 (재귀적으로 탐색, 더 깊이)
                                  RenderBox? rowBox;
                                  void findRow(RenderBox? box, int depth) {
                                    if (box == null || depth > 10) return;
                                    
                                    final typeName = box.runtimeType.toString();
                                    // RenderFlex 또는 실제 Row 위젯
                                    if (typeName.contains('RenderFlex')) {
                                      // Row는 가로로 배치되므로 width가 큰 경우
                                      if (box.size.width > 500) {
                                        rowBox = box;
                                        debugPrint('   → [푸터] Row 찾음 (depth=$depth): width=${box.size.width}, 타입=$typeName');
                                        return;
                                      }
                                    }
                                    
                                    box.visitChildren((child) {
                                      if (child is RenderBox && rowBox == null) {
                                        findRow(child, depth + 1);
                                      }
                                    });
                                  }
                                  
                                  findRow(renderBox, 0);
                                  
                                  if (rowBox != null) {
                                    debugPrint('   → [푸터] Row 찾음: width=${rowBox!.size.width}');
                                    final rowPosition = rowBox!.localToGlobal(Offset.zero);
                                    int columnIndex = 0;
                                    double cumulativeX = 0.0;
                                    
                                    // Row의 모든 자식 출력
                                    debugPrint('   → [푸터] Row 자식 탐색 시작');
                                    int childCount = 0;
                                    rowBox!.visitChildren((child) {
                                      if (child is RenderBox) {
                                        debugPrint('   → [푸터] Row 자식 #$childCount: 타입=${child.runtimeType}, width=${child.size.width}');
                                        childCount++;
                                      }
                                    });
                                    
                                    // SizedBox를 찾기 위해 더 깊이 탐색
                                    void findSizedBoxes(RenderBox? box, int depth) {
                                      if (box == null || depth > 5 || columnIndex >= keys.length) return;
                                      
                                      final typeName = box.runtimeType.toString();
                                      // RenderConstrainedBox (SizedBox) 또는 적절한 크기의 RenderFlex
                                      if (typeName.contains('RenderConstrainedBox') && box.size.width > 50 && box.size.width < 1000) {
                                        final childGlobalPosition = box.localToGlobal(Offset.zero);
                                        final childX = childGlobalPosition.dx - rowPosition.dx;
                                        debugPrint('   → [푸터] 칼럼 #$columnIndex: 실제 x=$childX, width=${box.size.width}, 예상 x=$cumulativeX, 차이=${childX - cumulativeX}, 타입=$typeName');
                                        cumulativeX += box.size.width;
                                        if (columnIndex < keys.length - 1) {
                                          cumulativeX += 8; // columnSpacing
                                        }
                                        columnIndex++;
                                        return;
                                      }
                                      
                                      box.visitChildren((grandChild) {
                                        if (grandChild is RenderBox && columnIndex < keys.length) {
                                          findSizedBoxes(grandChild, depth + 1);
                                        }
                                      });
                                    }
                                    
                                    rowBox!.visitChildren((child) {
                                      if (child is RenderBox && columnIndex < keys.length) {
                                        findSizedBoxes(child, 0);
                                      }
                                    });
                                    
                                    if (columnIndex == 0) {
                                      debugPrint('   ⚠️ [푸터] 칼럼을 찾을 수 없습니다');
                                    }
                                  } else {
                                    debugPrint('   ⚠️ [푸터] Row를 찾을 수 없습니다');
                                  }
                                }
                              });
                              
                              return footer;
                            },
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
    );
  }

  /// 테이블 콘텐츠 빌드 (수평 스크롤 여부에 따라 분기)
  static Widget _buildTableContent({
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
    return ReportTableRenderer.buildTableContent(
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
  }

  /// 수평 스크롤이 있는 테이블 빌드 (ReportTableRenderer로 위임)
  static Widget _buildTableWithHorizontalScroll({
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
    return ReportTableRenderer.buildTableWithHorizontalScroll(
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
  }

  /// 수평 스크롤이 없는 테이블 빌드 (ReportTableRenderer로 위임)
  static Widget _buildTableWithoutHorizontalScroll({
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
    return ReportTableRenderer.buildTableWithoutHorizontalScroll(
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
  
  /// DataTable 위젯 빌드 (ReportTableRenderer로 위임)
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
    return ReportTableRenderer.buildDataTable(
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
      isLargeScreen: isLargeScreen,
      useMeasuredWidths: useMeasuredWidths,
      hideHeadingRow: hideHeadingRow,
    );
  }

  // ─── Forwarding wrappers → ReportTableHeaderFooter ─────────────────────────

  /// Forwarding alias — see [ReportTableHeaderFooter.buildFixedTotalRow].
  static Widget buildFixedTotalRow(List<String> keys, List<dynamic> displayedList,
          Color reportColor,
          {Map<String, double>? columnWidths,
          List<dynamic>? dataList,
          ReportType? reportType,
          double? explicitWidth,
          String? unit,
          FventasSummary? fventasSummary}) =>
      ReportTableHeaderFooter.buildFixedTotalRow(keys, displayedList, reportColor,
          columnWidths: columnWidths,
          dataList: dataList,
          reportType: reportType,
          explicitWidth: explicitWidth,
          unit: unit,
          fventasSummary: fventasSummary);

  /// Forwarding alias — see [ReportTableHeaderFooter.buildHeaderRow].
  static Widget buildHeaderRow(
    List<String> keys,
    List<DataColumn> columns,
    Color reportColor,
    String? sortColumn,
    bool sortAscending,
    Function(int columnIndex, bool ascending)? onSort, {
    Map<String, double>? columnWidths,
    ReportType? reportType,
    double? explicitWidth,
    String? unit,
    bool useMeasuredWidths = false,
    bool isLargeScreen = false,
    void Function(String columnKey, double newWidth)? onColumnResize,
  }) =>
      ReportTableHeaderFooter.buildHeaderRow(
        keys, columns, reportColor, sortColumn, sortAscending, onSort,
        columnWidths: columnWidths,
        reportType: reportType,
        explicitWidth: explicitWidth,
        unit: unit,
        useMeasuredWidths: useMeasuredWidths,
        isLargeScreen: isLargeScreen,
        onColumnResize: onColumnResize,
      );



  static bool isTableData(Map<String, dynamic> data) {
    return data.values.every((value) => value is List);
  }

  static Widget buildTable(
    Map<String, dynamic> data,
    ReportType reportType,
  ) {
    final columns = data.keys.map((key) {
      return DataColumn(
        label: Text(
          key.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }).toList();

    final firstKey = data.keys.first;
    final rowCount = (data[firstKey] as List).length;
    final reportColor = ReportUtils.getReportColor(reportType);

    final rows = List.generate(rowCount, (index) {
      return DataRow(
        cells: data.keys.map((key) {
          final value = data[key];
          if (value is List && index < value.length) {
            final cellValue = value[index];
            final formattedValue = ReportUtils.formatValue(cellValue);
            final isNumeric = ReportUtils.isNumeric(cellValue);
            return DataCell(
              Text(
                formattedValue,
                textAlign: isNumeric ? TextAlign.right : TextAlign.left,
              ),
            );
          }
          return const DataCell(Text(''));
        }).toList(),
      );
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        horizontalMargin: 0, // 헤더 Row와 정확히 일치시키기 위해 0으로 설정 (기본값 24px)
        columnSpacing: 8,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        headingRowColor: WidgetStateProperty.all(
          reportColor.withOpacity(0.1),
        ),
        columns: columns,
        rows: rows,
      ),
    );
  }
}
