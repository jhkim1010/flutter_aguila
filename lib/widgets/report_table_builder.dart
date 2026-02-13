import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'report_utils.dart';
import '../utils/mobile_layout_helper.dart';

class ReportTableBuilder {
  // 디버깅용 카운터
  static int _debugRowCount = 0;
  static int _debugCellCount = 0;
  
  
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

    final firstItem = displayedList.first as Map<String, dynamic>;
    
    // Ventas report의 경우 특정 컬럼만 특정 순서로 표시
    // Items 및 Ingresos report의 경우 start_date, end_date, sucursal 제외
    List<String> keys;
    if (reportType == ReportType.ventas) {
      // vcode unit용 컬럼 목록 (응답 순서대로)
      final vcodeColumns = <String>[
        'vcode',
        'tpago',
        'cntropas',
        'clientenombre',
        'tefectivo',
        'tcredito',
        'tbanco',
        'treservado',
        'tfavor',
        'vendedor',
        'tipo',
        'dni',
        'hora',
        'fecha',
        'resiva',
        'casoesp',
        'nencargado',
        'cretmp',
        'sucursal',
        'ntiqrepetir',
        'b_mercadopago',
        'd_num_caja',
        'd_num_terminal',
        'id',
      ];
      
      // unit 파라미터가 있으면 직접 사용, 없으면 데이터 구조로 판단
      final isDayMonthYearUnit = unit != null && unit != 'vcode';
      final isDayUnit = unit == 'day';
      final isMonthUnit = unit == 'month';
      final isYearUnit = unit == 'year';
      
      debugPrint('🔍 [buildTableFromList] unit 파라미터 확인');
      debugPrint('   → unit: $unit');
      debugPrint('   → isDayMonthYearUnit: $isDayMonthYearUnit');
      debugPrint('   → isDayUnit: $isDayUnit');
      debugPrint('   → isMonthUnit: $isMonthUnit');
      debugPrint('   → isYearUnit: $isYearUnit');
      
      // 첫 번째 항목으로 데이터 구조 확인
      final firstItem = displayedList.isNotEmpty && displayedList.first is Map<String, dynamic>
          ? displayedList.first as Map<String, dynamic>
          : <String, dynamic>{};
      
      debugPrint('   → firstItem keys: ${firstItem.keys.toList()}');
      
      // unit 파라미터가 없을 때만 데이터 구조로 판단
      bool finalIsDayMonthYearUnit = isDayMonthYearUnit;
      if (unit == null) {
        // vcode 필드가 없고, fecha/month/year 중 하나가 있으면 day/month/year 유닛
        final hasVcodeFieldParam = firstItem.containsKey('vcode');
        final hasFechaFieldParam = firstItem.containsKey('fecha');
        final hasMonthFieldParam = firstItem.containsKey('month');
        final hasYearFieldParam = firstItem.containsKey('year');
        final hasDayMonthYearKeyParam = hasFechaFieldParam || hasMonthFieldParam || hasYearFieldParam;
        // vcode 유닛 전용 필드들 (day/month/year 유닛에는 없음)
        final hasVcodeOnlyFieldsParam = firstItem.containsKey('tpago') || 
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
        
        // vcode 필드가 없고, day/month/year 키가 있고, vcode 전용 필드가 없으면 day/month/year 유닛
        finalIsDayMonthYearUnit = !hasVcodeFieldParam && hasDayMonthYearKeyParam && !hasVcodeOnlyFieldsParam;
      }
      
      // 모든 행에서 공통으로 존재하는 컬럼 확인
      final commonKeys = <String>{};
      final allKeys = <String>{}; // 모든 행에서 나타나는 키 (하나라도 있으면 포함)
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
      
      if (finalIsDayMonthYearUnit) {
        // day/month/year unit용 컬럼 목록 (실제 응답 구조에 맞게)
        // day unit: fecha, eventCount, tVents, tCntRopas, tefectivo, tcredito, tbanco, treservado, tfavor, sucursal
        // month unit: month, eventCount, tVents, tCntRopas, tefectivo, tcredito, tbanco, treservado, tfavor, nencargado, sucursal
        // year unit: year, eventCount, tVentas, tCntRopas, tefectivo, tcredito, tbanco, treservado, tfavor, nencargado, sucursal
        
        // month unit일 때는 month 필드를 첫 번째로 배치
        final actualMonthKey = allKeys.firstWhere(
          (k) => k.toLowerCase() == 'month',
          orElse: () => '',
        );
        final actualEventCountKeyForMonth = allKeys.firstWhere(
          (k) => k.toLowerCase() == 'eventcount',
          orElse: () => '',
        );
        
        if (isMonthUnit && actualMonthKey.isNotEmpty) {
          keys = [actualMonthKey];
          
          // eventCount를 두 번째 컬럼으로 명시적으로 추가 (allKeys에 있으면 무조건 포함)
          if (actualEventCountKeyForMonth.isNotEmpty) {
            keys.add(actualEventCountKeyForMonth);
          }
          
          // 나머지 필수 필드들 (순서 보장)
          final requiredMonthFields = ['tVents', 'tVentas', 'tCntRopas'];
          for (var field in requiredMonthFields) {
            if (!keys.contains(field) && (commonKeys.contains(field) || firstItem.containsKey(field))) {
              keys.add(field);
            }
          }
          
          // 나머지 컬럼 추가 (순서 보장)
          final otherColumns = <String>[
            'tefectivo',    // 현금
            'tcredito',     // 신용카드
            'tbanco',       // 은행
            'treservado',   // 예약
            'tfavor',       // 호의
            'nencargado',   // 담당자 (month/year unit에만 있을 수 있음)
            'sucursal',     // 지점
            'fecha',        // day unit용 (month unit에서는 사용 안 함)
          ];
          // 나머지 필드는 commonKeys에 있는 것만 순서대로 추가
          for (var column in otherColumns) {
            if (commonKeys.contains(column) && !keys.contains(column)) {
              keys.add(column);
            }
          }
        } else {
          // day/year unit 또는 month 필드가 없을 때
          final dayMonthYearColumns = <String>[
            'fecha',
            'month',        // month unit용
            'year',         // year unit용
            'eventCount',
            'tVents',       // day unit의 총 판매액
            'tVentas',      // month/year unit의 총 판매액 (있을 경우)
            'tCntRopas',    // 총 의류 개수
            'tefectivo',    // 현금
            'tcredito',     // 신용카드
            'tbanco',       // 은행
            'treservado',   // 예약
            'tfavor',       // 호의
            'nencargado',   // 담당자 (month/year unit에만 있을 수 있음)
            'sucursal',     // 지점
          ];
          
          // day/month/year 컬럼 목록에서 실제 데이터에 있는 것만 선택
          // 단, day/month unit의 필수 필드는 allKeys에 하나라도 있으면 무조건 포함 (대소문자 구분 없이)
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
            if (actualEventCountKey.isNotEmpty) {
              requiredFields.add(actualEventCountKey);
            }
            if (actualTVentsKey.isNotEmpty) {
              requiredFields.add(actualTVentsKey);
            }
            if (actualTVentasKey.isNotEmpty) {
              requiredFields.add(actualTVentasKey);
            }
            if (actualTCntRopasKey.isNotEmpty) {
              requiredFields.add(actualTCntRopasKey);
            }
          }
          
          // commonKeys에 있는 필드들 추가 (필수 필드는 allKeys에 있으면 포함)
          // 대소문자 구분 없이 매칭
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
          
          // day unit일 때는 fecha를 첫 번째로, eventCount를 두 번째로 배치
          if (isDayUnit) {
            // fecha를 첫 번째로 이동
            final actualFechaKey = allKeys.firstWhere(
              (k) => k.toLowerCase() == 'fecha',
              orElse: () => 'fecha',
            );
            if (keys.contains(actualFechaKey)) {
              keys.remove(actualFechaKey);
              keys.insert(0, actualFechaKey);
            }
            // eventCount를 두 번째 위치에 명시적으로 배치
            if (actualEventCountKey.isNotEmpty) {
              if (keys.contains(actualEventCountKey)) {
                keys.remove(actualEventCountKey);
              }
              keys.insert(1, actualEventCountKey);
            }
          }
          // month unit일 때는 month를 첫 번째로 이동하고, eventCount를 두 번째로 배치
          else if (isMonthUnit) {
            final actualMonthKey = allKeys.firstWhere(
              (k) => k.toLowerCase() == 'month',
              orElse: () => 'month',
            );
            final actualEventCountKey = allKeys.firstWhere(
              (k) => k.toLowerCase() == 'eventcount',
              orElse: () => '',
            );
            
            if (keys.contains(actualMonthKey)) {
              keys.remove(actualMonthKey);
              keys.insert(0, actualMonthKey);
            }
            // eventCount를 두 번째 위치에 명시적으로 배치
            if (actualEventCountKey.isNotEmpty) {
              if (keys.contains(actualEventCountKey)) {
                keys.remove(actualEventCountKey);
              }
              keys.insert(1, actualEventCountKey);
            }
          }
        }
        
        // day unit일 때는 nencargado 제외 (day unit 응답에는 없음)
        if (isDayUnit) {
          keys.removeWhere((key) => key == 'nencargado');
        }
        
        // vcode unit 전용 필드가 섞여 있으면 제거 (반드시 제거)
        final vcodeOnlyFields = ['vcode', 'tpago', 'cntropas', 'd_num_caja', 'd_num_terminal', 
                                 'id', 'hora', 'clientenombre', 'vendedor', 'tipo', 'dni', 
                                 'resiva', 'casoesp', 'cretmp', 'ntiqrepetir', 'b_mercadopago'];
        keys.removeWhere((key) => vcodeOnlyFields.contains(key));
        
        print('🔍 Ventas report - unit: $unit, isDayMonthYearUnit: $finalIsDayMonthYearUnit, isDayUnit: $isDayUnit, isMonthUnit: $isMonthUnit');
        print('🔍 First item: $firstItem');
        print('🔍 First item keys: ${firstItem.keys.toList()}');
        print('🔍 All keys in data: $allKeys');
        print('🔍 Common keys in data: $commonKeys');
        print('🔍 Selected columns: $keys');
        if (unit == 'year' && firstItem.containsKey('year')) {
          print('🔵🔵🔵 year unit 확인 - year 필드 값: ${firstItem['year']}, 타입: ${firstItem['year'].runtimeType}');
        }
        final eventCountKey = allKeys.firstWhere(
          (k) => k.toLowerCase() == 'eventcount',
          orElse: () => '',
        );
        print('🔍 eventCount key (case-insensitive): "$eventCountKey", in allKeys: ${eventCountKey.isNotEmpty}, in commonKeys: ${commonKeys.any((k) => k.toLowerCase() == 'eventcount')}, in firstItem: ${firstItem.keys.any((k) => k.toLowerCase() == 'eventcount')}, value: ${eventCountKey.isNotEmpty ? firstItem[eventCountKey] : 'N/A'}');
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
        print('📊 Ventas vcode columns 순서: $keys');
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
    } else if (reportType == ReportType.alertas) {
      // Alertas 보고서: alerta 컬럼 제외
      keys = firstItem.keys
          .where((key) => key != 'alerta')
          .toList();
    } else {
      keys = firstItem.keys.toList();
    }
    // 컬럼별 기본 너비 설정 (헤더와 일치하도록)
    // 넓은 화면에서 모든 칼럼이 보이도록 크기 조정
    final columnWidths = <String, double>{
      // Items 보고서
      'codigo1': 200,  // codigo1 칼럼 너비 증가 (120 -> 200)
      'desc1': 200,
      'ProductName': 400,  // ProductName 칼럼 너비 증가 (250 -> 400)
      'totalCantidad': 120,  // totalCantidad 칼럼 너비 추가
      'CategoryCode': 100,  // CategoryCode 칼럼 너비 추가
      'CompanyCode': 100,  // CompanyCode 칼럼 너비 추가
      'tprendas': 100,
      'timporte': 120,
      // Ingresos 보고서
      'codigo': 120,
      'descripcion': 200,
      'tevent': 100,
      'tcant': 120,
      'tIngreso': 120,
      'tingreso': 120,
      'cntEvent': 100,
      'cntevent': 100,
      // Alertas 보고서 (모든 칼럼을 절반으로 줄이고, evento는 2배로 늘림)
      'fecha': 60,   // 120 -> 60 (절반)
      'hora': 50,    // 100 -> 50 (절반)
      'evento': 1000, // 500 -> 1000 (2배)
      'progname': 75, // 150 -> 75 (절반)
      'alerta': 40,   // 80 -> 40 (절반)
      'sucursal': 50, // 100 -> 50 (절반)
      // Ventas 보고서 - vcode 유닛용 칼럼 너비 (30% 감소: 1.7배 -> 1.19배, 약 19% 증가)
      'vcode': 119,      // 170 * 0.7 (30% 감소)
      'tpago': 143,      // 204 * 0.7 (30% 감소)
      'cntropas': 119,   // 170 * 0.7 (30% 감소)
      'clientenombre': 238,  // 340 * 0.7 (30% 감소)
      'tefectivo': 143,   // 204 * 0.7 (30% 감소)
      'tcredito': 143,    // 204 * 0.7 (30% 감소)
      'tbanco': 143,      // 204 * 0.7 (30% 감소)
      'treservado': 143,  // 204 * 0.7 (30% 감소)
      'tfavor': 143,      // 204 * 0.7 (30% 감소)
      'vendedor': 179,    // 255 * 0.7 (30% 감소)
      'tipo': 179,        // 255 * 0.7 (30% 감소)
      'dni': 179,         // 255 * 0.7 (30% 감소)
      'hora': 119,        // 170 * 0.7 (30% 감소)
      'fecha': 143,       // 204 * 0.7 (30% 감소)
      'resiva': 179,      // 255 * 0.7 (30% 감소)
      'casoesp': 179,     // 255 * 0.7 (30% 감소)
      'nencargado': 143,  // 204 * 0.7 (30% 감소)
      'cretmp': 179,      // 255 * 0.7 (30% 감소)
      'ntiqrepetir': 179, // 255 * 0.7 (30% 감소)
      'b_mercadopago': 179,  // 255 * 0.7 (30% 감소)
      'd_num_caja': 179,     // 255 * 0.7 (30% 감소)
      'd_num_terminal': 179, // 255 * 0.7 (30% 감소)
      'id': 179,          // 255 * 0.7 (30% 감소)
      // Ventas 보고서 - day/month/year 유닛용 칼럼 너비 (70% 증가: 1.7배)
      'eventcount': 340,  // 200 * 1.7
      'eventCount': 340,  // 200 * 1.7
      'tvents': 425,      // 250 * 1.7
      'tVents': 425,      // 250 * 1.7
      'tventas': 425,     // 250 * 1.7
      'tVentas': 425,     // 250 * 1.7
      'tcntropas': 340,   // 200 * 1.7
      'tCntRopas': 340,   // 200 * 1.7
      'month': 204,       // 120 * 1.7
      'year': 204,        // 120 * 1.7
      // 기타
      'start_date': 120,
      'end_date': 120,
    };
    
    // month 유닛인 경우 tefectivo, tcredito, tbanco 칼럼 너비를 30% 증가
    final isMonthUnit = unit == 'month' || (unit != null && unit != 'vcode' && keys.contains('month'));
    if (isMonthUnit) {
      // day/month/year 유닛용 기본값이 없으면 vcode 유닛용 값을 사용 (143)
      final baseTefectivo = columnWidths['tefectivo'] ?? 143;
      final baseTcredito = columnWidths['tcredito'] ?? 143;
      final baseTbanco = columnWidths['tbanco'] ?? 143;
      
      // 30% 증가: 1.3배
      columnWidths['tefectivo'] = (baseTefectivo * 1.3).roundToDouble();
      columnWidths['tcredito'] = (baseTcredito * 1.3).roundToDouble();
      columnWidths['tbanco'] = (baseTbanco * 1.3).roundToDouble();
      
      debugPrint('📊 [month 유닛] tefectivo, tcredito, tbanco 칼럼 너비 30% 증가');
      debugPrint('   → tefectivo: $baseTefectivo -> ${columnWidths['tefectivo']}');
      debugPrint('   → tcredito: $baseTcredito -> ${columnWidths['tcredito']}');
      debugPrint('   → tbanco: $baseTbanco -> ${columnWidths['tbanco']}');
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
              style: TextStyle(
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
      _debugRowCount = 0;
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
          // 컬럼 간격 (1px) * (컬럼 수 - 1) + 좌우 패딩 (32px)
          final totalSpacing = 1 * (keys.length - 1) + 32;
          final availableWidth = screenWidth - totalSpacing;
          
          // 대형 화면 감지 (1200px 이상)
          final isLargeScreen = screenWidth >= 1200;
          
          // Alertas 컬럼별 최소 너비 설정
          // 대형 화면에서는 fecha, hora를 2배로 설정
          final alertasMinWidths = <String, double>{
            'fecha': isLargeScreen ? 120 : 60,   // 대형 화면: 120 (2배), 일반: 60
            'hora': isLargeScreen ? 100 : 50,    // 대형 화면: 100 (2배), 일반: 50
            'progname': 75, // 150 -> 75 (절반)
            'sucursal': 50, // 100 -> 50 (절반)
          };
          
          debugPrint('   → [대형 화면 감지] screenWidth: $screenWidth, isLargeScreen: $isLargeScreen');
          debugPrint('   → [칼럼 너비] fecha: ${alertasMinWidths['fecha']}, hora: ${alertasMinWidths['hora']}');
          
          // 최소 너비가 필요한 컬럼들의 총 너비 계산
          double totalMinWidth = 0;
          for (var key in keys) {
            if (alertasMinWidths.containsKey(key)) {
              totalMinWidth += alertasMinWidths[key]!;
            }
          }
          
          // evento 컬럼에 할당할 나머지 공간 계산 (최소 1000으로 설정)
          final eventoWidth = (availableWidth - totalMinWidth).clamp(1000.0, double.infinity);
          
          // 동적 컬럼 너비 계산
          final dynamicColumnWidths = <String, double>{};
          for (var key in keys) {
            if (key.toLowerCase() == 'evento') {
              dynamicColumnWidths[key] = eventoWidth;
            } else if (alertasMinWidths.containsKey(key)) {
              dynamicColumnWidths[key] = alertasMinWidths[key]!;
            } else {
              dynamicColumnWidths[key] = columnWidths[key] ?? 150.0;
            }
          }
          
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('📊 [Alertas 보고서] 테이블 빌드 시작');
          debugPrint('   → keys: $keys');
          debugPrint('   → keys.length: ${keys.length}');
          debugPrint('   → displayedList.length: ${displayedList.length}');
          debugPrint('   → dataList.length: ${dataList.length}');
          debugPrint('   → dynamicColumnWidths: $dynamicColumnWidths');
          debugPrint('   → screenWidth: $screenWidth');
          debugPrint('   → availableWidth: $availableWidth');
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
                        debugPrint('   → 칼럼별 너비: ${keys.map((k) => '${k}=${dynamicColumnWidths[k] ?? 150.0}').join(', ')}');
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
                              }).toList(),
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
      return _ItemsTableWithMeasuredColumns(
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
        reportType: reportType,
        onRowDoubleTap: onRowDoubleTap,
        onRowTap: onRowTap,
        unit: unit,
        scrollController: scrollController,
        horizontalScrollController: horizontalScrollController,
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
                      if (shouldDoubleColumnWidths && columnWidths != null) {
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
                                final defaultColumnWidths = <String, double>{
                                  'codigo1': 200, 'desc1': 200, 'ProductName': 400, 'totalCantidad': 120,
                                  'CategoryCode': 100, 'CompanyCode': 100, 'tprendas': 100, 'timporte': 120,
                                  'codigo': 120, 'descripcion': 200, 'tevent': 100, 'tcant': 120,
                                  'tIngreso': 120, 'tingreso': 120, 'cntEvent': 100, 'cntevent': 100,
                                  'fecha': 60, 'hora': 50, 'evento': 1000, 'progname': 75,
                                  'alerta': 40, 'sucursal': 50,
                                  // ventas/fventas 보고서용 컬럼 너비
                                  'vcode': 100, 'tpago': 120, 'cntropas': 100, 'clientenombre': 200,
                                  'id_fventa': 150, 'numfactura': 150, 'tipofactura': 150, 'dni': 150,
                                  'monto': 150, 'xefectivo': 150, 'xbanco': 150, 'xcheque': 150,
                                  'numcheque': 150, 'utime': 150, 'borrado': 150, 'ref_num': 150,
                                  'cae': 150, 'vencimiento_cae': 150, 'punto_venta': 150, 'afip_number': 150,
                                  'tipo_pago': 150, 'b_impreso_x_comandera': 150, 'terminal': 150,
                                  'ref_id_vcode': 150, 'b_sincronizado_node_svr': 150,
                                  // clientes 보고서용 컬럼 너비
                                  'nombre': 150, 'vendedor': 150, 'direccion': 150, 'localidad': 150,
                                  'provincia': 150, 'telefono': 150, 'cntoperation': 150, 'totalimporte_compra': 150,
                                  'totaldeuda': 150, 'last_buy_date': 150, 'memo': 150,
                                  // Ventas 보고서 - day/month/year 유닛용 칼럼 너비
                                  // 큰 숫자를 표시하기 위해 기본값을 크게 설정
                                  'eventcount': 200, 'eventCount': 200,  // 큰 숫자 표시를 위해 100 -> 200으로 증가
                                  'tvents': 250, 'tVents': 250,  // 큰 숫자 표시를 위해 120 -> 250으로 증가
                                  'tventas': 250, 'tVentas': 250,  // 큰 숫자 표시를 위해 120 -> 250으로 증가
                                  'tcntropas': 200, 'tCntRopas': 200,  // 큰 숫자 표시를 위해 120 -> 200으로 증가
                                  'tefectivo': 306, 'tcredito': 306, 'tbanco': 306,  // 180 * 1.7 (70% 증가)
                                  'treservado': 306, 'tfavor': 255,  // 180 * 1.7, 150 * 1.7 (70% 증가)
                                  'month': 204, 'year': 204,  // 120 * 1.7 (70% 증가)
                                  'nencargado': 120,
                                };
                                
                                // month 유닛인 경우 tefectivo, tcredito, tbanco 칼럼 너비를 30% 증가
                                final isMonthUnitForFooter = unit == 'month';
                                if (isMonthUnitForFooter) {
                                  defaultColumnWidths['tefectivo'] = (306 * 1.3).roundToDouble(); // 306 * 1.3 = 398
                                  defaultColumnWidths['tcredito'] = (306 * 1.3).roundToDouble(); // 306 * 1.3 = 398
                                  defaultColumnWidths['tbanco'] = (306 * 1.3).roundToDouble(); // 306 * 1.3 = 398
                                  debugPrint('📊 [푸터] month 유닛: tefectivo, tcredito, tbanco 칼럼 너비 30% 증가 (306 -> 398)');
                                }
                                
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
      final tableWidget = _buildTableWithoutHorizontalScroll(
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
      return _buildTableWithHorizontalScroll(
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
      return _buildTableWithoutHorizontalScroll(
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
    // 테이블의 실제 너비 계산 (columnWidths 기반)
    double calculateTableWidth() {
      final defaultColumnWidths = <String, double>{
        'codigo1': 200,
        'desc1': 200,
        'ProductName': 400,
        'totalCantidad': 120,
        'CategoryCode': 100,
        'CompanyCode': 100,
        'tprendas': 100,
        'timporte': 120,
        'codigo': 120,
        'descripcion': 200,
        'tevent': 100,
        'tcant': 120,
        'tIngreso': 120,
        'tingreso': 120,
        'cntEvent': 100,
        'cntevent': 100,
        'fecha': 120,
        'hora': 100,
        'evento': 500,
        'progname': 150,
        'alerta': 80,
        'sucursal': 100,
        // Ventas 보고서 - day/month/year 유닛용 칼럼 너비
        // 큰 숫자를 표시하기 위해 기본값을 크게 설정
        'eventcount': 200, 'eventCount': 200,  // 큰 숫자 표시를 위해 100 -> 200으로 증가
        'tvents': 250, 'tVents': 250,  // 큰 숫자 표시를 위해 120 -> 250으로 증가
        'tventas': 250, 'tVentas': 250,  // 큰 숫자 표시를 위해 120 -> 250으로 증가
        'tcntropas': 200, 'tCntRopas': 200,  // 큰 숫자 표시를 위해 120 -> 200으로 증가
        'tefectivo': 306, 'tcredito': 306, 'tbanco': 306,  // 180 * 1.7 (70% 증가)
        'treservado': 306, 'tfavor': 255,  // 180 * 1.7, 150 * 1.7 (70% 증가)
        'month': 204, 'year': 204,  // 120 * 1.7 (70% 증가)
        'nencargado': 120,
      };
      
      // month 유닛인 경우 tefectivo, tcredito, tbanco 칼럼 너비를 30% 증가
      final isMonthUnitForScroll = unit == 'month';
      if (isMonthUnitForScroll) {
        defaultColumnWidths['tefectivo'] = (306 * 1.3).roundToDouble(); // 306 * 1.3 = 398
        defaultColumnWidths['tcredito'] = (306 * 1.3).roundToDouble(); // 306 * 1.3 = 398
        defaultColumnWidths['tbanco'] = (306 * 1.3).roundToDouble(); // 306 * 1.3 = 398
        debugPrint('📊 [수평 스크롤] month 유닛: tefectivo, tcredito, tbanco 칼럼 너비 30% 증가 (306 -> 398)');
      }
      
      final finalColumnWidths = columnWidths ?? defaultColumnWidths;
      
      double totalWidth = 0.0;
      for (int i = 0; i < keys.length; i++) {
        final key = keys[i];
        final width = finalColumnWidths[key] ?? 150.0;
        totalWidth += width;
        if (i < keys.length - 1) {
          totalWidth += 8; // columnSpacing
        }
      }
      // 최소 너비는 화면 너비보다 크게 설정하여 스크롤 가능하도록 함
      return totalWidth > constraints.maxWidth ? totalWidth : constraints.maxWidth + 100;
    }
    
    final tableWidth = calculateTableWidth();
    
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
  
  // 디버깅: 괄호/구문 오류 확인을 위한 헬퍼 함수
  static void _checkBracketBalance(String functionName, int startLine) {
    debugPrint('🔍 [구문 검사] $functionName 함수 괄호 균형 확인');
    debugPrint('   → 파일: report_table_builder.dart');
    debugPrint('   → 시작 라인: $startLine');
    debugPrint('   → 함수명: $functionName');
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
    _checkBracketBalance('buildDataTable', 1788);
    
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
    
    // items/ingresos 보고서는 별도 헤더를 사용하므로 DataTable의 기본 헤더를 숨겨야 함
    // ventas 보고서는 buildTableFromList에서 별도 헤더를 생성하므로 항상 headingRowHeight를 0으로 설정
    // (모든 unit에서 별도 헤더를 사용하므로)
    final isVentas = reportType == ReportType.ventas;
    // ventas 보고서는 항상 별도 헤더를 사용하므로 DataTable의 기본 헤더를 숨김
    final headingRowHeight = isVentas || isItemsOrIngresos ? 0.0 : 56.0;
    
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
            horizontalMargin: 0, // 헤더 Row와 정확히 일치시키기 위해 0으로 설정 (기본값 24px)
            columnSpacing: columnSpacing,
            dataRowMinHeight: reportType == ReportType.alertas ? 72 : 48,
            dataRowMaxHeight: reportType == ReportType.alertas ? 84 : 56,
            headingRowHeight: headingRowHeight,
            headingRowColor: MaterialStateProperty.all(Colors.transparent),
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
          return _buildDataRowFromMap(
            item: item,
            keys: keys,
            reportType: reportType,
            onRowDoubleTap: onRowDoubleTap,
            onRowTap: onRowTap,
            unit: unit,
            columnWidths: columnWidths, // null 대신 전달받은 columnWidths 사용 (헤더와 일치시키기 위함)
            useMeasuredWidths: useMeasuredWidths, // 측정된 너비 사용 여부 전달
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
                  style: TextStyle(
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
                // useMeasuredWidths가 true인 경우:
                // - 헤더: headerSizedBoxWidth = baseColumnWidth (측정값 전체)
                // - 데이터 행: SizedBox 너비 = baseCellWidth (측정값 전체), padding 없음
                final baseCellWidth = cellWidth ?? 75.0;  // 기본값도 절반으로 줄임 (150 -> 75)
                final finalCellWidth = useMeasuredWidths
                    ? baseCellWidth  // 측정된 너비는 이미 전체 너비를 포함하므로 그대로 사용
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
                                style: TextStyle(
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
                      // 디버깅: 데이터 행 칼럼 위치 및 너비 측정 (else 블록 - ventas day/month/year 아님) (숨김)
                      // WidgetsBinding.instance.addPostFrameCallback((_) {
                      //   final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                      //   if (renderBox != null) {
                      //     debugPrint('═══════════════════════════════════════════════════════');
                      //     debugPrint('🔍 [report_table_builder.dart:3023] 데이터 행 칼럼 위치 및 너비 측정 (else 블록 - ventas day/month/year 아님)');
                      //     debugPrint('   → 라인: 3023');
                      //     debugPrint('   → key: $key');
                      //     debugPrint('   → 실제 렌더링 위치: ${renderBox.localToGlobal(Offset.zero).dx}');
                      //     debugPrint('   → 실제 렌더링 너비: ${renderBox.size.width}');
                      //     print('🔍 [report_table_builder.dart:3023] 데이터 행 칼럼 위치 및 너비 측정 (else 블록 - ventas day/month/year 아님)');
                      //     print('   → 라인: 3023');
                      //     print('   → key: $key');
                      //     print('   → 실제 렌더링 위치: ${renderBox.localToGlobal(Offset.zero).dx}');
                      //     print('   → 실제 렌더링 너비: ${renderBox.size.width}');
                      //     debugPrint('═══════════════════════════════════════════════════════');
                      //   }
                      // });
                      
                      // ventas/fventas 보고서가 아닐 때만 수직선 표시 (ventas·fventas는 수직선 숨김)
                      return Container(
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
                            style: TextStyle(
                              fontSize: 14, // ventas 보고서도 14px로 통일
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
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
          
          MaterialStateProperty<Color?>? rowColor;
          if (shouldApplyRowColor && index % 5 == 4) {
            // 매 5번째 행 (0-based index이므로 4, 9, 14, ...)에 약간 다른 색상 적용
            rowColor = MaterialStateProperty.all(Colors.grey.withOpacity(0.05));
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
                  style: TextStyle(
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
          
          MaterialStateProperty<Color?>? rowColor;
          if (shouldApplyRowColor && index % 5 == 4) {
            // 매 5번째 행 (0-based index이므로 4, 9, 14, ...)에 약간 다른 색상 적용
            rowColor = MaterialStateProperty.all(Colors.grey.withOpacity(0.05));
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

  /// DataTable의 rows 생성
  static List<DataRow> _buildDataTableRows({
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
        return _buildDataRowFromMap(
          item: item,
          keys: keys,
          reportType: reportType,
          onRowDoubleTap: onRowDoubleTap,
          onRowTap: onRowTap,
          unit: unit,
          columnWidths: columnWidths,
          useMeasuredWidths: useMeasuredWidths, // 측정된 너비 사용 여부 전달
          rowIndex: index, // 행 인덱스 전달 (5행마다 색상 변경용)
        );
      } else {
        debugPrint('   → [데이터 행 생성] Map이 아닌 타입 - _buildDataRowFromNonMap 호출');
        return _buildDataRowFromNonMap(
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
      rows.add(_buildTotalRow(keys, totalDataList, color, reportType: reportType));
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
  static DataRow _buildDataRowFromMap({
    required Map<String, dynamic> item,
    required List<String> keys,
    required ReportType reportType,
    Function(Map<String, dynamic>)? onRowDoubleTap,
    Function(Map<String, dynamic>)? onRowTap,
    String? unit,
    Map<String, double>? columnWidths,
    bool useMeasuredWidths = false, // 측정된 너비 사용 여부
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
    final defaultColumnWidths = <String, double>{
      // Items 보고서
      'codigo1': 200,  // codigo1 칼럼 너비 증가 (120 -> 200)
      'desc1': 200,
      'ProductName': 400,  // ProductName 칼럼 너비 증가 (250 -> 400)
      'totalCantidad': 120,  // totalCantidad 칼럼 너비 추가
      'CategoryCode': 100,  // CategoryCode 칼럼 너비 추가
      'CompanyCode': 100,  // CompanyCode 칼럼 너비 추가
      'tprendas': 100,
      'timporte': 120,
      // Ingresos 보고서
      'codigo': 120,
      'descripcion': 200,
      'tevent': 100,
      'tcant': 120,
      'tIngreso': 120,
      'tingreso': 120,
      'cntEvent': 100,
      'cntevent': 100,
      // Alertas 보고서
      'fecha': 120,
      'hora': 100,
      'evento': 500,
      'progname': 150,
      'alerta': 80,
      'sucursal': 100,
    };
    
    final finalColumnWidths = columnWidths ?? defaultColumnWidths;
    
    // 디버깅: 데이터 행 칼럼 너비 정보 출력 (1번만 출력)
    if ((isItemsOrIngresos || isAlertas) && ReportTableBuilder._debugRowCount == 0) {
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
      ReportTableBuilder._debugRowCount++;
    }
    
    var cells = keys.map((key) {
      final cell = _buildDataCell(
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
        final columnWidth = finalColumnWidths[key] ?? 
                           finalColumnWidths[key.toLowerCase()] ??
                           (key.toLowerCase() == 'eventcount' ? finalColumnWidths['eventCount'] : null) ??
                           (key.toLowerCase() == 'tvents' ? finalColumnWidths['tVents'] : null) ??
                           (key.toLowerCase() == 'tventas' ? finalColumnWidths['tVentas'] : null) ??
                           (key.toLowerCase() == 'tcntropas' ? finalColumnWidths['tCntRopas'] : null) ??
                           75.0;  // 기본값도 절반으로 줄임 (150 -> 75)
        
        // 헤더와 정확히 일치시키기 위해 계산
        // 헤더: headerSizedBoxWidth = useMeasuredWidths ? baseColumnWidth : (isAlertas ? baseColumnWidth + 2.0 : (isVentas ? baseColumnWidth + 32.0 : baseColumnWidth))
        // 데이터 행: SizedBox 너비를 헤더의 headerSizedBoxWidth와 동일하게 설정
        // ventas 보고서의 모든 유닛(vcode 포함)은 DataCell padding을 고려해야 함
        final dataRowColumnWidth = useMeasuredWidths
            ? columnWidth  // 측정된 너비는 이미 전체 너비를 포함하므로 그대로 사용
            : (isAlertas
                ? columnWidth + 2.0  // alertas는 padding 1px * 2
                : (isVentasInClosure
                    ? columnWidth + 32.0  // ventas 보고서(vcode, day, month, year 모두)는 헤더와 동일하게 padding 추가
                    : columnWidth));
        
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
          // alertas는 padding이 1px이므로 baseColumnWidth + 2.0 (1px * 2)
          final alertasColumnWidth = useMeasuredWidths
              ? columnWidth
              : columnWidth + 2.0;  // 헤더와 동일하게 padding 추가 (1px * 2)
          
          debugPrint('🔍 [Alertas _buildDataRowFromMap] DataCell 생성 - key: $key, columnWidth: $columnWidth, alertasColumnWidth: $alertasColumnWidth, padding: 1px');
          debugPrint('   → 라인: 3367');
          // cell.child가 Align인 경우 Align의 child를 SizedBox로 감싸기
          if (cell.child is Align) {
            final align = cell.child as Align;
            debugPrint('   → cell.child는 Align 타입');
            return DataCell(
              Stack(
                children: [
                  SizedBox(
                    width: alertasColumnWidth,  // 헤더와 동일하게 padding 추가
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
                  width: alertasColumnWidth,  // 헤더와 동일하게 padding 추가
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
              // 헤더와 정확히 일치시키기 위해 계산
              // ventas 보고서의 모든 유닛(vcode 포함)은 DataCell padding을 고려해야 함
              // 클로저 내부에서 직접 계산하여 변수 스코프 문제 방지
              final isVentasForCellInClosure = reportType == ReportType.ventas;
              final dataRowColumnWidthForCell = useMeasuredWidths
                  ? columnWidth  // 측정된 너비는 이미 전체 너비를 포함하므로 그대로 사용
                  : (isAlertas
                      ? columnWidth + 2.0  // alertas는 padding 1px * 2
                      : (isVentasForCellInClosure
                          ? columnWidth + 32.0  // ventas 보고서(vcode, day, month, year 모두)는 헤더와 동일하게 padding 추가
                          : columnWidth));
              
              return Stack(
                children: [
                  SizedBox(
                    width: dataRowColumnWidthForCell,  // 헤더의 headerSizedBoxWidth와 일치 (baseColumnWidth + 32.0)
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
      cells = _addGesturesToCells(
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
  static DataRow _buildDataRowFromNonMap({
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
  static DataCell _buildDataCell({
    required String key,
    required dynamic value,
    required ReportType reportType,
  }) {
    // 디버깅: 함수 진입 확인 (너무 많이 출력되지 않도록 제한)
    if (ReportTableBuilder._debugCellCount < 10) {
      debugPrint('   → [구문 검사] _buildDataCell 함수 시작');
      debugPrint('      → 파일: report_table_builder.dart');
      debugPrint('      → 라인: ${2218}');
      debugPrint('      → 함수명: _buildDataCell');
      debugPrint('      → 파라미터 개수: 3');
      debugPrint('      → key: $key');
      debugPrint('      → value 타입: ${value.runtimeType}');
      debugPrint('      → value: $value');
      debugPrint('      → reportType: $reportType');
      ReportTableBuilder._debugCellCount++;
    }
    
    String formattedValue;
    final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1' || key == 'vcode';
    final keyLower = key.toLowerCase();
    
    if (ReportTableBuilder._debugCellCount <= 10) {
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
  static List<DataCell> _addGesturesToCells({
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

  // 고정된 합계 행 빌드 (화면 하단에 고정, 현재 보이는 항목들의 합계)
  static Widget buildFixedTotalRow(List<String> keys, List<dynamic> displayedList, Color reportColor, {Map<String, double>? columnWidths, List<dynamic>? dataList, ReportType? reportType, double? explicitWidth, String? unit}) {
    // 디버깅: 함수 진입 확인 (가장 먼저 실행)
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [_buildFixedTotalRow] 함수 진입');
    debugPrint('   → keys: $keys');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columnWidths 전달됨: ${columnWidths != null}');
    debugPrint('   → displayedList.length: ${displayedList.length}');
    debugPrint('   → dataList.length: ${dataList?.length ?? 0}');
    debugPrint('   → reportType: $reportType');
    
    // items/ingresos 보고서의 경우 전체 데이터(dataList)를 사용하여 합계 계산
    // 다른 보고서는 displayedList 사용 (페이지네이션된 경우)
    final listForTotal = ((reportType == ReportType.items || reportType == ReportType.ingresos) && dataList != null && dataList.isNotEmpty) 
        ? dataList 
        : displayedList;
    
    debugPrint('   → 합계 계산에 사용할 리스트 길이: ${listForTotal.length}');
    
    // fventas 보고서의 경우 factura A와 B 각각의 개수와 monto 합계만 계산
    Map<String, dynamic>? fventasSummary;
    if (reportType == ReportType.fventas) {
      int countA = 0;
      int countB = 0;
      double montoA = 0.0;
      double montoB = 0.0;
      
      for (var item in listForTotal) {
        if (item is Map<String, dynamic>) {
          final tipofactura = item['tipofactura']?.toString() ?? '';
          final monto = (item['monto'] as num?)?.toDouble() ?? 0.0;
          
          if (tipofactura == 'A') {
            countA++;
            montoA += monto;
          } else if (tipofactura == 'B') {
            countB++;
            montoB += monto;
          }
        }
      }
      
      fventasSummary = {
        'countA': countA,
        'countB': countB,
        'montoA': montoA,
        'montoB': montoB,
      };
      
      debugPrint('   → [FVentas] Factura A: $countA개, Monto: $montoA');
      debugPrint('   → [FVentas] Factura B: $countB개, Monto: $montoB');
    }
    
    // 각 칼럼별 합계 계산 (fventas가 아닌 경우에만)
    final totals = <String, num>{};
    
    if (reportType != ReportType.fventas) {
      for (var key in keys) {
        // 합계를 계산하지 않아야 하는 컬럼들
        final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1' || key == 'vcode' || key == 'id';
        final isDateColumn = key == 'fecha' || key == 'month' || key == 'year' || key == 'hora';
        final isTextColumn = key == 'dni' || key == 'DNI' || key == 'clientenombre' || key == 'vendedor' || 
                            key == 'tipo' || key == 'nencargado' || key == 'casoesp' || key == 'resiva' || 
                            key == 'cretmp' || key == 'sucursal' || key == 'ntiqrepetir' || key == 'b_mercadopago' ||
                            key == 'd_num_caja' || key == 'd_num_terminal' || key == 'ProductName' || key == 'desc1' || 
                            key == 'descripcion' || key == 'CategoryCode' || key == 'CompanyCode'; // CategoryCode, CompanyCode 추가
        if (isCodigoColumn || isDateColumn || isTextColumn) continue; // 합계 계산 제외
        
        num sum = 0;
        for (var item in listForTotal) {
          if (item is Map<String, dynamic> && item.containsKey(key)) {
            final value = item[key];
            if (ReportUtils.isNumeric(value)) {
              final numValue = num.tryParse(value.toString().replaceAll(',', '').replaceAll('\$', '').trim());
              if (numValue != null) {
                sum += numValue;
              }
            }
          }
        }
        totals[key] = sum;
      }
    }
    
    // 컬럼별 고정 너비 설정 (헤더와 일치) - 파라미터로 받은 columnWidths 사용, 없으면 기본값 사용
    // 넓은 화면에서 모든 칼럼이 보이도록 크기 조정
    final defaultColumnWidths = <String, double>{
      // Items 보고서
      'codigo1': 200,  // codigo1 칼럼 너비 증가 (120 -> 200)
      'desc1': 200,
      'ProductName': 400,  // ProductName 칼럼 너비 증가 (250 -> 400)
      'totalCantidad': 120,  // totalCantidad 칼럼 너비 추가
      'CategoryCode': 100,  // CategoryCode 칼럼 너비 추가
      'CompanyCode': 100,  // CompanyCode 칼럼 너비 추가
      'tprendas': 100,
      'timporte': 120,
      // Ingresos 보고서
      'codigo': 120,
      'descripcion': 200,
      'tevent': 100,
      'tcant': 120,
      'tIngreso': 120,
      'tingreso': 120,
      'cntEvent': 100,
      'cntevent': 100,
    };
    
    var finalColumnWidths = columnWidths ?? defaultColumnWidths;
    
    // month 유닛인 경우 tefectivo, tcredito, tbanco 칼럼 너비를 30% 증가
    final isMonthUnitForFooter = unit == 'month';
    if (isMonthUnitForFooter && finalColumnWidths.containsKey('tefectivo')) {
      final baseTefectivo = finalColumnWidths['tefectivo'] ?? 306;
      final baseTcredito = finalColumnWidths['tcredito'] ?? 306;
      final baseTbanco = finalColumnWidths['tbanco'] ?? 306;
      
      // 30% 증가: 1.3배
      finalColumnWidths = Map<String, double>.from(finalColumnWidths);
      finalColumnWidths['tefectivo'] = (baseTefectivo * 1.3).roundToDouble();
      finalColumnWidths['tcredito'] = (baseTcredito * 1.3).roundToDouble();
      finalColumnWidths['tbanco'] = (baseTbanco * 1.3).roundToDouble();
      
      debugPrint('📊 [푸터] month 유닛: tefectivo, tcredito, tbanco 칼럼 너비 30% 증가');
      debugPrint('   → tefectivo: $baseTefectivo -> ${finalColumnWidths['tefectivo']}');
      debugPrint('   → tcredito: $baseTcredito -> ${finalColumnWidths['tcredito']}');
      debugPrint('   → tbanco: $baseTbanco -> ${finalColumnWidths['tbanco']}');
    }
    
    // 디버깅: 푸터 칼럼 너비 정보 출력 (항상 출력)
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📊 [푸터] _buildFixedTotalRow 칼럼 너비 정보');
    debugPrint('   → keys: $keys');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columnWidths 전달됨: ${columnWidths != null}');
    debugPrint('   → finalColumnWidths: $finalColumnWidths');
    final isAlertas = reportType == ReportType.alertas;
    final footerPadding = isAlertas ? 1 : 16; // alertas는 1, 다른 보고서는 16
    final footerColumnSpacing = isAlertas ? 1 : 8; // alertas는 1, 다른 보고서는 8
    
    // ventas day/month/year 유닛인지 확인 (푸터도 헤더/데이터 행과 동일한 칼럼 폭 계산)
    final isVentasDayMonthYear = reportType == ReportType.ventas && 
                                 unit != null && 
                                 unit != 'vcode';
    
    double footerCumulativeX = 0.0;
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final baseColumnWidth = finalColumnWidths[key] ?? 150.0;
      
      // 헤더와 동일한 칼럼 폭 계산 로직 적용
      final footerColumnWidth = isVentasDayMonthYear
          ? baseColumnWidth + 32.0  // DataCell padding (16px * 2) 추가
          : baseColumnWidth;
      
      debugPrint('   → [푸터] 칼럼 #$i: key="$key", baseWidth=$baseColumnWidth, footerWidth=$footerColumnWidth, x=$footerCumulativeX, padding=$footerPadding (alertas: $isAlertas, ventasDayMonthYear: $isVentasDayMonthYear)');
      footerCumulativeX += footerColumnWidth;
      if (i < keys.length - 1) {
        footerCumulativeX += footerColumnSpacing;
        debugPrint('      → columnSpacing($footerColumnSpacing) 추가 후 x=$footerCumulativeX');
      }
    }
    debugPrint('   → [푸터] 총 너비: $footerCumulativeX');
    
    // fventas의 경우 명시적 너비 사용, 다른 보고서는 double.infinity 사용
    final containerWidth = explicitWidth ?? double.infinity;
    
    return Container(
      width: containerWidth, // 명시적 너비가 있으면 사용, 없으면 전체 폭 차지
      decoration: BoxDecoration(
        color: reportColor.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: reportColor.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Builder(
        builder: (context) {
          // 푸터 렌더링 후 실제 크기 측정
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              debugPrint('═══════════════════════════════════════════════════════');
              debugPrint('🔍 [오버랩 디버깅] buildFixedTotalRow 실제 렌더링 크기');
              debugPrint('   → reportType: $reportType');
              debugPrint('   → 푸터 실제 width: ${renderBox.size.width}');
              debugPrint('   → 푸터 실제 height: ${renderBox.size.height}');
              debugPrint('   → 계산된 총 너비: $footerCumulativeX');
              
              // fventas의 경우 추가 디버깅
              if (reportType == ReportType.fventas) {
                debugPrint('   → [FVentas 푸터] 높이 확인: ${renderBox.size.height}');
                debugPrint('   → [FVentas 푸터] 예상 높이: 56.0 (1줄)');
                if (renderBox.size.height > 60) {
                  debugPrint('   ⚠️ [FVentas 푸터] 높이가 60px 이상입니다! 2줄로 표시되고 있을 가능성');
                }
                
                // RenderObject 트리 확인
                debugPrint('   → [FVentas 푸터] RenderBox 타입: ${renderBox.runtimeType}');
                debugPrint('   → [FVentas 푸터] RenderBox constraints: ${renderBox.constraints}');
              }
              
              final parentBox = renderBox.parent as RenderBox?;
              if (parentBox != null) {
                debugPrint('   → 부모 실제 width: ${parentBox.size.width}');
                final footerOverflow = renderBox.size.width - parentBox.size.width;
                if (footerOverflow > 0) {
                  debugPrint('   ⚠️ 푸터 오버랩: ${footerOverflow.toStringAsFixed(1)}px');
                } else {
                  debugPrint('   ✅ 푸터 오버랩 없음. 여유: ${(-footerOverflow).toStringAsFixed(1)}px');
                }
              }
              debugPrint('═══════════════════════════════════════════════════════');
            }
          });
          
          // Footer는 수평 스크롤 컨트롤러를 사용하지 않음 (전체가 하나의 스크롤로 동기화됨)
          
          // fventas 보고서의 경우 factura A와 B 각각의 개수와 monto 합계를 1줄로 표시
          if (reportType == ReportType.fventas && fventasSummary != null) {
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('🔍 [FVentas 푸터] 1줄 표시 시작');
            debugPrint('   → fventasSummary: $fventasSummary');
            debugPrint('   → keys: $keys');
            debugPrint('   → keys.length: ${keys.length}');
            
            // tipofactura와 monto 컬럼의 위치 찾기
            int tipofacturaIndex = keys.indexOf('tipofactura');
            int montoIndex = keys.indexOf('monto');
            
            debugPrint('   → tipofacturaIndex: $tipofacturaIndex');
            debugPrint('   → montoIndex: $montoIndex');
            
            if (tipofacturaIndex == -1) tipofacturaIndex = 0;
            if (montoIndex == -1) montoIndex = keys.length - 1;
            
            debugPrint('   → 조정 후 tipofacturaIndex: $tipofacturaIndex');
            debugPrint('   → 조정 후 montoIndex: $montoIndex');
            
            // Factura A와 B를 1줄로 표시
            final rowWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: keys.asMap().entries.map((entry) {
                  final index = entry.key;
                  final key = entry.value;
                  final columnWidth = finalColumnWidths[key] ?? 150.0;
                  
                debugPrint('   → [푸터 셀] index=$index, key=$key, width=$columnWidth');
                
                // tipofactura 컬럼에 Factura A와 B 정보를 모두 표시
                  if (index == tipofacturaIndex) {
                  final text = 'Factura A: ${fventasSummary!['countA']} | Factura B: ${fventasSummary!['countB']}';
                  debugPrint('   → [푸터 셀] tipofactura 컬럼 텍스트: "$text"');
                  debugPrint('   → [푸터 셀] tipofactura 컬럼 너비: $columnWidth');
                  
                    return SizedBox(
                      width: columnWidth,
                      child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        height: 56.0,
                        child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                // monto 컬럼에 Factura A와 B의 monto 합계를 모두 표시
                  else if (index == montoIndex) {
                  final montoAText = ReportUtils.formatValue(fventasSummary!['montoA'] as double);
                  final montoBText = ReportUtils.formatValue(fventasSummary!['montoB'] as double);
                  final text = '$montoAText | $montoBText';
                  debugPrint('   → [푸터 셀] monto 컬럼 텍스트: "$text"');
                  debugPrint('   → [푸터 셀] monto 컬럼 너비: $columnWidth');
                  
                    return SizedBox(
                      width: columnWidth,
                      child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        height: 56.0,
                        child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  // 다른 컬럼은 빈 칸
                  else {
                    return SizedBox(
                      width: columnWidth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        height: 56.0,
                        child: const SizedBox.shrink(),
                      ),
                    );
                  }
                }).toList(),
              );
            
            debugPrint('   → [FVentas 푸터] Row 위젯 생성 완료');
            debugPrint('   → [FVentas 푸터] Row children 개수: ${rowWidget.children.length}');
            debugPrint('═══════════════════════════════════════════════════════');
            
            return rowWidget;
          }
          
          // Alertas 보고서의 경우 총 로그 개수만 표시
          if (reportType == ReportType.alertas) {
            final totalLogCount = listForTotal.length;
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('🔍 [Alertas 푸터] 총 로그 개수 계산');
            debugPrint('   → listForTotal.length: ${listForTotal.length}');
            debugPrint('   → totalLogCount: $totalLogCount');
            debugPrint('   → keys: $keys');
            debugPrint('   → keys[0]: ${keys.isNotEmpty ? keys[0] : "없음"}');
            debugPrint('   → finalColumnWidths[keys[0]]: ${keys.isNotEmpty ? finalColumnWidths[keys[0]] : "없음"}');
            debugPrint('   → 표시할 텍스트: "Total: $totalLogCount"');
            debugPrint('═══════════════════════════════════════════════════════');
            
            // 첫 번째 칼럼 너비는 최소 150으로 설정하여 "Total: XX" 텍스트가 잘리지 않도록 함
            final actualFirstColumnWidth = keys.isNotEmpty 
                ? (finalColumnWidths[keys[0]] ?? 150.0)
                : 150.0;
            final firstColumnWidth = actualFirstColumnWidth < 150.0 ? 150.0 : actualFirstColumnWidth;
            debugPrint('🔍 [Alertas 푸터] 첫 번째 칼럼 너비: $firstColumnWidth (실제: $actualFirstColumnWidth)');
            
            final totalText = 'Total: $totalLogCount';
            debugPrint('🔍 [Alertas 푸터] 생성할 텍스트: "$totalText"');
            
            // 총 너비 계산 (오버플로우 방지)
            double totalFooterWidth = firstColumnWidth;
            for (int i = 1; i < keys.length; i++) {
              final columnWidth = finalColumnWidths[keys[i]] ?? 150.0;
              totalFooterWidth += columnWidth + 1; // columnSpacing (1) 고려
            }
            debugPrint('🔍 [Alertas 푸터] 계산된 총 너비: $totalFooterWidth, explicitWidth: $explicitWidth');
            
            return Container(
              width: explicitWidth ?? double.infinity,
              decoration: BoxDecoration(
                color: reportColor.withOpacity(0.1),
                border: Border(
                  top: BorderSide(
                    color: reportColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                    // 첫 번째 칼럼에 총 로그 개수 표시 (최소 150 너비로 텍스트가 잘리지 않도록)
                    SizedBox(
                      width: firstColumnWidth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8), // padding을 1로 설정
                        height: 56.0,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            totalText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: reportColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible, // 텍스트가 잘리지 않도록 visible 사용
                          ),
                        ),
                      ),
                    ),
                    // 나머지 칼럼은 빈 칸
                    ...keys.skip(1).map((key) {
                      final columnWidth = finalColumnWidths[key] ?? 150.0;
                      debugPrint('🔍 [Alertas 푸터] 빈 칸 칼럼: $key, width: $columnWidth');
                      return SizedBox(
                        width: columnWidth + 1, // columnSpacing 고려
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 8), // padding을 1로 설정
                          height: 56.0,
                          child: const SizedBox.shrink(),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }
          
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: keys.asMap().entries.expand((entry) {
            final index = entry.key;
            final key = entry.value;
            // 합계를 계산하지 않아야 하는 컬럼들
            final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1' || key == 'vcode' || key == 'id';
            final isDateColumn = key == 'fecha' || key == 'month' || key == 'year' || key == 'hora';
            final isTextColumn = key == 'dni' || key == 'DNI' || key == 'clientenombre' || key == 'vendedor' || 
                                key == 'tipo' || key == 'nencargado' || key == 'casoesp' || key == 'resiva' || 
                                key == 'cretmp' || key == 'sucursal' || key == 'ntiqrepetir' || key == 'b_mercadopago' ||
                                key == 'd_num_caja' || key == 'd_num_terminal' || key == 'ProductName' || key == 'desc1' || 
                                key == 'descripcion' || key == 'CategoryCode' || key == 'CompanyCode'; // CategoryCode, CompanyCode 추가
            final baseColumnWidth = finalColumnWidths[key] ?? 150.0;
            
            // ventas day/month/year 유닛인지 확인 (푸터도 헤더/데이터 행과 동일한 칼럼 폭 계산)
            final isVentasDayMonthYear = reportType == ReportType.ventas && 
                                        unit != null && 
                                        unit != 'vcode';
            
            // 헤더와 동일한 칼럼 폭 계산 로직 적용
            // ventas day/month/year 유닛은 padding(32px)을 고려하여 푸터 너비 계산
            final footerColumnWidth = isVentasDayMonthYear
                ? baseColumnWidth + 32.0  // DataCell padding (16px * 2) 추가
                : baseColumnWidth;
            
            // 합계를 계산하지 않는 컬럼은 빈 칸으로 표시
            final isExcludedColumn = isCodigoColumn || isDateColumn || isTextColumn;
            final total = isExcludedColumn ? null : (totals.containsKey(key) ? totals[key] ?? 0 : null);
            
            // 첫 칼럼(codigo1 또는 codigo)에 총 개수 표시 (items/ingresos 보고서만)
            final isFirstColumn = index == 0;
            final shouldShowTotalCount = (reportType == ReportType.items || reportType == ReportType.ingresos) && 
                                        isFirstColumn && isCodigoColumn;
            final totalCount = shouldShowTotalCount ? listForTotal.length : null;
            
            // DataTable의 DataCell과 동일한 구조로 만들기
            // 헤더와 동일한 구조 사용: Container + padding
            // DataTable은 각 DataCell에 horizontal: 16 padding을 추가함
            // items/ingresos 보고서의 경우 행 높이가 32-37이므로 푸터도 동일한 높이로 맞춤
            final isNumericColumn = (key == 'tevent' || key == 'tcant' || key == 'tprendas' || key == 'timporte' || 
                                    key == 'tIngreso' || key == 'tingreso' || key == 'cntEvent' || key == 'cntevent' ||
                                    key == 'sucursal' || key == 'totalCantidad');
            
            final footerHeight = (reportType == ReportType.items || reportType == ReportType.ingresos) ? 37.0 : 56.0;
            final isVentas = reportType == ReportType.ventas;
            
            return [
              SizedBox(
                width: footerColumnWidth,  // 헤더와 동일한 칼럼 폭 사용
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 테이블 행 높이에 맞춰 vertical: 8로 조정 (32-37 높이)
                  height: footerHeight, // items/ingresos는 37, 다른 보고서는 56
                  child: shouldShowTotalCount && totalCount != null
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Total: $totalCount',
                            style: TextStyle(
                              fontSize: 14, // ventas 보고서도 14px로 통일
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : total != null
                          ? Align(
                              alignment: isNumericColumn ? Alignment.centerRight : Alignment.centerLeft, // 숫자 칼럼은 오른쪽 정렬
                              child: Text(
                                ReportUtils.formatValue(total),
                                style: TextStyle(
                                  fontSize: 14, // ventas 보고서도 14px로 통일
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
              ),
              // 마지막 칼럼이 아니면 columnSpacing 추가
              // ventas day/month/year 유닛의 경우 간격을 줄여서 더 많은 공간 확보
              if (index < keys.length - 1) ...[
                Builder(
                  builder: (context) {
                    final isVentasDayMonthYearForSpacing = reportType == ReportType.ventas && 
                                                           unit != null && 
                                                           unit != 'vcode';
                    final spacing = isVentasDayMonthYearForSpacing ? 4.0 : 8.0;
                    return SizedBox(width: spacing);
                  },
                ),
              ],
            ];
          }).toList(),
          );
        },
      ),
    );
  }

  // 헤더 행 빌드 (수평 스크롤 동기화용)
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
    bool useMeasuredWidths = false, // _ItemsTableWithMeasuredColumns에서 측정된 너비인지 여부
    bool isLargeScreen = false, // 대형 화면 여부 (헤더 칼럼 간격 조정용)
  }) {
    // 디버깅: 함수 진입 확인 (가장 먼저 실행)
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [report_table_builder.dart:3941] buildHeaderRow 함수 진입');
    debugPrint('   → 라인: 3941');
    debugPrint('   → keys: $keys');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columns.length: ${columns.length}');
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
      debugPrint('   → ⚠️ [중요] 이 columnWidths가 데이터 행의 columnWidths와 동일한지 확인 필요');
    } else {
      debugPrint('   → ⚠️ [경고] columnWidths가 null! 기본값 사용됨');
    }
    debugPrint('   → reportType: $reportType');
    debugPrint('   → unit: $unit');
    debugPrint('   → sortColumn: $sortColumn');
    debugPrint('   → sortAscending: $sortAscending');
    debugPrint('   → onSort != null: ${onSort != null}');
    debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
    debugPrint('   → isLargeScreen: $isLargeScreen');
    
    // Items/Ingresos 보고서인지 확인
    final isItems = reportType == ReportType.items;
    final isIngresos = reportType == ReportType.ingresos;
    final isItemsOrIngresos = isItems || isIngresos;
    
    if (isItemsOrIngresos) {
      debugPrint('   → [Items/Ingresos 헤더] 별도 헤더 행 생성 중');
      debugPrint('   → [중복 확인] DataTable의 headingRowHeight가 0이어야 함');
      debugPrint('   → [정렬 확인] 각 칼럼의 onSort 콜백 상태:');
      
      for (int i = 0; i < columns.length; i++) {
        final column = columns[i];
        final key = i < keys.length ? keys[i] : 'unknown';
        final hasOnSort = column.onSort != null;
        final isSorted = sortColumn == key;
        debugPrint('      칼럼 #$i ($key):');
        debugPrint('         → onSort=${hasOnSort ? "있음 ✅" : "없음 ❌"}');
        debugPrint('         → isSorted=$isSorted');
        if (hasOnSort) {
          debugPrint('         → 정렬 아이콘 표시: ${isSorted ? "예 ✅" : "아니오"}');
        } else {
          debugPrint('         → ⚠️ 정렬 불가: column.onSort가 null');
        }
      }
    }
    
    // 컬럼별 고정 너비 설정 (DataTable과 일치)
    // 넓은 화면에서 모든 칼럼이 보이도록 크기 조정
    final defaultColumnWidths = <String, double>{
      // Items 보고서
      'codigo1': 200,  // codigo1 칼럼 너비 증가 (120 -> 200)
      'desc1': 200,
      'ProductName': 400,  // ProductName 칼럼 너비 증가 (250 -> 400)
      'totalCantidad': 120,  // totalCantidad 칼럼 너비 추가
      'CategoryCode': 100,  // CategoryCode 칼럼 너비 추가
      'CompanyCode': 100,  // CompanyCode 칼럼 너비 추가
      'tprendas': 100,
      'timporte': 120,
      // Ingresos 보고서
      'codigo': 120,
      'descripcion': 200,
      'tevent': 100,
      'tcant': 120,
      'tIngreso': 120,
      'tingreso': 120,
      'cntEvent': 100,
      'cntevent': 100,
      // Alertas 보고서 (모든 칼럼을 절반으로 줄이고, evento는 2배로 늘림)
      'fecha': 60,   // 120 -> 60 (절반)
      'hora': 50,    // 100 -> 50 (절반)
      'evento': 1000, // 500 -> 1000 (2배)
      'progname': 75, // 150 -> 75 (절반)
      'alerta': 40,   // 80 -> 40 (절반)
      'sucursal': 80, // 큰 숫자 표시를 위해 50 -> 80으로 증가
      // Ventas 보고서 - day/month/year 유닛용 칼럼 너비 (70% 증가: 1.7배)
      'eventcount': 340,  // 200 * 1.7
      'eventCount': 340,  // 200 * 1.7
      'tvents': 425,      // 250 * 1.7
      'tVents': 425,      // 250 * 1.7
      'tventas': 425,     // 250 * 1.7
      'tVentas': 425,     // 250 * 1.7
      'tcntropas': 340,   // 200 * 1.7
      'tCntRopas': 340,   // 200 * 1.7
      'tefectivo': 306,   // 180 * 1.7 (70% 증가)
      'tcredito': 306,    // 180 * 1.7 (70% 증가)
      'tbanco': 306,      // 180 * 1.7 (70% 증가)
      'treservado': 306,  // 180 * 1.7 (70% 증가)
      'tfavor': 255,      // 150 * 1.7 (70% 증가)
      'month': 204,       // 120 * 1.7 (70% 증가)
      'year': 204,        // 120 * 1.7 (70% 증가)
      'nencargado': 120,  // nencargado 칼럼 너비
    };
    
    // month 유닛인 경우 tefectivo, tcredito, tbanco 칼럼 너비를 30% 증가
    final isMonthUnitForHeader = unit == 'month';
    if (isMonthUnitForHeader) {
      defaultColumnWidths['tefectivo'] = (306 * 1.3).roundToDouble(); // 306 * 1.3 = 398
      defaultColumnWidths['tcredito'] = (306 * 1.3).roundToDouble(); // 306 * 1.3 = 398
      defaultColumnWidths['tbanco'] = (306 * 1.3).roundToDouble(); // 306 * 1.3 = 398
      debugPrint('📊 [헤더] month 유닛: tefectivo, tcredito, tbanco 칼럼 너비 30% 증가 (306 -> 398)');
    }
    
    final finalColumnWidths = columnWidths ?? defaultColumnWidths;
    
    // 디버깅: 헤더 칼럼 너비 정보 출력 (항상 출력)
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📊 [헤더] _buildHeaderRow 칼럼 너비 정보');
    debugPrint('   → keys: $keys');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columns.length: ${columns.length}');
    debugPrint('   → columnWidths 전달됨: ${columnWidths != null}');
    debugPrint('   → finalColumnWidths: $finalColumnWidths');
    final isAlertas = reportType == ReportType.alertas;
    // ventas day/month/year 유닛의 경우 대형 화면에서 칼럼 간격을 줄여서 더 많은 공간 확보
    final isVentasDayMonthYearForSpacing = reportType == ReportType.ventas && 
                                          unit != null && 
                                          unit != 'vcode';
    // 대형 화면에서 헤더 칼럼 간격을 줄여서 더 많은 공간 활용
    final headerColumnSpacing = isAlertas 
        ? 1 
        : (isVentasDayMonthYearForSpacing ? (isLargeScreen ? 2 : 4) : 8); // alertas는 1, ventas day/month/year는 대형 화면에서 2px, 그 외는 4px 또는 8px
    final headerPadding = isAlertas ? 1 : 16; // alertas는 1, 다른 보고서는 16
    
    // ventas 보고서의 day/month/year 유닛인지 확인
    final isVentasDayMonthYear = reportType == ReportType.ventas && 
                                 unit != null && 
                                 unit != 'vcode';
    
    double headerCumulativeX = 0.0;
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final keyLower = key.toLowerCase();
      double? columnWidth;
      columnWidth = finalColumnWidths[key] ?? 
                   finalColumnWidths[keyLower] ??
                   (keyLower == 'eventcount' ? finalColumnWidths['eventCount'] : null) ??
                   (keyLower == 'tvents' ? finalColumnWidths['tVents'] : null) ??
                   (keyLower == 'tventas' ? finalColumnWidths['tVentas'] : null) ??
                   (keyLower == 'tcntropas' ? finalColumnWidths['tCntRopas'] : null);
      final baseColumnWidth = columnWidth ?? 150.0;
      
          // 헤더 너비 계산: DataCell의 padding을 고려
          // useMeasuredWidths가 true인 경우 (_ItemsTableWithMeasuredColumns에서 측정된 값):
          // - 측정된 칼럼 너비는 이미 DataTable의 실제 칼럼 너비(전체 너비)를 포함하고 있음
          // - 따라서 padding을 추가하지 않고 그대로 사용해야 함
          // alertas는 padding이 1px이므로 baseColumnWidth + 2.0 (1px * 2)
          // ventas 보고서의 모든 유닛(vcode 포함)은 DataCell padding을 고려해야 함
          final isVentas = reportType == ReportType.ventas;
          final finalColumnWidth = useMeasuredWidths
              ? baseColumnWidth  // 측정된 너비는 이미 전체 너비를 포함하므로 그대로 사용
              : (isAlertas
                  ? baseColumnWidth + 2.0  // alertas는 padding 1px * 2
                  : (isVentas
                      ? baseColumnWidth + 32.0  // ventas 보고서(vcode, day, month, year 모두)는 DataCell padding (16px * 2) 추가
                      : baseColumnWidth));
      
      debugPrint('   → [헤더] 칼럼 #$i: key="$key", baseWidth=$baseColumnWidth, finalWidth=$finalColumnWidth, x=$headerCumulativeX, padding=$headerPadding (alertas: $isAlertas, ventasDayMonthYear: $isVentasDayMonthYear)');
      headerCumulativeX += finalColumnWidth;
      if (i < keys.length - 1) {
        headerCumulativeX += headerColumnSpacing;
        debugPrint('      → columnSpacing($headerColumnSpacing) 추가 후 x=$headerCumulativeX');
      }
    }
    debugPrint('   → [헤더] 총 너비: $headerCumulativeX');
    
    // DataTable의 헤더와 동일한 스타일로 헤더 행 생성
    // DataTable의 columnSpacing(8)을 고려하여 각 컬럼에 동일한 간격 적용
    return Container(
      width: explicitWidth, // 명시적 너비가 있으면 사용, 없으면 null (자동 크기)
      padding: EdgeInsets.zero, // padding 제거하여 DataTable과 정확히 일치
      decoration: BoxDecoration(
        color: reportColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[400]!,
            width: 2,
          ),
        ),
      ),
      child: Builder(
        builder: (context) {
          // 헤더 렌더링 후 실제 크기 측정
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              debugPrint('═══════════════════════════════════════════════════════');
              debugPrint('🔍 [오버랩 디버깅] buildHeaderRow 실제 렌더링 크기');
              debugPrint('   → 헤더 실제 width: ${renderBox.size.width}');
              debugPrint('   → 헤더 실제 height: ${renderBox.size.height}');
              debugPrint('   → 계산된 총 너비: $headerCumulativeX');
              final parentBox = renderBox.parent as RenderBox?;
              if (parentBox != null) {
                debugPrint('   → 부모 실제 width: ${parentBox.size.width}');
                final headerOverflow = renderBox.size.width - parentBox.size.width;
                if (headerOverflow > 0) {
                  debugPrint('   ⚠️ 헤더 오버랩: ${headerOverflow.toStringAsFixed(1)}px');
                } else {
                  debugPrint('   ✅ 헤더 오버랩 없음. 여유: ${(-headerOverflow).toStringAsFixed(1)}px');
                }
              }
              debugPrint('═══════════════════════════════════════════════════════');
            }
          });
          
          // 헤더는 수평 스크롤 컨트롤러를 사용하지 않음 (전체가 하나의 스크롤로 동기화됨)
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: columns.asMap().entries.expand((entry) {
          final index = entry.key;
          final column = entry.value;
          final key = keys[index];
          final isSorted = sortColumn == key;
          
          // columnWidths에서 칼럼 너비 가져오기 (대소문자 구분 없이)
          final keyLower = key.toLowerCase();
          double? columnWidth;
          columnWidth = finalColumnWidths[key] ?? 
                       finalColumnWidths[keyLower] ??
                       (keyLower == 'eventcount' ? finalColumnWidths['eventCount'] : null) ??
                       (keyLower == 'tvents' ? finalColumnWidths['tVents'] : null) ??
                       (keyLower == 'tventas' ? finalColumnWidths['tVentas'] : null) ??
                       (keyLower == 'tcntropas' ? finalColumnWidths['tCntRopas'] : null);
          final baseColumnWidth = columnWidth ?? 150.0;
          
          // ventas 보고서의 모든 유닛(vcode, day, month, year)은 DataCell의 padding(16px * 2 = 32px)을 고려해야 함
          final isVentas = reportType == ReportType.ventas;
          final isVentasDayMonthYear = reportType == ReportType.ventas && 
                                       unit != null && 
                                       unit != 'vcode';
          
          // DataCell은 기본적으로 horizontal padding이 16px씩 양쪽에 있습니다.
          // DataTable이 각 칼럼의 실제 너비를 계산할 때:
          // - DataCell의 child (SizedBox) 너비 + DataCell의 horizontal padding (16px * 2 = 32px)
          // 따라서 헤더의 SizedBox 너비는 DataCell의 SizedBox 너비 + padding (32px)과 일치해야 합니다.
          // 하지만 실제로는 DataTable이 각 칼럼의 전체 너비를 자동으로 계산하므로,
          // 헤더의 SizedBox 너비를 DataCell의 실제 너비 (SizedBox 너비 + padding)와 일치시켜야 합니다.
          // 
          // useMeasuredWidths가 true인 경우 (_ItemsTableWithMeasuredColumns에서 측정된 값):
          // - 측정된 칼럼 너비는 이미 DataTable의 실제 칼럼 너비(전체 너비)를 포함하고 있음
          // - 따라서 padding을 추가하지 않고 그대로 사용해야 함
          // 
          // ventas 보고서의 모든 유닛(vcode 포함)은 DataCell padding을 고려해야 함
          final finalColumnWidth = useMeasuredWidths
              ? baseColumnWidth  // 측정된 너비는 이미 전체 너비를 포함하므로 그대로 사용
              : (isVentas
                  ? baseColumnWidth + 32.0  // ventas 보고서(vcode, day, month, year 모두)는 DataCell padding (16px * 2) 추가
                  : baseColumnWidth);
          
          // useMeasuredWidths가 true인 경우, 측정된 칼럼 너비는 DataTable의 실제 칼럼 너비(전체 너비)입니다.
          // 헤더의 SizedBox 너비는 측정값 전체를 사용해야 합니다.
          // 대형 화면에서 2배로 증가된 칼럼 너비의 경우에도 동일하게 전체 너비를 사용해야 합니다.
          // 중요: 헤더와 데이터 테이블이 동일한 너비를 사용하도록 보장
          // 헤더와 데이터 행의 칼럼 너비를 정확히 일치시키기 위해:
          // useMeasuredWidths가 false인 경우 (ventas day/month/year):
          // - 헤더: headerSizedBoxWidth = baseColumnWidth + 32.0 (고정 픽셀 값 + padding)
          // - 데이터 행: SizedBox 너비 = baseColumnWidth (고정 픽셀 값), DataCell이 자동으로 padding 32px 추가
          // - 따라서 실제 칼럼 너비는 동일: baseColumnWidth + 32
          // useMeasuredWidths가 true인 경우:
          // - 헤더: headerSizedBoxWidth = baseColumnWidth (측정값 전체)
          // - 데이터 행: SizedBox 너비 = baseColumnWidth (측정값 전체), padding 없음
          final headerSizedBoxWidth = useMeasuredWidths
              ? baseColumnWidth  // 측정값 전체 사용 (2배 증가된 경우도 포함) - 데이터 테이블과 동일
              : finalColumnWidth;  // 기본값 + padding (useMeasuredWidths가 false일 때)
          
          // 디버깅: 헤더 칼럼 너비 최종 계산 (숨김)
          // debugPrint('🔍 [report_table_builder.dart:4569] 헤더 칼럼 너비 최종 계산');
          // debugPrint('   → 라인: 4569');
          // debugPrint('   → key: $key');
          // debugPrint('   → baseColumnWidth: $baseColumnWidth');
          // debugPrint('   → finalColumnWidth: $finalColumnWidth');
          // debugPrint('   → headerSizedBoxWidth: $headerSizedBoxWidth');
          // debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
          // debugPrint('   → isVentas: $isVentas');
          // debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
          // if (isVentas) {
          //   debugPrint('   → ⚠️ [매칭 확인] 데이터 행의 SizedBox 너비는 $baseColumnWidth이어야 함 (DataCell padding 32px 자동 추가)');
          //   debugPrint('   → ⚠️ [매칭 확인] 헤더의 headerSizedBoxWidth ($headerSizedBoxWidth) = 데이터 행의 실제 칼럼 너비 ($baseColumnWidth + 32 = ${baseColumnWidth + 32.0})');
          // }
          // print('🔍 [report_table_builder.dart:4569] 헤더 칼럼 너비 최종 계산');
          // print('   → 라인: 4569');
          // print('   → key: $key');
          // print('   → baseColumnWidth: $baseColumnWidth');
          // print('   → headerSizedBoxWidth: $headerSizedBoxWidth');
          // print('   → useMeasuredWidths: $useMeasuredWidths');
          // print('   → ⚠️ 데이터 행의 SizedBox 너비는 $baseColumnWidth이어야 함');
          
          // debugPrint('   → [헤더] headerSizedBoxWidth 계산: useMeasuredWidths=$useMeasuredWidths, baseColumnWidth=$baseColumnWidth, headerSizedBoxWidth=$headerSizedBoxWidth');
          
          // debugPrint('   → [헤더] 칼럼 #$index ($key): baseColumnWidth=$baseColumnWidth, finalColumnWidth=$finalColumnWidth, headerSizedBoxWidth=$headerSizedBoxWidth');
          
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [buildHeaderRow:4214] 헤더 칼럼 너비 설정');
          debugPrint('   → 라인: 4214');
          debugPrint('   → reportType: $reportType');
          debugPrint('   → unit: $unit');
          debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
          debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
          debugPrint('   → key: $key');
          debugPrint('   → keyLower: $keyLower');
          debugPrint('   → baseColumnWidth: $baseColumnWidth (columnWidths에서 가져온 값)');
          debugPrint('   → finalColumnWidth: $finalColumnWidth (useMeasuredWidths에 따라 계산된 값)');
          debugPrint('   → headerSizedBoxWidth: $headerSizedBoxWidth (헤더 SizedBox 너비)');
          debugPrint('   → headerColumnSpacing: $headerColumnSpacing');
          debugPrint('   → finalColumnWidths[$key]: ${finalColumnWidths[key]}');
          debugPrint('   → finalColumnWidths[$keyLower]: ${finalColumnWidths[keyLower]}');
          debugPrint('   → ⚠️ [중요] useMeasuredWidths=$useMeasuredWidths이므로 ${useMeasuredWidths ? "전체 너비 그대로 사용 (baseColumnWidth=$baseColumnWidth)" : "padding 추가 (baseColumnWidth + 32.0 = ${baseColumnWidth + 32.0})"}');
          debugPrint('   → ⚠️ [매칭 확인] 데이터 행의 finalCellWidth와 일치해야 함');
          debugPrint('   → ⚠️ [매칭 확인] 데이터 행의 실제 칼럼 너비 (finalCellWidth + 32.0) = headerSizedBoxWidth와 일치해야 함');
          debugPrint('═══════════════════════════════════════════════════════');
          print('🔍 [buildHeaderRow:4214] 헤더 칼럼 너비 설정');
          print('   → 라인: 4214');
          print('   → key: $key');
          print('   → baseColumnWidth: $baseColumnWidth');
          print('   → headerSizedBoxWidth: $headerSizedBoxWidth');
          print('   → useMeasuredWidths: $useMeasuredWidths');
          
          // label에서 텍스트 추출
          String labelText = '';
          if (column.label is Row) {
            final row = column.label as Row;
            for (var child in row.children) {
              if (child is Text) {
                labelText = child.data ?? '';
                break;
              }
            }
          } else if (column.label is Text) {
            labelText = (column.label as Text).data ?? '';
          } else {
            labelText = key.toString();
          }
          
          // 고정 너비로 설정하여 DataTable과 정확히 일치
          // DataTable의 columnSpacing(8)을 각 칼럼 사이에 추가
          final isNumericHeader = (key == 'tevent' || key == 'tcant' || key == 'tprendas' || key == 'timporte' || 
                                   key == 'tIngreso' || key == 'tingreso' || key == 'cntEvent' || key == 'cntevent' ||
                                   key == 'sucursal' ||
                                   keyLower == 'eventcount' || keyLower == 'tvents' || keyLower == 'tventas' ||
                                   keyLower == 'tcntropas' || keyLower == 'tefectivo' || keyLower == 'tcredito' ||
                                   keyLower == 'tbanco' || keyLower == 'treservado' || keyLower == 'tfavor' ||
                                   keyLower == 'nencargado');
          
          // column.onSort가 있으면 사용하고, 없으면 onSort 파라미터를 사용 (fallback)
          final effectiveOnSort = column.onSort ?? onSort;
          final canSort = effectiveOnSort != null;
          
          // 헤더 칼럼 위치 계산 (디버깅용)
          double headerColumnX = 0.0;
          for (int j = 0; j < index; j++) {
            final prevKey = keys[j];
            final prevKeyLower = prevKey.toLowerCase();
            double? prevColumnWidth;
            prevColumnWidth = finalColumnWidths[prevKey] ?? 
                             finalColumnWidths[prevKeyLower] ??
                             (prevKeyLower == 'eventcount' ? finalColumnWidths['eventCount'] : null) ??
                             (prevKeyLower == 'tvents' ? finalColumnWidths['tVents'] : null) ??
                             (prevKeyLower == 'tventas' ? finalColumnWidths['tVentas'] : null) ??
                             (prevKeyLower == 'tcntropas' ? finalColumnWidths['tCntRopas'] : null);
            final prevBaseColumnWidth = prevColumnWidth ?? 150.0;
            // ventas 보고서의 모든 유닛(vcode 포함)은 DataCell padding을 고려해야 함
            final isVentasForPrev = reportType == ReportType.ventas;
            final prevFinalColumnWidth = useMeasuredWidths
                ? prevBaseColumnWidth
                : (isAlertas
                    ? prevBaseColumnWidth + 2.0  // alertas는 padding 1px * 2
                    : (isVentasForPrev
                        ? prevBaseColumnWidth + 32.0  // ventas 보고서(vcode, day, month, year 모두)는 padding 추가
                        : prevBaseColumnWidth));
            headerColumnX += prevFinalColumnWidth;
            if (j < index - 1) {
              headerColumnX += headerColumnSpacing;
            }
          }
          
          // 디버깅: 헤더 칼럼 위치와 너비 측정 (라인 번호 포함)
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [report_table_builder.dart:4545] 헤더 칼럼 위치 및 너비 측정');
          debugPrint('   → 라인: 4545');
          debugPrint('   → 칼럼 #$index ($key)');
          debugPrint('   → headerColumnX (계산된 x 위치): $headerColumnX');
          debugPrint('   → headerSizedBoxWidth: $headerSizedBoxWidth');
          debugPrint('   → baseColumnWidth: $baseColumnWidth');
          debugPrint('   → finalColumnWidth: $finalColumnWidth');
          debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
          debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
          print('🔍 [report_table_builder.dart:4545] 헤더 칼럼 위치 및 너비 측정');
          print('   → 라인: 4545');
          print('   → 칼럼 #$index ($key)');
          print('   → headerColumnX: $headerColumnX');
          print('   → headerSizedBoxWidth: $headerSizedBoxWidth');
          
          // useMeasuredWidths가 true인 경우, 측정된 칼럼 너비는 DataTable의 실제 칼럼 너비(전체 너비)입니다.
          // 헤더의 SizedBox 너비는 측정값 전체를 사용해야 합니다.
          return [
            Builder(
              builder: (context) {
                // 디버깅: 헤더 칼럼 위치 및 너비 측정 (숨김)
                // WidgetsBinding.instance.addPostFrameCallback((_) {
                //   final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                //   if (renderBox != null) {
                //     debugPrint('═══════════════════════════════════════════════════════');
                //     debugPrint('🔍 [report_table_builder.dart:4399] 헤더 칼럼 위치 및 너비 측정');
                //     debugPrint('   → 라인: 4399');
                //     debugPrint('   → 칼럼 #$index ($key)');
                //     debugPrint('   → 계산된 x 위치: $headerColumnX');
                //     debugPrint('   → baseColumnWidth: $baseColumnWidth');
                //     debugPrint('   → finalColumnWidth: $finalColumnWidth');
                //     debugPrint('   → headerSizedBoxWidth: $headerSizedBoxWidth');
                //     debugPrint('   → headerColumnSpacing: $headerColumnSpacing');
                //     debugPrint('   → 실제 렌더링 위치: ${renderBox.localToGlobal(Offset.zero).dx}');
                //     debugPrint('   → 실제 렌더링 너비: ${renderBox.size.width}');
                //     debugPrint('   → useMeasuredWidths: $useMeasuredWidths');
                //     debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
                //     print('🔍 [report_table_builder.dart:4399] 헤더 칼럼 위치 및 너비 측정');
                //     print('   → 라인: 4399');
                //     print('   → 칼럼 #$index ($key)');
                //     print('   → 계산된 x 위치: $headerColumnX');
                //     print('   → headerSizedBoxWidth: $headerSizedBoxWidth');
                //     print('   → 실제 렌더링 위치: ${renderBox.localToGlobal(Offset.zero).dx}');
                //     print('   → 실제 렌더링 너비: ${renderBox.size.width}');
                //     debugPrint('═══════════════════════════════════════════════════════');
                //   }
                // });
                
                // 디버깅: 헤더 칼럼에 수직선 추가 (라인 번호 포함)
                // 수직선은 칼럼 너비에 포함되지 않도록 별도로 추가
                debugPrint('🔍 [report_table_builder.dart:4710] 헤더 칼럼 수직선 추가');
                debugPrint('   → 라인: 4710');
                debugPrint('   → 칼럼 #$index ($key)');
                debugPrint('   → headerSizedBoxWidth: $headerSizedBoxWidth');
                debugPrint('   → headerColumnSpacing: $headerColumnSpacing');
                print('🔍 [report_table_builder.dart:4710] 헤더 칼럼 수직선 추가');
                print('   → 라인: 4710');
                print('   → 칼럼 #$index ($key)');
                print('   → headerSizedBoxWidth: $headerSizedBoxWidth');
                
                return Stack(
                  children: [
                    SizedBox(
                      width: headerSizedBoxWidth,
                      child: InkWell(
                    onTap: canSort
                    ? () {
                        debugPrint('═══════════════════════════════════════════════════════');
                        debugPrint('🔍 [buildHeaderRow] 헤더 칼럼 클릭 이벤트');
                        debugPrint('   → 칼럼 #$index ($key)');
                        debugPrint('   → column.onSort != null: ${column.onSort != null}');
                        debugPrint('   → onSort 파라미터 != null: ${onSort != null}');
                        debugPrint('   → effectiveOnSort != null: $canSort');
                        debugPrint('   → 현재 isSorted: $isSorted');
                        debugPrint('   → 현재 sortAscending: $sortAscending');
                        
                        if (canSort) {
                          final newAscending = isSorted ? !sortAscending : false;
                          debugPrint('   → 새 정렬 방향: $newAscending (${isSorted ? "토글" : "첫 클릭"})');
                          debugPrint('   → effectiveOnSort($index, $newAscending) 호출');
                          effectiveOnSort!(index, newAscending);
                          debugPrint('   ✅ onSort 호출 완료');
                        } else {
                          debugPrint('   ⚠️ effectiveOnSort가 null이므로 정렬 불가');
                        }
                        debugPrint('═══════════════════════════════════════════════════════');
                      }
                    : () {
                        debugPrint('═══════════════════════════════════════════════════════');
                        debugPrint('⚠️ [buildHeaderRow] 헤더 칼럼 클릭 - 정렬 불가');
                        debugPrint('   → 칼럼 #$index ($key)');
                        debugPrint('   → column.onSort == null: ${column.onSort == null}');
                        debugPrint('   → onSort 파라미터 == null: ${onSort == null}');
                        debugPrint('   → effectiveOnSort == null: 정렬 기능 없음');
                        debugPrint('═══════════════════════════════════════════════════════');
                      },
                    child: Container(
                      // DataCell과 동일한 구조: Container는 padding 없음, 내부 Padding이 16px 양쪽
                      padding: EdgeInsets.zero,
                      height: (reportType == ReportType.items || reportType == ReportType.ingresos) ? 37 : 56, // items/ingresos는 37, 다른 보고서는 56
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isAlertas ? 1 : 16, vertical: 8), // alertas는 1, 다른 보고서는 16 (DataCell과 동일)
                        child: Align(
                          alignment: isNumericHeader ? Alignment.centerRight : Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: isNumericHeader ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  labelText,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14, // ventas 보고서도 14px로 통일
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: isNumericHeader ? TextAlign.right : TextAlign.left,
                                ),
                              ),
                              if (isSorted && canSort)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(
                                    sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                    size: 16,
                                    color: reportColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      ),
                    ),
                    ),
                    // ventas/fventas 보고서가 아닐 때만 수직선 표시 (ventas·fventas는 수직선 숨김)
                    if (reportType != ReportType.ventas && reportType != ReportType.fventas && index < columns.length - 1)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 1.0,
                          color: Colors.red.withOpacity(0.5),  // 디버깅용 빨간색 수직선
                        ),
                      ),
                  ],
                );
              },
            ),
            // 마지막 칼럼이 아니면 columnSpacing 추가 (alertas는 1, 다른 보고서는 8)
            // 헤더와 데이터 행의 칼럼 간격이 정확히 일치해야 함
            if (index < columns.length - 1) SizedBox(width: headerColumnSpacing.toDouble()),
          ];
        }).toList(),
          );
        },
      ),
    );
  }

  // 합계 행 빌드
  static DataRow _buildTotalRow(List<String> keys, List<dynamic> dataList, Color reportColor, {ReportType? reportType}) {
    // 각 칼럼별 합계 계산
    final totals = <String, num>{};
    
    for (var key in keys) {
      // 합계를 계산하지 않아야 하는 컬럼들
      final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1' || key == 'vcode' || key == 'id';
      final isDateColumn = key == 'fecha' || key == 'month' || key == 'year' || key == 'hora';
      final isTextColumn = key == 'dni' || key == 'DNI' || key == 'clientenombre' || key == 'vendedor' || 
                          key == 'tipo' || key == 'nencargado' || key == 'casoesp' || key == 'resiva' || 
                          key == 'cretmp' || key == 'sucursal' || key == 'ntiqrepetir' || key == 'b_mercadopago' ||
                          key == 'd_num_caja' || key == 'd_num_terminal' || key == 'ProductName' || key == 'desc1' || 
                          key == 'descripcion';
      if (isCodigoColumn || isDateColumn || isTextColumn) continue; // 합계 계산 제외
      
      num sum = 0;
      for (var item in dataList) {
        if (item is Map<String, dynamic> && item.containsKey(key)) {
          final value = item[key];
          if (ReportUtils.isNumeric(value)) {
            final numValue = num.tryParse(value.toString().replaceAll(',', '').replaceAll('\$', '').trim());
            if (numValue != null) {
              sum += numValue;
            }
          }
        }
      }
      totals[key] = sum;
    }
    
    final isVentas = reportType == ReportType.ventas;
    
    return DataRow(
      color: MaterialStateProperty.all(reportColor.withOpacity(0.1)),
      cells: keys.map((key) {
        // 합계를 계산하지 않아야 하는 컬럼들
        final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1' || key == 'vcode' || key == 'id';
        final isDateColumn = key == 'fecha' || key == 'month' || key == 'year' || key == 'hora';
        final isTextColumn = key == 'dni' || key == 'DNI' || key == 'clientenombre' || key == 'vendedor' || 
                            key == 'tipo' || key == 'nencargado' || key == 'casoesp' || key == 'resiva' || 
                            key == 'cretmp' || key == 'sucursal' || key == 'ntiqrepetir' || key == 'b_mercadopago' ||
                            key == 'd_num_caja' || key == 'd_num_terminal';
        
        // 합계를 계산하지 않는 컬럼은 빈 칸으로 표시
        if (isCodigoColumn || isDateColumn || isTextColumn) {
          return const DataCell(Text(''));
        }
        
        // 합계가 계산된 컬럼만 합계 값 표시
        if (totals.containsKey(key)) {
          final total = totals[key] ?? 0;
          return DataCell(
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                ReportUtils.formatValue(total),
                style: TextStyle(
                  fontSize: 14, // ventas 보고서도 14px로 통일
                  fontWeight: FontWeight.bold,
                  height: isVentas ? 1.0 : 1.2,
                ),
              ),
            ),
          );
        }
        
        // 합계가 계산되지 않은 컬럼도 빈 칸으로 표시
        return const DataCell(Text(''));
      }).toList(),
    );
  }

  // Map 형태 테이블용 합계 행 빌드
  static DataRow _buildTotalRowForMapTable(Map<String, dynamic> data, Color reportColor) {
    final totals = <String, num>{};
    
    for (var key in data.keys) {
      final value = data[key];
      if (value is List) {
        num sum = 0;
        for (var item in value) {
          if (ReportUtils.isNumeric(item)) {
            final numValue = num.tryParse(item.toString().replaceAll(',', '').replaceAll('\$', '').trim());
            if (numValue != null) {
              sum += numValue;
            }
          }
        }
        totals[key] = sum;
      }
    }
    
    return DataRow(
      color: MaterialStateProperty.all(reportColor.withOpacity(0.1)),
      cells: data.keys.map((key) {
        final total = totals[key] ?? 0;
        return DataCell(
          Text(
            ReportUtils.formatValue(total),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

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
        headingRowColor: MaterialStateProperty.all(
          reportColor.withOpacity(0.1),
        ),
        columns: columns,
        rows: rows,
      ),
    );
  }
}

/// Items/Ingresos 보고서용 StatefulWidget: DataTable의 실제 칼럼 너비를 측정하여 헤더와 푸터에 적용
class _ItemsTableWithMeasuredColumns extends StatefulWidget {
  final List<String> keys;
  final List<DataColumn> columns;
  final Color color;
  final String? sortColumn;
  final bool sortAscending;
  final Function(int columnIndex, bool ascending)? onSort;
  final Map<String, double>? columnWidths;
  final List<dynamic> displayedList;
  final List<dynamic> dataList;
  final ReportType reportType;
  final Function(Map<String, dynamic>)? onRowDoubleTap;
  final Function(Map<String, dynamic>)? onRowTap;
  final String? unit;
  final ScrollController scrollController;
  final ScrollController? horizontalScrollController;

  const _ItemsTableWithMeasuredColumns({
    Key? key,
    required this.keys,
    required this.columns,
    required this.color,
    this.sortColumn,
    this.sortAscending = true,
    this.onSort,
    this.columnWidths,
    required this.displayedList,
    required this.dataList,
    required this.reportType,
    this.onRowDoubleTap,
    this.onRowTap,
    this.unit,
    required this.scrollController,
    this.horizontalScrollController,
  }) : super(key: key);

  @override
  State<_ItemsTableWithMeasuredColumns> createState() => _ItemsTableWithMeasuredColumnsState();
}

class _ItemsTableWithMeasuredColumnsState extends State<_ItemsTableWithMeasuredColumns> {
  Map<String, double>? _measuredColumnWidths;
  final GlobalKey _dataTableKey = GlobalKey();
  bool _hasMeasured = false; // 측정 완료 플래그 추가

  @override
  void initState() {
    super.initState();
    // 초기 칼럼 너비는 전달된 값 또는 기본값 사용
    _measuredColumnWidths = widget.columnWidths;
  }

  @override
  void didUpdateWidget(_ItemsTableWithMeasuredColumns oldWidget) {
    super.didUpdateWidget(oldWidget);
    // unit이나 keys가 변경되면 측정값을 초기화하여 다시 측정하도록 함
    if (oldWidget.unit != widget.unit || 
        !_listEquals(oldWidget.keys, widget.keys) ||
        oldWidget.displayedList.length != widget.displayedList.length) {
      debugPrint('🔍 [report_table_builder.dart:4542] [didUpdateWidget] unit 또는 keys 변경 감지 - 측정값 초기화');
      debugPrint('   → 라인: 4542');
      debugPrint('   → oldWidget.unit: ${oldWidget.unit}');
      debugPrint('   → widget.unit: ${widget.unit}');
      debugPrint('   → oldWidget.keys: ${oldWidget.keys}');
      debugPrint('   → widget.keys: ${widget.keys}');
      debugPrint('   → oldWidget.displayedList.length: ${oldWidget.displayedList.length}');
      debugPrint('   → widget.displayedList.length: ${widget.displayedList.length}');
      print('🔍 [report_table_builder.dart:4542] [didUpdateWidget] unit 또는 keys 변경 감지 - 측정값 초기화');
      print('   → 라인: 4542');
      print('   → oldWidget.unit: ${oldWidget.unit}');
      print('   → widget.unit: ${widget.unit}');
      print('   → oldWidget.keys: ${oldWidget.keys}');
      print('   → widget.keys: ${widget.keys}');
      print('   → oldWidget.displayedList.length: ${oldWidget.displayedList.length}');
      print('   → widget.displayedList.length: ${widget.displayedList.length}');
      _measuredColumnWidths = null;
      _hasMeasured = false;
    }
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _measureColumnWidths() {
    // 이미 측정이 완료되었으면 다시 측정하지 않음
    if (_hasMeasured) {
      debugPrint('   → [report_table_builder.dart:4574] [측정] 이미 측정 완료됨. 재측정 건너뜀');
      debugPrint('      → 라인: 4574');
      return;
    }
    
    final RenderBox? renderBox = _dataTableKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // DataTable의 RenderTable 찾기
    RenderBox? tableBox;
    void findTable(RenderBox? box, int depth) {
      if (box == null || depth > 5) return;
      if (box.runtimeType.toString().contains('RenderTable')) {
        tableBox = box;
        return;
      }
      box.visitChildren((child) {
        if (child is RenderBox) {
          findTable(child, depth + 1);
        }
      });
    }
    findTable(renderBox, 0);

    if (tableBox == null) return;

    // RenderTable의 자식들을 직접 순회하여 첫 번째 데이터 행의 칼럼 너비 측정
    // 로그를 보면 RenderTable의 자식들이 RenderSemanticsAnnotations로 나타나고,
    // 헤더 행은 height=0.0, 데이터 행은 height=37.0입니다.
    // 각 행은 keys.length개의 칼럼을 가지고 있습니다.
    final measuredWidths = <String, double>{};
    final tableChildren = <RenderBox>[];
    tableBox!.visitChildren((child) {
      if (child is RenderBox) {
        tableChildren.add(child);
      }
    });

    // 첫 번째 데이터 행 찾기 (height > 0인 첫 번째 행)
    int dataRowStartIndex = -1;
    for (int i = 0; i < tableChildren.length; i++) {
      if (tableChildren[i].size.height > 0) {
        dataRowStartIndex = i;
        break;
      }
    }

    if (dataRowStartIndex == -1 || dataRowStartIndex + widget.keys.length > tableChildren.length) {
      debugPrint('   ⚠️ [report_table_builder.dart:4621] [측정] 첫 번째 데이터 행을 찾을 수 없습니다');
      debugPrint('      → 라인: 4621');
      debugPrint('      → dataRowStartIndex: $dataRowStartIndex');
      debugPrint('      → widget.keys.length: ${widget.keys.length}');
      debugPrint('      → tableChildren.length: ${tableChildren.length}');
      return;
    }

    // 기본 칼럼 너비 (최대값 제한용)
    // ventas day/month/year 유닛의 경우 기본 칼럼 너비를 포함
    final isVentasDayMonthYear = widget.reportType == ReportType.ventas && 
                                 widget.unit != null && 
                                 widget.unit != 'vcode';
    
    final defaultColumnWidths = widget.columnWidths ?? <String, double>{
      'codigo1': 200,  // codigo1 칼럼 너비 증가 (150 -> 200)
      'desc1': 300,
      'ProductName': 450,  // ProductName 칼럼 너비 유지
      'totalCantidad': 150,
      'CategoryCode': 120,
      'CompanyCode': 120,
      'tprendas': 120,
      'timporte': 150,
      // Ventas 보고서 - day/month/year 유닛용 칼럼 너비
      // 큰 숫자를 표시하기 위해 기본값을 크게 설정
      'eventcount': 200, 'eventCount': 200,  // 큰 숫자 표시를 위해 100 -> 200으로 증가
      'tvents': 250, 'tVents': 250,  // 큰 숫자 표시를 위해 120 -> 250으로 증가
      'tventas': 250, 'tVentas': 250,  // 큰 숫자 표시를 위해 120 -> 250으로 증가
      'tcntropas': 200, 'tCntRopas': 200,  // 큰 숫자 표시를 위해 120 -> 200으로 증가
      'tefectivo': 306, 'tcredito': 306, 'tbanco': 306,  // 180 * 1.7 (70% 증가)
      'treservado': 306, 'tfavor': 255,  // 180 * 1.7, 150 * 1.7 (70% 증가)
      'month': 204, 'year': 204,  // 120 * 1.7 (70% 증가)
      'nencargado': 204,  // 120 * 1.7 (70% 증가)
      'fecha': 255,  // 150 * 1.7 (70% 증가)
      'sucursal': 136,  // 80 * 1.7 (70% 증가)
    };
    
    // month 유닛인 경우 tefectivo, tcredito, tbanco 칼럼 너비를 30% 증가
    final isMonthUnitForMeasured = widget.unit == 'month';
    if (isMonthUnitForMeasured) {
      defaultColumnWidths['tefectivo'] = (306 * 1.3).roundToDouble(); // 306 * 1.3 = 398
      defaultColumnWidths['tcredito'] = (306 * 1.3).roundToDouble(); // 306 * 1.3 = 398
      defaultColumnWidths['tbanco'] = (306 * 1.3).roundToDouble(); // 306 * 1.3 = 398
      debugPrint('📊 [측정 칼럼] month 유닛: tefectivo, tcredito, tbanco 칼럼 너비 30% 증가 (306 -> 398)');
    }
    
    // 칼럼별 최대 너비 제한
    final maxColumnWidths = <String, double>{};
    for (final key in widget.keys) {
      final keyLower = key.toLowerCase();
      // ventas day/month/year 유닛의 경우 대소문자 변형도 고려
      final defaultWidth = defaultColumnWidths[key] ?? 
                          defaultColumnWidths[keyLower] ??
                          (keyLower == 'eventcount' ? defaultColumnWidths['eventCount'] : null) ??
                          (keyLower == 'tvents' ? defaultColumnWidths['tVents'] : null) ??
                          (keyLower == 'tventas' ? defaultColumnWidths['tVentas'] : null) ??
                          (keyLower == 'tcntropas' ? defaultColumnWidths['tCntRopas'] : null) ??
                          150.0;
      // ProductName은 기본값을 유지하거나 최대 500px로 제한
      if (key == 'ProductName') {
        maxColumnWidths[key] = 500.0;
      } else {
        // 다른 칼럼은 기본값의 1.3배를 최대값으로 설정
        // ventas day/month/year 유닛의 경우 측정값을 그대로 사용하므로 최대값을 크게 설정
        maxColumnWidths[key] = isVentasDayMonthYear ? (defaultWidth * 2.0) : (defaultWidth * 1.3);
      }
    }
    
    // 첫 번째 데이터 행의 각 칼럼 너비 측정
    for (int i = 0; i < widget.keys.length; i++) {
      final cellBox = tableChildren[dataRowStartIndex + i];
      final key = widget.keys[i];
      final keyLower = key.toLowerCase();
      final measuredWidth = cellBox.size.width;
      
      // ProductName은 측정값을 사용하지 않고 항상 기본값 사용
      // ventas day/month/year 유닛의 경우 대소문자 변형도 고려
      final defaultWidth = defaultColumnWidths[key] ?? 
                          defaultColumnWidths[keyLower] ??
                          (keyLower == 'eventcount' ? defaultColumnWidths['eventCount'] : null) ??
                          (keyLower == 'tvents' ? defaultColumnWidths['tVents'] : null) ??
                          (keyLower == 'tventas' ? defaultColumnWidths['tVentas'] : null) ??
                          (keyLower == 'tcntropas' ? defaultColumnWidths['tCntRopas'] : null) ??
                          150.0;
      final maxWidth = maxColumnWidths[key] ?? 
                      maxColumnWidths[keyLower] ??
                      (defaultWidth * 1.3);
      
      double finalWidth;
      if (key == 'ProductName') {
        // ProductName은 항상 기본값(450px) 사용 (측정값 무시)
        finalWidth = defaultWidth;
      } else {
        // 다른 칼럼은 측정값이 최대값을 초과하면 기본값 사용
        // ventas day/month/year 유닛의 경우 측정값을 그대로 사용 (DataTable이 자동으로 계산한 실제 너비)
        finalWidth = measuredWidth > maxWidth ? defaultWidth : measuredWidth;
      }
      
      measuredWidths[key] = finalWidth;
      debugPrint('   → [report_table_builder.dart:4706] [측정] 칼럼 #$i: key="$key", 측정 width=$measuredWidth, 최종 width=$finalWidth (기본: $defaultWidth, 최대: $maxWidth, ventasDayMonthYear: $isVentasDayMonthYear)');
      debugPrint('      → 라인: 4706');
    }

    // 측정된 칼럼 너비가 있고, 이전 값과 다를 때만 상태 업데이트 (무한 루프 방지)
    if (measuredWidths.isNotEmpty && measuredWidths.length == widget.keys.length) {
      bool hasChanged = false;
      if (_measuredColumnWidths == null) {
        hasChanged = true;
      } else {
        for (final key in widget.keys) {
          final oldWidth = _measuredColumnWidths![key] ?? 0.0;
          final newWidth = measuredWidths[key] ?? 0.0;
          // 1픽셀 이상 차이가 있을 때만 변경으로 간주 (작은 변화 무시)
          if ((oldWidth - newWidth).abs() > 1.0) {
            hasChanged = true;
            break;
          }
        }
      }
      
      if (hasChanged) {
        // ProductName은 측정 결과에서 제외하고 항상 기본값 사용
        final defaultColumnWidths = widget.columnWidths ?? <String, double>{
          'ProductName': 450,
        };
        final finalMeasuredWidths = Map<String, double>.from(measuredWidths);
        // ProductName이 있으면 기본값으로 교체
        if (finalMeasuredWidths.containsKey('ProductName')) {
          finalMeasuredWidths['ProductName'] = defaultColumnWidths['ProductName'] ?? 450.0;
        }
        
        setState(() {
          _measuredColumnWidths = finalMeasuredWidths;
          _hasMeasured = true; // 측정 완료 표시
        });
        debugPrint('   → [report_table_builder.dart:4741] [측정 완료] 칼럼 너비: $finalMeasuredWidths (ProductName은 기본값 사용)');
        debugPrint('      → 라인: 4741');
        print('   → [report_table_builder.dart:4741] [측정 완료] 칼럼 너비: $finalMeasuredWidths (ProductName은 기본값 사용)');
        print('      → 라인: 4741');
      } else {
        // 변경이 없어도 측정은 완료된 것으로 간주
        _hasMeasured = true;
        debugPrint('   → [report_table_builder.dart:4745] [측정] 칼럼 너비 변경 없음 (무시, 측정 완료)');
        debugPrint('      → 라인: 4745');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [큰 화면 디버깅] _ItemsTableWithMeasuredColumns build 시작');
        debugPrint('   → reportType: ${widget.reportType}');
        debugPrint('   → displayedList.length: ${widget.displayedList.length}');
        debugPrint('   → dataList.length: ${widget.dataList.length}');
        debugPrint('   → keys.length: ${widget.keys.length}');
        debugPrint('   → scrollController: ${widget.scrollController != null}');
        debugPrint('   → horizontalScrollController: ${widget.horizontalScrollController != null}');
        debugPrint('   → sortColumn: ${widget.sortColumn}');
        debugPrint('   → sortAscending: ${widget.sortAscending}');
        debugPrint('   → onSort != null: ${widget.onSort != null}');
        debugPrint('   → columns.length: ${widget.columns.length}');
        
        // 각 칼럼의 정렬 기능 확인
        debugPrint('   → [정렬 기능 확인] 각 칼럼의 onSort 상태:');
        for (int i = 0; i < widget.columns.length; i++) {
          final column = widget.columns[i];
          final key = i < widget.keys.length ? widget.keys[i] : 'unknown';
          final hasOnSort = column.onSort != null;
          final isSorted = widget.sortColumn == key;
          debugPrint('      칼럼 #$i ($key): onSort=${hasOnSort ? "있음 ✅" : "없음 ❌"}, isSorted=$isSorted');
        }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        debugPrint('🔍 [큰 화면 디버깅] LayoutBuilder constraints');
        debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
        debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
        debugPrint('   → constraints.minWidth: ${constraints.minWidth}');
        debugPrint('   → constraints.minHeight: ${constraints.minHeight}');
        
        // 기본 칼럼 너비 정의 (ventas day/month/year 유닛용)
        // 헤더와 행 모두 동일한 고정 픽셀 값 사용 (70% 증가: 1.7배)
        final baseDefaultColumnWidths = <String, double>{
          'ProductName': 382.5,  // 225 * 1.7
          'eventcount': 127.5, 'eventCount': 127.5,  // 75 * 1.7
          'tvents': 153, 'tVents': 153,  // 90 * 1.7
          'tventas': 153, 'tVentas': 153,  // 90 * 1.7
          'tcntropas': 127.5, 'tCntRopas': 127.5,  // 75 * 1.7
          'tefectivo': 102, 'tcredito': 102, 'tbanco': 102,  // 60 * 1.7
          'treservado': 102, 'tfavor': 85,  // 60 * 1.7, 50 * 1.7
          'month': 85, 'year': 85,  // 50 * 1.7
          'fecha': 102,  // 60 * 1.7
          'sucursal': 51,  // 30 * 1.7
        };
        
        // month 유닛인 경우 tefectivo, tcredito, tbanco 칼럼 너비를 30% 증가
        final isMonthUnitForLargeScreen = widget.unit == 'month';
        if (isMonthUnitForLargeScreen) {
          baseDefaultColumnWidths['tefectivo'] = (102 * 1.3).roundToDouble(); // 102 * 1.3 = 133
          baseDefaultColumnWidths['tcredito'] = (102 * 1.3).roundToDouble(); // 102 * 1.3 = 133
          baseDefaultColumnWidths['tbanco'] = (102 * 1.3).roundToDouble(); // 102 * 1.3 = 133
          debugPrint('📊 [큰 화면] month 유닛: tefectivo, tcredito, tbanco 칼럼 너비 30% 증가 (102 -> 133)');
        }
        
        // ProductName은 항상 기본값 사용하도록 보장
        final defaultColumnWidths = widget.columnWidths ?? <String, double>{
          'ProductName': 225,
        };
        
        // ventas day/month/year 유닛인 경우 고정 픽셀 값 사용 (x 2 없이)
        final isVentasDayMonthYearForAdjustment = widget.reportType == ReportType.ventas && 
                                                   widget.unit != null && 
                                                   (widget.unit == 'day' || widget.unit == 'month' || widget.unit == 'year');
        
        debugPrint('🔍 [report_table_builder.dart:4979] 칼럼 너비 계산 (고정 픽셀 값 사용)');
        debugPrint('   → 라인: 4979');
        debugPrint('   → widget.reportType: ${widget.reportType}');
        debugPrint('   → widget.unit: ${widget.unit}');
        debugPrint('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
        debugPrint('   → _measuredColumnWidths != null: ${_measuredColumnWidths != null}');
        print('🔍 [report_table_builder.dart:4979] 칼럼 너비 계산 (고정 픽셀 값 사용)');
        print('   → 라인: 4979');
        print('   → widget.reportType: ${widget.reportType}');
        print('   → widget.unit: ${widget.unit}');
        print('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
        print('   → _measuredColumnWidths != null: ${_measuredColumnWidths != null}');
        
        // 최종 칼럼 너비 계산 (헤더와 데이터 테이블 모두 동일한 고정 픽셀 값 사용)
        Map<String, double> columnWidthsForHeader;
        
        if (isVentasDayMonthYearForAdjustment) {
          // ventas day/month/year 유닛인 경우 고정 픽셀 값 사용 (x 2 없이)
          final fixedWidths = <String, double>{};
          for (final key in widget.keys) {
            final keyLower = key.toLowerCase();
            final fixedWidth = baseDefaultColumnWidths[key] ?? 
                            baseDefaultColumnWidths[keyLower] ??
                            (keyLower == 'eventcount' ? baseDefaultColumnWidths['eventCount'] : null) ??
                            (keyLower == 'tvents' ? baseDefaultColumnWidths['tVents'] : null) ??
                            (keyLower == 'tventas' ? baseDefaultColumnWidths['tVentas'] : null) ??
                            (keyLower == 'tcntropas' ? baseDefaultColumnWidths['tCntRopas'] : null) ??
                            75.0;  // 기본값도 절반으로 줄임 (150 -> 75)
            
            fixedWidths[key] = fixedWidth;
            
            debugPrint('🔍 [report_table_builder.dart:5005] 고정 칼럼 너비 설정: key=$key, width=$fixedWidth');
            debugPrint('   → 라인: 5005');
            print('🔍 [report_table_builder.dart:5005] 고정 칼럼 너비 설정: key=$key, width=$fixedWidth');
            print('   → 라인: 5005');
          }
          columnWidthsForHeader = fixedWidths;
        } else {
          // 다른 보고서는 측정값 또는 기본값 사용
          debugPrint('🔍 [report_table_builder.dart:5011] 측정값 또는 기본값 사용');
          debugPrint('   → 라인: 5011');
          debugPrint('   → _measuredColumnWidths != null: ${_measuredColumnWidths != null}');
          debugPrint('   → widget.columnWidths != null: ${widget.columnWidths != null}');
          print('🔍 [report_table_builder.dart:5011] 측정값 또는 기본값 사용');
          print('   → 라인: 5011');
          print('   → _measuredColumnWidths != null: ${_measuredColumnWidths != null}');
          print('   → widget.columnWidths != null: ${widget.columnWidths != null}');
          columnWidthsForHeader = _measuredColumnWidths != null
              ? Map<String, double>.from(_measuredColumnWidths!)
              : Map<String, double>.from(widget.columnWidths ?? {});
        }
        
        // ProductName이 있으면 항상 기본값으로 교체
        columnWidthsForHeader['ProductName'] = baseDefaultColumnWidths['ProductName'] ?? 225.0;
        
        // 디버깅 정보 출력
        if (isVentasDayMonthYearForAdjustment) {
          debugPrint('🔍 [ventas day/month/year 고정 칼럼 너비]');
          debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYearForAdjustment');
          debugPrint('   → 고정 칼럼 너비: $columnWidthsForHeader');
          debugPrint('   → 각 키별 상세:');
          for (final key in widget.keys) {
            final fixedWidth = columnWidthsForHeader[key];
            debugPrint('     → $key: fixedWidth=$fixedWidth');
          }
          print('🔍 [ventas day/month/year 고정 칼럼 너비]');
          print('   → 고정 칼럼 너비: $columnWidthsForHeader');
        }
        
        debugPrint('   → 최종 columnWidthsForHeader: $columnWidthsForHeader');
        
        // constraints.maxWidth가 Infinity인 경우 ConstrainedBox를 사용하지 않음
        final hasValidWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0;
        // constraints.maxHeight가 bounded인지 확인 (Expanded 사용 가능 여부)
        final hasBoundedHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0;
        // 큰 화면인지 확인 (너비가 800 이상이면 큰 화면으로 간주)
        final isLargeScreen = constraints.maxWidth.isFinite && constraints.maxWidth >= 800;
        
        // 헤더와 푸터는 측정된 칼럼 너비 사용 (ProductName은 항상 기본값)
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [_ItemsTableWithMeasuredColumns] buildHeaderRow 호출 전');
        debugPrint('   → widget.keys: ${widget.keys}');
        debugPrint('   → widget.columns.length: ${widget.columns.length}');
        debugPrint('   → widget.sortColumn: ${widget.sortColumn}');
        debugPrint('   → widget.sortAscending: ${widget.sortAscending}');
        debugPrint('   → widget.onSort != null: ${widget.onSort != null}');
        debugPrint('   → columnWidthsForHeader: $columnWidthsForHeader');
        debugPrint('   → isLargeScreen: $isLargeScreen');
        
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [헤더 호출 전] 칼럼 너비 확인');
        debugPrint('   → columnWidthsForHeader: $columnWidthsForHeader');
        debugPrint('   → _measuredColumnWidths: $_measuredColumnWidths');
        debugPrint('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
        debugPrint('   → useMeasuredWidths: ${_measuredColumnWidths != null}');
        debugPrint('   → widget.keys: ${widget.keys}');
        debugPrint('   → 각 키별 칼럼 너비:');
        for (final key in widget.keys) {
          final headerWidth = columnWidthsForHeader[key];
          final measuredWidth = _measuredColumnWidths?[key];
          debugPrint('     → $key: headerWidth=$headerWidth, measuredWidth=$measuredWidth');
        }
        debugPrint('═══════════════════════════════════════════════════════');
        
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [report_table_builder.dart:5072] 헤더와 데이터 행 칼럼 너비 일치 확인');
        debugPrint('   → 라인: 5072');
        debugPrint('   → columnWidthsForHeader (헤더에 전달될 값): $columnWidthsForHeader');
        debugPrint('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
        debugPrint('   → useMeasuredWidths: ${_measuredColumnWidths != null}');
        debugPrint('   → 각 키별 헤더 칼럼 너비:');
        for (final key in widget.keys) {
          final headerWidth = columnWidthsForHeader[key];
          debugPrint('     → $key: $headerWidth');
        }
        debugPrint('   → ⚠️ [중요] 이 columnWidthsForHeader가 buildHeaderRow와 buildDataTable 모두에 전달됨');
        debugPrint('   → ⚠️ [중요] buildHeaderRow와 buildDataTable에서 동일한 columnWidths를 사용하는지 확인 필요');
        debugPrint('═══════════════════════════════════════════════════════');
        print('🔍 [report_table_builder.dart:5072] 헤더와 데이터 행 칼럼 너비 일치 확인');
        print('   → 라인: 5072');
        print('   → columnWidthsForHeader: $columnWidthsForHeader');
        print('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
        print('   → useMeasuredWidths: ${_measuredColumnWidths != null}');
        
        // ventas day/month/year 유닛인 경우 고정 픽셀 값을 사용하므로 useMeasuredWidths를 false로 설정
        // (고정 픽셀 값에 padding이 추가되어야 하므로)
        final useMeasuredWidthsForHeader = isVentasDayMonthYearForAdjustment 
            ? false  // 고정 픽셀 값 사용 시 padding 추가 필요
            : (_measuredColumnWidths != null);  // 다른 보고서는 측정값 사용
        
        debugPrint('🔍 [report_table_builder.dart:5106] useMeasuredWidthsForHeader 설정');
        debugPrint('   → 라인: 5106');
        debugPrint('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
        debugPrint('   → _measuredColumnWidths != null: ${_measuredColumnWidths != null}');
        debugPrint('   → useMeasuredWidthsForHeader: $useMeasuredWidthsForHeader');
        print('🔍 [report_table_builder.dart:5106] useMeasuredWidthsForHeader 설정');
        print('   → 라인: 5106');
        print('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
        print('   → useMeasuredWidthsForHeader: $useMeasuredWidthsForHeader');
        
        final headerRow = ReportTableBuilder.buildHeaderRow(
          widget.keys,
          widget.columns,
          widget.color,
          widget.sortColumn,
          widget.sortAscending,
          widget.onSort,
          columnWidths: columnWidthsForHeader,
          reportType: widget.reportType,
          unit: widget.unit,
          useMeasuredWidths: useMeasuredWidthsForHeader, // ventas day/month/year는 false, 다른 보고서는 측정값 사용
          isLargeScreen: isLargeScreen, // 대형 화면 여부 전달
        );
        
        debugPrint('🔍 [_ItemsTableWithMeasuredColumns] buildHeaderRow 호출 후');
        debugPrint('   → headerRow != null: ${headerRow != null}');
        debugPrint('   → ⚠️ [중복 확인] DataTable의 headingRowHeight가 0이어야 함');
        debugPrint('   → ⚠️ [정렬 확인] headerRow의 각 칼럼이 column.onSort를 사용해야 함');
        debugPrint('═══════════════════════════════════════════════════════');
        
        // MediaQuery를 사용하여 화면 높이 확인 (footer 고정을 위해)
        // 단, constraints.maxHeight가 bounded이면 그것을 우선 사용 (resumen이 있을 때 패널 높이 사용)
        final mediaQuery = MediaQuery.of(context);
        final screenHeight = mediaQuery.size.height;
        final availableHeight = screenHeight - mediaQuery.padding.top - mediaQuery.padding.bottom;
        
        // 오버랩 디버깅: 화면 너비와 테이블 총 너비 비교
        double totalTableWidth = 0.0;
        for (int i = 0; i < widget.keys.length; i++) {
          final key = widget.keys[i];
          final columnWidth = columnWidthsForHeader[key] ?? 150.0;
          totalTableWidth += columnWidth;
          if (i < widget.keys.length - 1) {
            totalTableWidth += 8; // columnSpacing
          }
        }
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [오버랩 디버깅] _ItemsTableWithMeasuredColumns build');
        debugPrint('   → 화면 너비 (constraints.maxWidth): ${constraints.maxWidth}');
        debugPrint('   → 테이블 총 너비 (계산): $totalTableWidth');
        debugPrint('   → 칼럼 개수: ${widget.keys.length}');
        debugPrint('   → 각 칼럼 너비:');
        double cumulativeX = 0.0;
        for (int i = 0; i < widget.keys.length; i++) {
          final key = widget.keys[i];
          final columnWidth = columnWidthsForHeader[key] ?? 150.0;
          debugPrint('      칼럼 #$i ($key): width=$columnWidth, x=$cumulativeX');
          cumulativeX += columnWidth;
          if (i < widget.keys.length - 1) {
            cumulativeX += 8; // columnSpacing
          }
        }
        if (hasValidWidth) { // if: hasValidWidth
          final overflow = totalTableWidth - constraints.maxWidth;
          if (overflow > 0) { // if: overflow > 0
            debugPrint('   ⚠️ 오버랩 발생! 테이블이 화면보다 ${overflow.toStringAsFixed(1)}px 더 넓음');
            debugPrint('   → 오버랩 비율: ${(overflow / constraints.maxWidth * 100).toStringAsFixed(1)}%');
          } else { // if (overflow > 0) - else
            debugPrint('   ✅ 오버랩 없음. 여유 공간: ${(-overflow).toStringAsFixed(1)}px');
          } // if (overflow > 0) - else 끝
        } else { // if (hasValidWidth) - else
          debugPrint('   ⚠️ 화면 너비가 unbounded (Infinity)');
        } // if (hasValidWidth) - else 끝
        debugPrint('═══════════════════════════════════════════════════════');
        
        // 테이블 내용 위젯 생성
        // hasBoundedHeight가 true이면 수직 스크롤 포함 (데스크톱/패널)
        // false이면 수직 스크롤 제거 (모바일, 부모의 SingleChildScrollView가 처리)
        final tableContent = Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _measureColumnWidths();
            });
            
            // tableContent 내부에서도 isLargeScreen을 계산 (Builder 내부이므로 constraints에 직접 접근 불가)
            final screenWidth = MediaQuery.of(context).size.width;
            final isLargeScreenForTable = screenWidth >= 800;
            
            final dataTable = Builder(
              key: _dataTableKey,
              builder: (context) {
                debugPrint('═══════════════════════════════════════════════════════');
                debugPrint('🔍 [_ItemsTableWithMeasuredColumns] buildDataTable 호출 전');
                debugPrint('   → widget.reportType: ${widget.reportType}');
                debugPrint('   → widget.columns.length: ${widget.columns.length}');
                debugPrint('   → ⚠️ [중복 확인] buildDataTable 내부에서 headingRowHeight가 0인지 확인 필요');
                debugPrint('   → ⚠️ [정렬 확인] buildDataTable에서 sortColumn/sortAscending이 null/false로 하드코딩되어 있는지 확인 필요');
                debugPrint('🔍 [_ItemsTableWithMeasuredColumns] buildDataTable 호출 - 정렬 파라미터 전달');
                debugPrint('   → widget.sortColumn: ${widget.sortColumn}');
                debugPrint('   → widget.sortAscending: ${widget.sortAscending}');
                debugPrint('   → ⚠️ [해결] sortColumn과 sortAscending을 buildDataTable에 전달');
                debugPrint('   → isLargeScreenForTable: $isLargeScreenForTable (칼럼 간격 조정용)');
                
                debugPrint('═══════════════════════════════════════════════════════');
                debugPrint('🔍 [report_table_builder.dart:5200] buildDataTable 호출 전 - 칼럼 너비 확인');
                debugPrint('   → 라인: 5200');
                debugPrint('   → columnWidthsForHeader (데이터 행에 전달될 값): $columnWidthsForHeader');
                debugPrint('   → _measuredColumnWidths: $_measuredColumnWidths');
                debugPrint('   → isLargeScreenForTable: $isLargeScreenForTable');
                debugPrint('   → widget.reportType: ${widget.reportType}');
                debugPrint('   → widget.unit: ${widget.unit}');
                debugPrint('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
                debugPrint('   → useMeasuredWidths: ${_measuredColumnWidths != null}');
                debugPrint('   → 각 키별 칼럼 너비 (헤더와 데이터 행이 동일해야 함):');
                for (final key in widget.keys) {
                  final headerWidth = columnWidthsForHeader[key];
                  final measuredWidth = _measuredColumnWidths?[key];
                  debugPrint('     → $key: headerWidth=$headerWidth, measuredWidth=$measuredWidth');
                }
                debugPrint('   → ⚠️ [중요] columnWidthsForHeader가 buildDataTable의 columnWidths 파라미터로 전달됨');
                debugPrint('   → ⚠️ [중요] buildDataTable 내부에서 _buildDataRowFromMap에 columnWidths 전달 확인 필요');
                debugPrint('   → ⚠️ [매칭 확인] 헤더와 데이터 행이 동일한 columnWidths를 사용하는지 확인');
                debugPrint('   → ⚠️ [매칭 확인] 헤더의 headerSizedBoxWidth = 데이터 행의 실제 칼럼 너비 (finalCellWidth + padding)');
                debugPrint('═══════════════════════════════════════════════════════');
                print('🔍 [report_table_builder.dart:5200] buildDataTable 호출 전 - 칼럼 너비 확인');
                print('   → 라인: 5200');
                print('   → columnWidthsForHeader: $columnWidthsForHeader');
                print('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
                print('   → useMeasuredWidths: ${_measuredColumnWidths != null}');
                
                // ventas day/month/year 유닛인 경우 고정 픽셀 값을 사용하므로 useMeasuredWidths를 false로 설정
                // (헤더와 동일하게 설정)
                final useMeasuredWidthsForData = isVentasDayMonthYearForAdjustment 
                    ? false  // 고정 픽셀 값 사용 시 padding 추가 필요
                    : (_measuredColumnWidths != null);  // 다른 보고서는 측정값 사용
                
                debugPrint('🔍 [report_table_builder.dart:5226] useMeasuredWidthsForData 설정');
                debugPrint('   → 라인: 5226');
                debugPrint('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
                debugPrint('   → _measuredColumnWidths != null: ${_measuredColumnWidths != null}');
                debugPrint('   → useMeasuredWidthsForData: $useMeasuredWidthsForData');
                print('🔍 [report_table_builder.dart:5226] useMeasuredWidthsForData 설정');
                print('   → 라인: 5226');
                print('   → isVentasDayMonthYearForAdjustment: $isVentasDayMonthYearForAdjustment');
                print('   → useMeasuredWidthsForData: $useMeasuredWidthsForData');
                
                final table = ReportTableBuilder.buildDataTable(
                  reportType: widget.reportType,
                  displayedList: widget.displayedList,
                  keys: widget.keys,
                  columns: widget.columns,
                  dataList: widget.dataList,
                  color: widget.color,
                  onRowDoubleTap: widget.onRowDoubleTap,
                  onRowTap: widget.onRowTap,
                  unit: widget.unit,
                  columnWidths: columnWidthsForHeader, // 헤더와 동일한 칼럼 너비 사용
                  sortColumn: widget.sortColumn,
                  sortAscending: widget.sortAscending,
                  isLargeScreen: isLargeScreenForTable, // 대형 화면 여부 전달 (칼럼 간격 조정용)
                  useMeasuredWidths: useMeasuredWidthsForData, // 헤더와 동일하게 설정
                );
                
                debugPrint('═══════════════════════════════════════════════════════');
                debugPrint('🔍 [report_table_builder.dart:5136] buildDataTable 호출 후');
                debugPrint('   → 라인: 5136');
                debugPrint('   → table != null: ${table != null}');
                debugPrint('   → ⚠️ [확인 필요] buildDataTable 내부에서 columnWidths가 _buildDataRowFromMap에 제대로 전달되었는지 확인');
                debugPrint('═══════════════════════════════════════════════════════');
                
                debugPrint('🔍 [_ItemsTableWithMeasuredColumns] buildDataTable 호출 후');
                debugPrint('   → dataTable != null: ${table != null}');
                debugPrint('   → ⚠️ [중복 확인] DataTable의 headingRowHeight가 0이면 헤더가 표시되지 않음');
                debugPrint('   → ⚠️ [중복 확인] headingRowHeight가 0이 아니면 별도 헤더와 중복될 수 있음');
                debugPrint('═══════════════════════════════════════════════════════');
                
                return table;
              },
            );
            
            // 수평 스크롤은 전체 Column에서 처리하므로 여기서는 제거
            // bounded height일 때만 수직 스크롤 포함 (데스크톱/패널)
            if (hasBoundedHeight) {
              return Scrollbar(
                controller: widget.scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  scrollDirection: Axis.vertical,
                  child: dataTable,
                ),
              );
            } else { // if (hasBoundedHeight) - else: 모바일
              // 모바일: 수직 스크롤 없이 반환 (부모의 SingleChildScrollView가 처리)
              return dataTable;
            } // if (hasBoundedHeight) - else 끝
          },
        );
        
        // 푸터 위젯 생성
        final footer = ReportTableBuilder.buildFixedTotalRow(
          widget.keys,
          widget.displayedList,
          widget.color,
          columnWidths: columnWidthsForHeader,
          dataList: widget.dataList,
          reportType: widget.reportType,
          unit: widget.unit,
        );
        
        // 항상 footer를 화면/패널 하단에 고정하기 위해 높이 제약 사용
        // hasBoundedHeight가 true이면 constraints.maxHeight 사용 (resumen이 있을 때 패널 높이)
        // 아니면 MediaQuery의 availableHeight 사용 (전체 화면 높이)
        final effectiveMaxHeight = hasBoundedHeight 
            ? constraints.maxHeight // if: hasBoundedHeight
            : (availableHeight > 0 ? availableHeight : double.infinity); // else: hasBoundedHeight
        
        debugPrint('🔍 [Footer 고정] 높이 계산');
        debugPrint('   → hasBoundedHeight: $hasBoundedHeight');
        debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
        debugPrint('   → availableHeight: $availableHeight');
        debugPrint('   → effectiveMaxHeight: $effectiveMaxHeight');
        
        // ventas day/month/year 유닛인지 확인
        final isVentasDayMonthYear = widget.reportType == ReportType.ventas && 
                                     widget.unit != null && 
                                     widget.unit != 'vcode';
        
        // 전체를 하나의 수평 스크롤 컨테이너로 감싸서 헤더, 테이블, footer가 함께 스크롤되도록 함
        // SingleChildScrollView 안의 Column은 무한 너비를 받으므로 crossAxisAlignment를 start로 설정하고 명시적 너비 설정
        // ventas day/month/year 유닛의 경우 대형 화면에서 전체 너비 사용
        // items/ingresos는 테이블 너비만 사용 (기존 동작 유지)
        final effectiveWidth = isVentasDayMonthYear && isLargeScreen && hasValidWidth
            ? constraints.maxWidth  // ventas day/month/year + 대형 화면: 전체 너비 사용
            : (totalTableWidth > 0 ? totalTableWidth : null);  // items/ingresos 또는 모바일: 테이블 너비 사용
        
        debugPrint('🔍 [너비 설정] _ItemsTableWithMeasuredColumns');
        debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
        debugPrint('   → isLargeScreen: $isLargeScreen');
        debugPrint('   → hasValidWidth: $hasValidWidth');
        debugPrint('   → totalTableWidth: $totalTableWidth');
        debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
        debugPrint('   → effectiveWidth: $effectiveWidth');
        
        final columnContent = SizedBox(
          height: (effectiveMaxHeight.isFinite && effectiveMaxHeight > 0 && hasBoundedHeight) 
              ? effectiveMaxHeight 
              : null,
          width: effectiveWidth, // ventas day/month/year + 대형 화면: 전체 너비, 그 외: 테이블 너비
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 무한 너비 문제 해결
            mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
            children: [
              // 헤더
              if (headerRow != null) headerRow,
              // 테이블 내용 (hasBoundedHeight일 때만 Expanded 사용)
              hasBoundedHeight
                  ? Expanded(child: tableContent)
                  : tableContent, // Expanded 없이 직접 표시
              // 푸터 (화면 하단에 고정)
              if (widget.horizontalScrollController != null)
                SingleChildScrollView(
                  controller: widget.horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: effectiveWidth ?? totalTableWidth, // ventas day/month/year + 대형 화면: 전체 너비
                    child: footer,
                  ),
                )
              else
                footer,
            ],
          ),
        );
        
        // 전체를 하나의 수평 스크롤 컨테이너로 감싸기 (헤더, 테이블, footer 동기화)
        // horizontalScrollController가 있으면 항상 SingleChildScrollView로 감싸서 헤더와 테이블이 함께 스크롤되도록 함
        // ventas day/month/year 유닛 + 대형 화면의 경우 테이블이 화면보다 작으면 스크롤이 필요 없지만,
        // 헤더와 테이블이 함께 움직이도록 하기 위해 항상 SingleChildScrollView로 감싸기
        final needsHorizontalScroll = widget.horizontalScrollController != null;
        
        debugPrint('🔍 [수평 스크롤] _ItemsTableWithMeasuredColumns');
        debugPrint('   → needsHorizontalScroll: $needsHorizontalScroll (항상 true로 설정하여 헤더와 테이블이 함께 스크롤되도록 함)');
        debugPrint('   → horizontalScrollController != null: ${widget.horizontalScrollController != null}');
        debugPrint('   → isVentasDayMonthYear: $isVentasDayMonthYear');
        debugPrint('   → isLargeScreen: $isLargeScreen');
        debugPrint('   → totalTableWidth > constraints.maxWidth: ${totalTableWidth > constraints.maxWidth}');
        
        // horizontalScrollController가 있으면 항상 SingleChildScrollView로 감싸서 헤더와 테이블이 함께 스크롤되도록 함
        final horizontallyScrollableContent = needsHorizontalScroll
            ? SingleChildScrollView( // if: horizontalScrollController가 있으면 항상 SingleChildScrollView로 감싸기
                scrollDirection: Axis.horizontal,
                controller: widget.horizontalScrollController,
                child: columnContent, // columnContent는 이미 적절한 너비를 가지고 있음 (헤더, 테이블, 푸터가 모두 포함됨)
              ) // SingleChildScrollView 끝 - if: horizontalScrollController가 있음
            : columnContent; // else: horizontalScrollController가 없으면 그대로 반환
        
        debugPrint('🔍 [큰 화면 디버깅] 최종 위젯 구조');
        debugPrint('   → hasValidWidth: $hasValidWidth');
        debugPrint('   → hasBoundedHeight: $hasBoundedHeight');
        debugPrint('   → isLargeScreen: $isLargeScreen');
        debugPrint('   → effectiveMaxHeight: $effectiveMaxHeight');
        debugPrint('   → headerRow != null: ${headerRow != null}');
        debugPrint('   → footer != null: ${footer != null}');
        debugPrint('   → tableContent != null: ${tableContent != null}');
        debugPrint('   → horizontallyScrollableContent 타입: ${horizontallyScrollableContent.runtimeType}');
        
        // constraints.maxWidth가 유효한 경우에만 외부 너비 제약 설정
        // SingleChildScrollView가 있으면 내부는 스크롤 가능하므로 외부만 제약
        // ventas day/month/year 유닛 + 대형 화면의 경우 전체 너비를 사용하므로 ConstrainedBox로 제약
        // 하지만 헤더와 테이블이 함께 스크롤되도록 하기 위해 항상 SingleChildScrollView를 사용하므로,
        // ventas day/month/year + 대형 화면인 경우에도 ConstrainedBox로 제약하여 전체 너비 사용
        final finalWidget = hasValidWidth && (isVentasDayMonthYear && isLargeScreen)
            ? ConstrainedBox( // if: hasValidWidth이고 ventas day/month/year + 대형 화면
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                ),
                child: horizontallyScrollableContent,
              ) // ConstrainedBox 끝 - if: hasValidWidth
            : horizontallyScrollableContent; // else: 그 외의 경우는 제약 없이 (스크롤 가능)
        
        debugPrint('   → finalWidget 타입: ${finalWidget.runtimeType}');
        debugPrint('═══════════════════════════════════════════════════════');
        
        return finalWidget;
      },
    );
  }
}

