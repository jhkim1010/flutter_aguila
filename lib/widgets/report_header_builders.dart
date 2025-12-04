import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'items_date_range_selector.dart';
import 'report_utils.dart';

/// 보고서 헤더 빌더들
class ReportHeaderBuilders {
  /// Ventas 보고서 헤더 빌드
  static Widget buildVentasHeader({
    required BuildContext context,
    required Map<String, dynamic>? data,
    required DateTime? ventasDate,
    required String? selectedSucursal,
    required Function(DateTime) onDateChanged,
    required Function(String?) onSucursalChanged,
    required Color reportColor,
  }) {
    // 데이터에서 sucursal 목록 추출
    List<String>? sucursales;
    if (data != null && data.containsKey('data') && data['data'] is List) {
      final dataList = data['data'] as List;
      final sucursalSet = <String>{};
      
      for (var item in dataList) {
        if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
          final sucursal = item['sucursal']?.toString();
          if (sucursal != null && sucursal.isNotEmpty) {
            sucursalSet.add(sucursal);
          }
        }
      }
      
      if (sucursalSet.isNotEmpty) {
        sucursales = sucursalSet.toList()..sort((a, b) {
          final aNum = int.tryParse(a) ?? 0;
          final bNum = int.tryParse(b) ?? 0;
          return aNum.compareTo(bNum);
        });
      }
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 날짜 표시 및 선택
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: ventasDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              locale: const Locale('ko', 'KR'),
            );
            
            if (picked != null && picked != ventasDate) {
              onDateChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  ventasDate != null
                      ? DateFormat('yyyy-MM-dd').format(ventasDate!)
                      : '날짜',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Sucursal이 1개 이상일 때만 콤보박스 표시
        if (sucursales != null && sucursales.length > 1) ...[
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(minWidth: 80),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButton<String?>(
              value: selectedSucursal,
              hint: const Text('모두', style: TextStyle(fontSize: 11)),
              underline: const SizedBox(),
              isDense: true,
              icon: Icon(Icons.arrow_drop_down, color: reportColor, size: 18),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('모두', style: TextStyle(fontSize: 11)),
                ),
                ...sucursales.map((sucursal) {
                  return DropdownMenuItem<String?>(
                    value: sucursal,
                    child: Text(sucursal, style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
              ],
              onChanged: onSucursalChanged,
            ),
          ),
        ],
      ],
    );
  }

  /// Items 보고서 필터 섹션 빌드
  static Widget buildItemsFilterSection({
    required Map<String, dynamic>? data,
    required TextEditingController filteringWordController,
    required DateTime? startDate,
    required DateTime? endDate,
    required Function(DateTime, DateTime) onDateRangeChanged,
    required ReportType reportType,
  }) {
    // 필터링된 데이터 개수 계산
    int totalCount = 0;
    int filteredCount = 0;
    
    if (data != null && data.containsKey('data') && data['data'] is List) {
      final dataList = data['data'] as List;
      totalCount = dataList.length;
      
      // filteringWord 필터 적용
      final filteringWord = filteringWordController.text.trim().toLowerCase();
      if (filteringWord.isNotEmpty) {
        filteredCount = dataList.where((item) {
          if (item is Map<String, dynamic>) {
            final codigo1 = item['codigo1']?.toString().toLowerCase() ?? '';
            final desc1 = item['desc1']?.toString().toLowerCase() ?? '';
            return codigo1.contains(filteringWord) || desc1.contains(filteringWord);
          }
          return false;
        }).length;
      } else {
        filteredCount = totalCount;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: ReportUtils.getReportColor(reportType).withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: ReportUtils.getReportColor(reportType).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 날짜 범위 선택
          Expanded(
            child: ItemsDateRangeSelector(
              reportType: reportType,
              startDate: startDate,
              endDate: endDate,
              onDateRangeChanged: onDateRangeChanged,
            ),
          ),
          const SizedBox(width: 12),
          // 데이터 개수 표시
          Text(
            'Total: $filteredCount${filteredCount != totalCount ? ' / $totalCount' : ''}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Items 보고서 데이터 개수 표시
  static Widget buildItemsDataCount(Map<String, dynamic>? data) {
    if (data == null) return const SizedBox.shrink();
    
    int totalCount = 0;
    if (data.containsKey('data') && data['data'] is List) {
      totalCount = (data['data'] as List).length;
    }
    
    return Text(
      'Total: $totalCount',
      style: const TextStyle(
        fontSize: 11,
        color: Colors.white70,
        fontWeight: FontWeight.normal,
      ),
    );
  }
}

