import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/server.dart';
import '../providers/server_provider.dart';
import '../services/supabase_service.dart';
import '../theme/platform_theme.dart';
import 'invite_dialog.dart';
import 'join_server_dialog.dart';
import 'create_server_dialog.dart';

class ServerList extends ConsumerWidget {
  final bool isBottomBar;

  const ServerList({super.key, this.isBottomBar = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = PlatformTheme.isMobile(context);
    final isIOS = PlatformTheme.isIOS(context);
    final serversAsync = ref.watch(serversStreamProvider);

    if (isBottomBar) {
      return _buildMobileBar(context, ref);
    }

    return SizedBox(
      width: 72,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: _buildServerList(context, ref, serversAsync),
      ),
    );
  }

  Widget _buildMobileBar(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createServer(context, ref),
            tooltip: 'Create Server',
          ),
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: () => _joinServer(context, ref),
            tooltip: 'Join Server',
          ),
        ],
      ),
    );
  }

  Widget _buildServerList(BuildContext context, WidgetRef ref, AsyncValue<List<Server>> serversAsync) {
    return serversAsync.when(
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: servers.length,
          itemBuilder: (context, index) {
            final server = servers[index];
            return _ServerIcon(
              isSelected: ref.watch(selectedServerProvider)?.id == server.id,
              onTap: () => ref.read(selectedServerProvider.notifier).state = server,
              child: Text(
                server.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            );
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
    );
  }

  Future<void> _createServer(BuildContext context, WidgetRef ref) async {
    final server = await showDialog<Server>(
      context: context,
      builder: (context) => const CreateServerDialog(),
    );

    if (server != null) {
      ref.read(selectedServerProvider.notifier).state = server;
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: child),
      ),
    );
  }
}
