import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:intl/intl.dart';
import 'report_utils.dart';
import 'report_filters.dart';
import 'report_header_builders.dart';
import '../utils/platform_utils.dart';

/// AppBar 관련 빌더 함수들을 모아놓은 클래스
class ReportAppBarBuilders {
  /// Ventas 보고서의 Unit 버튼들 (AppBar용)
  static Widget buildVentasUnitButtonsInAppBar({
    required BuildContext context,
    required String ventasUnit,
    required Color reportColor,
    required Function(String) onUnitChanged,
    required VoidCallback onLoadData,
  }) {
    return Builder(
      builder: (context) {
        final platformType = PlatformUtils.getPlatformType(context);
        final size = MediaQuery.of(context).size;
        final isLargeScreen = (platformType == PlatformType.desktop || 
                              PlatformUtils.isIPad(context)) && 
                             size.width >= 800;
        
        if (isLargeScreen) {
          // 큰 화면: 버튼 4개를 나란히 표시 (VCode, Day, Month, Year)
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 70,
                child: buildCompactUnitButton(
                  label: 'VCode',
                  value: 'vcode',
                  reportColor: reportColor,
                  ventasUnit: ventasUnit,
                  onUnitChanged: onUnitChanged,
                  onLoadData: onLoadData,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 65,
                child: buildCompactUnitButton(
                  label: 'Day',
                  value: 'day',
                  reportColor: reportColor,
                  ventasUnit: ventasUnit,
                  onUnitChanged: onUnitChanged,
                  onLoadData: onLoadData,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 75,
                child: buildCompactUnitButton(
                  label: 'Month',
                  value: 'month',
                  reportColor: reportColor,
                  ventasUnit: ventasUnit,
                  onUnitChanged: onUnitChanged,
                  onLoadData: onLoadData,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 70,
                child: buildCompactUnitButton(
                  label: 'Year',
                  value: 'year',
                  reportColor: reportColor,
                  ventasUnit: ventasUnit,
                  onUnitChanged: onUnitChanged,
                  onLoadData: onLoadData,
                ),
              ),
            ],
          );
        } else {
          // 작은 화면: 드롭다운 사용
          return buildCompactUnitDropdown(
            reportColor: reportColor,
            ventasUnit: ventasUnit,
            onUnitChanged: onUnitChanged,
            onLoadData: onLoadData,
          );
        }
      },
    );
  }

  /// 컴팩트한 Unit 버튼 (AppBar용)
  static Widget buildCompactUnitButton({
    required String label,
    required String value,
    required Color reportColor,
    required String ventasUnit,
    required Function(String) onUnitChanged,
    required VoidCallback onLoadData,
  }) {
    final isSelected = ventasUnit == value;
    debugPrint('🔵 buildCompactUnitButton 호출: label=$label, value=$value, isSelected=$isSelected, 현재 ventasUnit=$ventasUnit');
    
    return SizedBox(
      height: 28,
      child: TextButton(
        onPressed: () {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔵 Unit 버튼 클릭 이벤트 발생');
          debugPrint('   - 버튼 라벨: $label');
          debugPrint('   - 버튼 값: $value');
          debugPrint('   - 현재 선택된 unit: $ventasUnit');
          debugPrint('   - 이전 상태: isSelected=$isSelected');
          
          onUnitChanged(value);
          debugPrint('   → onLoadData() 호출 시작');
          onLoadData();
          debugPrint('═══════════════════════════════════════════════════════');
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: isSelected ? reportColor : Colors.white,
          foregroundColor: isSelected ? Colors.white : reportColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: isSelected ? reportColor : reportColor.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : reportColor,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 컴팩트한 Unit Dropdown (AppBar용)
  static Widget buildCompactUnitDropdown({
    required Color reportColor,
    required String ventasUnit,
    required Function(String) onUnitChanged,
    required VoidCallback onLoadData,
  }) {
    String getUnitLabel(String unit) {
      switch (unit) {
        case 'vcode':
          return 'VCode';
        case 'day':
          return 'Day';
        case 'month':
          return 'Month';
        case 'year':
          return 'Year';
        default:
          return 'VCode';
      }
    }

    final validUnits = ['vcode', 'day', 'month', 'year'];
    final displayUnit = validUnits.contains(ventasUnit) ? ventasUnit : 'vcode';

    return Container(
      constraints: const BoxConstraints(minWidth: 60),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: reportColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: DropdownButton<String>(
        value: displayUnit,
        isDense: true,
        isExpanded: false,
        underline: const SizedBox.shrink(),
        icon: Icon(Icons.arrow_drop_down, color: reportColor, size: 18),
        style: TextStyle(
          color: reportColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        items: validUnits.map((String unit) {
          return DropdownMenuItem<String>(
            value: unit,
            child: Text(
              getUnitLabel(unit),
              style: TextStyle(
                color: reportColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newUnit) {
          if (newUnit != null) {
            onUnitChanged(newUnit);
            onLoadData();
          }
        },
      ),
    );
  }

  /// 단일 날짜 선택 버튼 (AppBar용)
  static Widget buildSingleDateButton({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required Color reportColor,
    required Function(DateTime) onDateSelected,
    required ReportType reportType,
    String? unit, // ventas 보고서용 unit (vcode, day, month, year)
  }) {
    String dateText;
    IconData iconData;
    
    if (unit == 'year') {
      dateText = date != null ? DateFormat('yyyy').format(date) : label;
      iconData = Icons.event;
    } else if (unit == 'month') {
      dateText = date != null ? DateFormat('yyyy-MM').format(date) : label;
      iconData = Icons.calendar_view_month;
    } else {
      dateText = date != null ? DateFormat('yyyy-MM-dd').format(date) : label;
      iconData = Icons.calendar_today;
    }
    
    return InkWell(
      onTap: () async {
        DateTime? picked;
        
        if (unit == 'year') {
          // 연도 선택
          picked = await ReportHeaderBuilders.selectYearDialog(
            context,
            date ?? DateTime.now(),
            DateTime.now(),
            reportColor,
            reportType,
            title: label,
          );
        } else if (unit == 'month') {
          // 월 선택
          picked = await ReportHeaderBuilders.selectYearMonthDialog(
            context,
            date ?? DateTime.now(),
            DateTime.now(),
            reportColor,
            reportType,
            title: label,
          );
        } else {
          // 일반 날짜 선택 (vcode, day)
          picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
            locale: const Locale('es', 'ES'),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: reportColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );
        }
        
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: reportColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              color: reportColor,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              dateText,
              style: TextStyle(
                color: reportColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 컴팩트한 날짜 범위 버튼 (AppBar용)
  static Widget buildCompactDateRangeButton({
    required BuildContext context,
    required Color reportColor,
    required String ventasUnit,
    required DateTime? ventasStartDate,
    required DateTime? ventasEndDate,
    required ReportType reportType,
    required Function(DateTime, DateTime) onDateRangeChanged,
  }) {
    String rangeText = 'Rango';
    DateFormat dateFormat;
    
    if (ventasUnit == 'year') {
      dateFormat = DateFormat('yyyy');
    } else if (ventasUnit == 'month') {
      dateFormat = DateFormat('yyyy-MM');
    } else {
      dateFormat = DateFormat('yyyy-MM-dd');
    }
    
    if (ventasStartDate != null && ventasEndDate != null) {
      if (ventasUnit == 'year' || ventasUnit == 'month') {
        rangeText = '${dateFormat.format(ventasStartDate)} - ${dateFormat.format(ventasEndDate)}';
      } else {
        rangeText = '${dateFormat.format(ventasStartDate)} ~ ${dateFormat.format(ventasEndDate)}';
      }
      // 텍스트가 너무 길면 줄임
      if (rangeText.length > 12) {
        rangeText = '${rangeText.substring(0, 10)}...';
      }
    }
    
    return InkWell(
      onTap: () => ReportHeaderBuilders.selectDateRange(
        context,
        ventasStartDate,
        ventasEndDate,
        ventasUnit,
        reportColor,
        reportType,
        onDateRangeChanged,
      ),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: reportColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ventasUnit == 'year'
                  ? Icons.event
                  : ventasUnit == 'month'
                      ? Icons.calendar_view_month
                      : Icons.date_range,
              color: reportColor,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                rangeText,
                style: TextStyle(
                  color: reportColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 필터링 단어 필드 (AppBar용)
  static Widget buildFilteringWordFieldInAppBar({
    required TextEditingController controller,
    required VoidCallback onSubmitted,
    required VoidCallback onClear,
  }) {
    return ReportFilters.buildFilteringWordField(
      controller: controller,
      onSubmitted: (value) => onSubmitted(),
      onClear: onClear,
    );
  }

  /// 지점 선택 UI (AppBar용)
  static Widget buildSucursalSelector({
    required String? selectedSucursal,
    required List<String>? availableSucursales,
    required Color reportColor,
    required Function(String?) onSucursalChanged,
  }) {
    return SizedBox(
      width: 140, // 명시적 너비 설정
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: DropdownButton<String?>(
          value: selectedSucursal,
          hint: const Text('Todos', style: TextStyle(fontSize: 12)),
          underline: const SizedBox(),
          isDense: true,
          isExpanded: false, // AppBar의 Row 안에서는 false로 설정
          icon: Icon(Icons.arrow_drop_down, color: reportColor, size: 20),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todos', style: TextStyle(fontSize: 12)),
            ),
            if (availableSucursales != null)
              ...availableSucursales.map((sucursal) {
                return DropdownMenuItem<String?>(
                  value: sucursal,
                  child: Text('Sucursal $sucursal', style: const TextStyle(fontSize: 12)),
                );
              }),
          ],
          onChanged: (value) {
            onSucursalChanged(value);
          },
        ),
      ),
    );
  }

  /// Stocks 보고서의 View Type 선택기 (AppBar용)
  static Widget buildStocksViewTypeInAppBar({
    required Map<String, dynamic>? data,
    required String? selectedSucursal,
    required Function(String?) onSucursalChanged,
  }) {
    if (data == null || !data.containsKey('filters')) {
      return const SizedBox.shrink();
    }
    
    final filters = data['filters'] as Map<String, dynamic>?;
    if (filters == null || !filters.containsKey('bcolorview')) {
      return const SizedBox.shrink();
    }
    
    final bcolorview = filters['bcolorview'];
    final isBcolorviewEnabled = ReportUtils.isBcolorviewEnabled(bcolorview);
    final viewType = isBcolorviewEnabled ? 'Vista Resumida' : 'VistaD';
    
    // Vista Detallada일 때만 sucursal 필터 표시
    final bool showSucursalFilter = !isBcolorviewEnabled;
    List<String>? sucursales;
    
    if (showSucursalFilter && data.containsKey('data') && data['data'] is List) {
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
      
      sucursales = sucursalSet.toList()..sort((a, b) {
        final aNum = int.tryParse(a) ?? 0;
        final bNum = int.tryParse(b) ?? 0;
        return aNum.compareTo(bNum);
      });
    }
    
    // bcolorview 값에 따라 색상 결정
    Color reportColor = Colors.orange; // 기본값
    if (filters.containsKey('bcolorview')) {
      final bcolorviewValue = filters['bcolorview'];
      reportColor = ReportUtils.isBcolorviewEnabled(bcolorviewValue) ? Colors.orange : Colors.lightBlue;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isBcolorviewEnabled ? Icons.view_compact : Icons.view_list,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          viewType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // Sucursal이 2개 이상일 때만 콤보박스 표시
        if (showSucursalFilter && sucursales != null && sucursales.length > 1)
          ...[
            const SizedBox(width: 12),
            Container(
              constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: DropdownButton<String?>(
                value: selectedSucursal,
                hint: const Text('모두', style: TextStyle(fontSize: 12, color: Colors.white)),
                underline: const SizedBox(),
                isDense: true,
                dropdownColor: reportColor,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                style: const TextStyle(fontSize: 12, color: Colors.white),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('모두', style: TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  ...sucursales.map((sucursal) {
                    return DropdownMenuItem<String?>(
                      value: sucursal,
                      child: Text(sucursal, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    );
                  }),
                ],
                onChanged: onSucursalChanged,
              ),
            ),
          ],
      ],
    );
  }
}

