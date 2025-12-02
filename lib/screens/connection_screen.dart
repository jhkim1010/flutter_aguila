import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/connection_info.dart';
import '../services/connection_storage_service.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';
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
      final serverUrl = _serverUrlController.text.trim();
      
      final service = DatabaseService(serverUrl: serverUrl);

      final request = DatabaseConnectionRequest(
        databaseName: _databaseNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
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

    final l10n = AppLocalizations.of(context)!;
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
            content: Text(_isEditing ? l10n.connectionEdited : l10n.connectionSaved),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${l10n.saveFailed}: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editConnection : l10n.newConnection),
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
                decoration: InputDecoration(
                  labelText: l10n.connectionName,
                  hintText: l10n.connectionNameHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.label),
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.connectionNameRequired;
                  }
                  return null;
                },
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
                      title: Text(l10n.hostingerPrincipal),
                      value: ServerType.hostinger,
                      groupValue: _selectedServerType,
                      onChanged: _onServerTypeChanged,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<ServerType>(
                      title: Text(l10n.localIp),
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
              TextFormField(
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
              const SizedBox(height: 16),
              TextFormField(
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
                        _isEditing ? l10n.editAndConnect : l10n.saveAndConnect,
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
                  _isEditing ? l10n.editOnly : l10n.saveOnly,
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

