import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';

enum ReportType {
  stocks,
  items,
  clientes,
  gastos,
  ventas,
  alertas,
}

class ReportScreen extends StatefulWidget {
  final String serverUrl;
  final ReportType reportType;

  const ReportScreen({
    super.key,
    required this.serverUrl,
    required this.reportType,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final DatabaseService _databaseService;
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService(serverUrl: widget.serverUrl);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> data;
      
      switch (widget.reportType) {
        case ReportType.stocks:
          data = await _databaseService.getStocksReport();
          break;
        case ReportType.items:
          data = await _databaseService.getItemsReport();
          break;
        case ReportType.clientes:
          data = await _databaseService.getClientesReport();
          break;
        case ReportType.gastos:
          data = await _databaseService.getGastosReport();
          break;
        case ReportType.ventas:
          data = await _databaseService.getVentasReport();
          break;
        case ReportType.alertas:
          data = await _databaseService.getAlertasReport();
          break;
      }

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      String errorMessage = '알 수 없는 오류가 발생했습니다.';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = errorMessage;
        });
      }
    }
  }

  String _getReportTitle() {
    switch (widget.reportType) {
      case ReportType.stocks:
        return 'Stocks';
      case ReportType.items:
        return 'Items';
      case ReportType.clientes:
        return 'Clientes';
      case ReportType.gastos:
        return 'Gastos';
      case ReportType.ventas:
        return 'Ventas';
      case ReportType.alertas:
        return 'Alertas';
    }
  }

  IconData _getReportIcon() {
    switch (widget.reportType) {
      case ReportType.stocks:
        return Icons.warehouse;
      case ReportType.items:
        return Icons.inventory_2;
      case ReportType.clientes:
        return Icons.people;
      case ReportType.gastos:
        return Icons.receipt_long;
      case ReportType.ventas:
        return Icons.shopping_cart;
      case ReportType.alertas:
        return Icons.notifications;
    }
  }

  Color _getReportColor() {
    switch (widget.reportType) {
      case ReportType.stocks:
        return Colors.orange;
      case ReportType.items:
        return Colors.green;
      case ReportType.clientes:
        return Colors.purple;
      case ReportType.gastos:
        return Colors.red;
      case ReportType.ventas:
        return Colors.blue;
      case ReportType.alertas:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reportTitle = _getReportTitle();
    final reportIcon = _getReportIcon();
    final reportColor = _getReportColor();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(reportIcon, color: Colors.white),
            const SizedBox(width: 8),
            Text(reportTitle),
          ],
        ),
        backgroundColor: reportColor,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: reportColor),
                  const SizedBox(height: 16),
                  Text(l10n.loadingData),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.errorOccurred,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retry),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: reportColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : _data == null || _data!.isEmpty
                  ? Center(
                      child: Text(l10n.noData),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: _buildReportContent(),
                    ),
    );
  }

  Widget _buildReportContent() {
    if (_data == null) {
      return const Center(child: Text('No data'));
    }

    // 데이터 구조 분석 및 적절한 위젯 반환
    final data = _data!;
    
    // 'data' 키가 있고 리스트인 경우
    if (data.containsKey('data') && data['data'] is List) {
      final dataList = data['data'] as List;
      if (dataList.isEmpty) {
        return const Center(child: Text('No data available'));
      }
      
      // 첫 번째 항목이 맵이고 여러 키를 가지고 있으면 테이블로 표시
      if (dataList.isNotEmpty && dataList.first is Map) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTableFromList(dataList),
          ],
        );
      }
      
      return ListView(
        padding: const EdgeInsets.all(16),
        children: dataList.map((item) => _buildDataCard(item)).toList(),
      );
    }
    
    // 'data' 키가 있고 맵인 경우
    if (data.containsKey('data') && data['data'] is Map) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDataMap(data['data'] as Map<String, dynamic>),
        ],
      );
    }
    
    // 'data' 키가 없고 직접 리스트인 경우
    if (data is List) {
      if (data.isEmpty) {
        return const Center(child: Text('No data available'));
      }
      
      if (data.first is Map) {
        return _buildTableFromList(data);
      }
      
      return ListView(
        padding: const EdgeInsets.all(16),
        children: data.map((item) => _buildDataCard(item)).toList(),
      );
    }
    
    // 'data' 키가 없고 직접 맵인 경우
    if (data is Map) {
      // 테이블 형태로 표시 가능한지 확인
      if (_isTableData(data)) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTable(data),
          ],
        );
      }
      
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDataMap(data),
        ],
      );
    }
    
    return const Center(child: Text('Unknown data format'));
  }

  Widget _buildTableFromList(List<dynamic> dataList) {
    if (dataList.isEmpty) {
      return const Center(child: Text('No data'));
    }
    
    // 첫 번째 항목의 키를 컬럼으로 사용
    final firstItem = dataList.first as Map<String, dynamic>;
    final columns = firstItem.keys.map((key) {
      return DataColumn(
        label: Text(
          key.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }).toList();
    
    final rows = dataList.map((item) {
      if (item is Map<String, dynamic>) {
        return DataRow(
          cells: firstItem.keys.map((key) {
            return DataCell(Text(_formatValue(item[key])));
          }).toList(),
        );
      }
      return DataRow(
        cells: [DataCell(Text(_formatValue(item)))],
      );
    }).toList();
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: MaterialStateProperty.all(
            _getReportColor().withOpacity(0.1),
          ),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }

  Widget _buildDataCard(dynamic item) {
    if (item is Map<String, dynamic>) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: item.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _formatValue(entry.value),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(item.toString()),
      ),
    );
  }

  Widget _buildDataMap(Map<String, dynamic> data) {
    // 테이블 형태로 표시할 수 있는 데이터인지 확인
    if (_isTableData(data)) {
      return _buildTable(data);
    }

    // 카드 형태로 표시
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
                    child: _buildValueWidget(entry.value),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildValueWidget(dynamic value) {
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (value as Map<String, dynamic>).entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${entry.key}: ${_formatValue(entry.value)}',
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      );
    } else if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${entry.key + 1}. ${_formatValue(entry.value)}',
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      );
    }
    return Text(
      _formatValue(value),
      style: const TextStyle(fontSize: 16),
    );
  }

  bool _isTableData(Map<String, dynamic> data) {
    // 모든 값이 리스트인 경우 테이블로 표시
    return data.values.every((value) => value is List);
  }

  Widget _buildTable(Map<String, dynamic> data) {
    final columns = data.keys.map((key) {
      return DataColumn(
        label: Text(
          key.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }).toList();

    // 첫 번째 컬럼의 길이를 기준으로 행 수 결정
    final firstKey = data.keys.first;
    final rowCount = (data[firstKey] as List).length;

    final rows = List.generate(rowCount, (index) {
      return DataRow(
        cells: data.keys.map((key) {
          final value = data[key];
          if (value is List && index < value.length) {
            return DataCell(Text(_formatValue(value[index])));
          }
          return const DataCell(Text(''));
        }).toList(),
      );
    });

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: MaterialStateProperty.all(
            _getReportColor().withOpacity(0.1),
          ),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is num) {
      // 숫자가 큰 경우 통화 형식으로 표시
      if (value > 1000 && value is double) {
        return NumberFormat.currency(
          symbol: '\$',
          decimalDigits: 0,
          locale: 'es_CO',
        ).format(value);
      }
      return NumberFormat('#,###').format(value);
    }
    if (value is DateTime) {
      return DateFormat('yyyy-MM-dd HH:mm').format(value);
    }
    if (value is String && value.length > 50) {
      return '${value.substring(0, 50)}...';
    }
    return value.toString();
  }
}

