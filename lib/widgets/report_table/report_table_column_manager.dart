import 'package:flutter/foundation.dart';
import '../report_utils.dart';

/// 리포트 테이블 칼럼 관련 로직을 관리하는 클래스
/// report_table_builder.dart에서 추출된 칼럼 키 선택, 너비 계산 등의 로직을 포함
class ReportTableColumnManager {
  /// 리포트 타입별 기본 칼럼 너비 맵 반환
  /// buildTableFromList()에서 사용되는 columnWidths 맵
  static Map<String, double> getDefaultColumnWidths(ReportType reportType, {String? unit, List<String>? keys}) {
    final columnWidths = <String, double>{
      // Items 보고서 (codigo/codigo1, CategoryCode, CompanyCode 50% 더 넓게)
      'codigo1': 300,  // 200 * 1.5
      'desc1': 200,
      'ProductName': 400,  // ProductName 칼럼 너비 증가 (250 -> 400)
      'totalCantidad': 156,  // 120 * 1.3 (30% 넓게)
      'CategoryCode': 150,  // 100 * 1.5
      'CompanyCode': 150,  // 100 * 1.5
      'tprendas': 100,
      'timporte': 120,
      // Ingresos 보고서 (codigo 50% 더 넓게)
      'codigo': 180,  // 120 * 1.5
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
    final isMonthUnit = unit == 'month' || (unit != null && unit != 'vcode' && keys != null && keys.contains('month'));
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

    return columnWidths;
  }

  /// 리포트 타입별 표시할 칼럼 키 목록 반환
  /// buildTableFromList()에서 칼럼 키 선택 로직 추출
  static List<String> getKeysForReportType({
    required List<dynamic> displayedList,
    required ReportType reportType,
    String? unit,
  }) {
    if (displayedList.isEmpty || displayedList.first is! Map<String, dynamic>) {
      return [];
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
      final firstItemCheck = displayedList.isNotEmpty && displayedList.first is Map<String, dynamic>
          ? displayedList.first as Map<String, dynamic>
          : <String, dynamic>{};

      debugPrint('   → firstItem keys: ${firstItemCheck.keys.toList()}');

      // unit 파라미터가 없을 때만 데이터 구조로 판단
      bool finalIsDayMonthYearUnit = isDayMonthYearUnit;
      if (unit == null) {
        // vcode 필드가 없고, fecha/month/year 중 하나가 있으면 day/month/year 유닛
        final hasVcodeFieldParam = firstItemCheck.containsKey('vcode');
        final hasFechaFieldParam = firstItemCheck.containsKey('fecha');
        final hasMonthFieldParam = firstItemCheck.containsKey('month');
        final hasYearFieldParam = firstItemCheck.containsKey('year');
        final hasDayMonthYearKeyParam = hasFechaFieldParam || hasMonthFieldParam || hasYearFieldParam;
        // vcode 유닛 전용 필드들 (day/month/year 유닛에는 없음)
        final hasVcodeOnlyFieldsParam = firstItemCheck.containsKey('tpago') ||
                                       firstItemCheck.containsKey('cntropas') ||
                                       firstItemCheck.containsKey('d_num_caja') ||
                                       firstItemCheck.containsKey('d_num_terminal') ||
                                       firstItemCheck.containsKey('clientenombre') ||
                                       firstItemCheck.containsKey('vendedor') ||
                                       firstItemCheck.containsKey('tipo') ||
                                       firstItemCheck.containsKey('dni') ||
                                       firstItemCheck.containsKey('hora') ||
                                       firstItemCheck.containsKey('resiva') ||
                                       firstItemCheck.containsKey('casoesp') ||
                                       firstItemCheck.containsKey('cretmp') ||
                                       firstItemCheck.containsKey('ntiqrepetir') ||
                                       firstItemCheck.containsKey('b_mercadopago');

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

    return keys;
  }

  /// Alertas 보고서 전용 동적 칼럼 너비 계산
  /// 화면 너비에 맞춰 evento 칼럼에 나머지 공간을 할당
  static Map<String, double> getAlertasColumnWidths(List<String> keys, double screenWidth) {
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
    // getDefaultColumnWidths에서 기본 너비 가져오기 (alertas 외 칼럼 fallback용)
    final defaultWidths = getDefaultColumnWidths(ReportType.alertas);
    for (var key in keys) {
      if (key.toLowerCase() == 'evento') {
        dynamicColumnWidths[key] = eventoWidth;
      } else if (alertasMinWidths.containsKey(key)) {
        dynamicColumnWidths[key] = alertasMinWidths[key]!;
      } else {
        dynamicColumnWidths[key] = defaultWidths[key] ?? 150.0;
      }
    }

    return dynamicColumnWidths;
  }

  /// 수평 스크롤 테이블의 실제 너비 계산
  /// _buildTableWithHorizontalScroll에서 사용
  static double calculateTableWidth(List<String> keys, Map<String, double>? columnWidths, double maxWidth, {String? unit}) {
    final defaultColumnWidths = <String, double>{
      'codigo1': 300,
      'desc1': 200,
      'ProductName': 400,
      'totalCantidad': 156,
      'CategoryCode': 150,
      'CompanyCode': 150,
      'tprendas': 100,
      'timporte': 120,
      'codigo': 180,
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
    return totalWidth > maxWidth ? totalWidth : maxWidth + 100;
  }

  /// 푸터 전용 기본 칼럼 너비 맵 반환
  /// fventas/ventas/clientes/alertas 푸터의 너비 계산에 사용
  static Map<String, double> getFooterColumnWidths({String? unit}) {
    final defaultColumnWidths = <String, double>{
      'codigo1': 300, 'desc1': 200, 'ProductName': 400, 'totalCantidad': 156,
      'CategoryCode': 150, 'CompanyCode': 150, 'tprendas': 100, 'timporte': 120,
      'codigo': 180, 'descripcion': 200, 'tevent': 100, 'tcant': 120,
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

    return defaultColumnWidths;
  }
}
