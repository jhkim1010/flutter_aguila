import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ResumenDelDiaScreen extends StatefulWidget {
  final String serverUrl;

  const ResumenDelDiaScreen({
    super.key,
    required this.serverUrl,
  });

  @override
  State<ResumenDelDiaScreen> createState() => _ResumenDelDiaScreenState();
}

class _ResumenDelDiaScreenState extends State<ResumenDelDiaScreen> {
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
      final data = await _databaseService.getResumenDelDia();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Widget _buildDataCard(String title, dynamic value, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatValue(value),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is num) {
      return value.toStringAsFixed(value is double ? 2 : 0);
    }
    return value.toString();
  }

  Widget _buildTable(Map<String, dynamic>? tableData) {
    if (tableData == null || tableData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: MaterialStateProperty.all(
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          columns: tableData.keys.map((key) {
            return DataColumn(
              label: Text(
                key.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
          rows: _buildTableRows(tableData),
        ),
      ),
    );
  }

  List<DataRow> _buildTableRows(Map<String, dynamic> tableData) {
    // 테이블 데이터가 배열인 경우
    if (tableData.values.first is List) {
      final firstKey = tableData.keys.first;
      final rows = tableData[firstKey] as List;
      if (rows.isEmpty) return [];

      return rows.map((row) {
        return DataRow(
          cells: tableData.keys.map((key) {
            final value = tableData[key] is List
                ? (tableData[key] as List)[rows.indexOf(row)]
                : tableData[key];
            return DataCell(Text(_formatValue(value)));
          }).toList(),
        );
      }).toList();
    }

    // 단일 행인 경우
    return [
      DataRow(
        cells: tableData.values.map((value) {
          return DataCell(Text(_formatValue(value)));
        }).toList(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen del Día'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('데이터를 불러오는 중...'),
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
                        '오류 발생',
                        style: TextStyle(
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
                        label: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _data == null || _data!.isEmpty
                  ? const Center(
                      child: Text('데이터가 없습니다.'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        children: [
                          // 요약 정보 카드들
                          if (_data!.containsKey('resumen') ||
                              _data!.keys.any((k) => k.toString().toLowerCase().contains('total')))
                            _buildSection(
                              '요약',
                              _buildSummaryCards(),
                            ),

                          // 테이블 데이터
                          if (_data!.entries.any((entry) => entry.value is Map || entry.value is List))
                            _buildSection(
                              '상세 데이터',
                              _buildDetailSections(),
                            ),

                          // 일반 키-값 쌍
                          _buildSection(
                            '정보',
                            _buildInfoCards(),
                          ),
                        ],
                      ),
                    ),
    );
  }

  List<Widget> _buildSummaryCards() {
    final cards = <Widget>[];
    final summaryKeys = ['total', 'resumen', 'summary', 'count', 'amount'];

    _data!.forEach((key, value) {
      final keyLower = key.toString().toLowerCase();
      if (summaryKeys.any((sk) => keyLower.contains(sk)) && value is! Map && value is! List) {
        IconData icon;
        if (keyLower.contains('total') || keyLower.contains('amount')) {
          icon = Icons.attach_money;
        } else if (keyLower.contains('count')) {
          icon = Icons.numbers;
        } else {
          icon = Icons.info;
        }

        cards.add(_buildDataCard(key.toString(), value, icon));
      }
    });

    return cards.isEmpty ? [const SizedBox.shrink()] : cards;
  }

  List<Widget> _buildDetailSections() {
    final widgets = <Widget>[];

    _data!.forEach((key, value) {
      if (value is Map) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  key.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              _buildTable(value as Map<String, dynamic>),
            ],
          ),
        );
      } else if (value is List && value.isNotEmpty && value.first is Map) {
        // 리스트의 첫 번째 항목을 테이블 헤더로 사용
        final firstItem = value.first as Map;
        final tableData = <String, List>{};
        firstItem.keys.forEach((k) {
          tableData[k.toString()] = value.map((item) => (item as Map)[k]).toList();
        });
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  key.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              _buildTable(tableData),
            ],
          ),
        );
      }
    });

    return widgets.isEmpty ? [const SizedBox.shrink()] : widgets;
  }

  List<Widget> _buildInfoCards() {
    final cards = <Widget>[];

    _data!.forEach((key, value) {
      if (value is! Map && value is! List) {
        IconData icon = Icons.info_outline;
        if (key.toString().toLowerCase().contains('date') ||
            key.toString().toLowerCase().contains('fecha')) {
          icon = Icons.calendar_today;
        } else if (key.toString().toLowerCase().contains('time') ||
            key.toString().toLowerCase().contains('hora')) {
          icon = Icons.access_time;
        }

        cards.add(_buildDataCard(key.toString(), value, icon));
      }
    });

    return cards.isEmpty ? [const SizedBox.shrink()] : cards;
  }
}


