import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/friend_calendar_event_entity.dart';
import '../../domain/entities/friend_entity.dart';
import '../../domain/usecases/get_friend_calendar_use_case.dart';
import '../providers/friend_providers.dart';
import 'friend_avatar_chip.dart';
import 'friend_calendar_dialog.dart';
import 'friend_mini_calendar.dart';

class FriendCard extends ConsumerWidget {
  const FriendCard({
    super.key,
    required this.friend,
    required this.isExpanded,
    required this.onToggle,
    required this.onDelete,
    this.rank, // 0-based index (0 = 1위, 1 = 2위, 2 = 3위, null or 3+ = 멘트 없음)
  });

  final FriendEntity friend;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final int? rank;

  /// 순위별 고정 멘트 (null이면 빈 문자열)
  static String subtitleForRank(int? rank) {
    switch (rank) {
      case 0: return '나와 가장 많이 겹쳐요';
      case 1: return '나와 많이 겹쳐요';
      case 2: return '종종 시간이 겹쳐요';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = friend.friendProfile;
    final nickname = profile.nickname ?? '?';
    final color = FriendAvatarChip.avatarColor(friend.friendId);

    return AnimatedContainer(
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
          // 헤더 영역만 탭으로 expand/collapse
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
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
                        // 순위 기반 고정 멘트 (캘린더 펼침 여부와 무관)
                        if (subtitleForRank(rank).isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitleForRank(rank),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 항상 ... 메뉴만 표시
                  _MoreMenu(
                    nickname: nickname,
                    onDelete: onDelete,
                  ),
                ],
              ),
            ),
          ),
          // 펼쳐진 캘린더 - 탭하면 다이얼로그
          if (isExpanded)
            _ExpandedCalendar(
              friendId: friend.friendId,
              nickname: nickname,
              avatarColor: color,
            ),
        ],
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.nickname, required this.onDelete});
  final String nickname;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.more_horiz, color: Colors.grey, size: 22),
      onPressed: () => _showDeleteSheet(context),
    );
  }

  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '$nickname 님을 친구 목록에서\n삭제하시겠어요?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4D6A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '삭제',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ExpandedCalendar extends ConsumerStatefulWidget {
  const _ExpandedCalendar({
    required this.friendId,
    required this.nickname,
    required this.avatarColor,
  });
  final String friendId;
  final String nickname;
  final Color avatarColor;

  @override
  ConsumerState<_ExpandedCalendar> createState() => _ExpandedCalendarState();
}

class _ExpandedCalendarState extends ConsumerState<_ExpandedCalendar> {
  List<FriendCalendarEventEntity> _events = [];
  bool _isLoading = true;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _fetchEvents(_currentMonth);
  }

  Future<void> _fetchEvents(DateTime month) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final from = DateTime(month.year, month.month, 1);
      final to = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      final events = await ref.read(getFriendCalendarUseCaseProvider).call(
            GetFriendCalendarParams(
              friendId: widget.friendId,
              from: from,
              to: to,
            ),
          );
      if (mounted) setState(() => _events = events);
    } catch (_) {
      if (mounted) setState(() => _events = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 캘린더 내부 탭 → 다이얼로그
      onTap: () => FriendCalendarDialog.show(
        context,
        friendId: widget.friendId,
        nickname: widget.nickname,
        avatarColor: widget.avatarColor,
        initialMonth: _currentMonth,
      ),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        // 항상 FriendMiniCalendar를 유지해야 _current(월) state가 보존됨
        // 로딩 중에는 isLoading 플래그로 오버레이만 표시
        child: FriendMiniCalendar(
          events: _events,
          isLoading: _isLoading,
          onMonthChanged: (month) {
            _currentMonth = month;
            _fetchEvents(month);
          },
        ),
      ),
    );
  }
}
