import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/friend_entity.dart';
import '../providers/friend_providers.dart';

class FriendAvatarChip extends ConsumerWidget {
  const FriendAvatarChip({
    super.key,
    required this.friend,
    this.onTap,
    this.isSelected = false,
    this.showOverlapBadge = true,
  });

  final FriendEntity friend;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showOverlapBadge;

  static const _palette = [
    Color(0xFF9B8FF5),
    Color(0xFF6EC6B8),
    Color(0xFF5BB5E8),
    Color(0xFFF5A623),
    Color(0xFFF07DB3),
  ];

  static Color avatarColor(String id) =>
      _palette[id.hashCode.abs() % _palette.length];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = friend.friendProfile.nickname ?? '?';
    final color = avatarColor(friend.friendId);

    int? overlapDays;
    if (showOverlapBadge) {
      final slotsAsync = ref.watch(mergeCalendarProvider(friend.friendId));
      overlapDays = slotsAsync.maybeWhen(
        data: (slots) {
          final days = <String>{};
          for (final s in slots) {
            var d = DateTime(s.startAt.year, s.startAt.month, s.startAt.day);
            final end = DateTime(s.endAt.year, s.endAt.month, s.endAt.day);
            while (!d.isAfter(end)) {
              days.add('${d.year}-${d.month}-${d.day}');
              d = d.add(const Duration(days: 1));
            }
          }
          return days.length;
        },
        orElse: () => null,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(isSelected ? 0.28 : 0.15),
                    border: isSelected
                        ? Border.all(color: const Color(0xFF7C6AFA), width: 2.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ),
                if (overlapDays != null && overlapDays > 0)
                  Positioned(
                    bottom: -4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C6AFA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${overlapDays}일',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              nickname.length > 5 ? '${nickname.substring(0, 5)}…' : nickname,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
