import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'dart:math';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../models/connection_info.dart';
import '../services/connection_storage_service.dart';
import '../services/secure_storage_helper.dart';
import '../utils/platform_utils.dart';
import 'celebration_screen.dart';
import 'connection_screen.dart';
import 'additional_connections_screen.dart';
import 'resumen_del_dia_screen.dart';
import 'connection_list_screen.dart';
import 'report_screen.dart';
import '../widgets/report_utils.dart';
import 'helpers/biometric_auth_handler.dart';
import 'helpers/auto_connection_handler.dart';
import 'helpers/connection_manager.dart';

class MainConnectionScreen extends StatefulWidget {
  final bool skipAutoConnect;
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;
  
  const MainConnectionScreen({
    super.key,
    this.skipAutoConnect = false,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  State<MainConnectionScreen> createState() => _MainConnectionScreenState();
}

enum ServerType {
  hostinger,
  local,
}

class _MainConnectionScreenState extends State<MainConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileNameController = TextEditingController();
  final _databaseNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController();
  final _serverUrlController = TextEditingController();
  final _localIpController = TextEditingController();
  
  final ConnectionStorageService _connectionStorageService = ConnectionStorageService();
  final ConnectionManager _connectionManager = ConnectionManager();
  final BiometricAuthHandler _biometricAuthHandler = BiometricAuthHandler();
  ServerType _selectedServerType = ServerType.hostinger;
  bool _isLoading = false;
  bool _isAutoConnecting = false;
  bool _isConnected = false; // 연결 성공 여부
  String? _errorMessage;
  List<ConnectionInfo> _savedConnections = [];
  bool _isLoadingConnections = false;
  bool _isBiometricAuthenticated = false; // 생체 인식 성공 여부
  
  // 연결 성공 후 보고서 관련 상태
  String? _currentServerUrl; // 현재 연결된 서버 URL
  String? _currentDatabaseName; // 현재 연결된 데이터베이스 이름
  String _currentReport = 'resumen'; // 현재 선택된 보고서
  ReportType? _selectedReportType; // 선택된 보고서 타입
  DatabaseService? _databaseService; // 데이터베이스 서비스
  bool _isLeftPanelCollapsed = false; // 왼쪽 패널 축소 상태 (큰 화면에서만 사용)
  
  // 연결 ID 생성
  String _generateConnectionId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
  
  @override
  void initState() {
    super.initState();
    // 성능 최적화: 우선순위에 따라 순차 실행
    // 1. 자동 연결 시도 (가장 중요, 먼저 실행)
    _checkAndAutoConnect().then((_) {
      // 2. 자동 연결 실패 시에만 연결 리스트와 상태 확인
      if (mounted && !_isAutoConnecting) {
        _loadSavedConnections();
        _checkConnectionStatus();
      }
    });
    // 생체 인식은 BiometricAuthScreen에서 이미 완료되었으므로 여기서는 호출하지 않음
    // _authenticateInBackground();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 표시될 때마다 연결 리스트 갱신 (로딩 중이 아니고 이미 로드된 경우에만)
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent && !_isLoadingConnections && _savedConnections.isEmpty) {
      // 성능 최적화: 디버깅 출력 제거
      _loadSavedConnections();
    }
  }

  // 연결 상태 확인
  Future<void> _checkConnectionStatus() async {
    final status = await ConnectionManager.checkConnectionStatus();
    if (status.isConnected && status.serverUrl != null && status.databaseName != null) {
      setState(() {
        _isConnected = true;
        _currentServerUrl = status.serverUrl;
        _currentDatabaseName = status.databaseName;
        _databaseService?.dispose();
        _databaseService = DatabaseService(serverUrl: status.serverUrl!);
      });
    }
  }

  // 백그라운드에서 생체 인식 수행
  Future<void> _authenticateInBackground() async {
    final success = await _biometricAuthHandler.authenticateInBackground();
    if (mounted) {
      setState(() {
        _isBiometricAuthenticated = success;
      });
    }
  }

  // 저장된 연결 목록 불러오기
  Future<void> _loadSavedConnections() async {
    if (_isLoadingConnections) {
      print('⚠️ 이미 연결 리스트 로딩 중이므로 스킵');
      return;
    }

    _isLoadingConnections = true;
    setState(() {
      _isLoadingConnections = true;
    });

    try {
      final connections = await _connectionManager.loadSavedConnections();
      if (mounted) {
        setState(() {
          _savedConnections = connections;
          _isLoadingConnections = false;
        });
      }
    } catch (e) {
      print('❌ 연결 리스트 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoadingConnections = false;
        });
      }
    } finally {
      _isLoadingConnections = false;
    }
  }

  // 연결 삭제하기
  Future<void> _deleteConnection(ConnectionInfo connection) async {
    final deleted = await _connectionManager.deleteConnection(context, connection);
    if (deleted) {
      await _loadSavedConnections();
    }
  }

  Future<void> _connectWithSavedConnection(ConnectionInfo connection) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _connectionManager.connectWithSavedConnection(connection);

    if (result.isSuccess && mounted) {
      print('✅ 저장된 연결로 연결 성공 - ResumenDelDiaScreen으로 이동');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResumenDelDiaScreen(
            serverUrl: result.serverUrl!,
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? '연결에 실패했습니다.';
        _isLoading = false;
      });
    }
  }
  
  // 저장된 연결 정보 확인 후 자동 연결
  Future<void> _checkAndAutoConnect() async {
    if (widget.skipAutoConnect) {
      await _loadSavedConnectionInfo();
      return;
    }
    
    setState(() {
      _isAutoConnecting = true;
    });

    final result = await AutoConnectionHandler.checkAndAutoConnect(
      skipAutoConnect: widget.skipAutoConnect,
      onSuccess: (serverUrl) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResumenDelDiaScreen(serverUrl: serverUrl),
            ),
          );
        }
      },
    );

    if (result.isSuccess) {
      // 성공 시 onSuccess에서 처리됨
      return;
    }

    setState(() {
      _isAutoConnecting = false;
      if (result.errorMessage != null) {
        _errorMessage = 'Error de conexión automática: ${result.errorMessage}';
      }
    });

    await _loadSavedConnectionInfo();
  }

  @override
  void dispose() {
    _databaseService?.dispose(); // HTTP 클라이언트 정리, 연결 풀 낭비 방지
    _profileNameController.dispose();
    _databaseNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    _serverUrlController.dispose();
    _localIpController.dispose();
    super.dispose();
  }

  // 저장된 기본 연결 정보 불러오기
  Future<void> _loadSavedConnectionInfo() async {
    try {
      final profileName = await SecureStorageHelper.read('profile_name') ?? '';
      final serverType = await SecureStorageHelper.read('server_type');
      final databaseName = await SecureStorageHelper.read('database_name') ?? '';
      final username = await SecureStorageHelper.read('username') ?? '';
      final password = await SecureStorageHelper.readSecure('password') ?? '';
      final localIp = await SecureStorageHelper.read('local_ip') ?? '';
      final connectionSuccess = await SecureStorageHelper.read('connection_success');
      
      final serverUrl = serverType == 'local' && localIp.isNotEmpty
          ? 'http://$localIp:3030'
          : 'https://sync.coolsistema.com';
      
      setState(() {
        _profileNameController.text = profileName;
        if (serverType == 'local') {
          _selectedServerType = ServerType.local;
          _localIpController.text = localIp;
          _serverUrlController.text = serverUrl;
        } else {
          _selectedServerType = ServerType.hostinger;
          _serverUrlController.text = serverUrl;
        }
        _databaseNameController.text = databaseName;
        _usernameController.text = username;
        _passwordController.text = password;
        
        // 연결 상태 업데이트
        if (connectionSuccess == 'true' && databaseName.isNotEmpty) {
          _isConnected = true;
          _currentServerUrl = serverUrl;
          _currentDatabaseName = databaseName;
          _databaseService?.dispose();
          _databaseService = DatabaseService(serverUrl: serverUrl);
        } else {
          _isConnected = false;
          _currentServerUrl = null;
          _currentDatabaseName = null;
          _databaseService?.dispose();
          _databaseService = null;
        }
      });
    } catch (e) {
      // 저장된 정보가 없거나 오류가 발생한 경우 기본값 사용
      setState(() {
        _selectedServerType = ServerType.hostinger;
        _serverUrlController.text = 'https://sync.coolsistema.com';
        _isConnected = false;
      });
    }
  }
  
  // 서버 타입 변경 핸들러
  void _onServerTypeChanged(ServerType? newType) {
    if (newType == null) return;
    
    setState(() {
      _selectedServerType = newType;
      
      if (newType == ServerType.hostinger) {
        // Hostinger 선택 시
        _serverUrlController.text = 'https://sync.coolsistema.com';
        _localIpController.clear();
      } else {
        // Local 선택 시 (포트 3030 자동 사용)
        _serverUrlController.text = _localIpController.text.isNotEmpty 
            ? 'http://${_localIpController.text}:3030' 
            : '';
      }
    });
  }
  
  // 로컬 IP 변경 핸들러
  void _onLocalIpChanged(String value) {
    setState(() {
      _localIpController.text = value;
      if (_selectedServerType == ServerType.local) {
        _serverUrlController.text = value.isNotEmpty 
            ? 'http://$value:3030' 
            : '';
      }
    });
  }
  
  // 기본 연결 정보 저장하기 (보안 저장소 사용)
  Future<void> _saveConnectionInfo() async {
    try {
      // 하이브리드 저장 방식 사용
      await SecureStorageHelper.save('profile_name', _profileNameController.text.trim());
      await SecureStorageHelper.save(
        'server_type',
        _selectedServerType == ServerType.hostinger ? 'hostinger' : 'local',
      );
      await SecureStorageHelper.save('server_url', _serverUrlController.text.trim());
      await SecureStorageHelper.save('database_name', _databaseNameController.text.trim());
      await SecureStorageHelper.save('username', _usernameController.text.trim());
      // 비밀번호 저장: macOS는 SharedPreferences, 다른 플랫폼은 SecureStorage
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        await SecureStorageHelper.save('password', _passwordController.text.trim());
      } else {
        await SecureStorageHelper.saveSecure('password', _passwordController.text.trim());
      }
      if (_selectedServerType == ServerType.local) {
        await SecureStorageHelper.save('local_ip', _localIpController.text.trim());
        await SecureStorageHelper.save('port', '3030'); // Local은 항상 3030 포트 사용
      } else {
        await SecureStorageHelper.save('port', '');
      }
      // 연결 성공 플래그 저장
      await SecureStorageHelper.save('connection_success', 'true');
      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      // 저장 실패 시 무시
    }
  }
  
  // 연결 목록에 저장하기
  Future<void> _saveToConnectionList() async {
    try {
      final serverUrl = _serverUrlController.text.trim();
      final databaseName = _databaseNameController.text.trim();
      final username = _usernameController.text.trim();
      
      // 기존 연결 목록 가져오기
      final existingConnections = await _connectionStorageService.getAllConnections();
      
      // 중복 체크: 서버 URL, 데이터베이스 이름, 사용자 이름이 모두 같으면 중복
      final isDuplicate = existingConnections.any((conn) =>
        conn.serverUrl == serverUrl &&
        conn.databaseName == databaseName &&
        conn.username == username
      );
      
      if (isDuplicate) {
        print('⚠️ 중복된 연결이 이미 존재합니다. 추가하지 않습니다.');
        return;
      }
      
      // 포트 번호 추출 (서버 URL에서)
      int port = 3030; // 기본값
      final uri = Uri.tryParse(serverUrl);
      if (uri != null && uri.hasPort) {
        port = uri.port;
      } else if (_selectedServerType == ServerType.hostinger) {
        // Hostinger는 HTTPS 기본 포트
        port = 443;
      }
      
      // 연결 이름이 비어있으면 Profile Name 사용
      String connectionName = _profileNameController.text.trim();
      if (connectionName.isEmpty) {
        connectionName = databaseName;
        if (connectionName.isEmpty) {
          connectionName = '연결 ${DateTime.now().toString().substring(0, 10)}';
        }
      }
      
      final connection = ConnectionInfo(
        id: _generateConnectionId(),
        name: connectionName,
        serverUrl: serverUrl,
        databaseName: databaseName,
        username: username,
        password: _passwordController.text.trim(),
        port: port,
      );
      
      await _connectionStorageService.saveConnection(connection);
      print('✅ 연결 목록에 저장 완료: ${connection.name}');
    } catch (e) {
      print('❌ 연결 목록 저장 실패: $e');
      // 저장 실패해도 연결은 계속 진행
    }
  }

  Future<void> _connectToDatabase() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final serverUrl = _serverUrlController.text.trim();
    final service = DatabaseService(serverUrl: serverUrl);
    try {
      final request = DatabaseConnectionRequest(
        databaseName: _databaseNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      print('=== 연결 시작 ===');
      print('서버 URL: ${_serverUrlController.text.trim()}');
      print('데이터베이스: ${_databaseNameController.text.trim()}');
      print('사용자: ${_usernameController.text.trim()}');
      
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

      if (success && mounted) {
        print('✅ 연결 성공 - 정보 저장 및 상태 업데이트');
        final serverUrl = _serverUrlController.text.trim();
        final databaseName = _databaseNameController.text.trim();
        
        // 연결 성공 시 정보 저장
        await _saveConnectionInfo();
        
        // 연결 목록에도 저장
        await _saveToConnectionList();
        
        // 연결 목록 갱신
        await _loadSavedConnections();
        
        // macOS에서 저장 확인 (개발 환경: 모든 데이터를 SharedPreferences에 저장)
        if (defaultTargetPlatform == TargetPlatform.macOS) {
          print('🍎 macOS: 저장 확인 중...');
          final savedDbName = await SecureStorageHelper.read('database_name');
          final savedUsername = await SecureStorageHelper.read('username');
          final savedPassword = await SecureStorageHelper.read('password');  // macOS: SharedPreferences 사용
          
          print('🍎 macOS 최종 저장 확인:');
          print('   database_name: ${savedDbName ?? "(없음)"}');
          print('   username: ${savedUsername ?? "(없음)"}');
          print('   password: ${savedPassword != null && savedPassword.isNotEmpty ? "*** (길이: ${savedPassword.length})" : "(없음)"}');
          
          // 저장 확인 실패해도 연결은 성공했으므로 계속 진행
          if (savedDbName == null || savedDbName.isEmpty || 
              savedUsername == null || savedUsername.isEmpty ||
              savedPassword == null || savedPassword.isEmpty) {
            print('⚠️ macOS 저장 확인 실패했지만 연결은 성공했으므로 계속 진행합니다.');
          }
        }
        
        // 연결 성공 시 ResumenDelDiaScreen으로 완전히 이동
        print('✅ 연결 성공 - ResumenDelDiaScreen으로 이동');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResumenDelDiaScreen(
                serverUrl: serverUrl,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Error de conexión. (Verificar código de estado)';
          _isLoading = false;
          _isConnected = false;
        });
      }
    } catch (e) {
      print('❌ 연결 오류 발생: $e');
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      // 저장 실패 메시지 구분
      final isSaveError = errorMessage.contains('저장') || errorMessage.contains('save');
      setState(() {
        _errorMessage = isSaveError 
            ? 'La conexión fue exitosa pero falló al guardar la información. Por favor intente nuevamente.\n$errorMessage'
            : errorMessage;
        _isLoading = false;
        _isConnected = false;
      });
      
      // 상세 오류 정보를 다이얼로그로도 표시
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.connectionFailedTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.connectionFailedMessage),
                  const SizedBox(height: 16),
                  Text(
                    l10n.error(errorMessage),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.checkItems),
                  const Text('• Verificar que la URL del servidor sea correcta'),
                  const Text('• Verificar que el servidor esté en ejecución'),
                  const Text('• Verificar el estado de la conexión a Internet'),
                  const Text('• Verificar la configuración del firewall'),
                  const SizedBox(height: 16),
                  const Text(
                    'Consulte la terminal/consola para obtener más detalles.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      }
    } finally {
      service.dispose(); // HTTP 클라이언트 정리, 연결 풀 낭비 방지
    }
  }

  // 큰 화면인지 확인 (macOS, Windows, Linux, iPad)
  // 모든 데스크톱 플랫폼과 iPad는 큰 화면으로 간주하여 자동 축소 기능 사용
  bool _isLargeScreen(BuildContext context) {
    // macOS, Windows, Linux는 항상 큰 화면으로 간주
    // 화면 크기와 관계없이 데스크톱 플랫폼은 자동 축소 기능 사용
    if (PlatformUtils.isDesktop()) {
      return true;
    }
    
    // iPad도 큰 화면으로 간주하여 자동 축소 기능 사용
    if (PlatformUtils.isIPad(context)) {
      return true;
    }
    
    return false;
  }

  // 왼쪽 패널 빌드 (화면의 1/4 너비)
  Widget _buildLeftPanel(BuildContext context) {
    // 축소된 상태일 때는 메뉴 버튼만 표시
    if (_isLeftPanelCollapsed) {
      return Container(
        width: 60,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            right: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        child: Column(
          children: [
            // 메뉴 버튼
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isLeftPanelCollapsed = false;
                  });
                },
                tooltip: 'Menú',
              ),
            ),
            // 연결 관리 버튼
            if (_isConnected)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: const Icon(Icons.storage, color: Colors.blue),
                    onPressed: () {
                      setState(() {
                        _isLeftPanelCollapsed = false;
                      });
                    },
                    tooltip: 'Conexiones',
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    final leftPanelWidth = screenWidth * 0.25; // 화면의 1/4
    
    return Container(
      width: leftPanelWidth,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // 상단 1/4: 연결 리스트 (항상 표시)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.25,
            child: _buildConnectionListSection(context),
          ),
          // 구분선
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          // 하단 3/4: 연결 전에는 연결 폼, 연결 후에는 보고서 메뉴
          Expanded(
            child: _isConnected
                ? _buildReportMenuSection(context)
                : _buildConnectionFormSection(context),
          ),
        ],
      ),
    );
  }

  // 연결 리스트 섹션 빌드 (상단 1/4)
  Widget _buildConnectionListSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // 디버깅: 리스트 빌드 시 연결 수 확인
    print('🔨 _buildConnectionListSection: _savedConnections.length = ${_savedConnections.length}');
    print('   _currentDatabaseName = $_currentDatabaseName');
    
    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Row(
            children: [
              const Icon(Icons.storage, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.databaseConnection,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              // 축소 버튼 (큰 화면에서만 표시, 연결된 경우)
              if (_isLargeScreen(context) && _isConnected)
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 18),
                  onPressed: () {
                    setState(() {
                      _isLeftPanelCollapsed = true;
                    });
                  },
                  tooltip: 'Colapsar menú',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                onPressed: () async {
                  final result = await Navigator.push<ConnectionInfo>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConnectionScreen(),
                    ),
                  );
                  if (mounted) {
                    print('🔄 연결 추가 화면에서 돌아옴, 리스트 갱신 중...');
                    await Future.delayed(const Duration(milliseconds: 100));
                    await _loadSavedConnections();
                    if (mounted) {
                      setState(() {});
                    }
                  }
                },
                tooltip: l10n.addConnection,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.list, color: Colors.white, size: 18),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdditionalConnectionsScreen(),
                    ),
                  );
                  // 돌아왔을 때 리스트 강제 갱신
                  if (mounted) {
                    print('🔄 AdditionalConnectionsScreen에서 돌아옴, 리스트 강제 갱신');
                    await Future.delayed(const Duration(milliseconds: 100));
                    await _loadSavedConnections();
                    if (mounted) {
                      setState(() {});
                    }
                  }
                },
                tooltip: l10n.additionalConnections,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        // 연결 목록
        Expanded(
          child: _savedConnections.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storage_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noSavedConnections,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.addNewConnection,
                          style: TextStyle(color: Colors.grey[500], fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _savedConnections.length,
                  itemBuilder: (context, index) {
                    final connection = _savedConnections[index];
                    final isCurrentConnection = connection.databaseName == _currentDatabaseName;
                    
                    // 디버깅: 각 항목 빌드 시 정보 출력
                    if (index == 0) {
                      print('🔨 ListView.builder: itemCount = ${_savedConnections.length}');
                      print('   첫 번째 항목: ${connection.name} (DB: ${connection.databaseName})');
                      print('   isCurrentConnection: $isCurrentConnection');
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Card(
                        elevation: isCurrentConnection ? 3 : 1,
                        color: isCurrentConnection 
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                            : Colors.white,
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: isCurrentConnection
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[400],
                            child: Icon(
                              isCurrentConnection ? Icons.check_circle : Icons.storage, 
                              color: Colors.white, 
                              size: 16
                            ),
                          ),
                          title: Text(
                            connection.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isCurrentConnection
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              connection.databaseName,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 16),
                            onSelected: (value) {
                              if (value == 'connect' && !isCurrentConnection) {
                                _connectWithSavedConnection(connection);
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
                                _deleteConnection(connection);
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
                                      Text(l10n.connect, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, size: 16, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(l10n.edit, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete, size: 16, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(l10n.delete, style: const TextStyle(color: Colors.red, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            // 현재 연결이 아니면 바로 연결
                            if (!isCurrentConnection) {
                              _connectWithSavedConnection(connection);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 연결 폼 섹션 빌드 (하단 3/4, 연결 전)
  Widget _buildConnectionFormSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 회사 로고 (작게)
              Center(
                child: Image.asset(
                  'assets/logo.jpg',
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 120,
                      child: Icon(Icons.image, size: 80, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Profile Name과 언어 선택
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _profileNameController,
                      decoration: InputDecoration(
                        labelText: 'Profile Name',
                        hintText: l10n.profileNameHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 13),
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.none,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: widget.currentLocale?.languageCode ?? 
                             (Localizations.localeOf(context).languageCode == 'es' || 
                              Localizations.localeOf(context).languageCode == 'en' ||
                              Localizations.localeOf(context).languageCode == 'ko'
                              ? Localizations.localeOf(context).languageCode
                              : 'es'),
                      decoration: InputDecoration(
                        labelText: l10n.language,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.language, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'es',
                          child: Text('Esp', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('Eng', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'ko',
                          child: Text('Kor', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                      onChanged: widget.onLanguageChanged != null ? (value) {
                        if (value != null) {
                          widget.onLanguageChanged!(Locale(value, ''));
                        }
                      } : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 서버 타입 선택
              Text(
                l10n.serverType,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<ServerType>(
                      title: const Text('Hostinger', style: TextStyle(fontSize: 12)),
                      value: ServerType.hostinger,
                      groupValue: _selectedServerType,
                      onChanged: _onServerTypeChanged,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<ServerType>(
                      title: const Text('Local IP', style: TextStyle(fontSize: 12)),
                      value: ServerType.local,
                      groupValue: _selectedServerType,
                      onChanged: _onServerTypeChanged,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 로컬 IP 입력 필드
              if (_selectedServerType == ServerType.local)
                TextFormField(
                  controller: _localIpController,
                  decoration: InputDecoration(
                    labelText: l10n.localIpAddress,
                    hintText: l10n.localIpHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.computer, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 13),
                  keyboardType: TextInputType.number,
                  onChanged: _onLocalIpChanged,
                  validator: (value) {
                    if (_selectedServerType == ServerType.local) {
                      if (value == null || value.isEmpty) {
                        return l10n.localIpRequired;
                      }
                      final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                      if (!ipRegex.hasMatch(value)) {
                        return l10n.invalidIpAddress;
                      }
                    }
                    return null;
                  },
                ),
              if (_selectedServerType == ServerType.local)
                const SizedBox(height: 12),
              // 서버 URL
              TextFormField(
                controller: _serverUrlController,
                decoration: InputDecoration(
                  labelText: l10n.serverUrl,
                  hintText: 'http://localhost:3000',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.link, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style: const TextStyle(fontSize: 13),
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 12),
              // 데이터베이스 이름
              TextFormField(
                controller: _databaseNameController,
                decoration: InputDecoration(
                  labelText: l10n.databaseName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.storage, size: 18),
                  helperText: l10n.alphanumericOnly,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style: const TextStyle(fontSize: 13),
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.databaseNameRequired;
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                    return l10n.alphanumericOnly;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // 사용자 이름과 암호
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: l10n.username,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person, size: 18),
                        helperText: l10n.alphanumericOnly,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 13),
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.usernameRequired;
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                          return l10n.alphanumericOnly;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 13),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.passwordRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _connectToDatabase,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        l10n.connect,
                        style: const TextStyle(fontSize: 14),
                      ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  // 연결 추가 화면으로 이동
                  final result = await Navigator.push<ConnectionInfo>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConnectionScreen(),
                    ),
                  );
                  // 연결 화면에서 돌아왔을 때 리스트 갱신
                  if (mounted) {
                    print('🔄 연결 추가 화면에서 돌아옴, 리스트 갱신 중...');
                    print('   결과: ${result != null ? result.name : "null"}');
                    // 약간의 지연 후 리스트 갱신 (저장이 완전히 완료되도록)
                    await Future.delayed(const Duration(milliseconds: 100));
                    await _loadSavedConnections();
                    if (result != null) {
                      print('✅ 새 연결 추가됨: ${result.name}');
                    }
                    // UI 강제 업데이트
                    if (mounted) {
                      setState(() {});
                    }
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text(l10n.addConnection, style: const TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 보고서 메뉴 섹션 빌드 (하단 3/4, 연결 후)
  Widget _buildReportMenuSection(BuildContext context) {
    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
          ),
          child: Row(
            children: [
              const Icon(Icons.assessment, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Reportes',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              // 축소 버튼 (큰 화면에서만 표시)
              if (_isLargeScreen(context))
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 18),
                  onPressed: () {
                    setState(() {
                      _isLeftPanelCollapsed = true;
                    });
                  },
                  tooltip: 'Colapsar menú',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        // 보고서 목록
        Expanded(
          child: ListView(
            children: [
              _buildReportMenuItem(
                context,
                'resumen',
                'Resumen del Día',
                Icons.today,
                Colors.blue,
              ),
              _buildReportMenuItem(
                context,
                'ventas',
                'Ventas',
                Icons.shopping_cart,
                Colors.purple,
              ),
              _buildReportMenuItem(
                context,
                'fventas',
                'FVentas',
                Icons.receipt,
                Colors.deepPurple,
              ),
              const Divider(height: 1),
              _buildReportMenuItem(
                context,
                'stocks',
                'Stocks',
                Icons.warehouse,
                Colors.orange,
              ),
              _buildReportMenuItem(
                context,
                'codigos',
                'Codigos',
                Icons.qr_code,
                Colors.teal,
              ),
              _buildReportMenuItem(
                context,
                'todocodigos',
                'Todo Codigos',
                Icons.qr_code_scanner,
                Colors.cyan,
              ),
              _buildReportMenuItem(
                context,
                'items',
                'Items',
                Icons.inventory_2,
                Colors.green,
              ),
              _buildReportMenuItem(
                context,
                'gastos',
                'Gastos',
                Icons.receipt_long,
                Colors.red,
              ),
              _buildReportMenuItem(
                context,
                'alertas',
                'Alertas',
                Icons.notifications,
                Colors.orange,
              ),
              // 연결 끊기 버튼
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton.icon(
                  onPressed: _disconnectDatabase,
                  icon: const Icon(Icons.logout, color: Colors.orange, size: 16),
                  label: const Text('Desconectar', style: TextStyle(color: Colors.orange, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
            // resumen 선택 시 패널 확장 유지
            _isLeftPanelCollapsed = false;
          } else {
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
              case 'gastos':
                _selectedReportType = ReportType.gastos;
                break;
              case 'alertas':
                _selectedReportType = ReportType.alertas;
                break;
              case 'ventas':
                _selectedReportType = ReportType.ventas;
                break;
              case 'fventas':
                _selectedReportType = ReportType.fventas;
                break;
              default:
                _selectedReportType = null;
            }
            // 보고서 선택 시 큰 화면에서 왼쪽 패널 자동 축소
            if (_isLargeScreen(context)) {
              _isLeftPanelCollapsed = true;
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
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey[800],
                  fontSize: 12,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  // 데이터베이스 연결 끊기
  Future<void> _disconnectDatabase() async {
    if (_databaseService != null) {
      try {
        await _databaseService!.disconnectDatabase();
      } catch (e) {
        print('❌ 연결 끊기 오류: $e');
      }
    }
    
    setState(() {
      _isConnected = false;
      _currentServerUrl = null;
      _currentDatabaseName = null;
      _databaseService = null;
      _selectedReportType = null;
      _currentReport = 'resumen';
      _isLeftPanelCollapsed = false; // 연결 해제 시 패널 확장
    });
  }

  // 오른쪽 패널 빌드 (보고서 결과 또는 안내)
  Widget _buildRightPanel(BuildContext context) {
    if (!_isConnected) {
      // 연결 전: 안내 메시지
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.storage_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 24),
              Text(
                'Conecte a la base de datos',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingrese la información de conexión en el panel izquierdo\ny haga clic en el botón de conectar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 연결 후: 보고서 결과 표시
    if (_selectedReportType != null && _currentServerUrl != null) {
      // ventas 보고서는 항상 오늘 날짜로 요청
      if (_selectedReportType == ReportType.ventas) {
        return ReportScreen(
          serverUrl: _currentServerUrl!,
          reportType: _selectedReportType!,
          initialDate: DateTime.now(), // 오늘 날짜로 설정
        );
      }
      return ReportScreen(
        serverUrl: _currentServerUrl!,
        reportType: _selectedReportType!,
      );
    }
    
    // 기본: Resumen del Día 표시
    if (_currentServerUrl != null) {
      return ResumenDelDiaScreen(
        serverUrl: _currentServerUrl!,
      );
    }
    
    return Container(
      color: Colors.white,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLargeScreen = _isLargeScreen(context);
    
    // 자동 연결 중일 때 로딩 화면 표시
    if (_isAutoConnecting) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.connecting,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // 큰 화면인 경우: 항상 왼쪽 패널(메뉴) + 오른쪽 콘텐츠 분할 레이아웃
    if (isLargeScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.databaseConnection),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Row(
          children: [
            // 왼쪽: 연결 리스트 + 연결 폼 / 보고서 메뉴 (선택 가능하도록 항상 표시)
            _buildLeftPanel(context),
            // 오른쪽: 보고서 결과 또는 안내
            Expanded(
              child: _buildRightPanel(context),
            ),
          ],
        ),
      );
    }
    
    // 핸드폰: 기존 방식 유지
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.databaseConnection),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdditionalConnectionsScreen(),
                ),
              ).then((_) {
                _loadSavedConnections();
              });
            },
            tooltip: l10n.additionalConnections,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // 회사 로고
              Center(
                child: Image.asset(
                  'assets/logo.jpg',
                  height: 240,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 240,
                      child: Icon(Icons.image, size: 160, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // 저장된 연결 목록 표시
              if (_savedConnections.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.storage, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      l10n.savedConnections,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._savedConnections.map((connection) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.storage, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        connection.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.serverLabel}: ${connection.serverUrl}',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${l10n.dbLabel}: ${connection.databaseName}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.green),
                        onPressed: _isLoading ? null : () => _connectWithSavedConnection(connection),
                        tooltip: l10n.connectWithThisConnection,
                      ),
                      onTap: _isLoading ? null : () => _connectWithSavedConnection(connection),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
              ],
              // Profile Name과 언어 선택을 한 행에 배치
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _profileNameController,
                      decoration: InputDecoration(
                        labelText: 'Profile Name',
                        hintText: l10n.profileNameHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.none,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: widget.currentLocale?.languageCode ?? 
                             (Localizations.localeOf(context).languageCode == 'es' || 
                              Localizations.localeOf(context).languageCode == 'en' ||
                              Localizations.localeOf(context).languageCode == 'ko'
                              ? Localizations.localeOf(context).languageCode
                              : 'es'),
                      decoration: InputDecoration(
                        labelText: l10n.language,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.language),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        isDense: true,
                      ),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'es',
                          child: Text(
                            'Esp',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(
                            'Eng',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'ko',
                          child: Text(
                            'Kor',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                      onChanged: widget.onLanguageChanged != null ? (value) {
                        if (value != null) {
                          widget.onLanguageChanged!(Locale(value, ''));
                        }
                      } : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 서버 타입 선택
              Text(
                l10n.serverType,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<ServerType>(
                      title: const Text('Hostinger Principal'),
                      value: ServerType.hostinger,
                      groupValue: _selectedServerType,
                      onChanged: _onServerTypeChanged,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<ServerType>(
                      title: const Text('Local IP'),
                      value: ServerType.local,
                      groupValue: _selectedServerType,
                      onChanged: _onServerTypeChanged,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              // 로컬 IP 입력 필드 (Local 선택 시에만 표시)
              if (_selectedServerType == ServerType.local)
                TextFormField(
                  controller: _localIpController,
                  decoration: InputDecoration(
                    labelText: l10n.localIpAddress,
                    hintText: l10n.localIpHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.computer),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: _onLocalIpChanged,
                  validator: (value) {
                    if (_selectedServerType == ServerType.local) {
                      if (value == null || value.isEmpty) {
                        return l10n.localIpRequired;
                      }
                      // 간단한 IP 형식 검증
                      final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                      if (!ipRegex.hasMatch(value)) {
                        return l10n.invalidIpAddress;
                      }
                    }
                    return null;
                  },
                ),
              if (_selectedServerType == ServerType.local)
                const SizedBox(height: 16),
              // 서버 URL (읽기 전용으로 표시)
              TextFormField(
                controller: _serverUrlController,
                decoration: InputDecoration(
                  labelText: l10n.serverUrl,
                  hintText: 'http://localhost:3000',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.link),
                ),
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _databaseNameController,
                decoration: InputDecoration(
                  labelText: l10n.databaseName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.storage),
                  helperText: l10n.alphanumericOnly,
                ),
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.databaseNameRequired;
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                    return l10n.alphanumericOnly;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 사용자 이름과 암호를 한 줄에 나란히 배치
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: l10n.username,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                        helperText: l10n.alphanumericOnly,
                      ),
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.usernameRequired;
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                          return l10n.alphanumericOnly;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.passwordRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _connectToDatabase,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        l10n.connect,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  // 연결 추가 화면으로 이동
                  final result = await Navigator.push<ConnectionInfo>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConnectionScreen(),
                    ),
                  );
                  // 연결 화면에서 돌아왔을 때 리스트 갱신
                  if (mounted) {
                    print('🔄 연결 추가 화면에서 돌아옴, 리스트 갱신 중...');
                    print('   결과: ${result != null ? result.name : "null"}');
                    // 약간의 지연 후 리스트 갱신 (저장이 완전히 완료되도록)
                    await Future.delayed(const Duration(milliseconds: 100));
                    await _loadSavedConnections();
                    if (result != null) {
                      print('✅ 새 연결 추가됨: ${result.name}');
                    }
                    // UI 강제 업데이트
                    if (mounted) {
                      setState(() {});
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addConnection),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

