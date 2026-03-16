part of '../report_screen_legacy.dart';

mixin VentasControlsMixin on State<ReportScreenLegacy> {

  Widget _buildVentasControlsInAppBar() {
    final reportColor = _getReportColor();
    
    // 큰 화면(macOS, iPad)에서는 버튼 3개를 나란히 표시
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
                width: 50,
                child: _buildCompactUnitButton('VCode', 'vcode', reportColor),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 45,
                child: _buildCompactUnitButton('Day', 'day', reportColor),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 55,
                child: _buildCompactUnitButton('Month', 'month', reportColor),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 50,
                child: _buildCompactUnitButton('Year', 'year', reportColor),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: _buildCompactDateRangeButton(reportColor),
              ),
              const SizedBox(width: 8),
              // 지점 선택 UI (sucursal이 1개 이상일 때만 표시)
              if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                _buildSucursalSelector(),
                const SizedBox(width: 8),
              ],
              SizedBox(
                width: 300, // 큰 화면에서는 충분히 넓게
                child: _buildFilteringWordFieldInAppBar(),
              ),
            ],
          );
        } else {
          // 작은 화면: 드롭다운 사용
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactUnitDropdown(reportColor),
              const SizedBox(width: 4),
              SizedBox(
                width: 90,
                child: _buildCompactDateRangeButton(reportColor),
              ),
              // 지점 선택 UI (sucursal이 1개 이상일 때만 표시)
              if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 100,
                  child: _buildSucursalSelector(),
                ),
              ],
              const SizedBox(width: 4),
              SizedBox(
                width: 180, // 작은 화면에서도 충분한 크기
                child: _buildFilteringWordFieldInAppBar(),
              ),
            ],
          );
        }
      },
    );
  }

  /// Ventas 보고서의 Unit 버튼들을 AppBar에 표시 (타이틀 옆)
  Widget _buildVentasUnitButtonsInAppBar() {
    final reportColor = _getReportColor();
    
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
                child: _buildCompactUnitButton('VCode', 'vcode', reportColor),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 65,
                child: _buildCompactUnitButton('Day', 'day', reportColor),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 75,
                child: _buildCompactUnitButton('Month', 'month', reportColor),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 70,
                child: _buildCompactUnitButton('Year', 'year', reportColor),
              ),
            ],
          );
        } else {
          // 작은 화면: 드롭다운 사용
          return _buildCompactUnitDropdown(reportColor);
        }
      },
    );
  }

  /// Ventas 보고서의 나머지 컨트롤을 AppBar에 표시 (날짜 범위, sucursal, 필터)
  Widget _buildVentasOtherControlsInAppBar() {
    final reportColor = _getReportColor();
    
    return Builder(
      builder: (context) {
        final platformType = PlatformUtils.getPlatformType(context);
        final size = MediaQuery.of(context).size;
        final isLargeScreen = (platformType == PlatformType.desktop || 
                              PlatformUtils.isIPad(context)) && 
                             size.width >= 800;
        
        if (isLargeScreen) {
          // 큰 화면: 날짜 범위, sucursal, 필터 입력 필드
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 90,
                child: _buildCompactDateRangeButton(reportColor),
              ),
              const SizedBox(width: 8),
              // 지점 선택 UI (sucursal이 1개 이상일 때만 표시)
              if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                _buildSucursalSelector(),
                const SizedBox(width: 8),
              ],
              SizedBox(
                width: 200,
                child: _buildFilteringWordFieldInAppBar(),
              ),
            ],
          );
        } else {
          // 작은 화면: 날짜 범위, sucursal, 필터 입력 필드
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 90,
                child: _buildCompactDateRangeButton(reportColor),
              ),
              // 지점 선택 UI (sucursal이 1개 이상일 때만 표시)
              if (_availableSucursales != null && _availableSucursales!.length > 1) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 100,
                  child: _buildSucursalSelector(),
                ),
              ],
              const SizedBox(width: 4),
              SizedBox(
                width: 180, // 작은 화면에서도 충분한 크기
                child: _buildFilteringWordFieldInAppBar(),
              ),
            ],
          );
        }
      },
    );
  }

  /// Ventas 보고서의 필터 콤보박스 (넓은 화면용)
  /// 핸드폰 좁은 화면용: 4개 필터를 하나의 콤보박스로 통합
  Widget _buildVentasFiltersSingleComboBox() {
    final reportColor = _getReportColor();
    
    // 현재 선택된 필터 확인
    String? selectedFilter;
    if (_ventasDescontado) {
      selectedFilter = 'Descontado';
    } else if (_ventasReservado) {
      selectedFilter = 'Reservado';
    } else if (_ventasCredito) {
      selectedFilter = 'Crédito';
    } else if (_ventasMovidos) {
      selectedFilter = 'Movidos';
    } else {
      selectedFilter = 'Todos';
    }
    
    final options = ['Todos', 'Descontado', 'Reservado', 'Crédito', 'Movidos'];
    
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: DropdownButton<String>(
        value: selectedFilter,
        isExpanded: true, // 좁은 화면에서 전체 너비 사용
        underline: Container(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        dropdownColor: reportColor,
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              // 선택된 항목만 true로 설정하고 나머지는 false
              _ventasDescontado = newValue == 'Descontado';
              _ventasReservado = newValue == 'Reservado';
              _ventasCredito = newValue == 'Crédito';
              _ventasMovidos = newValue == 'Movidos';
            });
            _loadData();
          }
        },
      ),
    );
  }

  Widget _buildVentasFilterComboBox(String label, bool value, Function(bool) onChanged) {
    final reportColor = _getReportColor();
    final options = ['Todos', 'Sí', 'No'];
    String selectedValue;
    if (!value) {
      selectedValue = 'Todos';
    } else {
      selectedValue = 'Sí';
    }
    
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: DropdownButton<String>(
        value: selectedValue,
        isExpanded: false, // iPhone 가로 모드에서 unbounded constraint 문제 방지
        underline: Container(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        dropdownColor: reportColor,
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (String? newValue) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [_buildVentasFilterComboBox] onChanged 호출됨');
          debugPrint('   → label: $label');
          debugPrint('   → 현재 value: $value');
          debugPrint('   → newValue: $newValue');
          if (newValue != null) {
            final boolValue = newValue == 'Sí';
            debugPrint('   → 변환된 bool 값: $boolValue');
            debugPrint('   → onChanged 콜백 호출 시작');
            onChanged(boolValue);
            debugPrint('   → onChanged 콜백 호출 완료');
          } else {
            debugPrint('   ⚠️ newValue가 null이므로 콜백 호출 안 함');
          }
          debugPrint('═══════════════════════════════════════════════════════');
        },
        selectedItemBuilder: (BuildContext context) {
          return options.map<Widget>((String option) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$label: $option',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList();
        },
      ),
    );
  }

  /// 컴팩트한 Unit 버튼 (AppBar용)
  Widget _buildCompactUnitButton(String label, String value, Color reportColor) {
    final isSelected = _ventasUnit == value;
    debugPrint('🔵 [report_screen.dart:10089] _buildCompactUnitButton 호출: label=$label, value=$value, isSelected=$isSelected, 현재 _ventasUnit=$_ventasUnit');
    return SizedBox(
      height: 28,
      child: TextButton(
        onPressed: () {
          // 즉시 출력 (비동기 이전)
          print('🔵🔵🔵 [report_screen.dart:10125] Unit 버튼 클릭 이벤트 발생 - 즉시 출력');
          print('   → 버튼 라벨: $label');
          print('   → 버튼 값: $value');
          print('   → 현재 선택된 unit: $_ventasUnit');
          
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔵 [report_screen.dart:10125] Unit 버튼 클릭 이벤트 발생');
          debugPrint('   → 라인: 10125');
          debugPrint('   → 버튼 라벨: $label');
          debugPrint('   → 버튼 값: $value');
          debugPrint('   → 현재 선택된 unit: $_ventasUnit');
          debugPrint('   → 이전 상태: isSelected=$isSelected');
          debugPrint('   → 보고서 타입: ${widget.reportType}');
          debugPrint('   → 현재 날짜 범위: startDate=$_ventasStartDate, endDate=$_ventasEndDate');
          debugPrint('   → 필터링 단어: ${_filteringWordController.text}');
          debugPrint('   → 데이터 로딩 상태: isLoading=$_isLoading');
          debugPrint('   → 데이터 존재 여부: ${_data != null}');
          debugPrint('   → 호출 스택 (처음 5줄):');
          debugPrint('      ${StackTrace.current.toString().split("\n").take(5).join("\n      ")}');
          
        print('🔴🔴🔴 [report_screen.dart:10157] setState 호출 직전 - _ventasUnit 할당 전');
        print('   → 라인: 10157');
        print('   → 현재 _ventasUnit: $_ventasUnit');
        print('   → 할당할 값: $value');
        print('   → 호출 스택:');
        print('      ${StackTrace.current.toString().split("\n").take(5).join("\n      ")}');
        debugPrint('🔴🔴🔴 [report_screen.dart:10157] setState 호출 직전 - _ventasUnit 할당 전');
        debugPrint('   → 라인: 10157');
        debugPrint('   → 현재 _ventasUnit: $_ventasUnit');
        debugPrint('   → 할당할 값: $value');
        debugPrint('   → 호출 스택:');
        debugPrint('      ${StackTrace.current.toString().split("\n").take(5).join("\n      ")}');
        setState(() {
            final previousUnit = _ventasUnit;
            print('🔴🔴🔴 [report_screen.dart:10159] setState 내부 - _ventasUnit 할당 직전');
            print('   → 라인: 10159');
            print('   → previousUnit: $previousUnit');
            print('   → 할당할 값: $value');
            debugPrint('🔴🔴🔴 [report_screen.dart:10159] setState 내부 - _ventasUnit 할당 직전');
            debugPrint('   → 라인: 10159');
            debugPrint('   → previousUnit: $previousUnit');
            debugPrint('   → 할당할 값: $value');
          _ventasUnit = value;
            print('🔴🔴🔴 [report_screen.dart:10160] setState 내부 - _ventasUnit 할당 직후');
            print('   → 라인: 10160');
            print('   → _ventasUnit: $_ventasUnit');
            print('   → _ventasUnit == value: ${_ventasUnit == value}');
            debugPrint('🔴🔴🔴 [report_screen.dart:10160] setState 내부 - _ventasUnit 할당 직후');
            debugPrint('   → 라인: 10160');
            debugPrint('   → _ventasUnit: $_ventasUnit');
            debugPrint('   → _ventasUnit == value: ${_ventasUnit == value}');
            print('   → [report_screen.dart:10141] setState 실행: $_ventasUnit (이전: $previousUnit)');
            debugPrint('   → [report_screen.dart:10141] setState 실행: $_ventasUnit (이전: $previousUnit)');
            debugPrint('   → [report_screen.dart:10143] _ventasUnit 업데이트 후 값: $_ventasUnit');
            debugPrint('   → [report_screen.dart:10146] _ventasUnit == "day": ${_ventasUnit == "day"}');
            debugPrint('   → [report_screen.dart:10147] _ventasUnit == "month": ${_ventasUnit == "month"}');
            debugPrint('   → [report_screen.dart:10148] _ventasUnit == "year": ${_ventasUnit == "year"}');
            debugPrint('   → [report_screen.dart:10149] setState 내부에서 _ventasUnit 확인: $_ventasUnit');
        });
        print('🔴🔴🔴 [report_screen.dart:10167] setState 완료 직후');
        print('   → 라인: 10167');
        print('   → _ventasUnit: $_ventasUnit');
        debugPrint('🔴🔴🔴 [report_screen.dart:10167] setState 완료 직후');
        debugPrint('   → 라인: 10167');
        debugPrint('   → _ventasUnit: $_ventasUnit');
          
          print('   → [report_screen.dart:10152] setState 완료 후 _ventasUnit: $_ventasUnit');
          debugPrint('   → [report_screen.dart:10152] setState 완료 후 _ventasUnit: $_ventasUnit');
          print('   → [report_screen.dart:10154] _loadData() 호출 시작 (비동기)');
          debugPrint('   → [report_screen.dart:10154] _loadData() 호출 시작 (비동기)');
          print('   → [report_screen.dart:10155] _loadData() 호출 직전 _ventasUnit: $_ventasUnit');
          debugPrint('   → [report_screen.dart:10155] _loadData() 호출 직전 _ventasUnit: $_ventasUnit');
        _loadData();
          print('   → [report_screen.dart:10156] _loadData() 호출 완료 (비동기 함수이므로 즉시 반환됨)');
          debugPrint('   → [report_screen.dart:10156] _loadData() 호출 완료 (비동기 함수이므로 즉시 반환됨)');
          print('   → [report_screen.dart:10157] _loadData() 호출 직후 _ventasUnit: $_ventasUnit');
          debugPrint('   → [report_screen.dart:10157] _loadData() 호출 직후 _ventasUnit: $_ventasUnit');
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
  Widget _buildCompactUnitDropdown(Color reportColor) {
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
    final displayUnit = validUnits.contains(_ventasUnit) ? _ventasUnit : 'vcode';

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
            setState(() {
              _ventasUnit = newUnit;
            });
            _loadData();
          }
        },
      ),
    );
  }

  /// 단일 날짜 선택 버튼 (AppBar용)
  Widget _buildSingleDateButton({
    required String label,
    required DateTime? date,
    required Color reportColor,
    required Function(DateTime) onDateSelected,
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
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('🔍 [_buildSingleDateButton] onTap 호출됨');
        debugPrint('   → label: $label');
        debugPrint('   → date: $date');
        debugPrint('   → unit: $unit');
        debugPrint('   → reportType: ${widget.reportType}');
        debugPrint('═══════════════════════════════════════════════════════════');
        
        DateTime? picked;
        
        if (unit == 'year') {
          // 연도 선택
          debugPrint('📅 [DateButton] 연도 선택 다이얼로그 표시');
          picked = await ReportHeaderBuilders.selectYearDialog(
            context,
            date ?? DateTime.now(),
            DateTime.now(),
            reportColor,
            widget.reportType,
            title: label,
          );
        } else if (unit == 'month') {
          // 월 선택
          debugPrint('📅 [DateButton] 월 선택 다이얼로그 표시');
          picked = await ReportHeaderBuilders.selectYearMonthDialog(
            context,
            date ?? DateTime.now(),
            DateTime.now(),
            reportColor,
            widget.reportType,
            title: label,
          );
        } else {
          // 일반 날짜 선택 (vcode, day)
          debugPrint('📅 [DateButton] 일반 날짜 선택 다이얼로그 표시');
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
        
        debugPrint('📅 [DateButton] 선택된 날짜: $picked');
        if (picked != null) {
          debugPrint('📅 [DateButton] onDateSelected 콜백 호출: $picked');
          onDateSelected(picked);
        } else {
          debugPrint('📅 [DateButton] 날짜 선택 취소됨');
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
            Flexible(
              child: Text(
                dateText,
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

  /// 컴팩트한 날짜 범위 버튼 (AppBar용)
  Widget _buildCompactDateRangeButton(Color reportColor) {
    String rangeText = 'Rango';
    DateFormat dateFormat;
    
    if (_ventasUnit == 'year') {
      dateFormat = DateFormat('yyyy');
    } else if (_ventasUnit == 'month') {
      dateFormat = DateFormat('yyyy-MM');
    } else {
      dateFormat = DateFormat('yyyy-MM-dd');
    }
    
    if (_ventasStartDate != null && _ventasEndDate != null) {
      if (_ventasUnit == 'year' || _ventasUnit == 'month') {
        rangeText = '${dateFormat.format(_ventasStartDate!)} - ${dateFormat.format(_ventasEndDate!)}';
      } else {
        rangeText = '${dateFormat.format(_ventasStartDate!)} ~ ${dateFormat.format(_ventasEndDate!)}';
      }
      // 텍스트가 너무 길면 줄임
      if (rangeText.length > 12) {
        rangeText = '${rangeText.substring(0, 10)}...';
      }
    }
    
    return InkWell(
      onTap: () => ReportHeaderBuilders.selectDateRange(
        context,
        _ventasStartDate,
        _ventasEndDate,
        _ventasUnit,
        reportColor,
        widget.reportType,
        (startDate, endDate) {
          setState(() {
            _ventasStartDate = startDate;
            _ventasEndDate = endDate;
          });
          _loadData();
        },
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
              _ventasUnit == 'year'
                  ? Icons.event
                  : _ventasUnit == 'month'
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

  // Ventas report 헤더 (이전 버전 - 제거 예정, 사용되지 않음)
  // 전체 함수가 주석 처리되어 있음 - 필요시 삭제 가능
  /*
  Widget _buildVentasHeaderOld() {
    // 데이터에서 sucursal 목록 추출
    List<String>? sucursales;
    if (_data != null && _data!.containsKey('data') && _data!['data'] is List) {
      final dataList = _data!['data'] as List;
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
              value: _selectedSucursal,
              hint: const Text('모두', style: TextStyle(fontSize: 11)),
              underline: const SizedBox(),
              isDense: true,
              icon: Icon(Icons.arrow_drop_down, color: _getReportColor(), size: 18),
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
              onChanged: (String? value) {
                setState(() {
                  _selectedSucursal = value;
                });
              },
            ),
          ),
        ],
      ],
    );
  }
  */

}
