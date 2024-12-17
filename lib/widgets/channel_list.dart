import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/channel.dart';
import '../providers/server_provider.dart';
import '../providers/channel_provider.dart';
import '../services/supabase_service.dart';

class ChannelList extends ConsumerWidget {
  const ChannelList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedServerId = ref.watch(selectedServerProvider);
    
    if (selectedServerId == null) {
      return const Center(
        child: Text('Select a server to view channels'),
      );
    }

    final channelsAsync = ref.watch(channelsProvider(selectedServerId));
    final selectedChannelId = ref.watch(selectedChannelProvider);

    return Container(
      width: 240,
      color: Colors.grey[850],
      child: Column(
        children: [
          _buildHeader(context, ref),
          Expanded(
            child: channelsAsync.when(
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
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    final isSelected = channel.id == selectedChannelId;

                    return _ChannelTile(
                      channel: channel,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(selectedChannelProvider.notifier).state = channel.id;
                      },
                      onDelete: () => _deleteChannel(context, ref, channel),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
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
                      onPressed: () => ref.refresh(channelsProvider(selectedServerId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.grey[900],
      child: Row(
        children: [
          const Text(
            'Channels',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showCreateChannelDialog(context, ref),
            tooltip: 'Create Channel',
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateChannelDialog(BuildContext context, WidgetRef ref) async {
    final serverId = ref.read(selectedServerProvider);
    if (serverId == null) return;

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
                  hintText: 'Enter channel name',
                ),
                enabled: !isLoading,
              ),
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
                      setState(() => isLoading = true);
                      try {
                        final channel = await ref
                            .read(supabaseServiceProvider)
                            .createChannel(serverId, nameController.text);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ref.read(selectedChannelProvider.notifier).state = channel.id;
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error creating channel: $e')),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteChannel(BuildContext context, WidgetRef ref, Channel channel) async {
    final serverId = ref.read(selectedServerProvider);
    if (serverId == null) return;

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
      await ref.read(supabaseServiceProvider).deleteChannel(serverId, channel.id);
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
  const _ChannelTile({
    required this.channel,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  final Channel channel;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.tag,
        color: Colors.white70,
        size: 20,
      ),
      title: Text(
        channel.name,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blueAccent.withOpacity(0.2),
      onTap: onTap,
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
        onPressed: onDelete,
        tooltip: 'Delete Channel',
      ),
    );
  }
}
