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
      // 내 이번 달 일정 + 친구 이번 달 일정을 비교해서
      // 둘 다 이벤트 없는 날(진짜 빈날) 수를 배지로 표시
      final myEventsAsync =
          ref.watch(friendCalendarProvider(friend.userId));
      final friendEventsAsync =
          ref.watch(friendCalendarProvider(friend.friendId));

      overlapDays = myEventsAsync.maybeWhen(
        data: (myEvents) => friendEventsAsync.maybeWhen(
          data: (friendEvents) {
            final now = DateTime.now();
            final daysInMonth =
                DateUtils.getDaysInMonth(now.year, now.month);

            // 바쁜 날 수집
            final busyDays = <int>{};
            for (final e in myEvents) {
              if (e.startAt.year == now.year &&
                  e.startAt.month == now.month) {
                busyDays.add(e.startAt.day);
              }
            }
            for (final e in friendEvents) {
              if (e.startAt.year == now.year &&
                  e.startAt.month == now.month) {
                busyDays.add(e.startAt.day);
              }
            }

            // 빈날 = 전체 - 바쁜 날
            return daysInMonth - busyDays.length;
          },
          orElse: () => null,
        ),
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
