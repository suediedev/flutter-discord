import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ChannelHeader extends StatelessWidget {
  final String channelName;

  const ChannelHeader({super.key, required this.channelName});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.channelBarColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.tag,
            color: AppColors.secondaryTextColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            channelName,
            style: const TextStyle(
              color: AppColors.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.secondaryTextColor),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.people, color: AppColors.secondaryTextColor),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
