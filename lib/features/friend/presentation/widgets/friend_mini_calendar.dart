import 'package:flutter/material.dart';
import '../../domain/entities/friend_calendar_event_entity.dart';

class FriendMiniCalendar extends StatefulWidget {
  const FriendMiniCalendar({
    super.key,
    required this.events,
    this.onMonthChanged,
  });

  final List<FriendCalendarEventEntity> events;
  final void Function(DateTime month)? onMonthChanged;

  @override
  State<FriendMiniCalendar> createState() => _FriendMiniCalendarState();
}

class _FriendMiniCalendarState extends State<FriendMiniCalendar> {
  late DateTime _current;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _current = DateTime(now.year, now.month);
  }

  Map<int, List<Color>> _buildEventMap() {
    final map = <int, List<Color>>{};
    for (final e in widget.events) {
      if (e.startAt.year != _current.year || e.startAt.month != _current.month) {
        continue;
      }
      final color = _parseColor(e.color);
      for (var d = e.startAt.day; d <= e.endAt.day; d++) {
        map.putIfAbsent(d, () => []).add(color);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_current.year, _current.month);
    final firstWeekday = DateTime(_current.year, _current.month, 1).weekday % 7;
    final eventMap = _buildEventMap();
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final now = DateTime.now();

    return Column(
      children: [
        // Month nav
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                final next = DateTime(_current.year, _current.month - 1);
                setState(() => _current = next);
                widget.onMonthChanged?.call(next);
              },
              child: const Icon(Icons.chevron_left, size: 20, color: Colors.grey),
            ),
            Text(
              '${_current.year}년 ${_current.month}월 ▾',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            GestureDetector(
              onTap: () {
                final next = DateTime(_current.year, _current.month + 1);
                setState(() => _current = next);
                widget.onMonthChanged?.call(next);
              },
              child: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Weekday headers
        Row(
          children: weekdays.asMap().entries.map((e) => Expanded(
            child: Center(
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: e.key == 0 ? Colors.red.shade300 : Colors.grey.shade500,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.1,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (_, i) {
            if (i < firstWeekday) return const SizedBox();
            final day = i - firstWeekday + 1;
            final isToday = now.year == _current.year &&
                now.month == _current.month &&
                now.day == day;
            final dots = eventMap[day] ?? [];
            final isSunday = (i % 7) == 0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
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
                        fontSize: 12,
                        color: isToday
                            ? Colors.white
                            : isSunday
                                ? Colors.red.shade300
                                : Colors.black87,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                if (dots.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: dots.take(3).map((c) => Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(right: 1),
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                      )).toList(),
                    ),
                  )
                else
                  const SizedBox(height: 6),
              ],
            );
          },
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF7C6AFA);
    }
  }
}
