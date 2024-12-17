import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/server_provider.dart';
import 'create_server_dialog.dart';

class ServerSidebar extends ConsumerWidget {
  const ServerSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversAsync = ref.watch(serversProvider);
    final selectedServerId = ref.watch(selectedServerProvider);

    return Container(
      width: 72,
      color: Colors.grey[900],
      child: Column(
        children: [
          const SizedBox(height: 12),
          serversAsync.when(
            data: (servers) => Expanded(
              child: ListView.builder(
                itemCount: servers.length + 1, // +1 for add server button
                itemBuilder: (context, index) {
                  if (index == servers.length) {
                    return _buildAddServerButton(context);
                  }

                  final server = servers[index];
                  final isSelected = server.id == selectedServerId;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _ServerIcon(
                      name: server.name,
                      iconUrl: server.iconUrl,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(selectedServerProvider.notifier).state = server.id;
                      },
                    ),
                  );
                },
              ),
            ),
            loading: () => const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(serversProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddServerButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _ServerIcon(
        name: 'Add Server',
        icon: Icons.add,
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => const CreateServerDialog(),
          );
        },
      ),
    );
  }
}

class _ServerIcon extends StatelessWidget {
  const _ServerIcon({
    required this.name,
    this.iconUrl,
    this.icon,
    this.isSelected = false,
    required this.onTap,
  });

  final String name;
  final String? iconUrl;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name,
      preferBelow: false,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(isSelected ? 16 : 24),
            image: iconUrl != null
                ? DecorationImage(
                    image: NetworkImage(iconUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: icon != null
              ? Icon(icon, color: Colors.white)
              : iconUrl == null
                  ? Center(
                      child: Text(
                        name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    )
                  : null,
        ),
      ),
    );
  }
}
