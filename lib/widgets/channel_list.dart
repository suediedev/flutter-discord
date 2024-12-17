import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/platform_theme.dart';
import '../models/channel.dart';
import '../models/server.dart';
import '../providers/server_provider.dart';
import '../providers/channel_provider.dart';
import '../services/supabase_service.dart';

class ChannelList extends ConsumerWidget {
  final bool isBottomBar;

  const ChannelList({super.key, this.isBottomBar = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedServer = ref.watch(selectedServerProvider);
    
    if (selectedServer == null) {
      return Container(
        width: 240,
        color: Colors.grey[850],
        child: const Center(
          child: Text(
            'Select a server to view channels',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (isBottomBar) {
      return _buildMobileBar(context, ref, selectedServer.id);
    }

    return SizedBox(
      width: 240,
      child: Container(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        child: Column(
          children: [
            _buildHeader(context, ref, selectedServer),
            Expanded(
              child: _buildChannelList(context, ref, selectedServer.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBar(BuildContext context, WidgetRef ref, String serverId) {
    final channelsAsync = ref.watch(channelsProvider(serverId));
    
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              // TODO: Show channel selection bottom sheet
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _buildChannelList(context, ref, serverId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Show settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, Server server) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              server.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showCreateChannelDialog(context, ref, server.id),
            tooltip: 'Create Channel',
          ),
        ],
      ),
    );
  }

  Widget _buildChannelList(BuildContext context, WidgetRef ref, String serverId) {
    final channelsAsync = ref.watch(channelsProvider(serverId));
    final selectedChannelId = ref.watch(selectedChannelProvider);

    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return const Center(
            child: Text(
              'No channels yet',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            final isSelected = channel.id == selectedChannelId;

            return _ChannelTile(
              channel: channel,
              isSelected: isSelected,
              onTap: () => ref.read(selectedChannelProvider.notifier).state = channel.id,
              onDelete: () => _deleteChannel(context, ref, channel),
            );
          },
        );
      },
      loading: () => Center(
        child: PlatformTheme.adaptiveProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Future<void> _showCreateChannelDialog(BuildContext context, WidgetRef ref, String serverId) async {
    final nameController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Channel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Channel Name',
                  border: OutlineInputBorder(),
                ),
                enabled: !isLoading,
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      setState(() => isLoading = true);

                      try {
                        await ref
                            .read(supabaseServiceProvider)
                            .createChannel(serverId, name);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error creating channel: $e')),
                          );
                        }
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteChannel(BuildContext context, WidgetRef ref, Channel channel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Channel'),
        content: Text('Are you sure you want to delete "${channel.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(supabaseServiceProvider).deleteChannel(channel.serverId, channel.id);
      if (ref.read(selectedChannelProvider) == channel.id) {
        ref.read(selectedChannelProvider.notifier).state = null;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting channel: $e')),
        );
      }
    }
  }
}

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChannelTile({
    required this.channel,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.tag,
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
      ),
      title: Text(
        channel.name,
        style: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      onTap: onTap,
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
        onPressed: onDelete,
        tooltip: 'Delete Channel',
      ),
    );
  }
}
