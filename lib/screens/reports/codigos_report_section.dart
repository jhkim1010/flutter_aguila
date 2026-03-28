part of '../report_screen_legacy.dart';

mixin CodigosReportMixin on _ReportScreenStateBase {
  // Codigos 보고서 콘텐츠 빌드
  Widget _buildCodigosContent(Map<String, dynamic> data) {
    // ============================================================
    // 📱 Codigos/Todocodigos 화면 깨짐 현상 디버깅
    // ============================================================
    final layoutInfo = MobileLayoutHelper.getLayoutInfo(context);
    final isMobilePhone = layoutInfo.isMobilePhone;
    final isMobilePhonePortrait = layoutInfo.isMobilePhonePortrait;
    final isMobilePhoneLandscape = layoutInfo.isMobilePhoneLandscape;
    final screenSize = layoutInfo.screenSize;
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📱 [Codigos/Todocodigos] _buildCodigosContent 시작');
    debugPrint('   → reportType: ${widget.reportType}');
    debugPrint('   → isMobilePhone: $isMobilePhone');
    debugPrint('   → isMobilePhonePortrait: $isMobilePhonePortrait');
    debugPrint('   → isMobilePhoneLandscape: $isMobilePhoneLandscape');
    debugPrint('   → screenSize: $screenSize');
    debugPrint('   → screenWidth: ${screenSize.width}');
    debugPrint('   → screenHeight: ${screenSize.height}');
    debugPrint('═══════════════════════════════════════════════════════');
    
    final dataList = data['data'] as List;
    if (dataList.isEmpty) {
      debugPrint('   ⚠️ [Codigos/Todocodigos] dataList가 비어있음');
      return const Center(child: Text('No data available'));
    }
    
    debugPrint('   → dataList.length: ${dataList.length}');
    debugPrint('   → _selectedCodigo: ${_selectedCodigo != null ? "있음" : "null"}');

    // 첫 번째 항목에서 모든 칼럼 키 추출
    final firstItem = dataList[0] as Map<String, dynamic>;
    final columnKeys = widget.reportType == ReportType.todocodigos
        ? ['id_todocodigo', 'tcodigo', 'tdesc', 'tpre1', 'tpre2', 'tpre3', 'tpre4', 'tpre5', 'utime', 'borrado', 'ip', 'mac']
            .where((key) => firstItem.containsKey(key))
            .toList()
        : firstItem.keys
            .where((key) => key != 'id_woocommerce' && key != 'id_woocommerce_producto')
            .toList();
    
    debugPrint('   → columnKeys.length: ${columnKeys.length}');
    debugPrint('   → columnKeys: $columnKeys');
    
    // 칼럼별 너비 설정
    final columnWidths = <String, double>{
      'codigo': 150,
      'descripcion': 300,
      'pre1': 100,
      'pre2': 100,
      'pre3': 100,
      'pre4': 100,
      'pre5': 100,
      'preorg': 100,
      'tcodigo': 120,
      'tdesc': 300,
      'tpre1': 100,
      'tpre2': 100,
      'tpre3': 100,
      'tpre4': 100,
      'tpre5': 100,
      'utime': 150,
      'borrado': 80,
      'ip': 120,
      'mac': 150,
      'b_sincronizar_x_web': 120,
      'id_woocommerce': 120,
      'id_woocommerce_producto': 150,
      'id_codigo': 100,
      'id_todocodigo': 120,
    };
    
    // 칼럼별 표시 이름 설정
    final columnDisplayNames = <String, String>{
      'codigo': 'Codigo',
      'descripcion': 'Descripción',
      'pre1': 'Precio 1',
      'pre2': 'Precio 2',
      'pre3': 'Precio 3',
      'pre4': 'Precio 4',
      'pre5': 'Precio 5',
      'preorg': 'Precio Org',
      'tcodigo': 'T Codigo',
      'tdesc': 'T Desc',
      'tpre1': 'T Precio 1',
      'tpre2': 'T Precio 2',
      'tpre3': 'T Precio 3',
      'tpre4': 'T Precio 4',
      'tpre5': 'T Precio 5',
      'utime': 'Utime',
      'borrado': 'Borrado',
      'ip': 'IP',
      'mac': 'MAC',
      'b_sincronizar_x_web': 'Sincronizar Web',
      'id_woocommerce': 'ID WooCommerce',
      'id_woocommerce_producto': 'ID WooCommerce Producto',
      'id_codigo': 'ID Codigo',
      'id_todocodigo': 'ID Todo Codigo',
    };
    
    // 기본 너비가 없는 칼럼은 100으로 설정
    for (var key in columnKeys) {
      if (!columnWidths.containsKey(key)) {
        columnWidths[key] = 100.0;
      }
      if (!columnDisplayNames.containsKey(key)) {
        columnDisplayNames[key] = key;
      }
    }

    // DB·보고서별 저장된 칼럼 너비 로드 및 병합
    final dbKey = '${_connectedDatabaseName ?? ""}_${widget.reportType == ReportType.todocodigos ? "todocodigos" : "codigos"}';
    if (_codigosColumnWidthsDbKey != dbKey) {
      _codigosColumnWidthsDbKey = dbKey;
      _codigosColumnWidths = null;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final saved = await CodigosColumnWidthStorage.load(_connectedDatabaseName ?? '', widget.reportType);
        if (!mounted) return;
        setState(() {
          _codigosColumnWidths = saved != null ? Map<String, double>.from(saved) : null;
        });
      });
    }
    final mergedColumnWidths = Map<String, double>.from(columnWidths);
    if (_codigosColumnWidths != null && _codigosColumnWidthsDbKey == dbKey) {
      mergedColumnWidths.addAll(_codigosColumnWidths!);
    }

    // ============================================================
    // 📱 Codigos/Todocodigos Row 레이아웃 디버깅
    // ============================================================
    // 핸드폰에서 화면 깨짐 현상 원인 파악을 위한 디버깅
    final mediaQuery = MediaQuery.of(context);
    final availableWidth = mediaQuery.size.width;
    final availableHeight = mediaQuery.size.height;
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📱 [Codigos/Todocodigos] Row 레이아웃 빌드 시작');
    debugPrint('   → reportType: ${widget.reportType}');
    debugPrint('   → _selectedCodigo != null: ${_selectedCodigo != null}');
    debugPrint('   → availableWidth: $availableWidth');
    debugPrint('   → availableHeight: $availableHeight');
    debugPrint('   → isMobilePhone: $isMobilePhone');
    debugPrint('   → isMobilePhonePortrait: $isMobilePhonePortrait');
    debugPrint('   → isMobilePhoneLandscape: $isMobilePhoneLandscape');
    debugPrint('   → Row children 개수: ${_selectedCodigo != null ? 2 : 1}');
    debugPrint('   → 첫 번째 Expanded flex: ${_selectedCodigo != null ? 1 : 1}');
    debugPrint('   → 두 번째 Expanded flex: ${_selectedCodigo != null ? 1 : 0} (없음)');
    debugPrint('═══════════════════════════════════════════════════════');
    
    return Builder(
      builder: (context) {
        // 렌더링 후 실제 크기 측정
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('📱 [Codigos/Todocodigos] Row 실제 렌더링 크기');
            debugPrint('   → Row width: ${renderBox.size.width}');
            debugPrint('   → Row height: ${renderBox.size.height}');
            debugPrint('   → 예상 width: $availableWidth');
            debugPrint('   → 차이: ${renderBox.size.width - availableWidth}');
            
            // Row의 자식들 확인
            int childIndex = 0;
            renderBox.visitChildren((child) {
              if (child is RenderBox) {
                debugPrint('   → [Row 자식 #$childIndex]');
                debugPrint('      → width: ${child.size.width}');
                debugPrint('      → height: ${child.size.height}');
                debugPrint('      → 타입: ${child.runtimeType}');
                childIndex++;
              }
            });
            debugPrint('═══════════════════════════════════════════════════════');
          }
        });
        
        return Row(
          children: [
            Expanded(
              flex: _selectedCodigo != null ? 1 : 1,
              child: Builder(
                builder: (leftContext) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final RenderBox? renderBox = leftContext.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      debugPrint('📱 [Codigos/Todocodigos] 왼쪽 Expanded 실제 크기');
                      debugPrint('   → width: ${renderBox.size.width}');
                      debugPrint('   → height: ${renderBox.size.height}');
                    }
                  });
                  
                  // ResizableDataTable 사용: 행 선택/편집 강조를 위해 인덱스 계산
                  final isTodocodigos = widget.reportType == ReportType.todocodigos;
                  int? selectedIdx;
                  if (_selectedCodigo != null) {
                    final i = dataList.indexWhere((item) {
                      final m = item as Map<String, dynamic>;
                      return isTodocodigos
                          ? m['tcodigo'] == _selectedCodigo!['tcodigo']
                          : m['codigo'] == _selectedCodigo!['codigo'];
                    });
                    selectedIdx = i < 0 ? null : i;
                  }
                  int? editedIdx;
                  if (_editedCodigoIdentifier != null) {
                    final i = dataList.indexWhere((item) {
                      final m = item as Map<String, dynamic>;
                      final id = isTodocodigos
                          ? m['tcodigo']?.toString()
                          : m['codigo']?.toString();
                      return id == _editedCodigoIdentifier;
                    });
                    editedIdx = i < 0 ? null : i;
                  }
                  return ResizableDataTable(
                    columns: CodigosBuilder.buildColumnDefs(isTodocodigos: isTodocodigos),
                    rows: CodigosBuilder.buildRows(
                      dataList,
                      isTodocodigos: isTodocodigos,
                      selectedCodigo: _selectedCodigo,
                      editedCodigoIdentifier: _editedCodigoIdentifier,
                      reportColor: _getReportColor(),
                    ),
                    columnWidths: mergedColumnWidths,
                    onColumnResize: (String columnKey, double newWidth) {
                      setState(() {
                        _codigosColumnWidths ??= Map<String, double>.from(mergedColumnWidths);
                        _codigosColumnWidths![columnKey] = newWidth;
                      });
                      CodigosColumnWidthStorage.save(_connectedDatabaseName ?? '', widget.reportType, _codigosColumnWidths!);
                    },
                    sortColumn: _codigosSortColumn,
                    sortAscending: _codigosSortAscending,
                    onSort: (column, ascending) {
                      setState(() {
                        if (_codigosSortColumn == column) {
                          _codigosSortAscending = ascending;
                        } else {
                          _codigosSortColumn = column;
                          _codigosSortAscending = false;
                        }
                      });
                      _notifyStateChanged();
                      _reloadDataWithFilters();
                    },
                    headerColor: _getReportColor(),
                    isLoadingMore: _isLoadingMoreCodigos,
                    scrollController: _scrollController,
                    selectedRowIndex: selectedIdx,
                    editedRowIndex: editedIdx,
                    onRowTap: (index) {
                      final codigo = dataList[index] as Map<String, dynamic>;
                      if (isTodocodigos) {
                        final idTodocodigo = codigo['id_todocodigo']?.toString();
                        if (idTodocodigo == null || idTodocodigo.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('id_todocodigo가 없어서 편집할 수 없습니다.'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                      }
                      setState(() {
                        _selectedCodigo = Map<String, dynamic>.from(codigo);
                        _isEditingCodigo = false;
                        _initializeCodigoEditControllers();
                      });
                    },
                    onRowDoubleTap: (index) {
                      final codigo = dataList[index] as Map<String, dynamic>;
                      if (isTodocodigos) {
                        final idTodocodigo = codigo['id_todocodigo']?.toString();
                        if (idTodocodigo == null || idTodocodigo.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('id_todocodigo가 없어서 편집할 수 없습니다.'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                      }
                      setState(() {
                        _selectedCodigo = Map<String, dynamic>.from(codigo);
                        _isEditingCodigo = false;
                        _initializeCodigoEditControllers();
                      });
                    },
                  );
                },
              ),
            ),
            // 오른쪽: 선택된 Codigo 편집 UI
            if (_selectedCodigo != null)
              Expanded(
                flex: 1,
                child: Builder(
                  builder: (rightContext) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final RenderBox? renderBox = rightContext.findRenderObject() as RenderBox?;
                      if (renderBox != null) {
                        debugPrint('📱 [Codigos/Todocodigos] 오른쪽 Expanded 실제 크기');
                        debugPrint('   → width: ${renderBox.size.width}');
                        debugPrint('   → height: ${renderBox.size.height}');
                      }
                    });
                    
                    return _buildCodigoEditPanel();
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // Codigos 칼럼 헤더 빌드
  Widget _buildCodigosHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[400]!,
            width: 2,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSortableHeader('codigo', 'Codigo', 150),
          const SizedBox(width: 12),
          _buildSortableHeader('descripcion', 'Descripción', 300),
          const SizedBox(width: 12),
          _buildSortableHeader('pre1', 'Precio 1', 100),
          const SizedBox(width: 12),
          _buildSortableHeader('pre2', 'Precio 2', 100),
        ],
      ),
    );
  }
  
  // Stocks 칼럼 헤더 빌드
  @override
  Widget _buildStocksHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getReportColor().withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[400]!,
            width: 2,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSortableHeader('codigo', 'Codigo', 150),
            const SizedBox(width: 12),
            _buildSortableHeader('descripcion', 'Descripción', 300),
            const SizedBox(width: 12),
            _buildSortableHeader('stockreal', 'Stock', 100),
            const SizedBox(width: 12),
            _buildSortableHeader('pre1', 'Precio 1', 100),
          ],
        ),
      ),
    );
  }
  
  // 정렬 가능한 헤더 위젯 빌드 (Codigos용)
  Widget _buildSortableHeader(String columnKey, String displayName, double width) {
    final isSorted = ((widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) && _codigosSortColumn == columnKey) ||
                     (widget.reportType == ReportType.stocks && _stocksSortColumn == columnKey);
    final isAscending = (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos)
        ? _codigosSortAscending 
        : _stocksSortAscending;
    
    return InkWell(
      onTap: () {
        setState(() {
          if (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) {
            if (_codigosSortColumn == columnKey) {
              // 같은 칼럼을 클릭하면 정렬 방향 변경
              _codigosSortAscending = !_codigosSortAscending;
            } else {
              // 다른 칼럼을 클릭하면 새 칼럼으로 정렬 (첫 클릭 시 내림차순)
              _codigosSortColumn = columnKey;
              _codigosSortAscending = false;
            }
          } else if (widget.reportType == ReportType.stocks) {
            if (_stocksSortColumn == columnKey) {
              // 같은 칼럼을 클릭하면 정렬 방향 변경
              _stocksSortAscending = !_stocksSortAscending;
            } else {
              // 다른 칼럼을 클릭하면 새 칼럼으로 정렬 (첫 클릭 시 내림차순)
              _stocksSortColumn = columnKey;
              _stocksSortAscending = false;
            }
          }
        });
        _notifyStateChanged();
        // 데이터 재로드
        _reloadDataWithFilters();
      },
      child: SizedBox(
        width: width,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSorted ? Colors.teal[700] : Colors.black87,
              ),
            ),
            if (isSorted)
              Icon(
                isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: Colors.teal[700],
              ),
          ],
        ),
      ),
    );
  }

  // Codigo 편집 컨트롤러 초기화
  void _initializeCodigoEditControllers() {
    if (_selectedCodigo == null) return;

    // 편집 가능한 필드만 초기화
    final editableFields = widget.reportType == ReportType.todocodigos
        ? ['tcodigo', 'tdesc', 'tpre1', 'tpre2', 'tpre3', 'tpre4', 'tpre5', 'borrado']
        : ['codigo', 'descripcion', 'pre1', 'pre2', 'pre3', 'pre4', 'pre5', 'b_mostrar_vcontrol', 'borrado'];

    for (var field in editableFields) {
      if (!_codigoEditControllers.containsKey(field)) {
        _codigoEditControllers[field] = TextEditingController();
      }
      
      // FocusNode 초기화
      if (!_codigoFocusNodes.containsKey(field)) {
        _codigoFocusNodes[field] = FocusNode();
      }
      
      // 필드가 없으면 기본값 사용
      final value = _selectedCodigo![field];
      // boolean 필드는 1/0으로 변환
      if (field == 'b_mostrar_vcontrol' || field == 'borrado') {
        // 필드가 없으면 기본값 0 (false)
        if (value == null && !_selectedCodigo!.containsKey(field)) {
          _codigoEditControllers[field]!.text = '0';
        } else {
          _codigoEditControllers[field]!.text = (value == 1 || value == true || value?.toString() == '1') ? '1' : '0';
        }
      } else {
      _codigoEditControllers[field]!.text = value?.toString() ?? '';
      }
    }
  }
  
  // Codigo 편집 리소스 정리
  void _disposeCodigoEditResources() {
    for (var controller in _codigoEditControllers.values) {
      controller.dispose();
    }
    _codigoEditControllers.clear();
    
    for (var focusNode in _codigoFocusNodes.values) {
      focusNode.dispose();
    }
    _codigoFocusNodes.clear();
  }

  // Codigo 편집 패널 빌드
  Widget _buildCodigoEditPanel() {
    if (_selectedCodigo == null) return const SizedBox.shrink();

    return CodigosBuilder.buildEditPanel(
      selectedCodigo: _selectedCodigo!,
      editControllers: _codigoEditControllers,
      isLoading: _isLoading,
      onClose: () {
        setState(() {
          _selectedCodigo = null;
          _isEditingCodigo = false;
        });
      },
      onSave: _saveCodigoChanges,
      reportColor: _getReportColor(),
      reportType: widget.reportType,
      buildEditField: (fieldKey, label, order) {
        if (!_codigoEditControllers.containsKey(fieldKey)) {
          _codigoEditControllers[fieldKey] = TextEditingController();
          // 필드가 없으면 기본값 설정
          if (fieldKey == 'b_mostrar_vcontrol' || fieldKey == 'borrado') {
            final value = _selectedCodigo![fieldKey];
            if (!_selectedCodigo!.containsKey(fieldKey) || value == null) {
              _codigoEditControllers[fieldKey]!.text = '0';
            } else {
              _codigoEditControllers[fieldKey]!.text = (value == 1 || value == true || value?.toString() == '1') ? '1' : '0';
            }
          } else {
            _codigoEditControllers[fieldKey]!.text = _selectedCodigo![fieldKey]?.toString() ?? '';
          }
        }
        
        // FocusNode 초기화
        if (!_codigoFocusNodes.containsKey(fieldKey)) {
          _codigoFocusNodes[fieldKey] = FocusNode();
        }
        
        return CodigosBuilder.buildEditField(
          fieldKey: fieldKey,
          label: label,
          controller: _codigoEditControllers[fieldKey]!,
          focusNode: _codigoFocusNodes[fieldKey]!,
          order: order,
          onChanged: (value) {
            setState(() {
              _isEditingCodigo = true;
            });
          },
        );
      },
    );
  }

  // Codigo 편집 필드 빌드
  Widget _buildCodigoEditField(String fieldKey, String label) {
    if (!_codigoEditControllers.containsKey(fieldKey)) {
      _codigoEditControllers[fieldKey] = TextEditingController();
    }
    
    final controller = _codigoEditControllers[fieldKey]!;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        enabled: true,
      ),
      keyboardType: (fieldKey.startsWith('pre') || 
                     fieldKey == 'borrado' || 
                     fieldKey.startsWith('id_')) 
          ? TextInputType.number 
          : TextInputType.text,
      onChanged: (value) {
        setState(() {
          _isEditingCodigo = true;
        });
      },
    );
  }

  // Codigo 변경사항 저장
  Future<void> _saveCodigoChanges() async {
    if (_selectedCodigo == null) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await CodigosBuilder.saveCodigoChanges(
        databaseService: _databaseService,
        selectedCodigo: _selectedCodigo!,
        editControllers: _codigoEditControllers,
        reportType: widget.reportType,
      );

      // 서버 응답 확인
      if (response.containsKey('error')) {
        throw Exception(response['error'] ?? 'Error al actualizar codigo');
      }

      // 로컬 데이터 업데이트
      final dataList = _data!['data'] as List;
      final index = widget.reportType == ReportType.todocodigos
          ? dataList.indexWhere((item) => 
              item is Map<String, dynamic> && 
              item['tcodigo'] == _selectedCodigo!['tcodigo'])
          : dataList.indexWhere((item) => 
          item is Map<String, dynamic> && 
          item['codigo'] == _selectedCodigo!['codigo']);
      
      if (index != -1) {
        // 편집된 값들 수집 (편집 가능한 필드만)
        final editableFields = widget.reportType == ReportType.todocodigos
            ? ['tcodigo', 'tdesc', 'tpre1', 'tpre2', 'tpre3', 'tpre4', 'tpre5', 'borrado']
            : ['codigo', 'descripcion', 'pre1', 'pre2', 'pre3', 'pre4', 'pre5', 'b_mostrar_vcontrol', 'borrado'];
        
        final updatedData = <String, dynamic>{};
        for (var entry in _codigoEditControllers.entries) {
          final key = entry.key;
          
          // 편집 가능한 필드만 포함
          if (!editableFields.contains(key)) {
            continue;
          }
          
          final value = entry.value.text.trim();
          
          if (key.startsWith('pre') || key.startsWith('tpre')) {
            final numValue = num.tryParse(value);
            if (numValue != null) {
              updatedData[key] = numValue;
            } else if (value.isEmpty) {
              updatedData[key] = null;
            } else {
              updatedData[key] = value;
            }
          } else if (key == 'b_mostrar_vcontrol' || key == 'borrado') {
            // boolean 필드는 1 또는 0으로 변환
            updatedData[key] = (value == '1' || value.toLowerCase() == 'true') ? 1 : 0;
          } else {
            updatedData[key] = value.isEmpty ? null : value;
          }
        }

        dataList[index] = {...dataList[index] as Map<String, dynamic>, ...updatedData};
        _selectedCodigo = Map<String, dynamic>.from(dataList[index] as Map<String, dynamic>);
        _initializeCodigoEditControllers();
        
        // 편집된 codigo 식별자 저장 (색상 표시용)
        final editedIdentifier = widget.reportType == ReportType.todocodigos
            ? _selectedCodigo!['tcodigo']?.toString()
            : _selectedCodigo!['codigo']?.toString();

      setState(() {
        _isLoading = false;
        _isEditingCodigo = false;
          _selectedCodigo = null; // 편집 패널 닫기
          _editedCodigoIdentifier = editedIdentifier; // 편집된 항목 표시
        });
        
        // 3초 후 색상 표시 제거
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _editedCodigoIdentifier = null;
            });
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _isEditingCodigo = false;
          _selectedCodigo = null; // 편집 패널 닫기
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Actualizado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
