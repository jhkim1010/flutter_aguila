import 'package:flutter/material.dart';
import '../services/config_service.dart';
import 'report_utils.dart';

/// 보고서 테이블의 합계 행을 빌드하는 유틸리티 클래스
/// 성능 최적화를 위해 캐싱 기능 포함
class ReportTotalRowBuilder {
  // 성능 최적화: 합계 계산 캐시
  static final Map<String, DataRow> _totalRowCache = {};
  static String? _lastTotalRowCacheKey;

  /// 합계 행 빌드 (캐싱 적용)
  /// 
  /// [orderedKeys] 컬럼 키 목록
  /// [dataList] 데이터 리스트
  /// [isResumida] 요약 여부
  /// [reportColor] 보고서 색상
  static DataRow buildTotalRow(
    List<String> orderedKeys,
    List<dynamic> dataList,
    bool isResumida,
    Color reportColor,
  ) {
    // 캐시 키에 showTpago 포함 (false면 금액 칸 **** 표시)
    final showTpago = ConfigService().getVentasConfig()?['showTpago'];
    final cacheKey = '${dataList.length}_${orderedKeys.join('_')}_$isResumida}_$showTpago';
    
    // 캐시 확인
    if (_totalRowCache.containsKey(cacheKey) && _lastTotalRowCacheKey == cacheKey) {
      return _totalRowCache[cacheKey]!;
    }
    
    // 각 칼럼별 합계 계산
    final totals = <String, num>{};
    
    for (var key in orderedKeys) {
      final isCodigoColumn = key == 'codigo' || key == 'tcode' || key == 'codigo1' || key == 'id_codigo1';
      if (isCodigoColumn) continue; // 문자 칼럼은 합계 계산 제외
      
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
    
    final totalRow = DataRow(
      color: MaterialStateProperty.all(reportColor.withOpacity(0.1)),
      cells: orderedKeys.map((key) {
        final isCodigoColumn = key == 'codigo' || key == 'tcode' || key == 'codigo1' || key == 'id_codigo1';
        if (isCodigoColumn) {
          return DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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
              ReportUtils.formatValueForTotalRow(total, key),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
    
    // 캐시 저장 (최대 10개까지만 유지)
    if (_totalRowCache.length >= 10) {
      _totalRowCache.clear();
    }
    _totalRowCache[cacheKey] = totalRow;
    _lastTotalRowCacheKey = cacheKey;
    
    return totalRow;
  }

  /// 테이블용 합계 행 빌드 (캐싱 적용)
  /// 
  /// [keys] 컬럼 키 목록
  /// [dataList] 데이터 리스트
  /// [reportColor] 보고서 색상
  static DataRow buildTotalRowForTable(
    List<String> keys,
    List<dynamic> dataList,
    Color reportColor,
  ) {
    // 캐시 키에 showTpago 포함 (false면 금액 칸 **** 표시)
    final showTpago = ConfigService().getVentasConfig()?['showTpago'];
    final cacheKey = '${dataList.length}_${keys.join('_')}_$showTpago';
    
    // 캐시 확인
    if (_totalRowCache.containsKey(cacheKey) && _lastTotalRowCacheKey == cacheKey) {
      return _totalRowCache[cacheKey]!;
    }
    
    // 각 칼럼별 합계 계산
    final totals = <String, num>{};
    
    for (var key in keys) {
      final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
      if (isCodigoColumn) continue; // 문자 칼럼은 합계 계산 제외
      
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
    
    final totalRow = DataRow(
      color: MaterialStateProperty.all(reportColor.withOpacity(0.1)),
      cells: keys.map((key) {
        final isCodigoColumn = key == 'codigo' || key == 'codigo1' || key == 'tcode' || key == 'id_codigo1';
        if (isCodigoColumn) {
          return DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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
              ReportUtils.formatValueForTotalRow(total, key),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
    
    // 캐시 저장 (최대 10개까지만 유지)
    if (_totalRowCache.length >= 10) {
      _totalRowCache.clear();
    }
    _totalRowCache[cacheKey] = totalRow;
    _lastTotalRowCacheKey = cacheKey;
    
    return totalRow;
  }

  /// 캐시 무효화 (데이터 변경 시 호출)
  static void clearCache() {
    _totalRowCache.clear();
    _lastTotalRowCacheKey = null;
  }
}

