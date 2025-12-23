import 'package:flutter/material.dart';
import 'report_utils.dart';
import '../services/config_service.dart';

class ReportTableBuilder {
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
    if (dataList.isEmpty) {
      return const Center(child: Text('No hay datos'));
    }

    final displayedList = dataList.take(displayedItemsCount).toList();
    final totalCount = dataList.length;
    final color = reportColor ?? ReportUtils.getReportColor(reportType);
    

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
    final columnWidths = <String, double>{
      // Items 보고서
      'codigo1': 150,
      'desc1': 300,
      'tprendas': 120,
      'timporte': 150,
      // Ingresos 보고서
      'codigo': 150,
      'descripcion': 300,
      'tevent': 120,
      'tcant': 150,
      'tIngreso': 150,
      'tingreso': 150,
      'cntEvent': 120,
      'cntevent': 120,
      // Alertas 보고서
      'fecha': 120,
      'hora': 100,
      'evento': 500, // 긴 텍스트를 위해 충분한 너비 할당
      'progname': 150,
      'alerta': 80,
      'sucursal': 100,
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
          reportType == ReportType.ventas; // ventas 보고서는 모든 컬럼 정렬 가능
      
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

    // Items, Ingresos 및 Alertas 보고서의 경우 합계 행을 화면 하단에 고정하면서 수직 스크롤 가능
    if (reportType == ReportType.items || reportType == ReportType.ingresos || reportType == ReportType.alertas) {
      // Alertas 보고서의 경우 화면 너비에 맞춰 컬럼 너비 동적 계산
      if (reportType == ReportType.alertas) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            // 컬럼 간격 (8px) * (컬럼 수 - 1) + 좌우 패딩 (32px)
            final totalSpacing = 8 * (keys.length - 1) + 32;
            final availableWidth = screenWidth - totalSpacing;
            
            // Alertas 컬럼별 최소 너비 설정 (alerta 제외, 더 작게 조정)
            final alertasMinWidths = <String, double>{
              'fecha': 100,  // 120 -> 100
              'hora': 80,    // 100 -> 80
              'progname': 120, // 150 -> 120
              'sucursal': 60,  // 100 -> 60
            };
            
            // 최소 너비가 필요한 컬럼들의 총 너비 계산
            double totalMinWidth = 0;
            for (var key in keys) {
              if (alertasMinWidths.containsKey(key)) {
                totalMinWidth += alertasMinWidths[key]!;
              }
            }
            
            // evento 컬럼에 할당할 나머지 공간 계산
            final eventoWidth = (availableWidth - totalMinWidth).clamp(200.0, double.infinity);
            
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
            
            // 헤더를 별도로 분리하여 수평 스크롤 동기화
            final headerRow = _buildHeaderRow(keys, columns, color, sortColumn, sortAscending, onSort, columnWidths: dynamicColumnWidths);
            
            return Column(
              children: [
                // 헤더 (수평 스크롤 동기화)
                headerRow,
                Expanded(
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columnSpacing: 8,
                        dataRowMinHeight: reportType == ReportType.alertas ? null : 12, // Alertas는 자동 높이
                        dataRowMaxHeight: reportType == ReportType.alertas ? null : 20, // Alertas는 자동 높이
                        headingRowHeight: 0,
                        headingRowColor: MaterialStateProperty.all(Colors.transparent),
                        sortColumnIndex: sortColumn != null && keys.contains(sortColumn) 
                            ? keys.indexOf(sortColumn) 
                            : null,
                        sortAscending: sortAscending,
                        columns: columns.map((col) {
                          final index = columns.indexOf(col);
                          final key = keys[index];
                          return DataColumn(
                            label: SizedBox(
                              width: dynamicColumnWidths[key] ?? 150.0,
                              child: col.label,
                            ),
                            onSort: col.onSort,
                          );
                        }).toList(),
                        rows: displayedList.map((item) {
                          if (item is Map<String, dynamic>) {
                            var cells = keys.map((key) {
                              final value = item[key];
                              
                              final keyLower = key.toLowerCase();
                              final isEventoColumn = keyLower == 'evento';
                              
                              // evento 컬럼은 formatValue에서 자르지 않음 (2줄 표시를 위해)
                              String formattedValue;
                              if (isEventoColumn && value is String) {
                                formattedValue = value.replaceAll('\$', '').trim();
                              } else {
                                formattedValue = ReportUtils.formatValue(value);
                              }
                              
                              final isAmountColumn = keyLower == 'sucursal';
                              final isNumeric = ReportUtils.isNumeric(value) || isAmountColumn;
                              
                              final cellWidth = dynamicColumnWidths[key] ?? 150.0;
                              
                              return DataCell(
                                SizedBox(
                                  width: cellWidth,
                                  child: Align(
                                    alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Wrap(
                                      children: [
                                        Text(
                                          formattedValue,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: isEventoColumn ? 1.3 : 1.2,
                                          ),
                                          maxLines: null, // Alertas는 모든 줄 표시
                                          overflow: TextOverflow.visible, // 내용에 맞게 자동 높이 조절
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList();
                            
                            return DataRow(cells: cells);
                          }
                          return DataRow(cells: keys.map((key) => const DataCell(Text(''))).toList());
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
      
      // 헤더를 별도로 분리하여 수평 스크롤 동기화
      final headerRow = _buildHeaderRow(keys, columns, color, sortColumn, sortAscending, onSort);
      
      return Column(
        children: [
          // 헤더 (수평 스크롤 동기화)
          if (horizontalScrollController != null)
            SingleChildScrollView(
              controller: horizontalScrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: headerRow,
            )
          else
            headerRow,
          Expanded(
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // 데이터 부분의 수평 스크롤 이벤트를 헤더에 전달
                  if (notification is ScrollUpdateNotification && 
                      notification.depth == 0 && 
                      notification.metrics.axis == Axis.horizontal &&
                      horizontalScrollController != null &&
                      horizontalScrollController.hasClients) {
                    horizontalScrollController.jumpTo(notification.metrics.pixels);
                  }
                  return false;
                },
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.vertical,
                  child: horizontalScrollController != null
                      ? SingleChildScrollView(
                          controller: horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 8,
                            dataRowMinHeight: reportType == ReportType.alertas ? null : 48, // Alertas는 자동 높이
                            dataRowMaxHeight: reportType == ReportType.alertas ? null : 56, // Alertas는 자동 높이
                            headingRowHeight: 0, // 헤더는 _buildHeaderRow로 표시하므로 0으로 설정
                    headingRowColor: MaterialStateProperty.all(
                              Colors.transparent, // 헤더 배경을 투명하게
                    ),
                    sortColumnIndex: sortColumn != null && keys.contains(sortColumn) 
                        ? keys.indexOf(sortColumn) 
                        : null,
                    sortAscending: sortAscending,
                    columns: columns, // columns는 정렬 기능을 위해 필요하지만 headingRowHeight가 0이므로 표시되지 않음
                    rows: displayedList.map((item) {
                      if (item is Map<String, dynamic>) {
                        // keys의 각 키에 대해 셀 생성 (키가 없어도 셀은 생성)
                        var cells = keys.map((key) {
                          final value = item[key];
                          String formattedValue;
                          
                          // codigo 관련 칼럼은 문자로 처리 (숫자 포맷팅 제외)
                          // vcode는 서버에서 이미 right(vcode, 5)로 처리되었으므로 특별 처리 불필요
                          final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1' || key == 'vcode';
                          
                          // year 필드 포맷팅: "2025-01-01" 또는 "2025" -> "2025" (대소문자 구분 없음)
                          final keyLower = key.toLowerCase();
                          if (keyLower == 'year' && value != null) {
                            final yearStr = value.toString();
                            print('🔵🔵🔵 year 필드 포맷팅 - key: $key, keyLower: $keyLower, value: $yearStr, unit: $unit');
                            if (yearStr.contains('-')) {
                              // "YYYY-MM-DD" 또는 "YYYY-MM" 형식에서 연도만 추출
                              formattedValue = yearStr.split('-')[0];
                              print('🔵🔵🔵 year 포맷팅 결과: $formattedValue (원본: $yearStr)');
                            } else {
                              formattedValue = yearStr;
                            }
                          }
                          // month 필드 포맷팅: "2025-12-01" -> "2025-12" (대소문자 구분 없음)
                          else if (keyLower == 'month' && value != null) {
                            final monthStr = value.toString();
                            if (monthStr.length >= 7 && monthStr.contains('-')) {
                              // "YYYY-MM-DD" 형식을 "YYYY-MM"으로 변환
                              formattedValue = monthStr.substring(0, 7);
                            } else {
                              formattedValue = monthStr;
                            }
                          } else {
                            formattedValue = isCodigoColumn 
                                ? (value?.toString() ?? 'N/A')
                                : ReportUtils.formatValue(value);
                          }
                          
                          // 디버깅: year 필드인데 포맷팅이 안 된 경우
                          if (keyLower == 'year' && formattedValue.contains('-')) {
                            print('⚠️⚠️⚠️ year 필드가 포맷팅되지 않았습니다! key: $key, formattedValue: $formattedValue');
                          }
                          
                          // 금액/숫자 관련 컬럼명 체크 (명시적으로 숫자로 처리)
                          final isAmountColumn = keyLower.contains('costo') || 
                                                 keyLower.contains('importe') || 
                                                 keyLower.contains('ingreso') || 
                                                 keyLower.contains('precio') ||
                                                 keyLower.contains('pre') ||
                                                 keyLower.contains('venta') ||
                                                 keyLower.contains('cantidad') ||
                                                 keyLower.contains('count') ||
                                                 keyLower.contains('total') ||
                                                 keyLower == 'sucursal' || // alertas 보고서의 sucursal 컬럼
                                                 (keyLower.startsWith('t') && 
                                                  (keyLower.contains('cant') || 
                                                   keyLower.contains('event') ||
                                                   keyLower.contains('prendas')));
                          
                          final isNumeric = (key != 'codigo' && key != 'codigo1' && key != 'tcode' && key != 'id_codigo1' && key != 'vcode') 
                              ? (ReportUtils.isNumeric(value) || isAmountColumn)
                              : false;
                          
                          // 헤더와 일치하는 고정 너비 적용
                          final cellWidth = columnWidths[key] ?? 150.0;
                          
                          // Alertas 보고서는 내용에 맞게 자동 높이 조절
                          final isAlertas = reportType == ReportType.alertas;
                          final isEventoColumn = key.toLowerCase() == 'evento';
                          
                          return DataCell(
                            SizedBox(
                              width: cellWidth,
                              child: Align(
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
                                            maxLines: null, // 모든 줄 표시
                                            overflow: TextOverflow.visible, // 내용에 맞게 자동 높이 조절
                                          ),
                                        ],
                                      )
                                    : Text(
                                        formattedValue,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.2, // 읽기 가능한 줄 높이로 조정
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                            ),
                          );
                        }).toList();
                        
                        // 셀 개수가 keys.length와 일치하는지 확인
                        assert(cells.length == keys.length, 
                          'Row cells count (${cells.length}) must match keys count (${keys.length})');
                        
                        // ventas 보고서의 vcode 단위에서 더블 탭 및 단일 탭 제스처 추가
                        if ((onRowDoubleTap != null || onRowTap != null) && reportType == ReportType.ventas && unit == 'vcode' && cells.isNotEmpty) {
                          // vcode 컬럼의 인덱스 찾기
                          final vcodeIndex = keys.indexOf('vcode');
                          if (vcodeIndex >= 0 && vcodeIndex < cells.length) {
                            final vcodeCell = cells[vcodeIndex];
                            if (vcodeCell.child is SizedBox) {
                              final sizedBox = vcodeCell.child as SizedBox;
                              if (sizedBox.child is Align) {
                                final align = sizedBox.child as Align;
                                cells[vcodeIndex] = DataCell(
                                  GestureDetector(
                                    onTap: onRowTap != null ? () => onRowTap(item) : null,
                                    onDoubleTap: onRowDoubleTap != null ? () => onRowDoubleTap(item) : null,
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
                            }
                          }
                          // vcode 컬럼을 찾지 못한 경우 첫 번째 셀에 적용 (하위 호환성)
                          else if (cells.isNotEmpty) {
                          final firstCell = cells[0];
                            if (firstCell.child is SizedBox) {
                              final sizedBox = firstCell.child as SizedBox;
                              if (sizedBox.child is Align) {
                                final align = sizedBox.child as Align;
                            cells[0] = DataCell(
                              GestureDetector(
                                    onTap: onRowTap != null ? () => onRowTap(item) : null,
                                onDoubleTap: onRowDoubleTap != null ? () => onRowDoubleTap(item) : null,
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
                            }
                          }
                        }
                        
                        return DataRow(cells: cells);
                      }
                      // Map이 아닌 경우에도 keys.length만큼 셀 생성
                      final formattedValue = ReportUtils.formatValue(item);
                      final isNumeric = ReportUtils.isNumeric(item);
                      final nonMapCells = List.generate(keys.length, (index) {
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
                      
                      // ventas 보고서의 경우 제스처 추가
                      // year, month, day 단위: 모든 셀에 제스처 추가
                      // vcode 단위: 첫 번째 셀에만 제스처 추가
                      if ((onRowDoubleTap != null || onRowTap != null) && reportType == ReportType.ventas && nonMapCells.isNotEmpty && item is Map<String, dynamic>) {
                        final updatedCells = List<DataCell>.from(nonMapCells);
                        
                        if (unit == 'year' || unit == 'month' || unit == 'day') {
                          // year, month, day 단위: 모든 셀에 제스처 추가
                          for (int i = 0; i < updatedCells.length; i++) {
                            final cell = updatedCells[i];
                            if (cell.child is Align) {
                              final align = cell.child as Align;
                              updatedCells[i] = DataCell(
                                GestureDetector(
                                  onDoubleTap: onRowDoubleTap != null ? () => onRowDoubleTap(item) : null,
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
                          }
                        } else {
                          // vcode 단위: 첫 번째 셀에만 제스처 추가
                          final firstCell = updatedCells[0];
                          if (firstCell.child is Align) {
                            final align = firstCell.child as Align;
                            updatedCells[0] = DataCell(
                              GestureDetector(
                                onTap: (onRowTap != null && unit == 'vcode') ? () => onRowTap(item) : null,
                                onDoubleTap: onRowDoubleTap != null ? () => onRowDoubleTap(item) : null,
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
                        }
                        
                        return DataRow(cells: updatedCells);
                      }
                      
                      return DataRow(cells: nonMapCells);
                    }).toList(),
                          ),
                        )
                      : DataTable(
                          columnSpacing: 8,
                          dataRowMinHeight: reportType == ReportType.alertas ? 72 : 48, // Alertas는 1.5배 높이
                          dataRowMaxHeight: reportType == ReportType.alertas ? 84 : 56, // Alertas는 1.5배 높이
                          headingRowHeight: reportType == ReportType.ventas ? 0 : 56, // ventas는 상단 헤더 사용
                          headingRowColor: MaterialStateProperty.all(
                            Colors.transparent,
                          ),
                          sortColumnIndex: sortColumn != null && keys.contains(sortColumn) 
                              ? keys.indexOf(sortColumn) 
                              : null,
                          sortAscending: sortAscending,
                          columns: columns,
                          rows: displayedList.map((item) {
                            print('🔵 DataTable rows 생성 - unit: $unit, reportType: $reportType, onRowDoubleTap: ${onRowDoubleTap != null}');
                            if (item is Map<String, dynamic>) {
                              var cells = keys.map((key) {
                                final value = item[key];
                                String formattedValue;
                                // codigo 관련 칼럼은 문자로 처리 (숫자 포맷팅 제외)
                                // vcode는 서버에서 이미 right(vcode, 5)로 처리되었으므로 특별 처리 불필요
                                final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1' || key == 'vcode';
                                
                                // year 필드 포맷팅: "2025-01-01" 또는 "2025" -> "2025" (대소문자 구분 없음)
                                final keyLower = key.toLowerCase();
                                if (keyLower == 'year' && value != null) {
                                  final yearStr = value.toString();
                                  print('🔵 year 필드 포맷팅 - key: $key, value: $yearStr');
                                  if (yearStr.contains('-')) {
                                    // "YYYY-MM-DD" 또는 "YYYY-MM" 형식에서 연도만 추출
                                    formattedValue = yearStr.split('-')[0];
                                    print('🔵 year 포맷팅 결과: $formattedValue');
                                  } else {
                                    formattedValue = yearStr;
                                  }
                                }
                                // month 필드 포맷팅: "2025-12-01" -> "2025-12" (대소문자 구분 없음)
                                else if (keyLower == 'month' && value != null) {
                                  final monthStr = value.toString();
                                  if (monthStr.length >= 7 && monthStr.contains('-')) {
                                    // "YYYY-MM-DD" 형식을 "YYYY-MM"으로 변환
                                    formattedValue = monthStr.substring(0, 7);
                                  } else {
                                    formattedValue = monthStr;
                                  }
                                } else {
                                  formattedValue = isCodigoColumn 
                                      ? (value?.toString() ?? 'N/A')
                                      : ReportUtils.formatValue(value);
                                }
                                
                                // 금액/숫자 관련 컬럼명 체크 (명시적으로 숫자로 처리)
                                final isAmountColumn = keyLower.contains('costo') ||
                                                       keyLower.contains('importe') ||
                                                       keyLower.contains('ingreso') ||
                                                       keyLower.contains('precio') ||
                                                       keyLower.contains('pre') ||
                                                       keyLower.contains('venta') ||
                                                       keyLower.contains('cantidad') ||
                                                       keyLower.contains('count') ||
                                                       keyLower.contains('total') ||
                                                       keyLower == 'sucursal' || // alertas 보고서의 sucursal 컬럼
                                                       (keyLower.startsWith('t') &&
                                                        (keyLower.contains('cant') ||
                                                         keyLower.contains('event') ||
                                                         keyLower.contains('prendas')));
                                
                                final isNumeric = (key != 'codigo' && key != 'codigo1' && key != 'tcode' && key != 'id_codigo1' && key != 'vcode')
                                    ? (ReportUtils.isNumeric(value) || isAmountColumn)
                                    : false;
                                return DataCell(
                                  Align(
                                    alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Text(
                                      formattedValue,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                );
                              }).toList();
                              assert(cells.length == keys.length);
                              
                              // ventas 보고서의 vcode 단위에서 더블 탭 및 단일 탭 제스처 추가
                              final finalCells = ((onRowDoubleTap != null || onRowTap != null) && reportType == ReportType.ventas && unit == 'vcode' && cells.isNotEmpty)
                                  ? (() {
                                      final updatedCells = List<DataCell>.from(cells);
                                      // vcode 컬럼의 인덱스 찾기
                                      final vcodeIndex = keys.indexOf('vcode');
                                      if (vcodeIndex >= 0 && vcodeIndex < updatedCells.length) {
                                        final vcodeCell = updatedCells[vcodeIndex];
                                        if (vcodeCell.child is Align) {
                                          final align = vcodeCell.child as Align;
                                          updatedCells[vcodeIndex] = DataCell(
                                            GestureDetector(
                                              onTap: onRowTap != null ? () => onRowTap(item) : null,
                                              onDoubleTap: onRowDoubleTap != null ? () => onRowDoubleTap(item) : null,
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
                                      }
                                      // vcode 컬럼을 찾지 못한 경우 첫 번째 셀에 적용 (하위 호환성)
                                      else if (updatedCells.isNotEmpty) {
                                      final firstCell = updatedCells[0];
                                      if (firstCell.child is Align) {
                                        final align = firstCell.child as Align;
                                        updatedCells[0] = DataCell(
                                          GestureDetector(
                                              onTap: onRowTap != null ? () => onRowTap(item) : null,
                                            onDoubleTap: onRowDoubleTap != null ? () => onRowDoubleTap(item) : null,
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
                                      }
                                      return updatedCells;
                                    })()
                                  : cells;
                              
                              return DataRow(cells: finalCells);
                            }
                            final formattedValue = ReportUtils.formatValue(item);
                            final isNumeric = ReportUtils.isNumeric(item);
                            final nonMapCells = List.generate(keys.length, (index) {
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
                            
                            // ventas 보고서의 vcode 단위에서 더블 탭 및 단일 탭 제스처 추가
                            if ((onRowDoubleTap != null || onRowTap != null) && reportType == ReportType.ventas && unit == 'vcode' && nonMapCells.isNotEmpty && item is Map<String, dynamic>) {
                              final updatedCells = List<DataCell>.from(nonMapCells);
                              // vcode 컬럼의 인덱스 찾기
                              final vcodeIndex = keys.indexOf('vcode');
                              if (vcodeIndex >= 0 && vcodeIndex < updatedCells.length) {
                                final vcodeCell = updatedCells[vcodeIndex];
                                if (vcodeCell.child is Align) {
                                  final align = vcodeCell.child as Align;
                                  updatedCells[vcodeIndex] = DataCell(
                                    GestureDetector(
                                      onTap: onRowTap != null ? () => onRowTap(item) : null,
                                      onDoubleTap: onRowDoubleTap != null ? () => onRowDoubleTap(item) : null,
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
                              }
                              // vcode 컬럼을 찾지 못한 경우 첫 번째 셀에 적용 (하위 호환성)
                              else if (updatedCells.isNotEmpty) {
                              final firstCell = updatedCells[0];
                              if (firstCell.child is Align) {
                                final align = firstCell.child as Align;
                                updatedCells[0] = DataCell(
                                  GestureDetector(
                                      onTap: onRowTap != null ? () => onRowTap(item) : null,
                                    onDoubleTap: onRowDoubleTap != null ? () => onRowDoubleTap(item) : null,
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
                              }
                              return DataRow(cells: updatedCells);
                            }
                            
                            return DataRow(cells: nonMapCells);
                          }).toList(),
                        ),
                ),
              ),
            ),
          ),
          // 고정된 합계 행 (현재 화면에 보이는 항목들의 합계)
          _buildFixedTotalRow(keys, displayedList, color),
        ],
      );
    }

    // 다른 보고서는 기존 방식 유지 (ventas는 DataTable 헤더 사용)
    // ventas 보고서의 경우 별도 헤더를 사용하지 않고 DataTable 헤더만 사용
    final headerRow = reportType == ReportType.ventas 
        ? null 
        : _buildHeaderRow(keys, columns, color, sortColumn, sortAscending, onSort);
    
    return Column(
      children: [
        // 헤더 (수평 스크롤 동기화) - ventas는 제외
        if (headerRow != null)
          if (horizontalScrollController != null)
            SingleChildScrollView(
              controller: horizontalScrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: headerRow,
            )
          else
            headerRow,
        Expanded(
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // 데이터 부분의 수평 스크롤 이벤트를 헤더에 전달
                if (notification is ScrollUpdateNotification && 
                    notification.depth == 0 && 
                    notification.metrics.axis == Axis.horizontal &&
                    horizontalScrollController != null &&
                    horizontalScrollController.hasClients) {
                  horizontalScrollController.jumpTo(notification.metrics.pixels);
                }
                return false;
              },
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.vertical,
                child: (horizontalScrollController != null || reportType == ReportType.ventas)
                    ? SingleChildScrollView(
                        controller: horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 8,
                          dataRowMinHeight: reportType == ReportType.ventas ? 32 : (reportType == ReportType.alertas ? null : 48),
                          dataRowMaxHeight: reportType == ReportType.ventas ? 40 : (reportType == ReportType.alertas ? null : 56),
                          headingRowHeight: reportType == ReportType.ventas ? 40 : 56,
                          headingRowColor: MaterialStateProperty.all(
                            Colors.transparent, // 헤더 배경을 투명하게
                          ),
                          columns: columns,
                          rows: [
                          ...displayedList.map((item) {
                            if (item is Map<String, dynamic>) {
                              // keys의 각 키에 대해 셀 생성 (키가 없어도 셀은 생성)
                              var cells = keys.map((key) {
                                final value = item[key];
                                String formattedValue;
                                
                                // codigo 관련 칼럼은 문자로 처리 (숫자 포맷팅 제외)
                                final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
                                
                                // year 필드 포맷팅: "2025-01-01" 또는 "2025" -> "2025" (대소문자 구분 없음)
                                final keyLower = key.toLowerCase();
                                if (keyLower == 'year' && value != null) {
                                  final yearStr = value.toString();
                                  if (yearStr.contains('-')) {
                                    // "YYYY-MM-DD" 또는 "YYYY-MM" 형식에서 연도만 추출
                                    formattedValue = yearStr.split('-')[0];
                                  } else {
                                    formattedValue = yearStr;
                                  }
                                }
                                // month 필드 포맷팅: "2025-12-01" -> "2025-12" (대소문자 구분 없음)
                                else if (keyLower == 'month' && value != null) {
                                  final monthStr = value.toString();
                                  if (monthStr.length >= 7 && monthStr.contains('-')) {
                                    // "YYYY-MM-DD" 형식을 "YYYY-MM"으로 변환
                                    formattedValue = monthStr.substring(0, 7);
                                  } else {
                                    formattedValue = monthStr;
                                  }
                                } else {
                                  formattedValue = isCodigoColumn 
                                      ? (value?.toString() ?? 'N/A')
                                      : ReportUtils.formatValue(value);
                                }
                                
                                // 금액/숫자 관련 컬럼명 체크 (명시적으로 숫자로 처리)
                                final isAmountColumn = keyLower.contains('costo') || 
                                                       keyLower.contains('importe') || 
                                                       keyLower.contains('ingreso') || 
                                                       keyLower.contains('precio') ||
                                                       keyLower.contains('pre') ||
                                                       keyLower.contains('venta') ||
                                                       keyLower.contains('cantidad') ||
                                                       keyLower.contains('count') ||
                                                       keyLower.contains('total') ||
                                                       (keyLower.startsWith('t') && 
                                                        (keyLower.contains('cant') || 
                                                         keyLower.contains('event') ||
                                                         keyLower.contains('prendas')));
                                
                                final isNumeric = (key != 'codigo' && key != 'codigo1' && key != 'tcode' && key != 'id_codigo1') 
                                    ? (ReportUtils.isNumeric(value) || isAmountColumn)
                                    : false;
                                // Alertas 보고서는 내용에 맞게 자동 높이 조절
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
                                                maxLines: null, // 모든 줄 표시
                                                overflow: TextOverflow.visible, // 내용에 맞게 자동 높이 조절
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
                              }).toList();
                              
                              // 셀 개수가 keys.length와 일치하는지 확인
                              assert(cells.length == keys.length, 
                                'Row cells count (${cells.length}) must match keys count (${keys.length})');
                              
                              // ventas 보고서의 경우 제스처 추가
                              // 모든 단위: 모든 셀에 더블 클릭 제스처 추가
                              if ((onRowDoubleTap != null || onRowTap != null) && reportType == ReportType.ventas && cells.isNotEmpty) {
                                // 모든 셀에 더블 클릭 제스처 추가
                                cells = cells.map((cell) {
                                  if (cell.child is Align) {
                                    final align = cell.child as Align;
                                    return DataCell(
                                      GestureDetector(
                                        onTap: (onRowTap != null && unit == 'vcode') ? () => onRowTap(item) : null,
                                        onDoubleTap: onRowDoubleTap != null ? () => onRowDoubleTap(item) : null,
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
                                  return cell;
                                }).toList();
                              }
                              
                              return DataRow(cells: cells);
                            }
                            // Map이 아닌 경우에도 keys.length만큼 셀 생성
                            final formattedValue = ReportUtils.formatValue(item);
                            final isNumeric = ReportUtils.isNumeric(item);
                            return DataRow(
                              cells: List.generate(keys.length, (index) {
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
                              }),
                            );
                          }),
                          // 합계 행 추가
                          _buildTotalRow(keys, dataList, color, reportType: reportType),
                          ],
                        ),
                      )
                      : DataTable(
                          columnSpacing: 8,
                          dataRowMinHeight: reportType == ReportType.ventas ? 32 : (reportType == ReportType.alertas ? null : 48),
                          dataRowMaxHeight: reportType == ReportType.ventas ? 40 : (reportType == ReportType.alertas ? null : 56),
                          headingRowHeight: reportType == ReportType.ventas ? 40 : 56,
                          headingRowColor: MaterialStateProperty.all(
                            Colors.transparent,
                          ),
                          columns: columns,
                          rows: [
                            ...displayedList.map((item) {
                              if (item is Map<String, dynamic>) {
                                var cells = keys.map((key) {
                                  final value = item[key];
                                  String formattedValue;
                                  // codigo 관련 칼럼은 문자로 처리 (숫자 포맷팅 제외)
                                  // vcode는 서버에서 이미 right(vcode, 5)로 처리되었으므로 특별 처리 불필요
                                  final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1' || key == 'vcode';
                                  
                                  // year 필드 포맷팅: "2025-01-01" 또는 "2025" -> "2025" (대소문자 구분 없음)
                                  final keyLower = key.toLowerCase();
                                  if (keyLower == 'year' && value != null) {
                                    final yearStr = value.toString();
                                    print('🔵 year 필드 포맷팅 - key: $key, value: $yearStr');
                                    if (yearStr.contains('-')) {
                                      // "YYYY-MM-DD" 또는 "YYYY-MM" 형식에서 연도만 추출
                                      formattedValue = yearStr.split('-')[0];
                                      print('🔵 year 포맷팅 결과: $formattedValue');
                                    } else {
                                      formattedValue = yearStr;
                                    }
                                  }
                                  // month 필드 포맷팅: "2025-12-01" -> "2025-12" (대소문자 구분 없음)
                                  else if (keyLower == 'month' && value != null) {
                                    final monthStr = value.toString();
                                    if (monthStr.length >= 7 && monthStr.contains('-')) {
                                      // "YYYY-MM-DD" 형식을 "YYYY-MM"으로 변환
                                      formattedValue = monthStr.substring(0, 7);
                                    } else {
                                      formattedValue = monthStr;
                                    }
                                  } else {
                                    formattedValue = isCodigoColumn 
                                        ? (value?.toString() ?? 'N/A')
                                        : ReportUtils.formatValue(value);
                                  }
                                
                                // 금액/숫자 관련 컬럼명 체크 (명시적으로 숫자로 처리)
                                final isAmountColumn = keyLower.contains('costo') ||
                                                       keyLower.contains('importe') ||
                                                       keyLower.contains('ingreso') ||
                                                       keyLower.contains('precio') ||
                                                       keyLower.contains('pre') ||
                                                       keyLower.contains('venta') ||
                                                       keyLower.contains('cantidad') ||
                                                       keyLower.contains('count') ||
                                                       keyLower.contains('total') ||
                                                       keyLower == 'sucursal' || // alertas 보고서의 sucursal 컬럼
                                                       (keyLower.startsWith('t') &&
                                                        (keyLower.contains('cant') ||
                                                         keyLower.contains('event') ||
                                                         keyLower.contains('prendas')));
                                
                                final isNumeric = (key != 'codigo' && key != 'codigo1' && key != 'tcode' && key != 'id_codigo1' && key != 'vcode')
                                    ? (ReportUtils.isNumeric(value) || isAmountColumn)
                                    : false;
                                // Alertas 보고서는 내용에 맞게 자동 높이 조절
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
                                                maxLines: null, // 모든 줄 표시
                                                overflow: TextOverflow.visible, // 내용에 맞게 자동 높이 조절
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
                                }).toList();
                                assert(cells.length == keys.length);
                                
                                // ventas 보고서의 경우 제스처 추가
                                // year, month, day 단위: 모든 셀에 제스처 추가
                                // vcode 단위: 모든 셀에 제스처 추가 (단일 탭은 vcode만)
                                final finalCells = ((onRowDoubleTap != null || onRowTap != null) && reportType == ReportType.ventas)
                                    ? cells.map((cell) {
                                        if (cell.child is Align) {
                                          final align = cell.child as Align;
                                          return DataCell(
                                            GestureDetector(
                                              onTap: (onRowTap != null && unit == 'vcode') ? () {
                                                print('🔵 단일 탭 감지 (vcode unit)');
                                                onRowTap(item);
                                              } : null,
                                              onDoubleTap: onRowDoubleTap != null ? () {
                                                print('🔵🔵 더블 탭 감지! unit: $unit');
                                                onRowDoubleTap(item);
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
                                        } else {
                                          print('⚠️ cell.child가 Align이 아닙니다: ${cell.child.runtimeType}');
                                        }
                                        return cell;
                                      }).toList()
                                    : cells;
                                
                                return DataRow(cells: finalCells);
                              }
                              final formattedValue = ReportUtils.formatValue(item);
                              final isNumeric = ReportUtils.isNumeric(item);
                              final nonMapCells = List.generate(keys.length, (index) {
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
                              
                              // ventas 보고서의 경우 제스처 추가
                              // 모든 단위: 모든 셀에 더블 클릭 제스처 추가
                              if ((onRowDoubleTap != null || onRowTap != null) && reportType == ReportType.ventas && nonMapCells.isNotEmpty && item is Map<String, dynamic>) {
                                final updatedCells = List<DataCell>.from(nonMapCells);
                                
                                // 모든 셀에 더블 클릭 제스처 추가
                                for (int i = 0; i < updatedCells.length; i++) {
                                  final cell = updatedCells[i];
                                  if (cell.child is Align) {
                                    final align = cell.child as Align;
                                    updatedCells[i] = DataCell(
                                      GestureDetector(
                                        onTap: (onRowTap != null && unit == 'vcode') ? () => onRowTap(item) : null,
                                        onDoubleTap: onRowDoubleTap != null ? () => onRowDoubleTap(item) : null,
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
                                }
                                
                                return DataRow(cells: updatedCells);
                              }
                              
                              return DataRow(cells: nonMapCells);
                            }),
                            _buildTotalRow(keys, dataList, color, reportType: reportType),
                          ],
                        ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 고정된 합계 행 빌드 (화면 하단에 고정, 현재 보이는 항목들의 합계)
  static Widget _buildFixedTotalRow(List<String> keys, List<dynamic> displayedList, Color reportColor) {
    // 각 칼럼별 합계 계산 (현재 화면에 보이는 항목들만)
    final totals = <String, num>{};
    
    for (var key in keys) {
      final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
      if (isCodigoColumn) continue; // 문자 칼럼은 합계 계산 제외
      
      num sum = 0;
      for (var item in displayedList) {
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
    
    // 컬럼별 고정 너비 설정 (헤더와 일치)
    final columnWidths = <String, double>{
      // Items 보고서
      'codigo1': 150,
      'desc1': 300,
      'tprendas': 120,
      'timporte': 150,
      // Ingresos 보고서
      'codigo': 150,
      'descripcion': 300,
      'tevent': 120,
      'tcant': 150,
      'tIngreso': 150,
      'tingreso': 150,
      'cntEvent': 120,
      'cntevent': 120,
    };
    
    return Container(
      width: double.infinity, // 전체 폭 차지
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
          children: keys.asMap().entries.map((entry) {
            final index = entry.key;
            final key = entry.value;
            final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
            final columnWidth = columnWidths[key] ?? 150.0;
            
            if (isCodigoColumn) {
              return SizedBox(
                width: columnWidth + (index < keys.length - 1 ? 8 : 0), // 마지막 컬럼 제외하고 8px 간격 추가
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), // vertical padding을 12에서 5로 줄임
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Total',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }
            
            final total = totals[key] ?? 0;
            return SizedBox(
              width: columnWidth + (index < keys.length - 1 ? 8 : 0), // 마지막 컬럼 제외하고 8px 간격 추가
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), // vertical padding을 12에서 5로 줄임
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    ReportUtils.formatValue(total),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 헤더 행 빌드 (수평 스크롤 동기화용)
  static Widget _buildHeaderRow(
    List<String> keys,
    List<DataColumn> columns,
    Color reportColor,
    String? sortColumn,
    bool sortAscending,
    Function(int columnIndex, bool ascending)? onSort, {
    Map<String, double>? columnWidths,
  }) {
    // 컬럼별 고정 너비 설정 (DataTable과 일치)
    final defaultColumnWidths = <String, double>{
      // Items 보고서
      'codigo1': 150,
      'desc1': 300,
      'tprendas': 120,
      'timporte': 150,
      // Ingresos 보고서
      'codigo': 150,
      'descripcion': 300,
      'tevent': 120,
      'tcant': 150,
      'tIngreso': 150,
      'tingreso': 150,
      'cntEvent': 120,
      'cntevent': 120,
      // Alertas 보고서
      'fecha': 120,
      'hora': 100,
      'evento': 500,
      'progname': 150,
      'alerta': 80,
      'sucursal': 100,
    };
    
    final finalColumnWidths = columnWidths ?? defaultColumnWidths;
    
    // DataTable의 헤더와 동일한 스타일로 헤더 행 생성
    // DataTable의 columnSpacing(8)을 고려하여 각 컬럼에 동일한 간격 적용
    return Container(
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
      child: Row(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // DataTable의 기본 padding과 일치
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
            // 마지막 칼럼이 아니면 columnSpacing(8px) 추가
            if (index < columns.length - 1) const SizedBox(width: 8),
          ];
        }).toList(),
      ),
    );
  }

  // 합계 행 빌드
  static DataRow _buildTotalRow(List<String> keys, List<dynamic> dataList, Color reportColor, {ReportType? reportType}) {
    // 각 칼럼별 합계 계산
    final totals = <String, num>{};
    
    for (var key in keys) {
      final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
      final isDateColumn = key == 'fecha' || key == 'month' || key == 'year' || key == 'hora';
      if (isCodigoColumn || isDateColumn) continue; // 문자 칼럼 및 날짜 칼럼은 합계 계산 제외
      
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
        final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
        final isDateColumn = key == 'fecha' || key == 'month' || key == 'year' || key == 'hora';
        if (isCodigoColumn || isDateColumn) {
          return DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total',
                style: TextStyle(
                  fontSize: isVentas ? 12 : 14,
                  fontWeight: FontWeight.bold,
                  height: isVentas ? 1.0 : 1.2,
                ),
              ),
            ),
          );
        }
        
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

