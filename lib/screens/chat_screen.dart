import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/server_provider.dart';
import '../services/supabase_service.dart';
import '../widgets/server_sidebar.dart';
import '../widgets/channel_list.dart';
import '../widgets/member_list.dart';
import '../models/channel.dart';
import '../models/message.dart';

final selectedChannelProvider = StateProvider<Channel?>((ref) => null);
final messagesProvider = StreamProvider.family<List<Message>, String>((ref, channelId) {
  return ref.read(supabaseServiceProvider).getMessagesStream(channelId);
});

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(Channel channel) async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await ref.read(supabaseServiceProvider).sendMessage(channel.id, content);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedServerId = ref.watch(selectedServerProvider);
    final selectedChannel = ref.watch(selectedChannelProvider);

    return Scaffold(
      body: Row(
        children: [
          const ServerSidebar(),
          if (selectedServerId != null) ...[
            const ChannelList(),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: selectedChannel != null
                    ? Column(
                        children: [
                          _buildHeader(selectedChannel),
                          Expanded(
                            child: _buildMessageList(selectedChannel),
                          ),
                          _buildMessageInput(selectedChannel),
                        ],
                      )
                    : const Center(
                        child: Text(
                          'Select a channel to start chatting!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
            ),
            MemberList(serverId: selectedServerId),
          ] else
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: const Center(
                  child: Text(
                    'Select or create a server to start chatting!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(Channel channel) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            channel.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(Channel channel) {
    return ref.watch(messagesProvider(channel.id)).when(
          data: (messages) {
            if (messages.isEmpty) {
              return const Center(child: Text('No messages yet'));
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isFirstMessage = index == 0 ||
                    messages[index - 1].userId != message.userId ||
                    messages[index - 1].createdAt.difference(message.createdAt).inMinutes.abs() > 5;

                return _MessageItem(
                  message: message,
                  showHeader: isFirstMessage,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
  }

  Widget _buildMessageInput(Channel channel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Send a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(channel),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendMessage(channel),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  final Message message;
  final bool showHeader;

  const _MessageItem({
    required this.message,
    required this.showHeader,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                Text(
                  message.userDisplayName ?? 'Unknown User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(message.createdAt),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Text(message.content),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
