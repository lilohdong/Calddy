import 'package:flutter/material.dart';
import '../../../calendar/domain/entities/event_entity.dart';
import 'event_block_widget.dart';

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.events,
    required this.onTap,
    this.isHoliday = false,
    this.holidayName,
    this.drawingThumbnailUrl,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final List<EventEntity> events;
  final VoidCallback onTap;
  final bool isHoliday;
  final String? holidayName;
  final String? drawingThumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final isSunday = date.weekday == DateTime.sunday;
    final isSaturday = date.weekday == DateTime.saturday;

    Color dateColor;
    if (!isCurrentMonth) {
      dateColor = Colors.grey.shade400;
    } else if (isHoliday || isSunday) {
      dateColor = const Color(0xFFE53935);
    } else if (isSaturday) {
      dateColor = const Color(0xFF1565C0);
    } else {
      dateColor = Colors.black87;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
          color: isSelected
              ? const Color(0xFF7C6AFA).withValues(alpha: 0.08)
              : Colors.white,
          image: drawingThumbnailUrl != null
              ? DecorationImage(
                  image: NetworkImage(drawingThumbnailUrl!),
                  fit: BoxFit.cover,
                  opacity: 0.85,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 숫자
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 3, right: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: isToday
                        ? const BoxDecoration(
                            color: Color(0xFF7C6AFA),
                            shape: BoxShape.circle,
                          )
                        : null,
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? Colors.white : dateColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 이벤트 블록 (최대 2개, 하단 구간 바 공간 확보)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ...events.take(2).map((e) => EventBlockWidget(event: e)),
                  const Spacer(), // pushes events to top, leaves bottom for range bars
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
