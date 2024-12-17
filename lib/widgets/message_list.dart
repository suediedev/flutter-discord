import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/message_provider.dart';
import '../providers/channel_provider.dart';
import '../theme/platform_theme.dart';
import 'message_item.dart';

class MessageList extends ConsumerWidget {
  const MessageList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChannelId = ref.watch(selectedChannelProvider);
    
    if (selectedChannelId == null) {
      return const Center(
        child: Text(
          'Select a channel to start chatting',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final messagesAsync = ref.watch(messagesProvider(selectedChannelId));

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          reverse: true, // Show newest messages at the bottom
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return MessageItem(
              username: message.username,
              content: message.content,
              timestamp: message.createdAt,
              avatarUrl: message.avatarUrl ?? 'https://www.gravatar.com/avatar/${message.userId}?d=identicon',
            );
          },
        );
      },
      loading: () => Center(
        child: PlatformTheme.adaptiveProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error loading messages: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
