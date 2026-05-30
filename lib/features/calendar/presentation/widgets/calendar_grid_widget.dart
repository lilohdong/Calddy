import 'package:flutter/material.dart';
import '../../../calendar/domain/entities/calendar_data.dart';
import '../../../calendar/domain/entities/event_entity.dart';
import '../../../calendar/domain/entities/holiday_entity.dart';
import '../../../../core/utils/extensions.dart';
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

  String? _thumbnailForDay(DateTime day) =>
      drawingThumbnails[day.toDateString()]; // extensions.dart

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

  List<Widget> _buildRangeBarsForWeek(
    List<DateTime> weekDays,
    List<EventEntity> ranges,
    double cellWidth,
    double cellHeight,
  ) {
    final bars = <Widget>[];

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

      final startCol =
          weekDays.indexWhere((d) => d.isSameDay(displayStart));
      final endCol =
          weekDays.indexWhere((d) => d.isSameDay(displayEnd));
      if (startCol == -1 || endCol == -1) continue;

      final left = startCol * cellWidth;
      final width = (endCol - startCol + 1) * cellWidth;
      final isStart = displayStart.isSameDay(rangeStart);
      final isEnd = displayEnd.isSameDay(rangeEnd);

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

    // 빌드 시 1회 전처리 — 이후 셀당 O(1) 조회 (이전: O(n) × 42)
    final eventsByDate = <String, List<EventEntity>>{};
    for (final e in data.events) {
      if (e.startAt.isSameDay(e.endAt)) {
        (eventsByDate[e.startAt.toDateString()] ??= []).add(e);
      }
    }
    for (final h in data.habits) {
      (eventsByDate[h.startAt.toDateString()] ??= []).add(h);
    }

    final holidayByDate = <String, HolidayEntity>{};
    for (final h in data.holidays) {
      holidayByDate[h.date.toDateString()] = h;
    }

    // getter 대신 로컬 변수 — build() 내 6회 반복 중복 할당 방지
    final multiDayEvents = data.events
        .where((e) => !e.startAt.isSameDay(e.endAt))
        .toList();

    final today = DateTime.now();

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
                            final isToday = day.isSameDay(today);
                            final isSelected = day.isSameDay(selectedDay);
                            final key = day.toDateString();
                            final holiday = holidayByDate[key];
                            return SizedBox(
                              width: cellWidth,
                              height: cellHeight,
                              child: CalendarDayCell(
                                date: day,
                                isCurrentMonth: isCurrent,
                                isSelected: isSelected,
                                isToday: isToday,
                                events: isCurrent
                                    ? (eventsByDate[key] ?? const [])
                                    : const [],
                                isHoliday: holiday != null,
                                holidayName: holiday?.name,
                                onTap: () => onDaySelected(day),
                                drawingThumbnailUrl:
                                    isCurrent ? _thumbnailForDay(day) : null,
                              ),
                            );
                          }).toList(),
                        ),
                        ..._buildRangeBarsForWeek(
                          weekDays,
                          [...data.ranges, ...multiDayEvents],
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
