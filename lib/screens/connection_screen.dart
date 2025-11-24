import 'package:flutter/material.dart';
import 'dart:math';
import '../models/connection_info.dart';
import '../services/connection_storage_service.dart';
import '../services/database_service.dart';
import 'celebration_screen.dart';

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
  
  final ConnectionStorageService _storageService = ConnectionStorageService();
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
      _portController.text = widget.connection!.port.toString();
    } else {
      // 새 연결 추가 모드
      _connectionId = _generateId();
      _serverUrlController.text = 'http://localhost:3000';
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
    super.dispose();
  }
  
  // 연결 정보 저장하기
  Future<void> _saveConnectionInfo() async {
    try {
      final connection = ConnectionInfo(
        id: _connectionId!,
        name: _connectionNameController.text.trim(),
        serverUrl: _serverUrlController.text.trim(),
        databaseName: _databaseNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        port: int.parse(_portController.text.trim()),
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
      final port = int.parse(_portController.text);
      
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
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const CelebrationScreen(),
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
              TextFormField(
                controller: _connectionNameController,
                decoration: const InputDecoration(
                  labelText: '연결 이름',
                  hintText: '예: 프로덕션 DB, 개발 DB',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '연결 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serverUrlController,
                decoration: const InputDecoration(
                  labelText: '서버 URL',
                  hintText: 'http://localhost:3000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '서버 URL을 입력해주세요';
                  }
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasAbsolutePath) {
                    return '유효한 URL을 입력해주세요';
                  }
                  return null;
                },
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: '포트 번호',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '포트 번호를 입력해주세요';
                  }
                  final port = int.tryParse(value);
                  if (port == null || port < 1 || port > 65535) {
                    return '유효한 포트 번호를 입력해주세요 (1-65535)';
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

