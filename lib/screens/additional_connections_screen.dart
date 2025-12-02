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

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    setState(() {
      _isLoading = true;
    });

    final connections = await _storageService.getAllConnections();
    
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConnectionScreen(
            connection: connection,
          ),
        ),
      ).then((_) => _loadConnections());
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ConnectionScreen(
                                          connection: connection,
                                        ),
                                      ),
                                    ).then((_) => _loadConnections());
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
    );
  }
}

