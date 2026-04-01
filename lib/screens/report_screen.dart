import 'package:flutter/material.dart';
import '../widgets/report_utils.dart';
import '../services/secure_storage_helper.dart';
import 'report_screen_legacy.dart';
import 'reports/stocks_report_view.dart';

export '../widgets/report_utils.dart' show ReportType;

/// 보고서 화면 진입점: 라우팅 + 공통 AppBar만 담당하고, 본문은 타입별 뷰로 위임.
/// - Stocks: [StocksReportView] (분리된 화면/로직)
/// - 그 외: [ReportScreenLegacy] (기존 단일 대형 화면, 추후 타입별 분리 예정)
class ReportScreen extends StatefulWidget {
  final String serverUrl;
  final ReportType reportType;
  final DateTime? initialDate;
  final DateTime? initialItemsStartDate;
  final DateTime? initialItemsEndDate;
  final String? initialFilteringWord;
  final String? initialSortColumn;
  final bool? initialSortAscending;
  final bool? initialVentasDescontado;
  final Function(String?, String?, bool?)? onStateChanged;
  final Function(DateTime?, DateTime?)? onItemsDateRangeChanged;
  final bool useFullWidth;
  final VoidCallback? onMenuPressed;
  final List<String>? initialAvailableSucursales;

  const ReportScreen({
    super.key,
    required this.serverUrl,
    required this.reportType,
    this.initialDate,
    this.initialItemsStartDate,
    this.initialItemsEndDate,
    this.initialFilteringWord,
    this.initialSortColumn,
    this.initialSortAscending,
    this.initialVentasDescontado,
    this.onStateChanged,
    this.onItemsDateRangeChanged,
    this.useFullWidth = false,
    this.onMenuPressed,
    this.initialAvailableSucursales,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  /// 현재 본문(뷰)에서 등록한 공유 콜백. 공통 AppBar의 Share 버튼에서 호출.
  void Function()? _currentShare;
  /// 접속된 DB 이름 (제목 옆 { } 표시용)
  String? _connectedDatabaseName;
  /// Stocks 보고서용: AppBar 하단에 표시할 필터 바 (tipos, temporada, filtering word)
  Widget? _stocksAppBarFilterBar;
  /// Stocks 보고서용: bcolorview 상태에 따른 AppBar 색상
  Color? _stocksAppBarColor;

  @override
  void initState() {
    super.initState();
    _loadConnectedDatabaseName();
  }

  Future<void> _loadConnectedDatabaseName() async {
    final name = await SecureStorageHelper.read('database_name');
    if (mounted) {
      setState(() => _connectedDatabaseName = name?.trim().isNotEmpty == true ? name : null);
    }
  }

  String _titleWithDb(String baseTitle) {
    final db = _connectedDatabaseName ?? '';
    return db.isEmpty ? '$baseTitle { }' : '$baseTitle { $db }';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reportType == ReportType.stocks) {
      return _buildStocksShell();
    }
    return ReportScreenLegacy(
      serverUrl: widget.serverUrl,
      reportType: widget.reportType,
      initialDate: widget.initialDate,
      initialItemsStartDate: widget.initialItemsStartDate,
      initialItemsEndDate: widget.initialItemsEndDate,
      initialFilteringWord: widget.initialFilteringWord,
      initialSortColumn: widget.initialSortColumn,
      initialSortAscending: widget.initialSortAscending,
      initialVentasDescontado: widget.initialVentasDescontado,
      onStateChanged: widget.onStateChanged,
      onItemsDateRangeChanged: widget.onItemsDateRangeChanged,
      useFullWidth: widget.useFullWidth,
      onMenuPressed: widget.onMenuPressed,
      initialAvailableSucursales: widget.initialAvailableSucursales,
      onSwitchReport: (ReportType type) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReportScreen(
              serverUrl: widget.serverUrl,
              reportType: type,
              initialDate: widget.initialDate,
              initialItemsStartDate: widget.initialItemsStartDate,
              initialItemsEndDate: widget.initialItemsEndDate,
              initialFilteringWord: widget.initialFilteringWord,
              initialSortColumn: widget.initialSortColumn,
              initialSortAscending: widget.initialSortAscending,
              onStateChanged: widget.onStateChanged,
              onItemsDateRangeChanged: widget.onItemsDateRangeChanged,
              useFullWidth: widget.useFullWidth,
              onMenuPressed: widget.onMenuPressed,
              initialAvailableSucursales: widget.initialAvailableSucursales,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStocksShell() {
    final baseTitle = ReportUtils.getReportTitle(ReportType.stocks);
    final reportTitle = _titleWithDb(baseTitle);
    final reportIcon = ReportUtils.getReportIcon(ReportType.stocks);
    final reportColor = _stocksAppBarColor ?? ReportUtils.getReportColor(ReportType.stocks);
    final isLargeScreen = MediaQuery.of(context).size.width >= 800;
    final showFilterInOneLine = isLargeScreen && _stocksAppBarFilterBar != null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: widget.useFullWidth && widget.onMenuPressed != null
            ? IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: widget.onMenuPressed,
                tooltip: 'Menú',
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
        title: Row(
          children: [
            Icon(reportIcon, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                reportTitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            if (showFilterInOneLine) ...[
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _stocksAppBarFilterBar!,
              ),
            ],
          ],
        ),
        backgroundColor: reportColor,
        bottom: !showFilterInOneLine && _stocksAppBarFilterBar != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Material(
                  color: reportColor.withOpacity(0.15),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: _stocksAppBarFilterBar!,
                  ),
                ),
              )
            : null,
        actions: [
          PopupMenuButton<ReportType>(
            icon: const Icon(Icons.assessment, color: Colors.white),
            tooltip: 'Reportes',
            onSelected: (ReportType reportType) {
              if (reportType != widget.reportType) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportScreen(
                      serverUrl: widget.serverUrl,
                      reportType: reportType,
                      initialDate: widget.initialDate,
                      initialItemsStartDate: widget.initialItemsStartDate,
                      initialItemsEndDate: widget.initialItemsEndDate,
                      initialFilteringWord: widget.initialFilteringWord,
                      initialSortColumn: widget.initialSortColumn,
                      initialSortAscending: widget.initialSortAscending,
                      onStateChanged: widget.onStateChanged,
                      onItemsDateRangeChanged: widget.onItemsDateRangeChanged,
                      useFullWidth: widget.useFullWidth,
                      onMenuPressed: widget.onMenuPressed,
                      initialAvailableSucursales: widget.initialAvailableSucursales,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => _buildReportMenuItems(reportColor),
          ),
          if (_currentShare != null)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              tooltip: 'Compartir como PDF',
              onPressed: _currentShare,
            ),
        ],
      ),
      body: StocksReportView(
        serverUrl: widget.serverUrl,
        initialFilteringWord: widget.initialFilteringWord,
        initialSortColumn: widget.initialSortColumn,
        initialSortAscending: widget.initialSortAscending,
        onStateChanged: widget.onStateChanged,
        useFullWidth: widget.useFullWidth,
        onMenuPressed: widget.onMenuPressed,
        initialAvailableSucursales: widget.initialAvailableSucursales,
        registerShare: (void Function() shareFn) {
          setState(() => _currentShare = shareFn);
        },
        onFilterBarReady: (Widget filterBar) {
          if (mounted) setState(() => _stocksAppBarFilterBar = filterBar);
        },
        onAppBarColorChanged: (Color color) {
          if (mounted) setState(() => _stocksAppBarColor = color);
        },
      ),
    );
  }

  List<PopupMenuEntry<ReportType>> _buildReportMenuItems(Color reportColor) {
    final types = [
      ReportType.ventas,
      ReportType.fventas,
      ReportType.stocks,
      ReportType.codigos,
      ReportType.todocodigos,
      ReportType.items,
      ReportType.ingresos,
      ReportType.gastos,
      ReportType.clientes,
      ReportType.alertas,
    ];
    return types.map((ReportType type) {
      final isSelected = widget.reportType == type;
      return PopupMenuItem<ReportType>(
        value: type,
        child: Row(
          children: [
            Icon(ReportUtils.getReportIcon(type), color: isSelected ? ReportUtils.getReportColor(type) : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Text(
              ReportUtils.getReportTitle(type),
              style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(Icons.check, color: ReportUtils.getReportColor(type), size: 18),
            ],
          ],
        ),
      );
    }).toList();
  }
}
