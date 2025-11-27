import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import 'main_connection_screen.dart';

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
        _errorMessage = null;
      });
    } catch (e) {
      // 오류 메시지 추출
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
        print('❌ resumen_del_dia 오류: $errorMessage');
      }
    }
  }

  Widget _buildDataCard(String title, dynamic value, IconData icon, {bool isCurrency = false}) {
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
                    _formatValue(value, isCurrency: isCurrency),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCurrency ? Theme.of(context).colorScheme.primary : null,
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

  String _formatValue(dynamic value, {bool isCurrency = false}) {
    if (value == null) return 'N/A';
    if (value is num) {
      if (isCurrency) {
        return NumberFormat.currency(
          symbol: '\$',
          decimalDigits: 0,
          locale: 'es_CO',
        ).format(value);
      }
      return NumberFormat('#,###').format(value);
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
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainConnectionScreen(
                                skipAutoConnect: true,
                              ),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.settings_backup_restore),
                        label: const Text('다시 접속 화면으로 이동'),
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
                          // 날짜 표시
                          if (_data!.containsKey('fecha'))
                            _buildDateHeader(_data!['fecha']),

                          // 판매 통계 (vcodes)
                          if (_data!.containsKey('vcodes') && _data!['vcodes'] is Map)
                            _buildSection(
                              '📊 판매 통계',
                              _buildVcodesSection(_data!['vcodes'] as Map<String, dynamic>),
                            ),

                          // 지출 통계 (gastos)
                          if (_data!.containsKey('gastos') && _data!['gastos'] is Map)
                            _buildSection(
                              '💸 지출 통계',
                              _buildGastosSection(_data!['gastos'] as Map<String, dynamic>),
                            ),

                          // 할인 통계 (vdetalle)
                          if (_data!.containsKey('vdetalle') && _data!['vdetalle'] is Map)
                            _buildSection(
                              '🎁 할인 통계',
                              _buildVdetalleSection(_data!['vdetalle'] as Map<String, dynamic>),
                            ),

                          // 결제 통계 (vcodes_mpago)
                          if (_data!.containsKey('vcodes_mpago') && _data!['vcodes_mpago'] is Map)
                            _buildSection(
                              '💳 결제 통계',
                              _buildMpagoSection(_data!['vcodes_mpago'] as Map<String, dynamic>),
                            ),

                          // 스크립트 결과 (scripts)
                          if (_data!.containsKey('scripts') && _data!['scripts'] is Map)
                          _buildSection(
                              '⚙️ 스크립트 실행 결과',
                              _buildScriptsSection(_data!['scripts'] as Map<String, dynamic>),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildDateHeader(String fecha) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_today,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Fecha: $fecha',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildVcodesSection(Map<String, dynamic> vcodes) {
    final cards = <Widget>[];
    
    if (vcodes.containsKey('operation_count')) {
      cards.add(_buildDataCard(
        '총 거래 건수',
        vcodes['operation_count'],
        Icons.shopping_cart,
      ));
    }
    
    if (vcodes.containsKey('total_venta_day')) {
      cards.add(_buildDataCard(
        '총 판매액',
        vcodes['total_venta_day'],
        Icons.attach_money,
        isCurrency: true,
      ));
    }
    
    if (vcodes.containsKey('total_efectivo_day')) {
      cards.add(_buildDataCard(
        '현금 판매',
        vcodes['total_efectivo_day'],
        Icons.money,
        isCurrency: true,
      ));
    }
    
    if (vcodes.containsKey('total_credito_day')) {
      cards.add(_buildDataCard(
        '신용 판매',
        vcodes['total_credito_day'],
        Icons.credit_card,
        isCurrency: true,
      ));
    }
    
    if (vcodes.containsKey('total_banco_day')) {
      cards.add(_buildDataCard(
        '은행 판매',
        vcodes['total_banco_day'],
        Icons.account_balance,
        isCurrency: true,
      ));
    }
    
    if (vcodes.containsKey('total_favor_day')) {
      cards.add(_buildDataCard(
        'Favor 판매',
        vcodes['total_favor_day'],
        Icons.favorite,
        isCurrency: true,
      ));
    }
    
    if (vcodes.containsKey('total_count_ropas')) {
      cards.add(_buildDataCard(
        '총 의류 수',
        vcodes['total_count_ropas'],
        Icons.checkroom,
      ));
    }

    return cards;
  }

  List<Widget> _buildGastosSection(Map<String, dynamic> gastos) {
    final cards = <Widget>[];
    
    if (gastos.containsKey('gasto_count')) {
      cards.add(_buildDataCard(
        '지출 건수',
        gastos['gasto_count'],
        Icons.receipt_long,
      ));
    }
    
    if (gastos.containsKey('total_gasto_day')) {
      cards.add(_buildDataCard(
        '총 지출액',
        gastos['total_gasto_day'],
        Icons.payments,
        isCurrency: true,
      ));
    }

    return cards;
  }

  List<Widget> _buildVdetalleSection(Map<String, dynamic> vdetalle) {
    final cards = <Widget>[];
    
    if (vdetalle.containsKey('count_discount_event')) {
      cards.add(_buildDataCard(
        '할인 이벤트 건수',
        vdetalle['count_discount_event'],
        Icons.local_offer,
      ));
    }
    
    if (vdetalle.containsKey('total_discount_day')) {
      cards.add(_buildDataCard(
        '총 할인액',
        vdetalle['total_discount_day'],
        Icons.discount,
        isCurrency: true,
      ));
    }

    return cards;
  }

  List<Widget> _buildMpagoSection(Map<String, dynamic> mpago) {
    final cards = <Widget>[];
    
    if (mpago.containsKey('count_mpago_total')) {
      cards.add(_buildDataCard(
        '결제 건수',
        mpago['count_mpago_total'],
        Icons.payment,
      ));
    }
    
    if (mpago.containsKey('total_mpago_day')) {
      cards.add(_buildDataCard(
        '총 결제액',
        mpago['total_mpago_day'],
        Icons.account_balance_wallet,
        isCurrency: true,
      ));
    }

    return cards;
  }

  List<Widget> _buildScriptsSection(Map<String, dynamic> scripts) {
    final cards = <Widget>[];
    
    if (scripts.containsKey('executed')) {
      cards.add(_buildDataCard(
        '실행된 스크립트 수',
        scripts['executed'],
        Icons.code,
      ));
    }
    
    if (scripts.containsKey('results') && scripts['results'] is List) {
      final results = scripts['results'] as List;
      if (results.isNotEmpty) {
        cards.add(
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  Row(
                    children: [
                      Icon(
                        Icons.list,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '스크립트 결과 (${results.length}개)',
                        style: const TextStyle(
                    fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...results.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                        '${entry.key + 1}. ${entry.value}',
                  style: TextStyle(
                          fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      }
    }

    return cards;
  }

}


