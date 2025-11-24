import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/database_service.dart';
import '../models/connection_info.dart';
import '../services/connection_storage_service.dart';
import 'celebration_screen.dart';
import 'connection_screen.dart';
import 'additional_connections_screen.dart';
import 'resumen_del_dia_screen.dart';

class MainConnectionScreen extends StatefulWidget {
  const MainConnectionScreen({super.key});

  @override
  State<MainConnectionScreen> createState() => _MainConnectionScreenState();
}

enum ServerType {
  hostinger,
  local,
}

class _MainConnectionScreenState extends State<MainConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _databaseNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController();
  final _serverUrlController = TextEditingController();
  final _localIpController = TextEditingController();
  
  ServerType _selectedServerType = ServerType.hostinger;
  bool _isLoading = false;
  bool _isAutoConnecting = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _checkAndAutoConnect();
  }
  
  // 저장된 연결 정보 확인 후 자동 연결
  Future<void> _checkAndAutoConnect() async {
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
      // 포트 번호 가져오기
      final portStr = await _storage.read(key: 'port') ?? '3030';
      final port = int.tryParse(portStr) ?? 3030;
      
      final service = DatabaseService(serverUrl: serverUrl);
      
      final request = DatabaseConnectionRequest(
        databaseName: databaseName,
        username: username,
        password: password,
        port: port,
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
        });
        await _loadSavedConnectionInfo();
      }
    } catch (e) {
      // 자동 연결 실패 시 연결 화면 표시
      setState(() {
        _isAutoConnecting = false;
        _errorMessage = '자동 연결 실패: ${e.toString().replaceFirst('Exception: ', '')}';
      });
      await _loadSavedConnectionInfo();
    }
  }

  @override
  void dispose() {
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
      final serverType = await _storage.read(key: 'server_type');
      final databaseName = await _storage.read(key: 'database_name') ?? '';
      final username = await _storage.read(key: 'username') ?? '';
      final password = await _storage.read(key: 'password') ?? '';
      final localIp = await _storage.read(key: 'local_ip') ?? '';
      
      setState(() {
        if (serverType == 'local') {
          _selectedServerType = ServerType.local;
          _localIpController.text = localIp;
          _serverUrlController.text = localIp.isNotEmpty ? 'http://$localIp:3030' : '';
          _portController.text = '3030';
        } else {
          _selectedServerType = ServerType.hostinger;
          _serverUrlController.text = 'https://sync.coolsistema.com';
          _portController.text = '';
        }
        _databaseNameController.text = databaseName;
        _usernameController.text = username;
        _passwordController.text = password;
      });
    } catch (e) {
      // 저장된 정보가 없거나 오류가 발생한 경우 기본값 사용
      setState(() {
        _selectedServerType = ServerType.hostinger;
        _serverUrlController.text = 'https://sync.coolsistema.com';
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
        _portController.text = '';
        _localIpController.clear();
      } else {
        // Local 선택 시
        _serverUrlController.text = _localIpController.text.isNotEmpty 
            ? 'http://${_localIpController.text}:3030' 
            : '';
        _portController.text = '3030';
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
        await _storage.write(key: 'port', value: _portController.text.trim());
      } else {
        await _storage.write(key: 'port', value: '');
      }
      // 연결 성공 플래그 저장
      await _storage.write(key: 'connection_success', value: 'true');
    } catch (e) {
      // 저장 실패 시 무시
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
      // 포트 번호 처리
      int port;
      if (_selectedServerType == ServerType.hostinger) {
        // Hostinger는 포트 번호가 필요 없을 수 있으므로 기본값 사용
        port = 443; // HTTPS 기본 포트
      } else {
        port = int.parse(_portController.text);
      }
      
      final service = DatabaseService(
        serverUrl: _serverUrlController.text.trim(),
      );

      final request = DatabaseConnectionRequest(
        databaseName: _databaseNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        port: port,
      );

      final success = await service.connectToDatabase(request);

      if (success && mounted) {
        // 연결 성공 시 정보 저장
        await _saveConnectionInfo();
        
        // resumen_del_dia 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResumenDelDiaScreen(
              serverUrl: _serverUrlController.text.trim(),
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
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 24),
                Text(
                  '자동 연결 중...',
                  style: TextStyle(
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
        title: const Text('데이터베이스 연결'),
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
              );
            },
            tooltip: '추가 연결 관리',
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
              const SizedBox(height: 24),
              // 서버 타입 선택 콤보박스
              DropdownButtonFormField<ServerType>(
                value: _selectedServerType,
                decoration: const InputDecoration(
                  labelText: '서버 타입',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cloud),
                ),
                items: const [
                  DropdownMenuItem(
                    value: ServerType.hostinger,
                    child: Text('Hostinger principal Server'),
                  ),
                  DropdownMenuItem(
                    value: ServerType.local,
                    child: Text('Local database con IP'),
                  ),
                ],
                onChanged: _onServerTypeChanged,
              ),
              const SizedBox(height: 16),
              // 로컬 IP 입력 필드 (Local 선택 시에만 표시)
              if (_selectedServerType == ServerType.local)
                TextFormField(
                  controller: _localIpController,
                  decoration: const InputDecoration(
                    labelText: 'IP 주소',
                    hintText: '192.168.1.100',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.computer),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: _onLocalIpChanged,
                  validator: (value) {
                    if (_selectedServerType == ServerType.local) {
                      if (value == null || value.isEmpty) {
                        return 'IP 주소를 입력해주세요';
                      }
                      // 간단한 IP 형식 검증
                      final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                      if (!ipRegex.hasMatch(value)) {
                        return '유효한 IP 주소를 입력해주세요';
                      }
                    }
                    return null;
                  },
                ),
              if (_selectedServerType == ServerType.local) const SizedBox(height: 16),
              // 서버 URL 표시 (읽기 전용)
              TextFormField(
                controller: _serverUrlController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: '서버 URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _databaseNameController,
                decoration: const InputDecoration(
                  labelText: '데이터베이스 이름',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.storage),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '데이터베이스 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '사용자 이름',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '사용자 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '암호',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '암호를 입력해주세요';
                  }
                  return null;
                },
              ),
              // 포트 번호 필드 (Local 선택 시에만 표시)
              if (_selectedServerType == ServerType.local) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _portController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: '포트 번호',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                    helperText: '포트 3030이 자동으로 사용됩니다',
                  ),
                ),
              ],
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
                    : const Text(
                        '연결하기',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConnectionScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('연결 추가하기'),
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

