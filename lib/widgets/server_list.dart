import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/server.dart';
import '../providers/server_provider.dart';
import '../services/supabase_service.dart';
import 'create_server_dialog.dart';

class ServerList extends ConsumerWidget {
  final bool isBottomBar;

  const ServerList({
    super.key,
    this.isBottomBar = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversAsync = ref.watch(serversStreamProvider);
    final selectedServer = ref.watch(selectedServerProvider);

    if (isBottomBar) {
      return _buildMobileBar(context, ref, serversAsync);
    }

    return Container(
      width: 72,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Add Server Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _ServerIcon(
              onTap: () => _showCreateServerDialog(context, ref),
              child: const Icon(
                Icons.add,
                color: Colors.green,
                size: 32,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Divider(color: Colors.white24, height: 1),
          ),
          // Server List
          Expanded(
            child: serversAsync.when(
              data: (servers) => ListView.builder(
                itemCount: servers.length,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, index) {
                  final server = servers[index];
                  final isSelected = server.id == selectedServer?.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ServerIcon(
                      isSelected: isSelected,
                      onTap: () => ref.read(selectedServerProvider.notifier).state = server,
                      child: server.iconUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(
                                server.iconUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildServerInitials(server.name),
                              ),
                            )
                          : _buildServerInitials(server.name),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBar(BuildContext context, WidgetRef ref, AsyncValue<List<Server>> serversAsync) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: serversAsync.when(
        data: (servers) => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: servers.length + 1, // +1 for add button
          itemBuilder: (context, index) {
            if (index == 0) {
              return IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCreateServerDialog(context, ref),
                tooltip: 'Create Server',
              );
            }
            final server = servers[index - 1];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _ServerIcon(
                onTap: () => ref.read(selectedServerProvider.notifier).state = server,
                child: server.iconUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          server.iconUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: _buildServerInitials(server.name),
                            ),
                        ),
                      )
                    : SizedBox(
                        width: 40,
                        height: 40,
                        child: _buildServerInitials(server.name),
                      ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildServerInitials(String name) {
    final initials = name.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<void> _showCreateServerDialog(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (BuildContext context) => const CreateServerDialog(),
    );

    if (result != null && context.mounted) {
      try {
        final server = await ref.read(supabaseServiceProvider).createServer(
          result['name']!,
          iconUrl: result['iconUrl'],
        );
        if (context.mounted) {
          ref.read(selectedServerProvider.notifier).state = server;
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create server: $e')),
          );
        }
      }
    }
  }
}

class _ServerIcon extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isSelected;

  const _ServerIcon({
    required this.child,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(child: child),
      ),
    );
  }
}
