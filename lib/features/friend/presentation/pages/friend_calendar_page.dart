import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/friend_entity.dart';
import '../providers/friend_providers.dart';
import '../widgets/friend_avatar_chip.dart';
import '../widgets/friend_mini_calendar.dart';

class FriendCalendarPage extends ConsumerWidget {
  const FriendCalendarPage({super.key, required this.friendId});

  final String friendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(friendCalendarProvider(friendId));
    final friendsAsync =
        ref.watch(friendsProvider(FriendSortType.freeTimeOverlap));

    final friendEntity = friendsAsync.maybeWhen(
      data: (friends) => friends.cast<FriendEntity?>().firstWhere(
            (f) => f?.friendId == friendId,
            orElse: () => null,
          ),
      orElse: () => null,
    );

    final nickname = friendEntity?.friendProfile.nickname ?? '';
    final avatarColor = FriendAvatarChip.avatarColor(friendId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          nickname.isNotEmpty ? '$nickname의 캘린더' : '친구 캘린더',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e is FriendFailure ? e.message : '불러오기 실패'),
        ),
        data: (events) => SingleChildScrollView(
          child: Column(
            children: [
              // 프로필 헤더
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: avatarColor.withOpacity(0.18),
                      ),
                      child: Center(
                        child: Text(
                          nickname.isNotEmpty
                              ? nickname[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: avatarColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nickname,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '공개 일정 ${events.length}개',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 캘린더 카드
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
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
                child: FriendMiniCalendar(events: events),
              ),

              // 이벤트 목록 카드
              if (events.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  padding: const EdgeInsets.all(16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '이번 달 일정',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...events.map((e) {
                        Color eColor;
                        try {
                          eColor = Color(
                            int.parse(e.color.replaceFirst('#', '0xFF')),
                          );
                        } catch (_) {
                          eColor = avatarColor;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: eColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  e.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${e.startAt.month}/${e.startAt.day}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      '이번 달 공개 일정이 없어요',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
