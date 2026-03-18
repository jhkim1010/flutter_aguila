part of '../report_screen_legacy.dart';

mixin ClientesReportMixin on _ReportScreenStateBase {
  /// Cliente 행 탭 핸들러 - cliente 상세 정보 보기 (모달리스 대화상자)
  void _handleClienteRowTap(Map<String, dynamic> rowData) async {
    if (widget.reportType != ReportType.clientes) return;

    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🔍 [Cliente 행 더블클릭] 이벤트 감지');
    debugPrint('→ reportType: ${widget.reportType}');
    debugPrint('→ rowData keys: ${rowData.keys.toList()}');
    debugPrint('→ _clienteDetailOverlayEntry: ${_clienteDetailOverlayEntry != null ? "존재함" : "null"}');
    debugPrint('→ _currentClienteDetailData: ${_currentClienteDetailData != null ? "존재함" : "null"}');
    debugPrint('→ mounted: $mounted');
    debugPrint('═══════════════════════════════════════════════════════════');

    // dni 추출 (다양한 필드명 시도)
    final dni = rowData['dni'] ??
                rowData['DNI'] ??
                rowData['Dni'];

    if (dni == null) {
      debugPrint('❌ [_handleClienteRowTap] dni 필드를 찾을 수 없습니다.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DNI 정보를 찾을 수 없습니다.')),
        );
      }
      return;
    }

    // 이미 같은 cliente의 overlay가 열려있으면 닫기
    if (_clienteDetailOverlayEntry != null) {
      final currentDni = _currentClienteRowData?['dni'] ??
                         _currentClienteRowData?['DNI'] ??
                         _currentClienteRowData?['Dni'];
      if (currentDni?.toString() == dni.toString()) {
        debugPrint('→ 같은 Cliente overlay 클릭 - 닫기');
        _closeClienteDetailOverlay();
        return;
      }
      // 다른 cliente이면 기존 overlay 닫고 새로 열기
      _closeClienteDetailOverlay();
    }

    // 로딩 상태로 overlay 먼저 표시
    _currentClienteRowData = rowData;
    _currentClienteDetailData = null;
    _showClienteDetailOverlay({}, rowData);

    try {
      debugPrint('→ Cliente 상세 정보 요청 시작: dni=$dni');
      final clienteDetailData = await _databaseService.getClienteDetail(
        cuit: dni.toString(),
      );

      debugPrint('→ Cliente 상세 정보 응답 받음');

      if (mounted) {
        _currentClienteDetailData = clienteDetailData;
        _updateClienteDetailOverlay();
      }
    } catch (e) {
      debugPrint('❌ Cliente 상세 정보 요청 실패: $e');
      if (mounted) {
        _closeClienteDetailOverlay();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cliente 상세 정보를 가져오는 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  /// 모달리스 Cliente 상세 정보 대화상자 표시
  void _showClienteDetailOverlay(Map<String, dynamic> clienteDetailData, Map<String, dynamic> rowData) {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📋 [_showClienteDetailOverlay] 모달리스 대화상자 생성 시작');
    debugPrint('→ mounted: $mounted');

    if (!mounted) {
      debugPrint('❌ [_showClienteDetailOverlay] mounted=false, 종료');
      return;
    }

    final overlayState = Overlay.of(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWideScreen = screenWidth >= 800;
    final reportColor = _getReportColor();

    debugPrint('→ screenWidth: $screenWidth');
    debugPrint('→ screenHeight: $screenHeight');
    debugPrint('→ isWideScreen: $isWideScreen');

    final dialogWidth = isWideScreen ? screenWidth * 2 / 3 : screenWidth;
    final dialogHeight = isWideScreen ? screenHeight * 0.9 : screenHeight;

    debugPrint('→ dialogWidth: $dialogWidth');
    debugPrint('→ dialogHeight: $dialogHeight');

    _clienteDetailOverlayEntry = OverlayEntry(
      builder: (context) {
        debugPrint('🔨 [OverlayEntry builder] 빌드 시작');
        debugPrint('→ isWideScreen: $isWideScreen');
        debugPrint('→ dialogWidth: $dialogWidth');
        debugPrint('→ dialogHeight: $dialogHeight');

        Widget dialogWidget = Material(
          color: Colors.transparent,
          child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: isWideScreen ? BorderRadius.circular(8) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: reportColor,
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
                        'Detalle del Cliente',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            tooltip: 'Compartir (PDF/Excel)',
                            onPressed: () {
                              if (_currentClienteDetailData != null) {
                                _shareClienteDetail(_currentClienteDetailData!);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: _closeClienteDetailOverlay,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _currentClienteDetailData == null || _currentClienteRowData == null
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: _buildClienteDetailContent(_currentClienteDetailData!, _currentClienteRowData!),
                        ),
                ),
              ],
            ),
          ),
        );

        if (isWideScreen) {
          return Positioned(
            right: 16,
            top: 16,
            width: dialogWidth,
            height: dialogHeight,
            child: IgnorePointer(
              ignoring: false,
              child: dialogWidget,
            ),
          );
        } else {
          return Positioned.fill(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeClienteDetailOverlay,
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
                Center(
                  child: dialogWidget,
                ),
              ],
            ),
          );
        }
      },
    );

    debugPrint('📋 [_showClienteDetailOverlay] OverlayEntry 생성 완료, Overlay에 삽입 시작');
    overlayState.insert(_clienteDetailOverlayEntry!);
    debugPrint('✅ [_showClienteDetailOverlay] Overlay에 삽입 완료');

    if (mounted) {
      setState(() {
        // 상태 업데이트를 위한 빈 setState (onRowTap이 다시 평가되도록 함)
      });
    }

    debugPrint('═══════════════════════════════════════════════════════════');
  }

  /// 모달리스 Cliente 상세 정보 대화상자 업데이트
  void _updateClienteDetailOverlay() {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📋 [_updateClienteDetailOverlay] 대화상자 업데이트 시작');
    debugPrint('→ _clienteDetailOverlayEntry: ${_clienteDetailOverlayEntry != null ? "존재함" : "null"}');
    debugPrint('→ mounted: $mounted');
    debugPrint('→ _currentClienteDetailData: ${_currentClienteDetailData != null ? "존재함" : "null"}');
    debugPrint('→ _currentClienteRowData: ${_currentClienteRowData != null ? "존재함" : "null"}');

    if (_clienteDetailOverlayEntry == null || !mounted || _currentClienteDetailData == null || _currentClienteRowData == null) {
      debugPrint('❌ [_updateClienteDetailOverlay] 조건 불만족으로 종료');
      debugPrint('═══════════════════════════════════════════════════════════');
      return;
    }

    debugPrint('📋 [_updateClienteDetailOverlay] 기존 OverlayEntry 제거 및 새로 생성');
    final oldEntry = _clienteDetailOverlayEntry!;
    _showClienteDetailOverlay(_currentClienteDetailData!, _currentClienteRowData!);
    oldEntry.remove();
    debugPrint('✅ [_updateClienteDetailOverlay] 대화상자 업데이트 완료');
    debugPrint('═══════════════════════════════════════════════════════════');
  }

  /// Cliente 상세 정보를 표시하는 다이얼로그
  void _showClienteDetailDialog(Map<String, dynamic> clienteDetailData, Map<String, dynamic> rowData) {
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isWideScreen = screenWidth >= 800;
        final dialogWidth = isWideScreen ? screenWidth * 2 / 3 : screenWidth;
        final dialogHeight = isWideScreen ? screenHeight * 0.9 : screenHeight;
        final reportColor = _getReportColor();

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
                    color: reportColor,
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
                        'Detalle del Cliente',
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildClienteDetailContent(clienteDetailData, rowData),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClienteDetailContent(Map<String, dynamic> clienteDetailData, Map<String, dynamic> rowData) {
    final reportColor = _getReportColor();
    final cards = <Widget>[];

    // 1. Cliente 기본 정보 카드
    if (clienteDetailData.containsKey('cliente') && clienteDetailData['cliente'] is Map) {
      final cliente = clienteDetailData['cliente'] as Map<String, dynamic>;
      cards.add(_buildInfoCard(
        'Información del Cliente',
        {
          'DNI': cliente['dni']?.toString() ?? 'N/A',
          'Nombre': cliente['nombre']?.toString() ?? 'N/A',
          'Dirección': cliente['direccion']?.toString() ?? 'N/A',
          'Localidad': cliente['localidad']?.toString() ?? 'N/A',
          'Provincia': cliente['provincia']?.toString() ?? 'N/A',
          'Vendedor': cliente['vendedor']?.toString() ?? 'N/A',
          'Teléfono': cliente['telefono']?.toString() ?? 'N/A',
          'Email': cliente['email']?.toString() ?? 'N/A',
          'Transporte': cliente['transporte']?.toString() ?? 'N/A',
          'Deuda': ReportUtils.formatValue(cliente['deuda']),
          'Tipo': cliente['tipo']?.toString() ?? 'N/A',
          'Memo': cliente['memo']?.toString() ?? 'N/A',
        },
        reportColor: reportColor,
      ));
    }

    // 2. 구매 이력 요약 정보 카드
    if (clienteDetailData.containsKey('compra_historial')) {
      final compraHistorial = clienteDetailData['compra_historial'] as Map<String, dynamic>;

      if (compraHistorial.containsKey('summary') && compraHistorial['summary'] is Map) {
        final summary = compraHistorial['summary'] as Map<String, dynamic>;
        cards.add(_buildInfoCard(
          'Resumen de Compras',
          {
            'Total de Items': summary['total_items']?.toString() ?? 'N/A',
            'Unidad': summary['unit']?.toString() ?? 'N/A',
            'Función Usada': summary['function_used']?.toString() ?? 'N/A',
          },
          reportColor: reportColor,
        ));
      }

      if (compraHistorial.containsKey('filters') && compraHistorial['filters'] is Map) {
        final filters = compraHistorial['filters'] as Map<String, dynamic>;
        cards.add(_buildInfoCard(
          'Filtros Aplicados',
          {
            'Fecha Inicio': filters['fecha_inicio']?.toString() ?? 'N/A',
            'Fecha Fin': filters['fecha_fin']?.toString() ?? 'N/A',
            'Período (Días)': filters['period_days']?.toString() ?? 'N/A',
            'Período (Meses)': filters['period_months']?.toString() ?? 'N/A',
            'Período (Años)': filters['period_years']?.toString() ?? 'N/A',
          },
          reportColor: reportColor,
        ));
      }

      // 3. 구매 이력 데이터 테이블
      if (compraHistorial.containsKey('data') && compraHistorial['data'] is List) {
        final compraData = compraHistorial['data'] as List;
        if (compraData.isNotEmpty) {
          cards.add(_buildCompraHistorialTable(compraData, reportColor));
        }
      }
    }

    if (cards.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 800;

    if (isWideScreen && cards.length > 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: cards.where((card) => card != cards.last).toList(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: cards.last,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cards,
    );
  }

  /// 구매 이력 테이블 빌드
  Widget _buildCompraHistorialTable(List<dynamic> compraData, Color reportColor) {
    if (compraData.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstItem = compraData.first;
    if (firstItem is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }

    final columns = [
      'vcode',
      'fecha',
      'tpago',
      'cntropas',
      'tefectivo',
      'tcredito',
      'tbanco',
      'treservado',
      'sucursal',
      'vendedor',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de Compras (${compraData.length} registros)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: reportColor,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: DataTable(
                  columnSpacing: 20,
                  dividerThickness: 0.0,
                  headingRowColor: WidgetStateProperty.all(reportColor.withOpacity(0.1)),
                  columns: columns.map((key) {
                    final labels = {
                      'vcode': 'Código',
                      'fecha': 'Fecha',
                      'tpago': 'Total Pago',
                      'cntropas': 'Cant. Ropas',
                      'tefectivo': 'Efectivo',
                      'tcredito': 'Crédito',
                      'tbanco': 'Banco',
                      'treservado': 'Reservado',
                      'sucursal': 'Sucursal',
                      'vendedor': 'Vendedor',
                    };
                    final isNumeric = ['tpago', 'cntropas', 'tefectivo', 'tcredito', 'tbanco', 'treservado', 'sucursal'].contains(key);
                    return DataColumn(
                      label: Text(
                        labels[key] ?? key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      numeric: isNumeric,
                    );
                  }).toList(),
                  rows: compraData.map((item) {
                    if (item is! Map<String, dynamic>) {
                      return DataRow(
                        cells: columns.map((_) => const DataCell(Text('N/A'))).toList(),
                      );
                    }
                    return DataRow(
                      cells: columns.map((key) {
                        final value = item[key];
                        final formattedValue = ReportUtils.formatValue(value);
                        final isNumeric = ['tpago', 'cntropas', 'tefectivo', 'tcredito', 'tbanco', 'treservado', 'sucursal'].contains(key);
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
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cliente 상세 정보 공유 (macOS/Windows: Excel, 기타: PDF)
  Future<void> _shareClienteDetail(Map<String, dynamic> clienteDetailData) async {
    if (Platform.isMacOS || Platform.isWindows) {
      _shareClienteDetailAsExcel(clienteDetailData);
    } else {
      _shareClienteDetailAsPdf(clienteDetailData);
    }
  }

  /// Cliente 상세 정보를 PDF로 변환하여 공유
  Future<void> _shareClienteDetailAsPdf(Map<String, dynamic> clienteDetailData) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      final cliente = clienteDetailData['cliente'] as Map<String, dynamic>?;
      final clienteNombre = cliente?['nombre']?.toString() ?? 'Cliente';

      final pdfFile = await PdfService.generateClienteDetailPdf(
        clienteDetailData: clienteDetailData,
        clienteNombre: clienteNombre,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!await pdfFile.exists()) {
        throw Exception('PDF 파일이 생성되지 않았습니다: ${pdfFile.path}');
      }

      print('📄 PDF 파일 생성 완료: ${pdfFile.path}');

      if (mounted) {
        await _sharePdfFile(pdfFile);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        Navigator.of(context).pop();
      }

      print('❌ PDF 생성/공유 오류: $e');
      print('❌ Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar/compartir PDF: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Cliente 상세 정보를 Excel로 변환하여 공유
  Future<void> _shareClienteDetailAsExcel(Map<String, dynamic> clienteDetailData) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando Excel...'),
                ],
              ),
            ),
          ),
        ),
      );

      final cliente = clienteDetailData['cliente'] as Map<String, dynamic>?;
      final clienteNombre = cliente?['nombre']?.toString() ?? 'Cliente';

      final excelFile = await ExcelService.generateClienteDetailExcel(
        clienteDetailData: clienteDetailData,
        clienteNombre: clienteNombre,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!await excelFile.exists()) {
        throw Exception('Excel 파일이 생성되지 않았습니다: ${excelFile.path}');
      }

      print('📊 Excel 파일 생성 완료: ${excelFile.path}');

      if (mounted) {
        await _shareExcelFile(excelFile);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        Navigator.of(context).pop();
      }

      print('❌ Excel 생성/공유 오류: $e');
      print('❌ Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar/compartir Excel: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
