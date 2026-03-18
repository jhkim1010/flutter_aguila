part of '../report_screen_legacy.dart';

mixin ReportUtilsMixin on _ReportScreenStateBase {

  // Stocks 보고서의 vista 타입 표시 (Body용)
  Widget _buildStocksViewType() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 800;
        // 대형 화면에서는 AppBar에 표시되므로 여기서는 숨김
        if (isLargeScreen) {
          return const SizedBox.shrink();
        }
        // bcolorview 값에 따라 색상 결정
        Color stocksColor = Colors.orange; // 기본값
        if (_data != null) {
          if (_data!.containsKey('filters') && _data!['filters'] is Map) {
            final filters = _data!['filters'] as Map<String, dynamic>;
            final bcolorview = filters['bcolorview'];
            stocksColor = ReportUtils.isBcolorviewEnabled(bcolorview) ? Colors.orange : Colors.lightBlue;
          } else if (_data!.containsKey('bcolorview')) {
            final bcolorview = _data!['bcolorview'];
            stocksColor = ReportUtils.isBcolorviewEnabled(bcolorview) ? Colors.orange : Colors.lightBlue;
          }
        }
        return StocksBuilder.buildViewType(
          data: _data,
          selectedSucursal: _selectedSucursal,
          onSucursalChanged: (value) {
            setState(() {
              _selectedSucursal = value;
            });
          },
          reportColor: stocksColor,
        );
      },
    );
  }

  // Stocks 보고서의 vista 타입 표시 (AppBar용 - 컴팩트 버전)
  Widget _buildStocksViewTypeInAppBar() {
    if (_data == null || !_data!.containsKey('filters')) {
      return const SizedBox.shrink();
    }
    
    final filters = _data!['filters'] as Map<String, dynamic>?;
    if (filters == null || !filters.containsKey('bcolorview')) {
      return const SizedBox.shrink();
    }
    
    final bcolorview = filters['bcolorview'];
    final isBcolorviewEnabled = ReportUtils.isBcolorviewEnabled(bcolorview);
    final viewType = isBcolorviewEnabled ? 'Vista Resumida' : 'VistaD';
    
    // Vista Detallada일 때만 sucursal 필터 표시
    final bool showSucursalFilter = !isBcolorviewEnabled;
    List<String>? sucursales;
    
    if (showSucursalFilter && _data!.containsKey('data') && _data!['data'] is List) {
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
                value: _selectedSucursal,
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
                onChanged: (value) {
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
  Widget _buildTableFromList(List<dynamic> dataList) {
    if (dataList.isEmpty) {
      return const Center(child: Text('No hay datos'));
    }
    
    // 대량 데이터 처리: 처음 100개만 표시하고 나머지는 스크롤 시 로드
    final displayedList = dataList.take(_displayedItemsCount).toList();
    final totalCount = dataList.length;
    final hasMore = _displayedItemsCount < totalCount;
    
    // 첫 번째 항목의 키를 컬럼으로 사용
    final firstItem = displayedList.first as Map<String, dynamic>;
    final columns = firstItem.keys.map((key) {
      return DataColumn(
        label: Text(
          key.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }).toList();
    
    return Column(
      children: [
        // 테이블 (가상 스크롤 사용)
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 8,
                dataRowMinHeight: 5,
                dataRowMaxHeight: 5,
                headingRowColor: WidgetStateProperty.all(
                  _getReportColor().withOpacity(0.1),
                ),
                columns: columns,
                rows: [
                  ...displayedList.map((item) {
                    if (item is Map<String, dynamic>) {
                      return DataRow(
                        cells: firstItem.keys.map((key) {
                          final value = item[key];
                          final formattedValue = ReportUtils.formatValue(value);
                          final isNumeric = ReportUtils.isNumeric(value);
                          return DataCell(
                            Align(
                              alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                              child: Text(
                                formattedValue,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }
                    final formattedValue = ReportUtils.formatValue(item);
                    final isNumeric = ReportUtils.isNumeric(item);
                    return DataRow(
                      cells: [
                        DataCell(
                          Align(
                            alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                            child: Text(
                              formattedValue,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  // 합계 행 추가
                  _buildTotalRowForTable(firstItem.keys.toList(), dataList),
                ],
              ),
            ),
          ),
        ),
        // 더 보기 버튼 또는 로딩 인디케이터
        if (hasMore)
          Padding(
            padding: const EdgeInsets.all(2.0),
            child: ElevatedButton.icon(
              onPressed: _loadMoreItems,
              icon: const Icon(Icons.expand_more),
              label: Text('Cargar más (${totalCount - _displayedItemsCount} restantes)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getReportColor(),
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  // 테이블용 합계 행 빌드 (캐싱 적용) - ReportTotalRowBuilder로 이동
  DataRow _buildTotalRowForTable(List<String> keys, List<dynamic> dataList) {
    return ReportTotalRowBuilder.buildTotalRowForTable(
      keys,
      dataList,
      _getReportColor(),
    );
  }

  Widget _buildDataCard(dynamic item) {
    return ReportDataBuilder.buildDataCard(item);
  }

  Widget _buildDataCardOld(dynamic item) {
    if (item is Map<String, dynamic>) {
      return Container(
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: item.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.zero,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      ReportUtils.formatValue(entry.value),
                      textAlign: ReportUtils.isNumeric(entry.value) ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        dense: true,
        title: Text(
          item.toString(),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildDataMap(Map<String, dynamic> data) {
    // 테이블 형태로 표시할 수 있는 데이터인지 확인
    if (ReportTableBuilder.isTableData(data)) {
      return ReportTableBuilder.buildTable(data, widget.reportType);
    }

    // 카드 없이 직접 표시
    return ReportDataBuilder.buildDataMap(data);
  }

  Widget _buildValueWidget(dynamic value) {
    return ReportDataBuilder.buildValueWidget(value);
  }

  Widget _buildValueWidgetOld(dynamic value) {
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (value as Map<String, dynamic>).entries.map((entry) {
          final formattedValue = ReportUtils.formatValue(entry.value);
          final isNumeric = ReportUtils.isNumeric(entry.value);
          return Padding(
            padding: EdgeInsets.zero,
            child: Text(
              '${entry.key}: $formattedValue',
              textAlign: isNumeric ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      );
    } else if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.asMap().entries.map((entry) {
          final formattedValue = ReportUtils.formatValue(entry.value);
          final isNumeric = ReportUtils.isNumeric(entry.value);
          return Padding(
            padding: EdgeInsets.zero,
            child: Text(
              '${entry.key + 1}. $formattedValue',
              textAlign: isNumeric ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      );
    }
    final formattedValue = ReportUtils.formatValue(value);
    final isNumeric = ReportUtils.isNumeric(value);
    return Text(
      formattedValue,
      textAlign: isNumeric ? TextAlign.right : TextAlign.left,
      style: const TextStyle(fontSize: 14),
    );
  }

  // 보고서 메뉴 아이템 빌드
  List<PopupMenuEntry<ReportType>> _buildReportMenuItems() {
    debugPrint('🔍 [메뉴] _buildReportMenuItems 호출됨');
    debugPrint('🔍 [메뉴] 현재 reportType: ${widget.reportType}');
    
    // 빌드 날짜 문자열 생성 및 디버깅
    final buildDateString = _getBuildDateString();
    debugPrint('🔍 [메뉴] 빌드 날짜 문자열: "$buildDateString"');
    debugPrint('🔍 [메뉴] BuildInfo.buildDate: "${BuildInfo.buildDate}"');
    debugPrint('🔍 [메뉴] BuildInfo.buildDateTime: "${BuildInfo.buildDateTime}"');
    
    try {
      final buildDate = BuildInfo.buildDateAsDateTime;
      debugPrint('🔍 [메뉴] buildDateAsDateTime: $buildDate');
      debugPrint('🔍 [메뉴] year: ${buildDate.year}, month: ${buildDate.month}, day: ${buildDate.day}');
    } catch (e) {
      debugPrint('❌ [메뉴] buildDateAsDateTime 파싱 오류: $e');
    }
    
    final menuItems = <PopupMenuEntry<ReportType>>[
      PopupMenuItem<ReportType>(
        value: ReportType.ventas,
        child: Row(
          children: [
            Icon(
              Icons.shopping_cart,
              color: widget.reportType == ReportType.ventas ? Colors.purple : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Ventas',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.ventas ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.ventas) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.purple, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<ReportType>(
        value: ReportType.fventas,
        child: Row(
          children: [
            Icon(
              Icons.receipt,
              color: widget.reportType == ReportType.fventas ? Colors.deepPurple : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'FVentas',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.fventas ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.fventas) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.deepPurple, size: 18),
            ],
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<ReportType>(
        value: ReportType.stocks,
        child: Row(
          children: [
            Icon(
              Icons.warehouse,
              color: widget.reportType == ReportType.stocks ? Colors.orange : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Stocks',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.stocks ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.stocks) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.orange, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<ReportType>(
        value: ReportType.codigos,
        child: Row(
          children: [
            Icon(
              Icons.qr_code,
              color: widget.reportType == ReportType.codigos ? Colors.teal : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Codigos',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.codigos ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.codigos) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.teal, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<ReportType>(
        value: ReportType.todocodigos,
        child: Row(
          children: [
            Icon(
              Icons.qr_code_scanner,
              color: widget.reportType == ReportType.todocodigos ? Colors.cyan : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Todo Codigos',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.todocodigos ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.todocodigos) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.cyan, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<ReportType>(
        value: ReportType.items,
        child: Row(
          children: [
            Icon(
              Icons.inventory_2,
              color: widget.reportType == ReportType.items ? Colors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Items',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.items ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.items) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.green, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<ReportType>(
        value: ReportType.ingresos,
        child: Row(
          children: [
            Icon(
              Icons.trending_up,
              color: widget.reportType == ReportType.ingresos ? Colors.indigo : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Ingresos',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.ingresos ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.ingresos) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.indigo, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<ReportType>(
        value: ReportType.gastos,
        child: Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: widget.reportType == ReportType.gastos ? Colors.red : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Gastos',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.gastos ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.gastos) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.red, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<ReportType>(
        value: ReportType.alertas,
        child: Row(
          children: [
            Icon(
              Icons.notifications,
              color: widget.reportType == ReportType.alertas ? Colors.orange : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Alertas',
              style: TextStyle(
                fontWeight: widget.reportType == ReportType.alertas ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (widget.reportType == ReportType.alertas) ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.orange, size: 18),
            ],
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<ReportType>(
        value: ReportType.alertas, // value는 필수이지만 onSelected에서 무시됨 (빌드 날짜 표시용)
        enabled: true, // enabled: true로 설정하여 항상 표시되도록 함
        height: 40, // 높이 명시적으로 설정
        child: Builder(
          builder: (context) {
            final dateString = _getBuildDateString();
            debugPrint('🔍 [메뉴] 빌드 날짜 메뉴 아이템 빌드 중, 문자열: "$dateString"');
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateString,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ];
    
    debugPrint('🔍 [메뉴] 메뉴 아이템 리스트 생성 완료, 총 ${menuItems.length}개');
    debugPrint('🔍 [메뉴] 마지막 아이템 타입: ${menuItems.last.runtimeType}');
    if (menuItems.last is PopupMenuItem) {
      final lastItem = menuItems.last as PopupMenuItem<ReportType>;
      debugPrint('🔍 [메뉴] 마지막 아이템 enabled: ${lastItem.enabled}');
      debugPrint('🔍 [메뉴] 마지막 아이템 value: ${lastItem.value}');
    }
    
    // 빌드 날짜 메뉴 아이템의 인덱스를 저장 (onSelected에서 사용)
    final buildDateItemIndex = menuItems.length - 1;
    debugPrint('🔍 [메뉴] 빌드 날짜 메뉴 아이템 인덱스: $buildDateItemIndex');
    
    return menuItems;
  }

  /// 오늘 날짜를 스페인어 형식으로 반환 (예: "ver. 2026-Enero-02")
  String _getBuildDateString() {
    debugPrint('🔍 [빌드날짜] _getBuildDateString 호출됨');
    try {
      // 오늘 날짜 사용
      final today = DateTime.now();
      debugPrint('🔍 [빌드날짜] 오늘 날짜: $today');
      debugPrint('🔍 [빌드날짜] year: ${today.year}, month: ${today.month}, day: ${today.day}');
      
      final monthNames = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];
      
      if (today.month < 1 || today.month > 12) {
        debugPrint('❌ [빌드날짜] 잘못된 월: ${today.month}');
        return 'ver. ${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      }
      
      final monthName = monthNames[today.month - 1];
      final day = today.day.toString().padLeft(2, '0');
      final result = 'ver. ${today.year}-$monthName-$day';
      debugPrint('✅ [빌드날짜] 최종 결과: "$result"');
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ [빌드날짜] 오류 발생: $e');
      debugPrint('❌ [빌드날짜] 스택 트레이스: $stackTrace');
      final today = DateTime.now();
      final fallback = 'ver. ${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      debugPrint('🔍 [빌드날짜] 폴백 결과: "$fallback"');
      return fallback;
    }
  }

  /// 화면에 표시되는 모든 데이터를 수집 (필터링/정렬 적용)
  Map<String, dynamic> _getDisplayedData() {
    if (_data == null) {
      return {};
    }

    final data = Map<String, dynamic>.from(_data!);
    
    // Gastos 보고서의 경우 summary_by_rubro를 포함한 전체 구조 유지
    // rubro 선택 시 summary_by_rubro는 원본 데이터를 유지하고, data만 필터링된 데이터 사용
    if (widget.reportType == ReportType.gastos && 
        data.containsKey('data') && 
        data['data'] is List) {
      debugPrint('🔍 [ReportScreen] _getDisplayedData: Gastos 보고서 처리');
      
      // summary_by_rubro가 있고 원본 데이터가 저장되어 있으면 원본 사용
      if (data.containsKey('summary_by_rubro') && _originalGastosData != null) {
        debugPrint('   → summary_by_rubro는 원본 데이터에서 가져옴');
        final result = Map<String, dynamic>.from(data);
        // summary_by_rubro는 원본 데이터에서 가져오기
        result['summary_by_rubro'] = _originalGastosData!['summary_by_rubro'];
        return result;
      }
      
      // 원본 데이터가 없으면 현재 데이터 그대로 사용
      debugPrint('   → 원본 데이터 없음, 현재 데이터 사용');
      return data;
    }
    
    // 데이터 리스트가 있는 경우 필터링/정렬 적용
    if (data.containsKey('data')) {
      // items 보고서의 경우 data['data']가 Map일 수 있음
      if (widget.reportType == ReportType.items && data['data'] is Map) {
        debugPrint('⚠️ [Items Report] data["data"]가 Map 구조입니다. List로 변환할 수 없습니다.');
        // Map 구조인 경우 필터링/정렬을 건너뜀
      } else if (data['data'] is List) {
        List<dynamic> dataList = List.from(data['data'] as List);
      
      // 필터링 적용
      if (widget.reportType == ReportType.items || 
          widget.reportType == ReportType.ingresos || 
          widget.reportType == ReportType.gastos ||
          widget.reportType == ReportType.alertas ||
          widget.reportType == ReportType.ventas) {
        // Alertas 보고서의 경우 WEB 버튼이 활성화되면 progname과 evento 필터 모두 적용
        if (widget.reportType == ReportType.alertas && _alertasWeb) {
          final filteringWord = _filteringWordController.text.trim().toLowerCase();
          dataList = dataList.where((item) {
            if (item is Map<String, dynamic>) {
              final progname = item['progname']?.toString().toLowerCase() ?? '';
              final evento = item['evento']?.toString().toLowerCase() ?? '';
              // progname에 'web'이 포함되어야 하고
              final hasWeb = progname.contains('web');
              // filteringWord가 비어있지 않으면 evento에도 포함되어야 함
              if (filteringWord.isNotEmpty) {
                return hasWeb && evento.contains(filteringWord);
              } else {
                return hasWeb;
              }
            }
            return false;
          }).toList();
        } else {
          // 일반 filteringWord 필터링
          final filteringWord = _filteringWordController.text.trim().toLowerCase();
          if (filteringWord.isNotEmpty) {
            dataList = dataList.where((item) {
              if (item is Map<String, dynamic>) {
                if (widget.reportType == ReportType.items) {
                  // codigo1 또는 desc1(제품 이름)에서 검색
                  final codigo1 = item['codigo1']?.toString().toLowerCase() ?? '';
                  final desc1 = item['desc1']?.toString().toLowerCase() ?? '';
                  return codigo1.contains(filteringWord) || desc1.contains(filteringWord);
                } else if (widget.reportType == ReportType.ingresos) {
                  final codigo = item['codigo']?.toString().toLowerCase() ?? '';
                  final descripcion = item['descripcion']?.toString().toLowerCase() ?? '';
                  return codigo.contains(filteringWord) || descripcion.contains(filteringWord);
                } else if (widget.reportType == ReportType.gastos) {
                  // gastos 필터링: tema 칼럼에서 대소문자 구분 없이 비교
                  final tema = item['tema']?.toString().toLowerCase() ?? '';
                  return tema.contains(filteringWord);
                } else if (widget.reportType == ReportType.alertas) {
                  // alertas 필터링 로직: evento 필드에서 검색
                  final evento = item['evento']?.toString().toLowerCase() ?? '';
                  return evento.contains(filteringWord);
                } else if (widget.reportType == ReportType.ventas) {
                  if (item.containsKey('clientenombre')) {
                    final clientenombre = item['clientenombre']?.toString().toLowerCase() ?? '';
                    return clientenombre.contains(filteringWord);
                  } else {
                    final fecha = item['fecha']?.toString().toLowerCase() ?? '';
                    final sucursal = item['sucursal']?.toString().toLowerCase() ?? '';
                    final nencargado = item['nencargado']?.toString().toLowerCase() ?? '';
                    return fecha.contains(filteringWord) || 
                           sucursal.contains(filteringWord) ||
                           nencargado.contains(filteringWord);
                  }
                } else if (widget.reportType == ReportType.fventas) {
                  // fventas 필터링: cuit, cliente, clientenombre, numfactura 필드에서 검색
                  final cuit = item['cuit']?.toString().toLowerCase() ?? '';
                  final cliente = item['cliente']?.toString().toLowerCase() ?? '';
                  final clientenombre = item['clientenombre']?.toString().toLowerCase() ?? '';
                  final numfactura = item['numfactura']?.toString().toLowerCase() ?? '';
                  return cuit.contains(filteringWord) || 
                         cliente.contains(filteringWord) ||
                         clientenombre.contains(filteringWord) ||
                         numfactura.contains(filteringWord);
                }
              }
              return false;
            }).toList();
          }
        }
      }
      
      // 모든 보고서의 sucursal 필터 적용
      if (_selectedSucursal != null) {
        dataList = dataList.where((item) {
          if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
            final sucursal = item['sucursal']?.toString();
            return sucursal == _selectedSucursal;
          }
          return false;
        }).toList();
      }
      
      // Codigos 및 Todo Codigos 보고서의 필터링
      if (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) {
        final filteringWord = _filteringWordController.text.trim().toLowerCase();
        if (filteringWord.isNotEmpty) {
          dataList = dataList.where((item) {
            if (item is Map<String, dynamic>) {
              final codigo = item['codigo']?.toString().toLowerCase() ?? '';
              final descripcion = item['descripcion']?.toString().toLowerCase() ?? '';
              return codigo.contains(filteringWord) || descripcion.contains(filteringWord);
            }
            return false;
          }).toList();
        }
      }
      
      // Items, Ingresos, Gastos 및 Alertas 보고서의 정렬 적용
      if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos || widget.reportType == ReportType.gastos || widget.reportType == ReportType.alertas) {
        // Alertas 보고서는 항상 id_log 역순으로 정렬
        if (widget.reportType == ReportType.alertas) {
          dataList.sort((a, b) {
            if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) {
              return 0;
            }
            
            final aIdLog = a['id_log'];
            final bIdLog = b['id_log'];
            
            // null 처리
            if (aIdLog == null && bIdLog == null) return 0;
            if (aIdLog == null) return 1; // null은 뒤로
            if (bIdLog == null) return -1; // null은 뒤로
            
            // 숫자 비교 (역순: 큰 값이 앞으로)
            final aNum = ReportUtils.isNumeric(aIdLog) ? num.tryParse(aIdLog.toString().replaceAll(',', '')) : null;
            final bNum = ReportUtils.isNumeric(bIdLog) ? num.tryParse(bIdLog.toString().replaceAll(',', '')) : null;
            
            if (aNum != null && bNum != null) {
              return bNum.compareTo(aNum); // 역순 정렬
            }
            
            // 문자열 비교 (역순)
            final aStr = aIdLog.toString().toLowerCase();
            final bStr = bIdLog.toString().toLowerCase();
            return bStr.compareTo(aStr); // 역순 정렬
          });
        } else if (_sortColumn != null) {
          // 다른 보고서는 기존 정렬 로직 사용
          dataList.sort((a, b) {
            if (a is! Map<String, dynamic> || b is! Map<String, dynamic>) {
              return 0;
            }
            
            final aValue = a[_sortColumn];
            final bValue = b[_sortColumn];
            
            if (aValue == null && bValue == null) return 0;
            if (aValue == null) return _sortAscending ? -1 : 1;
            if (bValue == null) return _sortAscending ? 1 : -1;
            
            final aNum = ReportUtils.isNumeric(aValue) ? num.tryParse(aValue.toString().replaceAll(',', '')) : null;
            final bNum = ReportUtils.isNumeric(bValue) ? num.tryParse(bValue.toString().replaceAll(',', '')) : null;
            
            if (aNum != null && bNum != null) {
              final comparison = aNum.compareTo(bNum);
              return _sortAscending ? comparison : -comparison;
            }
            
            final aStr = aValue.toString().toLowerCase();
            final bStr = bValue.toString().toLowerCase();
            final comparison = aStr.compareTo(bStr);
            return _sortAscending ? comparison : -comparison;
          });
        }
      }
      
      // 필터링/정렬된 데이터로 업데이트
      data['data'] = dataList;
      }
    }
    
    // Gastos 보고서의 경우 data.detail에 필터링 적용
    if (widget.reportType == ReportType.gastos && 
        data.containsKey('data') && 
        data['data'] is Map &&
        (data['data'] as Map).containsKey('detail')) {
      final dataMap = data['data'] as Map<String, dynamic>;
      if (dataMap['detail'] is List) {
        List<dynamic> detailList = List.from(dataMap['detail'] as List);
        
        // sucursal 필터 적용
        if (_selectedSucursal != null) {
          detailList = detailList.where((item) {
            if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
              final sucursal = item['sucursal']?.toString();
              return sucursal == _selectedSucursal;
            }
            return false;
          }).toList();
        }
        
        // 필터링된 detail로 업데이트
        dataMap['detail'] = detailList;
        data['data'] = dataMap;
      }
    }
    
    return data;
  }

  String _getReportTitle() {
    final base = ReportUtils.getReportTitle(widget.reportType);
    final db = _connectedDatabaseName ?? '';
    return db.isEmpty ? '$base { }' : '$base { $db }';
  }
  IconData _getReportIcon() => ReportUtils.getReportIcon(widget.reportType);
  Color _getReportColor() => ReportUtils.getReportColor(widget.reportType);

  /// 다른 보고서 타입으로 전환. onSwitchReport가 있으면 콜백 호출(슬림 ReportScreen으로 라우팅), 없으면 기존대로 push.
  void _switchToReport(ReportType reportType) {
    if (reportType == widget.reportType) return;
    if (widget.onSwitchReport != null) {
      widget.onSwitchReport!(reportType);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReportScreenLegacy(
          serverUrl: widget.serverUrl,
          reportType: reportType,
          initialDate: widget.initialDate,
          initialItemsStartDate: widget.initialItemsStartDate,
          initialItemsEndDate: widget.initialItemsEndDate,
          initialFilteringWord: _getInitialFilteringWordForNavigation(widget.reportType, reportType),
          initialSortColumn: widget.initialSortColumn,
          initialSortAscending: widget.initialSortAscending,
          onStateChanged: widget.onStateChanged,
          onItemsDateRangeChanged: widget.onItemsDateRangeChanged,
          useFullWidth: widget.useFullWidth,
          onMenuPressed: widget.onMenuPressed,
          initialAvailableSucursales: widget.initialAvailableSucursales,
          onSwitchReport: widget.onSwitchReport,
        ),
      ),
    );
  }

  // Items 보고서용 데이터 개수 표시
  Widget _buildItemsDataCount() {
    return ReportHeaderBuilders.buildItemsDataCount(_data);
  }
}
