import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../providers/message_provider.dart';
import '../providers/server_provider.dart';
import '../providers/channel_provider.dart';
import '../services/supabase_service.dart';
import '../theme/platform_theme.dart';
import 'message_bubble.dart';
import 'message_input.dart';
import 'member_list.dart';

class ChatView extends ConsumerWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedServer = ref.watch(selectedServerProvider);
    final selectedChannelId = ref.watch(selectedChannelProvider);

    if (selectedServer == null || selectedChannelId == null) {
      return Center(
        child: Text(
          'Select a channel to start chatting',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                AppBar(
                  title: Text(selectedServer.name),
                  actions: [
                    if (MediaQuery.of(context).size.width <= 600)
                      IconButton(
                        icon: const Icon(Icons.people),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => MemberList(
                              serverId: selectedServer.id,
                            ),
                          );
                        },
                      ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: MessageList(
                          channelId: selectedChannelId,
                          serverId: selectedServer.id,
                        ),
                      ),
                      MessageInput(
                        channelId: selectedChannelId,
                        serverId: selectedServer.id,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (MediaQuery.of(context).size.width > 600)
            SizedBox(
              width: 240,
              child: MemberList(
                serverId: selectedServer.id,
              ),
            ),
        ],
      ),
    );
  }
}

class MessageList extends ConsumerStatefulWidget {
  final String channelId;
  final String serverId;

  const MessageList({
    Key? key,
    required this.channelId,
    required this.serverId,
  }) : super(key: key);

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    await ref.read(supabaseServiceProvider).loadMessages(widget.channelId);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.channelId));
    
    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(
            child: Text('No messages yet'),
          );
        }

        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return MessageBubble(
              message: message,
              onDelete: () async {
                try {
                  await ref.read(supabaseServiceProvider).deleteMessage(
                    widget.channelId,
                    message.id,
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete message: $e')),
                  );
                }
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}

class MessageInput extends ConsumerStatefulWidget {
  final String channelId;
  final String serverId;

  const MessageInput({
    Key? key,
    required this.channelId,
    required this.serverId,
  }) : super(key: key);

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  late final TextEditingController _messageController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await ref.read(supabaseServiceProvider).sendMessage(
        widget.channelId,
        content,
      );
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
