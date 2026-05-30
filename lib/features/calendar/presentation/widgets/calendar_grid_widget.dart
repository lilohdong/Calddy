import 'package:flutter/material.dart';
import '../../../calendar/domain/entities/calendar_data.dart';
import '../../../calendar/domain/entities/event_entity.dart';
import 'calendar_day_cell.dart';
import 'range_bar_widget.dart';

class CalendarGridWidget extends StatelessWidget {
  const CalendarGridWidget({
    super.key,
    required this.year,
    required this.month,
    required this.data,
    required this.selectedDay,
    required this.onDaySelected,
    this.drawingThumbnails = const {},
  });

  final int year;
  final int month;
  final CalendarData data;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final Map<String, String?> drawingThumbnails;

  String? _thumbnailForDay(DateTime day) {
    final key =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return drawingThumbnails[key];
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> _buildMonthDates() {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startOffset = firstDay.weekday % 7; // 0=Sun … 6=Sat
    final dates = <DateTime>[];
    for (int i = startOffset; i > 0; i--) {
      dates.add(firstDay.subtract(Duration(days: i)));
    }
    for (int i = 0; i < lastDay.day; i++) {
      dates.add(DateTime(year, month, i + 1));
    }
    while (dates.length < 42) {
      dates.add(dates.last.add(const Duration(days: 1)));
    }
    return dates;
  }

  List<EventEntity> _eventsForDay(DateTime day) {
    return [
      ...data.events.where((e) =>
          _isSameDay(e.startAt, day) &&
          _isSameDay(e.startAt, e.endAt)), // single-day only
      ...data.habits.where((e) => _isSameDay(e.startAt, day)),
    ];
  }

  List<EventEntity> get _multiDayEvents => data.events
      .where((e) => !_isSameDay(e.startAt, e.endAt))
      .toList();

  bool _isHoliday(DateTime day) =>
      data.holidays.any((h) => _isSameDay(h.date, day));

  String? _holidayName(DateTime day) =>
      data.holidays
          .where((h) => _isSameDay(h.date, day))
          .map((h) => h.name)
          .firstOrNull;

  List<Widget> _buildRangeBarsForWeek(
    List<DateTime> weekDays,
    List<EventEntity> ranges,
    double cellWidth,
    double cellHeight,
  ) {
    final bars = <Widget>[];

    // Collect which ranges overlap this week
    final overlapping = <EventEntity>[];
    for (final range in ranges) {
      final rangeStart = DateTime(
          range.startAt.year, range.startAt.month, range.startAt.day);
      final rangeEnd =
          DateTime(range.endAt.year, range.endAt.month, range.endAt.day);
      final weekStart = weekDays.first;
      final weekEnd = weekDays.last;
      if (!rangeEnd.isBefore(weekStart) && !rangeStart.isAfter(weekEnd)) {
        overlapping.add(range);
      }
    }

    // Place from bottom up (idx=0 at bottom, higher idx stacks upward)
    for (int idx = 0; idx < overlapping.length; idx++) {
      final range = overlapping[idx];
      final rangeStart = DateTime(
          range.startAt.year, range.startAt.month, range.startAt.day);
      final rangeEnd =
          DateTime(range.endAt.year, range.endAt.month, range.endAt.day);
      final weekStart = weekDays.first;
      final weekEnd = weekDays.last;

      final displayStart =
          rangeStart.isBefore(weekStart) ? weekStart : rangeStart;
      final displayEnd = rangeEnd.isAfter(weekEnd) ? weekEnd : rangeEnd;

      final startCol = weekDays.indexWhere((d) => _isSameDay(d, displayStart));
      final endCol = weekDays.indexWhere((d) => _isSameDay(d, displayEnd));
      if (startCol == -1 || endCol == -1) continue;

      final left = startCol * cellWidth;
      final width = (endCol - startCol + 1) * cellWidth;
      final isStart = _isSameDay(displayStart, rangeStart);
      final isEnd = _isSameDay(displayEnd, rangeEnd);

      // Bottom position: first range at bottom, subsequent ones stack upward
      final bottom = 2.0 + idx * 20.0;

      bars.add(
        Positioned(
          bottom: bottom,
          left: left,
          width: width,
          height: 18,
          child: RangeBarWidget(
            event: range,
            isStart: isStart,
            isEnd: isEnd,
          ),
        ),
      );
    }
    return bars;
  }

  @override
  Widget build(BuildContext context) {
    final dates = _buildMonthDates();
    final weeks = List.generate(6, (i) => dates.sublist(i * 7, i * 7 + 7));

    return Column(
      children: [
        // 요일 헤더
        Row(
          children: ['일', '월', '화', '수', '목', '금', '토'].asMap().entries.map((e) {
            Color c;
            if (e.key == 0) {
              c = const Color(0xFFE53935);
            } else if (e.key == 6) {
              c = const Color(0xFF1565C0);
            } else {
              c = Colors.black54;
            }
            return Expanded(
              child: Center(
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        // 그리드
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / 7;
              final cellHeight = constraints.maxHeight / 6;

              return Column(
                children: weeks.map((weekDays) {
                  return SizedBox(
                    height: cellHeight,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Row(
                          children: weekDays.map((day) {
                            final isCurrent = day.month == month;
                            final isToday = _isSameDay(day, DateTime.now());
                            final isSelected = _isSameDay(day, selectedDay);
                            return SizedBox(
                              width: cellWidth,
                              height: cellHeight,
                              child: CalendarDayCell(
                                date: day,
                                isCurrentMonth: isCurrent,
                                isSelected: isSelected,
                                isToday: isToday,
                                events: isCurrent ? _eventsForDay(day) : [],
                                isHoliday: _isHoliday(day),
                                holidayName: _holidayName(day),
                                onTap: () => onDaySelected(day),
                                drawingThumbnailUrl: isCurrent ? _thumbnailForDay(day) : null,
                              ),
                            );
                          }).toList(),
                        ),
                        ..._buildRangeBarsForWeek(
                          weekDays,
                          [...data.ranges, ..._multiDayEvents],
                          cellWidth,
                          cellHeight,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
