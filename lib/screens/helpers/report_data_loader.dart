part of '../report_screen_legacy.dart';

mixin ReportDataLoaderMixin on _ReportScreenStateBase {

  /// Tipos와 Temporadas 데이터 로드
  Future<void> _loadTiposAndTemporadas() async {
    try {
      final tipos = await _databaseService.getTipos();
      final temporadas = await _databaseService.getTemporadas();
      // 로그는 database_service에서 출력됨
      
      // 디버깅: 실제 데이터 구조 확인
      if (tipos.isNotEmpty) {
        print('🔍 Tipos 데이터 구조 확인:');
        print('   첫 번째 tipo 키: ${tipos.first.keys.toList()}');
        print('   첫 번째 tipo 값: ${tipos.first}');
      }
      if (temporadas.isNotEmpty) {
        print('🔍 Temporadas 데이터 구조 확인:');
        print('   첫 번째 temporada 키: ${temporadas.first.keys.toList()}');
        print('   첫 번째 temporada 값: ${temporadas.first}');
      }
      
      if (mounted) {
        setState(() {
          _tiposList = tipos;
          _temporadasList = temporadas;
          
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [Tipos/Temporadas 로드 완료]');
          debugPrint('   → _tiposList.length: ${tipos.length}');
          debugPrint('   → _temporadasList.length: ${temporadas.length}');
          debugPrint('   → reportType: ${widget.reportType}');
          if (tipos.isNotEmpty) {
            debugPrint('   → 첫 번째 tipo: ${tipos.first}');
          }
          if (temporadas.isNotEmpty) {
            debugPrint('   → 첫 번째 temporada: ${temporadas.first}');
          }
          debugPrint('═══════════════════════════════════════════════════════');
          
          // 선택된 값이 새 리스트에 없으면 null로 초기화
          if (_selectedTipoId != null) {
            final tipoIds = tipos.map((tipo) {
              final id = tipo['id_tipo'] is int 
                  ? tipo['id_tipo'] 
                  : (tipo['id_tipo'] != null ? int.tryParse(tipo['id_tipo'].toString()) : null) ??
                    (tipo['id'] is int ? tipo['id'] : (tipo['id'] != null ? int.tryParse(tipo['id'].toString()) : null));
              return id;
            }).where((id) => id != null).cast<int>().toList();
            if (!tipoIds.contains(_selectedTipoId)) {
              _selectedTipoId = null;
            }
          }
          
          if (_selectedTemporadaId != null) {
            final temporadaIds = temporadas.map((temporada) {
              final id = temporada['id_temporada'] is int 
                  ? temporada['id_temporada'] 
                  : (temporada['id_temporada'] != null ? int.tryParse(temporada['id_temporada'].toString()) : null) ??
                    (temporada['id'] is int ? temporada['id'] : (temporada['id'] != null ? int.tryParse(temporada['id'].toString()) : null));
              return id;
            }).where((id) => id != null).cast<int>().toList();
            if (!temporadaIds.contains(_selectedTemporadaId)) {
              _selectedTemporadaId = null;
            }
          }
        });
      }
    } catch (e) {
      print('⚠️ Tipos/Temporadas 로드 실패: $e');
    }
  }

  /// Gastos 보고서의 오른쪽 패널(세부 테이블)만 갱신하는 메서드
  Future<void> _loadGastosDetailOnly(String? rubroCode) async {
    if (widget.reportType != ReportType.gastos) return;
    
    setState(() {
      _isLoadingGastosDetail = true;
    });

    try {
      final now = DateTime.now();
      final startDate = _itemsStartDate ?? now;
      final endDate = _itemsEndDate ?? now;
      final currentFilteringWord = _filteringWordController.text.trim();
      
      final filters = <String, dynamic>{
        'fecha_inicio': DateFormat('yyyy-MM-dd').format(startDate),
        'fecha_fin': DateFormat('yyyy-MM-dd').format(endDate),
      };
      if (_selectedSucursal != null) {
        filters['sucursal'] = _selectedSucursal;
      }
      
      debugPrint('🔍 [ReportScreen] Gastos Detail만 API 요청 시작');
      debugPrint('   → rubroCode: $rubroCode');
      debugPrint('   → filteringWord: ${currentFilteringWord.isNotEmpty ? currentFilteringWord : null}');
      debugPrint('   → sucursal: $_selectedSucursal');
      
      final data = await _databaseService.getGastosReport(
        filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
        rubroCode: rubroCode,
        filters: filters,
      );
      
      debugPrint('🔍 [ReportScreen] Gastos Detail API 응답 받음');
      
      if (mounted && _data != null) {
        setState(() {
          // summary_by_rubro는 유지하고 detail/data만 업데이트
          if (data.containsKey('data')) {
            if (_data!['data'] is Map && data['data'] is Map) {
              // 기존 구조: data가 Map이고 detail 키가 있는 경우
              final newDataMap = Map<String, dynamic>.from(_data!);
              final newDataData = Map<String, dynamic>.from(newDataMap['data'] as Map);
              newDataData['detail'] = (data['data'] as Map)['detail'];
              newDataMap['data'] = newDataData;
              _data = newDataMap;
            } else if (data['data'] is List) {
              // 새로운 구조: data가 List인 경우
              final newDataMap = Map<String, dynamic>.from(_data!);
              newDataMap['data'] = data['data'];
              _data = newDataMap;
            }
          }
          
          // summary 카드도 업데이트 (필요한 경우)
          if (data.containsKey('summary')) {
            final newDataMap = Map<String, dynamic>.from(_data!);
            newDataMap['summary'] = data['summary'];
            _data = newDataMap;
          }
          
          _isLoadingGastosDetail = false;
          
          // displayedItemsCount 업데이트
          if (_data!.containsKey('data')) {
            if (_data!['data'] is List) {
              final dataList = _data!['data'] as List;
              _displayedItemsCount = dataList.length > _itemsPerPage ? _itemsPerPage : dataList.length;
            } else if (_data!['data'] is Map) {
              final dataMap = _data!['data'] as Map<String, dynamic>;
              if (dataMap.containsKey('detail') && dataMap['detail'] is List) {
                final detailList = dataMap['detail'] as List;
                _displayedItemsCount = detailList.length > _itemsPerPage ? _itemsPerPage : detailList.length;
              }
            }
          }
          
          debugPrint('   → 오른쪽 패널만 업데이트 완료');
        });
      }
    } catch (e) {
      debugPrint('❌ Gastos Detail 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoadingGastosDetail = false;
        });
      }
    }
  }

  @override
  Future<void> _loadData({String? filteringWord}) async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [_loadData] 함수 호출');
    debugPrint('   → 파일: report_screen.dart');
    debugPrint('   → 라인: ${1659}');
    debugPrint('   → reportType: ${widget.reportType}');
    debugPrint('   → 파라미터 filteringWord: $filteringWord');
    debugPrint('   → _filteringWordController.text: "${_filteringWordController.text}"');
    debugPrint('   → _filteringWordController.text.trim(): "${_filteringWordController.text.trim()}"');
    debugPrint('   → _filteringWordController.text.isEmpty: ${_filteringWordController.text.isEmpty}');
    debugPrint('   → _filteringWordController.text.length: ${_filteringWordController.text.length}');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> data;
      
      switch (widget.reportType) {
        case ReportType.stocks:
          // 첫 페이지만 먼저 받아서 표시
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          final filters = <String, dynamic>{};
          if (_selectedTipoId != null) {
            filters['tipo_id'] = _selectedTipoId;
          }
          if (_selectedTemporadaId != null) {
            filters['temporada_id'] = _selectedTemporadaId;
          }
          if (_selectedStocksColorCode != null) {
            filters['color_id'] = _selectedStocksColorCode;
          }
          if (_selectedSucursal != null) {
            filters['sucursal'] = _selectedSucursal;
          }
          debugPrint('   → [Stocks] 전달할 filters: $filters');
          debugPrint('   → [Stocks] color_id: $_selectedStocksColorCode');
          debugPrint('   → [Stocks] sucursal: $_selectedSucursal');
          data = await _databaseService.getStocksReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            sortColumn: _stocksSortColumn,
            sortAscending: _stocksSortAscending,
            filters: filters.isNotEmpty ? filters : null,
          );
          
          // 디버깅: 응답 데이터 구조 확인
          print('📊 Stocks 응답 데이터 구조:');
          print('   - data 키 존재: ${data.containsKey('data')}');
          if (data.containsKey('data')) {
            final dataList = data['data'];
            print('   - data 타입: ${dataList.runtimeType}');
            if (dataList is List) {
              print('   - data 배열 길이: ${dataList.length}');
            }
          }
          print('   - filters 키 존재: ${data.containsKey('filters')}');
          print('   - summary 키 존재: ${data.containsKey('summary')}');
          print('   - pagination 키 존재: ${data.containsKey('pagination')}');
          
          // 페이지네이션 정보 저장
          if (data.containsKey('pagination') && data['pagination'] is Map) {
            final pagination = data['pagination'] as Map<String, dynamic>;
            _stocksHasMore = pagination['hasMore'] == true;
            _stocksNextMaxUtime = pagination['nextMaxUtime']?.toString();
            print('   - 페이지네이션: hasMore=$_stocksHasMore, nextMaxUtime=$_stocksNextMaxUtime');
          } else {
            print('   ⚠️ 페이지네이션 정보 없음');
          }
          break;
        case ReportType.items:
          // items 보고서는 항상 날짜 범위가 필요함 (기본값: 오늘부터 오늘까지)
          final now = DateTime.now();
          final startDate = _itemsStartDate ?? now;
          final endDate = _itemsEndDate ?? now;
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          
          // 날짜 범위 디버깅 로그
          debugPrint('📅 [Items Report] 날짜 범위 필터링:');
          debugPrint('   → _itemsStartDate: $_itemsStartDate');
          debugPrint('   → _itemsEndDate: $_itemsEndDate');
          debugPrint('   → 사용할 startDate: $startDate (${DateFormat('yyyy-MM-dd').format(startDate)})');
          debugPrint('   → 사용할 endDate: $endDate (${DateFormat('yyyy-MM-dd').format(endDate)})');
          
          final filters = <String, dynamic>{
            'fecha_inicio': DateFormat('yyyy-MM-dd').format(startDate),
            'fecha_fin': DateFormat('yyyy-MM-dd').format(endDate),
          };
          if (_selectedTipoId != null) {
            filters['tipo_id'] = _selectedTipoId;
          }
          if (_selectedTemporadaId != null) {
            filters['temporada_id'] = _selectedTemporadaId;
          }
          if (_selectedColorCode != null) {
            filters['color_id'] = _selectedColorCode;
          }
          if (_selectedSucursal != null) {
            filters['sucursal'] = _selectedSucursal;
          }
          
          debugPrint('   → 전달할 filters: $filters');
          debugPrint('   → filteringWord: ${currentFilteringWord.isNotEmpty ? currentFilteringWord : null}');
          debugPrint('   → color_id: $_selectedColorCode');
          debugPrint('   → sucursal: $_selectedSucursal');
          
          data = await _databaseService.getItemsReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            filters: filters,
          );
          
          debugPrint('   → API 응답 받음: ${data.containsKey('data') ? (data['data'] is List ? (data['data'] as List).length : (data['data'] is Map ? 'Map 구조' : '알 수 없음')) : 0}개 항목');
          break;
        case ReportType.clientes:
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [Clientes Report] _loadData 시작');
          debugPrint('   → 파라미터 filteringWord: $filteringWord');
          debugPrint('   → _filteringWordController.text: "${_filteringWordController.text}"');
          debugPrint('   → _filteringWordController.text.trim(): "${_filteringWordController.text.trim()}"');
          debugPrint('   → _filteringWordController.text.isEmpty: ${_filteringWordController.text.isEmpty}');
          debugPrint('   → _filteringWordController.text.length: ${_filteringWordController.text.length}');
          
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          debugPrint('   → currentFilteringWord: "$currentFilteringWord"');
          debugPrint('   → currentFilteringWord.isEmpty: ${currentFilteringWord.isEmpty}');
          debugPrint('   → currentFilteringWord.length: ${currentFilteringWord.length}');
          
          final filters = <String, dynamic>{};
          
          // 날짜 범위 필터 추가 (달력이 선택된 경우에만)
          if (_itemsStartDate != null && _itemsEndDate != null) {
            filters['fecha_inicio'] = DateFormat('yyyy-MM-dd').format(_itemsStartDate!);
            filters['fecha_fin'] = DateFormat('yyyy-MM-dd').format(_itemsEndDate!);
            debugPrint('   → 날짜 필터 추가: ${filters['fecha_inicio']} ~ ${filters['fecha_fin']}');
          } else {
            debugPrint('   → 날짜 필터 없음');
          }
          
          if (_clientesResponsableIns != null) {
            filters['responsable_ins'] = _clientesResponsableIns;
            debugPrint('   → responsable_ins 필터 추가: ${filters['responsable_ins']}');
          }
          if (_clientesProvincia != null) {
            filters['provincia'] = _clientesProvincia;
            debugPrint('   → provincia 필터 추가: ${filters['provincia']}');
          }
          if (_clientesDeudores) {
            filters['deudores'] = '1';
            debugPrint('   → deudores 필터 추가');
          }
          if (_clientesReservadores) {
            filters['reservadores'] = '1';
            debugPrint('   → reservadores 필터 추가');
          }
          if (_selectedSucursal != null) {
            filters['sucursal'] = _selectedSucursal;
            debugPrint('   → sucursal 필터 추가: ${filters['sucursal']}');
          }
          if (currentFilteringWord.isNotEmpty) {
            filters['filtering_word'] = currentFilteringWord;
            debugPrint('   → filtering_word 필터 추가: "${filters['filtering_word']}"');
          } else {
            debugPrint('   → filtering_word 필터 없음 (비어있음)');
          }
          
          debugPrint('   → 최종 filters: $filters');
          debugPrint('═══════════════════════════════════════════════════════');
          
          // 정렬 파라미터 추가
          if (_clientesSortColumn != null) {
            filters['sort_column'] = _clientesSortColumn;
            filters['sort_ascending'] = _clientesSortAscending ? '1' : '0';
          }
          
          // 첫 페이지 로드: offset을 0으로 리셋
          _clientesOffset = 0;
          data = await _databaseService.getClientesReport(
            filters: filters.isNotEmpty ? filters : null,
            limit: 200,
            offset: 0,
          );
          
          // 페이지네이션 정보 확인
          if (data.containsKey('data') && data['data'] is List) {
            final dataList = data['data'] as List;
            // 받은 데이터가 200개면 다음 페이지가 있을 수 있음
            _clientesHasMore = dataList.length >= 200;
            _clientesOffset = dataList.length;
            print('📄 Clientes 첫 페이지 로드: ${dataList.length}개 항목, hasMore=$_clientesHasMore');
          } else {
            _clientesHasMore = false;
            _clientesOffset = 0;
          }
          break;
        case ReportType.gastos:
          // gastos 보고서는 날짜 범위 필터 사용 (기본값: 오늘부터 오늘까지)
          final now = DateTime.now();
          final startDate = _itemsStartDate ?? now;
          final endDate = _itemsEndDate ?? now;
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          
          final filters = <String, dynamic>{
            'fecha_inicio': DateFormat('yyyy-MM-dd').format(startDate),
            'fecha_fin': DateFormat('yyyy-MM-dd').format(endDate),
          };
          if (_selectedSucursal != null) {
            filters['sucursal'] = _selectedSucursal;
          }
          debugPrint('🔍 [ReportScreen] Gastos API 요청 시작');
          debugPrint('   → rubroCode: null (전체 데이터 로드)');
          debugPrint('   → filteringWord: ${currentFilteringWord.isNotEmpty ? currentFilteringWord : null}');
          debugPrint('   → fecha_inicio: ${filters['fecha_inicio']}');
          debugPrint('   → fecha_fin: ${filters['fecha_fin']}');
          debugPrint('   → sucursal: $_selectedSucursal');
          // 첫 로드 시 전체 데이터를 가져옴 (summary_by_rubro 포함)
          data = await _databaseService.getGastosReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            rubroCode: null, // 첫 로드 시 전체 데이터
            filters: filters,
          );
          debugPrint('🔍 [ReportScreen] Gastos API 응답 받음');
          debugPrint('   → 데이터 키: ${data.keys.toList()}');
          if (data.containsKey('data') && data['data'] is List) {
            debugPrint('   → data 개수: ${(data['data'] as List).length}');
          }
          break;
        case ReportType.ventas:
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [report_screen.dart:1957] [_loadData] ReportType.ventas 케이스 실행 시작');
          debugPrint('   → 라인: 1957');
          debugPrint('   → 호출 스택:');
          debugPrint('      ${StackTrace.current.toString().split("\n").take(5).join("\n      ")}');
          debugPrint('   → [report_screen.dart:1962] 현재 _ventasUnit: $_ventasUnit');
          debugPrint('   → [report_screen.dart:1963] _ventasUnit 타입: ${_ventasUnit.runtimeType}');
          debugPrint('   → [report_screen.dart:1964] _ventasUnit == "day": ${_ventasUnit == "day"}');
          debugPrint('   → [report_screen.dart:1965] _ventasUnit == "month": ${_ventasUnit == "month"}');
          debugPrint('   → [report_screen.dart:1966] _ventasUnit == "year": ${_ventasUnit == "year"}');
          debugPrint('   → [report_screen.dart:1967] _ventasUnit == "vcode": ${_ventasUnit == "vcode"}');
          debugPrint('   → [report_screen.dart:1968] _isLoading: $_isLoading');
          debugPrint('   → [report_screen.dart:1969] _data != null: ${_data != null}');
          if (_data != null && _data!.containsKey('data') && _data!['data'] is List) {
            final dataList = _data!['data'] as List;
            if (dataList.isNotEmpty && dataList.first is Map<String, dynamic>) {
              final firstItem = dataList.first as Map<String, dynamic>;
              final hasVcodeField = firstItem.containsKey('vcode');
              final hasFechaField = firstItem.containsKey('fecha');
              final hasMonthField = firstItem.containsKey('month');
              final hasYearField = firstItem.containsKey('year');
              debugPrint('   → [report_screen.dart:1970] 현재 _data 구조:');
              debugPrint('      → hasVcodeField: $hasVcodeField');
              debugPrint('      → hasFechaField: $hasFechaField');
              debugPrint('      → hasMonthField: $hasMonthField');
              debugPrint('      → hasYearField: $hasYearField');
            }
          }
          debugPrint('═══════════════════════════════════════════════════════');
          
          // current_date 사용 (기본값: 오늘)
          final now = DateTime.now();
          var startDate = _ventasStartDate ?? now;
          var endDate = _ventasEndDate ?? now;
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          
          debugPrint('      - 초기 날짜 범위: startDate=$startDate, endDate=$endDate');
          debugPrint('      - 필터링 단어: $currentFilteringWord');
          
          // month unit일 때 날짜 범위를 정확히 설정
          if (_ventasUnit == 'month') {
            debugPrint('      - month unit 감지: 날짜 범위를 월 단위로 조정');
            // 시작 날짜: 해당 월의 1일
            startDate = DateTime(startDate.year, startDate.month, 1);
            // 종료 날짜: 해당 월의 마지막 날 (다음 달의 0일 = 이번 달의 마지막 날)
            endDate = DateTime(endDate.year, endDate.month + 1, 0);
            debugPrint('      - 조정된 날짜 범위: startDate=$startDate, endDate=$endDate');
          }
          // year unit일 때 날짜 범위를 정확히 설정
          else if (_ventasUnit == 'year') {
            debugPrint('      - year unit 감지: 날짜 범위를 연 단위로 조정');
            // 시작 날짜: 해당 연도의 1월 1일
            startDate = DateTime(startDate.year, 1, 1);
            // 종료 날짜: 해당 연도의 12월 31일
            endDate = DateTime(endDate.year, 12, 31);
            debugPrint('      - 조정된 날짜 범위: startDate=$startDate, endDate=$endDate');
          } else {
            debugPrint('      - vcode/day unit: 날짜 범위 유지');
          }
          
          // current_date는 startDate를 사용 (또는 endDate, 사용자 요구사항에 따라)
          final currentDate = DateFormat('yyyy-MM-dd').format(startDate);
          
          final filters = <String, dynamic>{
            'fecha_inicio': DateFormat('yyyy-MM-dd').format(startDate),
            'fecha_fin': DateFormat('yyyy-MM-dd').format(endDate),
          };
          
          // 체크박스 필터 추가
          if (_ventasDescontado) {
            filters['descontado'] = '1';
          }
          if (_ventasReservado) {
            filters['reservado'] = '1';
          }
          if (_ventasCredito) {
            filters['credito'] = '1';
          }
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [Ventas _loadData] movidos 필터 확인');
          debugPrint('   → _ventasMovidos: $_ventasMovidos');
          debugPrint('   → _ventasMovidos 타입: ${_ventasMovidos.runtimeType}');
          if (_ventasMovidos) {
            filters['movidos'] = '1';
            debugPrint('   → movidos 필터 추가됨: filters["movidos"] = "1"');
          } else {
            debugPrint('   → movidos 필터 추가 안 됨 (_ventasMovidos가 false)');
            // movidos가 false일 때는 필터에서 제거 (명시적으로)
            filters.remove('movidos');
          }
          debugPrint('   → 최종 filters: $filters');
          debugPrint('═══════════════════════════════════════════════════════');
          if (_selectedSucursal != null) {
            filters['sucursal'] = _selectedSucursal;
          }
          
          debugPrint('      - API 요청 파라미터:');
          debugPrint('         * currentDate: $currentDate');
          debugPrint('         * fecha_inicio: ${filters['fecha_inicio']}');
          debugPrint('         * fecha_fin: ${filters['fecha_fin']}');
          debugPrint('         * filteringWord: $currentFilteringWord');
          debugPrint('         * unit: $_ventasUnit');
          debugPrint('         * descontado: $_ventasDescontado');
          debugPrint('         * reservado: $_ventasReservado');
          debugPrint('         * credito: $_ventasCredito');
          debugPrint('         * movidos: $_ventasMovidos');
          debugPrint('         * sucursal: $_selectedSucursal');
          
          debugPrint('      → [report_screen.dart:2044] getVentasReport API 호출 시작');
          debugPrint('      → [report_screen.dart:2048] API 호출 시 전달할 unit: $_ventasUnit');
          print('🔵🔵🔵 [report_screen.dart:2068] API 호출 직전 _ventasUnit: $_ventasUnit');
          debugPrint('🔵🔵🔵 [report_screen.dart:2068] API 호출 직전 _ventasUnit: $_ventasUnit');
          data = await _databaseService.getVentasReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            currentDate: currentDate,
            unit: _ventasUnit,
            filters: filters,
          );
          print('🔵🔵🔵 [report_screen.dart:2074] API 호출 완료 직후 _ventasUnit: $_ventasUnit');
          debugPrint('🔵🔵🔵 [report_screen.dart:2074] API 호출 완료 직후 _ventasUnit: $_ventasUnit');
          print('🔵🔵🔵 [report_screen.dart:2076] setState 호출 직전 _ventasUnit: $_ventasUnit');
          debugPrint('🔵🔵🔵 [report_screen.dart:2076] setState 호출 직전 _ventasUnit: $_ventasUnit');
          debugPrint('      → [report_screen.dart:2051] getVentasReport API 호출 완료');
          debugPrint('      → [report_screen.dart:2051] API 응답 후 _ventasUnit: $_ventasUnit');
          debugPrint('      - 응답 데이터 타입: ${data.runtimeType}');
          debugPrint('      - 응답 데이터 키: ${data.keys.toList()}');
          if (data.containsKey('data') && data['data'] is List) {
            final dataList = data['data'] as List;
            debugPrint('      - 응답 데이터 개수: ${dataList.length}');
          }
          break;
        case ReportType.fventas:
          // current_date 사용 (기본값: 오늘)
          final now = DateTime.now();
          var startDate = _ventasStartDate ?? now;
          var endDate = _ventasEndDate ?? now;
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          
          print('📅 FVentas 보고서 - 초기 날짜 상태:');
          print('  - _ventasStartDate: $_ventasStartDate');
          print('  - _ventasEndDate: $_ventasEndDate');
          print('  - startDate (사용할 값): $startDate');
          print('  - endDate (사용할 값): $endDate');
          print('  - unit: $_ventasUnit');
          
          // month unit일 때 날짜 범위를 정확히 설정
          if (_ventasUnit == 'month') {
            // 시작 날짜: 해당 월의 1일
            startDate = DateTime(startDate.year, startDate.month, 1);
            // 종료 날짜: 해당 월의 마지막 날 (다음 달의 0일 = 이번 달의 마지막 날)
            endDate = DateTime(endDate.year, endDate.month + 1, 0);
            print('  - month unit 적용 후: startDate=$startDate, endDate=$endDate');
          }
          // year unit일 때 날짜 범위를 정확히 설정
          else if (_ventasUnit == 'year') {
            // 시작 날짜: 시작 연도의 1월 1일
            final startYear = startDate.year;
            startDate = DateTime(startYear, 1, 1);
            // 종료 날짜: 종료 연도의 12월 31일
            final endYear = endDate.year;
            endDate = DateTime(endYear, 12, 31);
            print('  - year unit 적용 후: startDate=$startDate, endDate=$endDate');
            // 연도 범위가 여러 연도에 걸쳐 있으면, 각 연도별로 1월 1일~12월 31일 범위를 보장
            // (서버가 unit=year일 때 자동으로 연도별 그룹화하므로, fecha_inicio와 fecha_fin만 정확히 설정하면 됨)
          }
          
          // fecha_inicio와 fecha_fin만 사용 (currentDate는 전달하지 않음 - 단일 날짜 필터링 방지)
          final filters = <String, dynamic>{
            'fecha_inicio': DateFormat('yyyy-MM-dd').format(startDate),
            'fecha_fin': DateFormat('yyyy-MM-dd').format(endDate),
          };
          if (_selectedSucursal != null) {
            filters['sucursal'] = _selectedSucursal;
          }
          print('📅 FVentas 보고서 요청 - 최종 날짜 범위: ${filters['fecha_inicio']} ~ ${filters['fecha_fin']}, filteringWord: $currentFilteringWord, unit: $_ventasUnit, sucursal: $_selectedSucursal');
          // fventas 보고서의 filteringWord는 클라이언트 측에서만 필터링 (cuit, cliente 필드)
          // 서버로 전달하지 않음
          data = await _databaseService.getFVentasReport(
            filteringWord: null, // 서버로 전달하지 않음 (클라이언트 측에서만 필터링)
            currentDate: null, // currentDate를 null로 설정하여 fecha 파라미터가 추가되지 않도록 함
            unit: _ventasUnit,
            filters: filters,
          );
          
          // fventas 데이터 디버깅
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('🔍 [FVentas Report] API 응답 데이터 확인');
          debugPrint('   → data 타입: ${data.runtimeType}');
          debugPrint('   → data 키: ${data.keys.toList()}');
          if (data.containsKey('data') && data['data'] is List) {
            final dataList = data['data'] as List;
            debugPrint('   → data[\'data\'] 타입: List, 길이: ${dataList.length}');
            if (dataList.isNotEmpty) {
              debugPrint('   → 첫 번째 항목: ${dataList.first}');
              if (dataList.first is Map<String, dynamic>) {
                final firstItem = dataList.first as Map<String, dynamic>;
                debugPrint('   → 첫 번째 항목 키: ${firstItem.keys.toList()}');
                debugPrint('   → 첫 번째 항목 샘플: fecha=${firstItem['fecha']}, numfactura=${firstItem['numfactura']}, tipofactura=${firstItem['tipofactura']}');
              }
            } else {
              debugPrint('   ⚠️ data[\'data\']가 비어있습니다!');
            }
          } else {
            debugPrint('   ⚠️ data[\'data\']가 없거나 List가 아닙니다!');
            debugPrint('   → data[\'data\']: ${data['data']}');
          }
          if (data.containsKey('pagination') && data['pagination'] is Map) {
            final pagination = data['pagination'] as Map<String, dynamic>;
            debugPrint('   → pagination 정보:');
            debugPrint('      - count: ${pagination['count']}');
            debugPrint('      - total: ${pagination['total']}');
            debugPrint('      - hasMore: ${pagination['hasMore']}');
            debugPrint('      - offset: ${pagination['offset']}');
            debugPrint('      - limit: ${pagination['limit']}');
          } else {
            debugPrint('   ⚠️ pagination 정보가 없습니다.');
          }
          debugPrint('═══════════════════════════════════════════════════════');
          break;
        case ReportType.alertas:
          // alertas 보고서는 날짜 범위 필터 사용 (기본값: 오늘부터 오늘까지)
          final now = DateTime.now();
          final startDate = _itemsStartDate ?? now;
          final endDate = _itemsEndDate ?? now;
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          
          final filters = <String, dynamic>{
            'fecha_inicio': DateFormat('yyyy-MM-dd').format(startDate),
            'fecha_fin': DateFormat('yyyy-MM-dd').format(endDate),
          };
          if (_selectedSucursal != null) {
            filters['sucursal'] = _selectedSucursal;
          }
          debugPrint('   → [Alertas] 전달할 filters: $filters');
          debugPrint('   → [Alertas] sucursal: $_selectedSucursal');
          // VCancelado 필터는 filteringWord를 통해 처리 (서버 필터 제거)
          data = await _databaseService.getAlertasReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            filters: filters,
          );
          break;
        case ReportType.ingresos:
          // ingresos 보고서는 날짜 범위 필터 사용 (기본값: 오늘부터 오늘까지)
          final now = DateTime.now();
          final startDate = _itemsStartDate ?? now;
          final endDate = _itemsEndDate ?? now;
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          
          final filters = <String, dynamic>{
            'fecha_inicio': DateFormat('yyyy-MM-dd').format(startDate),
            'fecha_fin': DateFormat('yyyy-MM-dd').format(endDate),
          };
          if (_selectedTipoId != null) {
            filters['tipo_id'] = _selectedTipoId;
          }
          if (_selectedTemporadaId != null) {
            filters['temporada_id'] = _selectedTemporadaId;
          }
          if (_selectedIngresosColorCode != null) {
            filters['color_id'] = _selectedIngresosColorCode;
          }
          if (_selectedSucursal != null) {
            filters['sucursal'] = _selectedSucursal;
          }
          if (_ingresosMovidos) {
            filters['movidos'] = '1';
          }
          debugPrint('   → [Ingresos] 전달할 filters: $filters');
          debugPrint('   → [Ingresos] color_id: $_selectedIngresosColorCode');
          debugPrint('   → [Ingresos] sucursal: $_selectedSucursal');
          debugPrint('   → [Ingresos] movidos: $_ingresosMovidos');
          data = await _databaseService.getIngresosReport(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            filters: filters,
          );
          break;
        case ReportType.codigos:
          // 첫 페이지만 먼저 받아서 표시
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          print('🔍 Codigos 요청 - filteringWord: "$currentFilteringWord"');
          final filters = <String, dynamic>{};
          if (_selectedTipoId != null) {
            filters['tipo_id'] = _selectedTipoId;
          }
          if (_selectedTemporadaId != null) {
            filters['temporada_id'] = _selectedTemporadaId;
          }
          if (_selectedCodigosColorCode != null) {
            filters['color_id'] = _selectedCodigosColorCode;
          }
          if (_selectedSucursal != null) {
            filters['sucursal'] = _selectedSucursal;
          }
          if (_codigosSoloBorrados) {
            filters['borrado'] = '1';
          } else {
            filters['borrado'] = '0';
          }
          debugPrint('   → [Codigos] 전달할 filters: $filters');
          debugPrint('   → [Codigos] color_id: $_selectedCodigosColorCode');
          debugPrint('   → [Codigos] sucursal: $_selectedSucursal');
          data = await _databaseService.getCodigos(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            sortColumn: _codigosSortColumn,
            sortAscending: _codigosSortAscending,
            filters: filters.isNotEmpty ? filters : null,
          );
          // 페이지네이션 정보 저장
          // pagination.id_codigo가 있으면 다음 페이지가 있다고 판단
          if (data.containsKey('pagination') && data['pagination'] is Map) {
            final pagination = data['pagination'] as Map<String, dynamic>;
            // pagination.id_codigo가 있으면 다음 페이지가 있음
            if (pagination.containsKey('id_codigo') && pagination['id_codigo'] != null) {
              _codigosNextIdCodigo = pagination['id_codigo']?.toString();
              _codigosHasMore = true;
              print('📄 다음 페이지 id_codigo: $_codigosNextIdCodigo');
            } else {
              _codigosNextIdCodigo = null;
              _codigosHasMore = false;
              print('ℹ️ 마지막 페이지입니다.');
            }
          } else {
            _codigosNextIdCodigo = null;
            _codigosHasMore = false;
          }
          
          // id_codigo가 포함되어 있는지 확인
          if (data.containsKey('data') && data['data'] is List) {
            final dataList = data['data'] as List;
            if (dataList.isNotEmpty) {
              final firstItem = dataList[0] as Map<String, dynamic>;
              print('📋 첫 번째 Codigo 항목 확인:');
              print('   - codigo: ${firstItem['codigo']}');
              print('   - id_codigo: ${firstItem['id_codigo']}');
              if (firstItem.containsKey('id_codigo')) {
                print('✅ id_codigo 필드가 서버 응답에 포함되어 있습니다!');
              } else {
                print('⚠️ id_codigo 필드가 서버 응답에 없습니다.');
              }
            }
          }
          break;
        case ReportType.todocodigos:
          // Todo Codigos - todocodigos 엔드포인트 사용
          print('🔍 Todo Codigos 요청');
          final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
          final filters = <String, dynamic>{};
          if (_selectedTipoId != null) {
            filters['tipo_id'] = _selectedTipoId;
          }
          if (_selectedTemporadaId != null) {
            filters['temporada_id'] = _selectedTemporadaId;
          }
          if (_selectedSucursal != null) {
            filters['sucursal'] = _selectedSucursal;
          }
          if (_codigosSoloBorrados) {
            filters['borrado'] = '1';
          } else {
            filters['borrado'] = '0';
          }
          debugPrint('   → [TodoCodigos] 전달할 filters: $filters');
          debugPrint('   → [TodoCodigos] sucursal: $_selectedSucursal');
          data = await _databaseService.getTodocodigos(
            filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
            sortColumn: _codigosSortColumn,
            sortAscending: _codigosSortAscending,
            filters: filters.isNotEmpty ? filters : null,
          );
          // 페이지네이션 정보 저장
          if (data.containsKey('pagination') && data['pagination'] is Map) {
            final pagination = data['pagination'] as Map<String, dynamic>;
            if (pagination.containsKey('id_todocodigo') && pagination['id_todocodigo'] != null) {
              _codigosNextIdCodigo = pagination['id_todocodigo']?.toString();
              _codigosHasMore = true;
              print('📄 다음 페이지 id_todocodigo: $_codigosNextIdCodigo');
            } else {
              _codigosNextIdCodigo = null;
              _codigosHasMore = false;
              print('ℹ️ 마지막 페이지입니다.');
            }
          } else {
            _codigosNextIdCodigo = null;
            _codigosHasMore = false;
          }
          break;
      }

      // 데이터에서 sucursal 목록 추출
      List<String>? sucursales;
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔍 [Ventas Sucursal 디버깅] sucursal 목록 추출 시작');
      debugPrint('   → reportType: ${widget.reportType}');
      debugPrint('   → data.containsKey("data"): ${data.containsKey('data')}');
      
      if (data.containsKey('data')) {
        debugPrint('   → data["data"] 타입: ${data['data'].runtimeType}');
        
        if (data['data'] is List) {
          final dataList = data['data'] as List;
          debugPrint('   → data["data"]는 List, 길이: ${dataList.length}');
          final sucursalSet = <String>{};
          
          for (var item in dataList) {
            if (item is Map<String, dynamic>) {
              debugPrint('   → 항목 키: ${item.keys.toList()}');
              if (item.containsKey('sucursal')) {
                final sucursal = item['sucursal']?.toString();
                debugPrint('   → sucursal 값: $sucursal (타입: ${item['sucursal'].runtimeType})');
                if (sucursal != null && sucursal.isNotEmpty) {
                  sucursalSet.add(sucursal);
                  debugPrint('   → sucursal 추가됨: $sucursal');
                } else {
                  debugPrint('   ⚠️ sucursal이 null이거나 비어있음');
                }
              } else {
                debugPrint('   ⚠️ 항목에 "sucursal" 키가 없음');
              }
            } else {
              debugPrint('   ⚠️ 항목이 Map이 아님: ${item.runtimeType}');
            }
          }
          
          debugPrint('   → 추출된 sucursalSet: $sucursalSet');
          debugPrint('   → sucursalSet.isEmpty: ${sucursalSet.isEmpty}');
          
          if (sucursalSet.isNotEmpty) {
            sucursales = sucursalSet.toList()..sort((a, b) {
              final aNum = int.tryParse(a) ?? 0;
              final bNum = int.tryParse(b) ?? 0;
              return aNum.compareTo(bNum);
            });
            debugPrint('   → 정렬된 sucursales: $sucursales');
          } else {
            debugPrint('   ⚠️ sucursalSet이 비어있어서 sucursales = null');
          }
        } else if (data['data'] is Map) {
          debugPrint('   → data["data"]는 Map');
          // gastos 보고서처럼 data가 Map인 경우
          final dataMap = data['data'] as Map<String, dynamic>;
          debugPrint('   → dataMap 키: ${dataMap.keys.toList()}');
          
          if (dataMap.containsKey('detail') && dataMap['detail'] is List) {
            final detailList = dataMap['detail'] as List;
            debugPrint('   → detailList 길이: ${detailList.length}');
            final sucursalSet = <String>{};
            
            for (var item in detailList) {
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
          } else {
            debugPrint('   ⚠️ dataMap에 "detail" 키가 없거나 List가 아님');
          }
        } else {
          debugPrint('   ⚠️ data["data"]가 List도 Map도 아님: ${data['data'].runtimeType}');
        }
      } else {
        debugPrint('   ⚠️ data에 "data" 키가 없음');
      }
      
      debugPrint('   → 최종 sucursales: $sucursales');
      debugPrint('   → sucursales == null: ${sucursales == null}');
      if (sucursales != null) {
        debugPrint('   → sucursales.length: ${sucursales.length}');
        debugPrint('   → sucursales.length > 1: ${sucursales.length > 1}');
      }
      debugPrint('═══════════════════════════════════════════════════════');

      debugPrint('   → 데이터 로딩 완료');
      debugPrint('   - 데이터 타입: ${data.runtimeType}');
      debugPrint('   - 데이터 키: ${data.keys.toList()}');
      if (data.containsKey('data') && data['data'] is List) {
        final dataList = data['data'] as List;
        debugPrint('   - 응답 데이터 개수: ${dataList.length}');
      }
      // Items 보고서의 경우 CompanyResumen, CategoryResumen 확인
      if (widget.reportType == ReportType.items) {
        debugPrint('   - Items 보고서 데이터 구조 확인:');
        if (data.containsKey('CompanyResumen')) {
          debugPrint('     → CompanyResumen 존재: ${data['CompanyResumen']}');
        }
        if (data.containsKey('CategoryResumen')) {
          debugPrint('     → CategoryResumen 존재: ${data['CategoryResumen']}');
        }
        if (data.containsKey('company_resumen')) {
          debugPrint('     → company_resumen 존재: ${data['company_resumen']}');
        }
        if (data.containsKey('category_resumen')) {
          debugPrint('     → category_resumen 존재: ${data['category_resumen']}');
        }
      }
      // 페이지네이션 정보 확인
      if (data.containsKey('pagination') && data['pagination'] is Map) {
        final pagination = data['pagination'] as Map<String, dynamic>;
        debugPrint('   - 페이지네이션 정보: $pagination');
        if (widget.reportType == ReportType.gastos) {
          debugPrint('   ⚠️ Gastos 보고서에 페이지네이션 정보가 있습니다!');
          debugPrint('      → 현재 페이지네이션 처리 없음');
        }
      }
      debugPrint('   - 사용 가능한 sucursales: $sucursales');

      setState(() {
        // Gastos 보고서의 경우 원본 데이터 저장 (summary_by_rubro 유지용)
        if (widget.reportType == ReportType.gastos && 
            data.containsKey('summary_by_rubro') && 
            _selectedRubroCode == null) {
          // rubro가 선택되지 않은 첫 로드 시 원본 데이터 저장
          _originalGastosData = Map<String, dynamic>.from(data);
          debugPrint('🔍 [ReportScreen] 원본 Gastos 데이터 저장 (summary_by_rubro 포함)');
        }
        
        _data = data;
        _isLoading = false;
        
        // Items, Ingresos, Gastos 보고서의 경우 데이터에서 sucursal 목록 추출
        // 단, 필터링되지 않은 전체 데이터에서만 추출 (sucursal 필터가 없을 때만)
        List<String>? extractedSucursales = sucursales;
        if (widget.reportType == ReportType.items || 
            widget.reportType == ReportType.ingresos || 
            widget.reportType == ReportType.gastos) {
          debugPrint('🔍 [Items/Ingresos/Gastos] 데이터에서 sucursal 목록 추출 시작');
          debugPrint('   → reportType: ${widget.reportType}');
          debugPrint('   → _selectedSucursal: $_selectedSucursal');
          debugPrint('   → _availableSucursales (현재): $_availableSucursales');
          
          // sucursal 필터가 없거나, 아직 _availableSucursales가 설정되지 않은 경우에만 추출
          // 이미 _availableSucursales가 있으면 유지 (필터링된 결과에서 추출하지 않음)
          if (_selectedSucursal == null && (_availableSucursales == null || _availableSucursales!.isEmpty)) {
            debugPrint('   → sucursal 필터 없음 또는 목록 미설정 - 추출 진행');
            final Set<String> sucursalSet = <String>{};
            
            if (widget.reportType == ReportType.items || widget.reportType == ReportType.ingresos) {
              // Items와 Ingresos: products 리스트에서 추출
              if (data.containsKey('data') && data['data'] is Map) {
                final dataMap = data['data'] as Map<String, dynamic>;
                if (dataMap.containsKey('products') && dataMap['products'] is List) {
                  final productsList = dataMap['products'] as List;
                  debugPrint('   → productsList.length: ${productsList.length}');
                  
                  for (var product in productsList) {
                    if (product is Map<String, dynamic> && product.containsKey('sucursal')) {
                      final sucursal = product['sucursal']?.toString();
                      if (sucursal != null && sucursal.isNotEmpty) {
                        sucursalSet.add(sucursal);
                      }
                    }
                  }
                }
              }
            } else if (widget.reportType == ReportType.gastos) {
              // Gastos: detail 또는 data 리스트에서 추출
              if (data.containsKey('data')) {
                if (data['data'] is Map) {
                  final dataMap = data['data'] as Map<String, dynamic>;
                  if (dataMap.containsKey('detail') && dataMap['detail'] is List) {
                    final detailList = dataMap['detail'] as List;
                    debugPrint('   → detailList.length: ${detailList.length}');
                    
                    for (var item in detailList) {
                      if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
                        final sucursal = item['sucursal']?.toString();
                        if (sucursal != null && sucursal.isNotEmpty) {
                          sucursalSet.add(sucursal);
                        }
                      }
                    }
                  }
                } else if (data['data'] is List) {
                  final dataList = data['data'] as List;
                  debugPrint('   → dataList.length: ${dataList.length}');
                  
                  for (var item in dataList) {
                    if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
                      final sucursal = item['sucursal']?.toString();
                      if (sucursal != null && sucursal.isNotEmpty) {
                        sucursalSet.add(sucursal);
                      }
                    }
                  }
                }
              }
            }
            
            extractedSucursales = sucursalSet.toList()..sort();
            debugPrint('   → 추출된 sucursales: $extractedSucursales');
          } else {
            debugPrint('   → sucursal 필터 있음 또는 목록 이미 설정됨 - 기존 목록 유지');
            debugPrint('   → _availableSucursales 유지: $_availableSucursales');
            extractedSucursales = _availableSucursales; // 기존 목록 유지
          }
        }
        
        // resumen del dia에서 전달된 initialAvailableSucursales가 있으면 항상 그것을 사용
        // (API 응답에서 추출한 목록이 더 많아도 덮어쓰지 않음)
        if (widget.initialAvailableSucursales != null && widget.initialAvailableSucursales!.isNotEmpty) {
          _availableSucursales = widget.initialAvailableSucursales;
          debugPrint('🔍 [Sucursal] resumen del dia에서 전달된 목록으로 설정 (API 응답 무시)');
        } else {
          _availableSucursales = extractedSucursales;
        }
        
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🔍 [Sucursal 디버깅] setState에서 _availableSucursales 설정');
        debugPrint('   → reportType: ${widget.reportType}');
        debugPrint('   → initialAvailableSucursales: ${widget.initialAvailableSucursales}');
        debugPrint('   → sucursales (API): $sucursales');
        debugPrint('   → extractedSucursales: $extractedSucursales');
        debugPrint('   → _availableSucursales (최종): $_availableSucursales');
        debugPrint('   → _availableSucursales == null: ${_availableSucursales == null}');
        debugPrint('   → _selectedSucursal (현재): $_selectedSucursal');
        if (_availableSucursales != null) {
          debugPrint('   → _availableSucursales.length: ${_availableSucursales!.length}');
          debugPrint('   → _availableSucursales.length > 1: ${_availableSucursales!.length > 1}');
          debugPrint('   → _availableSucursales 내용: ${_availableSucursales!.join(", ")}');
          
          // 선택된 sucursal이 목록에 포함되어 있는지 확인
          if (_selectedSucursal != null) {
            final isSelectedSucursalInList = _availableSucursales!.contains(_selectedSucursal);
            debugPrint('   → 선택된 sucursal ($_selectedSucursal)이 목록에 포함되어 있는가: $isSelectedSucursalInList');
            
            // 선택된 sucursal이 목록에 없으면 추가
            if (!isSelectedSucursalInList) {
              debugPrint('   ⚠️ 선택된 sucursal ($_selectedSucursal)이 목록에 없어서 추가합니다.');
              _availableSucursales!.add(_selectedSucursal!);
              _availableSucursales!.sort((a, b) {
                final aNum = int.tryParse(a) ?? 0;
                final bNum = int.tryParse(b) ?? 0;
                return aNum.compareTo(bNum);
              });
              debugPrint('   → 업데이트된 _availableSucursales: ${_availableSucursales!.join(", ")}');
            }
          }
        }
        debugPrint('═══════════════════════════════════════════════════════');
        
        // 성능 최적화: 데이터 변경 시 합계 계산 캐시 무효화
        ReportTotalRowBuilder.clearCache();
        // sucursal이 1개 이하이면 필터 초기화 (단, 선택된 sucursal이 있으면 유지)
        if (_availableSucursales == null || (_availableSucursales!.length <= 1 && _selectedSucursal == null)) {
          if (_selectedSucursal != null) {
            debugPrint('🔍 [Sucursal 디버깅] sucursal이 1개 이하이지만 선택된 값이 있어서 유지: $_selectedSucursal');
          } else {
            _selectedSucursal = null;
            debugPrint('🔍 [Sucursal 디버깅] sucursal이 1개 이하이므로 _selectedSucursal = null');
          }
        }
        // 데이터가 로드되면 처음 100개만 표시
        if (data.containsKey('data')) {
          if (data['data'] is List) {
            final dataList = data['data'] as List;
            _displayedItemsCount = dataList.length > _itemsPerPage ? _itemsPerPage : dataList.length;
          } else if (data['data'] is Map) {
            final dataMap = data['data'] as Map<String, dynamic>;
            if (dataMap.containsKey('detail') && dataMap['detail'] is List) {
              final detailList = dataMap['detail'] as List;
              _displayedItemsCount = detailList.length > _itemsPerPage ? _itemsPerPage : detailList.length;
            } else {
              _displayedItemsCount = 100;
            }
          } else {
            _displayedItemsCount = 100;
          }
        } else {
          _displayedItemsCount = 100;
        }
        print('🔵🔵🔵 [report_screen.dart:2593] _loadData setState 호출 직전');
        print('   → 라인: 2593');
        if (widget.reportType == ReportType.ventas) {
          print('   → _ventasUnit: $_ventasUnit');
          print('   → 호출 스택 (처음 5줄):');
          print('      ${StackTrace.current.toString().split("\n").take(5).join("\n      ")}');
        }
        debugPrint('   → [report_screen.dart:2593] setState: _data 업데이트, _isLoading=false, _displayedItemsCount=$_displayedItemsCount');
        print('🔵🔵🔵 [report_screen.dart:2593] setState 내부 진입 - _ventasUnit: $_ventasUnit');
        debugPrint('🔵🔵🔵 [report_screen.dart:2593] setState 내부 진입 - _ventasUnit: $_ventasUnit');
        if (widget.reportType == ReportType.ventas) {
          debugPrint('   → [report_screen.dart:2594] [Ventas] setState 내부 _ventasUnit 확인');
          debugPrint('      → [report_screen.dart:2596] _ventasUnit: $_ventasUnit');
          debugPrint('      → [report_screen.dart:2597] _ventasUnit 타입: ${_ventasUnit.runtimeType}');
          debugPrint('      → [report_screen.dart:2598] _ventasUnit == "day": ${_ventasUnit == "day"}');
          debugPrint('      → [report_screen.dart:2599] _ventasUnit == "month": ${_ventasUnit == "month"}');
          debugPrint('      → [report_screen.dart:2600] _ventasUnit == "year": ${_ventasUnit == "year"}');
          debugPrint('      → [report_screen.dart:2601] _ventasUnit == "vcode": ${_ventasUnit == "vcode"}');
          print('🔵🔵🔵 [report_screen.dart:2601] setState 내부 _ventasUnit 최종 확인: $_ventasUnit');
          debugPrint('🔵🔵🔵 [report_screen.dart:2601] setState 내부 _ventasUnit 최종 확인: $_ventasUnit');
        }
      });
      
      debugPrint('📊 [report_screen.dart:2626] _loadData() 완료');
      if (widget.reportType == ReportType.ventas) {
        debugPrint('   → [report_screen.dart:2627] [Ventas] _loadData 완료 후 _ventasUnit 확인');
        debugPrint('      → [report_screen.dart:2629] _ventasUnit: $_ventasUnit');
        debugPrint('      → [report_screen.dart:2630] _ventasUnit 타입: ${_ventasUnit.runtimeType}');
        debugPrint('      → [report_screen.dart:2631] _ventasUnit == "day": ${_ventasUnit == "day"}');
        debugPrint('      → [report_screen.dart:2632] _ventasUnit == "month": ${_ventasUnit == "month"}');
        debugPrint('      → [report_screen.dart:2633] _ventasUnit == "year": ${_ventasUnit == "year"}');
        debugPrint('      → [report_screen.dart:2634] _ventasUnit == "vcode": ${_ventasUnit == "vcode"}');
      }
      debugPrint('═══════════════════════════════════════════════════════');
    } catch (e) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('❌ _loadData() 오류 발생');
      debugPrint('   - 오류 타입: ${e.runtimeType}');
      debugPrint('   - 오류 메시지: $e');
      debugPrint('   - 스택 트레이스: ${StackTrace.current}');
      
        String errorMessage = 'Ocurrió un error desconocido.';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      debugPrint('   - 처리된 오류 메시지: $errorMessage');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = errorMessage;
          debugPrint('   → setState: _isLoading=false, _errorMessage=$errorMessage');
        });
      }
      debugPrint('❌ _loadData() 오류 처리 완료');
      debugPrint('═══════════════════════════════════════════════════════');
    }
  }

  // Codigos 다음 페이지 로드 (스크롤 기반)
  Future<void> _loadNextCodigosPage() async {
    if (widget.reportType != ReportType.codigos && widget.reportType != ReportType.todocodigos) return;
    if (!_codigosHasMore || _codigosNextIdCodigo == null) return;
    if (_isLoadingMoreCodigos) return; // 이미 로딩 중이면 중복 요청 방지
    
    setState(() {
      _isLoadingMoreCodigos = true;
    });
    
    try {
      final filteringWord = _filteringWordController.text.trim();
      Map<String, dynamic> response;
      
      final filters = <String, dynamic>{};
      if (_selectedTipoId != null) {
        filters['tipo_id'] = _selectedTipoId;
      }
      if (_selectedTemporadaId != null) {
        filters['temporada_id'] = _selectedTemporadaId;
      }
      if (_selectedCodigosColorCode != null) {
        filters['color_id'] = _selectedCodigosColorCode;
      }
      if (_codigosSoloBorrados) {
        filters['borrado'] = '1';
      } else {
        filters['borrado'] = '0';
      }

      if (widget.reportType == ReportType.todocodigos) {
        print('📄 다음 Todocodigos 페이지 로드 중... (id_todocodigo=$_codigosNextIdCodigo)');
        response = await _databaseService.getTodocodigos(
          idTodocodigo: _codigosNextIdCodigo,
          filteringWord: filteringWord.isNotEmpty ? filteringWord : null,
          sortColumn: _codigosSortColumn,
          sortAscending: _codigosSortAscending,
          filters: filters.isNotEmpty ? filters : null,
        );
      } else {
        print('📄 다음 Codigos 페이지 로드 중... (id_codigo=$_codigosNextIdCodigo)');
        response = await _databaseService.getCodigos(
          idCodigo: _codigosNextIdCodigo,
          filteringWord: filteringWord.isNotEmpty ? filteringWord : null,
          sortColumn: _codigosSortColumn,
          sortAscending: _codigosSortAscending,
          filters: filters.isNotEmpty ? filters : null,
        );
      }
      
      // 새 데이터 추가
      if (response.containsKey('data') && response['data'] is List) {
        final newData = response['data'] as List;
        if (newData.isNotEmpty && _data != null && _data!.containsKey('data')) {
          final currentData = _data!['data'] as List;
          setState(() {
            _data = {
              ..._data!,
              'data': [...currentData, ...newData],
            };
          });
          print('✅ 다음 페이지 로드됨: ${newData.length}개 항목 (총 ${currentData.length + newData.length}개)');
        }
      }
      
      // 페이지네이션 정보 업데이트
      if (response.containsKey('pagination') && response['pagination'] is Map) {
        final pagination = response['pagination'] as Map<String, dynamic>;
        
        if (widget.reportType == ReportType.todocodigos) {
          // Todocodigos: pagination.id_todocodigo 사용
          if (pagination.containsKey('id_todocodigo') && pagination['id_todocodigo'] != null) {
            _codigosNextIdCodigo = pagination['id_todocodigo']?.toString();
            _codigosHasMore = true;
            print('📄 다음 페이지 id_todocodigo: $_codigosNextIdCodigo');
          } else {
            _codigosNextIdCodigo = null;
            _codigosHasMore = false;
            print('ℹ️ 모든 Todocodigos 페이지 로드 완료');
          }
        } else {
          // Codigos: pagination.id_codigo 사용
          if (pagination.containsKey('id_codigo') && pagination['id_codigo'] != null) {
            _codigosNextIdCodigo = pagination['id_codigo']?.toString();
            _codigosHasMore = true;
            print('📄 다음 페이지 id_codigo: $_codigosNextIdCodigo');
          } else {
            _codigosNextIdCodigo = null;
            _codigosHasMore = false;
            print('ℹ️ 모든 Codigos 페이지 로드 완료');
          }
        }
      } else {
        _codigosNextIdCodigo = null;
        _codigosHasMore = false;
      }
    } catch (e) {
      print('❌ 다음 페이지 로드 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreCodigos = false;
        });
      }
    }
  }

  // Stocks 다음 페이지 로드 (스크롤 기반)
  Future<void> _loadNextStocksPage() async {
    if (widget.reportType != ReportType.stocks) return;
    if (!_stocksHasMore || _stocksNextMaxUtime == null) return;
    if (_isLoadingMoreStocks) return; // 이미 로딩 중이면 중복 요청 방지
    
    setState(() {
      _isLoadingMoreStocks = true;
    });
    
    try {
      print('📄 다음 Stocks 페이지 로드 중... (max_utime=$_stocksNextMaxUtime)');
      final filteringWord = _filteringWordController.text.trim();
      final filters = <String, dynamic>{};
      if (_selectedTipoId != null) {
        filters['tipo_id'] = _selectedTipoId;
      }
      if (_selectedTemporadaId != null) {
        filters['temporada_id'] = _selectedTemporadaId;
      }
      if (_selectedStocksColorCode != null) {
        filters['color_id'] = _selectedStocksColorCode;
      }
      
      final response = await _databaseService.getStocksReport(
        filteringWord: filteringWord.isNotEmpty ? filteringWord : null,
        sortColumn: _stocksSortColumn,
        sortAscending: _stocksSortAscending,
        filters: filters.isNotEmpty ? filters : null,
      );
      
      // 새 데이터 추가
      if (response.containsKey('data') && response['data'] is List) {
        final newData = response['data'] as List;
        if (newData.isNotEmpty && _data != null && _data!.containsKey('data')) {
          final currentData = _data!['data'] as List;
          // filters와 summary 정보도 유지
          setState(() {
            _data = {
              ..._data!,
              'data': [...currentData, ...newData],
            };
          });
          print('✅ 다음 페이지 로드됨: ${newData.length}개 항목 (총 ${currentData.length + newData.length}개)');
        }
      }
      
      // 페이지네이션 정보 업데이트
      if (response.containsKey('pagination') && response['pagination'] is Map) {
        final pagination = response['pagination'] as Map<String, dynamic>;
        _stocksHasMore = pagination['hasMore'] == true;
        _stocksNextMaxUtime = pagination['nextMaxUtime']?.toString();
        
        if (!_stocksHasMore) {
          print('ℹ️ 모든 Stocks 페이지 로드 완료');
        }
      } else {
        _stocksHasMore = false;
      }
    } catch (e) {
      print('❌ 다음 페이지 로드 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreStocks = false;
        });
      }
    }
  }

  // Clientes 다음 페이지 로드 (스크롤 기반)
  Future<void> _loadNextClientesPage() async {
    if (widget.reportType != ReportType.clientes) return;
    if (!_clientesHasMore) return;
    if (_clientesIsLoadingMore) return; // 이미 로딩 중이면 중복 요청 방지
    
    setState(() {
      _clientesIsLoadingMore = true;
    });
    
    try {
      print('📄 다음 Clientes 페이지 로드 중... (offset=$_clientesOffset)');
      final currentFilteringWord = _filteringWordController.text.trim();
      final filters = <String, dynamic>{};
      
      // 날짜 범위 필터 추가 (달력이 선택된 경우에만)
      if (_itemsStartDate != null && _itemsEndDate != null) {
        filters['fecha_inicio'] = DateFormat('yyyy-MM-dd').format(_itemsStartDate!);
        filters['fecha_fin'] = DateFormat('yyyy-MM-dd').format(_itemsEndDate!);
      }
      
      if (_clientesResponsableIns != null) {
        filters['responsable_ins'] = _clientesResponsableIns;
      }
      if (_clientesProvincia != null) {
        filters['provincia'] = _clientesProvincia;
      }
      if (_clientesDeudores) {
        filters['deudores'] = '1';
      }
      if (_clientesReservadores) {
        filters['reservadores'] = '1';
      }
      if (currentFilteringWord.isNotEmpty) {
        filters['filtering_word'] = currentFilteringWord;
      }
      
      // 정렬 파라미터 추가
      if (_clientesSortColumn != null) {
        filters['sort_column'] = _clientesSortColumn;
        filters['sort_ascending'] = _clientesSortAscending ? '1' : '0';
      }
      
      final response = await _databaseService.getClientesReport(
        filters: filters.isNotEmpty ? filters : null,
        limit: 200,
        offset: _clientesOffset,
      );
      
      // 새 데이터 추가
      if (response.containsKey('data') && response['data'] is List) {
        final newData = response['data'] as List;
        if (newData.isNotEmpty && _data != null && _data!.containsKey('data')) {
          final currentData = _data!['data'] as List;
          setState(() {
            _data = {
              ..._data!,
              'data': [...currentData, ...newData],
            };
            // 성능 최적화: 데이터 변경 시 합계 계산 캐시 무효화
            ReportTotalRowBuilder.clearCache();
          });
          print('✅ 다음 페이지 로드됨: ${newData.length}개 항목 (총 ${currentData.length + newData.length}개)');
          
          // 페이지네이션 정보 업데이트
          // 받은 데이터가 200개 미만이면 마지막 페이지
          _clientesHasMore = newData.length >= 200;
          _clientesOffset += newData.length;
          
          if (!_clientesHasMore) {
            print('ℹ️ 모든 Clientes 페이지 로드 완료');
          }
        } else {
          _clientesHasMore = false;
        }
      } else {
        _clientesHasMore = false;
      }
    } catch (e) {
      print('❌ 다음 페이지 로드 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _clientesIsLoadingMore = false;
        });
      }
    }
  }

  // 스크롤 이벤트 처리 (무한 스크롤)
  void _onScroll() {
    if (widget.reportType == ReportType.codigos || widget.reportType == ReportType.todocodigos) {
      // Codigos의 경우 스크롤이 80% 이상 내려갔을 때 다음 페이지 로드
      if (_scrollController.hasClients && 
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        _loadNextCodigosPage();
      }
    } else if (widget.reportType == ReportType.stocks) {
      // Stocks의 경우 스크롤이 80% 이상 내려갔을 때 다음 페이지 로드
      if (_scrollController.hasClients && 
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        _loadNextStocksPage();
      }
    } else if (widget.reportType == ReportType.clientes) {
      // Clientes의 경우 아래쪽 50개 남았을 때 다음 페이지 로드 (약 75% 지점)
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        // 아래쪽 50개 남았을 때 = 전체 높이의 약 75% 지점
        if (currentScroll >= maxScroll * 0.75) {
          _loadNextClientesPage();
        }
      }
    } else {
      // 다른 보고서의 경우 기존 로직 사용
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        _loadMoreItems();
      }
    }
  }

  // 더 많은 항목 로드
  @override
  void _loadMoreItems() {
    if (_data == null) return;
    
    if (_data!.containsKey('data') && _data!['data'] is List) {
      final dataList = _data!['data'] as List;
      if (_displayedItemsCount < dataList.length) {
        setState(() {
          _displayedItemsCount = (_displayedItemsCount + _itemsPerPage).clamp(0, dataList.length);
        });
      }
    }
  }

  /// 접속된 DB 이름 로드 (제목 옆 { dbname } 표시용)
  Future<void> _loadConnectedDatabaseName() async {
    final name = await SecureStorageHelper.read('database_name');
    if (mounted) {
      setState(() => _connectedDatabaseName = name?.trim().isNotEmpty == true ? name : null);
    }
  }
}
