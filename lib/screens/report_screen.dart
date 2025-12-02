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
  final TextEditingController _filteringWordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService(serverUrl: widget.serverUrl);
    _loadData();
  }

  @override
  void dispose() {
    _filteringWordController.dispose();
    super.dispose();
  }

  Future<void> _loadData({String? filteringWord}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> data;
      
      switch (widget.reportType) {
        case ReportType.stocks:
          final stocksFilteringWord = filteringWord ?? 
              (_filteringWordController.text.isEmpty ? null : _filteringWordController.text);
          data = await _databaseService.getStocksReport(
            filteringWord: stocksFilteringWord,
          );
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
                  : Column(
                      children: [
                        // 스톡 보고서일 때만 검색 필드 표시
                        if (widget.reportType == ReportType.stocks)
                          _buildFilteringWordField(),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () => _loadData(),
                            child: _buildReportContent(),
                          ),
                        ),
                      ],
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
    
    // 'data' 키가 없고 직접 맵인 경우
    if (data is Map<String, dynamic>) {
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

  // Filtering word 입력 필드
  Widget _buildFilteringWordField() {
    final reportColor = _getReportColor();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: reportColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _filteringWordController,
              decoration: InputDecoration(
                labelText: 'Filtering Word',
                hintText: '검색어를 입력하세요',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filteringWordController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _filteringWordController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _loadData(filteringWord: value);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              final filteringWord = _filteringWordController.text.trim();
              _loadData(filteringWord: filteringWord.isEmpty ? null : filteringWord);
            },
            icon: const Icon(Icons.search),
            label: const Text('검색'),
            style: ElevatedButton.styleFrom(
              backgroundColor: reportColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
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
            final value = item[key];
            final formattedValue = _formatValue(value);
            final isNumeric = _isNumeric(value);
            return DataCell(
              Text(
                formattedValue,
                textAlign: isNumeric ? TextAlign.right : TextAlign.left,
              ),
            );
          }).toList(),
        );
      }
      final formattedValue = _formatValue(item);
      final isNumeric = _isNumeric(item);
      return DataRow(
        cells: [
          DataCell(
            Text(
              formattedValue,
              textAlign: isNumeric ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
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
                        textAlign: _isNumeric(entry.value) ? TextAlign.right : TextAlign.left,
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
          final formattedValue = _formatValue(entry.value);
          final isNumeric = _isNumeric(entry.value);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
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
          final formattedValue = _formatValue(entry.value);
          final isNumeric = _isNumeric(entry.value);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${entry.key + 1}. $formattedValue',
              textAlign: isNumeric ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      );
    }
    final formattedValue = _formatValue(value);
    final isNumeric = _isNumeric(value);
    return Text(
      formattedValue,
      textAlign: isNumeric ? TextAlign.right : TextAlign.left,
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
            final cellValue = value[index];
            final formattedValue = _formatValue(cellValue);
            final isNumeric = _isNumeric(cellValue);
            return DataCell(
              Text(
                formattedValue,
                textAlign: isNumeric ? TextAlign.right : TextAlign.left,
              ),
            );
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

  // 숫자인지 확인하는 헬퍼 함수
  bool _isNumeric(dynamic value) {
    if (value == null) return false;
    if (value is num) return true;
    if (value is String) {
      // 숫자로 변환 가능한 문자열인지 확인
      return double.tryParse(value) != null || int.tryParse(value) != null;
    }
    return false;
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is num) {
      // 숫자는 천 단위 구분자만 사용 (통화 기호 없음)
      return NumberFormat('#,###').format(value);
    }
    if (value is DateTime) {
      return DateFormat('yyyy-MM-dd HH:mm').format(value);
    }
    if (value is String) {
      // 문자열에서 $ 기호 제거
      String cleanedValue = value.replaceAll('\$', '').trim();
      
      // 숫자로 변환 가능한 문자열인지 확인
      final numValue = num.tryParse(cleanedValue.replaceAll(',', ''));
      if (numValue != null) {
        // 숫자로 변환 가능하면 천 단위 구분자로 포맷팅
        return NumberFormat('#,###').format(numValue);
      }
      
      // 긴 문자열은 자르기
      if (cleanedValue.length > 50) {
        return '${cleanedValue.substring(0, 50)}...';
      }
      
      return cleanedValue;
    }
    // 다른 타입은 문자열로 변환하고 $ 기호 제거
    String strValue = value.toString();
    return strValue.replaceAll('\$', '').trim();
  }

  // 숫자면 오른쪽 정렬, 아니면 기본 정렬로 Text 위젯 생성
  Widget _buildTextWidget(String text, {bool isNumeric = false}) {
    return Text(
      text,
      textAlign: isNumeric ? TextAlign.right : TextAlign.left,
      style: const TextStyle(fontSize: 16),
    );
  }
}

