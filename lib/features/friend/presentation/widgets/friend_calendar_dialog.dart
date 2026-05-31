import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/friend_calendar_event_entity.dart';
import '../../domain/usecases/get_friend_calendar_use_case.dart';
import '../providers/friend_providers.dart';

/// 친구 캘린더 전체화면 다이얼로그
/// 인라인 캘린더(점 표시) 탭 → 이벤트 제목 표시 달력
class FriendCalendarDialog extends ConsumerStatefulWidget {
  const FriendCalendarDialog({
    super.key,
    required this.friendId,
    required this.nickname,
    required this.avatarColor,
    this.initialMonth,
  });

  final String friendId;
  final String nickname;
  final Color avatarColor;
  final DateTime? initialMonth;

  static Future<void> show(
    BuildContext context, {
    required String friendId,
    required String nickname,
    required Color avatarColor,
    DateTime? initialMonth,
  }) {
    return showDialog(
      context: context,
      builder: (_) => FriendCalendarDialog(
        friendId: friendId,
        nickname: nickname,
        avatarColor: avatarColor,
        initialMonth: initialMonth,
      ),
    );
  }

  @override
  ConsumerState<FriendCalendarDialog> createState() =>
      _FriendCalendarDialogState();
}

class _FriendCalendarDialogState extends ConsumerState<FriendCalendarDialog> {
  late DateTime _current;
  List<FriendCalendarEventEntity> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _current = widget.initialMonth ?? DateTime(now.year, now.month);
    _fetchEvents(_current);
  }

  Future<void> _fetchEvents(DateTime month) async {
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

  // 날짜별 이벤트 맵
  Map<int, List<FriendCalendarEventEntity>> _buildEventMap() {
    final map = <int, List<FriendCalendarEventEntity>>{};
    for (final e in _events) {
      if (e.startAt.year == _current.year &&
          e.startAt.month == _current.month) {
        map.putIfAbsent(e.startAt.day, () => []).add(e);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateUtils.getDaysInMonth(_current.year, _current.month);
    final firstWeekday =
        DateTime(_current.year, _current.month, 1).weekday % 7;
    final eventMap = _buildEventMap();
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final now = DateTime.now();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.avatarColor.withOpacity(0.18),
                  ),
                  child: Center(
                    child: Text(
                      widget.nickname.isNotEmpty
                          ? widget.nickname[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: widget.avatarColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${widget.nickname}의 캘린더',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // 월 네비게이션
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left,
                          size: 22, color: Colors.grey),
                      onPressed: () {
                        final prev =
                            DateTime(_current.year, _current.month - 1);
                        setState(() => _current = prev);
                        _fetchEvents(prev);
                      },
                    ),
                    Text(
                      '${_current.year}년 ${_current.month}월',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right,
                          size: 22, color: Colors.grey),
                      onPressed: () {
                        final next =
                            DateTime(_current.year, _current.month + 1);
                        setState(() => _current = next);
                        _fetchEvents(next);
                      },
                    ),
                  ],
                ),

                // 요일 헤더
                Row(
                  children: weekdays
                      .asMap()
                      .entries
                      .map((e) => Expanded(
                            child: Center(
                              child: Text(
                                e.value,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: e.key == 0
                                      ? Colors.red.shade300
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 6),

                // 달력 그리드
                if (_isLoading)
                  const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: firstWeekday + daysInMonth,
                    itemBuilder: (_, i) {
                      if (i < firstWeekday) return const SizedBox();
                      final day = i - firstWeekday + 1;
                      final isToday = now.year == _current.year &&
                          now.month == _current.month &&
                          now.day == day;
                      final dayEvents = eventMap[day] ?? [];
                      final isSunday = (i % 7) == 0;
                      final hasEvents = dayEvents.isNotEmpty;

                      return GestureDetector(
                        onTap: hasEvents
                            ? () => _showDayDetail(
                                  context,
                                  day: day,
                                  events: dayEvents,
                                )
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: hasEvents
                                ? const Color(0xFFF8F7FF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: hasEvents
                                ? Border.all(
                                    color: const Color(0xFFEDE9FF),
                                    width: 1)
                                : null,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 3),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: isToday
                                    ? const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF7C6AFA),
                                      )
                                    : null,
                                child: Center(
                                  child: Text(
                                    '$day',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isToday
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isToday
                                          ? Colors.white
                                          : isSunday
                                              ? Colors.red.shade300
                                              : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              // 이벤트 제목 표시
                              ...dayEvents.take(2).map((e) {
                                Color color;
                                try {
                                  color = Color(
                                    int.parse(
                                        e.color.replaceFirst('#', '0xFF')),
                                  );
                                } catch (_) {
                                  color = widget.avatarColor;
                                }
                                return Container(
                                  margin: const EdgeInsets.fromLTRB(2, 1, 2, 0),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    e.title,
                                    style: TextStyle(
                                      fontSize: 7,
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                              if (dayEvents.length > 2)
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Text(
                                    '+${dayEvents.length - 2}',
                                    style: TextStyle(
                                      fontSize: 7,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                if (_events.isEmpty && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '이번 달 공개 일정이 없어요',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade400),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDayDetail(
    BuildContext context, {
    required int day,
    required List<FriendCalendarEventEntity> events,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DayDetailSheet(
        year: _current.year,
        month: _current.month,
        day: day,
        events: events,
        nickname: widget.nickname,
        avatarColor: widget.avatarColor,
      ),
    );
  }
}

// ── 날짜별 세부 일정 바텀시트 ─────────────────────────────────────────────────

class _DayDetailSheet extends StatelessWidget {
  const _DayDetailSheet({
    required this.year,
    required this.month,
    required this.day,
    required this.events,
    required this.nickname,
    required this.avatarColor,
  });

  final int year;
  final int month;
  final int day;
  final List<FriendCalendarEventEntity> events;
  final String nickname;
  final Color avatarColor;

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  String _weekdayStr() {
    final w = DateTime(year, month, day).weekday;
    return _weekdays[w - 1];
  }

  String _timeStr(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Text(
                  '$month월 ${day}일 (${_weekdayStr()})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '${nickname}의 일정',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 12),
          ...events.map((e) {
            Color color;
            try {
              color =
                  Color(int.parse(e.color.replaceFirst('#', '0xFF')));
            } catch (_) {
              color = avatarColor;
            }
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_timeStr(e.startAt)} – ${_timeStr(e.endAt)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
