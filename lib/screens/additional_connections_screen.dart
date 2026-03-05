import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/connection_info.dart';
import '../services/connection_storage_service.dart';
import '../services/database_service.dart';
import 'connection_screen.dart';
import 'resumen_del_dia_screen.dart';

class AdditionalConnectionsScreen extends StatefulWidget {
  const AdditionalConnectionsScreen({super.key});

  @override
  State<AdditionalConnectionsScreen> createState() => _AdditionalConnectionsScreenState();
}

class _AdditionalConnectionsScreenState extends State<AdditionalConnectionsScreen> {
  final ConnectionStorageService _storageService = ConnectionStorageService();
  List<ConnectionInfo> _connections = [];
  bool _isLoading = true;
  bool _isLoadingConnections = false; // 중복 호출 방지

  @override
  void initState() {
    super.initState();
    print('🚀 AdditionalConnectionsScreen: initState 호출');
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    // 중복 호출 방지
    if (_isLoadingConnections) {
      print('⚠️ AdditionalConnectionsScreen: 이미 로딩 중이므로 스킵');
      return;
    }

    _isLoadingConnections = true;
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 AdditionalConnectionsScreen: 연결 리스트 로드 시작...');
      final connections = await _storageService.getAllConnections();
      print('✅ AdditionalConnectionsScreen: ${connections.length}개 연결 로드 완료');
      
      for (var conn in connections) {
        print('   - ${conn.name} (ID: ${conn.id}, DB: ${conn.databaseName})');
      }
      
      if (mounted) {
        setState(() {
          _connections = connections;
          _isLoading = false;
        });
        print('🔄 AdditionalConnectionsScreen: UI 업데이트 완료 (${_connections.length}개 연결 표시)');
        print('   현재 _connections 리스트:');
        for (var conn in _connections) {
          print('     - ${conn.name}');
        }
      }
    } catch (e) {
      print('❌ AdditionalConnectionsScreen: 연결 리스트 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } finally {
      _isLoadingConnections = false;
    }
  }

  Future<void> _showLongPressOptions(ConnectionInfo connection) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(connection.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Modifica'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(l10n.delete),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (result == 'edit') {
      Navigator.push<ConnectionInfo>(
        context,
        MaterialPageRoute(
          builder: (context) => ConnectionScreen(
            connection: connection,
          ),
        ),
      ).then((savedConnection) {
        if (mounted) {
          print('🔄 AdditionalConnectionsScreen: 연결 편집 화면에서 돌아옴');
          // 약간의 지연 후 리스트 갱신
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _loadConnections();
              setState(() {}); // UI 강제 업데이트
            }
          });
        }
      });
    } else if (result == 'delete') {
      _deleteConnection(connection);
    }
  }

  Future<void> _deleteConnection(ConnectionInfo connection) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConnection),
        content: Text(l10n.deleteConnectionConfirm(connection.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.deleteConnection(connection.id);
      _loadConnections();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.connectionDeleted)),
        );
      }
    }
  }

  Future<void> _connectToDatabase(ConnectionInfo connection) async {
    final service = DatabaseService(serverUrl: connection.serverUrl);
    try {
      // 연결 변경 시 기존 캐시 초기화
      service.clearTiposTemporadasCache();
      
      final request = DatabaseConnectionRequest(
        databaseName: connection.databaseName,
        username: connection.username,
        password: connection.password,
      );

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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ResumenDelDiaScreen(
              serverUrl: connection.serverUrl,
            ),
          ),
          (route) => false,
        );
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.connectionFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.error(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      service.dispose(); // HTTP 클라이언트 정리, 연결 풀 낭비 방지
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.additionalConnections),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _connections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storage_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noAdditionalConnections,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.addFromMainScreen,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _connections.length,
                  itemBuilder: (context, index) {
                    final connection = _connections[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.storage, color: Colors.white),
                        ),
                        title: Text(
                          connection.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(l10n.server(connection.serverUrl)),
                            Text(l10n.db(connection.databaseName)),
                            Text(l10n.port(connection.port?.toString() ?? "N/A")),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'connect') {
                              _connectToDatabase(connection);
                            } else if (value == 'edit') {
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () {
                                    Navigator.push<ConnectionInfo>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ConnectionScreen(
                                          connection: connection,
                                        ),
                                      ),
                                    ).then((savedConnection) {
                                      if (mounted) {
                                        print('🔄 AdditionalConnectionsScreen: 연결 편집 화면에서 돌아옴');
                                        Future.delayed(const Duration(milliseconds: 100), () {
                                          if (mounted) {
                                            _loadConnections();
                                            setState(() {}); // UI 강제 업데이트
                                          }
                                        });
                                      }
                                    });
                                  },
                                );
                            } else if (value == 'delete') {
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () => _deleteConnection(connection),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'connect',
                              child: Row(
                                children: [
                                  const Icon(Icons.play_arrow, size: 20, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(l10n.connect),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, size: 20),
                                  const SizedBox(width: 8),
                                  Text(l10n.edit),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete, size: 20, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _connectToDatabase(connection),
                        onLongPress: () => _showLongPressOptions(connection),
                      ),
                    );
                  },
                ),
    );
  }
}

