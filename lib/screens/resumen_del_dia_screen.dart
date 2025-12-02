import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../services/connection_storage_service.dart';
import '../models/connection_info.dart';
import 'main_connection_screen.dart';
import 'celebration_screen.dart';
import 'connection_screen.dart';
import 'report_screen.dart';

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
  final ConnectionStorageService _connectionStorageService = ConnectionStorageService();
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _selectedDate;
  String? _selectedSucursal;
  String? _databaseName;
  String _currentReport = 'resumen'; // 현재 선택된 보고서

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService(serverUrl: widget.serverUrl);
    // 현재 날짜를 명확하게 설정
    final now = DateTime.now();
    _selectedDate = now;
    // 데이터베이스 이름 로드
    _loadDatabaseName();
    // 초기 로드 시 현재 날짜를 명시적으로 전달
    _loadData(date: now);
  }

  Future<void> _loadDatabaseName() async {
    try {
      final databaseName = await _storage.read(key: 'database_name') ?? '';
      if (mounted) {
        setState(() {
          _databaseName = databaseName;
        });
      }
    } catch (e) {
      print('❌ 데이터베이스 이름 로드 실패: $e');
    }
  }

  Future<void> _showConnectionListDialog() async {
    try {
      final connections = await _connectionStorageService.getAllConnections();

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      final result = await showDialog<dynamic>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.storage, color: Colors.blue),
              const SizedBox(width: 8),
              Text(l10n.databaseConnection),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 새 연결 추가 버튼
                  Card(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                      title: Text(
                        l10n.newConnection,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(l10n.newConnectionDescription),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context, 'new');
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 기존 연결 목록
                  if (connections.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        l10n.noSavedConnections,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...connections.map((connection) {
                      final isCurrentConnection = connection.databaseName == _databaseName;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isCurrentConnection 
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                            : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCurrentConnection
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            child: const Icon(Icons.storage, color: Colors.white, size: 20),
                          ),
                          title: Text(
                            connection.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCurrentConnection
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${l10n.serverLabel}: ${connection.serverUrl}'),
                              Text('${l10n.dbLabel}: ${connection.databaseName}'),
                            ],
                          ),
                          trailing: isCurrentConnection
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.pop(context, connection);
                          },
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );

      if (result != null && mounted) {
        if (result == 'new') {
          // 새 연결 추가 화면으로 이동
          final newConnection = await Navigator.push<ConnectionInfo>(
            context,
            MaterialPageRoute(
              builder: (context) => const ConnectionScreen(),
            ),
          );
          
          // 새 연결이 생성되고 연결에 성공하면 자동으로 전환됨
          if (newConnection != null && mounted) {
            // 연결 화면에서 이미 연결을 시도했을 수 있으므로 확인
            await _loadDatabaseName();
            _loadData();
          }
        } else if (result is ConnectionInfo) {
          await _switchConnection(result);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('연결 목록 로드 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 기존 연결을 끊고 초기 화면으로 이동
  Future<void> _disconnectAndGoToInitialScreen() async {
    final l10n = AppLocalizations.of(context)!;
    
    // 확인 다이얼로그 표시
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('연결 끊기'),
          ],
        ),
        content: const Text('기존 연결을 끊고 초기 화면으로 이동하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 로딩 표시
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // 기존 연결 끊기
      await _databaseService.disconnectDatabase();

      // 저장된 연결 정보 삭제
      await _storage.delete(key: 'database_name');
      await _storage.delete(key: 'username');
      await _storage.delete(key: 'password');
      await _storage.delete(key: 'connection_success');
      await _storage.delete(key: 'profile_name');
      await _storage.delete(key: 'server_type');
      await _storage.delete(key: 'local_ip');

      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        
        // 초기 화면으로 이동 (모든 화면 제거)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MainConnectionScreen(),
          ),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('연결이 끊어졌습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('연결 끊기 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _switchConnection(ConnectionInfo connection) async {
    try {
      // 로딩 표시
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // serverUrl에서 host 추출
      String host = 'localhost';
      try {
        final uri = Uri.parse(connection.serverUrl);
        host = uri.host.isNotEmpty ? uri.host : 'localhost';
      } catch (e) {
        host = 'localhost';
      }

      final service = DatabaseService(serverUrl: connection.serverUrl);

      final request = DatabaseConnectionRequest(
        databaseName: connection.databaseName,
        username: connection.username,
        password: connection.password,
        host: host,
        port: null,
      );

      final success = await service.connectToDatabase(request);

      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
      }

      if (success && mounted) {
        // 연결 정보를 secure storage에 저장
        await _storage.write(key: 'database_name', value: connection.databaseName);
        await _storage.write(key: 'username', value: connection.username);
        await _storage.write(key: 'password', value: connection.password);

        // 축하 화면으로 이동 (자동으로 resumen del dia로 이동)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CelebrationScreen(
              serverUrl: connection.serverUrl,
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('연결 실패: 데이터베이스에 연결할 수 없습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('연결 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadData({DateTime? date, String? sucursal}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 날짜가 없으면 현재 날짜 사용 (명확하게 보장)
      final dateToUse = date ?? _selectedDate ?? DateTime.now();
      
      // 날짜와 sucursal을 API 호출에 포함
      final data = await _databaseService.getResumenDelDia(
        date: dateToUse,
        sucursal: sucursal ?? _selectedSucursal,
      );
      setState(() {
        _data = data;
        _isLoading = false;
        _errorMessage = null;
        // 사용된 날짜로 업데이트 (명확하게 보장)
        _selectedDate = dateToUse;
        if (sucursal != null) {
          _selectedSucursal = sucursal;
        }
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // 선택된 날짜로 데이터 다시 로드
      _loadData(date: picked);
    }
  }

  void _goToMainConnectionScreen() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MainConnectionScreen(
          skipAutoConnect: true,
        ),
      ),
      (route) => false,
    );
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
      // 통화 기호 없이 천 단위 구분자만 사용
      return NumberFormat('#,###').format(value);
    }
    // 문자열에서 $ 기호 제거
    if (value is String) {
      String cleanedValue = value.replaceAll('\$', '').trim();
      // 숫자로 변환 가능한 문자열인지 확인
      final numValue = num.tryParse(cleanedValue.replaceAll(',', '').replaceAll('.', ''));
      if (numValue != null) {
        return NumberFormat('#,###').format(numValue);
      }
      return cleanedValue;
    }
    return value.toString().replaceAll('\$', '').trim();
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.orange),
                      title: const Text('연결 끊고 초기 화면으로'),
                      subtitle: const Text('기존 연결을 끊고 초기 화면으로 이동합니다'),
                      onTap: () {
                        Navigator.pop(context);
                        _disconnectAndGoToInitialScreen();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.storage, color: Colors.blue),
                      title: Text(l10n.databaseConnection),
                      subtitle: const Text('다른 데이터베이스로 연결 전환'),
                      onTap: () {
                        Navigator.pop(context);
                        _showConnectionListDialog();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        title: Row(
          children: [
            if (_databaseName != null && _databaseName!.isNotEmpty)
              GestureDetector(
                onTap: _showConnectionListDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.storage,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _databaseName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            if (_databaseName != null && _databaseName!.isNotEmpty)
              const SizedBox(width: 12),
            Expanded(
              child: Text(_getCurrentReportTitle()),
            ),
          ],
        ),
        actions: [
          // 보고서 선택 드롭다운 메뉴
          PopupMenuButton<String>(
            icon: const Icon(Icons.assessment),
            tooltip: 'Reportes',
            onSelected: (value) {
              setState(() {
                _currentReport = value;
              });
              _navigateToReport(value);
            },
            itemBuilder: (BuildContext context) => _buildReportMenuItems(),
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.loadingData),
                ],
              ),
            )
          : _errorMessage != null
              ? Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Center(
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
                            label: Text(l10n.goBackToConnection),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : _data == null || _data!.isEmpty
                  ? Center(
                      child: Text(AppLocalizations.of(context)!.noData),
                    )
                  : Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return RefreshIndicator(
                          onRefresh: _loadData,
                          child: _hasMultipleSucursales()
                              ? _buildComparisonView(l10n)
                              : ListView(
                                  children: [
                                    // 날짜 표시
                                    if (_data!.containsKey('fecha'))
                                      _buildDateHeader(_data!['fecha']),

                                    // 판매 통계 (vcodes)
                                    if (_data!.containsKey('vcodes') && _data!['vcodes'] is Map)
                                      _buildSection(
                                        l10n.salesStatistics,
                                        _buildVcodesSection(_data!['vcodes'] as Map<String, dynamic>),
                                      ),

                                    // 지출 통계 (gastos)
                                    if (_data!.containsKey('gastos') && _data!['gastos'] is Map)
                                      _buildSection(
                                        l10n.expenseStatistics,
                                        _buildGastosSection(_data!['gastos'] as Map<String, dynamic>),
                                      ),

                                    // 할인 통계 (vdetalle)
                                    if (_data!.containsKey('vdetalle') && _data!['vdetalle'] is Map)
                                      _buildSection(
                                        l10n.discountStatistics,
                                        _buildVdetalleSection(_data!['vdetalle'] as Map<String, dynamic>),
                                      ),

                                    // 결제 통계 (vcodes_mpago)
                                    if (_data!.containsKey('vcodes_mpago') && _data!['vcodes_mpago'] is Map)
                                      _buildSection(
                                        l10n.mercadoPagoStatistics,
                                        _buildMpagoSection(_data!['vcodes_mpago'] as Map<String, dynamic>),
                                      ),
                                  ],
                                ),
                        );
                      },
                    ),
    );
  }

  Widget _buildDateHeader(String fecha) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
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
            const SizedBox(height: 4),
            const Text(
              'Tap para cambiar fecha',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildVcodesSection(Map<String, dynamic> vcodes) {
    final cards = <Widget>[];
    
    if (vcodes.containsKey('operation_count')) {
      cards.add(_buildDataCard(
        'Total de Transacciones',
        vcodes['operation_count'],
        Icons.shopping_cart,
      ));
    }
    
    if (vcodes.containsKey('total_venta_day')) {
      cards.add(_buildDataCard(
        'Total de Ventas',
        vcodes['total_venta_day'],
        Icons.attach_money,
        isCurrency: true,
      ));
    }
    
    if (vcodes.containsKey('total_efectivo_day')) {
      cards.add(_buildDataCard(
        'Ventas en Efectivo',
        vcodes['total_efectivo_day'],
        Icons.money,
        isCurrency: true,
      ));
    }
    
    if (vcodes.containsKey('total_credito_day')) {
      cards.add(_buildDataCard(
        'Ventas a Crédito',
        vcodes['total_credito_day'],
        Icons.credit_card,
        isCurrency: true,
      ));
    }
    
    if (vcodes.containsKey('total_banco_day')) {
      cards.add(_buildDataCard(
        'Ventas Bancarias',
        vcodes['total_banco_day'],
        Icons.account_balance,
        isCurrency: true,
      ));
    }
    
    if (vcodes.containsKey('total_favor_day')) {
      cards.add(_buildDataCard(
        'Ventas Favor',
        vcodes['total_favor_day'],
        Icons.favorite,
        isCurrency: true,
      ));
    }
    
    if (vcodes.containsKey('total_count_ropas')) {
      cards.add(_buildDataCard(
        'Total de Ropas',
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
        'Número de Gastos',
        gastos['gasto_count'],
        Icons.receipt_long,
      ));
    }
    
    if (gastos.containsKey('total_gasto_day')) {
      cards.add(_buildDataCard(
        'Total de Gastos',
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
        'Eventos de Descuento',
        vdetalle['count_discount_event'],
        Icons.local_offer,
      ));
    }
    
    if (vdetalle.containsKey('total_discount_day')) {
      cards.add(_buildDataCard(
        'Total de Descuentos',
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
        'Operaciones MPago',
        mpago['count_mpago_total'],
        Icons.payment,
      ));
    }
    
    if (mpago.containsKey('total_mpago_day')) {
      cards.add(_buildDataCard(
        'Total MPago',
        mpago['total_mpago_day'],
        Icons.account_balance_wallet,
        isCurrency: true,
      ));
    }

    return cards;
  }

  List<Widget> _buildScriptsSection(Map<String, dynamic> scripts) {
    final cards = <Widget>[];
    
    // 실행된 스크립트 수는 표시하지 않음
    
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

  // 여러 sucursal 데이터가 있는지 확인 (배열 형태인 경우 항상 비교 테이블 표시)
  bool _hasMultipleSucursales() {
    if (_data == null) return false;
    
    // vcodes가 배열인 경우 (1개 지점이어도 배열 형태로 올 수 있음)
    if (_data!.containsKey('vcodes') && _data!['vcodes'] is List) {
      final vcodesList = _data!['vcodes'] as List;
      if (vcodesList.isNotEmpty && vcodesList.first is Map) {
        // 배열 형태이면 항상 비교 테이블로 표시 (1개 지점이어도)
        return true;
      }
    }
    
    // 여러 형태의 응답 구조를 확인
    // 1. sucursales 배열 형태
    if (_data!.containsKey('sucursales') && _data!['sucursales'] is List) {
      return (_data!['sucursales'] as List).length > 1;
    }
    
    // 2. 각 sucursal이 키로 있는 맵 형태
    final sucursalKeys = _data!.keys.where((key) => 
      key.toString().length == 2 && 
      int.tryParse(key.toString()) != null
    ).toList();
    
    if (sucursalKeys.length > 1) {
      return true;
    }
    
    // 3. data 배열 형태
    if (_data!.containsKey('data') && _data!['data'] is List) {
      return (_data!['data'] as List).length > 1;
    }
    
    return false;
  }

  // 비교 테이블 뷰 생성
  Widget _buildComparisonView(AppLocalizations l10n) {
    List<Map<String, dynamic>> sucursalesData = [];
    
    // vcodes가 배열인 경우 (서버 응답 구조)
    if (_data!.containsKey('vcodes') && _data!['vcodes'] is List) {
      final vcodesList = _data!['vcodes'] as List;
      
      // 각 sucursal별로 데이터를 합침
      final sucursalMap = <int, Map<String, dynamic>>{};
      
      // vcodes 데이터 추가
      for (var item in vcodesList) {
        if (item is Map && item.containsKey('sucursal')) {
          final sucursal = item['sucursal'] is int 
              ? item['sucursal'] as int 
              : int.tryParse(item['sucursal'].toString()) ?? 0;
          
          if (!sucursalMap.containsKey(sucursal)) {
            sucursalMap[sucursal] = {'sucursal': sucursal};
          }
          sucursalMap[sucursal]!['vcodes'] = item;
        }
      }
      
      // vdetalle 데이터 추가
      if (_data!.containsKey('vdetalle') && _data!['vdetalle'] is List) {
        final vdetalleList = _data!['vdetalle'] as List;
        for (var item in vdetalleList) {
          if (item is Map && item.containsKey('sucursal')) {
            final sucursal = item['sucursal'] is int 
                ? item['sucursal'] as int 
                : int.tryParse(item['sucursal'].toString()) ?? 0;
            
            if (sucursalMap.containsKey(sucursal)) {
              sucursalMap[sucursal]!['vdetalle'] = item;
            }
          }
        }
      }
      
      // vcodes_mpago 데이터 추가
      if (_data!.containsKey('vcodes_mpago') && _data!['vcodes_mpago'] is List) {
        final mpagoList = _data!['vcodes_mpago'] as List;
        for (var item in mpagoList) {
          if (item is Map && item.containsKey('sucursal')) {
            final sucursal = item['sucursal'] is int 
                ? item['sucursal'] as int 
                : int.tryParse(item['sucursal'].toString()) ?? 0;
            
            if (sucursalMap.containsKey(sucursal)) {
              sucursalMap[sucursal]!['vcodes_mpago'] = item;
            }
          }
        }
      }
      
      // gastos 데이터 추가
      if (_data!.containsKey('gastos') && _data!['gastos'] is List) {
        final gastosList = _data!['gastos'] as List;
        for (var item in gastosList) {
          if (item is Map && item.containsKey('sucursal')) {
            final sucursal = item['sucursal'] is int 
                ? item['sucursal'] as int 
                : int.tryParse(item['sucursal'].toString()) ?? 0;
            
            if (sucursalMap.containsKey(sucursal)) {
              sucursalMap[sucursal]!['gastos'] = item;
            }
          }
        }
      }
      
      // ingresos 데이터 추가
      if (_data!.containsKey('ingresos') && _data!['ingresos'] is List) {
        final ingresosList = _data!['ingresos'] as List;
        for (var item in ingresosList) {
          if (item is Map && item.containsKey('sucursal')) {
            final sucursalStr = item['sucursal']?.toString() ?? '';
            final sucursal = int.tryParse(sucursalStr) ?? 0;
            
            if (sucursalMap.containsKey(sucursal)) {
              sucursalMap[sucursal]!['ingresos'] = item;
            }
          }
        }
      }
      
      sucursalesData = sucursalMap.values.toList();
      // sucursal 번호로 정렬
      sucursalesData.sort((a, b) => 
        (a['sucursal'] as int).compareTo(b['sucursal'] as int)
      );
    }
    // 다른 형태의 데이터 구조 처리
    else if (_data!.containsKey('sucursales') && _data!['sucursales'] is List) {
      sucursalesData = List<Map<String, dynamic>>.from(_data!['sucursales']);
    } else if (_data!.containsKey('data') && _data!['data'] is List) {
      sucursalesData = List<Map<String, dynamic>>.from(_data!['data']);
    } else {
      // 각 키가 sucursal 번호인 경우
      final sucursalKeys = _data!.keys.where((key) => 
        key.toString().length == 2 && 
        int.tryParse(key.toString()) != null &&
        _data![key] is Map
      ).toList();
      
      for (var key in sucursalKeys) {
        final data = _data![key] as Map<String, dynamic>;
        sucursalesData.add({
          'sucursal': key,
          ...data,
        });
      }
    }

    if (sucursalesData.isEmpty) {
      return Center(
        child: Text(l10n.noData),
      );
    }

    return ListView(
      children: [
        // 날짜 표시
        if (_data!.containsKey('fecha'))
          _buildDateHeader(_data!['fecha']),
        
        // 비교 테이블 섹션
        _buildSection(
          l10n.branchComparison,
          [
            _buildComparisonTable(sucursalesData, l10n),
          ],
        ),
      ],
    );
  }

  // 비교 테이블 생성
  Widget _buildComparisonTable(List<Map<String, dynamic>> sucursalesData, AppLocalizations l10n) {
    // 모든 통계 항목 수집
    final allMetrics = <String>[];
    
    for (var sucursalData in sucursalesData) {
      // vcodes 항목
      if (sucursalData.containsKey('vcodes') && sucursalData['vcodes'] is Map) {
        final vcodes = sucursalData['vcodes'] as Map<String, dynamic>;
        vcodes.keys.forEach((key) {
          if (!allMetrics.contains('vcodes_$key')) {
            allMetrics.add('vcodes_$key');
          }
        });
      }
      
      // gastos 항목
      if (sucursalData.containsKey('gastos') && sucursalData['gastos'] is Map) {
        final gastos = sucursalData['gastos'] as Map<String, dynamic>;
        gastos.keys.forEach((key) {
          if (!allMetrics.contains('gastos_$key')) {
            allMetrics.add('gastos_$key');
          }
        });
      }
      
      // vdetalle 항목
      if (sucursalData.containsKey('vdetalle') && sucursalData['vdetalle'] is Map) {
        final vdetalle = sucursalData['vdetalle'] as Map<String, dynamic>;
        vdetalle.keys.forEach((key) {
          if (!allMetrics.contains('vdetalle_$key')) {
            allMetrics.add('vdetalle_$key');
          }
        });
      }
      
      // vcodes_mpago 항목
      if (sucursalData.containsKey('vcodes_mpago') && sucursalData['vcodes_mpago'] is Map) {
        final mpago = sucursalData['vcodes_mpago'] as Map<String, dynamic>;
        mpago.keys.forEach((key) {
          if (!allMetrics.contains('mpago_$key')) {
            allMetrics.add('mpago_$key');
          }
        });
      }
      
      // ingresos 항목
      if (sucursalData.containsKey('ingresos') && sucursalData['ingresos'] is Map) {
        final ingresos = sucursalData['ingresos'] as Map<String, dynamic>;
        ingresos.keys.forEach((key) {
          if (!allMetrics.contains('ingresos_$key')) {
            allMetrics.add('ingresos_$key');
          }
        });
      }
    }

    // 테이블 컬럼 생성
    final columns = [
      DataColumn(
        label: Text(
          l10n.item,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      ...sucursalesData.map((data) {
        final sucursal = data['sucursal']?.toString() ?? 
                        data['sucursal_id']?.toString() ?? 
                        'N/A';
        return DataColumn(
          label: Text(
            sucursal,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }),
    ];

    // 테이블 행 생성 (sucursal 필터링)
    final rows = allMetrics
        .where((metric) => !metric.contains('sucursal')) // sucursal 제외
        .map((metric) {
      final parts = metric.split('_');
      final category = parts[0];
      final key = parts.sublist(1).join('_');
      
      // 항목 이름 매핑 (스페인어)
      final metricNames = {
        'vcodes_operation_count': 'Total de Transacciones',
        'vcodes_total_venta_day': 'Total de Ventas',
        'vcodes_total_efectivo_day': 'Ventas en Efectivo',
        'vcodes_total_credito_day': 'Ventas a Crédito',
        'vcodes_total_banco_day': 'Ventas Bancarias',
        'vcodes_total_favor_day': 'Ventas Favor',
        'vcodes_total_count_ropas': 'Total de Ropas',
        'gastos_gasto_count': 'Número de Gastos',
        'gastos_total_gasto_day': 'Total de Gastos',
        'vdetalle_count_discount_event': 'Eventos de Descuento',
        'vdetalle_total_discount_day': 'Total de Descuentos',
        'mpago_count_mpago_total': 'Operaciones MPago',
        'mpago_total_mpago_day': 'Total MPago',
        'ingresos_ingreso_events': 'Eventos de Ingreso',
        'ingresos_ingreso_total_ropas': 'Total de Ropas Ingresadas',
      };
      
      final metricName = metricNames[metric] ?? key;
      // 통화 표시가 필요한 항목만 true로 설정 (건수는 제외)
      final isCurrency = (metric.contains('total_venta') || 
                         metric.contains('total_efectivo') || 
                         metric.contains('total_credito') || 
                         metric.contains('total_banco') || 
                         metric.contains('total_favor') ||
                         metric.contains('total_gasto') ||
                         metric.contains('total_discount') ||
                         metric.contains('total_mpago')) &&
                        !metric.contains('count') &&
                        !metric.contains('_count_');
      
      return DataRow(
        cells: [
          DataCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(metricName),
            ),
          ),
          ...sucursalesData.map((data) {
            dynamic value;
            
            if (category == 'vcodes' && data.containsKey('vcodes')) {
              final vcodesData = data['vcodes'];
              if (vcodesData is Map<String, dynamic>) {
                value = vcodesData[key];
              }
            } else if (category == 'gastos' && data.containsKey('gastos')) {
              final gastosData = data['gastos'];
              if (gastosData is Map<String, dynamic>) {
                value = gastosData[key];
              }
            } else if (category == 'vdetalle' && data.containsKey('vdetalle')) {
              final vdetalleData = data['vdetalle'];
              if (vdetalleData is Map<String, dynamic>) {
                value = vdetalleData[key];
              }
            } else if (category == 'mpago' && data.containsKey('vcodes_mpago')) {
              final mpagoData = data['vcodes_mpago'];
              if (mpagoData is Map<String, dynamic>) {
                value = mpagoData[key];
              }
            } else if (category == 'ingresos' && data.containsKey('ingresos')) {
              final ingresosData = data['ingresos'];
              if (ingresosData is Map<String, dynamic>) {
                value = ingresosData[key];
              }
            }
            
            final formattedValue = _formatValue(value, isCurrency: isCurrency);
            final isNumeric = value is num || (value is String && (num.tryParse(value.toString().replaceAll(',', '').replaceAll('.', '')) != null));
            
            return DataCell(
              Align(
                alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  formattedValue,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isCurrency ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
              ),
            );
          }),
        ],
      );
    }).toList();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: MaterialStateProperty.all(
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );
  }

  // 현재 보고서 제목 가져오기
  String _getCurrentReportTitle() {
    switch (_currentReport) {
      case 'resumen':
        return 'Resumen del Día';
      case 'items':
        return 'Items';
      case 'stocks':
        return 'Stocks';
      case 'clientes':
        return 'Clientes';
      case 'gastos':
        return 'Gastos';
      case 'ventas':
        return 'Ventas';
      case 'alertas':
        return 'Alertas';
      default:
        return 'Resumen del Día';
    }
  }

  // 보고서 메뉴 아이템 빌드
  List<PopupMenuEntry<String>> _buildReportMenuItems() {
    return [
      PopupMenuItem<String>(
        value: 'resumen',
        child: Row(
          children: [
            Icon(
              Icons.today,
              color: _currentReport == 'resumen' ? Colors.blue : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Resumen del Día',
              style: TextStyle(
                fontWeight: _currentReport == 'resumen' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (_currentReport == 'resumen') ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.blue, size: 18),
            ],
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'stocks',
        child: Row(
          children: [
            Icon(
              Icons.warehouse,
              color: _currentReport == 'stocks' ? Colors.orange : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Stocks',
              style: TextStyle(
                fontWeight: _currentReport == 'stocks' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (_currentReport == 'stocks') ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.orange, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'items',
        child: Row(
          children: [
            Icon(
              Icons.inventory_2,
              color: _currentReport == 'items' ? Colors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Items',
              style: TextStyle(
                fontWeight: _currentReport == 'items' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (_currentReport == 'items') ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.green, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'clientes',
        child: Row(
          children: [
            Icon(
              Icons.people,
              color: _currentReport == 'clientes' ? Colors.purple : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Clientes',
              style: TextStyle(
                fontWeight: _currentReport == 'clientes' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (_currentReport == 'clientes') ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.purple, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'gastos',
        child: Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: _currentReport == 'gastos' ? Colors.red : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Gastos',
              style: TextStyle(
                fontWeight: _currentReport == 'gastos' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (_currentReport == 'gastos') ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.red, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'ventas',
        child: Row(
          children: [
            Icon(
              Icons.shopping_cart,
              color: _currentReport == 'ventas' ? Colors.blue : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Ventas',
              style: TextStyle(
                fontWeight: _currentReport == 'ventas' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (_currentReport == 'ventas') ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.blue, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'alertas',
        child: Row(
          children: [
            Icon(
              Icons.notifications,
              color: _currentReport == 'alertas' ? Colors.amber : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Alertas',
              style: TextStyle(
                fontWeight: _currentReport == 'alertas' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (_currentReport == 'alertas') ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.amber, size: 18),
            ],
          ],
        ),
      ),
    ];
  }

  // 보고서로 이동하는 메서드
  void _navigateToReport(String reportType) {
    // 현재 보고서는 아무것도 하지 않음
    if (reportType == 'resumen') {
      return;
    }

    // ReportType으로 변환
    final ReportType reportTypeEnum;
    switch (reportType) {
      case 'stocks':
        reportTypeEnum = ReportType.stocks;
        break;
      case 'items':
        reportTypeEnum = ReportType.items;
        break;
      case 'clientes':
        reportTypeEnum = ReportType.clientes;
        break;
      case 'gastos':
        reportTypeEnum = ReportType.gastos;
        break;
      case 'ventas':
        reportTypeEnum = ReportType.ventas;
        break;
      case 'alertas':
        reportTypeEnum = ReportType.alertas;
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportScreen(
          serverUrl: widget.serverUrl,
          reportType: reportTypeEnum,
        ),
      ),
    );
  }

}



