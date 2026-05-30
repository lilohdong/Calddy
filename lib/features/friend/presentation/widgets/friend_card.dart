import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/friend_entity.dart';
import '../providers/friend_providers.dart';
import 'friend_avatar_chip.dart';
import 'friend_mini_calendar.dart';

class FriendCard extends ConsumerWidget {
  const FriendCard({
    super.key,
    required this.friend,
    required this.isExpanded,
    required this.onToggle,
    required this.onDelete,
    required this.onMerge,
  });

  final FriendEntity friend;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onMerge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = friend.friendProfile;
    final nickname = profile.nickname ?? '?';
    final color = FriendAvatarChip.avatarColor(friend.friendId);

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.18),
                    ),
                    child: Center(
                      child: Text(
                        nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nickname,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isExpanded ? '나와 가장 많이 겹쳐요!' : '나와 많이 겹쳐요',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  if (isExpanded)
                    _DeleteChip(onDelete: onDelete)
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MergeChip(onMerge: onMerge),
                        const SizedBox(width: 4),
                        _MoreMenu(onDelete: onDelete),
                      ],
                    ),
                ],
              ),
            ),
            // Expanded calendar
            if (isExpanded)
              _ExpandedCalendar(friendId: friend.friendId),
          ],
        ),
      ),
    );
  }
}

class _DeleteChip extends StatelessWidget {
  const _DeleteChip({required this.onDelete});
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE4EF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '삭제',
          style: TextStyle(
            color: Color(0xFFE91E8C),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MergeChip extends StatelessWidget {
  const _MergeChip({required this.onMerge});
  final VoidCallback onMerge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onMerge,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '나와 합쳐 보기',
          style: TextStyle(
            color: Color(0xFF7C6AFA),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onDelete});
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: Colors.grey, size: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) {
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'delete',
          child: Text('친구 삭제', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

class _ExpandedCalendar extends ConsumerWidget {
  const _ExpandedCalendar({required this.friendId});
  final String friendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(friendCalendarProvider(friendId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: eventsAsync.when(
        loading: () => const SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => const SizedBox(
          height: 60,
          child: Center(
            child: Text('일정을 불러오지 못했어요', style: TextStyle(color: Colors.grey)),
          ),
        ),
        data: (events) => FriendMiniCalendar(events: events),
      ),
    );
  }
}
