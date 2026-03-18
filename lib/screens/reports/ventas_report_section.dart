part of '../report_screen_legacy.dart';

mixin VentasReportMixin on _ReportScreenStateBase {
  Widget _buildVentasHeader() {
    return ReportHeaderBuilders.buildVentasHeader(
      context: context,
      data: _data,
      startDate: _ventasStartDate,
      endDate: _ventasEndDate,
      selectedSucursal: _selectedSucursal,
      unit: _ventasUnit,
      onDateRangeChanged: (startDate, endDate) {
        setState(() {
          _ventasStartDate = startDate;
          _ventasEndDate = endDate;
        });
        _loadData();
      },
      onSucursalChanged: (value) {
        setState(() {
          _selectedSucursal = value;
        });
      },
      onUnitChanged: (value) {
        setState(() {
          _ventasUnit = value;
        });
        _loadData();
      },
      reportColor: _getReportColor(),
      reportType: widget.reportType,
      filteringWordController: _filteringWordController,
      onFilteringWordSubmitted: (value) {
        // filteringWord 변경 시 자동으로 필터링됨 (리스너에서 처리)
      },
      onFilteringWordClear: () {
        setState(() {
          _filteringWordController.clear();
        });
      },
    );
  }

  /// 행 더블 클릭 핸들러 - 세부 내역 보기
  void _handleRowDoubleTap(Map<String, dynamic> rowData) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔵🔵🔵 더블 클릭 감지됨! 🔵🔵🔵');
    debugPrint('🔵 reportType: ${widget.reportType}, ventasUnit: $_ventasUnit');
    debugPrint('🔵 rowData: $rowData');
    debugPrint('🔵 rowData keys: ${rowData.keys.toList()}');

    if (widget.reportType != ReportType.ventas) {
      print('❌ reportType이 ventas가 아닙니다: ${widget.reportType}');
      return;
    }

    // vcode 단위에서는 더블 클릭으로 vdetalle 상세 정보 보기
    if (_ventasUnit == 'vcode') {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔵🔵🔵 VCODE 단위 더블 클릭 처리 시작! 🔵🔵🔵');
      debugPrint('   → vcode 단위 더블 클릭 - vdetalle 요청');
      debugPrint('   → rowData keys: ${rowData.keys.toList()}');
      debugPrint('   → rowData: $rowData');
      debugPrint('═══════════════════════════════════════════════════════');
      _handleVcodeRowTap(rowData);
      return;
    }

    debugPrint('   → 더블 클릭 - 현재 unit: $_ventasUnit');
    debugPrint('   → rowData keys: ${rowData.keys.toList()}');
    debugPrint('   → rowData: $rowData');

    DateTime? selectedDate;
    String? newUnit;
    DateTime? newStartDate;
    DateTime? newEndDate;

    // 현재 unit에 따라 처리
    if (_ventasUnit == 'year') {
      print('🔵🔵🔵 YEAR 단위 더블 클릭 처리 시작! 🔵🔵🔵');
      dynamic yearValue;

      // 1. 'year' 필드 확인
      yearValue = rowData['year'] ?? rowData['Year'] ?? rowData['YEAR'];

      // year 필드가 "YYYY-MM-DD" 형식인 경우 "YYYY"만 추출
      if (yearValue != null) {
        final yearStr = yearValue.toString();
        if (yearStr.contains('-')) {
          final parts = yearStr.split('-');
          if (parts.isNotEmpty) {
            yearValue = parts[0];
          }
        }
      }

      // 2. 'fecha' 필드 확인 (year 단위에서는 "YYYY" 형식)
      if (yearValue == null) {
        final fechaValue = rowData['fecha'] ?? rowData['Fecha'] ?? rowData['FECHA'];
        if (fechaValue != null) {
          final fechaStr = fechaValue.toString();
          if (fechaStr.length == 4 && int.tryParse(fechaStr) != null) {
            yearValue = fechaStr;
          } else if (fechaStr.contains('-')) {
            final parts = fechaStr.split('-');
            if (parts.isNotEmpty) {
              yearValue = parts[0];
            }
          }
        }
      }

      // 3. 다른 필드에서 4자리 숫자 찾기
      if (yearValue == null) {
        yearValue = rowData.values.firstWhere(
          (v) {
            if (v == null) return false;
            final str = v.toString();
            if (str.length == 4 && int.tryParse(str) != null) {
              return true;
            }
            if (str.contains('-')) {
              final parts = str.split('-');
              if (parts.isNotEmpty && parts[0].length == 4 && int.tryParse(parts[0]) != null) {
                return true;
              }
            }
            return false;
          },
          orElse: () => null,
        );
        if (yearValue != null && yearValue.toString().contains('-')) {
          final parts = yearValue.toString().split('-');
          if (parts.isNotEmpty) {
            yearValue = parts[0];
          }
        }
      }

      print('🔍 year 단위 - yearValue: $yearValue, rowData keys: ${rowData.keys.toList()}');

      if (yearValue != null) {
        final yearStr = yearValue.toString();
        final year = yearStr.contains('-')
            ? int.tryParse(yearStr.split('-')[0])
            : int.tryParse(yearStr);

        if (year != null && year >= 2000 && year <= DateTime.now().year) {
          newUnit = 'month';
          newStartDate = DateTime(year, 1, 1);
          newEndDate = DateTime(year, 12, 31);
          print('✅ year -> month: $year년 ($newStartDate ~ $newEndDate)');
        } else {
          print('❌ year 값이 유효하지 않습니다: $year (범위: 2000 ~ ${DateTime.now().year})');
        }
      } else {
        print('❌ year 값을 찾을 수 없습니다. rowData: $rowData');
      }
    } else if (_ventasUnit == 'month') {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔵🔵🔵 MONTH 단위 더블 클릭 처리 시작! 🔵🔵🔵');
      debugPrint('   → rowData keys: ${rowData.keys.toList()}');
      debugPrint('   → rowData: $rowData');

      dynamic monthValue = rowData['month'] ??
                        rowData['Month'] ??
                        rowData['MONTH'];

      debugPrint('   → [1차 시도] month 필드 직접 확인: $monthValue');

      if (monthValue == null) {
        debugPrint('   → [2차 시도] 다른 필드에서 날짜 형식 찾기');
        monthValue = rowData.values.firstWhere(
          (v) {
            if (v == null) return false;
            final str = v.toString();
            final hasDash = str.contains('-');
            final parts = str.split('-');
            final isValidFormat = hasDash && parts.length >= 2 && parts.length <= 3;
            if (isValidFormat) {
              debugPrint('      → 후보 발견: $str');
            }
            return isValidFormat;
          },
          orElse: () => null,
        );
        debugPrint('   → [2차 시도] 결과: $monthValue');
      }

      debugPrint('   → 최종 monthValue: $monthValue');

      if (monthValue != null) {
        final monthStr = monthValue.toString();
        debugPrint('   → monthStr: $monthStr');

        final parts = monthStr.split('-');
        debugPrint('   → parts: $parts, length: ${parts.length}');

        if (parts.length >= 2) {
          final year = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          debugPrint('   → 파싱 결과 - year: $year, month: $month');

          if (year != null && month != null && month >= 1 && month <= 12) {
            newUnit = 'day';
            newStartDate = DateTime(year, month, 1);
            newEndDate = DateTime(year, month + 1, 0);
            debugPrint('   ✅ month -> day: $year년 $month월 ($newStartDate ~ $newEndDate)');
          } else {
            debugPrint('   ❌ year 또는 month 값이 유효하지 않습니다: year=$year, month=$month');
          }
        } else {
          debugPrint('   ❌ monthStr을 파싱할 수 없습니다. parts.length=${parts.length}');
        }
      } else {
        debugPrint('   ❌ month 값을 찾을 수 없습니다.');
        debugPrint('   ❌ rowData의 모든 키: ${rowData.keys.toList()}');
        debugPrint('   ❌ rowData의 모든 값: ${rowData.values.toList()}');
      }
      debugPrint('═══════════════════════════════════════════════════════');
    } else if (_ventasUnit == 'day') {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔵🔵🔵 DAY 단위 더블 클릭 처리 시작! 🔵🔵🔵');
      debugPrint('   → rowData keys: ${rowData.keys.toList()}');
      debugPrint('   → rowData: $rowData');

      dynamic fechaValue = rowData['fecha'] ??
                        rowData['Fecha'] ??
                        rowData['FECHA'];

      debugPrint('   → [1차 시도] fecha 필드 직접 확인: $fechaValue');

      if (fechaValue == null) {
        debugPrint('   → [2차 시도] 다른 필드에서 날짜 형식 찾기 (YYYY-MM-DD)');
        fechaValue = rowData.values.firstWhere(
          (v) {
            if (v == null) return false;
            final str = v.toString();
            final parts = str.split('-');
            final isValidFormat = parts.length == 3;
            if (isValidFormat) {
              debugPrint('      → 후보 발견: $str');
            }
            return isValidFormat;
          },
          orElse: () => null,
        );
        debugPrint('   → [2차 시도] 결과: $fechaValue');
      }

      debugPrint('   → 최종 fechaValue: $fechaValue');

      if (fechaValue != null) {
        final fechaStr = fechaValue.toString();
        debugPrint('   → fechaStr: $fechaStr');

        final parts = fechaStr.split('-');
        debugPrint('   → parts: $parts, length: ${parts.length}');

        if (parts.length >= 3) {
          final year = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final day = int.tryParse(parts[2]);
          debugPrint('   → 파싱 결과 - year: $year, month: $month, day: $day');

          if (year != null && month != null && day != null) {
            newUnit = 'vcode';
            selectedDate = DateTime(year, month, day);
            newStartDate = selectedDate;
            newEndDate = selectedDate;
            debugPrint('   ✅ day -> vcode: $year년 $month월 $day일');
          } else {
            debugPrint('   ❌ year, month, day 값 중 하나가 유효하지 않습니다: year=$year, month=$month, day=$day');
          }
        } else {
          debugPrint('   ❌ fechaStr을 파싱할 수 없습니다. parts.length=${parts.length}');
        }
      } else {
        debugPrint('   ❌ fecha 값을 찾을 수 없습니다.');
        debugPrint('   ❌ rowData의 모든 키: ${rowData.keys.toList()}');
        debugPrint('   ❌ rowData의 모든 값: ${rowData.values.toList()}');
      }
      debugPrint('═══════════════════════════════════════════════════════');
    }

    // unit과 날짜 범위 변경
    if (newUnit != null && newStartDate != null && newEndDate != null) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('✅ 변경 적용: unit=$newUnit, startDate=$newStartDate, endDate=$newEndDate');
      debugPrint('   → 이전 unit: $_ventasUnit');
      debugPrint('   → 이전 startDate: $_ventasStartDate');
      debugPrint('   → 이전 endDate: $_ventasEndDate');
      setState(() {
        _ventasUnit = newUnit!;
        _ventasStartDate = newStartDate;
        _ventasEndDate = newEndDate;
      });
      print('🔴🔴🔵 [report_screen.dart:10781] 더블 클릭 핸들러 - setState 호출 직전');
      print('   → 라인: 10781');
      print('   → 이전 _ventasUnit: $_ventasUnit');
      print('   → 할당할 newUnit: $newUnit');
      debugPrint('🔴🔴🔵 [report_screen.dart:10781] 더블 클릭 핸들러 - setState 호출 직전');
      debugPrint('   → 라인: 10781');
      debugPrint('   → 이전 _ventasUnit: $_ventasUnit');
      debugPrint('   → 할당할 newUnit: $newUnit');
      setState(() {
        print('🔴🔴🔵 [report_screen.dart:10782] 더블 클릭 핸들러 - setState 내부 _ventasUnit 할당 직전');
        print('   → 라인: 10782');
        print('   → 현재 _ventasUnit: $_ventasUnit');
        print('   → 할당할 newUnit: $newUnit');
        debugPrint('🔴🔴🔵 [report_screen.dart:10782] 더블 클릭 핸들러 - setState 내부 _ventasUnit 할당 직전');
        debugPrint('   → 라인: 10782');
        debugPrint('   → 현재 _ventasUnit: $_ventasUnit');
        debugPrint('   → 할당할 newUnit: $newUnit');
        _ventasUnit = newUnit!;
        print('🔴🔴🔵 [report_screen.dart:10783] 더블 클릭 핸들러 - setState 내부 _ventasUnit 할당 직후');
        print('   → 라인: 10783');
        print('   → _ventasUnit: $_ventasUnit');
        debugPrint('🔴🔴🔵 [report_screen.dart:10783] 더블 클릭 핸들러 - setState 내부 _ventasUnit 할당 직후');
        debugPrint('   → 라인: 10783');
        debugPrint('   → _ventasUnit: $_ventasUnit');
        _ventasStartDate = newStartDate;
        _ventasEndDate = newEndDate;
      });
      debugPrint('   → 변경 후 unit: $_ventasUnit');
      debugPrint('   → 변경 후 startDate: $_ventasStartDate');
      debugPrint('   → 변경 후 endDate: $_ventasEndDate');
      print('🔴🔴🔵 [report_screen.dart:10790] 더블 클릭 핸들러 - setState 완료 직후');
      print('   → 라인: 10790');
      print('   → _ventasUnit: $_ventasUnit');
      debugPrint('🔴🔴🔵 [report_screen.dart:10790] 더블 클릭 핸들러 - setState 완료 직후');
      debugPrint('   → 라인: 10790');
      debugPrint('   → _ventasUnit: $_ventasUnit');
      debugPrint('   → _loadData() 호출 시작');
      _loadData();
      debugPrint('   → _loadData() 호출 완료');
      debugPrint('═══════════════════════════════════════════════════════');
    } else {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('❌ 변경 실패: newUnit=$newUnit, newStartDate=$newStartDate, newEndDate=$newEndDate');
      debugPrint('   → 현재 unit: $_ventasUnit');
      debugPrint('   → 더블 클릭 처리 실패 - 필수 값이 null입니다');
      debugPrint('═══════════════════════════════════════════════════════');
    }
  }

  /// Ventas 보고서 행 단일 클릭 핸들러 - day/month/year 단위에서 sucursal 필터링
  void _handleRowTap(Map<String, dynamic> rowData) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔵🔵🔵 단일 클릭 감지됨! (sucursal 필터링) 🔵🔵🔵');
    debugPrint('🔵 reportType: ${widget.reportType}, ventasUnit: $_ventasUnit');
    debugPrint('🔵 rowData: $rowData');
    debugPrint('🔵 rowData keys: ${rowData.keys.toList()}');

    if (widget.reportType != ReportType.ventas) {
      debugPrint('❌ reportType이 ventas가 아닙니다: ${widget.reportType}');
      return;
    }

    // vcode 단위에서는 단일 클릭을 사용하지 않음
    if (_ventasUnit == 'vcode') {
      debugPrint('❌ vcode 단위에서는 단일 클릭을 사용하지 않습니다');
      return;
    }

    // day/month/year 단위에서만 sucursal 필터링
    if (_ventasUnit != 'day' && _ventasUnit != 'month' && _ventasUnit != 'year') {
      debugPrint('❌ day/month/year 단위가 아닙니다: $_ventasUnit');
      return;
    }

    // sucursal 값 추출
    dynamic sucursalValue = rowData['sucursal'] ??
                           rowData['Sucursal'] ??
                           rowData['SUCURSAL'];

    debugPrint('   → 추출된 sucursal 값: $sucursalValue');

    if (sucursalValue == null) {
      debugPrint('   ❌ sucursal 값이 없습니다.');
      return;
    }

    final sucursalStr = sucursalValue.toString();
    debugPrint('   → sucursalStr: $sucursalStr');

    // year 단위에서의 처리
    if (_ventasUnit == 'year') {
      dynamic yearValue = rowData['year'] ?? rowData['Year'] ?? rowData['YEAR'];

      if (yearValue == null) {
        final fechaValue = rowData['fecha'] ?? rowData['Fecha'] ?? rowData['FECHA'];
        if (fechaValue != null) {
          final fechaStr = fechaValue.toString();
          if (fechaStr.length == 4 && int.tryParse(fechaStr) != null) {
            yearValue = fechaStr;
          } else if (fechaStr.contains('-')) {
            final parts = fechaStr.split('-');
            if (parts.isNotEmpty) yearValue = parts[0];
          }
        }
      }

      if (yearValue != null) {
        final yearStr = yearValue.toString().contains('-')
            ? yearValue.toString().split('-')[0]
            : yearValue.toString();
        final year = int.tryParse(yearStr);
        if (year != null) {
          debugPrint('   → year 단위 sucursal 필터링: year=$year, sucursal=$sucursalStr');
          setState(() {
            _selectedSucursal = sucursalStr == _selectedSucursal ? null : sucursalStr;
          });
          debugPrint('      → 콤보박스가 업데이트되어야 함: _selectedSucursal=$_selectedSucursal');
          debugPrint('═══════════════════════════════════════════════════════');
          return;
        } else {
          debugPrint('   ❌ year 값이 유효하지 않습니다: $year');
        }
      } else {
        debugPrint('   ❌ year 값을 찾을 수 없습니다.');
      }
    }

    // month/day 단위에서는 기존 동작 유지 (sucursal 필터링만)
    if (_selectedSucursal == sucursalStr) {
      debugPrint('   → 이미 선택된 sucursal과 같음 - 필터 해제');
      setState(() {
        _selectedSucursal = null;
      });
      debugPrint('   → _loadData() 호출 시작 (필터 해제)');
      _loadData();
      debugPrint('   → _loadData() 호출 완료');
    } else {
      debugPrint('   → 새 sucursal 선택: $sucursalStr');
      setState(() {
        _selectedSucursal = sucursalStr;
      });
      debugPrint('   → _loadData() 호출 시작 (sucursal 필터 적용)');
      _loadData();
      debugPrint('   → _loadData() 호출 완료');
    }

    debugPrint('═══════════════════════════════════════════════════════');
  }

  /// vcode 행 탭 핸들러 - vdetalle 상세 정보 보기
  void _handleVcodeRowTap(Map<String, dynamic> rowData) async {
    if (widget.reportType != ReportType.ventas || _ventasUnit != 'vcode') return;

    print('🔍 vcode 행 더블 클릭 - rowData: $rowData');
    print('🔍 rowData의 모든 키: ${rowData.keys.toList()}');

    dynamic vcodeId;
    dynamic sucursal;

    for (var key in rowData.keys) {
      final lowerKey = key.toLowerCase();
      if (lowerKey == 'id' || lowerKey == 'vcode_id' || lowerKey == 'vcodeid') {
        vcodeId = rowData[key];
        print('✅ vcode_id 찾음: key=$key, value=$vcodeId');
        break;
      }
    }

    for (var key in rowData.keys) {
      final lowerKey = key.toLowerCase();
      if (lowerKey == 'sucursal') {
        sucursal = rowData[key];
        print('✅ sucursal 찾음: key=$key, value=$sucursal');
        break;
      }
    }

    if (vcodeId == null || sucursal == null) {
      print('❌ vcode_id 또는 sucursal이 없습니다.');
      print('   - vcode_id: $vcodeId');
      print('   - sucursal: $sucursal');
      print('   - rowData의 모든 키: ${rowData.keys.toList()}');
      print('   - rowData의 모든 값: ${rowData.values.toList()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('vcode_id 또는 sucursal 정보를 찾을 수 없습니다.')),
        );
      }
      return;
    }

    final vcodeIdInt = vcodeId is int ? vcodeId : int.tryParse(vcodeId.toString());
    final sucursalInt = sucursal is int ? sucursal : int.tryParse(sucursal.toString());

    if (vcodeIdInt == null || sucursalInt == null) {
      print('❌ vcode_id 또는 sucursal을 정수로 변환할 수 없습니다.');
      print('   - vcode_id 원본: $vcodeId (타입: ${vcodeId.runtimeType})');
      print('   - sucursal 원본: $sucursal (타입: ${sucursal.runtimeType})');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('vcode_id 또는 sucursal 형식이 올바르지 않습니다.')),
        );
      }
      return;
    }

    print('✅ vdetalles 요청 - vcode_id: $vcodeIdInt, sucursal: $sucursalInt');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final vdetalleData = await _databaseService.getVdetalle(
        vcodeId: vcodeIdInt,
        sucursal: sucursalInt,
      );

      if (mounted) Navigator.of(context).pop();

      print('✅ vdetalle 응답: $vdetalleData');

      if (mounted) {
        _showVdetalleDialog(vdetalleData, rowData);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      print('❌ vdetalle 요청 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('vdetalle 데이터를 가져오는 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  /// vdetalle 데이터를 카드 형태로 표시하는 다이얼로그
  void _showVdetalleDialog(Map<String, dynamic> vdetalleData, Map<String, dynamic> rowData) {
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isWideScreen = screenWidth >= 800;
        final dialogWidth = isWideScreen ? screenWidth * 2 / 3 : screenWidth;
        final dialogHeight = isWideScreen ? screenHeight * 0.9 : screenHeight;

        return Dialog(
          insetPadding: isWideScreen ? const EdgeInsets.all(16) : EdgeInsets.zero,
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: isWideScreen
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Detalle de Venta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildVdetalleCards(vdetalleData, rowData, isWideScreen),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// vdetalle 데이터를 카드 형태로 구성
  Widget _buildVdetalleCards(Map<String, dynamic> vdetalleData, Map<String, dynamic> rowData, bool isWideScreen) {
    final leftCards = <Widget>[];
    final rightCards = <Widget>[];

    if (vdetalleData.containsKey('vcodes') && vdetalleData['vcodes'] is Map) {
      final vcodes = vdetalleData['vcodes'] as Map<String, dynamic>;
      leftCards.add(_buildInfoCard('Información de Pago', {
        'Total Pago': ReportUtils.formatValue(vcodes['tpago']),
        'Efectivo': ReportUtils.formatValue(vcodes['tefectivo']),
        'Crédito': ReportUtils.formatValue(vcodes['tcredito']),
        'Banco': ReportUtils.formatValue(vcodes['tbanco']),
        'Reservado': ReportUtils.formatValue(vcodes['treservado']),
        'Favor': ReportUtils.formatValue(vcodes['tfavor']),
        'Núm. Caja': vcodes['d_num_caja']?.toString() ?? 'N/A',
        'Núm. Terminal': vcodes['d_num_terminal']?.toString() ?? 'N/A',
      }));
    }

    if (vdetalleData.containsKey('cliente') && vdetalleData['cliente'] is Map) {
      final cliente = vdetalleData['cliente'] as Map<String, dynamic>;
      leftCards.add(_buildInfoCard('Información del Cliente', {
        'DNI': cliente['dni']?.toString() ?? 'N/A',
        'Nombre': cliente['nombre']?.toString() ?? 'N/A',
        'Dirección': cliente['direccion']?.toString() ?? 'N/A',
        'Localidad': cliente['localidad']?.toString() ?? 'N/A',
        'Provincia': cliente['provincia']?.toString() ?? 'N/A',
        'Vendedor': cliente['vendedor']?.toString() ?? 'N/A',
      }));
    }

    if (vdetalleData.containsKey('cheque') && vdetalleData['cheque'] is List) {
      final cheques = vdetalleData['cheque'] as List;
      if (cheques.isNotEmpty) {
        leftCards.add(_buildChequesCard(cheques));
      }
    }

    if (vdetalleData.containsKey('vtags') && vdetalleData['vtags'] is List) {
      final vtags = vdetalleData['vtags'] as List;
      if (vtags.isNotEmpty) {
        leftCards.add(_buildVtagsCard(vtags));
      }
    }

    if (vdetalleData.containsKey('detalles') && vdetalleData['detalles'] is List) {
      final detalles = vdetalleData['detalles'] as List;
      if (detalles.isNotEmpty) {
        rightCards.add(_buildDetallesCard(detalles));
      }
    }

    if (vdetalleData.containsKey('online_ventas') && vdetalleData['online_ventas'] is List) {
      final onlineVentas = vdetalleData['online_ventas'] as List;
      if (onlineVentas.isNotEmpty) {
        rightCards.add(_buildOnlineVentasCard(onlineVentas));
      }
    }

    if (isWideScreen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: leftCards,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rightCards,
              ),
            ),
          ),
        ],
      );
    } else {
      final allCards = <Widget>[];
      for (int i = 0; i < leftCards.length; i++) {
        allCards.add(leftCards[i]);
        if (i < leftCards.length - 1 || rightCards.isNotEmpty) {
          allCards.add(const SizedBox(height: 16));
        }
      }
      for (int i = 0; i < rightCards.length; i++) {
        allCards.add(rightCards[i]);
        if (i < rightCards.length - 1) {
          allCards.add(const SizedBox(height: 16));
        }
      }
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: allCards,
        ),
      );
    }
  }

  /// Detalles 카드 (판매 상세 내역 테이블)
  Widget _buildDetallesCard(List<dynamic> detalles) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles de Venta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(Colors.purple.withOpacity(0.1)),
                columns: const [
                  DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Precio Unit.', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Precio Total', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                ],
                rows: detalles.map((item) {
                  if (item is Map<String, dynamic>) {
                    return DataRow(
                      cells: [
                        DataCell(Text(item['codigo1']?.toString() ?? 'N/A')),
                        DataCell(Text(item['desc1']?.toString() ?? 'N/A')),
                        DataCell(Text(ReportUtils.formatValue(item['cant1']))),
                        DataCell(Text(ReportUtils.formatValue(item['preuni']))),
                        DataCell(Text(ReportUtils.formatValue(item['precio']))),
                      ],
                    );
                  }
                  return const DataRow(cells: [
                    DataCell(Text('N/A')),
                    DataCell(Text('N/A')),
                    DataCell(Text('N/A')),
                    DataCell(Text('N/A')),
                    DataCell(Text('N/A')),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vtags 카드 (결제 정보 테이블)
  Widget _buildVtagsCard(List<dynamic> vtags) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Pago',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(Colors.purple.withOpacity(0.1)),
                columns: const [
                  DataColumn(label: Text('Cuenta', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Núm. Autorización', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Monto', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Sucursal', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                ],
                rows: vtags.map((item) {
                  if (item is Map<String, dynamic>) {
                    return DataRow(
                      cells: [
                        DataCell(Text(item['cuenta_nombre']?.toString() ?? 'N/A')),
                        DataCell(Text(item['num_autorizacion']?.toString() ?? 'N/A')),
                        DataCell(Text(ReportUtils.formatValue(item['fmonto']))),
                        DataCell(Text(item['sucursal']?.toString() ?? 'N/A')),
                      ],
                    );
                  }
                  return const DataRow(cells: [
                    DataCell(Text('N/A')),
                    DataCell(Text('N/A')),
                    DataCell(Text('N/A')),
                    DataCell(Text('N/A')),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cheques 카드 (수표 정보 테이블)
  Widget _buildChequesCard(List<dynamic> cheques) {
    if (cheques.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstCheque = cheques.first;
    if (firstCheque is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }

    final keys = firstCheque.keys.toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Cheques',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(Colors.purple.withOpacity(0.1)),
                columns: keys.map((key) {
                  return DataColumn(
                    label: Text(
                      key.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                rows: cheques.map((item) {
                  if (item is Map<String, dynamic>) {
                    return DataRow(
                      cells: keys.map((key) {
                        return DataCell(Text(
                          ReportUtils.formatValue(item[key]),
                        ));
                      }).toList(),
                    );
                  }
                  return DataRow(
                    cells: keys.map((_) => const DataCell(Text('N/A'))).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 정보 카드 위젯 생성
  Widget _buildInfoCard(String title, Map<String, dynamic> data, {Color? reportColor}) {
    final cardColor = reportColor ?? Colors.purple;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cardColor,
              ),
            ),
            const SizedBox(height: 12),
            ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${entry.key}:',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value?.toString() ?? 'N/A',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Online Ventas 카드 (온라인 판매 정보 테이블)
  Widget _buildOnlineVentasCard(List<dynamic> onlineVentas) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ventas Online',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Builder(
                builder: (context) {
                  if (onlineVentas.isEmpty) {
                    return const Text('No hay ventas online');
                  }
                  final firstItem = onlineVentas.first;
                  if (firstItem is! Map<String, dynamic>) {
                    return const Text('Formato de datos no válido');
                  }
                  final keys = firstItem.keys.toList();
                  return DataTable(
                    columnSpacing: 20,
                    headingRowColor: WidgetStateProperty.all(Colors.purple.withOpacity(0.1)),
                    columns: keys.map((key) {
                      return DataColumn(
                        label: Text(
                          key.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                    rows: onlineVentas.map((item) {
                      if (item is Map<String, dynamic>) {
                        return DataRow(
                          cells: keys.map((key) {
                            return DataCell(Text(
                              ReportUtils.formatValue(item[key]),
                            ));
                          }).toList(),
                        );
                      }
                      return DataRow(
                        cells: keys.map((_) => const DataCell(Text('N/A'))).toList(),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
