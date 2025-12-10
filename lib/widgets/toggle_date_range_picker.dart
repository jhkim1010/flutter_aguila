import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 토글 방식으로 시작일과 종료일을 번갈아가며 선택하는 날짜 범위 선택기
class ToggleDateRangePicker {
  /// 날짜 범위 선택 다이얼로그 표시
  /// 
  /// 동작 방식:
  /// 1. 달력 시작 시 종료일은 오늘로 초기화
  /// 2. 첫 번째 선택: 시작일 선택
  /// 3. 두 번째 선택: 종료일 선택
  /// 4. 세 번째 선택: 다시 시작일 선택
  /// 5. 이런 식으로 번갈아가며 선택
  static Future<DateTimeRange?> show({
    required BuildContext context,
    required Color reportColor,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    String? unit, // 'vcode', 'day', 'month', 'year'
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 초기값 설정: 종료일은 항상 오늘로 초기화
    DateTime? startDate = initialStartDate;
    DateTime endDate = initialEndDate ?? today;
    
    // 다음에 선택할 것이 시작일인지 종료일인지 (true = 시작일, false = 종료일)
    bool selectStartDate = startDate == null;
    
    return showDialog<DateTimeRange>(
      context: context,
      builder: (context) {
        return _ToggleDateRangePickerDialog(
          reportColor: reportColor,
          initialStartDate: startDate,
          initialEndDate: endDate,
          initialSelectStartDate: selectStartDate,
          today: today,
          unit: unit,
        );
      },
    );
  }
}

class _ToggleDateRangePickerDialog extends StatefulWidget {
  final Color reportColor;
  final DateTime? initialStartDate;
  final DateTime initialEndDate;
  final bool initialSelectStartDate;
  final DateTime today;
  final String? unit; // 'vcode', 'day', 'month', 'year'

  const _ToggleDateRangePickerDialog({
    required this.reportColor,
    this.initialStartDate,
    required this.initialEndDate,
    required this.initialSelectStartDate,
    required this.today,
    this.unit,
  });

  @override
  State<_ToggleDateRangePickerDialog> createState() => _ToggleDateRangePickerDialogState();
}

class _ToggleDateRangePickerDialogState extends State<_ToggleDateRangePickerDialog> {
  late DateTime? _startDate;
  late DateTime _endDate;
  late bool _selectStartDate; // true = 시작일 선택 중, false = 종료일 선택 중
  late DateFormat _dateFormat;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _selectStartDate = widget.initialSelectStartDate;
    
    // unit에 따라 날짜 포맷 결정
    if (widget.unit == 'year') {
      _dateFormat = DateFormat('yyyy');
    } else if (widget.unit == 'month') {
      _dateFormat = DateFormat('yyyy-MM');
    } else {
      _dateFormat = DateFormat('yyyy-MM-dd');
    }
    
    // 시작일이 없으면 종료일을 오늘로 초기화
    if (_startDate == null) {
      _endDate = widget.today;
    }
  }

  void _onDateSelected(DateTime selectedDate) {
    setState(() {
      DateTime adjustedDate = selectedDate;
      
      // unit에 따라 날짜 조정
      if (widget.unit == 'year') {
        adjustedDate = DateTime(selectedDate.year, 1, 1);
      } else if (widget.unit == 'month') {
        adjustedDate = DateTime(selectedDate.year, selectedDate.month, 1);
      }
      
      if (_selectStartDate) {
        // 시작일 선택
        _startDate = adjustedDate;
        // 시작일이 종료일보다 늦으면 종료일을 시작일로 설정
        if (_startDate!.isAfter(_endDate)) {
          _endDate = _startDate!;
        }
        // 다음에는 종료일 선택
        _selectStartDate = false;
      } else {
        // 종료일 선택
        // 시작일이 없으면 시작일로 설정
        if (_startDate == null) {
          _startDate = adjustedDate;
          _endDate = widget.today;
          _selectStartDate = false;
        } else {
          // 종료일이 시작일보다 이전이면 시작일로 설정하고, 다음에는 종료일 선택
          if (adjustedDate.isBefore(_startDate!)) {
            _startDate = adjustedDate;
            _selectStartDate = false;
          } else {
            // unit에 따라 종료일 조정
            if (widget.unit == 'year') {
              _endDate = DateTime(adjustedDate.year, 12, 31);
            } else if (widget.unit == 'month') {
              _endDate = DateTime(adjustedDate.year, adjustedDate.month + 1, 0);
            } else {
              _endDate = adjustedDate;
            }
            // 다음에는 시작일 선택
            _selectStartDate = true;
          }
        }
      }
    });
  }

  void _confirmSelection() {
    if (_startDate != null) {
      Navigator.pop(context, DateTimeRange(start: _startDate!, end: _endDate));
    }
  }

  void _cancel() {
    Navigator.pop(context);
  }

  String _formatDate(DateTime date) {
    if (widget.unit == 'year') {
      return DateFormat('yyyy').format(date);
    } else if (widget.unit == 'month') {
      return DateFormat('yyyy-MM').format(date);
    } else {
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.date_range, color: widget.reportColor),
          const SizedBox(width: 8),
          const Text('Seleccionar Rango'),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 현재 선택 상태 표시
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.reportColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectStartDate ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: _selectStartDate ? widget.reportColor : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Inicio:',
                        style: TextStyle(
                          fontWeight: _selectStartDate ? FontWeight.bold : FontWeight.normal,
                          color: _selectStartDate ? widget.reportColor : Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _startDate != null ? _dateFormat.format(_startDate!) : 'No seleccionado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _startDate != null ? widget.reportColor : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        !_selectStartDate ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: !_selectStartDate ? widget.reportColor : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fin:',
                        style: TextStyle(
                          fontWeight: !_selectStartDate ? FontWeight.bold : FontWeight.normal,
                          color: !_selectStartDate ? widget.reportColor : Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(_endDate),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.reportColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 달력
            SizedBox(
              height: 300,
              child: _CustomCalendar(
                reportColor: widget.reportColor,
                startDate: _startDate,
                endDate: _endDate,
                selectStartDate: _selectStartDate,
                today: widget.today,
                unit: widget.unit,
                onDateSelected: _onDateSelected,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _startDate != null ? _confirmSelection : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.reportColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

/// 커스텀 달력 위젯 (반복적으로 날짜 선택 가능)
class _CustomCalendar extends StatefulWidget {
  final Color reportColor;
  final DateTime? startDate;
  final DateTime endDate;
  final bool selectStartDate;
  final DateTime today;
  final String? unit; // 'vcode', 'day', 'month', 'year'
  final Function(DateTime) onDateSelected;

  const _CustomCalendar({
    required this.reportColor,
    required this.startDate,
    required this.endDate,
    required this.selectStartDate,
    required this.today,
    this.unit,
    required this.onDateSelected,
  });

  @override
  State<_CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<_CustomCalendar> {
  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: widget.selectStartDate 
          ? (widget.startDate ?? widget.today)
          : widget.endDate,
      firstDate: DateTime(2000),
      lastDate: widget.today,
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.reportColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      widget.onDateSelected(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 현재 선택 상태 표시
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.reportColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.selectStartDate ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: widget.selectStartDate ? widget.reportColor : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Inicio:',
                    style: TextStyle(
                      fontWeight: widget.selectStartDate ? FontWeight.bold : FontWeight.normal,
                      color: widget.selectStartDate ? widget.reportColor : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.startDate != null 
                        ? _formatDate(widget.startDate!)
                        : 'No seleccionado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.startDate != null ? widget.reportColor : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    !widget.selectStartDate ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: !widget.selectStartDate ? widget.reportColor : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Fin:',
                    style: TextStyle(
                      fontWeight: !widget.selectStartDate ? FontWeight.bold : FontWeight.normal,
                      color: !widget.selectStartDate ? widget.reportColor : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(widget.endDate),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.reportColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 날짜 선택 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _selectDate,
            icon: Icon(
              widget.selectStartDate ? Icons.calendar_today : Icons.event,
              color: Colors.white,
            ),
            label: Text(
              widget.selectStartDate ? 'Seleccionar Inicio' : 'Seleccionar Fin',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.reportColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    if (widget.unit == 'year') {
      return DateFormat('yyyy').format(date);
    } else if (widget.unit == 'month') {
      return DateFormat('yyyy-MM').format(date);
    } else {
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }
}
