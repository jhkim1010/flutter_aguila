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
      
      final isDayMonthYearUnit = unit != null && unit != 'vcode';
      final isDayUnit = unit == 'day';
      final isMonthUnit = unit == 'month';
      
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
    debugPrint('🔍 [${reportType.name}] buildTableFromList 시작');
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
      
      // 첫 번째 항목으로 데이터 구조 확인
      final firstItem = displayedList.isNotEmpty && displayedList.first is Map<String, dynamic>
          ? displayedList.first as Map<String, dynamic>
          : <String, dynamic>{};
      
      // unit 파라미터가 없을 때만 데이터 구조로 판단
      bool finalIsDayMonthYearUnit = isDayMonthYearUnit;
      if (unit == null) {
        // day/month/year unit 필드가 있는지 확인 (첫 번째 항목 기준)
        final hasDayMonthYearFields = firstItem.containsKey('tVents') || 
                                      firstItem.containsKey('tVentas') || 
                                      firstItem.containsKey('eventCount') ||
                                      firstItem.containsKey('tCntRopas');
        
        // vcode unit 필드가 있는지 확인 (첫 번째 항목 기준)
        final hasVcodeFields = firstItem.containsKey('vcode') || 
                               firstItem.containsKey('tpago') || 
                               firstItem.containsKey('cntropas') ||
                               firstItem.containsKey('d_num_caja') ||
                               firstItem.containsKey('d_num_terminal') ||
                               firstItem.containsKey('clientenombre');
        
        // day/month/year unit이 명확히 감지되고 vcode 필드가 없을 때만 day/month/year 컬럼 사용
        finalIsDayMonthYearUnit = hasDayMonthYearFields && !hasVcodeFields;
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
      // 기타
      'start_date': 120,
      'end_date': 120,
    };
    
    final columns = keys.asMap().entries.map((entry) {
      final index = entry.key;
      final key = entry.value;
      final isSorted = sortColumn == key;
      final isSortable = (reportType == ReportType.items || reportType == ReportType.ingresos) && 
          (key == 'codigo' || key == 'codigo1' || key == 'descripcion' || key == 'desc1' || 
           key == 'tprendas' || key == 'timporte' || key == 'tIngreso' || key == 'tingreso' ||
           key == 'tevent' || key == 'tcant' || key == 'cntEvent' || key == 'cntevent') ||
          reportType == ReportType.ventas || // ventas 보고서는 모든 컬럼 정렬 가능
          reportType == ReportType.clientes; // clientes 보고서는 모든 컬럼 정렬 가능
      
      return DataColumn(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              key.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: reportType == ReportType.ventas ? 12 : 14,
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
                // DataTable이 전달하는 columnIndex는 columns 리스트의 인덱스이므로
                // keys 리스트의 인덱스와 동일합니다
                onSort(columnIndex, ascending);
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
    
    // items 및 ingresos 보고서는 LayoutBuilder로 전체 폭 강제 (먼저 처리)
    if (isItemsOrIngresos) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📊 [ReportTableBuilder:600] buildTableFromList - Items/Ingresos 모드 진입 (조기 처리)');
      debugPrint('   → 파일: report_table_builder.dart');
      debugPrint('   → 라인: 600');
      debugPrint('   → reportType: $reportType');
      debugPrint('   → isItemsOrIngresos: $isItemsOrIngresos');
      
      debugPrint('✅ [Items/Ingresos 체크] 조건 통과 - items/ingresos 전용 경로 실행');
      debugPrint('   → reportType: $reportType');
      debugPrint('   → isItemsOrIngresos: $isItemsOrIngresos');
      
      // DataTable의 실제 칼럼 너비를 측정하여 헤더와 푸터에 적용하기 위한 StatefulWidget
      return _ItemsTableWithMeasuredColumns(
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
                      // ventas/clientes/fventas는 별도 헤더 행을 사용하지 않음 (DataTable의 headingRowHeight가 0)
                      // 하지만 수평 스크롤이 있는 경우 별도 헤더가 필요할 수 있음
                      final isVentasOrClientesOrFventas = reportType == ReportType.ventas || 
                                                          reportType == ReportType.clientes || 
                                                          reportType == ReportType.fventas;
                      
                      // 핸드폰 화면 구성 정보 확인
                      final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
                      final isMobilePhone = layoutInfo.isMobilePhone;
                      final isMobilePhonePortrait = layoutInfo.isMobilePhonePortrait;
                      final isMobilePhoneLandscape = layoutInfo.isMobilePhoneLandscape;
                      
                      debugPrint('═══════════════════════════════════════════════════════');
                      debugPrint('📱 [Ventas 헤더 디버깅] 헤더 생성 시작');
                      debugPrint('   → reportType: $reportType');
                      debugPrint('   → isVentasOrClientesOrFventas: $isVentasOrClientesOrFventas');
                      debugPrint('   → isMobilePhone: $isMobilePhone');
                      debugPrint('   → isMobilePhonePortrait: $isMobilePhonePortrait');
                      debugPrint('   → isMobilePhoneLandscape: $isMobilePhoneLandscape');
                      debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
                      debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
                      debugPrint('   → keys.length: ${keys.length}');
                      debugPrint('   → columns.length: ${columns.length}');
                      debugPrint('   → horizontalScrollController: ${horizontalScrollController != null}');
                      
                      final headerRow = isVentasOrClientesOrFventas
                          ? null 
                          : buildHeaderRow(keys, columns, color, sortColumn, sortAscending, onSort, columnWidths: columnWidths, reportType: reportType);
                      
                      // ventas 보고서 디버깅 (핸드폰에서 헤더가 안 보이는 문제 분석)
                      if (reportType == ReportType.ventas) {
                        debugPrint('═══════════════════════════════════════════════════════');
                        debugPrint('📱 [Ventas Report] 헤더 처리 디버깅');
                        debugPrint('   → keys.length: ${keys.length}');
                        debugPrint('   → keys: $keys');
                        debugPrint('   → displayedList.length: ${displayedList.length}');
                        debugPrint('   → headerRow: ${headerRow != null ? "생성됨" : "null (ventas는 별도 헤더 없음)"}');
                        debugPrint('   → horizontalScrollController: ${horizontalScrollController != null}');
                        debugPrint('   → isMobilePhone: $isMobilePhone');
                        debugPrint('   → isMobilePhonePortrait: $isMobilePhonePortrait');
                        debugPrint('   → isMobilePhoneLandscape: $isMobilePhoneLandscape');
                        debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
                        debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
                        debugPrint('   ⚠️ [문제] ventas는 headerRow가 null이므로 별도 헤더가 표시되지 않음');
                        debugPrint('   ⚠️ [문제] DataTable의 headingRowHeight가 0으로 설정되어 있음');
                        debugPrint('   ⚠️ [문제] 핸드폰에서 헤더가 안 보이는 원인: 별도 헤더 행이 없고 DataTable 헤더도 숨겨져 있음');
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
                                if (horizontalScrollController != null)
                                  return SingleChildScrollView(
                                    controller: horizontalScrollController,
                                    scrollDirection: Axis.horizontal,
                                    physics: const NeverScrollableScrollPhysics(),
                                    child: headerRow,
                                  );
                                else
                                  return headerRow;
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
                                  columnWidths: columnWidths,
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
                                };
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
                                columnWidths: columnWidths,
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
      };
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
    
    return SingleChildScrollView(
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
  }) {
    // 디버깅: 괄호/구문 오류 확인을 위한 로깅
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [구문 검사] buildDataTable 함수 시작');
    debugPrint('   → 파일: report_table_builder.dart');
    debugPrint('   → 라인: ${1788}');
    debugPrint('   → 함수명: buildDataTable');
    debugPrint('   → 파라미터 개수: 10');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → displayedList.length: ${displayedList.length}');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columns.length: ${columns.length}');
    debugPrint('   → dataList.length: ${dataList.length}');
    debugPrint('   → columnWidths: ${columnWidths != null}');
    debugPrint('   → unit: $unit');
    debugPrint('   → onRowDoubleTap: ${onRowDoubleTap != null}');
    debugPrint('   → onRowTap: ${onRowTap != null}');
    
    // 디버깅: 괄호 균형 확인
    _checkBracketBalance('buildDataTable', 1788);
    
    // sortColumn과 sortAscending은 buildTableFromList에서 전달받아야 하는데,
    // buildDataTable에서는 직접 접근할 수 없으므로 파라미터로 받아야 합니다.
    // 하지만 현재 구조에서는 buildTableFromList에서만 사용되므로,
    // buildDataTable 내부에서 null로 처리합니다.
    String? sortColumn;
    bool sortAscending = false;
    
    // 디버깅: sortColumn과 sortAscending 확인
    debugPrint('   → sortColumn: $sortColumn');
    debugPrint('   → sortAscending: $sortAscending');
    
    // alertas 보고서는 Table 위젯 사용
    if (reportType == ReportType.alertas) {
      debugPrint('   → [Alertas] Table 위젯 사용');
      // Table 위젯을 사용하는 코드는 buildTableFromList에 있으므로,
      // 여기서는 DataTable을 사용합니다.
    }
    
    // ============================================================
    // 📱 Ventas 테이블 헤더 디버깅 - 핸드폰에서 헤더가 안 보이는 문제 분석
    // ============================================================
    // ventas 보고서는 headingRowHeight가 0으로 설정되어 있어서 DataTable의 기본 헤더가 숨겨짐
    // 별도 헤더 행이 필요하지만 현재는 null로 설정되어 있음
    final isVentas = reportType == ReportType.ventas;
    final headingRowHeight = isVentas ? 0.0 : 56.0;
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📱 [Ventas DataTable] buildDataTable 호출');
    debugPrint('   → reportType: $reportType');
    debugPrint('   → isVentas: $isVentas');
    debugPrint('   → headingRowHeight: $headingRowHeight (ventas는 0으로 설정됨)');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columns.length: ${columns.length}');
    debugPrint('   → displayedList.length: ${displayedList.length}');
    debugPrint('   ⚠️ [문제] ventas는 headingRowHeight가 0이므로 DataTable 헤더가 표시되지 않음');
    debugPrint('   ⚠️ [문제] 별도 헤더 행(headerRow)도 null이므로 헤더가 전혀 표시되지 않음');
    debugPrint('═══════════════════════════════════════════════════════');
    
    return DataTable(
      columnSpacing: reportType == ReportType.alertas ? 1 : 8,
      dataRowMinHeight: reportType == ReportType.alertas ? 72 : 48,
      dataRowMaxHeight: reportType == ReportType.alertas ? 84 : 56,
      headingRowHeight: headingRowHeight,
      headingRowColor: MaterialStateProperty.all(Colors.transparent),
      sortColumnIndex: sortColumn != null && keys.contains(sortColumn) 
          ? keys.indexOf(sortColumn) 
          : null,
      sortAscending: sortAscending,
      columns: columns,
      rows: displayedList.map((item) {
        // 디버깅: DataRow 생성 시작
        debugPrint('   → [buildDataTable] DataRow 생성 - item 타입: ${item.runtimeType}');
        
        if (item is Map<String, dynamic>) {
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
            
            // alertas 보고서는 내용이 잘리지 않도록 설정
            if (reportType == ReportType.alertas) {
              final cellWidth = columnWidths?[key] ?? 150.0;
              
              final cellWidget = Align(
                alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  formattedValue,
                  style: const TextStyle(fontSize: 14),
                  maxLines: null,
                  overflow: TextOverflow.visible,
                ),
              );
              
              return DataCell(
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: cellWidth,
                    maxWidth: cellWidth,
                  ),
                  child: cellWidget,
                ),
              );
            } else {
              // 다른 보고서는 기본 DataCell 사용
              return DataCell(
                Align(
                  alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    formattedValue,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }
          }).toList();
          
          // 셀 개수 확인
          assert(cells.length == keys.length, 
            'Row cells count (${cells.length}) must match keys count (${keys.length})');
          
          return DataRow(cells: cells);
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
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            );
          });
          
          return DataRow(cells: cells);
        }
      }).toList(),
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
    rows.addAll(displayedList.map((item) {
      debugPrint('   → [데이터 행 생성] item 타입: ${item.runtimeType}');
      if (item is Map<String, dynamic>) {
        debugPrint('   → [데이터 행 생성] Map 타입 - _buildDataRowFromMap 호출');
        return _buildDataRowFromMap(
          item: item,
          keys: keys,
          reportType: reportType,
          onRowDoubleTap: onRowDoubleTap,
          onRowTap: onRowTap,
          unit: unit,
          columnWidths: columnWidths,
        );
      } else {
        debugPrint('   → [데이터 행 생성] Map이 아닌 타입 - _buildDataRowFromNonMap 호출');
        return _buildDataRowFromNonMap(
          item: item,
          keys: keys,
          reportType: reportType,
          columnWidths: columnWidths,
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
  }) {
    // 디버깅: 함수 진입 확인
    debugPrint('   → [구문 검사] _buildDataRowFromMap 함수 시작');
    debugPrint('      → 파일: report_table_builder.dart');
    debugPrint('      → 라인: ${2037}');
    debugPrint('      → 함수명: _buildDataRowFromMap');
    debugPrint('      → 파라미터 개수: 7');
    debugPrint('      → reportType: $reportType');
    debugPrint('      → keys.length: ${keys.length}');
    debugPrint('      → item.keys.length: ${item.keys.length}');
    debugPrint('      → columnWidths 전달됨: ${columnWidths != null}');
    debugPrint('      → onRowDoubleTap: ${onRowDoubleTap != null}');
    debugPrint('      → onRowTap: ${onRowTap != null}');
    debugPrint('      → unit: $unit');
    
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
      
      // items/ingresos/alertas 보고서는 각 셀의 너비를 설정하여 헤더와 일치시킴
      if (isItemsOrIngresos || isAlertas) {
        final columnWidth = finalColumnWidths[key] ?? 150.0;
        // alertas 보고서는 padding을 최소화하여 내용이 더 넓게 보이도록 설정
        if (isAlertas) {
          debugPrint('🔍 [Alertas _buildDataRowFromMap] DataCell 생성 - key: $key, columnWidth: $columnWidth, padding: 최소화');
          // cell.child가 Align인 경우 Align의 child를 SizedBox로 감싸기 (Padding 제거)
          if (cell.child is Align) {
            final align = cell.child as Align;
            debugPrint('   → cell.child는 Align 타입');
            return DataCell(
              SizedBox(
                    width: columnWidth,
                child: Align(
                  alignment: align.alignment,
                  child: align.child,
                ),
              ),
            );
          }
          // cell.child가 다른 타입인 경우 SizedBox로 감싸기 (Padding 제거)
          debugPrint('   → cell.child는 ${cell.child.runtimeType} 타입');
          return DataCell(
            SizedBox(
              width: columnWidth,
              child: cell.child,
            ),
          );
        }
        // items/ingresos 보고서는 기존대로
        // cell.child가 Align인 경우 Align의 child를 SizedBox로 감싸기
        if (cell.child is Align) {
          final align = cell.child as Align;
          return DataCell(
            SizedBox(
              width: columnWidth,
              child: Align(
                alignment: align.alignment,
                child: align.child,
              ),
            ),
          );
        }
        // cell.child가 다른 타입인 경우 그대로 SizedBox로 감싸기
        return DataCell(
          SizedBox(
            width: columnWidth,
            child: cell.child,
          ),
        );
      }
      
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
              fontSize: reportType == ReportType.ventas ? 12 : 14,
              height: reportType == ReportType.ventas ? 1.0 : 1.2,
            ),
          ),
        ),
      );
    });
    
    debugPrint('   → [구문 검사] _buildDataRowFromNonMap 함수 종료');
    debugPrint('      → 반환 cells.length: ${cells.length}');
    
    return DataRow(cells: cells);
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
    
    return DataCell(
      Align(
        alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
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
                  fontSize: reportType == ReportType.ventas ? 12 : 14,
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
      
      if (cell.child is Align) {
        final align = cell.child as Align;
        // clientes 보고서는 항상 onTap 설정, ventas 보고서는 vcode 단위일 때만
        final shouldAddOnTap = onRowTap != null && 
            (reportType == ReportType.clientes || 
             (reportType == ReportType.ventas && unit == 'vcode'));
        
        debugPrint('   → [제스처 추가] Align 타입 셀 처리');
        debugPrint('      → shouldAddOnTap: $shouldAddOnTap');
        debugPrint('      → onRowDoubleTap != null: ${onRowDoubleTap != null}');
        
        return DataCell(
          GestureDetector(
            onTap: shouldAddOnTap ? () {
              debugPrint('🔍 [report_table_builder] _addGesturesToCells - 단일클릭 감지됨!');
              debugPrint('→ reportType: $reportType');
              debugPrint('→ unit: $unit');
              onRowTap!(item);
            } : null,
            onDoubleTap: onRowDoubleTap != null ? () {
              debugPrint('🔍 [report_table_builder] _addGesturesToCells - 더블클릭 감지됨!');
              debugPrint('→ reportType: $reportType');
              onRowDoubleTap!(item);
            } : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              alignment: align.alignment,
              child: align.child,
            ),
          ),
        );
      }
      
      debugPrint('   → [제스처 추가] Align이 아닌 셀 - 그대로 반환');
      return cell;
    }).toList();
  }

  // 고정된 합계 행 빌드 (화면 하단에 고정, 현재 보이는 항목들의 합계)
  static Widget buildFixedTotalRow(List<String> keys, List<dynamic> displayedList, Color reportColor, {Map<String, double>? columnWidths, List<dynamic>? dataList, ReportType? reportType, double? explicitWidth}) {
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
    
    final finalColumnWidths = columnWidths ?? defaultColumnWidths;
    
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
    
    double footerCumulativeX = 0.0;
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final columnWidth = finalColumnWidths[key] ?? 150.0;
      debugPrint('   → [푸터] 칼럼 #$i: key="$key", width=$columnWidth, x=$footerCumulativeX, padding=$footerPadding (alertas: $isAlertas)');
      footerCumulativeX += columnWidth;
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
            final columnWidth = finalColumnWidths[key] ?? 150.0;
            
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
            
            return [
              SizedBox(
                width: columnWidth,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 테이블 행 높이에 맞춰 vertical: 8로 조정 (32-37 높이)
                  height: footerHeight, // items/ingresos는 37, 다른 보고서는 56
                  child: shouldShowTotalCount && totalCount != null
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Total: $totalCount',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : total != null
                          ? Align(
                              alignment: isNumericColumn ? Alignment.centerRight : Alignment.centerLeft, // 숫자 칼럼은 오른쪽 정렬
                              child: Text(
                                ReportUtils.formatValue(total),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
              ),
              // 마지막 칼럼이 아니면 columnSpacing(8px) 추가
              if (index < keys.length - 1) const SizedBox(width: 8),
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
  }) {
    // 디버깅: 함수 진입 확인 (가장 먼저 실행)
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [_buildHeaderRow] 함수 진입');
    debugPrint('   → keys: $keys');
    debugPrint('   → keys.length: ${keys.length}');
    debugPrint('   → columns.length: ${columns.length}');
    debugPrint('   → columnWidths 전달됨: ${columnWidths != null}');
    
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
      'sucursal': 50, // 100 -> 50 (절반)
    };
    
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
    final headerColumnSpacing = isAlertas ? 1 : 8; // alertas는 1, 다른 보고서는 8
    final headerPadding = isAlertas ? 1 : 16; // alertas는 1, 다른 보고서는 16
    
    double headerCumulativeX = 0.0;
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final columnWidth = finalColumnWidths[key] ?? 150.0;
      debugPrint('   → [헤더] 칼럼 #$i: key="$key", width=$columnWidth, x=$headerCumulativeX, padding=$headerPadding (alertas: $isAlertas)');
      headerCumulativeX += columnWidth;
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
          
          final columnWidth = finalColumnWidths[key] ?? 150.0;
          
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
                                   key == 'sucursal');
          
          return [
            SizedBox(
              width: columnWidth,
              child: InkWell(
                onTap: column.onSort != null
                    ? () {
                        if (isSorted) {
                          column.onSort!(index, !sortAscending);
                        } else {
                          column.onSort!(index, false); // 첫 클릭 시 내림차순
                        }
                      }
                    : null,
                child: Container(
                  // DataTable의 DataCell은 기본적으로 horizontal padding이 16이므로, 헤더도 동일하게 맞춤
                  // Container의 padding을 0으로 설정하고, 내부에 Padding 위젯을 사용하여 DataTable과 동일한 구조로 만듦
                  // alertas 보고서는 padding을 1로 설정
                  padding: EdgeInsets.zero,
                  height: (reportType == ReportType.items || reportType == ReportType.ingresos) ? 37 : 56, // items/ingresos는 37, 다른 보고서는 56
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isAlertas ? 1 : 16, vertical: 8), // alertas는 1, 다른 보고서는 16
                    child: Align(
                      alignment: isNumericHeader ? Alignment.centerRight : Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: isNumericHeader ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              labelText,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: isNumericHeader ? TextAlign.right : TextAlign.left,
                            ),
                          ),
                          if (isSorted && column.onSort != null)
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
            // 마지막 칼럼이 아니면 columnSpacing 추가 (alertas는 1, 다른 보고서는 8)
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
                  fontSize: isVentas ? 12 : 14,
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
  });

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

  void _measureColumnWidths() {
    // 이미 측정이 완료되었으면 다시 측정하지 않음
    if (_hasMeasured) {
      debugPrint('   → [측정] 이미 측정 완료됨. 재측정 건너뜀');
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
      debugPrint('   ⚠️ [측정] 첫 번째 데이터 행을 찾을 수 없습니다');
      return;
    }

    // 기본 칼럼 너비 (최대값 제한용)
    final defaultColumnWidths = widget.columnWidths ?? <String, double>{
      'codigo1': 200,  // codigo1 칼럼 너비 증가 (150 -> 200)
      'desc1': 300,
      'ProductName': 450,  // ProductName 칼럼 너비 유지
      'totalCantidad': 150,
      'CategoryCode': 120,
      'CompanyCode': 120,
      'tprendas': 120,
      'timporte': 150,
    };
    
    // 칼럼별 최대 너비 제한
    final maxColumnWidths = <String, double>{};
    for (final key in widget.keys) {
      final defaultWidth = defaultColumnWidths[key] ?? 150.0;
      // ProductName은 기본값을 유지하거나 최대 500px로 제한
      if (key == 'ProductName') {
        maxColumnWidths[key] = 500.0;
      } else {
        // 다른 칼럼은 기본값의 1.3배를 최대값으로 설정
        maxColumnWidths[key] = defaultWidth * 1.3;
      }
    }
    
    // 첫 번째 데이터 행의 각 칼럼 너비 측정
    for (int i = 0; i < widget.keys.length; i++) {
      final cellBox = tableChildren[dataRowStartIndex + i];
      final key = widget.keys[i];
      final measuredWidth = cellBox.size.width;
      
      // ProductName은 측정값을 사용하지 않고 항상 기본값 사용
      final defaultWidth = defaultColumnWidths[key] ?? 150.0;
      final maxWidth = maxColumnWidths[key] ?? (defaultWidth * 1.3);
      
      double finalWidth;
      if (key == 'ProductName') {
        // ProductName은 항상 기본값(450px) 사용 (측정값 무시)
        finalWidth = defaultWidth;
      } else {
        // 다른 칼럼은 측정값이 최대값을 초과하면 기본값 사용
        finalWidth = measuredWidth > maxWidth ? defaultWidth : measuredWidth;
      }
      
      measuredWidths[key] = finalWidth;
      debugPrint('   → [측정] 칼럼 #$i: key="$key", 측정 width=$measuredWidth, 최종 width=$finalWidth (기본: $defaultWidth, 최대: $maxWidth)');
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
        debugPrint('   → [측정 완료] 칼럼 너비: $finalMeasuredWidths (ProductName은 기본값 사용)');
      } else {
        // 변경이 없어도 측정은 완료된 것으로 간주
        _hasMeasured = true;
        debugPrint('   → [측정] 칼럼 너비 변경 없음 (무시, 측정 완료)');
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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        debugPrint('🔍 [큰 화면 디버깅] LayoutBuilder constraints');
        debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
        debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
        debugPrint('   → constraints.minWidth: ${constraints.minWidth}');
        debugPrint('   → constraints.minHeight: ${constraints.minHeight}');
        
        // ProductName은 항상 기본값 사용하도록 보장
        final defaultColumnWidths = widget.columnWidths ?? <String, double>{
          'ProductName': 450,
        };
        final columnWidthsForHeader = _measuredColumnWidths != null
            ? Map<String, double>.from(_measuredColumnWidths!)
            : Map<String, double>.from(widget.columnWidths ?? {});
        // ProductName이 있으면 항상 기본값으로 교체
        if (columnWidthsForHeader.containsKey('ProductName')) {
          columnWidthsForHeader['ProductName'] = defaultColumnWidths['ProductName'] ?? 450.0;
        } else {
          columnWidthsForHeader['ProductName'] = defaultColumnWidths['ProductName'] ?? 450.0;
        }
        
        debugPrint('   → columnWidthsForHeader: $columnWidthsForHeader');
        
        // 헤더와 푸터는 측정된 칼럼 너비 사용 (ProductName은 항상 기본값)
        final headerRow = ReportTableBuilder.buildHeaderRow(
          widget.keys,
          widget.columns,
          widget.color,
          widget.sortColumn,
          widget.sortAscending,
          widget.onSort,
          columnWidths: columnWidthsForHeader,
          reportType: widget.reportType,
        );

        // constraints.maxWidth가 Infinity인 경우 ConstrainedBox를 사용하지 않음
        final hasValidWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0;
        // constraints.maxHeight가 bounded인지 확인 (Expanded 사용 가능 여부)
        final hasBoundedHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0;
        // 큰 화면인지 확인 (너비가 800 이상이면 큰 화면으로 간주)
        final isLargeScreen = constraints.maxWidth.isFinite && constraints.maxWidth >= 800;
        
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
            
            final dataTable = Builder(
              key: _dataTableKey,
              builder: (context) {
                return ReportTableBuilder.buildDataTable(
                  reportType: widget.reportType,
                  displayedList: widget.displayedList,
                  keys: widget.keys,
                  columns: widget.columns,
                  dataList: widget.dataList,
                  color: widget.color,
                  onRowDoubleTap: widget.onRowDoubleTap,
                  onRowTap: widget.onRowTap,
                  unit: widget.unit,
                  columnWidths: columnWidthsForHeader,
                );
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
        
        // 전체를 하나의 수평 스크롤 컨테이너로 감싸서 헤더, 테이블, footer가 함께 스크롤되도록 함
        // SingleChildScrollView 안의 Column은 무한 너비를 받으므로 crossAxisAlignment를 start로 설정하고 명시적 너비 설정
        // 모든 경우에 SizedBox로 감싸서 명시적 너비 설정 (무한 너비 문제 해결)
        final columnContent = SizedBox(
          height: (effectiveMaxHeight.isFinite && effectiveMaxHeight > 0 && hasBoundedHeight) 
              ? effectiveMaxHeight 
              : null,
          width: totalTableWidth > 0 ? totalTableWidth : null, // 명시적 너비 설정 (무한 너비 방지)
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
                    width: totalTableWidth,
                    child: footer,
                  ),
                )
              else
                footer,
            ],
          ),
        );
        
        // 전체를 하나의 수평 스크롤 컨테이너로 감싸기 (헤더, 테이블, footer 동기화)
        // horizontalScrollController가 있으면 SingleChildScrollView로 감싸기
        // SingleChildScrollView 안의 child는 너비 제약을 받지 않아야 하므로 columnContent를 직접 사용
        final horizontallyScrollableContent = widget.horizontalScrollController != null
            ? SingleChildScrollView( // if: horizontalScrollController가 있음
                scrollDirection: Axis.horizontal,
                controller: widget.horizontalScrollController,
                child: columnContent, // columnContent는 이미 적절한 너비를 가지고 있음
              ) // SingleChildScrollView 끝 - if: horizontalScrollController
            : columnContent; // else: horizontalScrollController 없음
        
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
        final finalWidget = hasValidWidth && widget.horizontalScrollController == null
            ? ConstrainedBox( // if: hasValidWidth이고 horizontalScrollController가 없음 (스크롤 없을 때만 제약)
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                ),
                child: horizontallyScrollableContent,
              ) // ConstrainedBox 끝 - if: hasValidWidth
            : horizontallyScrollableContent; // else: horizontalScrollController가 있으면 제약 없이 (스크롤 가능)
        
        debugPrint('   → finalWidget 타입: ${finalWidget.runtimeType}');
        debugPrint('═══════════════════════════════════════════════════════');
        
        return finalWidget;
      },
    );
  }
}

