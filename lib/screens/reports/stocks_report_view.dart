import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';
import '../../services/excel_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/report_utils.dart';
import '../../widgets/report_filters.dart';
import '../../widgets/report_filter_widgets.dart';
import '../../widgets/report_total_row_builder.dart';
import '../../widgets/stocks_builder.dart';
import '../../widgets/resizable_data_table.dart';
import '../../services/stocks_column_width_storage.dart';
import 'report_view_connector.dart';

/// Stocks 보고서 전용 화면/로직. ReportScreen(셸)에서 라우팅 시 사용.
class StocksReportView extends StatefulWidget {
  final String serverUrl;
  final String? initialFilteringWord;
  final String? initialSortColumn;
  final bool? initialSortAscending;
  final Function(String?, String?, bool?)? onStateChanged;
  final bool useFullWidth;
  final VoidCallback? onMenuPressed;
  final List<String>? initialAvailableSucursales;
  final RegisterShareCallback? registerShare;
  /// AppBar에 필터 바(tipos, temporada, filtering word)를 넣을 때 호출. ReportScreen이 전달.
  final void Function(Widget filterBar)? onFilterBarReady;
  /// 데이터 로드 후 bcolorview 상태에 따라 AppBar 색상 변경 콜백
  final void Function(Color color)? onAppBarColorChanged;

  const StocksReportView({
    super.key,
    required this.serverUrl,
    this.initialFilteringWord,
    this.initialSortColumn,
    this.initialSortAscending,
    this.onStateChanged,
    this.useFullWidth = false,
    this.onMenuPressed,
    this.initialAvailableSucursales,
    this.registerShare,
    this.onFilterBarReady,
    this.onAppBarColorChanged,
  });

  @override
  State<StocksReportView> createState() => _StocksReportViewState();
}

class _StocksReportViewState extends State<StocksReportView> {
  /// Stocks 칼럼 폭 저장소 키 — load()와 save() 양쪽에서 동일 값 참조
  static const String _stocksColumnWidthDbKey = '';

  late final DatabaseService _databaseService;
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _filteringWordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _tiposList = [];
  List<Map<String, dynamic>> _temporadasList = [];
  int? _selectedTipoId;
  int? _selectedTemporadaId;
  String? _stocksSortColumn = 'codigo';
  bool _stocksSortAscending = true;
  int _currentPage = 1;        // 현재 페이지 (1-based)
  int _pageSize = 100;         // 페이지 크기 (기본 100: 50/100/200 선택 가능)
  int _totalItems = 0;         // 서버 total (totalPages 계산용)
  String? _selectedSucursal;
  String? _selectedStocksColorCode;
  Map<String, double>? _stocksColumnWidths;
  /// bcolorview=1(resumido)일 때, 체크하면 bcolorview=0으로 서버 요청
  bool _verConColorYTalle = false;

  Color get _reportColor => ReportUtils.getReportColor(ReportType.stocks);

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService(serverUrl: widget.serverUrl);
    _filteringWordController.addListener(_onFilteringWordChangedDebounced);
    if (widget.initialFilteringWord != null && widget.initialFilteringWord!.isNotEmpty) {
      _filteringWordController.text = widget.initialFilteringWord!;
    }
    if (widget.initialSortColumn != null) {
      _stocksSortColumn = widget.initialSortColumn;
      _stocksSortAscending = widget.initialSortAscending ?? true;
    }
    _loadTiposAndTemporadas();
    _loadData();
    _loadColumnWidths(); // 칼럼 폭 초기 로딩 (1회만 실행)
  }

  Timer? _filteringWordDebounceTimer;
  void _onFilteringWordChangedDebounced() {
    _filteringWordDebounceTimer?.cancel();
    _filteringWordDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _reloadDataWithFilters();
      }
    });
  }

  @override
  void dispose() {
    _filteringWordDebounceTimer?.cancel();
    _databaseService.dispose();
    _filteringWordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 칼럼 폭 로딩 (initState에서 1회 호출, try-catch로 에러 처리)
  Future<void> _loadColumnWidths() async {
    try {
      final loaded = await StocksColumnWidthStorage.load(_stocksColumnWidthDbKey);
      if (mounted) {
        setState(() {
          _stocksColumnWidths = loaded;
        });
      }
    } catch (e) {
      // 칼럼 폭 로딩 실패 시 기본값 사용 (null fallback)
      print('⚠️ 칼럼 폭 로딩 실패: $e');
    }
  }

  Future<void> _loadTiposAndTemporadas() async {
    try {
      final tipos = await _databaseService.getTipos();
      final temporadas = await _databaseService.getTemporadas();
      if (mounted) {
        setState(() {
          _tiposList = tipos;
          _temporadasList = temporadas;
        });
      }
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadData({String? filteringWord}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final currentFilteringWord = filteringWord ?? _filteringWordController.text.trim();
      final filters = <String, dynamic>{};
      if (_selectedTipoId != null) filters['tipo_id'] = _selectedTipoId;
      if (_selectedTemporadaId != null) filters['temporada_id'] = _selectedTemporadaId;
      if (_selectedStocksColorCode != null) filters['color_id'] = _selectedStocksColorCode;
      if (_selectedSucursal != null) filters['sucursal'] = _selectedSucursal;
      // 체크박스 선택 시 bcolorview=0으로 서버에 요청
      if (_verConColorYTalle) filters['bcolorview'] = 0;

      final data = await _databaseService.getStocksReport(
        filteringWord: currentFilteringWord.isNotEmpty ? currentFilteringWord : null,
        sortColumn: _stocksSortColumn,
        sortAscending: _stocksSortAscending,
        filters: filters.isNotEmpty ? filters : null,
        offset: (_currentPage - 1) * _pageSize,
        limit: _pageSize,
      );
      if (data.containsKey('pagination') && data['pagination'] is Map) {
        final pagination = data['pagination'] as Map<String, dynamic>;
        _totalItems = pagination['total'] as int? ?? 0;
      }
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
        _notifyStateChanged();
        _notifyAppBarColor();
        if (_data != null && _data!.isNotEmpty) {
          widget.registerShare?.call(_shareReport);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reloadDataWithFilters() async {
    ReportTotalRowBuilder.clearCache();
    // 필터/정렬 변경 시 항상 첫 페이지로 (Pitfall 1 방지)
    _currentPage = 1;
    await _loadData();
  }

  /// 페이지네이션 컨트롤: 이전/다음 버튼 + 페이지 번호 + 페이지 크기 선택기 (D-04, D-05, D-06)
  Widget _buildPaginationControls() {
    final totalPages = (_totalItems / _pageSize).ceil().clamp(1, 99999);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 이전 페이지 버튼
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
          ),
          // 현재 페이지 / 전체 페이지 표시
          Text('$_currentPage / $totalPages'),
          // 다음 페이지 버튼
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages ? () => _goToPage(_currentPage + 1) : null,
          ),
          const SizedBox(width: 16),
          // 페이지 크기 선택기 (D-05: 50/100/200)
          DropdownButton<int>(
            value: _pageSize,
            items: [50, 100, 200].map((size) =>
              DropdownMenuItem(value: size, child: Text('$size'))
            ).toList(),
            onChanged: (size) {
              if (size != null) {
                setState(() {
                  _pageSize = size;
                  _currentPage = 1; // 크기 변경 시 첫 페이지로
                });
                _loadData();
              }
            },
          ),
        ],
      ),
    );
  }

  /// 지정 페이지로 이동 (스크롤 상단 복귀 포함)
  void _goToPage(int page) {
    setState(() => _currentPage = page);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _loadData();
  }

  /// bcolorview 상태에 따라 AppBar 색상 변경 알림
  void _notifyAppBarColor() {
    if (widget.onAppBarColorChanged == null || _data == null) return;
    final color = _isBcolorviewEnabled && !_verConColorYTalle
        ? Colors.orange
        : Colors.lightBlue;
    widget.onAppBarColorChanged!(color);
  }

  void _notifyStateChanged() {
    if (widget.onStateChanged != null) {
      widget.onStateChanged!(
        _filteringWordController.text.trim().isEmpty ? null : _filteringWordController.text.trim(),
        _stocksSortColumn,
        _stocksSortAscending,
      );
    }
  }

  Future<void> _shareReport() async {
    if (_data == null) return;
    // 웹: Platform API 사용 불가 — PDF 다운로드로 처리
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows)) {
      _shareAsExcel();
    } else {
      _shareAsPdf();
    }
  }

  Future<void> _shareAsPdf() async {
    if (_data == null) return;
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
      final filteringWord = _filteringWordController.text.trim();
      final pdfFile = await PdfService.generateReportPdf(
        reportType: ReportType.stocks,
        data: _data!,
        startDate: null,
        endDate: null,
        filteringWord: filteringWord.isEmpty ? null : filteringWord,
        displayedColumns: null,
      );
      if (mounted) Navigator.of(context).pop();
      // 웹: 브라우저 다운로드가 이미 완료됨 — 공유 다이얼로그 생략
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF descargado'), duration: Duration(seconds: 2)),
          );
        }
        return;
      }
      if (mounted) await Share.shareXFiles([XFile(pdfFile.path)]);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _shareAsExcel() async {
    if (_data == null) return;
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
      final filteringWord = _filteringWordController.text.trim();
      final excelFile = await ExcelService.generateReportExcel(
        reportType: ReportType.stocks,
        data: _data!,
        startDate: null,
        endDate: null,
        filteringWord: filteringWord.isEmpty ? null : filteringWord,
        displayedColumns: null,
      );
      if (mounted) Navigator.of(context).pop();
      // 웹: 브라우저 다운로드가 이미 완료됨 — 공유 다이얼로그 생략
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Excel descargado'), duration: Duration(seconds: 2)),
          );
        }
        return;
      }
      if (mounted) await Share.shareXFiles([XFile(excelFile.path)]);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildTipoSelector() {
    return ReportFilterWidgets.buildTipoSelector(
      tiposList: _tiposList,
      selectedTipoId: _selectedTipoId,
      onChanged: (int? value) {
        setState(() => _selectedTipoId = value);
        _loadData();
      },
      reportColor: _reportColor,
    );
  }

  Widget _buildTemporadaSelector() {
    return ReportFilterWidgets.buildTemporadaSelector(
      temporadasList: _temporadasList,
      selectedTemporadaId: _selectedTemporadaId,
      onChanged: (int? value) {
        setState(() => _selectedTemporadaId = value);
        _loadData();
      },
      reportColor: _reportColor,
    );
  }

  Widget _buildFilteringWordField() {
    return ReportFilters.buildFilteringWordField(
      controller: _filteringWordController,
      onSubmitted: (_) => _reloadDataWithFilters(),
      onClear: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _filteringWordController.clear();
        });
      },
      forLightBackground: true, // 본문은 밝은 배경이라 진한 글자/테두리로 보이게
    );
  }

  Widget _buildStocksViewType() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) return const SizedBox.shrink();
        Color stocksColor = Colors.orange;
        if (_data != null) {
          if (_data!.containsKey('filters') && _data!['filters'] is Map) {
            final filters = _data!['filters'] as Map<String, dynamic>;
            stocksColor = ReportUtils.isBcolorviewEnabled(filters['bcolorview']) ? Colors.orange : Colors.lightBlue;
          } else if (_data!.containsKey('bcolorview')) {
            stocksColor = ReportUtils.isBcolorviewEnabled(_data!['bcolorview']) ? Colors.orange : Colors.lightBlue;
          }
        }
        return StocksBuilder.buildViewType(
          data: _data,
          selectedSucursal: _selectedSucursal,
          onSucursalChanged: (value) => setState(() => _selectedSucursal = value),
          reportColor: stocksColor,
        );
      },
    );
  }

  Widget _buildStocksContent(Map<String, dynamic> data) {
    Color stocksColor = Colors.orange;
    if (data.containsKey('filters') && data['filters'] is Map) {
      final filters = data['filters'] as Map<String, dynamic>;
      stocksColor = ReportUtils.isBcolorviewEnabled(filters['bcolorview']) ? Colors.orange : Colors.lightBlue;
    } else if (data.containsKey('bcolorview')) {
      stocksColor = ReportUtils.isBcolorviewEnabled(data['bcolorview']) ? Colors.orange : Colors.lightBlue;
    }
    // 칼럼 폭은 initState → _loadColumnWidths()에서 1회 로딩. build에서 재로딩 없음.
    final defaults = {
      for (final col in StocksBuilder.buildColumnDefs()) col.key: col.defaultWidth
    };
    final mergedColumnWidths = Map<String, double>.from(defaults)
      ..addAll(_stocksColumnWidths ?? {});

    final dataList = data['data'] as List? ?? [];

    return ResizableDataTable(
      columns: StocksBuilder.buildColumnDefs(),
      rows: StocksBuilder.buildRows(dataList),
      columnWidths: mergedColumnWidths,
      onColumnResize: (key, newWidth) {
        setState(() {
          _stocksColumnWidths ??= {};
          _stocksColumnWidths![key] = newWidth;
        });
        StocksColumnWidthStorage.save(_stocksColumnWidthDbKey, _stocksColumnWidths!);
      },
      scrollController: _scrollController, // 세로 스크롤용 (페이지 내 스크롤)
      sortColumn: _stocksSortColumn,
      sortAscending: _stocksSortAscending,
      onSort: (column, ascending) {
        setState(() {
          _stocksSortColumn = column;
          _stocksSortAscending = ascending;
        });
        _notifyStateChanged();
        _reloadDataWithFilters();
      },
      headerColor: stocksColor,
      isLoadingMore: false,
      footerWidget: _buildPaginationControls(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _reportColor),
            const SizedBox(height: 16),
            Text(l10n.loadingData),
          ],
        ),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(l10n.errorOccurred, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadData(),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(backgroundColor: _reportColor, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    if (_data == null || _data!.isEmpty) {
      return Center(child: Text(l10n.noData));
    }
    // AppBar에 필터 바 전달 (post-frame으로 하여 setState during build 방지)
    if (widget.onFilterBarReady != null) {
      final filterBar = _buildAppBarFilterRow();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onFilterBarReady?.call(filterBar);
      });
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= 800;
        final showFilterBarInBody = widget.onFilterBarReady == null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showFilterBarInBody)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: _buildAppBarFilterRow(),
              ),
            if (!isLargeScreen) _buildStocksViewType(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadData(),
                child: RepaintBoundary(child: _buildStocksContent(_data!)),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 현재 데이터의 bcolorview가 1(resumido)인지 확인
  bool get _isBcolorviewEnabled {
    if (_data == null) return false;
    if (_data!.containsKey('filters') && _data!['filters'] is Map) {
      final filters = _data!['filters'] as Map<String, dynamic>;
      return ReportUtils.isBcolorviewEnabled(filters['bcolorview']);
    }
    if (_data!.containsKey('bcolorview')) {
      return ReportUtils.isBcolorviewEnabled(_data!['bcolorview']);
    }
    return false;
  }

  /// AppBar 하단에 표시할 필터 행 (tipos, temporada, filtering word). onFilterBarReady로 전달.
  Widget _buildAppBarFilterRow() {
    // bcolorview=1(resumido)이거나 이미 체크박스를 사용 중일 때 표시
    final showColorTalleCheckbox = _isBcolorviewEnabled || _verConColorYTalle;
    return Row(
      children: [
        if (_tiposList.length > 1) ...[
          Expanded(flex: 1, child: _buildTipoSelector()),
          const SizedBox(width: 8),
        ],
        if (_temporadasList.length > 1) ...[
          Expanded(flex: 1, child: _buildTemporadaSelector()),
          const SizedBox(width: 8),
        ],
        Expanded(flex: 2, child: _buildFilteringWordField()),
        if (showColorTalleCheckbox) ...[
          const SizedBox(width: 8),
          _buildColorTalleCheckbox(),
        ],
      ],
    );
  }

  /// "Ver con color y talle" 체크박스 위젯
  Widget _buildColorTalleCheckbox() {
    return InkWell(
      onTap: () {
        setState(() => _verConColorYTalle = !_verConColorYTalle);
        _reloadDataWithFilters();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _verConColorYTalle,
              onChanged: (value) {
                setState(() => _verConColorYTalle = value ?? false);
                _reloadDataWithFilters();
              },
              activeColor: Colors.white,
              checkColor: Colors.orange,
              side: const BorderSide(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Ver con color y talle',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
