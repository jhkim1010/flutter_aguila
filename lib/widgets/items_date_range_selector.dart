import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'report_utils.dart';

class ItemsDateRangeSelector extends StatefulWidget {
  final ReportType reportType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? unit; // 'vcode', 'day', 'month', 'year' - ventas 보고서용
  final Function(DateTime startDate, DateTime endDate) onDateRangeChanged;

  const ItemsDateRangeSelector({
    super.key,
    required this.reportType,
    this.startDate,
    this.endDate,
    this.unit, // unit 파라미터 추가
    required this.onDateRangeChanged,
  });

  @override
  State<ItemsDateRangeSelector> createState() => _ItemsDateRangeSelectorState();
}

class _ItemsDateRangeSelectorState extends State<ItemsDateRangeSelector> {
  late DateTime? _startDate;
  late DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  void didUpdateWidget(ItemsDateRangeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startDate != oldWidget.startDate) {
      _startDate = widget.startDate;
    }
    if (widget.endDate != oldWidget.endDate) {
      _endDate = widget.endDate;
    }
  }

  /// 날짜 범위 선택 (하나의 달력에서 시작일과 종료일 선택)
  Future<void> _selectDateRange() async {
    if (widget.unit == 'year') {
      // 연도 범위 선택 (이전 방식)
      await _selectYearRange();
    } else if (widget.unit == 'month') {
      // 월 범위 선택 (이전 방식)
      await _selectMonthRange();
    } else {
      // 일반 날짜 범위 선택 (vcode, day) - showDateRangePicker 사용
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // 기본값: 기존 범위가 있으면 사용, 없으면 오늘~오늘
      final defaultRange = _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(start: today, end: today);
      
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        initialDateRange: defaultRange,
        firstDate: DateTime(2000),
        lastDate: today,
        locale: const Locale('es', 'ES'),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: ReportUtils.getReportColor(widget.reportType),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        // 선택한 범위 적용
        final selectedStartDate = picked.start;
        final selectedEndDate = picked.end;
        
        // 시작일이 오늘보다 미래면 오늘로 제한
        final finalStartDate = selectedStartDate.isAfter(today) 
            ? today 
            : selectedStartDate;
        final finalEndDate = selectedEndDate.isAfter(today) 
            ? today 
            : selectedEndDate;
        
        setState(() {
          _startDate = finalStartDate;
          _endDate = finalEndDate;
        });
        widget.onDateRangeChanged(finalStartDate, finalEndDate);
      }
    }
  }

  /// 연도 범위 선택
  Future<void> _selectYearRange() async {
    final startYear = await _selectYear(
      initialDate: _startDate ?? DateTime.now(),
      maxDate: _endDate,
    );
    
    if (startYear != null) {
      final adjustedStartDate = DateTime(startYear.year, 1, 1);
      final endYear = await _selectYear(
        initialDate: _endDate ?? adjustedStartDate,
        minDate: adjustedStartDate,
      );
      
      if (endYear != null) {
        final adjustedEndDate = DateTime(endYear.year, 12, 31);
        setState(() {
          _startDate = adjustedStartDate;
          _endDate = adjustedEndDate;
        });
        widget.onDateRangeChanged(adjustedStartDate, adjustedEndDate);
      }
    }
  }

  /// 월 범위 선택
  Future<void> _selectMonthRange() async {
    final startMonth = await _selectYearMonth(
      initialDate: _startDate ?? DateTime.now(),
      maxDate: _endDate,
    );
    
    if (startMonth != null) {
      final adjustedStartDate = DateTime(startMonth.year, startMonth.month, 1);
      final endMonth = await _selectYearMonth(
        initialDate: _endDate ?? adjustedStartDate,
        minDate: adjustedStartDate,
      );
      
      if (endMonth != null) {
        final adjustedEndDate = DateTime(endMonth.year, endMonth.month + 1, 0);
        setState(() {
          _startDate = adjustedStartDate;
          _endDate = adjustedEndDate;
        });
        widget.onDateRangeChanged(adjustedStartDate, adjustedEndDate);
      }
    }
  }

  /// 연도 선택 다이얼로그
  Future<DateTime?> _selectYear({
    required DateTime initialDate,
    DateTime? minDate,
    DateTime? maxDate,
  }) async {
    final currentYear = initialDate.year;
    final minYear = minDate?.year ?? 2000;
    final maxYear = maxDate?.year ?? DateTime.now().year;
    
    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        int selectedYear = currentYear;
        final reportColor = ReportUtils.getReportColor(widget.reportType);
        
        return AlertDialog(
          title: const Text('Seleccionar Año'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    // 연도 선택 (스크롤 가능한 리스트)
                    Expanded(
                      child: ListView.builder(
                        itemCount: maxYear - minYear + 1,
                        itemBuilder: (context, index) {
                          final year = maxYear - index; // 최신 연도부터 표시
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
                                    Icon(
                                      Icons.check_circle,
                                      color: reportColor,
                                      size: 20,
                                    )
                                  else
                                    const Icon(
                                      Icons.circle_outlined,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
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
  Future<DateTime?> _selectYearMonth({
    required DateTime initialDate,
    DateTime? minDate,
    DateTime? maxDate,
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
                    // 연도 선택
                    Text(
                      'Año: $selectedYear',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: selectedYear > minYear
                              ? () {
                                  setState(() {
                                    selectedYear--;
                                  });
                                }
                              : null,
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            '$selectedYear',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: selectedYear < maxYear
                              ? () {
                                  setState(() {
                                    selectedYear++;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                    const Divider(),
                    // 월 선택
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
                                  : () {
                                      setState(() {
                                        selectedMonth = month;
                                      });
                                    },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? ReportUtils.getReportColor(widget.reportType)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? ReportUtils.getReportColor(widget.reportType)
                                        : Colors.grey[400]!,
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
                        Navigator.pop(
                          context,
                          DateTime(selectedYear, selectedMonth),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ReportUtils.getReportColor(widget.reportType),
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

  String _getMonthName(int month) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final reportColor = ReportUtils.getReportColor(widget.reportType);
    DateFormat dateFormat;

    // unit에 따라 포맷 결정
    if (widget.unit == 'year') {
      dateFormat = DateFormat('yyyy');
    } else if (widget.unit == 'month') {
      dateFormat = DateFormat('yyyy-MM');
    } else {
      // vcode, day
      dateFormat = DateFormat('yyyy-MM-dd');
    }

    // 날짜 범위 표시 문자열 생성
    String rangeDisplay;
    if (_startDate != null && _endDate != null) {
      if (widget.unit == 'year') {
        rangeDisplay = '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}';
      } else if (widget.unit == 'month') {
        rangeDisplay = '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}';
      } else {
        rangeDisplay = '${dateFormat.format(_startDate!)} ~ ${dateFormat.format(_endDate!)}';
      }
    } else {
      rangeDisplay = 'Seleccionar rango';
    }

    return Container(
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
      child: GestureDetector(
        onTap: _selectDateRange,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: reportColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.unit == 'year'
                          ? 'Rango de Años'
                          : widget.unit == 'month'
                              ? 'Rango de Meses'
                              : 'Rango de Fechas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rangeDisplay,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                widget.unit == 'year'
                    ? Icons.event
                    : widget.unit == 'month'
                        ? Icons.calendar_view_month
                        : Icons.date_range,
                color: reportColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

