import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member.dart';
import '../providers/server_provider.dart';
import '../theme/app_colors.dart';
import 'status_indicator.dart';

class MemberList extends ConsumerWidget {
  final String serverId;
  final bool isBottomSheet;

  const MemberList({
    super.key,
    required this.serverId,
    this.isBottomSheet = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider(serverId));

    if (isBottomSheet) {
      return _buildMemberListContent(context, membersAsync);
    }

    return Container(
      width: 240,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      child: _buildMemberListContent(context, membersAsync),
    );
  }

  Widget _buildMemberListContent(BuildContext context, AsyncValue<List<Member>> membersAsync) {
    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Members',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              membersAsync.when(
                data: (members) => Text(
                  members.length.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        Expanded(
          child: membersAsync.when(
            data: (members) {
              final onlineMembers = members
                  .where((m) => m.isOnline)
                  .toList()
                  ..sort((a, b) => (a.username ?? '').compareTo(b.username ?? ''));

              final offlineMembers = members
                  .where((m) => !m.isOnline)
                  .toList()
                  ..sort((a, b) => (a.username ?? '').compareTo(b.username ?? ''));

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (onlineMembers.isNotEmpty) ...[
                    _buildMemberSection(
                      context,
                      'ONLINE',
                      onlineMembers.length.toString(),
                    ),
                    ...onlineMembers.map((m) => _MemberTile(member: m)),
                  ],
                  if (offlineMembers.isNotEmpty) ...[
                    _buildMemberSection(
                      context,
                      'OFFLINE',
                      offlineMembers.length.toString(),
                    ),
                    ...offlineMembers.map((m) => _MemberTile(member: m)),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberSection(BuildContext context, String title, String count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Member member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[800],
            backgroundImage: member.avatarUrl != null
                ? NetworkImage(member.avatarUrl!)
                : null,
            child: member.avatarUrl == null
                ? Text(
                    member.username?[0].toUpperCase() ?? '?',
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: StatusIndicator(status: member.status),
          ),
        ],
      ),
      title: Text(
        member.username ?? 'Unknown User',
        style: TextStyle(
          color: member.isOnline
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
      subtitle: !member.isOnline
          ? Text(
              _formatLastSeen(member.lastSeen),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            )
          : null,
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
