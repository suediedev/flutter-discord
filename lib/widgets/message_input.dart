import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MessageInput extends StatelessWidget {
  const MessageInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.backgroundColor,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.secondaryTextColor),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.messageInputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                style: TextStyle(color: AppColors.textColor),
                decoration: InputDecoration(
                  hintText: 'Message #general',
                  hintStyle: TextStyle(color: AppColors.secondaryTextColor),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.secondaryTextColor),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
