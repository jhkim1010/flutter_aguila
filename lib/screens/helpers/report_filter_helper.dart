part of '../report_screen_legacy.dart';

mixin ReportFilterMixin on _ReportScreenStateBase {

  // Items 보고서용 필터 섹션 (데이터 개수 + 날짜 범위 + 필터링)
  Widget _buildItemsFilterSection() {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🔍 [_buildItemsFilterSection] 호출됨');
    debugPrint('   → reportType: ${widget.reportType}');
    debugPrint('   → _itemsStartDate: $_itemsStartDate');
    debugPrint('   → _itemsEndDate: $_itemsEndDate');
    debugPrint('   → _data: ${_data != null ? "있음 (키: ${_data!.keys.toList()})" : "null"}');
    debugPrint('═══════════════════════════════════════════════════════════');
    
    return LayoutBuilder(
      builder: (context, constraints) {
        debugPrint('🔍 [_buildItemsFilterSection] LayoutBuilder 호출됨');
        debugPrint('   → constraints.maxWidth: ${constraints.maxWidth}');
        debugPrint('   → constraints.maxHeight: ${constraints.maxHeight}');
        debugPrint('   → constraints.isTight: ${constraints.isTight}');
        debugPrint('   → constraints.isNormalized: ${constraints.isNormalized}');
        
        if (constraints.maxWidth.isInfinite) {
          debugPrint('⚠️ [_buildItemsFilterSection] constraints.maxWidth가 무한대입니다!');
          return const SizedBox.shrink();
        }
        
        return SizedBox(
          width: constraints.maxWidth,
          child: ReportHeaderBuilders.buildItemsFilterSection(
            data: _data,
            filteringWordController: _filteringWordController,
            startDate: _itemsStartDate,
            endDate: _itemsEndDate,
            onDateRangeChanged: (startDate, endDate) {
              debugPrint('📅 [_buildItemsFilterSection] 날짜 범위 변경: $startDate ~ $endDate');
              setState(() {
                _itemsStartDate = startDate;
                _itemsEndDate = endDate;
              });
              // 날짜 범위 변경 콜백 호출
              if (widget.onItemsDateRangeChanged != null) {
                widget.onItemsDateRangeChanged!(startDate, endDate);
              }
              _loadData();
            },
            reportType: widget.reportType,
          ),
        );
      },
    );
  }

  // Items 보고서용 필터 섹션 (이전 버전 - 제거 예정)
  Widget _buildItemsFilterSectionOld() {
    // 필터링된 데이터 개수 계산
    int totalCount = 0;
    int filteredCount = 0;
    
    if (_data != null && _data!.containsKey('data') && _data!['data'] is List) {
      final dataList = _data!['data'] as List;
      totalCount = dataList.length;
      
      // filteringWord 필터 적용
      final filteringWord = _filteringWordController.text.trim().toLowerCase();
      if (filteringWord.isNotEmpty) {
        filteredCount = dataList.where((item) {
          if (item is Map<String, dynamic>) {
            // codigo1 또는 desc1(제품 이름)에서 검색
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

    // bcolorview 값에 따라 색상 결정
    Color itemsColor = Colors.blue; // 기본값 (items 보고서 기본 색상)
    if (_data != null) {
      if (_data!.containsKey('filters') && _data!['filters'] is Map) {
        final filters = _data!['filters'] as Map<String, dynamic>;
        final bcolorview = filters['bcolorview'];
        itemsColor = ReportUtils.isBcolorviewEnabled(bcolorview) ? Colors.orange : Colors.lightBlue;
      } else if (_data!.containsKey('bcolorview')) {
        final bcolorview = _data!['bcolorview'];
        itemsColor = ReportUtils.isBcolorviewEnabled(bcolorview) ? Colors.orange : Colors.lightBlue;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: itemsColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: itemsColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 날짜 범위 선택
          Expanded(
            child: ItemsDateRangeSelector(
              reportType: widget.reportType,
              startDate: _itemsStartDate,
              endDate: _itemsEndDate,
              onDateRangeChanged: (startDate, endDate) {
                setState(() {
                  _itemsStartDate = startDate;
                  _itemsEndDate = endDate;
                });
                // 날짜 범위 변경 콜백 호출
                if (widget.onItemsDateRangeChanged != null) {
                  widget.onItemsDateRangeChanged!(startDate, endDate);
                }
                _loadData();
              },
            ),
          ),
          const SizedBox(width: 12),
          // 데이터 개수 표시 (옆)
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

  /// Ingresos 보고서: Sucursal 콤보 옆 Movidos 체크박스
  Widget _buildIngresosMovidosCheckbox() {
    final reportColor = _getReportColor();
    return SizedBox(
      width: 110,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: _ingresosMovidos,
              onChanged: (v) {
                setState(() => _ingresosMovidos = v ?? false);
                _loadData();
              },
              activeColor: reportColor,
              fillColor: WidgetStateProperty.resolveWith((_) => Colors.white),
              checkColor: reportColor,
            ),
          ),
          const SizedBox(width: 4),
          const Text('Movidos', style: TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  // Stocks 필드명 매핑 (스페인어)

  // Ventas report 헤더 (날짜 범위 및 sucursal 선택)
  /// Ventas 보고서의 컨트롤을 AppBar에 표시 (오른쪽)
  /// Alertas 보고서 필터 버튼 빌드
  Widget _buildAlertasFilterButton(String label, bool isActive, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: isActive 
            ? Colors.white.withOpacity(0.3) 
            : Colors.transparent,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // Filtering word 입력 필드 (AppBar용)
  Widget _buildFilteringWordFieldInAppBar() {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🔍 [_buildFilteringWordFieldInAppBar] 호출됨');
    debugPrint('   → reportType: ${widget.reportType}');
    debugPrint('   → _filteringWordController.text: ${_filteringWordController.text}');
    debugPrint('═══════════════════════════════════════════════════════════');
    
    // Expanded 안에 있으므로 LayoutBuilder 불필요 - Expanded가 이미 제약을 제공함
    return ReportFilters.buildFilteringWordField(
      controller: _filteringWordController,
      onSubmitted: (value) {
        debugPrint('🔍 [_buildFilteringWordFieldInAppBar] onSubmitted 호출됨: $value');
        // codigos, todocodigos 또는 stocks 보고서인 경우 서버에 요청
        if (widget.reportType == ReportType.codigos || 
            widget.reportType == ReportType.todocodigos || 
            widget.reportType == ReportType.stocks) {
          _reloadDataWithFilters();
        }
      },
      onClear: () {
        debugPrint('🔍 [_buildFilteringWordFieldInAppBar] onClear 호출됨');
        // clear 호출을 다음 프레임으로 지연하여 키보드 이벤트 충돌 방지
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _filteringWordController.clear();
          }
        });
      },
    );
  }

  // Tipo 선택 UI (AppBar용) - ReportFilterWidgets로 이동
  Widget _buildTipoSelector() {
    return ReportFilterWidgets.buildTipoSelector(
      tiposList: _tiposList,
      selectedTipoId: _selectedTipoId,
      onChanged: (int? value) {
        setState(() {
          _selectedTipoId = value;
        });
        _loadData();
      },
      reportColor: _getReportColor(),
    );
  }

  // Temporada 선택 UI (AppBar용) - ReportFilterWidgets로 이동
  Widget _buildTemporadaSelector() {
    return ReportFilterWidgets.buildTemporadaSelector(
      temporadasList: _temporadasList,
      selectedTemporadaId: _selectedTemporadaId,
      onChanged: (int? value) {
        setState(() {
          _selectedTemporadaId = value;
        });
        _loadData();
      },
      reportColor: _getReportColor(),
    );
  }

  /// Codigos/Todocodigos: Solo borrados 체크박스 (filteringWord 왼쪽에 배치)
  Widget _buildCodigosSoloBorradosCheckbox() {
    return InkWell(
      onTap: () {
        setState(() {
          _codigosSoloBorrados = !_codigosSoloBorrados;
        });
        _reloadDataWithFilters();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _codigosSoloBorrados,
                onChanged: (bool? value) {
                  setState(() => _codigosSoloBorrados = value ?? false);
                  _reloadDataWithFilters();
                },
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return Colors.white;
                  return Colors.transparent;
                }),
                checkColor: _getReportColor(),
                side: const BorderSide(color: Colors.white70),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Solo borrados',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Clientes 보고서용 필터 UI 빌더들 - ReportFilterWidgets로 이동
  // Responsable Ins 콤보박스
  Widget _buildClientesResponsableInsSelector() {
    debugPrint('🔍 [_buildClientesResponsableInsSelector] 호출됨');
    debugPrint('   → _clientesResponsableIns: $_clientesResponsableIns');
    
    return ReportFilterWidgets.buildClientesResponsableInsSelector(
      selectedValue: _clientesResponsableIns,
      onChanged: (String? value) {
        debugPrint('🔍 [_buildClientesResponsableInsSelector] onChanged 호출됨: $value');
        setState(() {
          _clientesResponsableIns = value;
        });
        _loadData();
      },
      reportColor: _getReportColor(),
    );
  }

  // Provincias 콤보박스 - ReportFilterWidgets로 이동
  Widget _buildClientesProvinciaSelector() {
    debugPrint('🔍 [_buildClientesProvinciaSelector] 호출됨');
    debugPrint('   → _clientesProvincia: $_clientesProvincia');
    
    return ReportFilterWidgets.buildClientesProvinciaSelector(
      selectedValue: _clientesProvincia,
      onChanged: (String? value) {
        debugPrint('🔍 [_buildClientesProvinciaSelector] onChanged 호출됨: $value');
        setState(() {
          _clientesProvincia = value;
        });
        _loadData();
      },
      reportColor: _getReportColor(),
    );
  }

  // Deudores 체크박스 - ReportFilterWidgets로 이동
  Widget _buildClientesDeudoresCheckbox() {
    return ReportFilterWidgets.buildClientesDeudoresCheckbox(
      value: _clientesDeudores,
      onChanged: (bool value) {
        setState(() {
          _clientesDeudores = value;
        });
        _loadData();
      },
    );
  }

  // Reservadores 체크박스 - ReportFilterWidgets로 이동
  Widget _buildClientesReservadoresCheckbox() {
    return ReportFilterWidgets.buildClientesReservadoresCheckbox(
      value: _clientesReservadores,
      onChanged: (bool value) {
        setState(() {
          _clientesReservadores = value;
        });
        _loadData();
      },
    );
  }

  // 지점 선택 UI (AppBar용) - ReportFilterWidgets로 이동
  Widget _buildSucursalSelector() {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [_buildSucursalSelector] 호출됨');
    debugPrint('   → reportType: ${widget.reportType}');
    debugPrint('   → _selectedSucursal: $_selectedSucursal');
    debugPrint('   → _availableSucursales: $_availableSucursales');
    if (_availableSucursales != null) {
      debugPrint('   → _availableSucursales.length: ${_availableSucursales!.length}');
      debugPrint('   → _availableSucursales 내용: ${_availableSucursales!.join(", ")}');
      if (_selectedSucursal != null) {
        debugPrint('   → 선택된 sucursal ($_selectedSucursal)이 목록에 포함되어 있는가: ${_availableSucursales!.contains(_selectedSucursal)}');
      }
    }
    debugPrint('═══════════════════════════════════════════════════════');
    
    return ReportFilterWidgets.buildSucursalSelector(
      selectedSucursal: _selectedSucursal,
      availableSucursales: _availableSucursales,
      onChanged: (String? value) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [Sucursal 콤보박스 변경]');
        debugPrint('   → 이전 값: $_selectedSucursal');
        debugPrint('   → 새 값: $value');
        debugPrint('   → reportType: ${widget.reportType}');
        debugPrint('═══════════════════════════════════════════════════════');
        setState(() {
          _selectedSucursal = value;
        });
        // 모든 보고서의 경우 데이터 재로드
        debugPrint('🔍 [Sucursal 선택] ${widget.reportType} 보고서 - 데이터 재로드');
        _loadData();
      },
      reportColor: _getReportColor(),
    );
  }

  // Sucursal 콤보박스 표시 여부를 확인하고 디버깅하는 헬퍼 함수
  Widget? _buildSucursalSelectorWithDebug(String location) {
    if (widget.reportType == ReportType.ventas) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔍 [Ventas Sucursal 디버깅] 콤보박스 표시 조건 체크 ($location)');
      debugPrint('   → _availableSucursales: $_availableSucursales');
      debugPrint('   → _availableSucursales == null: ${_availableSucursales == null}');
      if (_availableSucursales != null) {
        debugPrint('   → _availableSucursales.length: ${_availableSucursales!.length}');
        debugPrint('   → _availableSucursales.length > 1: ${_availableSucursales!.length > 1}');
        debugPrint('   → _availableSucursales 내용: ${_availableSucursales!.join(", ")}');
      }
      final shouldShow = _availableSucursales != null && _availableSucursales!.length > 1;
      debugPrint('   → shouldShow (콤보박스 표시 여부): $shouldShow');
      debugPrint('═══════════════════════════════════════════════════════');
      
      if (shouldShow) {
        debugPrint('   ✅ 콤보박스 반환: _buildSucursalSelector() 호출');
        final widget = _buildSucursalSelector();
        debugPrint('   ✅ 실제 반환된 위젯 타입: ${widget.runtimeType}');
        debugPrint('   ✅ 위젯이 null인지 확인: ${widget == null}');
        debugPrint('   ✅ 위젯의 key: ${widget.key}');
        debugPrint('   ✅ 위젯의 child 타입: ${widget is SizedBox ? (widget).child?.runtimeType : "N/A"}');
              debugPrint('═══════════════════════════════════════════════════════');
        return widget;
      } else {
        debugPrint('   ❌ 콤보박스 반환 안 함: null 반환');
        debugPrint('═══════════════════════════════════════════════════════');
        return null;
      }
    }
    
    // ventas가 아닌 경우 기존 로직 사용
    if (_availableSucursales != null && _availableSucursales!.length > 1) {
      return _buildSucursalSelector();
    }
    return null;
  }
}
