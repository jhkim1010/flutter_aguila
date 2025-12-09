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
    required String unit, // 'vcode', 'day', 'month', 'year'
    required Function(DateTime, DateTime) onDateRangeChanged,
    required Function(String?) onSucursalChanged,
    required Function(String) onUnitChanged,
    required Color reportColor,
    required ReportType reportType,
    TextEditingController? filteringWordController,
    Function(String)? onFilteringWordSubmitted,
    Function()? onFilteringWordClear,
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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 600;
        
        // Unit에 따른 헤더 제목
        String headerTitle;
        switch (unit) {
          case 'vcode':
            headerTitle = 'Ventas Individuales';
            break;
          case 'day':
            headerTitle = 'Ventas por Día';
            break;
          case 'month':
            headerTitle = 'Ventas por Mes';
            break;
          case 'year':
            headerTitle = 'Ventas por Año';
            break;
          default:
            headerTitle = 'Reporte de Ventas';
        }
        
        return Column(
          children: [
            // 헤더 제목 (unit에 따라 다름)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: reportColor.withOpacity(0.15),
                border: Border(
                  bottom: BorderSide(
                    color: reportColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: reportColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    headerTitle,
                    style: TextStyle(
                      color: reportColor,
                      fontSize: isLargeScreen ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // 모든 컨트롤을 1줄에 배치: Unit 버튼 3개 + 달력 버튼 2개 + filteringWord 입력
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: reportColor.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: reportColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Unit 버튼 3개 (Day, Month, Year)
                  _buildUnitButton(
                    context: context,
                    label: 'Day',
                    value: 'day',
                    currentUnit: unit,
                    reportColor: reportColor,
                    onTap: () => onUnitChanged('day'),
                  ),
                  const SizedBox(width: 8),
                  _buildUnitButton(
                    context: context,
                    label: 'Month',
                    value: 'month',
                    currentUnit: unit,
                    reportColor: reportColor,
                    onTap: () => onUnitChanged('month'),
                  ),
                  const SizedBox(width: 8),
                  _buildUnitButton(
                    context: context,
                    label: 'Year',
                    value: 'year',
                    currentUnit: unit,
                    reportColor: reportColor,
                    onTap: () => onUnitChanged('year'),
                  ),
                  const SizedBox(width: 12),
                  // 달력 버튼 2개 (시작일, 종료일)
                  Expanded(
                    flex: 2,
                    child: _buildDateButton(
                      context: context,
                      label: 'Inicio',
                      date: startDate,
                      unit: unit,
                      reportColor: reportColor,
                      onTap: () => _selectStartDate(context, startDate, endDate, unit, reportColor, reportType, onDateRangeChanged),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _buildDateButton(
                      context: context,
                      label: 'Fin',
                      date: endDate,
                      unit: unit,
                      reportColor: reportColor,
                      onTap: () => _selectEndDate(context, startDate, endDate, unit, reportColor, reportType, onDateRangeChanged),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // filteringWord 입력 필드
                  if (filteringWordController != null)
                    Expanded(
                      flex: 3,
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: filteringWordController,
                        builder: (context, value, child) {
                          return Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: reportColor.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: filteringWordController,
                              style: TextStyle(
                                color: reportColor,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Filtrar...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                prefixIcon: Icon(Icons.search, color: reportColor, size: 18),
                                suffixIcon: value.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear, color: reportColor, size: 18),
                                        onPressed: onFilteringWordClear ?? () {
                                          filteringWordController.clear();
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      )
                                    : null,
                              ),
                              onSubmitted: onFilteringWordSubmitted,
                            ),
                          );
                        },
                      ),
                    ),
                ],
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
              // Total 표시 (unit에 따라 다른 레이블)
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
                        _getTotalLabel(unit) + ': ${_formatNumber(totalVentaDay!)}',
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
      },
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
  
  /// Unit 선택 버튼 빌드
  static Widget _buildUnitButton({
    required BuildContext context,
    required String label,
    required String value,
    required String currentUnit,
    required Color reportColor,
    required VoidCallback onTap,
  }) {
    final isSelected = currentUnit == value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? reportColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? reportColor : reportColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : reportColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 날짜 선택 버튼 빌드
  static Widget _buildDateButton({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required String? unit,
    required Color reportColor,
    required VoidCallback onTap,
  }) {
    String dateText = 'Seleccionar';
    DateFormat dateFormat;
    
    if (unit == 'year') {
      dateFormat = DateFormat('yyyy');
    } else if (unit == 'month') {
      dateFormat = DateFormat('yyyy-MM');
    } else {
      dateFormat = DateFormat('yyyy-MM-dd');
    }
    
    if (date != null) {
      dateText = dateFormat.format(date);
    }
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: reportColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              unit == 'year'
                  ? Icons.event
                  : unit == 'month'
                      ? Icons.calendar_view_month
                      : Icons.calendar_today,
              color: reportColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$label: $dateText',
                style: TextStyle(
                  color: reportColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 시작일 선택
  static Future<void> _selectStartDate(
    BuildContext context,
    DateTime? startDate,
    DateTime? endDate,
    String? unit,
    Color reportColor,
    ReportType reportType,
    Function(DateTime, DateTime) onDateRangeChanged,
  ) async {
    DateTime? picked;
    final initialDate = startDate ?? DateTime.now();
    
    if (unit == 'year') {
      picked = await _selectYearDialog(context, initialDate, endDate, reportColor, reportType);
    } else if (unit == 'month') {
      picked = await _selectYearMonthDialog(context, initialDate, endDate, reportColor, reportType);
    } else {
      picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: endDate ?? DateTime.now(),
        locale: const Locale('es', 'ES'),
      );
    }
    
    if (picked != null) {
      final newStartDate = picked;
      final newEndDate = (endDate != null && endDate.isBefore(picked)) ? picked : endDate ?? picked;
      onDateRangeChanged(newStartDate, newEndDate);
    }
  }

  /// 종료일 선택
  static Future<void> _selectEndDate(
    BuildContext context,
    DateTime? startDate,
    DateTime? endDate,
    String? unit,
    Color reportColor,
    ReportType reportType,
    Function(DateTime, DateTime) onDateRangeChanged,
  ) async {
    DateTime? picked;
    final initialDate = endDate ?? DateTime.now();
    
    if (unit == 'year') {
      picked = await _selectYearDialog(context, initialDate, null, reportColor, reportType, minDate: startDate);
    } else if (unit == 'month') {
      picked = await _selectYearMonthDialog(context, initialDate, null, reportColor, reportType, minDate: startDate);
    } else {
      picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: startDate ?? DateTime(2000),
        lastDate: DateTime.now(),
        locale: const Locale('es', 'ES'),
      );
    }
    
    if (picked != null) {
      final newEndDate = picked;
      final newStartDate = (startDate != null && picked.isBefore(startDate)) ? picked : startDate ?? picked;
      onDateRangeChanged(newStartDate, newEndDate);
    }
  }

  /// 연도 선택 다이얼로그
  static Future<DateTime?> _selectYearDialog(
    BuildContext context,
    DateTime initialDate,
    DateTime? maxDate,
    Color reportColor,
    ReportType reportType, {
    DateTime? minDate,
  }) async {
    final currentYear = initialDate.year;
    final minYear = minDate?.year ?? 2000;
    final maxYear = maxDate?.year ?? DateTime.now().year;
    
    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        int selectedYear = currentYear;
        
        return AlertDialog(
          title: const Text('Seleccionar Año'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: maxYear - minYear + 1,
                        itemBuilder: (context, index) {
                          final year = maxYear - index;
                          final isSelected = selectedYear == year;
                          
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedYear = year;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? reportColor.withOpacity(0.2)
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isSelected ? reportColor : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (isSelected)
                                    Icon(Icons.check_circle, color: reportColor, size: 20)
                                  else
                                    const Icon(Icons.circle_outlined, color: Colors.grey, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    '$year',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? reportColor : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, DateTime(selectedYear));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: reportColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 연도와 월 선택 다이얼로그
  static Future<DateTime?> _selectYearMonthDialog(
    BuildContext context,
    DateTime initialDate,
    DateTime? maxDate,
    Color reportColor,
    ReportType reportType, {
    DateTime? minDate,
  }) async {
    final currentYear = initialDate.year;
    final currentMonth = initialDate.month;
    final minYear = minDate?.year ?? 2000;
    final maxYear = maxDate?.year ?? DateTime.now().year;
    
    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        int selectedYear = currentYear;
        int selectedMonth = currentMonth;
        
        return AlertDialog(
          title: const Text('Seleccionar Año y Mes'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    Text(
                      'Año: $selectedYear',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: selectedYear > minYear
                              ? () => setState(() => selectedYear--)
                              : null,
                        ),
                        SizedBox(
                          width: 100,
                          child: Text('$selectedYear', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: selectedYear < maxYear
                              ? () => setState(() => selectedYear++)
                              : null,
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final month = index + 1;
                          final isSelected = selectedMonth == month;
                          final monthDate = DateTime(selectedYear, month);
                          final isDisabled = (minDate != null && monthDate.isBefore(DateTime(minDate.year, minDate.month))) ||
                              (maxDate != null && DateTime(maxDate.year, maxDate.month).isBefore(monthDate));
                          
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: InkWell(
                              onTap: isDisabled
                                  ? null
                                  : () => setState(() => selectedMonth = month),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? reportColor : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? reportColor : Colors.grey[400]!,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _getMonthName(month),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDisabled ? Colors.grey[400] : Colors.black),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, DateTime(selectedYear, selectedMonth));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: reportColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 월 이름 반환
  static String _getMonthName(int month) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return months[month - 1];
  }

  /// Unit에 따른 Total 레이블 반환
  static String _getTotalLabel(String unit) {
    switch (unit) {
      case 'vcode':
        return 'Total Ventas';
      case 'day':
        return 'Total del Día';
      case 'month':
        return 'Total del Mes';
      case 'year':
        return 'Total del Año';
      default:
        return 'Total';
    }
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

