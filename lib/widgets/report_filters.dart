import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'report_utils.dart';

/// 보고서 필터 관련 기능
class ReportFilters {
  /// Filtering word 입력 필드 빌드 (AppBar용)
  static Widget buildFilteringWordField({
    required TextEditingController controller,
    required Function(String) onSubmitted,
    required Function() onClear,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return TextField(
            key: ValueKey('filtering_word_field'), // 키 추가로 재생성 방지
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Filtrar...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white, size: 18),
                      onPressed: () {
                        // clear 호출을 다음 프레임으로 지연하여 키보드 이벤트 충돌 방지
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          onClear();
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  : null,
            ),
            onSubmitted: onSubmitted,
            // 키보드 이벤트 처리를 최적화
            enableInteractiveSelection: true,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
          );
        },
      ),
    );
  }

  /// 필터 적용
  static List<dynamic> applyFilters({
    required List<dynamic> dataList,
    required String filteringWord,
    required ReportType reportType,
    String? selectedSucursal,
    DateTime? ventasDate,
  }) {
    List<dynamic> filteredList = dataList;

    // filteringWord 필터 적용 (대소문자 구분 없이)
    if (filteringWord.isNotEmpty) {
      final filterLower = filteringWord.toLowerCase();
      filteredList = filteredList.where((item) {
        if (item is! Map<String, dynamic>) return false;
        
        switch (reportType) {
          case ReportType.items:
            // codigo1 또는 desc1(제품 이름)에서 검색
            final codigo1 = item['codigo1']?.toString().toLowerCase() ?? '';
            final desc1 = item['desc1']?.toString().toLowerCase() ?? '';
            return codigo1.contains(filterLower) || desc1.contains(filterLower);
          
          case ReportType.ventas:
            final codigo = item['codigo']?.toString().toLowerCase() ?? 
                          item['codigo1']?.toString().toLowerCase() ?? '';
            final descripcion = item['descripcion']?.toString().toLowerCase() ?? 
                              item['desc1']?.toString().toLowerCase() ?? '';
            final cliente = item['cliente']?.toString().toLowerCase() ?? '';
            final total = item['total']?.toString().toLowerCase() ?? '';
            return codigo.contains(filterLower) || 
                   descripcion.contains(filterLower) ||
                   cliente.contains(filterLower) ||
                   total.contains(filterLower);
          
          case ReportType.codigos:
          case ReportType.todocodigos:
            final codigo = item['codigo']?.toString().toLowerCase() ?? '';
            final descripcion = item['descripcion']?.toString().toLowerCase() ?? '';
            return codigo.contains(filterLower) || descripcion.contains(filterLower);
          
          default:
            return true;
        }
      }).toList();
    }

    // Ventas 보고서의 경우 날짜 필터 적용
    if (reportType == ReportType.ventas && ventasDate != null) {
      final targetDateStr = DateFormat('yyyy-MM-dd').format(ventasDate);
      filteredList = filteredList.where((item) {
        if (item is Map<String, dynamic>) {
          final fecha = item['fecha']?.toString() ?? 
                      item['fecha_venta']?.toString() ?? 
                      item['fechaVenta']?.toString() ?? '';
          
          if (fecha.isNotEmpty) {
            try {
              final itemDate = DateTime.parse(fecha);
              final itemDateStr = DateFormat('yyyy-MM-dd').format(itemDate);
              return itemDateStr == targetDateStr;
            } catch (e) {
              return fecha.startsWith(targetDateStr);
            }
          }
        }
        return false;
      }).toList();
    }

    // Ventas 보고서의 경우 sucursal 필터 적용
    if (reportType == ReportType.ventas && selectedSucursal != null) {
      filteredList = filteredList.where((item) {
        if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
          final sucursal = item['sucursal']?.toString();
          return sucursal == selectedSucursal;
        }
        return false;
      }).toList();
    }

    return filteredList;
  }

  /// 정렬 적용
  static List<dynamic> applySort({
    required List<dynamic> dataList,
    String? sortColumn,
    bool sortAscending = true,
  }) {
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
      if (aValue == null) return sortAscending ? -1 : 1;
      if (bValue == null) return sortAscending ? 1 : -1;
      
      // 숫자 비교
      final aNum = ReportUtils.isNumeric(aValue) ? num.tryParse(aValue.toString().replaceAll(',', '')) : null;
      final bNum = ReportUtils.isNumeric(bValue) ? num.tryParse(bValue.toString().replaceAll(',', '')) : null;
      
      if (aNum != null && bNum != null) {
        final comparison = aNum.compareTo(bNum);
        return sortAscending ? comparison : -comparison;
      }
      
      // 문자열 비교
      final aStr = aValue.toString().toLowerCase();
      final bStr = bValue.toString().toLowerCase();
      final comparison = aStr.compareTo(bStr);
      return sortAscending ? comparison : -comparison;
    });
    
    return sortedList;
  }
}

