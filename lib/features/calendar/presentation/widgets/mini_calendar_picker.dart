import 'package:flutter/material.dart';

class MiniCalendarPicker extends StatefulWidget {
  const MiniCalendarPicker({
    super.key,
    required this.selectedStart,
    required this.selectedEnd,
    required this.onRangeSelected,
  });

  final DateTime? selectedStart;
  final DateTime? selectedEnd;
  final void Function(DateTime start, DateTime end) onRangeSelected;

  @override
  State<MiniCalendarPicker> createState() => _MiniCalendarPickerState();
}

class _MiniCalendarPickerState extends State<MiniCalendarPicker> {
  late DateTime _viewMonth;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _start = widget.selectedStart;
    _end = widget.selectedEnd;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _onDayTap(DateTime day) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = day;
        _end = null;
      } else {
        if (day.isBefore(_start!)) {
          _end = _start;
          _start = day;
        } else {
          _end = day;
        }
        if (_start != null && _end != null) {
          widget.onRangeSelected(_start!, _end!);
        }
      }
    });
  }

  bool _isInRange(DateTime day) {
    if (_start == null || _end == null) return false;
    return day.isAfter(_start!) && day.isBefore(_end!);
  }

  List<DateTime> _buildDates() {
    final first = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final last = DateTime(_viewMonth.year, _viewMonth.month + 1, 0);
    final startOffset = first.weekday % 7;
    final dates = <DateTime>[];
    for (int i = startOffset; i > 0; i--) {
      dates.add(first.subtract(Duration(days: i)));
    }
    for (int i = 0; i < last.day; i++) {
      dates.add(DateTime(_viewMonth.year, _viewMonth.month, i + 1));
    }
    while (dates.length % 7 != 0) {
      dates.add(dates.last.add(const Duration(days: 1)));
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    final dates = _buildDates();
    final weeks = List.generate(
        dates.length ~/ 7, (i) => dates.sublist(i * 7, i * 7 + 7));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() {
                _viewMonth =
                    DateTime(_viewMonth.year, _viewMonth.month - 1);
              }),
            ),
            Text(
              '${_viewMonth.year}년 ${_viewMonth.month}월',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() {
                _viewMonth =
                    DateTime(_viewMonth.year, _viewMonth.month + 1);
              }),
            ),
          ],
        ),
        Row(
          children: ['일', '월', '화', '수', '목', '금', '토']
              .asMap()
              .entries
              .map((e) => Expanded(
                    child: Center(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 11,
                          color: e.key == 0
                              ? const Color(0xFFE53935)
                              : e.key == 6
                                  ? const Color(0xFF1565C0)
                                  : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        ...weeks.map((week) => Row(
              children: week.map((day) {
                final isStart = _start != null && _isSameDay(day, _start!);
                final isEnd = _end != null && _isSameDay(day, _end!);
                final inRange = _isInRange(day);
                final isCurrent = day.month == _viewMonth.month;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!isCurrent) {
                        setState(() {
                          _viewMonth = DateTime(day.year, day.month);
                        });
                      }
                      _onDayTap(day);
                    },
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: inRange
                            ? const Color(0xFF7C6AFA).withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.horizontal(
                          left: isStart
                              ? const Radius.circular(18)
                              : Radius.zero,
                          right: isEnd
                              ? const Radius.circular(18)
                              : Radius.zero,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: (isStart || isEnd)
                              ? const BoxDecoration(
                                  color: Color(0xFF7C6AFA),
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: (isStart || isEnd)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: (isStart || isEnd)
                                    ? Colors.white
                                    : isCurrent
                                        ? Colors.black87
                                        : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            )),
      ],
    );
  }
}
