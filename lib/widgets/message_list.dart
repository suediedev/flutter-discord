import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'message_item.dart';

class MessageList extends StatelessWidget {
  final List<Map<String, dynamic>> messages = [
    {
      'username': 'Concept Central',
      'content': 'What do you all think of the Nothing Phone()?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      'avatarUrl': 'https://i.pravatar.cc/150?img=1',
    },
    {
      'username': 'nance',
      'content': 'I think it\'s over hyped.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 4)),
      'avatarUrl': 'https://i.pravatar.cc/150?img=2',
    },
    // Add more sample messages as needed
  ];

  MessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageItem(
          username: message['username'],
          content: message['content'],
          timestamp: message['timestamp'],
          avatarUrl: message['avatarUrl'],
        );
      },
    );
  }
}
