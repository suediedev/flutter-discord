import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../models/member.dart';
import '../services/supabase_service.dart';

final membersProvider = StreamProvider.family<List<Member>, String>((ref, serverId) {
  return SupabaseService().getServerMembers(serverId);
});

class MemberList extends ConsumerWidget {
  final String serverId;

  const MemberList({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider(serverId));

    return Container(
      width: 240,
      color: AppColors.channelBarColor,
      child: Column(
        children: [
          Container(
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
            child: const Row(
              children: [
                Text(
                  'Members',
                  style: TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: membersAsync.when(
              data: (members) => _buildMemberList(members),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Error loading members')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(List<Member> members) {
    final onlineMembers = members.where((m) => m.isOnline).toList();
    final offlineMembers = members.where((m) => !m.isOnline).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (onlineMembers.isNotEmpty) ...[
          _buildRole('ONLINE—${onlineMembers.length}'),
          ...onlineMembers.map((member) => _buildMember(
                member.username,
                member.avatarUrl ?? 'https://via.placeholder.com/150',
                member.status == MemberStatus.online,
              )),
        ],
        if (offlineMembers.isNotEmpty) ...[
          _buildRole('OFFLINE—${offlineMembers.length}'),
          ...offlineMembers.map((member) => _buildMember(
                member.username,
                member.avatarUrl ?? 'https://via.placeholder.com/150',
                false,
                isOffline: true,
              )),
        ],
      ],
    );
  }

  Widget _buildRole(String name) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 4),
      child: Text(
        name,
        style: const TextStyle(
          color: AppColors.secondaryTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMember(String name, String avatarUrl, bool isActive, {bool isOffline = false}) {
    return ListTile(
      dense: true,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[700],
            backgroundImage: NetworkImage(
              avatarUrl.startsWith('http') 
                  ? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random'
                  : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random',
            ),
            onBackgroundImageError: (exception, stackTrace) {
              debugPrint('Error loading avatar for $name: $exception');
            },
            child: avatarUrl.isEmpty 
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          if (!isOffline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.channelBarColor,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        name,
        style: TextStyle(
          color: isOffline ? AppColors.secondaryTextColor.withOpacity(0.5) : AppColors.secondaryTextColor,
          fontSize: 16,
        ),
      ),
    );
  }
}
