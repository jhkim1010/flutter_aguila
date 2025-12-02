import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:math';
import 'dart:ui';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../models/connection_info.dart';
import '../services/connection_storage_service.dart';
import 'celebration_screen.dart';
import 'connection_screen.dart';
import 'additional_connections_screen.dart';
import 'resumen_del_dia_screen.dart';
import 'connection_list_screen.dart';

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
  ServerType _selectedServerType = ServerType.hostinger;
  bool _isLoading = false;
  bool _isAutoConnecting = false;
  bool _isConnected = false; // 연결 성공 여부
  String? _errorMessage;
  List<ConnectionInfo> _savedConnections = [];
  bool _isLoadingConnections = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // 연결 ID 생성
  String _generateConnectionId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
  
  @override
  void initState() {
    super.initState();
    _checkAndAutoConnect();
    _loadSavedConnections();
    // 백그라운드에서 생체 인식 수행
    _authenticateInBackground();
  }

  // 백그라운드에서 생체 인식 수행
  Future<void> _authenticateInBackground() async {
    try {
      final bool isSupported = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      
      if (isSupported && canCheckBiometrics) {
        // 약간의 지연 후 백그라운드에서 인증 시도
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          try {
            final bool didAuthenticate = await _localAuth.authenticate(
              localizedReason: 'Se requiere autenticación biométrica para usar la aplicación',
              options: const AuthenticationOptions(
                biometricOnly: false,
                stickyAuth: true,
              ),
            );
            
            if (!didAuthenticate && mounted) {
              // 인증 실패 시에도 화면은 계속 표시
              print('🔐 생체 인식 실패 또는 취소됨');
            }
          } on PlatformException catch (e) {
            print('❌ 생체 인식 오류: ${e.message}');
            // 오류 발생 시에도 화면은 계속 표시
          } catch (e) {
            print('❌ 생체 인식 알 수 없는 오류: $e');
            // 오류 발생 시에도 화면은 계속 표시
          }
        }
      }
    } catch (e) {
      print('❌ 생체 인식 확인 오류: $e');
      // 생체 인식이 지원되지 않거나 오류가 발생해도 화면은 계속 표시
    }
  }

  // 저장된 연결 목록 불러오기
  Future<void> _loadSavedConnections() async {
    setState(() {
      _isLoadingConnections = true;
    });

    try {
      final connections = await _connectionStorageService.getAllConnections();
      if (mounted) {
        setState(() {
          _savedConnections = connections;
          _isLoadingConnections = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingConnections = false;
        });
      }
    }
  }

  // 저장된 연결로 연결 시도
  Future<void> _connectWithSavedConnection(ConnectionInfo connection) async {
    try {
      // 로딩 표시
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final service = DatabaseService(serverUrl: connection.serverUrl);

      final request = DatabaseConnectionRequest(
        databaseName: connection.databaseName,
        username: connection.username,
        password: connection.password,
      );

      final success = await service.connectToDatabase(request);

      if (success && mounted) {
        // 연결 정보를 secure storage에 저장
        await _storage.write(key: 'database_name', value: connection.databaseName);
        await _storage.write(key: 'username', value: connection.username);
        await _storage.write(key: 'password', value: connection.password);
        await _storage.write(key: 'server_url', value: connection.serverUrl);
        await _storage.write(key: 'connection_success', value: 'true');
        await _storage.write(key: 'profile_name', value: connection.name);

        // 축하 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CelebrationScreen(
              serverUrl: connection.serverUrl,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = '연결에 실패했습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    }
  }
  
  // 저장된 연결 정보 확인 후 자동 연결
  Future<void> _checkAndAutoConnect() async {
    // skipAutoConnect가 true이면 자동 연결하지 않음
    if (widget.skipAutoConnect) {
      await _loadSavedConnectionInfo();
      return;
    }
    
    try {
      final serverUrl = await _storage.read(key: 'server_url');
      final databaseName = await _storage.read(key: 'database_name');
      final username = await _storage.read(key: 'username');
      final password = await _storage.read(key: 'password');
      final connectionSuccess = await _storage.read(key: 'connection_success');
      
      // 저장된 연결 정보가 있고, 이전에 연결 성공한 경우 자동 연결
      if (serverUrl != null && 
          serverUrl.isNotEmpty &&
          databaseName != null && 
          databaseName.isNotEmpty &&
          username != null && 
          username.isNotEmpty &&
          password != null && 
          password.isNotEmpty &&
          connectionSuccess == 'true') {
        
        setState(() {
          _isAutoConnecting = true;
        });
        
        // 저장된 정보로 자동 연결 시도
        await _autoConnectToDatabase(
          serverUrl: serverUrl,
          databaseName: databaseName,
          username: username,
          password: password,
        );
      } else {
        // 저장된 정보가 없으면 기존처럼 로드
        await _loadSavedConnectionInfo();
      }
    } catch (e) {
      // 오류 발생 시 기존 방식으로 로드
      await _loadSavedConnectionInfo();
    }
  }
  
  // 자동 연결 시도
  Future<void> _autoConnectToDatabase({
    required String serverUrl,
    required String databaseName,
    required String username,
    required String password,
  }) async {
    try {
      final service = DatabaseService(serverUrl: serverUrl);
      
      final request = DatabaseConnectionRequest(
        databaseName: databaseName,
        username: username,
        password: password,
      );

      final success = await service.connectToDatabase(request);

      if (success && mounted) {
        // 자동 연결 성공 시 resumen_del_dia로 바로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResumenDelDiaScreen(
              serverUrl: serverUrl,
            ),
          ),
        );
      } else {
        // 자동 연결 실패 시 연결 화면 표시
        setState(() {
          _isAutoConnecting = false;
          _isConnected = false;
        });
        await _loadSavedConnectionInfo();
      }
    } catch (e) {
      // 자동 연결 실패 시 연결 화면 표시
      setState(() {
        _isAutoConnecting = false;
        _isConnected = false;
        _errorMessage = '자동 연결 실패: ${e.toString().replaceFirst('Exception: ', '')}';
      });
      await _loadSavedConnectionInfo();
    }
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    _databaseNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    _serverUrlController.dispose();
    _localIpController.dispose();
    super.dispose();
  }
  
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // 저장된 기본 연결 정보 불러오기
  Future<void> _loadSavedConnectionInfo() async {
    try {
      final profileName = await _storage.read(key: 'profile_name') ?? '';
      final serverType = await _storage.read(key: 'server_type');
      final databaseName = await _storage.read(key: 'database_name') ?? '';
      final username = await _storage.read(key: 'username') ?? '';
      final password = await _storage.read(key: 'password') ?? '';
      final localIp = await _storage.read(key: 'local_ip') ?? '';
      final connectionSuccess = await _storage.read(key: 'connection_success');
      
      setState(() {
        _profileNameController.text = profileName;
        if (serverType == 'local') {
          _selectedServerType = ServerType.local;
          _localIpController.text = localIp;
          _serverUrlController.text = localIp.isNotEmpty ? 'http://$localIp:3030' : '';
        } else {
          _selectedServerType = ServerType.hostinger;
          _serverUrlController.text = 'https://sync.coolsistema.com';
        }
        _databaseNameController.text = databaseName;
        _usernameController.text = username;
        _passwordController.text = password;
        _isConnected = connectionSuccess == 'true';
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
      await _storage.write(key: 'profile_name', value: _profileNameController.text.trim());
      await _storage.write(
        key: 'server_type', 
        value: _selectedServerType == ServerType.hostinger ? 'hostinger' : 'local',
      );
      await _storage.write(key: 'server_url', value: _serverUrlController.text.trim());
      await _storage.write(key: 'database_name', value: _databaseNameController.text.trim());
      await _storage.write(key: 'username', value: _usernameController.text.trim());
      await _storage.write(key: 'password', value: _passwordController.text.trim());
      if (_selectedServerType == ServerType.local) {
        await _storage.write(key: 'local_ip', value: _localIpController.text.trim());
        await _storage.write(key: 'port', value: '3030'); // Local은 항상 3030 포트 사용
      } else {
        await _storage.write(key: 'port', value: '');
      }
      // 연결 성공 플래그 저장
      await _storage.write(key: 'connection_success', value: 'true');
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

    try {
      final serverUrl = _serverUrlController.text.trim();
      
      final service = DatabaseService(serverUrl: serverUrl);

      final request = DatabaseConnectionRequest(
        databaseName: _databaseNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      print('=== 연결 시작 ===');
      print('서버 URL: ${_serverUrlController.text.trim()}');
      print('데이터베이스: ${_databaseNameController.text.trim()}');
      print('사용자: ${_usernameController.text.trim()}');
      
      final success = await service.connectToDatabase(request);

      if (success && mounted) {
        print('✅ 연결 성공 - 정보 저장 및 축하 화면 이동');
        // 연결 성공 시 정보 저장
        await _saveConnectionInfo();
        
        // 연결 목록에도 저장
        await _saveToConnectionList();
        
        // 연결 목록 갱신
        await _loadSavedConnections();
        
        // 축하 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CelebrationScreen(
              serverUrl: _serverUrlController.text.trim(),
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = '연결에 실패했습니다. (상태 코드 확인 필요)';
          _isLoading = false;
          _isConnected = false;
        });
      }
    } catch (e) {
      print('❌ 연결 오류 발생: $e');
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = errorMessage;
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
                    '${l10n.error(errorMessage)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.checkItems),
                  const Text('• 서버 URL이 올바른지 확인'),
                  const Text('• 서버가 실행 중인지 확인'),
                  const Text('• 인터넷 연결 상태 확인'),
                  const Text('• 방화벽 설정 확인'),
                  const SizedBox(height: 16),
                  const Text(
                    '자세한 로그는 터미널/콘솔을 확인하세요.',
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
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
                // 연결 목록 화면에서 돌아왔을 때 목록 갱신
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
                }).toList(),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
              ],
              // 연결 성공 시 연결 전환 아이콘 표시
              if (_isConnected)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConnectionListScreen(),
                          ),
                        ).then((_) {
                          // 연결 목록에서 돌아왔을 때 상태 갱신
                          _loadSavedConnectionInfo();
                          _loadSavedConnections();
                        });
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.switchToAnotherConnection,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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
                      value: widget.currentLocale?.languageCode ?? 
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
                onPressed: () {
                  // 연결 추가하기 버튼을 눌러도 현재 화면 유지
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => const ConnectionScreen(),
                  //   ),
                  // );
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

