import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../services/connection_storage_service.dart';
import '../services/secure_storage_helper.dart';
import '../services/config_service.dart';
import '../models/connection_info.dart';
import '../utils/platform_utils.dart';
import '../widgets/report_utils.dart';
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
  String? _selectedSucursal; // null = Total, "1" = Sucursal 1, "2" = Sucursal 2 등
  String? _databaseName;
  List<String>? _availableSucursales; // 사용 가능한 sucursal 목록
  String _currentReport = 'resumen'; // 현재 선택된 보고서
  ReportType? _selectedReportType; // 큰 화면에서 오른쪽에 표시할 보고서 타입
  // 현재 보고서의 필터링 단어와 정렬 정보 (연결 변경 시 유지용)
  String? _currentFilteringWord;
  String? _currentSortColumn;
  bool? _currentSortAscending;
  // Items 보고서의 날짜 범위 정보 (연결 변경 시 유지용)
  DateTime? _currentItemsStartDate;
  DateTime? _currentItemsEndDate;
  // Ventas 보고서의 descontado 필터 (할인 통계 카드 클릭 시 사용)
  bool? _currentVentasDescontado;
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
        case ReportType.ingresos:
          _currentReport = 'ingresos';
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
        case ReportType.fventas:
          _currentReport = 'fventas';
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

      // 연결 변경 시 기존 캐시 초기화
      service.clearTiposTemporadasCache();

      final success = await service.connectToDatabase(request);
      
      // 데이터베이스 연결 성공 시 tipos와 temporadas 새로 로드
      if (success) {
        try {
          final tipos = await service.getTipos(forceRefresh: true);
          final temporadas = await service.getTemporadas(forceRefresh: true);
        } catch (e) {
          print('⚠️ Tipos/Temporadas 로드 실패 (계속 진행): $e');
        }
      }

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
      print('   - 날짜: $dateToUse');
      print('   - Sucursal: ${sucursal ?? _selectedSucursal ?? "없음"}');
      
      Map<String, dynamic> data;
      try {
        data = await _databaseService.getResumenDelDia(
          date: dateToUse,
          sucursal: sucursal ?? _selectedSucursal,
        );
        print('   - 응답 키: ${data.keys.toList()}');
        print('   - 응답 데이터 상세:');
        data.forEach((key, value) {
          if (value is List) {
            print('     - $key: List (${value.length}개 항목)');
            if (value.isNotEmpty) {
              print('       첫 번째 항목: ${value[0]}');
            }
          } else if (value is Map) {
            print('     - $key: Map (${(value as Map).keys.toList()})');
          } else {
            print('     - $key: ${value.runtimeType} = $value');
          }
        });
        
        // resumen del dia 응답에 stocks 데이터가 직접 포함되어 있는지 확인
        if (data.containsKey('stocks') && data['stocks'] is List) {
          final stocksList = data['stocks'] as List;
          // stock_resumen도 함께 설정
          if (!data.containsKey('stock_resumen')) {
            data['stock_resumen'] = {'stocks': stocksList};
          }
        }
      } catch (e) {
        print('❌ getResumenDelDia 실패: $e');
        rethrow; // 에러를 다시 던져서 catch 블록에서 처리하도록
      }
      
      // 응답 데이터에 에러 메시지가 포함되어 있는지 확인
      if (data is Map<String, dynamic>) {
        // 에러 메시지 필드 확인
        final errorFields = ['error', 'message', '오류', '에러'];
        for (final field in errorFields) {
          if (data.containsKey(field)) {
            final errorValue = data[field];
            if (errorValue != null && errorValue.toString().isNotEmpty) {
              final errorStr = errorValue.toString().toLowerCase();
              // 게이트웨이 오류나 서버 오류인 경우
              if (errorStr.contains('게이트웨이') || 
                  errorStr.contains('bad gateway') ||
                  errorStr.contains('서버 오류')) {
                print('⚠️ 응답 데이터에 에러 메시지 포함: $errorValue');
                throw Exception(errorValue.toString());
              }
            }
          }
        }
        
        // 데이터가 비어있거나 에러 메시지만 있는 경우 확인
        if (data.isEmpty || (data.length == 1 && data.values.first.toString().toLowerCase().contains('오류'))) {
          print('⚠️ 응답 데이터가 비어있거나 에러 메시지만 포함되어 있습니다.');
        }
      }
      
      // Stock resumen도 함께 가져오기 (stocks GET 요청에서 resumen_del_dia 포함)
      try {
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
          } else if (stockResumen.containsKey('stocks') && stockResumen['stocks'] is List) {
            // 기존 형식 지원 (하위 호환성)
            final stocksList = stockResumen['stocks'] as List;
            data['stock_resumen'] = stockResumen;
            data['stocks'] = stocksList;
          } else {
            data['stock_resumen'] = stockResumen;
          }
        }
      } catch (e) {
        // Stock resumen 가져오기 실패해도 resumen del dia는 계속 표시
      }
      
      // 사용 가능한 sucursal 목록 추출
      final availableSucursales = _extractAvailableSucursales(data);
      
      setState(() {
        _data = data;
        _isLoading = false;
        _errorMessage = null;
        // 사용된 날짜로 업데이트 (명확하게 보장)
        _selectedDate = dateToUse;
        if (sucursal != null) {
          _selectedSucursal = sucursal;
        }
        // 사용 가능한 sucursal 목록 업데이트
        _availableSucursales = availableSucursales;
        // 여러 sucursal이 있고 아직 선택되지 않았으면 Total로 설정
        if (_availableSucursales != null && _availableSucursales!.isNotEmpty && _selectedSucursal == null) {
          _selectedSucursal = null; // Total (null = Total)
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
          // 에러가 발생해도 이전 데이터가 있으면 유지 (사용자가 이전 데이터를 볼 수 있도록)
          // _data는 null로 유지하지 않고, 에러 메시지만 설정
          _errorMessage = errorMessage;
          // _data가 null이면 이전 데이터가 없으므로 null 유지
          // _data가 있으면 이전 데이터 유지 (에러 메시지와 함께 표시)
        });
        print('❌ resumen_del_dia 오류: $errorMessage');
        print('   - 이전 데이터 유지: ${_data != null ? "예 (${_data!.keys.length}개 키)" : "아니오"}');
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

  Widget _buildDataCard(String title, dynamic value, IconData icon, {bool isCurrency = false, VoidCallback? onTap}) {
    final isLarge = _isLargeScreen(context);
    // 큰 화면에서는 글자 크기를 2배의 2/3 수준으로 (약 1.33배)
    final titleFontSize = isLarge ? (10.0 * 2 * 2 / 3) : 10.0; // 약 13.3px
    final valueFontSize = isLarge ? (16.0 * 2 * 2 / 3) : 16.0; // 약 21.3px
    final iconSize = isLarge ? (20.0 * 2 * 2 / 3) : 20.0; // 약 26.7px
    final padding = isLarge ? (12.0 * 2 * 2 / 3) : 12.0; // 약 16px
    final iconPadding = isLarge ? (10.0 * 2 * 2 / 3) : 10.0; // 약 13.3px
    final spacing = isLarge ? (2.0 * 2 * 2 / 3) : 2.0; // 약 2.7px
    
    Widget cardContent = Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: iconSize,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: spacing),
                    Text(
                      _formatValue(value, isCurrency: isCurrency),
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: isCurrency ? Theme.of(context).colorScheme.primary : null,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: cardContent,
      );
    }
    
    return cardContent;
  }

  Widget _buildSection(String title, List<Widget> children, {VoidCallback? onTap, bool useGrid = true}) {
    // 빈 리스트인 경우 섹션을 표시하지 않음
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    
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
                    // 큰 화면에서 두 섹션이 나란히 있을 때를 고려하여 최소 너비 보장
                    final availableWidth = constraints.maxWidth;
                    // 카드 하나당 최소 너비를 고려 (약 250px)
                    final minCardWidth = 250.0;
                    final maxCrossAxisCount = (availableWidth / minCardWidth).floor();
                    final crossAxisCount = maxCrossAxisCount >= 4 ? 4 : (maxCrossAxisCount >= 3 ? 3 : 2);
                    
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.8,
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

  // 왼쪽 패널 빌드 (200px: 상단 보고서 목록, 하단 연결 관리)
  Widget _buildLeftPanel(BuildContext context, {bool forDrawer = false}) {
    final content = Column(
        children: [
          // 상단: 보고서 목록 (더 크게)
          Expanded(
            flex: _isAddingNewConnection ? 3 : 7,
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
          // 하단: 연결 관리 (2/3 수준으로 작게)
          Expanded(
            flex: _isAddingNewConnection ? 7 : 3,
            child: _buildConnectionManagementPanel(context),
          ),
        ],
    );
    
    // Drawer용일 때는 Container 없이 내용만 반환
    if (forDrawer) {
      return content;
    }
    
    // 일반 패널용일 때는 Container로 감싸서 반환
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: content,
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
                                    } else if (value == 'edit') {
                                      Navigator.push<ConnectionInfo>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ConnectionScreen(
                                            connection: connection,
                                          ),
                                        ),
                                      ).then((savedConnection) {
                                        if (mounted) {
                                          _loadSavedConnections();
                                        }
                                      });
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
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit, size: 16, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          const Text('편집', style: TextStyle(fontSize: 11)),
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
                              // 새 연결 폼 초기화
                              _newProfileNameController.clear();
                              _newServerUrlController.clear();
                              _newDatabaseNameController.clear();
                              _newUsernameController.clear();
                              _newPasswordController.clear();
                              _newLocalIpController.clear();
                              _newSelectedServerType = ServerType.hostinger;
                              // Hostinger 선택 시 URL 자동 설정
                              _newServerUrlController.text = 'https://sync.coolsistema.com';
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
    
    // Ventas
    items.add(_buildReportMenuItem(
      context,
      'ventas',
      'Ventas',
      Icons.shopping_cart,
      Colors.purple,
    ));
    
    // FVentas
    items.add(_buildReportMenuItem(
      context,
      'fventas',
      'FVentas',
      Icons.receipt,
      Colors.deepPurple,
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
    
    // Ingresos
    items.add(_buildReportMenuItem(
      context,
      'ingresos',
      'Ingresos',
      Icons.trending_up,
      Colors.indigo,
    ));
    
    // Gastos
    items.add(_buildReportMenuItem(
      context,
      'gastos',
      'Gastos',
      Icons.receipt_long,
      Colors.red,
    ));
    
    // Clientes
    items.add(_buildReportMenuItem(
      context,
      'clientes',
      'Clientes',
      Icons.people,
      Colors.purple,
    ));
    
    // Alertas
    items.add(_buildReportMenuItem(
      context,
      'alertas',
      'Alertas',
      Icons.notifications,
      Colors.orange,
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
        _navigateToReport(reportType);
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
    debugPrint('🔍 _buildReportContent 호출: _selectedReportType=$_selectedReportType, _currentReport=$_currentReport');
    if (_selectedReportType != null) {
      debugPrint('   → ReportScreen 반환: reportType=$_selectedReportType');
      // 보고서 화면 표시
      // key를 reportType과 필터 상태에 따라 설정하여 reportType 변경 시 새로운 위젯 인스턴스 생성
      debugPrint('🔍 _buildReportContent: _selectedReportType=$_selectedReportType, _currentVentasDescontado=$_currentVentasDescontado');
      return ReportScreen(
        key: ValueKey('report_${_selectedReportType.toString()}_descontado_${_currentVentasDescontado ?? false}_date_${_selectedDate?.toString() ?? 'null'}'),
        serverUrl: widget.serverUrl,
        reportType: _selectedReportType!,
        initialDate: (_selectedReportType == ReportType.ventas || _selectedReportType == ReportType.fventas) ? (_selectedDate ?? DateTime.now()) : null,
        initialFilteringWord: widget.initialFilteringWord ?? _currentFilteringWord,
        initialSortColumn: widget.initialSortColumn ?? _currentSortColumn,
        initialSortAscending: widget.initialSortAscending ?? _currentSortAscending,
        initialItemsStartDate: (_selectedReportType == ReportType.gastos || _selectedReportType == ReportType.items || _selectedReportType == ReportType.ingresos) 
            ? (_selectedDate ?? widget.initialItemsStartDate ?? _currentItemsStartDate)
            : (widget.initialItemsStartDate ?? _currentItemsStartDate),
        initialItemsEndDate: (_selectedReportType == ReportType.gastos || _selectedReportType == ReportType.items || _selectedReportType == ReportType.ingresos)
            ? (_selectedDate ?? widget.initialItemsEndDate ?? _currentItemsEndDate)
            : (widget.initialItemsEndDate ?? _currentItemsEndDate),
        initialVentasDescontado: _currentVentasDescontado,
        useFullWidth: true, // resumen del dia에서 사용 시 전체 너비 사용
        onMenuPressed: !_isLargeScreen(context) ? () {
          // 좁은 화면일 때 Drawer 열기
          Scaffold.of(context).openDrawer();
        } : null,
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
    
    debugPrint('🔍 _buildResumenContent 호출됨');
    debugPrint('   - _isLoading: $_isLoading');
    debugPrint('   - _errorMessage: $_errorMessage');
    debugPrint('   - _data: ${_data != null ? "${_data!.keys.toList()}" : "null"}');
    
    if (_isLoading) {
      debugPrint('   → 로딩 상태 반환');
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
    
    if (_errorMessage != null && _data == null) {
      // 에러가 있고 데이터가 없을 때만 에러 화면 표시
      debugPrint('   → 에러 상태 반환 (데이터 없음): $_errorMessage');
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
    
    // 에러가 있지만 데이터도 있는 경우: 데이터를 표시하고 경고 메시지 추가
    if (_errorMessage != null && _data != null && _data!.isNotEmpty) {
      debugPrint('   → 에러 있지만 이전 데이터 표시: $_errorMessage');
      // 아래에서 데이터를 표시하되, 상단에 경고 배너 추가
    }
    
    if (_data == null || _data!.isEmpty) {
      debugPrint('   → 데이터 없음 반환');
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
    
    // 여러 sucursal이 있어도 각 섹션을 개별 카드로 표시 (비교 테이블 대신)
    debugPrint('   → Resumen del Dia 섹션 뷰 렌더링 (항상 섹션 형태로 표시)');
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Builder(
                  builder: (context) {
                    debugPrint('   → 단일 sucursal 뷰 렌더링');
                    // 안전한 데이터 접근 (디버깅용)
                    if (_data!.containsKey('vcodes')) {
                      final vcodesData = _data!['vcodes'];
                      debugPrint('   - vcodes 데이터 타입: ${vcodesData.runtimeType}');
                      if (vcodesData is List) {
                        debugPrint('   - vcodes List 길이: ${vcodesData.length}');
                      }
                    }
                    
                    return SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: padding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 날짜 선택 버튼 (맨 윗줄)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _selectDate,
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(
                                      _selectedDate != null
                                          ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                                          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      backgroundColor: Colors.blue[700],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 에러가 있지만 데이터도 있는 경우 경고 배너 표시
                            if (_errorMessage != null && _data != null && _data!.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  border: Border.all(color: Colors.orange[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '데이터를 새로고침하는 중 오류가 발생했습니다. 이전 데이터를 표시합니다.',
                                        style: TextStyle(color: Colors.orange[900], fontSize: 12),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _loadData,
                                      child: const Text('다시 시도', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                            // 날짜 표시는 AppBar에 있으므로 본문에서는 제거

                            // 판매 통계 (vcodes) - 여러 sucursal이 있으면 합산
                            if (_data!.containsKey('vcodes')) ...[
                              Builder(
                                builder: (context) {
                                  final aggregatedVcodes = _getAggregatedVcodes();
                                  final vcodesWidgets = _buildVcodesSection(aggregatedVcodes);
                                  
                                  if (vcodesWidgets.isNotEmpty) {
                                    return _buildSection(
                                      l10n.salesStatistics,
                                      vcodesWidgets,
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
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                              ),
                            ],

                        // 지출 통계 (gastos)와 할인 통계 (vdetalle) - 큰 화면에서는 1줄에 배치
                        Builder(
                          builder: (context) {
                            final isLarge = _isLargeScreen(context);
                            final hasGastos = _data!.containsKey('gastos');
                            final hasVdetalle = _data!.containsKey('vdetalle');
                            
                            // 둘 다 없으면 빈 위젯 반환
                            if (!hasGastos && !hasVdetalle) {
                              return const SizedBox.shrink();
                            }
                            
                            // 큰 화면: Row로 1줄에 배치
                            if (isLarge) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 지출 통계 (gastos)
                                  if (hasGastos)
                                    Flexible(
                                      flex: 1,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(minWidth: 400),
                                        child: Builder(
                                          builder: (context) {
                                            final aggregatedGastos = _getAggregatedGastos();
                                            final gastosWidgets = _buildGastosSection(aggregatedGastos);
                                            
                                            if (gastosWidgets.isNotEmpty) {
                                              return _buildSection(
                                                l10n.expenseStatistics,
                                                gastosWidgets,
                                              );
                                            } else {
                                              return const SizedBox.shrink();
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  if (hasGastos && hasVdetalle)
                                    const SizedBox(width: 16),
                                  // 할인 통계 (vdetalle)
                                  if (hasVdetalle)
                                    Flexible(
                                      flex: 1,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(minWidth: 400),
                                        child: Builder(
                                          builder: (context) {
                                            final aggregatedVdetalle = _getAggregatedVdetalle();
                                            final vdetalleWidgets = _buildVdetalleSection(aggregatedVdetalle);
                                            
                                            if (vdetalleWidgets.isNotEmpty) {
                                              return _buildSection(
                                                l10n.discountStatistics,
                                                vdetalleWidgets,
                                              );
                                            } else {
                                              return const SizedBox.shrink();
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            }
                            
                            // 작은 화면: 기존대로 세로로 배치
                            return Column(
                              children: [
                                // 지출 통계 (gastos)
                                if (hasGastos)
                                  Builder(
                                    builder: (context) {
                                      final aggregatedGastos = _getAggregatedGastos();
                                      final gastosWidgets = _buildGastosSection(aggregatedGastos);
                                      
                                      if (gastosWidgets.isNotEmpty) {
                                        return _buildSection(
                                          l10n.expenseStatistics,
                                          gastosWidgets,
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  ),
                                // 할인 통계 (vdetalle)
                                if (hasVdetalle)
                                  Builder(
                                    builder: (context) {
                                      final aggregatedVdetalle = _getAggregatedVdetalle();
                                      final vdetalleWidgets = _buildVdetalleSection(aggregatedVdetalle);
                                      
                                      if (vdetalleWidgets.isNotEmpty) {
                                        return _buildSection(
                                          l10n.discountStatistics,
                                          vdetalleWidgets,
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  ),
                              ],
                            );
                          },
                        ),

                        // 결제 통계 (vcodes_mpago) - 여러 sucursal이 있으면 합산
                        if (_data!.containsKey('vcodes_mpago')) ...[
                          Builder(
                            builder: (context) {
                              final aggregatedMpago = _getAggregatedMpago();
                              final mpagoWidgets = _buildMpagoSection(aggregatedMpago);
                              
                              if (mpagoWidgets.isNotEmpty) {
                                return _buildSection(
                                  l10n.mercadoPagoStatistics,
                                  mpagoWidgets,
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ],

                        // FVentas 통계 - 여러 sucursal이 있으면 합산
                        if (_data!.containsKey('fventas')) ...[
                          Builder(
                            builder: (context) {
                              final aggregatedFventas = _getAggregatedFventas();
                              final fventasWidgets = _buildFventasSection(aggregatedFventas);
                              
                              if (fventasWidgets.isNotEmpty) {
                                return _buildSection(
                                  'FVentas',
                                  fventasWidgets,
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ],

                        // Stock Resumen (stock_resumen 또는 stocks 키 확인)
                        // useGrid: false로 설정하여 자체 GridView 사용 (중복 방지)
                        // stocks 데이터가 있으면 항상 표시
                          Builder(
                            builder: (context) {
                            debugPrint('🔍 Stock 섹션 체크: stock_resumen=${_data!.containsKey('stock_resumen')}, stocks=${_data!.containsKey('stocks')}');
                            
                            // stock_resumen 또는 stocks 키 확인
                            final hasStockResumen = _data!.containsKey('stock_resumen') && _data!['stock_resumen'] != null;
                            final hasStocks = _data!.containsKey('stocks') && _data!['stocks'] != null;
                            
                            debugPrint('   - hasStockResumen: $hasStockResumen');
                            debugPrint('   - hasStocks: $hasStocks');
                            
                            if (!hasStockResumen && !hasStocks) {
                              debugPrint('   → Stock 데이터 없음');
                              return const SizedBox.shrink();
                            }
                            
                            final stockData = hasStocks && _data!['stocks'] != null
                                  ? {'stocks': _data!['stocks']}
                                : (hasStockResumen && _data!['stock_resumen'] != null
                                    ? (_data!['stock_resumen'] is Map<String, dynamic>
                                        ? _data!['stock_resumen'] as Map<String, dynamic>
                                        : <String, dynamic>{})
                                      : <String, dynamic>{});
                            
                            debugPrint('   - stockData 키: ${stockData.keys.toList()}');
                              
                              final stockWidgets = _buildStockResumenSection(stockData);
                            
                            debugPrint('   - stockWidgets 개수: ${stockWidgets.length}');
                              
                              if (stockWidgets.isNotEmpty) {
                                return _buildSection(
                                  'Stock Resumen',
                                  stockWidgets,
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
                                );
                              } else {
                              debugPrint('   → stockWidgets가 비어있음');
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = _isLargeScreen(context);
    final platformType = PlatformUtils.getPlatformType(context);
    // 핸드폰만 체크 (iPad는 제외)
    final isMobilePhone = platformType == PlatformType.mobile && !PlatformUtils.isIPad(context);
    
    // 넓은 화면: 좌우 분할 레이아웃 (왼쪽 메뉴 항상 표시)
    if (isLargeScreen) {
      return Scaffold(
        body: Row(
          children: [
            // 왼쪽: 연결 관리 + 보고서 종류 패널 (200px 고정)
            _buildLeftPanel(context),
            // 오른쪽: 보고서 본문
            Expanded(
              child: _buildReportContent(context),
            ),
          ],
        ),
      );
    }
    
    // 좁은 화면: Drawer를 사용하여 메뉴 접근
    // 핸드폰의 경우 AppBar를 맨 위에 고정하여 메뉴 접근 용이하게 함 (iPad 제외)
    return Scaffold(
      appBar: isMobilePhone ? AppBar(
        title: const Text('Resumen del Día'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ) : null,
      drawer: Drawer(
        width: 280, // Drawer 너비
        child: _buildLeftPanel(context, forDrawer: true),
      ),
      body: _buildReportContent(context),
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

  // 여러 sucursal의 vcodes 데이터를 합산 (선택된 sucursal에 따라 필터링)
  Map<String, dynamic> _getAggregatedVcodes() {
    if (_data == null || !_data!.containsKey('vcodes')) {
      return <String, dynamic>{};
    }
    
    final vcodes = _data!['vcodes'];
    
    if (vcodes is! List || vcodes.isEmpty) {
      return vcodes is Map<String, dynamic> ? vcodes : <String, dynamic>{};
    }
    
    // 선택된 sucursal에 따라 필터링
    List<dynamic> filteredVcodes = vcodes;
    if (_selectedSucursal != null && _selectedSucursal!.isNotEmpty) {
      filteredVcodes = vcodes.where((item) {
        if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
          final sucursal = item['sucursal'] is int 
              ? item['sucursal'].toString()
              : item['sucursal'].toString();
          return sucursal == _selectedSucursal;
        }
        return false;
      }).toList();
    }
    
    // 여러 sucursal의 데이터 합산
    final aggregated = <String, dynamic>{
      'operation_count': 0,
      'total_venta_day': 0.0,
      'total_efectivo_day': 0.0,
      'total_credito_day': 0.0,
      'total_banco_day': 0.0,
      'total_favor_day': 0.0,
      'total_count_ropas': 0,
    };
    String? lastVentaHour;
    
    for (var item in filteredVcodes) {
      if (item is Map<String, dynamic>) {
        aggregated['operation_count'] = (aggregated['operation_count'] as int) + 
            (item['operation_count'] as int? ?? 0);
        aggregated['total_venta_day'] = (aggregated['total_venta_day'] as double) + 
            ((item['total_venta_day'] as num?)?.toDouble() ?? 0.0);
        aggregated['total_efectivo_day'] = (aggregated['total_efectivo_day'] as double) + 
            ((item['total_efectivo_day'] as num?)?.toDouble() ?? 0.0);
        aggregated['total_credito_day'] = (aggregated['total_credito_day'] as double) + 
            ((item['total_credito_day'] as num?)?.toDouble() ?? 0.0);
        aggregated['total_banco_day'] = (aggregated['total_banco_day'] as double) + 
            ((item['total_banco_day'] as num?)?.toDouble() ?? 0.0);
        aggregated['total_favor_day'] = (aggregated['total_favor_day'] as double) + 
            ((item['total_favor_day'] as num?)?.toDouble() ?? 0.0);
        aggregated['total_count_ropas'] = (aggregated['total_count_ropas'] as int) + 
            (item['total_count_ropas'] as int? ?? 0);
        
        // 가장 최근 판매 시간 저장
        if (item['last_venta_hour'] != null) {
          final currentHour = item['last_venta_hour'].toString();
          if (lastVentaHour == null || currentHour.compareTo(lastVentaHour) > 0) {
            lastVentaHour = currentHour;
          }
        }
      }
    }
    
    if (lastVentaHour != null) {
      aggregated['last_venta_hour'] = lastVentaHour;
    }
    
    return aggregated;
  }
  
  // 여러 sucursal의 gastos 데이터를 합산 (선택된 sucursal에 따라 필터링)
  Map<String, dynamic> _getAggregatedGastos() {
    if (_data == null || !_data!.containsKey('gastos')) {
      debugPrint('🔍 _getAggregatedGastos: gastos 키가 없음');
      return <String, dynamic>{};
    }
    
    final gastos = _data!['gastos'];
    debugPrint('🔍 _getAggregatedGastos: gastos 타입=${gastos.runtimeType}, 값=$gastos');
    
    // Map인 경우 그대로 반환
    if (gastos is Map<String, dynamic>) {
      debugPrint('   → Map 형태로 반환');
      return gastos;
    }
    
    // List인 경우 합산
    if (gastos is List) {
      if (gastos.isEmpty) {
        debugPrint('   → List가 비어있음');
        return <String, dynamic>{};
      }
      
      // 선택된 sucursal에 따라 필터링
      List<dynamic> filteredGastos = gastos;
      if (_selectedSucursal != null && _selectedSucursal!.isNotEmpty) {
        filteredGastos = gastos.where((item) {
          if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
            final sucursal = item['sucursal'] is int 
                ? item['sucursal'].toString()
                : item['sucursal'].toString();
            return sucursal == _selectedSucursal;
          }
          return false;
        }).toList();
      }
      
      debugPrint('   → List 형태 (${filteredGastos.length}개 항목), 합산 시작');
    final aggregated = <String, dynamic>{
      'gasto_count': 0,
      'total_gasto_day': 0.0,
    };
    
      for (var item in filteredGastos) {
      if (item is Map<String, dynamic>) {
          final gastoCount = item['gasto_count'] as int? ?? item['count'] as int? ?? 0;
          final totalGastoDay = (item['total_gasto_day'] as num?)?.toDouble() ?? 
                               (item['total'] as num?)?.toDouble() ?? 0.0;
          
          aggregated['gasto_count'] = (aggregated['gasto_count'] as int) + gastoCount;
          aggregated['total_gasto_day'] = (aggregated['total_gasto_day'] as double) + totalGastoDay;
          
          debugPrint('     - 항목: gasto_count=$gastoCount, total_gasto_day=$totalGastoDay');
        } else {
          debugPrint('     - 항목이 Map이 아님: ${item.runtimeType}');
        }
      }
      
      debugPrint('   → 합산 결과: gasto_count=${aggregated['gasto_count']}, total_gasto_day=${aggregated['total_gasto_day']}');
    return aggregated;
  }
  
    debugPrint('   → 알 수 없는 형태, 빈 Map 반환');
    return <String, dynamic>{};
  }
  
  // 여러 sucursal의 vdetalle 데이터를 합산 (선택된 sucursal에 따라 필터링)
  Map<String, dynamic> _getAggregatedVdetalle() {
    if (_data == null || !_data!.containsKey('vdetalle')) {
      return <String, dynamic>{};
    }
    
    final vdetalle = _data!['vdetalle'];
    if (vdetalle is! List || vdetalle.isEmpty) {
      return vdetalle is Map<String, dynamic> ? vdetalle : <String, dynamic>{};
    }
    
    // 선택된 sucursal에 따라 필터링
    List<dynamic> filteredVdetalle = vdetalle;
    if (_selectedSucursal != null && _selectedSucursal!.isNotEmpty) {
      filteredVdetalle = vdetalle.where((item) {
        if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
          final sucursal = item['sucursal'] is int 
              ? item['sucursal'].toString()
              : item['sucursal'].toString();
          return sucursal == _selectedSucursal;
        }
        return false;
      }).toList();
    }
    
    final aggregated = <String, dynamic>{
      'count_discount_event': 0,
      'total_discount_day': 0.0,
    };
    
    for (var item in filteredVdetalle) {
      if (item is Map<String, dynamic>) {
        aggregated['count_discount_event'] = (aggregated['count_discount_event'] as int) + 
            (item['count_discount_event'] as int? ?? 0);
        aggregated['total_discount_day'] = (aggregated['total_discount_day'] as double) + 
            ((item['total_discount_day'] as num?)?.toDouble() ?? 0.0);
      }
    }
    
    return aggregated;
  }
  
  // 여러 sucursal의 mpago 데이터를 합산 (선택된 sucursal에 따라 필터링)
  Map<String, dynamic> _getAggregatedMpago() {
    if (_data == null || !_data!.containsKey('vcodes_mpago')) {
      return <String, dynamic>{};
    }
    
    final mpago = _data!['vcodes_mpago'];
    if (mpago is! List || mpago.isEmpty) {
      return mpago is Map<String, dynamic> ? mpago : <String, dynamic>{};
    }
    
    // 선택된 sucursal에 따라 필터링
    List<dynamic> filteredMpago = mpago;
    if (_selectedSucursal != null && _selectedSucursal!.isNotEmpty) {
      filteredMpago = mpago.where((item) {
        if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
          final sucursal = item['sucursal'] is int 
              ? item['sucursal'].toString()
              : item['sucursal'].toString();
          return sucursal == _selectedSucursal;
        }
        return false;
      }).toList();
    }
    
    final aggregated = <String, dynamic>{
      'count_mpago_total': 0,
      'total_mpago_day': 0.0,
    };
    
    for (var item in filteredMpago) {
      if (item is Map<String, dynamic>) {
        aggregated['count_mpago_total'] = (aggregated['count_mpago_total'] as int) + 
            (item['count_mpago_total'] as int? ?? 0);
        aggregated['total_mpago_day'] = (aggregated['total_mpago_day'] as double) + 
            ((item['total_mpago_day'] as num?)?.toDouble() ?? 0.0);
      }
    }
    
    return aggregated;
  }
  
  // 여러 sucursal의 fventas 데이터를 합산 (선택된 sucursal에 따라 필터링)
  Map<String, dynamic> _getAggregatedFventas() {
    if (_data == null || !_data!.containsKey('fventas')) {
      return <String, dynamic>{};
    }
    
    final fventas = _data!['fventas'];
    if (fventas is! List || fventas.isEmpty) {
      return <String, dynamic>{};
    }
    
    // 선택된 sucursal에 따라 필터링
    List<dynamic> filteredFventas = fventas;
    if (_selectedSucursal != null && _selectedSucursal!.isNotEmpty) {
      filteredFventas = fventas.where((item) {
        if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
          final sucursal = item['sucursal'] is int 
              ? item['sucursal'].toString()
              : item['sucursal'].toString();
          return sucursal == _selectedSucursal;
        }
        return false;
      }).toList();
    }
    
    // tipofactura별로 그룹화하여 합산
    final Map<String, Map<String, dynamic>> grouped = {};
    
    for (var item in filteredFventas) {
      if (item is Map<String, dynamic>) {
        final tipofactura = item['tipofactura']?.toString() ?? 'Unknown';
        
        if (!grouped.containsKey(tipofactura)) {
          grouped[tipofactura] = {
            'tipofactura': tipofactura,
            'count': 0,
            'sum_monto': 0.0,
          };
        }
        
        grouped[tipofactura]!['count'] = (grouped[tipofactura]!['count'] as int) + 
            (item['count'] as int? ?? 0);
        grouped[tipofactura]!['sum_monto'] = (grouped[tipofactura]!['sum_monto'] as double) + 
            ((item['sum_monto'] as num?)?.toDouble() ?? 0.0);
      }
    }
    
    // 리스트로 변환
    return {
      'items': grouped.values.toList(),
      'total_count': grouped.values.fold<int>(0, (sum, item) => sum + (item['count'] as int? ?? 0)),
      'total_sum_monto': grouped.values.fold<double>(0.0, (sum, item) => sum + ((item['sum_monto'] as num?)?.toDouble() ?? 0.0)),
    };
  }

  List<Widget> _buildVcodesSection(Map<String, dynamic> vcodes) {
    try {
      debugPrint('🔍 _buildVcodesSection 호출됨');
      debugPrint('   - vcodes 키: ${vcodes.keys.toList()}');
      final cards = <Widget>[];
      final configService = ConfigService();
      
      // 빈 Map인 경우 빈 리스트 반환
      if (vcodes.isEmpty) {
        debugPrint('   ⚠️ vcodes가 비어있음');
        return cards;
      }
      
      // 항상 표시되어야 하는 필드들
      if (vcodes.containsKey('operation_count')) {
      cards.add(_buildDataCard(
        'Evento de Venta',
        vcodes['operation_count'],
        Icons.shopping_cart,
        onTap: () {
          // 해당 날짜의 ventas 보고서로 이동
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
      ));
    }
    
    // 설정에 따라 표시/숨김 처리되는 필드들
    if (vcodes.containsKey('total_venta_day') && 
        configService.shouldShowResumenField('total_venta_day')) {
      cards.add(_buildDataCard(
        'Total de Ventas',
        vcodes['total_venta_day'],
        Icons.attach_money,
        isCurrency: true,
      ));
    }
    
    if (vcodes.containsKey('total_efectivo_day') && 
        configService.shouldShowResumenField('total_efectivo_day')) {
      cards.add(_buildDataCard(
        'Ventas en Efectivo',
        vcodes['total_efectivo_day'],
        Icons.money,
        isCurrency: true,
      ));
    }
    
    if (vcodes.containsKey('total_credito_day') && 
        configService.shouldShowResumenField('total_credito_day')) {
      cards.add(_buildDataCard(
        'Ventas a Crédito',
        vcodes['total_credito_day'],
        Icons.credit_card,
        isCurrency: true,
      ));
    }
    
    if (vcodes.containsKey('total_banco_day') && 
        configService.shouldShowResumenField('total_banco_day')) {
      cards.add(_buildDataCard(
        'Ventas Bancarias',
        vcodes['total_banco_day'],
        Icons.account_balance,
        isCurrency: true,
      ));
    }
    
    if (vcodes.containsKey('total_favor_day') && 
        configService.shouldShowResumenField('total_favor_day')) {
      cards.add(_buildDataCard(
        'Ventas Favor',
        vcodes['total_favor_day'],
        Icons.favorite,
        isCurrency: true,
      ));
    }
    
    // 항상 표시되어야 하는 필드들
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
          final valueStr = lastVentaHour.toString();
          // "HH:mm:ss" 형식인 경우
          if (valueStr.contains(':') && valueStr.split(':').length == 3 && !valueStr.contains('-')) {
            // 시간만 있는 경우 그대로 사용
            formattedTime = valueStr;
          } else {
            // ISO 8601 형식인 경우 파싱
            final dateTime = DateTime.parse(valueStr);
            formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
          }
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

      debugPrint('   ✅ Vcodes 섹션 카드 생성 완료: ${cards.length}개');
      return cards;
    } catch (e) {
      debugPrint('❌ Error building Vcodes section: $e');
      return [];
    }
  }

  List<Widget> _buildGastosSection(Map<String, dynamic> gastos) {
    try {
      debugPrint('🔍 _buildGastosSection 호출: gastos=$gastos');
      final cards = <Widget>[];
      
      // 빈 Map인 경우 빈 리스트 반환
      if (gastos.isEmpty) {
        debugPrint('   → gastos가 비어있음');
        return cards;
      }
      
      // gasto_count 또는 count 필드 확인
      final gastoCount = gastos['gasto_count'] ?? gastos['count'];
      if (gastoCount != null && (gastoCount is int || gastoCount is num) && (gastoCount as num) > 0) {
        debugPrint('   → gasto_count 카드 추가: $gastoCount');
      cards.add(_buildDataCard(
        'Evento de Gastos',
          gastoCount,
        Icons.receipt_long,
        onTap: () {
          // 해당 날짜의 gastos 보고서로 이동
          if (_isLargeScreen(context)) {
            setState(() {
              _selectedReportType = ReportType.gastos;
              _currentReport = 'gastos';
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportScreen(
                  serverUrl: widget.serverUrl,
                  reportType: ReportType.gastos,
                  initialItemsStartDate: _selectedDate,
                  initialItemsEndDate: _selectedDate,
                ),
              ),
            );
          }
        },
      ));
    }
    
      // total_gasto_day 또는 total 필드 확인
      final totalGastoDay = gastos['total_gasto_day'] ?? gastos['total'];
      if (totalGastoDay != null && (totalGastoDay is num) && (totalGastoDay as num) > 0) {
        debugPrint('   → total_gasto_day 카드 추가: $totalGastoDay');
      cards.add(_buildDataCard(
        'Total de Gastos',
          totalGastoDay,
        Icons.payments,
        isCurrency: true,
      ));
      }

      debugPrint('   → 총 ${cards.length}개 카드 생성');
      return cards;
    } catch (e) {
      debugPrint('❌ Error building Gastos section: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  List<Widget> _buildFventasSection(Map<String, dynamic> fventas) {
    try {
      final cards = <Widget>[];
      
      // 빈 Map인 경우 빈 리스트 반환
      if (fventas.isEmpty) {
        return cards;
      }
      
      // tipofactura별 항목들 표시
      if (fventas.containsKey('items') && fventas['items'] is List) {
        final items = fventas['items'] as List;
        
        for (var item in items) {
          if (item is Map<String, dynamic>) {
            final tipofactura = item['tipofactura']?.toString() ?? 'Unknown';
            final count = item['count'] as int? ?? 0;
            final sumMonto = item['sum_monto'] as num? ?? 0.0;
            
            // tipofactura별 카드 추가
            cards.add(
              InkWell(
                onTap: () {
                  // 해당 날짜의 fventas 보고서로 이동
                  if (_isLargeScreen(context)) {
                    setState(() {
                      _selectedReportType = ReportType.fventas;
                      _currentReport = 'fventas';
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportScreen(
                          serverUrl: widget.serverUrl,
                          reportType: ReportType.fventas,
                          initialDate: _selectedDate,
                          initialItemsStartDate: _selectedDate,
                          initialItemsEndDate: _selectedDate,
                        ),
                      ),
                    );
                  }
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt, color: Colors.deepPurple, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Factura Tipo $tipofactura',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Cantidad',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    count.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Total Monto',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Flexible(
                                    child: Text(
                                      _formatValue(sumMonto.toDouble(), isCurrency: true),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                      textAlign: TextAlign.end,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        }
      }
      
      // 전체 합계 카드 추가
      if (fventas.containsKey('total_count') || fventas.containsKey('total_sum_monto')) {
        final totalCount = fventas['total_count'] as int? ?? 0;
        final totalSumMonto = (fventas['total_sum_monto'] as num?)?.toDouble() ?? 0.0;
        
        cards.add(
          InkWell(
            onTap: () {
              // 해당 날짜의 fventas 보고서로 이동
              if (_isLargeScreen(context)) {
                setState(() {
                  _selectedReportType = ReportType.fventas;
                  _currentReport = 'fventas';
                });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportScreen(
                      serverUrl: widget.serverUrl,
                      reportType: ReportType.fventas,
                      initialDate: _selectedDate,
                      initialItemsStartDate: _selectedDate,
                      initialItemsEndDate: _selectedDate,
                    ),
                  ),
                );
              }
            },
            child: Card(
              color: Colors.deepPurple.withOpacity(0.1),
              child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, color: Colors.deepPurple, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Total FVentas',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Cantidad',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              totalCount.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Monto Total',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                              const SizedBox(height: 4),
                              Flexible(
                                child: Text(
                                  _formatValue(totalSumMonto, isCurrency: true),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      }

      return cards;
    } catch (e) {
      debugPrint('Error building FVentas section: $e');
      return [];
    }
  }

  List<Widget> _buildVdetalleSection(Map<String, dynamic> vdetalle) {
    try {
      final cards = <Widget>[];
      
      // 빈 Map인 경우 빈 리스트 반환
      if (vdetalle.isEmpty) {
        return cards;
      }
      
      if (vdetalle.containsKey('count_discount_event')) {
      cards.add(_buildDataCard(
        'Eventos de Descuento',
        vdetalle['count_discount_event'],
        Icons.local_offer,
        onTap: () {
          // 해당 날짜의 descuento가 있는 ventas 보고서로 이동
          debugPrint('🔍 할인 통계 카드 클릭 (count_discount_event): _selectedDate=$_selectedDate');
          if (_isLargeScreen(context)) {
            setState(() {
              _selectedReportType = ReportType.ventas;
              _currentReport = 'ventas';
              _currentVentasDescontado = true; // descuento 필터 적용
              debugPrint('   → 큰 화면: _currentVentasDescontado=$_currentVentasDescontado');
            });
          } else {
            debugPrint('   → 작은 화면: Navigator.push with initialVentasDescontado=true');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportScreen(
                  serverUrl: widget.serverUrl,
                  reportType: ReportType.ventas,
                  initialDate: _selectedDate,
                  initialVentasDescontado: true,
                ),
              ),
            );
          }
        },
      ));
    }
    
    if (vdetalle.containsKey('total_discount_day')) {
      cards.add(_buildDataCard(
        'Evento de Descuento',
        vdetalle['total_discount_day'],
        Icons.discount,
        isCurrency: true,
        onTap: () {
          // 해당 날짜의 descuento가 있는 ventas 보고서로 이동
          debugPrint('🔍 할인 통계 카드 클릭: _selectedDate=$_selectedDate');
          if (_isLargeScreen(context)) {
            setState(() {
              _selectedReportType = ReportType.ventas;
              _currentReport = 'ventas';
              _currentVentasDescontado = true; // descuento 필터 적용
              debugPrint('   → 큰 화면: _currentVentasDescontado=$_currentVentasDescontado');
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportScreen(
                  serverUrl: widget.serverUrl,
                  reportType: ReportType.ventas,
                  initialDate: _selectedDate,
                  initialVentasDescontado: true,
                ),
              ),
            );
          }
        },
      ));
      }

      return cards;
    } catch (e) {
      debugPrint('Error building Vdetalle section: $e');
      return [];
    }
  }

  List<Widget> _buildStockResumenSection(Map<String, dynamic> stockResumen) {
    try {
      // 빈 Map인 경우 빈 리스트 반환
      if (stockResumen.isEmpty) {
        return [
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
        ];
      }
      
      // Stocks 배열이 있는 경우 (resumen del dia 응답의 stocks 배열)
      if (stockResumen.containsKey('stocks') && stockResumen['stocks'] is List) {
        final stocksList = stockResumen['stocks'] as List;
        
        if (stocksList.isEmpty) {
          return [
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
          ];
        }
        
        // 선택된 sucursal에 따라 필터링
        List<dynamic> filteredStocksList = stocksList;
        if (_selectedSucursal != null && _selectedSucursal!.isNotEmpty) {
          filteredStocksList = stocksList.where((item) {
            if (item is Map<String, dynamic> && item.containsKey('sucursal')) {
              final sucursal = item['sucursal'] is int 
                  ? item['sucursal'].toString()
                  : item['sucursal'].toString();
              return sucursal == _selectedSucursal;
            }
            return false;
          }).toList();
        }
        
        // 데이터 파싱 및 합계 계산
        final List<Map<String, dynamic>> parsedStocks = [];
        double totalItemCount = 0;
        double totalTVentas = 0;
        double totalTIngresos = 0;
        double totalTOffset = 0;
        double totalHVentas = 0;
        double totalHIngresos = 0;
        double totalFinalStock = 0;
        
        for (var stock in filteredStocksList) {
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
            
            // 다양한 필드명 시도 (대소문자, 언더스코어 등)
            final itemCount = _getValue(stock, ['item_count', 'itemCount', 'itemcount']) ?? 0;
            final tVentas = _getDoubleValue(stock, ['tventas', 'tVentas', 't_ventas', 'total_ventas', 'totalVentas']) ?? 0.0;
            final tIngresos = _getDoubleValue(stock, ['tingresos', 'tIngresos', 't_ingresos', 'total_ingresos', 'totalIngresos']) ?? 0.0;
            final tOffset = _getDoubleValue(stock, ['toffset', 'tOffset', 't_offset', 'total_offset', 'totalOffset']) ?? 0.0;
            final hVentas = _getDoubleValue(stock, ['hventas', 'hVentas', 'h_ventas', 'hoy_ventas', 'hoyVentas']) ?? 0.0;
            final hIngresos = _getDoubleValue(stock, ['hingresos', 'hIngresos', 'h_ingresos', 'hoy_ingresos', 'hoyIngresos']) ?? 0.0;
            final finalStock = _getDoubleValue(stock, ['finalstock', 'finalStock', 'final_stock']) ?? 0.0;
            
            parsedStocks.add({
              'sucursal': sucursal,
              'itemCount': itemCount,
              'tVentas': tVentas,
              'tIngresos': tIngresos,
              'tOffset': tOffset,
              'hVentas': hVentas,
              'hIngresos': hIngresos,
              'finalStock': finalStock,
            });
            
            // 합계 계산
            totalItemCount += (itemCount is num ? itemCount.toDouble() : (itemCount is String ? double.tryParse(itemCount) ?? 0.0 : 0.0));
            totalTVentas += tVentas;
            totalTIngresos += tIngresos;
            totalTOffset += tOffset;
            totalHVentas += hVentas;
            totalHIngresos += hIngresos;
            totalFinalStock += finalStock;
          }
        }
        
        if (parsedStocks.isEmpty) {
          return [
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
          ];
        }
        
        // 테이블 생성
        return [
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                columns: const [
                  DataColumn(label: Text('Sucursal', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Item Count', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Total Ventas', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Total Ingresos', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Total Offset', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Hoy Ventas', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Hoy Ingresos', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Final Stock', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                ],
                rows: [
                  // 데이터 행
                  ...parsedStocks.map((stock) => DataRow(
                    cells: [
                      DataCell(Text(stock['sucursal'].toString())),
                      DataCell(Text(stock['itemCount'].toString())),
                      DataCell(Text(_formatValue(stock['tVentas'], isCurrency: true))),
                      DataCell(Text(_formatValue(stock['tIngresos'], isCurrency: true))),
                      DataCell(Text(_formatValue(stock['tOffset'], isCurrency: true))),
                      DataCell(Text(_formatValue(stock['hVentas'], isCurrency: true))),
                      DataCell(Text(_formatValue(stock['hIngresos'], isCurrency: true))),
                      DataCell(Text(_formatValue(stock['finalStock']))),
                    ],
                  )),
                  // 합계 행
                  DataRow(
                    color: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ),
                    cells: [
                      const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(totalItemCount.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalTVentas, isCurrency: true), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalTIngresos, isCurrency: true), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalTOffset, isCurrency: true), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalHVentas, isCurrency: true), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalHIngresos, isCurrency: true), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(_formatValue(totalFinalStock), style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                      ),
                    ],
                  ),
                ),
              ),
        ];
    }
    
    // Stock resumen 데이터 구조에 따라 표시 (기존 로직)
    if (stockResumen.containsKey('summary')) {
      final summary = stockResumen['summary'];
      if (summary is Map<String, dynamic>) {
          final cards = <Widget>[];
          
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
          
          return cards;
      }
    }
    
    // 데이터가 없으면 기본 메시지 표시
      return [
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
      ];
    } catch (e) {
      debugPrint('Error building Stock Resumen section: $e');
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Stock resumen 데이터를 표시하는 중 오류가 발생했습니다: $e',
              style: TextStyle(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }
  }

  /// 다양한 필드명으로 값 찾기 (헬퍼 함수)
  dynamic _getValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key)) {
        return map[key];
      }
    }
    return null;
  }

  /// 다양한 필드명으로 double 값 찾기 (헬퍼 함수)
  double? _getDoubleValue(Map<String, dynamic> map, List<String> keys) {
    final value = _getValue(map, keys);
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
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
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: Colors.grey[600]),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  /// MercadoPago 섹션 빌드
  /// ⚠️ 중요: 이 섹션은 항상 표시되어야 하며, 설정에 의해 숨겨지지 않습니다.
  List<Widget> _buildMpagoSection(Map<String, dynamic> mpago) {
    try {
      final cards = <Widget>[];
      
      // 빈 Map인 경우 빈 리스트 반환
      if (mpago.isEmpty) {
        return cards;
      }
      
      // MercadoPago 필드들은 항상 표시 (설정과 무관하게)
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
    } catch (e) {
      debugPrint('Error building Mpago section: $e');
      return [];
    }
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

  // 사용 가능한 sucursal 목록 추출
  List<String>? _extractAvailableSucursales(Map<String, dynamic> data) {
    final sucursales = <String>{};
    
    // vcodes에서 추출
    if (data.containsKey('vcodes') && data['vcodes'] is List) {
      final vcodesList = data['vcodes'] as List;
      for (var item in vcodesList) {
        if (item is Map && item.containsKey('sucursal')) {
          final sucursal = item['sucursal'] is int 
              ? item['sucursal'].toString()
              : item['sucursal'].toString();
          if (sucursal.isNotEmpty) {
            sucursales.add(sucursal);
          }
        }
      }
    }
    
    // gastos에서 추출
    if (data.containsKey('gastos') && data['gastos'] is List) {
      final gastosList = data['gastos'] as List;
      for (var item in gastosList) {
        if (item is Map && item.containsKey('sucursal')) {
          final sucursal = item['sucursal'] is int 
              ? item['sucursal'].toString()
              : item['sucursal'].toString();
          if (sucursal.isNotEmpty) {
            sucursales.add(sucursal);
          }
        }
      }
    }
    
    // vdetalle에서 추출
    if (data.containsKey('vdetalle') && data['vdetalle'] is List) {
      final vdetalleList = data['vdetalle'] as List;
      for (var item in vdetalleList) {
        if (item is Map && item.containsKey('sucursal')) {
          final sucursal = item['sucursal'] is int 
              ? item['sucursal'].toString()
              : item['sucursal'].toString();
          if (sucursal.isNotEmpty) {
            sucursales.add(sucursal);
          }
        }
      }
    }
    
    // vcodes_mpago에서 추출
    if (data.containsKey('vcodes_mpago') && data['vcodes_mpago'] is List) {
      final mpagoList = data['vcodes_mpago'] as List;
      for (var item in mpagoList) {
        if (item is Map && item.containsKey('sucursal')) {
          final sucursal = item['sucursal'] is int 
              ? item['sucursal'].toString()
              : item['sucursal'].toString();
          if (sucursal.isNotEmpty) {
            sucursales.add(sucursal);
          }
        }
      }
    }
    
    // stocks에서 추출
    if (data.containsKey('stocks') && data['stocks'] is List) {
      final stocksList = data['stocks'] as List;
      for (var item in stocksList) {
        if (item is Map && item.containsKey('sucursal')) {
          final sucursal = item['sucursal'] is int 
              ? item['sucursal'].toString()
              : item['sucursal'].toString();
          if (sucursal.isNotEmpty) {
            sucursales.add(sucursal);
          }
        }
      }
    }
    
    if (sucursales.isEmpty) {
      return null;
    }
    
    // 숫자 순서로 정렬
    final sortedSucursales = sucursales.toList()..sort((a, b) {
      final aNum = int.tryParse(a) ?? 0;
      final bNum = int.tryParse(b) ?? 0;
      return aNum.compareTo(bNum);
    });
    
    return sortedSucursales;
  }

  /// AppBar에 표시할 날짜 선택기 (Resumen del Día용)
  Widget _buildDateSelectorInAppBar() {
    final dateText = _selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
        : 'Seleccionar';
    
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                dateText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sucursal 선택 콤보박스 빌드
  Widget _buildSucursalSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButton<String?>(
        value: _selectedSucursal,
        hint: const Text('Total', style: TextStyle(fontSize: 12, color: Colors.white)),
        underline: const SizedBox(),
        isDense: true,
        isExpanded: false, // AppBar의 Row 안에서는 false로 설정
        dropdownColor: Theme.of(context).colorScheme.inversePrimary,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
        style: const TextStyle(fontSize: 12, color: Colors.white),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Total', style: TextStyle(fontSize: 12, color: Colors.white)),
          ),
          if (_availableSucursales != null)
            ..._availableSucursales!.map((sucursal) {
              return DropdownMenuItem<String?>(
                value: sucursal,
                child: Text('Sucursal $sucursal', style: const TextStyle(fontSize: 12, color: Colors.white)),
              );
            }).toList(),
        ],
        onChanged: (String? value) {
          setState(() {
            _selectedSucursal = value;
          });
        },
      ),
    );
  }

  // 여러 sucursal 데이터가 있는지 확인 (실제로 2개 이상일 때만 비교 테이블 표시)
  bool _hasMultipleSucursales() {
    if (_data == null) {
      debugPrint('⚠️ _hasMultipleSucursales: _data가 null');
      return false;
    }
    
    debugPrint('🔍 _hasMultipleSucursales 체크 시작');
    debugPrint('   - _data 키: ${_data!.keys.toList()}');
    
    // vcodes가 배열인 경우 - 실제 sucursal 개수 확인
    if (_data!.containsKey('vcodes') && _data!['vcodes'] is List) {
      final vcodesList = _data!['vcodes'] as List;
      debugPrint('   - vcodes는 List: ${vcodesList.length}개 항목');
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
        debugPrint('   - 고유한 sucursal 개수: ${sucursales.length} - $sucursales');
        // 2개 이상일 때만 비교 테이블 표시
        final result = sucursales.length > 1;
        debugPrint('   → 결과: $result');
        return result;
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
    debugPrint('🔍 _buildComparisonView 호출됨');
    List<Map<String, dynamic>> sucursalesData = [];
    
    // vcodes가 배열인 경우 (서버 응답 구조)
    if (_data!.containsKey('vcodes') && _data!['vcodes'] is List) {
      debugPrint('   - vcodes 배열 처리 시작');
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
      
      // stocks 데이터 추가
      if (_data!.containsKey('stocks') && _data!['stocks'] is List) {
        final stocksList = _data!['stocks'] as List;
        for (var item in stocksList) {
          if (item is Map && item.containsKey('sucursal')) {
            final sucursal = item['sucursal'] is int 
                ? item['sucursal'] as int 
                : int.tryParse(item['sucursal'].toString()) ?? 0;
            
            if (sucursalMap.containsKey(sucursal)) {
              sucursalMap[sucursal]!['stocks'] = item;
            }
          }
        }
      }
      
      sucursalesData = sucursalMap.values.toList();
      // sucursal 번호로 정렬
      sucursalesData.sort((a, b) => 
        (a['sucursal'] as int).compareTo(b['sucursal'] as int)
      );
      debugPrint('   ✅ sucursalesData 수집 완료: ${sucursalesData.length}개');
      for (var data in sucursalesData) {
        debugPrint('     - Sucursal ${data['sucursal']}: ${data.keys.toList()}');
      }
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
      debugPrint('   ⚠️ sucursalesData가 비어있음');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '비교할 데이터가 없습니다',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '데이터 키: ${_data!.keys.toList()}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    debugPrint('   ✅ 비교 뷰 렌더링 시작: ${sucursalesData.length}개 sucursal');
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
      
      // stocks 항목
      if (sucursalData.containsKey('stocks') && sucursalData['stocks'] is Map) {
        final stocks = sucursalData['stocks'] as Map<String, dynamic>;
        stocks.keys.forEach((key) {
          if (!allMetrics.contains('stocks_$key')) {
            allMetrics.add('stocks_$key');
          }
        });
      }
    }

    debugPrint('📊 수집된 메트릭: ${allMetrics.length}개 - $allMetrics');

    // 메트릭이 없으면 빈 테이블 메시지 표시
    if (allMetrics.isEmpty) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              '표시할 데이터가 없습니다.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
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
    final filteredMetrics = allMetrics.where((metric) => !metric.contains('sucursal')).toList();
    debugPrint('📋 필터링된 메트릭: ${filteredMetrics.length}개');
    
    final rows = filteredMetrics.map((metric) {
      final parts = metric.split('_');
      final category = parts[0];
      final key = parts.sublist(1).join('_');
      
      debugPrint('  - 처리 중: $metric -> category: $category, key: $key');
      
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
        'stocks_item_count': 'Item Count',
        'stocks_tVentas': 'Total Ventas',
        'stocks_tIngresos': 'Total Ingresos',
        'stocks_tOffset': 'Total Offset',
        'stocks_hVentas': 'Hoy Ventas',
        'stocks_hIngresos': 'Hoy Ingresos',
        'stocks_finalStock': 'Final Stock',
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
                         metric.contains('total_mpago') ||
                         metric.contains('tVentas') ||
                         metric.contains('tIngresos') ||
                         metric.contains('tOffset') ||
                         metric.contains('hVentas') ||
                         metric.contains('hIngresos')) &&
                        !metric.contains('count') &&
                        !metric.contains('_count_') &&
                        !metric.contains('item_count') &&
                        !metric.contains('finalStock');
      
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
                // mpago 카테고리의 경우 키가 'count_mpago_total', 'total_mpago_day' 형식
                // allMetrics에는 'mpago_count_mpago_total'로 저장되므로 'count_mpago_total' 부분만 추출
                value = mpagoData[key];
              }
            } else if (category == 'ingresos' && data.containsKey('ingresos')) {
              final ingresosData = data['ingresos'];
              if (ingresosData is Map<String, dynamic>) {
                value = ingresosData[key];
              }
            } else if (category == 'stocks' && data.containsKey('stocks')) {
              final stocksData = data['stocks'];
              if (stocksData is Map<String, dynamic>) {
                value = stocksData[key];
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

    debugPrint('✅ 테이블 생성 완료: ${columns.length}개 컬럼, ${rows.length}개 행');
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
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
      case 'fventas':
        return 'FVentas';
      case 'alertas':
        return 'Alertas';
      case 'ingresos':
        return 'Ingresos';
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
      PopupMenuItem<String>(
        value: 'ventas',
        child: Row(
          children: [
            Icon(
              Icons.shopping_cart,
              color: _currentReport == 'ventas' ? Colors.purple : Colors.grey,
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
              const Icon(Icons.check, color: Colors.purple, size: 18),
            ],
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'fventas',
        child: Row(
          children: [
            Icon(
              Icons.receipt,
              color: _currentReport == 'fventas' ? Colors.deepPurple : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'FVentas',
              style: TextStyle(
                fontWeight: _currentReport == 'fventas' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (_currentReport == 'fventas') ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.deepPurple, size: 18),
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
        value: 'ingresos',
        child: Row(
          children: [
            Icon(
              Icons.trending_up,
              color: _currentReport == 'ingresos' ? Colors.indigo : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Ingresos',
              style: TextStyle(
                fontWeight: _currentReport == 'ingresos' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (_currentReport == 'ingresos') ...[
              const Spacer(),
              const Icon(Icons.check, color: Colors.indigo, size: 18),
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
        enabled: true,
        child: Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: Colors.red,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Gastos',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'alertas',
        enabled: true,
        child: Row(
          children: [
            Icon(
              Icons.notifications,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Alertas',
              style: TextStyle(
                color: Colors.black87,
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
    debugPrint('🔍 _navigateToReport 호출: reportType=$reportType, 현재 _currentReport=$_currentReport, _selectedReportType=$_selectedReportType');
    
    // 현재 보고서는 아무것도 하지 않음
    if (reportType == 'resumen') {
      if (_isLargeScreen(context)) {
        debugPrint('   → resumen으로 변경, _selectedReportType을 null로 설정');
        setState(() {
          _currentReport = 'resumen';
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
      case 'fventas':
        reportTypeEnum = ReportType.fventas;
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
      case 'ingresos':
        reportTypeEnum = ReportType.ingresos;
        break;
      default:
        debugPrint('   → 알 수 없는 reportType, return');
        return;
    }

    debugPrint('   → reportTypeEnum=$reportTypeEnum, _isLargeScreen=${_isLargeScreen(context)}');

    // 큰 화면인 경우 오른쪽 패널에 보고서 표시
    if (_isLargeScreen(context)) {
      debugPrint('   → 큰 화면: setState로 _currentReport=$reportType, _selectedReportType=$reportTypeEnum 설정');
      setState(() {
        _currentReport = reportType;
        _selectedReportType = reportTypeEnum;
        // ventas가 아닌 다른 보고서로 이동할 때는 descontado 필터 초기화
        if (reportTypeEnum != ReportType.ventas) {
          _currentVentasDescontado = null;
        }
      });
      debugPrint('   → setState 완료 후: _currentReport=$_currentReport, _selectedReportType=$_selectedReportType');
    } else {
      // 핸드폰: 기존 방식 (Navigator.push)
      // ventas 보고서의 경우 initialDate 전달
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportScreen(
            serverUrl: widget.serverUrl,
            reportType: reportTypeEnum,
            initialDate: (reportTypeEnum == ReportType.ventas || reportTypeEnum == ReportType.fventas) ? (_selectedDate ?? DateTime.now()) : null,
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
    _databaseService.dispose(); // HTTP 클라이언트 연결 풀 정리
    _newProfileNameController.dispose();
    _newServerUrlController.dispose();
    _newDatabaseNameController.dispose();
    _newUsernameController.dispose();
    _newPasswordController.dispose();
    _newLocalIpController.dispose();
    super.dispose();
  }
}



