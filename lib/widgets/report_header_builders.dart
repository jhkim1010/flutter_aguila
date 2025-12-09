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
    required DateTime? startDate,
    required DateTime? endDate,
    required String? selectedSucursal,
    required Function(DateTime, DateTime) onDateRangeChanged,
    required Function(String?) onSucursalChanged,
    required Color reportColor,
    required ReportType reportType,
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
    
    // Summary 정보 추출 (total_venta_day 등)
    num? totalVentaDay;
    
    if (data != null && data.containsKey('summary') && data['summary'] is Map) {
      final summary = data['summary'] as Map<String, dynamic>;
      if (summary.containsKey('total_venta_day')) {
        final value = summary['total_venta_day'];
        if (value is num) {
          totalVentaDay = value;
        } else if (value is String) {
          totalVentaDay = num.tryParse(value.replaceAll(',', '').replaceAll('.', ''));
        }
      }
    } else if (data != null && data.containsKey('vcodes')) {
      if (data['vcodes'] is Map) {
        final vcodes = data['vcodes'] as Map<String, dynamic>;
        if (vcodes.containsKey('total_venta_day')) {
          final value = vcodes['total_venta_day'];
          if (value is num) {
            totalVentaDay = value;
          } else if (value is String) {
            totalVentaDay = num.tryParse(value.replaceAll(',', '').replaceAll('.', ''));
          }
        }
      } else if (data['vcodes'] is List && (data['vcodes'] as List).isNotEmpty) {
        final firstVcode = (data['vcodes'] as List).first;
        if (firstVcode is Map && firstVcode.containsKey('total_venta_day')) {
          final value = firstVcode['total_venta_day'];
          if (value is num) {
            totalVentaDay = value;
          } else if (value is String) {
            totalVentaDay = num.tryParse(value.replaceAll(',', '').replaceAll('.', ''));
          }
        }
      }
    }
    
    // summary나 vcodes에 없으면 테이블 데이터에서 계산
    if (totalVentaDay == null && data != null && data.containsKey('data') && data['data'] is List) {
      final dataList = data['data'] as List;
      num sum = 0;
      for (var item in dataList) {
        if (item is Map<String, dynamic>) {
          // tpago 필드 합계 계산
          final tpago = item['tpago'];
          if (tpago != null) {
            if (tpago is num) {
              sum += tpago;
            } else if (tpago is String) {
              final numValue = num.tryParse(tpago.replaceAll(',', '').replaceAll('.', ''));
              if (numValue != null) {
                sum += numValue;
              }
            }
          }
        }
      }
      if (sum > 0) {
        totalVentaDay = sum;
      }
    }
    
    return Column(
      children: [
        // 날짜 범위 선택
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: reportColor.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: reportColor.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: ItemsDateRangeSelector(
            reportType: reportType,
            startDate: startDate,
            endDate: endDate,
            onDateRangeChanged: onDateRangeChanged,
          ),
        ),
        // Total 및 Sucursal 선택
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: reportColor.withOpacity(0.1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Total Venta del Día 표시
              if (totalVentaDay != null && totalVentaDay! > 0) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: reportColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attach_money, color: reportColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Total: ${_formatNumber(totalVentaDay!)}',
                        style: TextStyle(
                          color: reportColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    hint: const Text('Todos', style: TextStyle(fontSize: 11)),
                    underline: const SizedBox(),
                    isDense: true,
                    icon: Icon(Icons.arrow_drop_down, color: reportColor, size: 18),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos', style: TextStyle(fontSize: 11)),
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
          ),
        ),
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
  
  /// 숫자 포맷팅 헬퍼 함수
  static String _formatNumber(dynamic value) {
    if (value == null) return '0';
    if (value is num) {
      return NumberFormat('#,###').format(value);
    }
    if (value is String) {
      final numValue = num.tryParse(value.replaceAll(',', '').replaceAll('.', ''));
      if (numValue != null) {
        return NumberFormat('#,###').format(numValue);
      }
      return value;
    }
    return value.toString();
  }
}

