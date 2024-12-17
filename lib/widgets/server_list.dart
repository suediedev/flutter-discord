import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/server.dart';
import '../providers/server_provider.dart';
import '../services/supabase_service.dart';
import 'invite_dialog.dart';
import 'join_server_dialog.dart';

class ServerList extends ConsumerWidget {
  const ServerList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversAsync = ref.watch(serversStreamProvider);

    return Drawer(
      child: Container(
        color: Colors.grey[900],
        child: Column(
          children: [
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Servers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => _createServer(context, ref),
                        tooltip: 'Create Server',
                      ),
                      IconButton(
                        icon: const Icon(Icons.link, color: Colors.white),
                        onPressed: () => _joinServer(context, ref),
                        tooltip: 'Join Server',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: serversAsync.when(
                data: (servers) {
                  if (servers.isEmpty) {
                    return const Center(
                      child: Text(
                        'No servers yet',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: servers.length,
                    itemBuilder: (context, index) {
                      final server = servers[index];
                      return _ServerListTile(server: server);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createServer(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const CreateServerDialog(),
    );

    if (name == null || name.isEmpty) return;

    try {
      await ref.read(supabaseServiceProvider).createServer(name);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating server: $e')),
        );
      }
    }
  }

  Future<void> _joinServer(BuildContext context, WidgetRef ref) async {
    final joined = await showDialog<bool>(
      context: context,
      builder: (context) => const JoinServerDialog(),
    );

    if (joined == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined server!')),
      );
    }
  }
}

class _ServerListTile extends ConsumerWidget {
  final Server server;

  const _ServerListTile({required this.server});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedServer = ref.watch(selectedServerProvider);

    return ListTile(
      selected: selectedServer?.id == server.id,
      selectedTileColor: Colors.blue.withOpacity(0.2),
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(server.name[0].toUpperCase()),
      ),
      title: Text(
        server.name,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () => ref.read(selectedServerProvider.notifier).state = server,
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'invite',
            child: Text('Manage Invites'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete Server'),
          ),
        ],
        onSelected: (value) async {
          switch (value) {
            case 'invite':
              await showDialog(
                context: context,
                builder: (context) => InviteDialog(serverId: server.id),
              );
              break;
            case 'delete':
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Server'),
                  content: Text('Are you sure you want to delete ${server.name}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                try {
                  await ref.read(supabaseServiceProvider).deleteServer(server.id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting server: $e')),
                    );
                  }
                }
              }
              break;
          }
        },
      ),
    );
  }
}

class CreateServerDialog extends StatefulWidget {
  const CreateServerDialog({super.key});

  @override
  State<CreateServerDialog> createState() => _CreateServerDialogState();
}

class _CreateServerDialogState extends State<CreateServerDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create Server',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Server Name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                Navigator.of(context).pop(_nameController.text.trim());
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(_nameController.text.trim());
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
