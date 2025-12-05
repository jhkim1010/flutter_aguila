import 'package:flutter/material.dart';
import '../models/connection_info.dart';
import '../services/connection_storage_service.dart';
import '../l10n/app_localizations.dart';
import 'connection_screen.dart';
import 'celebration_screen.dart';
import '../services/database_service.dart';

class ConnectionListScreen extends StatefulWidget {
  const ConnectionListScreen({super.key});


  @override
  State<ConnectionListScreen> createState() => _ConnectionListScreenState();
}

class _ConnectionListScreenState extends State<ConnectionListScreen> {
  final ConnectionStorageService _storageService = ConnectionStorageService();
  List<ConnectionInfo> _connections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    setState(() {
      _isLoading = true;
    });

    print('🔄 연결 리스트 로드 시작...');
    final connections = await _storageService.getAllConnections();
    print('✅ 연결 리스트 로드 완료: ${connections.length}개 연결');
    
    setState(() {
      _connections = connections;
      _isLoading = false;
    });
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
          print('🔄 연결 편집 화면에서 돌아옴, 리스트 갱신 중...');
          _loadConnections();
          if (savedConnection != null) {
            print('✅ 연결 수정됨: ${savedConnection.name}');
          }
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
    try {
      final service = DatabaseService(serverUrl: connection.serverUrl);
      
      final request = DatabaseConnectionRequest(
        databaseName: connection.databaseName,
        username: connection.username,
        password: connection.password,
      );

      final success = await service.connectToDatabase(request);

      if (success && mounted) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.databaseConnectionList),
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
                        l10n.noSavedConnections,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.addNewConnection,
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
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, size: 20),
                                  const SizedBox(width: 8),
                                  Text(l10n.edit),
                                ],
                              ),
                              onTap: () {
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
                                        print('🔄 연결 편집 화면에서 돌아옴, 리스트 갱신 중...');
                                        _loadConnections();
                                        if (savedConnection != null) {
                                          print('✅ 연결 수정됨: ${savedConnection.name}');
                                        }
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                            PopupMenuItem(
                              child: Row(
                                children: [
                                  const Icon(Icons.delete, size: 20, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                              onTap: () {
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () => _deleteConnection(connection),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () => _connectToDatabase(connection),
                        onLongPress: () => _showLongPressOptions(connection),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push<ConnectionInfo>(
            context,
            MaterialPageRoute(
              builder: (context) => const ConnectionScreen(),
            ),
          ).then((savedConnection) {
            if (mounted) {
              print('🔄 연결 추가 화면에서 돌아옴, 리스트 갱신 중...');
              _loadConnections();
              if (savedConnection != null) {
                print('✅ 새 연결 추가됨: ${savedConnection.name}');
              }
            }
          });
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addConnection),
      ),
    );
  }
}

