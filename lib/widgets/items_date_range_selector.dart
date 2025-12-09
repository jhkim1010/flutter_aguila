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

  Future<void> _selectStartDate() async {
    DateTime? picked;
    
    if (widget.unit == 'year') {
      // 연도만 선택
      picked = await _selectYear(
        initialDate: _startDate ?? DateTime.now(),
        maxDate: _endDate,
      );
    } else if (widget.unit == 'month') {
      // 연도와 월 선택
      picked = await _selectYearMonth(
        initialDate: _startDate ?? DateTime.now(),
        maxDate: _endDate,
      );
    } else {
      // 전체 날짜 선택 (vcode, day)
      picked = await showDatePicker(
        context: context,
        initialDate: _startDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: _endDate ?? DateTime.now(),
        locale: const Locale('es', 'ES'),
      );
    }

    if (picked != null) {
      final endDate = _endDate;
      DateTime adjustedStartDate = picked!;
      
      // month unit일 때는 시작 날짜를 해당 월의 1일로 설정
      if (widget.unit == 'month') {
        adjustedStartDate = DateTime(picked.year, picked.month, 1);
      }
      // year unit일 때는 시작 날짜를 해당 연도의 1월 1일로 설정
      else if (widget.unit == 'year') {
        adjustedStartDate = DateTime(picked.year, 1, 1);
      }
      
      setState(() {
        _startDate = adjustedStartDate;
        if (endDate != null && endDate.isBefore(adjustedStartDate)) {
          _endDate = adjustedStartDate;
        }
      });
      widget.onDateRangeChanged(
        adjustedStartDate,
        _endDate ?? adjustedStartDate,
      );
    }
  }

  Future<void> _selectEndDate() async {
    DateTime? picked;
    
    if (widget.unit == 'year') {
      // 연도만 선택
      picked = await _selectYear(
        initialDate: _endDate ?? DateTime.now(),
        minDate: _startDate,
      );
    } else if (widget.unit == 'month') {
      // 연도와 월 선택
      picked = await _selectYearMonth(
        initialDate: _endDate ?? DateTime.now(),
        minDate: _startDate,
      );
    } else {
      // 전체 날짜 선택 (vcode, day)
      picked = await showDatePicker(
        context: context,
        initialDate: _endDate ?? DateTime.now(),
        firstDate: _startDate ?? DateTime(2000),
        lastDate: DateTime.now(),
        locale: const Locale('es', 'ES'),
      );
    }

    if (picked != null) {
      final startDate = _startDate;
      DateTime adjustedEndDate = picked!;
      
      // month unit일 때는 종료 날짜를 해당 월의 마지막 날로 설정
      if (widget.unit == 'month') {
        // 다음 달의 0일 = 이번 달의 마지막 날
        adjustedEndDate = DateTime(picked.year, picked.month + 1, 0);
      }
      // year unit일 때는 종료 날짜를 해당 연도의 12월 31일로 설정
      else if (widget.unit == 'year') {
        adjustedEndDate = DateTime(picked.year, 12, 31);
      }
      
      setState(() {
        _endDate = adjustedEndDate;
        if (startDate != null && adjustedEndDate.isBefore(startDate)) {
          _startDate = adjustedEndDate;
        }
      });
      widget.onDateRangeChanged(
        _startDate ?? adjustedEndDate,
        adjustedEndDate,
      );
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
    String startLabel;
    String endLabel;
    String startValue;
    String endValue;
    DateFormat dateFormat;

    // unit에 따라 레이블과 포맷 결정
    if (widget.unit == 'year') {
      startLabel = 'Año Inicio';
      endLabel = 'Año Fin';
      dateFormat = DateFormat('yyyy');
      startValue = _startDate != null ? dateFormat.format(_startDate!) : 'Seleccionar';
      endValue = _endDate != null ? dateFormat.format(_endDate!) : 'Seleccionar';
    } else if (widget.unit == 'month') {
      startLabel = 'Mes Inicio';
      endLabel = 'Mes Fin';
      dateFormat = DateFormat('yyyy-MM');
      startValue = _startDate != null ? dateFormat.format(_startDate!) : 'Seleccionar';
      endValue = _endDate != null ? dateFormat.format(_endDate!) : 'Seleccionar';
    } else {
      // vcode, day
      startLabel = 'Fecha Inicio';
      endLabel = 'Fecha Fin';
      dateFormat = DateFormat('yyyy-MM-dd');
      startValue = _startDate != null ? dateFormat.format(_startDate!) : 'Seleccionar';
      endValue = _endDate != null ? dateFormat.format(_endDate!) : 'Seleccionar';
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
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _selectStartDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          startLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          startValue,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      widget.unit == 'year'
                          ? Icons.event
                          : widget.unit == 'month'
                              ? Icons.calendar_view_month
                              : Icons.calendar_today,
                      color: reportColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _selectEndDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          endLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          endValue,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      widget.unit == 'year'
                          ? Icons.event
                          : widget.unit == 'month'
                              ? Icons.calendar_view_month
                              : Icons.calendar_today,
                      color: reportColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

