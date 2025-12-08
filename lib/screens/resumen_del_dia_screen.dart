import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../services/connection_storage_service.dart';
import '../services/secure_storage_helper.dart';
import '../models/connection_info.dart';
import '../utils/platform_utils.dart';
import 'main_connection_screen.dart' show ServerType, MainConnectionScreen;
import 'celebration_screen.dart';
import 'connection_screen.dart' hide ServerType;
import 'report_screen.dart';

class ResumenDelDiaScreen extends StatefulWidget {
  final String serverUrl;
  final ReportType? initialReportType; // 초기 보고서 타입
  final String? initialFilteringWord; // 초기 필터링 단어
  final String? initialSortColumn; // 초기 정렬 컬럼
  final bool? initialSortAscending; // 초기 정렬 방향
  final DateTime? initialItemsStartDate; // items 보고서용 초기 시작 날짜
  final DateTime? initialItemsEndDate; // items 보고서용 초기 종료 날짜

  const ResumenDelDiaScreen({
    super.key,
    required this.serverUrl,
    this.initialReportType,
    this.initialFilteringWord,
    this.initialSortColumn,
    this.initialSortAscending,
    this.initialItemsStartDate,
    this.initialItemsEndDate,
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
  ReportType? _selectedReportType; // 큰 화면에서 오른쪽에 표시할 보고서 타입
  // 현재 보고서의 필터링 단어와 정렬 정보 (연결 변경 시 유지용)
  String? _currentFilteringWord;
  String? _currentSortColumn;
  bool? _currentSortAscending;
  // Items 보고서의 날짜 범위 정보 (연결 변경 시 유지용)
  DateTime? _currentItemsStartDate;
  DateTime? _currentItemsEndDate;
  List<ConnectionInfo> _savedConnections = []; // 저장된 연결 목록
  bool _showAllConnections = false; // 연결 목록 전체 표시 여부
  bool _isAddingNewConnection = false; // 새 연결 추가 모드 여부
  
  // 새 연결 입력 필드 컨트롤러 (MainConnectionScreen과 동일한 구조)
  final _newProfileNameController = TextEditingController();
  final _newServerUrlController = TextEditingController();
  final _newDatabaseNameController = TextEditingController();
  final _newUsernameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _newLocalIpController = TextEditingController();
  ServerType _newSelectedServerType = ServerType.hostinger; // 서버 타입

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService(serverUrl: widget.serverUrl);
    // 현재 날짜를 명확하게 설정
    final now = DateTime.now();
    _selectedDate = now;
    // 초기 보고서 타입 설정 (연결 변경 시 유지)
    if (widget.initialReportType != null) {
      _selectedReportType = widget.initialReportType;
    }
    // Items 보고서의 초기 날짜 범위 설정 (연결 변경 시 유지)
    if (widget.initialItemsStartDate != null && widget.initialItemsEndDate != null) {
      _currentItemsStartDate = widget.initialItemsStartDate;
      _currentItemsEndDate = widget.initialItemsEndDate;
    }
    if (widget.initialReportType != null) {
      // _currentReport도 설정
      final reportType = widget.initialReportType!; // null 체크 후 non-null로 변환
      switch (reportType) {
        case ReportType.stocks:
          _currentReport = 'stocks';
          break;
        case ReportType.codigos:
          _currentReport = 'codigos';
          break;
        case ReportType.todocodigos:
          _currentReport = 'todocodigos';
          break;
        case ReportType.items:
          _currentReport = 'items';
          break;
        case ReportType.clientes:
          _currentReport = 'clientes';
          break;
        case ReportType.gastos:
          _currentReport = 'gastos';
          break;
        case ReportType.ventas:
          _currentReport = 'ventas';
          break;
        case ReportType.alertas:
          _currentReport = 'alertas';
          break;
      }
    }
    // 데이터베이스 이름 로드
    _loadDatabaseName();
    // 연결 목록 로드
    _loadSavedConnections();
    // 새 연결 입력 필드 기본값 설정
    _newServerUrlController.text = 'https://sync.coolsistema.com';
    _newSelectedServerType = ServerType.hostinger;
    // macOS에서 secure storage 읽기를 위한 지연 후 데이터 로드
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _loadData(date: now);
        }
      });
    } else {
      // 초기 로드 시 현재 날짜를 명시적으로 전달
      _loadData(date: now);
    }
  }

  Future<void> _loadSavedConnections() async {
    try {
      print('🔄 ResumenDelDiaScreen: 연결 목록 로드 시작...');
      final connections = await _connectionStorageService.getAllConnections();
      print('✅ ResumenDelDiaScreen: ${connections.length}개 연결 로드 완료');
      
      for (var conn in connections) {
        print('   - ${conn.name} (ID: ${conn.id}, DB: ${conn.databaseName})');
      }
      
      if (mounted) {
        setState(() {
          _savedConnections = connections;
        });
        print('🔄 ResumenDelDiaScreen: UI 업데이트 완료 (${_savedConnections.length}개 연결 표시)');
      }
    } catch (e) {
      print('❌ 연결 목록 로드 실패: $e');
    }
  }

  // 연결 목록에서 연결 삭제
  Future<void> _deleteConnectionFromList(ConnectionInfo connection) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('연결 삭제'),
        content: Text('${connection.name} 연결을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        print('🗑️ 연결 삭제 시작: ${connection.name} (ID: ${connection.id})');
        await _connectionStorageService.deleteConnection(connection.id);
        await _loadSavedConnections();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('연결이 삭제되었습니다')),
          );
        }
        print('✅ 연결 삭제 완료: ${connection.name}');
      } catch (e) {
        print('❌ 연결 삭제 실패: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 실패: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 표시될 때마다 연결 리스트 갱신
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      print('🔄 ResumenDelDiaScreen: didChangeDependencies 호출, 연결 리스트 갱신');
      _loadSavedConnections();
    }
  }

  Future<void> _loadDatabaseName() async {
    try {
      final databaseName = await SecureStorageHelper.read('database_name') ?? '';
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

      // 저장된 연결 정보 삭제 (하이브리드 방식)
      await SecureStorageHelper.delete('database_name');
      await SecureStorageHelper.delete('username');
      await SecureStorageHelper.delete('password');
      await SecureStorageHelper.delete('connection_success');
      await SecureStorageHelper.delete('profile_name');
      await SecureStorageHelper.delete('server_type');
      await SecureStorageHelper.delete('local_ip');

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

      final service = DatabaseService(serverUrl: connection.serverUrl);

      final request = DatabaseConnectionRequest(
        databaseName: connection.databaseName,
        username: connection.username,
        password: connection.password,
      );

      final success = await service.connectToDatabase(request);

      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
      }

      if (success && mounted) {
        // 연결 정보를 하이브리드 저장소에 저장
        await SecureStorageHelper.save('database_name', connection.databaseName);
        await SecureStorageHelper.save('username', connection.username);
        // macOS: SharedPreferences, 다른 플랫폼: SecureStorage
        if (defaultTargetPlatform == TargetPlatform.macOS) {
          await SecureStorageHelper.save('password', connection.password);
        } else {
          await SecureStorageHelper.saveSecure('password', connection.password);
        }

        // 현재 보고서 정보를 유지하면서 ResumenDelDiaScreen으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResumenDelDiaScreen(
              serverUrl: connection.serverUrl,
              initialReportType: _selectedReportType,
              initialFilteringWord: _currentFilteringWord,
              initialSortColumn: _currentSortColumn,
              initialSortAscending: _currentSortAscending,
              initialItemsStartDate: _currentItemsStartDate,
              initialItemsEndDate: _currentItemsEndDate,
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
      // macOS에서 secure storage 읽기를 위한 약간의 지연 추가
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        print('🍎 macOS: secure storage 읽기 전 대기 중...');
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      // 날짜가 없으면 현재 날짜 사용 (명확하게 보장)
      final dateToUse = date ?? _selectedDate ?? DateTime.now();
      
      // 디버깅: 로드 정보 출력
      print('  - 서버 URL: ${widget.serverUrl}');
      print('  - 사용 날짜: $dateToUse');
      print('  - Sucursal: ${sucursal ?? _selectedSucursal ?? '없음'}');
      
      // 날짜와 sucursal을 API 호출에 포함
      final data = await _databaseService.getResumenDelDia(
        date: dateToUse,
        sucursal: sucursal ?? _selectedSucursal,
      );
      
      // Stock resumen도 함께 가져오기 (stocks GET 요청에서 resumen_del_dia 포함)
      try {
        print('📊 Stock resumen 요청 시작...');
        final stockResumen = await _databaseService.getStocksReport(
          filters: {
            'date': dateToUse.toString().substring(0, 10), // YYYY-MM-DD 형식
            if (sucursal != null && sucursal.isNotEmpty) 'sucursal': sucursal,
            if (_selectedSucursal != null && _selectedSucursal!.isNotEmpty) 'sucursal': _selectedSucursal,
          },
        );
        
        // Stock resumen 데이터를 resumen del dia 데이터에 추가
        if (stockResumen != null && stockResumen.isNotEmpty) {
          // 새로운 응답 형식: resumen_del_dia 배열이 stocks 응답에 포함됨
          if (stockResumen.containsKey('resumen_del_dia') && stockResumen['resumen_del_dia'] is List) {
            final resumenDelDia = stockResumen['resumen_del_dia'] as List;
            // 기존 코드와 호환성을 위해 stocks 키로 변환
            data['stocks'] = resumenDelDia;
            data['stock_resumen'] = {'stocks': resumenDelDia};
            print('✅ Stock resumen 데이터 추가 완료 (resumen_del_dia에서 추출: ${resumenDelDia.length}개 항목)');
          } else {
            // 기존 형식 지원 (하위 호환성)
            data['stock_resumen'] = stockResumen;
            if (stockResumen.containsKey('stocks') && stockResumen['stocks'] is List) {
              data['stocks'] = stockResumen['stocks'];
            }
            print('✅ Stock resumen 데이터 추가 완료 (기존 형식)');
          }
        }
      } catch (e) {
        print('⚠️ Stock resumen 가져오기 실패 (무시하고 계속 진행): $e');
        // Stock resumen 가져오기 실패해도 resumen del dia는 계속 표시
      }
      
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
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatValue(value, isCurrency: isCurrency),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isCurrency ? Theme.of(context).colorScheme.primary : null,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, {VoidCallback? onTap, bool useGrid = true}) {
    final isLarge = _isLargeScreen(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[600],
                  ),
              ],
            ),
          ),
        ),
        // 대형 화면: 그리드 형태로 표시 (한 줄에 3-4개), 작은 화면: 세로로 배치
        // 단, useGrid가 false이면 항상 세로 배치 (stock resumen 등)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: (isLarge && useGrid)
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    // 화면 크기에 따라 열 개수 결정 (최소 3개, 최대 4개)
                    final crossAxisCount = constraints.maxWidth > 1000 ? 4 : 3;
                    
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 3.5,
                      children: children,
                    );
                  },
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
        ),
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
            return DataCell(Text(
              _formatValue(value),
              style: const TextStyle(fontSize: 24),
            ));
          }).toList(),
        );
      }).toList();
    }

    // 단일 행인 경우
    return [
      DataRow(
        cells: tableData.values.map((value) {
          return DataCell(Text(
            _formatValue(value),
            style: const TextStyle(fontSize: 24),
          ));
        }).toList(),
      ),
    ];
  }

  // 큰 화면인지 확인 (macOS, Windows, iPad)
  bool _isLargeScreen(BuildContext context) {
    final platformType = PlatformUtils.getPlatformType(context);
    final size = MediaQuery.of(context).size;
    
    // 데스크톱 또는 iPad이고 화면이 충분히 큰 경우
    if (platformType == PlatformType.desktop || PlatformUtils.isIPad(context)) {
      return size.width >= 800 && size.height >= 600;
    }
    
    return false;
  }

  // 왼쪽 패널 빌드 (300px: 상단 보고서 목록, 하단 연결 관리)
  Widget _buildLeftPanel(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // 상단: 보고서 목록 (확장 시 작아짐)
          Expanded(
            flex: _isAddingNewConnection ? 3 : 5,
            child: Column(
              children: [
                // 보고서 헤더
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assessment, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reportes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 보고서 목록
                Expanded(
                  child: ListView(
                    children: _buildReportMenuItemsForPanel(context),
                  ),
                ),
              ],
            ),
          ),
          // 구분선
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          // 하단: 연결 관리 (확장 시 더 커짐)
          Expanded(
            flex: _isAddingNewConnection ? 7 : 5,
            child: _buildConnectionManagementPanel(context),
          ),
        ],
      ),
    );
  }

  // 연결 관리 패널 빌드
  Widget _buildConnectionManagementPanel(BuildContext context) {
    return Column(
      children: [
        // 연결 관리 헤더
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Row(
            children: [
              const Icon(Icons.storage, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '연결 관리',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 연결 관리 내용
        Expanded(
          child: _isAddingNewConnection
              ? _buildNewConnectionForm(context)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 저장된 연결 목록
                      if (_savedConnections.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.storage_outlined, size: 32, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  '저장된 연결이 없습니다',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._savedConnections.map((connection) {
                          final isCurrentConnection = connection.databaseName == _databaseName;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Card(
                              elevation: isCurrentConnection ? 2 : 1,
                              color: isCurrentConnection 
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                                  : Colors.white,
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                leading: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: isCurrentConnection
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[400],
                                  child: Icon(
                                    isCurrentConnection ? Icons.check_circle : Icons.storage,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                title: Text(
                                  connection.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: isCurrentConnection
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  connection.databaseName,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 16),
                                  onSelected: (value) {
                                    if (value == 'connect' && !isCurrentConnection) {
                                      _switchConnection(connection);
                                    } else if (value == 'delete') {
                                      _deleteConnectionFromList(connection);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (!isCurrentConnection)
                                      PopupMenuItem(
                                        value: 'connect',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.play_arrow, size: 16, color: Colors.green),
                                            const SizedBox(width: 8),
                                            const Text('연결', style: TextStyle(fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.delete, size: 16, color: Colors.red),
                                          const SizedBox(width: 8),
                                          const Text('삭제', style: TextStyle(fontSize: 11, color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  if (!isCurrentConnection) {
                                    _switchConnection(connection);
                                  }
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      const SizedBox(height: 8),
                      // 새 연결 추가 버튼
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isAddingNewConnection = true;
                            });
                          },
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('새 연결 추가', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 연결 끊기 버튼
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _disconnectAndGoToInitialScreen,
                          icon: const Icon(Icons.logout, color: Colors.orange, size: 14),
                          label: const Text('연결 끊기', style: TextStyle(color: Colors.orange, fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // 새 연결 입력 폼 빌드 (MainConnectionScreen과 동일한 구조)
  Widget _buildNewConnectionForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // 서버 URL 자동 생성
    void _updateServerUrl() {
      if (_newSelectedServerType == ServerType.hostinger) {
        _newServerUrlController.text = 'https://sync.coolsistema.com';
      } else if (_newLocalIpController.text.isNotEmpty) {
        _newServerUrlController.text = 'http://${_newLocalIpController.text}:3030';
      } else {
        _newServerUrlController.text = '';
      }
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (취소 버튼 포함)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() {
                    _isAddingNewConnection = false;
                    _newProfileNameController.clear();
                    _newServerUrlController.clear();
                    _newDatabaseNameController.clear();
                    _newUsernameController.clear();
                    _newPasswordController.clear();
                    _newLocalIpController.clear();
                    _newSelectedServerType = ServerType.hostinger;
                  });
                },
                tooltip: '취소',
              ),
              const Expanded(
                child: Text(
                  '새 연결 추가',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 프로필 이름
          TextField(
            controller: _newProfileNameController,
            decoration: InputDecoration(
              labelText: l10n.profileName,
              hintText: l10n.profileNameHint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person_outline, size: 18),
            ),
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 12),
          // 서버 타입 선택
          Text(
            l10n.serverType,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: RadioListTile<ServerType>(
                  title: const Text('Hostinger', style: TextStyle(fontSize: 11)),
                  value: ServerType.hostinger,
                  groupValue: _newSelectedServerType,
                  onChanged: (value) {
                    setState(() {
                      _newSelectedServerType = value!;
                      _updateServerUrl();
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<ServerType>(
                  title: const Text('Local IP', style: TextStyle(fontSize: 11)),
                  value: ServerType.local,
                  groupValue: _newSelectedServerType,
                  onChanged: (value) {
                    setState(() {
                      _newSelectedServerType = value!;
                      _updateServerUrl();
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 로컬 IP 입력 필드 (Local 선택 시)
          if (_newSelectedServerType == ServerType.local)
            TextField(
              controller: _newLocalIpController,
              decoration: InputDecoration(
                labelText: l10n.localIpAddress,
                hintText: l10n.localIpHint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.computer, size: 18),
              ),
              style: const TextStyle(fontSize: 11),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _updateServerUrl();
              },
            ),
          if (_newSelectedServerType == ServerType.local)
            const SizedBox(height: 8),
          // 서버 URL (자동 생성, 읽기 전용)
          TextField(
            controller: _newServerUrlController,
            decoration: InputDecoration(
              labelText: l10n.serverUrl,
              hintText: 'http://localhost:3000',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.link, size: 18),
            ),
            style: const TextStyle(fontSize: 11),
            readOnly: true,
            enabled: false,
          ),
          const SizedBox(height: 8),
          // 데이터베이스 이름
          TextField(
            controller: _newDatabaseNameController,
            decoration: InputDecoration(
              labelText: l10n.databaseName,
              helperText: l10n.alphanumericOnly,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.storage, size: 18),
            ),
            style: const TextStyle(fontSize: 11),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 8),
          // 사용자 이름과 비밀번호 (한 줄에)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newUsernameController,
                  decoration: InputDecoration(
                    labelText: l10n.username,
                    helperText: l10n.alphanumericOnly,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person, size: 18),
                  ),
                  style: const TextStyle(fontSize: 11),
                  keyboardType: TextInputType.text,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock, size: 18),
                  ),
                  style: const TextStyle(fontSize: 11),
                  obscureText: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 저장 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final profileName = _newProfileNameController.text.trim();
                final serverUrl = _newServerUrlController.text.trim();
                final databaseName = _newDatabaseNameController.text.trim();
                final username = _newUsernameController.text.trim();
                final password = _newPasswordController.text.trim();
                
                if (profileName.isEmpty || serverUrl.isEmpty || databaseName.isEmpty || 
                    username.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('모든 필드를 입력해주세요.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // 포트 번호 추출
                int port = 3030;
                final uri = Uri.tryParse(serverUrl);
                if (uri != null && uri.hasPort) {
                  port = uri.port;
                } else if (serverUrl.startsWith('https://')) {
                  port = 443;
                }
                
                // 연결 이름이 비어있으면 프로필 이름 사용
                String connectionName = profileName.isEmpty ? databaseName : profileName;
                
                final connection = ConnectionInfo(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: connectionName,
                  serverUrl: serverUrl,
                  databaseName: databaseName,
                  username: username,
                  password: password,
                  port: port,
                );
                
                try {
                  await _connectionStorageService.saveConnection(connection);
                  await _loadSavedConnections();
                  
                  setState(() {
                    _isAddingNewConnection = false;
                    _newProfileNameController.clear();
                    _newServerUrlController.clear();
                    _newDatabaseNameController.clear();
                    _newUsernameController.clear();
                    _newPasswordController.clear();
                    _newLocalIpController.clear();
                    _newSelectedServerType = ServerType.hostinger;
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('연결이 저장되었습니다.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('저장 실패: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save, size: 14),
              label: const Text('저장', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 취소 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isAddingNewConnection = false;
                  _newProfileNameController.clear();
                  _newServerUrlController.clear();
                  _newDatabaseNameController.clear();
                  _newUsernameController.clear();
                  _newPasswordController.clear();
                  _newLocalIpController.clear();
                  _newSelectedServerType = ServerType.hostinger;
                });
              },
              icon: const Icon(Icons.cancel, size: 14),
              label: const Text('취소', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 왼쪽 패널용 보고서 메뉴 아이템 빌드
  List<Widget> _buildReportMenuItemsForPanel(BuildContext context) {
    final items = <Widget>[];
    
    // Resumen del Día
    items.add(_buildReportMenuItem(
      context,
      'resumen',
      'Resumen del Día',
      Icons.today,
      Colors.blue,
    ));
    
    items.add(const Divider(height: 1));
    
    // Stocks
    items.add(_buildReportMenuItem(
      context,
      'stocks',
      'Stocks',
      Icons.warehouse,
      Colors.orange,
    ));
    
    // Codigos
    items.add(_buildReportMenuItem(
      context,
      'codigos',
      'Codigos',
      Icons.qr_code,
      Colors.teal,
    ));
    
    // Todo Codigos
    items.add(_buildReportMenuItem(
      context,
      'todocodigos',
      'Todo Codigos',
      Icons.qr_code_scanner,
      Colors.cyan,
    ));
    
    // Items
    items.add(_buildReportMenuItem(
      context,
      'items',
      'Items',
      Icons.inventory_2,
      Colors.green,
    ));
    
    return items;
  }

  // 보고서 메뉴 아이템 빌드
  Widget _buildReportMenuItem(
    BuildContext context,
    String reportType,
    String title,
    IconData icon,
    Color color,
  ) {
    final isSelected = _currentReport == reportType;
    
    return InkWell(
      onTap: () {
        setState(() {
          _currentReport = reportType;
          if (reportType == 'resumen') {
            _selectedReportType = null;
          } else {
            // ReportType으로 변환
            switch (reportType) {
              case 'stocks':
                _selectedReportType = ReportType.stocks;
                break;
              case 'codigos':
                _selectedReportType = ReportType.codigos;
                break;
              case 'todocodigos':
                _selectedReportType = ReportType.todocodigos;
                break;
              case 'items':
                _selectedReportType = ReportType.items;
                break;
              case 'clientes':
                _selectedReportType = ReportType.clientes;
                break;
              case 'gastos':
                _selectedReportType = ReportType.gastos;
                break;
              case 'ventas':
                _selectedReportType = ReportType.ventas;
                break;
              case 'alertas':
                _selectedReportType = ReportType.alertas;
                break;
              default:
                _selectedReportType = null;
            }
          }
        });
      },
      child: Container(
        color: isSelected ? color.withOpacity(0.1) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey[800],
                  fontSize: 13,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  // 보고서 내용 빌드 (오른쪽 영역)
  Widget _buildReportContent(BuildContext context) {
    if (_selectedReportType != null) {
      // 보고서 화면 표시
      // key를 reportType에 따라 설정하여 reportType 변경 시 새로운 위젯 인스턴스 생성
      return ReportScreen(
        key: ValueKey('report_${_selectedReportType.toString()}'),
        serverUrl: widget.serverUrl,
        reportType: _selectedReportType!,
        initialFilteringWord: widget.initialFilteringWord ?? _currentFilteringWord,
        initialSortColumn: widget.initialSortColumn ?? _currentSortColumn,
        initialSortAscending: widget.initialSortAscending ?? _currentSortAscending,
        initialItemsStartDate: widget.initialItemsStartDate ?? _currentItemsStartDate,
        initialItemsEndDate: widget.initialItemsEndDate ?? _currentItemsEndDate,
        onStateChanged: (filteringWord, sortColumn, sortAscending) {
          // 보고서 상태 변경 시 저장 (연결 변경 시 유지용)
          setState(() {
            _currentFilteringWord = filteringWord;
            _currentSortColumn = sortColumn;
            _currentSortAscending = sortAscending;
          });
        },
        onItemsDateRangeChanged: (startDate, endDate) {
          // Items 보고서 날짜 범위 변경 시 저장 (연결 변경 시 유지용)
          setState(() {
            _currentItemsStartDate = startDate;
            _currentItemsEndDate = endDate;
          });
        },
      );
    }
    
    // 기본 resumen del dia 내용 표시
    return _buildResumenContent(context);
  }

  // Resumen del Dia 내용 빌드
  Widget _buildResumenContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
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
          ],
        ),
      );
    }
    
    if (_data == null || _data!.isEmpty) {
      return Center(
        child: Text(l10n.noData),
      );
    }
    
    final platformType = PlatformUtils.getPlatformType(context);
    final maxWidth = PlatformUtils.getMaxWidth(
      context,
      mobileMaxWidth: double.infinity,
      tabletMaxWidth: 1200,
      desktopMaxWidth: 1600,
    );
    final padding = PlatformUtils.getPadding(
      context,
      mobilePadding: const EdgeInsets.all(16),
      tabletPadding: const EdgeInsets.all(24),
      desktopPadding: const EdgeInsets.all(32),
    );
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _hasMultipleSucursales()
              ? Padding(
                  padding: padding,
                  child: _buildComparisonView(l10n),
                )
              : SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 날짜 표시
                        if (_data!.containsKey('fecha'))
                          _buildDateHeader(_data!['fecha']),

                        // 판매 통계 (vcodes)
                        if (_data!.containsKey('vcodes'))
                          _buildSection(
                            l10n.salesStatistics,
                            _buildVcodesSection(
                              _data!['vcodes'] is List && (_data!['vcodes'] as List).isNotEmpty
                                  ? ((_data!['vcodes'] as List).first is Map<String, dynamic>
                                      ? (_data!['vcodes'] as List).first as Map<String, dynamic>
                                      : <String, dynamic>{})
                                  : (_data!['vcodes'] is Map<String, dynamic>
                                      ? _data!['vcodes'] as Map<String, dynamic>
                                      : <String, dynamic>{})
                            ),
                            onTap: () {
                              if (_isLargeScreen(context)) {
                                setState(() {
                                  _selectedReportType = ReportType.ventas;
                                  _currentReport = 'ventas';
                                });
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportScreen(
                                      serverUrl: widget.serverUrl,
                                      reportType: ReportType.ventas,
                                      initialDate: _selectedDate,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),

                        // 지출 통계 (gastos) - 대형 화면에서 그리드 형태로 표시
                        if (_data!.containsKey('gastos'))
                          _buildSection(
                            l10n.expenseStatistics,
                            _buildGastosSection(
                              _data!['gastos'] is List && (_data!['gastos'] as List).isNotEmpty
                                  ? ((_data!['gastos'] as List).first is Map<String, dynamic>
                                      ? (_data!['gastos'] as List).first as Map<String, dynamic>
                                      : <String, dynamic>{})
                                  : (_data!['gastos'] is Map<String, dynamic>
                                      ? _data!['gastos'] as Map<String, dynamic>
                                      : <String, dynamic>{})
                            ),
                            // useGrid: true (기본값) - 대형 화면에서 그리드 형태로 표시
                          ),

                        // 할인 통계 (vdetalle) - 대형 화면에서 그리드 형태로 표시
                        if (_data!.containsKey('vdetalle'))
                          _buildSection(
                            l10n.discountStatistics,
                            _buildVdetalleSection(
                              _data!['vdetalle'] is List && (_data!['vdetalle'] as List).isNotEmpty
                                  ? ((_data!['vdetalle'] as List).first is Map<String, dynamic>
                                      ? (_data!['vdetalle'] as List).first as Map<String, dynamic>
                                      : <String, dynamic>{})
                                  : (_data!['vdetalle'] is Map<String, dynamic>
                                      ? _data!['vdetalle'] as Map<String, dynamic>
                                      : <String, dynamic>{})
                            ),
                            // useGrid: true (기본값) - 대형 화면에서 그리드 형태로 표시
                          ),

                        // 결제 통계 (vcodes_mpago) - 대형 화면에서 그리드 형태로 표시
                        if (_data!.containsKey('vcodes_mpago'))
                          _buildSection(
                            l10n.mercadoPagoStatistics,
                            _buildMpagoSection(
                              _data!['vcodes_mpago'] is List && (_data!['vcodes_mpago'] as List).isNotEmpty
                                  ? ((_data!['vcodes_mpago'] as List).first is Map<String, dynamic>
                                      ? (_data!['vcodes_mpago'] as List).first as Map<String, dynamic>
                                      : <String, dynamic>{})
                                  : (_data!['vcodes_mpago'] is Map<String, dynamic>
                                      ? _data!['vcodes_mpago'] as Map<String, dynamic>
                                      : <String, dynamic>{})
                            ),
                            // useGrid: true (기본값) - 대형 화면에서 그리드 형태로 표시
                          ),

                        // Stock Resumen (stock_resumen 또는 stocks 키 확인)
                        // useGrid: false로 설정하여 자체 GridView 사용 (중복 방지)
                        if (_data!.containsKey('stock_resumen') || _data!.containsKey('stocks'))
                          _buildSection(
                            'Stock Resumen',
                            _buildStockResumenSection(
                              _data!.containsKey('stocks') 
                                ? {'stocks': _data!['stocks']}
                                : _data!['stock_resumen']
                            ),
                            useGrid: false,
                            onTap: () {
                              if (_isLargeScreen(context)) {
                                setState(() {
                                  _selectedReportType = ReportType.stocks;
                                  _currentReport = 'stocks';
                                });
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportScreen(
                                      serverUrl: widget.serverUrl,
                                      reportType: ReportType.stocks,
                                      initialDate: _selectedDate,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLargeScreen = _isLargeScreen(context);
    
    // 큰 화면인 경우 분할 레이아웃
    if (isLargeScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              if (_databaseName != null && _databaseName!.isNotEmpty)
                Container(
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
                      const Icon(Icons.storage, color: Colors.white, size: 14),
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
                    ],
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
                  if (value == 'resumen') {
                    _selectedReportType = null;
                  } else {
                    // ReportType으로 변환
                    switch (value) {
                      case 'stocks':
                        _selectedReportType = ReportType.stocks;
                        break;
                      case 'codigos':
                        _selectedReportType = ReportType.codigos;
                        break;
                      case 'todocodigos':
                        _selectedReportType = ReportType.todocodigos;
                        break;
                      case 'items':
                        _selectedReportType = ReportType.items;
                        break;
                      case 'clientes':
                        _selectedReportType = ReportType.clientes;
                        break;
                      case 'gastos':
                        _selectedReportType = ReportType.gastos;
                        break;
                      case 'ventas':
                        _selectedReportType = ReportType.ventas;
                        break;
                      case 'alertas':
                        _selectedReportType = ReportType.alertas;
                        break;
                      default:
                        _selectedReportType = null;
                    }
                  }
                });
              },
              itemBuilder: (BuildContext context) => _buildReportMenuItems(),
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Row(
          children: [
            // 왼쪽: 연결 관리 + 보고서 종류 패널 (300px 고정)
            _buildLeftPanel(context),
            // 오른쪽: 항상 결과 표시
            Expanded(
              child: _buildReportContent(context),
            ),
          ],
        ),
      );
    }
    
    // 핸드폰: 기존 방식 유지
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
                        final platformType = PlatformUtils.getPlatformType(context);
                        final maxWidth = PlatformUtils.getMaxWidth(
                          context,
                          mobileMaxWidth: double.infinity,
                          tabletMaxWidth: 1200,
                          desktopMaxWidth: 1600,
                        );
                        final padding = PlatformUtils.getPadding(
                          context,
                          mobilePadding: const EdgeInsets.all(16),
                          tabletPadding: const EdgeInsets.all(24),
                          desktopPadding: const EdgeInsets.all(32),
                        );
                        
                        return RefreshIndicator(
                          onRefresh: _loadData,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxWidth),
                              child: _hasMultipleSucursales()
                                  ? Padding(
                                      padding: padding,
                                      child: _buildComparisonView(l10n),
                                    )
                                  : SingleChildScrollView(
                                      child: Container(
                                        width: double.infinity,
                                        padding: padding,
                                        child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // 날짜 표시
                                        if (_data!.containsKey('fecha'))
                                          _buildDateHeader(_data!['fecha']),

                                        // 판매 통계 (vcodes) - 배열이면 첫 번째 항목 사용
                                        if (_data!.containsKey('vcodes'))
                                          _buildSection(
                                            l10n.salesStatistics,
                                            _buildVcodesSection(
                                              _data!['vcodes'] is List && (_data!['vcodes'] as List).isNotEmpty
                                                  ? ((_data!['vcodes'] as List).first is Map<String, dynamic>
                                                      ? (_data!['vcodes'] as List).first as Map<String, dynamic>
                                                      : <String, dynamic>{})
                                                  : (_data!['vcodes'] is Map<String, dynamic>
                                                      ? _data!['vcodes'] as Map<String, dynamic>
                                                      : <String, dynamic>{})
                                            ),
                                            onTap: () {
                                              // 해당 날짜의 venta lista를 요청하는 화면으로 이동
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ReportScreen(
                                                    serverUrl: widget.serverUrl,
                                                    reportType: ReportType.ventas,
                                                    initialDate: _selectedDate,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),

                                        // 지출 통계 (gastos) - 대형 화면에서 그리드 형태로 표시
                                        if (_data!.containsKey('gastos'))
                                          _buildSection(
                                            l10n.expenseStatistics,
                                            _buildGastosSection(
                                              _data!['gastos'] is List && (_data!['gastos'] as List).isNotEmpty
                                                  ? ((_data!['gastos'] as List).first is Map<String, dynamic>
                                                      ? (_data!['gastos'] as List).first as Map<String, dynamic>
                                                      : <String, dynamic>{})
                                                  : (_data!['gastos'] is Map<String, dynamic>
                                                      ? _data!['gastos'] as Map<String, dynamic>
                                                      : <String, dynamic>{})
                                            ),
                                            // useGrid: true (기본값) - 대형 화면에서 그리드 형태로 표시
                                          ),

                                        // 할인 통계 (vdetalle) - 대형 화면에서 그리드 형태로 표시
                                        if (_data!.containsKey('vdetalle'))
                                          _buildSection(
                                            l10n.discountStatistics,
                                            _buildVdetalleSection(
                                              _data!['vdetalle'] is List && (_data!['vdetalle'] as List).isNotEmpty
                                                  ? ((_data!['vdetalle'] as List).first is Map<String, dynamic>
                                                      ? (_data!['vdetalle'] as List).first as Map<String, dynamic>
                                                      : <String, dynamic>{})
                                                  : (_data!['vdetalle'] is Map<String, dynamic>
                                                      ? _data!['vdetalle'] as Map<String, dynamic>
                                                      : <String, dynamic>{})
                                            ),
                                            // useGrid: true (기본값) - 대형 화면에서 그리드 형태로 표시
                                          ),

                                        // 결제 통계 (vcodes_mpago) - 대형 화면에서 그리드 형태로 표시
                                        if (_data!.containsKey('vcodes_mpago'))
                                          _buildSection(
                                            l10n.mercadoPagoStatistics,
                                            _buildMpagoSection(
                                              _data!['vcodes_mpago'] is List && (_data!['vcodes_mpago'] as List).isNotEmpty
                                                  ? ((_data!['vcodes_mpago'] as List).first is Map<String, dynamic>
                                                      ? (_data!['vcodes_mpago'] as List).first as Map<String, dynamic>
                                                      : <String, dynamic>{})
                                                  : (_data!['vcodes_mpago'] is Map<String, dynamic>
                                                      ? _data!['vcodes_mpago'] as Map<String, dynamic>
                                                      : <String, dynamic>{})
                                            ),
                                            // useGrid: true (기본값) - 대형 화면에서 그리드 형태로 표시
                                          ),

                                        // Stock Resumen (stock_resumen 또는 stocks 키 확인)
                                        // useGrid: false로 설정하여 자체 GridView 사용 (중복 방지)
                                        if (_data!.containsKey('stock_resumen') || _data!.containsKey('stocks'))
                                          _buildSection(
                                            'Stock Resumen',
                                            _buildStockResumenSection(
                                              _data!.containsKey('stocks') 
                                                ? {'stocks': _data!['stocks']}
                                                : _data!['stock_resumen']
                                            ),
                                            useGrid: false,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ReportScreen(
                                                    serverUrl: widget.serverUrl,
                                                    reportType: ReportType.stocks,
                                                    initialDate: _selectedDate,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Fecha: $fecha',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
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
        'Evento de Venta',
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
    
    if (vcodes.containsKey('last_venta_hour')) {
      final lastVentaHour = vcodes['last_venta_hour'];
      String formattedTime = '';
      if (lastVentaHour != null) {
        try {
          // ISO 8601 형식의 날짜 문자열 파싱
          final dateTime = DateTime.parse(lastVentaHour.toString());
          formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
        } catch (e) {
          formattedTime = lastVentaHour.toString();
        }
      }
      cards.add(_buildDataCard(
        'Última Venta',
        formattedTime,
        Icons.access_time,
      ));
    }

    return cards;
  }

  List<Widget> _buildGastosSection(Map<String, dynamic> gastos) {
    final cards = <Widget>[];
    
    if (gastos.containsKey('gasto_count')) {
      cards.add(_buildDataCard(
        'Evento de Gastos',
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
        'Evento de Descuento',
        vdetalle['total_discount_day'],
        Icons.discount,
        isCurrency: true,
      ));
    }

    return cards;
  }

  List<Widget> _buildStockResumenSection(Map<String, dynamic> stockResumen) {
    final cards = <Widget>[];
    
    // Stocks 배열이 있는 경우 (resumen del dia 응답의 stocks 배열)
    if (stockResumen.containsKey('stocks') && stockResumen['stocks'] is List) {
      final stocksList = stockResumen['stocks'] as List;
      
      if (stocksList.isNotEmpty) {
        // 각 sucursal별로 카드 생성
        for (var stock in stocksList) {
          if (stock is Map<String, dynamic>) {
            final sucursalValue = stock['sucursal'];
            final sucursal = sucursalValue?.toString() ?? 'N/A';
            
            // sucursal이 1 미만이거나 N/A인 경우 제외
            if (sucursal == 'N/A') {
              continue;
            }
            
            // 숫자로 변환하여 1 미만인지 확인
            final sucursalNum = sucursalValue is num 
                ? sucursalValue 
                : (sucursalValue is String ? int.tryParse(sucursalValue) : null);
            
            if (sucursalNum == null || sucursalNum < 1) {
              continue;
            }
            
            final itemCount = stock['item_count'] ?? 0;
            final tVentas = stock['tVentas'] ?? 0.0;
            final tIngresos = stock['tIngresos'] ?? 0.0;
            final tOffset = stock['tOffset'] ?? 0.0;
            final hVentas = stock['hVentas'] ?? 0.0;
            final hIngresos = stock['hIngresos'] ?? 0.0;
            final finalStock = stock['finalStock'] ?? 0.0;
            
            cards.add(
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sucursal 헤더
                      Row(
                        children: [
                          Icon(
                            Icons.store,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sucursal $sucursal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // 데이터 그리드 (수평으로 적당히 나눠서 표시)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // 화면 크기에 따라 열 개수 결정 (작은 화면: 1개, 중간: 2개, 큰 화면: 3-4개)
                          final crossAxisCount = constraints.maxWidth > 800 
                              ? 4 
                              : constraints.maxWidth > 600 
                                  ? 3 
                                  : constraints.maxWidth > 400
                                      ? 2
                                      : 1; // 핸드폰처럼 좁은 경우 1개 (전체 폭 차지)
                          
                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: crossAxisCount == 1 ? 3.5 : 3.0, // 높이를 키우기 위해 값 감소
                            children: [
                              _buildStockDataItem('Item Count', itemCount.toString(), Icons.inventory_2),
                              _buildStockDataItem('Total Ventas', _formatValue(tVentas, isCurrency: true), Icons.shopping_cart),
                              _buildStockDataItem('Total Ingresos', _formatValue(tIngresos, isCurrency: true), Icons.trending_up),
                              _buildStockDataItem('Total Offset', _formatValue(tOffset, isCurrency: true), Icons.swap_horiz),
                              _buildStockDataItem('Hoy Ventas', _formatValue(hVentas, isCurrency: true), Icons.today),
                              _buildStockDataItem('Hoy Ingresos', _formatValue(hIngresos, isCurrency: true), Icons.arrow_upward),
                              _buildStockDataItem('Final Stock', _formatValue(finalStock), Icons.warehouse),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }
      }
    }
    
    // Stock resumen 데이터 구조에 따라 표시 (기존 로직)
    if (stockResumen.containsKey('summary')) {
      final summary = stockResumen['summary'];
      if (summary is Map<String, dynamic>) {
        // 총 아이템 수
        if (summary.containsKey('total_items')) {
          cards.add(_buildDataCard(
            'Total Items',
            summary['total_items'].toString(),
            Icons.inventory_2,
          ));
        }
        
        // 총 재고량
        if (summary.containsKey('total_stock')) {
          cards.add(_buildDataCard(
            'Total Stock',
            _formatValue(summary['total_stock']),
            Icons.warehouse,
          ));
        }
        
        // 총 판매량
        if (summary.containsKey('total_venta')) {
          cards.add(_buildDataCard(
            'Total Venta',
            _formatValue(summary['total_venta']),
            Icons.shopping_cart,
          ));
        }
      }
    }
    
    // 데이터가 없으면 기본 메시지 표시
    if (cards.isEmpty) {
      cards.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Stock resumen 데이터가 없습니다.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    
    return cards;
  }

  Widget _buildStockDataItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: Colors.grey[600]),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMpagoSection(Map<String, dynamic> mpago) {
    final cards = <Widget>[];
    
    if (mpago.containsKey('count_mpago_total')) {
      cards.add(_buildDataCard(
        'Evento de MPago',
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

  // 여러 sucursal 데이터가 있는지 확인 (실제로 2개 이상일 때만 비교 테이블 표시)
  bool _hasMultipleSucursales() {
    if (_data == null) return false;
    
    // vcodes가 배열인 경우 - 실제 sucursal 개수 확인
    if (_data!.containsKey('vcodes') && _data!['vcodes'] is List) {
      final vcodesList = _data!['vcodes'] as List;
      if (vcodesList.isNotEmpty && vcodesList.first is Map) {
        // 고유한 sucursal 개수 확인
        final sucursales = <int>{};
        for (var item in vcodesList) {
          if (item is Map && item.containsKey('sucursal')) {
            final sucursal = item['sucursal'] is int 
                ? item['sucursal'] as int 
                : int.tryParse(item['sucursal'].toString()) ?? 0;
            if (sucursal > 0) {
              sucursales.add(sucursal);
            }
          }
        }
        // 2개 이상일 때만 비교 테이블 표시
        return sucursales.length > 1;
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

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
        ),
      ),
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
        'vcodes_operation_count': 'Evento de Venta',
        'vcodes_total_venta_day': 'Total de Ventas',
        'vcodes_total_efectivo_day': 'Ventas en Efectivo',
        'vcodes_total_credito_day': 'Ventas a Crédito',
        'vcodes_total_banco_day': 'Ventas Bancarias',
        'vcodes_total_favor_day': 'Ventas Favor',
        'vcodes_total_count_ropas': 'Total de Ropas',
        'vcodes_last_venta_hour': 'Última Venta',
        'gastos_gasto_count': 'Evento de Gastos',
        'gastos_total_gasto_day': 'Total de Gastos',
        'vdetalle_count_discount_event': 'Eventos de Descuento',
        'vdetalle_total_discount_day': 'Evento de Descuento',
        'mpago_count_mpago_total': 'Evento de MPago',
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
                // last_venta_hour 필드는 날짜/시간 형식으로 포맷팅
                if (key == 'last_venta_hour' && value != null) {
                  try {
                    final dateTime = DateTime.parse(value.toString());
                    value = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
                  } catch (e) {
                    // 파싱 실패 시 원본 값 유지
                  }
                }
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
                    fontSize: 24,
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
        thumbVisibility: false,
        trackVisibility: false,
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
        value: 'codigos',
        child: Row(
          children: [
            Icon(
              Icons.qr_code,
              color: _currentReport == 'codigos' ? Colors.teal : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Codigos',
              style: TextStyle(
                fontWeight: _currentReport == 'codigos' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (_currentReport == 'codigos') ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.teal, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'todocodigos',
        child: Row(
          children: [
            Icon(
              Icons.qr_code_scanner,
              color: _currentReport == 'todocodigos' ? Colors.cyan : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Todo Codigos',
              style: TextStyle(
                fontWeight: _currentReport == 'todocodigos' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (_currentReport == 'todocodigos') ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.cyan, size: 18),
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
        enabled: false,
        child: Row(
          children: [
            Icon(
              Icons.people,
              color: Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Clientes',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'gastos',
        enabled: false,
        child: Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Gastos',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'ventas',
        enabled: false,
        child: Row(
          children: [
            Icon(
              Icons.shopping_cart,
              color: Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Ventas',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'alertas',
        enabled: false,
        child: Row(
          children: [
            Icon(
              Icons.notifications,
              color: Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Alertas',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // 보고서로 이동하는 메서드
  void _navigateToReport(String reportType) {
    // 현재 보고서는 아무것도 하지 않음
    if (reportType == 'resumen') {
      if (_isLargeScreen(context)) {
        setState(() {
          _selectedReportType = null;
        });
      }
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
      case 'codigos':
        reportTypeEnum = ReportType.codigos;
        break;
      case 'todocodigos':
        reportTypeEnum = ReportType.todocodigos;
        break;
      default:
        return;
    }

    // 큰 화면인 경우 오른쪽 패널에 보고서 표시
    if (_isLargeScreen(context)) {
      setState(() {
        _selectedReportType = reportTypeEnum;
      });
    } else {
      // 핸드폰: 기존 방식 (Navigator.push)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportScreen(
            serverUrl: widget.serverUrl,
            reportType: reportTypeEnum,
          ),
        ),
      ).then((_) {
        // 뒤로 돌아왔을 때 _currentReport를 'resumen'으로 설정
        if (mounted) {
          setState(() {
            _currentReport = 'resumen';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _newProfileNameController.dispose();
    _newServerUrlController.dispose();
    _newDatabaseNameController.dispose();
    _newUsernameController.dispose();
    _newPasswordController.dispose();
    _newLocalIpController.dispose();
    super.dispose();
  }
}



