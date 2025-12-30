import '../widgets/report_utils.dart';

/// 보고서 데이터 처리 유틸리티 함수들
class ReportDataUtils {
  /// 필터 적용
  /// 
  /// [dataList] 원본 데이터 리스트
  /// [columnFilters] 컬럼별 필터 값 맵
  static List<dynamic> applyFilters(
    List<dynamic> dataList,
    Map<String, String> columnFilters,
  ) {
    if (columnFilters.isEmpty) {
      return dataList;
    }
    
    return dataList.where((item) {
      if (item is! Map<String, dynamic>) return true;
      
      for (var entry in columnFilters.entries) {
        final columnKey = entry.key;
        final filterValue = entry.value.toLowerCase();
        
        if (!item.containsKey(columnKey)) continue;
        
        final cellValue = item[columnKey];
        final cellValueStr = ReportUtils.formatValue(cellValue).toLowerCase();
        
        if (!cellValueStr.contains(filterValue)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  /// 정렬 적용
  /// 
  /// [dataList] 원본 데이터 리스트
  /// [sortColumn] 정렬할 컬럼 키
  /// [sortAscending] 오름차순 여부
  static List<dynamic> applySort(
    List<dynamic> dataList,
    String? sortColumn,
    bool sortAscending,
  ) {
    if (sortColumn == null || dataList.isEmpty) {
      return dataList;
    }
    
    final sortedList = List<dynamic>.from(dataList);
    
    sortedList.sort((a, b) {
      if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) {
        return 0;
      }
      
      final aValue = a[sortColumn];
      final bValue = b[sortColumn];
      
      // null 처리
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return 1;
      if (bValue == null) return -1;
      
      // 숫자 비교
      if (aValue is num && bValue is num) {
        final comparison = aValue.compareTo(bValue);
        return sortAscending ? comparison : -comparison;
      }
      
      // 문자열 비교
      final aStr = ReportUtils.formatValue(aValue).toLowerCase();
      final bStr = ReportUtils.formatValue(bValue).toLowerCase();
      final comparison = aStr.compareTo(bStr);
      return sortAscending ? comparison : -comparison;
    });
    
    return sortedList;
  }
}

