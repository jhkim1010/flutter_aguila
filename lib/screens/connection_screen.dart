import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/connection_info.dart';
import '../services/connection_storage_service.dart';
import '../services/database_service.dart';
import 'celebration_screen.dart';

enum ServerType {
  hostinger,
  local,
}

class ConnectionScreen extends StatefulWidget {
  final ConnectionInfo? connection;

  const ConnectionScreen({super.key, this.connection});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _connectionNameController = TextEditingController();
  final _databaseNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController();
  final _serverUrlController = TextEditingController();
  final _localIpController = TextEditingController();
  
  final ConnectionStorageService _storageService = ConnectionStorageService();
  ServerType _selectedServerType = ServerType.hostinger;
  bool _isLoading = false;
  String? _errorMessage;
  String? _connectionId;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.connection != null) {
      // 기존 연결 수정 모드
      _isEditing = true;
      _connectionId = widget.connection!.id;
      _connectionNameController.text = widget.connection!.name;
      _serverUrlController.text = widget.connection!.serverUrl;
      _databaseNameController.text = widget.connection!.databaseName;
      _usernameController.text = widget.connection!.username;
      _passwordController.text = widget.connection!.password;
      
      // 서버 URL에서 서버 타입 판단
      if (_serverUrlController.text.contains('sync.coolsistema.com')) {
        _selectedServerType = ServerType.hostinger;
      } else {
        _selectedServerType = ServerType.local;
        // Local IP 추출
        final uri = Uri.tryParse(_serverUrlController.text);
        if (uri != null) {
          _localIpController.text = uri.host;
        }
      }
    } else {
      // 새 연결 추가 모드
      _connectionId = _generateId();
      _selectedServerType = ServerType.hostinger;
      _serverUrlController.text = 'https://sync.coolsistema.com';
    }
  }
  
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  @override
  void dispose() {
    _connectionNameController.dispose();
    _databaseNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    _serverUrlController.dispose();
    _localIpController.dispose();
    super.dispose();
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
  
  // 연결 정보 저장하기
  Future<void> _saveConnectionInfo() async {
    try {
      // 포트 번호 추출 (서버 URL에서)
      int port = 3030; // 기본값
      final uri = Uri.tryParse(_serverUrlController.text.trim());
      if (uri != null && uri.hasPort) {
        port = uri.port;
      }
      
      final connection = ConnectionInfo(
        id: _connectionId!,
        name: _connectionNameController.text.trim(),
        serverUrl: _serverUrlController.text.trim(),
        databaseName: _databaseNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        port: port,
      );
      
      await _storageService.saveConnection(connection);
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
      // 포트 번호는 전송하지 않음 (서버 URL에 이미 포함되어 있음)
      final service = DatabaseService(
        serverUrl: _serverUrlController.text.trim(),
      );

      final request = DatabaseConnectionRequest(
        databaseName: _databaseNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        port: null, // 포트 번호는 전송하지 않음
      );

      final success = await service.connectToDatabase(request);

      if (success && mounted) {
        // 연결 성공 시 정보 저장
        await _saveConnectionInfo();
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => CelebrationScreen(
              serverUrl: _serverUrlController.text.trim(),
            ),
          ),
          (route) => false, // 모든 이전 화면 제거
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

  // 연결 정보만 저장 (연결하지 않음)
  Future<void> _saveConnectionOnly() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _saveConnectionInfo();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '연결이 수정되었습니다.' : '연결이 저장되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '저장에 실패했습니다: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '연결 수정' : '새 연결 추가'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
              TextFormField(
                controller: _connectionNameController,
                decoration: const InputDecoration(
                  labelText: '연결 이름',
                  hintText: '예: 프로덕션 DB, 개발 DB',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '연결 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // 서버 타입 선택
              Text(
                '서버 타입',
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
              // 로컬 IP 입력 필드 (Local 선택 시에만 표시)
              if (_selectedServerType == ServerType.local)
                TextFormField(
                  controller: _localIpController,
                  decoration: const InputDecoration(
                    labelText: '로컬 IP 주소',
                    hintText: '예: 192.168.1.100',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.computer),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: _onLocalIpChanged,
                  validator: (value) {
                    if (_selectedServerType == ServerType.local) {
                      if (value == null || value.isEmpty) {
                        return '로컬 IP 주소를 입력해주세요';
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
                decoration: const InputDecoration(
                  labelText: '서버 URL',
                  hintText: 'http://localhost:3000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _databaseNameController,
                decoration: const InputDecoration(
                  labelText: '데이터베이스 이름',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.storage),
                  helperText: '영어와 숫자만 입력 가능합니다',
                ),
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '데이터베이스 이름을 입력해주세요';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                    return '영어와 숫자만 입력 가능합니다';
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
                  helperText: '영어와 숫자만 입력 가능합니다',
                ),
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '사용자 이름을 입력해주세요';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                    return '영어와 숫자만 입력 가능합니다';
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
                        _isEditing ? '수정하고 연결하기' : '저장하고 연결하기',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isLoading ? null : _saveConnectionOnly,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isEditing ? '수정만 하기' : '저장만 하기',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

