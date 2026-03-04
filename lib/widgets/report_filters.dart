import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:intl/intl.dart';
import 'report_utils.dart';

/// 보고서 필터 관련 기능
class ReportFilters {
  /// Filtering word 입력 필드 빌드
  /// [forLightBackground] true면 본문(밝은 배경)용 스타일(진한 글자/테두리), false면 AppBar(어두운 배경)용 스타일.
  static Widget buildFilteringWordField({
    required TextEditingController controller,
    required Function(String) onSubmitted,
    required Function() onClear,
    bool forLightBackground = false,
  }) {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🔍 [ReportFilters.buildFilteringWordField] 호출됨 forLightBackground=$forLightBackground');
    debugPrint('═══════════════════════════════════════════════════════════');
    
    final bool light = forLightBackground;
    final Color textColor = light ? Colors.black87 : Colors.white;
    final Color hintColor = light ? Colors.grey : Colors.white.withOpacity(0.7);
    final Color iconColor = light ? Colors.grey[700]! : Colors.white;
    final Color containerColor = light ? Colors.grey[100]! : Colors.white.withOpacity(0.2);
    final InputBorder? border = light ? OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey[400]!)) : null;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return child!;
        },
        child: TextField(
          key: ValueKey('filtering_word_field_$light'),
          controller: controller,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Filtrar...',
            hintStyle: TextStyle(color: hintColor),
            border: border ?? InputBorder.none,
            enabledBorder: border ?? InputBorder.none,
            focusedBorder: light ? OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.orange, width: 1.5)) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: Icon(Icons.search, color: iconColor, size: 20),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                return value.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: iconColor, size: 18),
                        onPressed: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            onClear();
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
          onSubmitted: onSubmitted,
          enableInteractiveSelection: true,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
        ),
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

