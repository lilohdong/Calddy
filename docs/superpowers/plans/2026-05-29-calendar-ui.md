# Calendar UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Calddy 캘린더 화면 전체를 커스텀 Flutter UI로 구현한다. table_calendar 제거, 8개 화면, 11개 공유 위젯 신규/재설계.

**Architecture:** `presentation/` 레이어만 수정. `data/`, `domain/`, `providers/` 는 읽기 전용. 커스텀 CalendarGridWidget이 LayoutBuilder + Stack으로 월별 그리드와 구간 바를 렌더링. 날짜 탭 → DateBottomSheet(모달) → NewEventTypeSheet 흐름으로 진입.

**Tech Stack:** Flutter 3.x, Riverpod 2, go_router 14, flutter_naver_map 1.2, intl 0.19, image_picker 1.1

**Branch:** feat/calendar-ui (이미 생성됨)

---

## 파일 구조

### 새로 생성
```
lib/features/calendar/presentation/widgets/
  calendar_grid_widget.dart    — 월별 커스텀 그리드 (메인 조립)
  calendar_day_cell.dart       — 날짜 셀 1칸
  event_block_widget.dart      — 셀 안 이벤트 컬러 블록
  range_bar_widget.dart        — 다중일 가로 구간 바
  date_bottom_sheet.dart       — 날짜 탭 시 모달
  new_event_type_sheet.dart    — + 버튼 타입 선택 시트
  event_list_tile.dart         — 모달 내 이벤트 행
  complete_event_dialog.dart   — 완료 후 기록 유도 다이얼로그
  color_picker_row.dart        — 색상 선택 (공유 위젯)
  mini_calendar_picker.dart    — 구간 날짜 선택 인라인 캘린더
  sticker_grid_widget.dart     — 꾸미기 스티커 그리드

lib/features/calendar/presentation/pages/
  range_create_page.dart       — 구간 추가 (신규)
  record_page.dart             — 기록하기 (신규)

lib/features/map/presentation/pages/
  ai_midpoint_page.dart        — AI 중간지점 검색 (신규)
```

### 수정
```
pubspec.yaml                              — table_calendar 제거
lib/features/calendar/presentation/pages/calendar_page.dart     — 전체 재작성
lib/features/calendar/presentation/pages/event_create_page.dart — 디자인 재작성
lib/features/calendar/presentation/pages/drawing_page.dart      — 디자인 재작성
lib/core/router/app_routes.dart           — 경로 상수 추가
lib/core/router/app_router.dart           — 라우트 핸들러 추가
```

---

## 디자인 토큰 (모든 파일 공통 참조)

```dart
// 앱 전역 — 하드코딩 말고 이 값 사용
const kPrimary    = Color(0xFF7C6AFA);
const kSurface    = Color(0xFFF5F5F5);
const kSunday     = Color(0xFFE53935);
const kSaturday   = Color(0xFF1565C0);
const kCellBorder = Color(0xFFEEEEEE);

// 이벤트 프리셋 색상
const kColorOptions = [
  '#7C6AFA', '#4CAF50', '#FF9800', '#9C27B0', '#F44336', '#FFC107',
];
```

---

## Task 1: 환경 세팅

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/core/router/app_routes.dart`

- [ ] **Step 1: table_calendar 제거**

`pubspec.yaml` 에서 아래 줄 삭제:
```yaml
  table_calendar: ^3.1.2
```

- [ ] **Step 2: 새 경로 상수 추가**

`lib/core/router/app_routes.dart` 의 `// ── Calendar` 섹션 끝에 추가:
```dart
  static const String rangeCreate      = '/home/range/create';
  static const String record           = '/home/event/:eventId/record';
  static const String aiMidpoint       = '/map/ai-midpoint';

  static String recordPath(String eventId) => '/home/event/$eventId/record';
```

- [ ] **Step 3: 패키지 갱신 및 컴파일 확인**

```bash
flutter pub get
flutter analyze
```

Expected: table_calendar 관련 import 에러가 calendar_page.dart 에서 발생함 (다음 Task에서 수정).

---

## Task 2: 공유 위젯 — ColorPickerRow

**Files:**
- Create: `lib/features/calendar/presentation/widgets/color_picker_row.dart`

- [ ] **Step 1: 파일 생성**

```dart
import 'package:flutter/material.dart';

const kColorOptions = [
  '#7C6AFA', '#4CAF50', '#FF9800', '#9C27B0', '#F44336', '#FFC107',
];

class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    super.key,
    required this.selected,
    required this.onChanged,
    this.options = kColorOptions,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final List<String> options;

  static Color fromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF7C6AFA);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...options.map((hex) {
          final c = fromHex(hex);
          final isSelected = selected == hex;
          return GestureDetector(
            onTap: () => onChanged(hex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: isSelected
                    ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          );
        }),
        GestureDetector(
          onTap: () async {
            // TODO: 커스텀 색상 picker 연결 (추후 확장)
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.add, size: 18, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: 분석 확인**

```bash
flutter analyze lib/features/calendar/presentation/widgets/color_picker_row.dart
```

Expected: No issues.

---

## Task 3: 달력 셀 위젯 — EventBlockWidget, CalendarDayCell

**Files:**
- Create: `lib/features/calendar/presentation/widgets/event_block_widget.dart`
- Create: `lib/features/calendar/presentation/widgets/calendar_day_cell.dart`

- [ ] **Step 1: EventBlockWidget 생성**

```dart
// lib/features/calendar/presentation/widgets/event_block_widget.dart
import 'package:flutter/material.dart';
import '../../../calendar/domain/entities/event_entity.dart';
import 'color_picker_row.dart';

class EventBlockWidget extends StatelessWidget {
  const EventBlockWidget({super.key, required this.event});
  final EventEntity event;

  @override
  Widget build(BuildContext context) {
    final color = ColorPickerRow.fromHex(event.color);
    final timeStr =
        '${event.startAt.hour.toString().padLeft(2, '0')}:${event.startAt.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.white,
              height: 1.1,
            ),
            maxLines: 1,
          ),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: CalendarDayCell 생성**

```dart
// lib/features/calendar/presentation/widgets/calendar_day_cell.dart
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
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final List<EventEntity> events;
  final VoidCallback onTap;
  final bool isHoliday;
  final String? holidayName;

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
              ? const Color(0xFF7C6AFA).withOpacity(0.08)
              : Colors.white,
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
            // 이벤트 블록 (최대 3개)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: events
                    .take(3)
                    .map((e) => EventBlockWidget(event: e))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 분석 확인**

```bash
flutter analyze lib/features/calendar/presentation/widgets/
```

Expected: No issues.

---

## Task 4: RangeBarWidget

**Files:**
- Create: `lib/features/calendar/presentation/widgets/range_bar_widget.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/features/calendar/presentation/widgets/range_bar_widget.dart
import 'package:flutter/material.dart';
import '../../../calendar/domain/entities/event_entity.dart';
import 'color_picker_row.dart';

class RangeBarWidget extends StatelessWidget {
  const RangeBarWidget({
    super.key,
    required this.event,
    required this.isStart,
    required this.isEnd,
  });

  final EventEntity event;
  final bool isStart;
  final bool isEnd;

  @override
  Widget build(BuildContext context) {
    final color = ColorPickerRow.fromHex(event.color);
    return Container(
      height: 16,
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.horizontal(
          left: isStart ? const Radius.circular(8) : Radius.zero,
          right: isEnd ? const Radius.circular(8) : Radius.zero,
        ),
      ),
      alignment: Alignment.centerLeft,
      padding: isStart ? const EdgeInsets.only(left: 6) : EdgeInsets.zero,
      child: isStart
          ? Text(
              event.title,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
    );
  }
}
```

---

## Task 5: CalendarGridWidget

**Files:**
- Create: `lib/features/calendar/presentation/widgets/calendar_grid_widget.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/features/calendar/presentation/widgets/calendar_grid_widget.dart
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
  });

  final int year;
  final int month;
  final CalendarData data;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

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
      ...data.events.where((e) => _isSameDay(e.startAt, day)),
      ...data.habits.where((e) => _isSameDay(e.startAt, day)),
    ];
  }

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
    double verticalOffset = cellHeight * 0.55;

    for (final range in ranges) {
      final rangeStart = DateTime(
          range.startAt.year, range.startAt.month, range.startAt.day);
      final rangeEnd =
          DateTime(range.endAt.year, range.endAt.month, range.endAt.day);
      final weekStart = weekDays.first;
      final weekEnd = weekDays.last;

      if (rangeEnd.isBefore(weekStart) || rangeStart.isAfter(weekEnd)) {
        continue;
      }

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

      bars.add(
        Positioned(
          top: verticalOffset,
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
      verticalOffset += 20;
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
                              ),
                            );
                          }).toList(),
                        ),
                        ..._buildRangeBarsForWeek(
                          weekDays,
                          data.ranges,
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
```

- [ ] **Step 2: 분석 확인**

```bash
flutter analyze lib/features/calendar/presentation/widgets/calendar_grid_widget.dart
```

Expected: No issues.

---

## Task 6: CalendarPage 재작성

**Files:**
- Modify: `lib/features/calendar/presentation/pages/calendar_page.dart`

- [ ] **Step 1: 파일 전체 교체**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/calendar_providers.dart';
import '../widgets/calendar_grid_widget.dart';
import '../widgets/date_bottom_sheet.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR', null);
  }

  void _onDaySelected(DateTime day) {
    setState(() => _selectedDay = day);
    // selectedMonthProvider 와 다른 달이면 월 변경
    ref.read(selectedMonthProvider.notifier).state =
        DateTime(day.year, day.month);
    _showDateSheet(day);
  }

  void _showDateSheet(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DateBottomSheet(
        date: day,
        onAddPressed: () {
          Navigator.of(context).pop();
          _showNewEventTypeSheet(day);
        },
      ),
    );
  }

  void _showNewEventTypeSheet(DateTime day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => NewEventTypeBottomSheet(date: day),
    );
  }

  String _headerTitle() {
    final m = ref.watch(selectedMonthProvider);
    return '${m.year}-${m.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(calendarDataProvider);
    final user = ref.watch(currentUserProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                final prev = DateTime(
                    selectedMonth.year, selectedMonth.month - 1);
                ref.read(selectedMonthProvider.notifier).state = prev;
              },
              child: const Icon(Icons.chevron_left,
                  color: Colors.black87, size: 22),
            ),
            const SizedBox(width: 4),
            Text(
              _headerTitle(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                final next = DateTime(
                    selectedMonth.year, selectedMonth.month + 1);
                ref.read(selectedMonthProvider.notifier).state = next;
              },
              child: const Icon(Icons.chevron_right,
                  color: Colors.black87, size: 22),
            ),
          ],
        ),
        actions: [
          if (user?.avatarUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(user!.avatarUrl!),
              ),
            ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.black87),
                onPressed: () => context.push(AppRoutes.notifications),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: calendarAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('불러오기 실패: $e')),
        data: (data) => CalendarGridWidget(
          year: selectedMonth.year,
          month: selectedMonth.month,
          data: data,
          selectedDay: _selectedDay,
          onDaySelected: _onDaySelected,
        ),
      ),
    );
  }
}

// NewEventTypeBottomSheet는 date_bottom_sheet.dart에서 import
// (Task 7에서 구현)
```

- [ ] **Step 2: NewEventTypeBottomSheet import 임시 stub 추가**

`calendar_page.dart` 상단 import에 아래 추가 (Task 7에서 실제 파일 생성):
```dart
import '../widgets/date_bottom_sheet.dart';
```

- [ ] **Step 3: 분석 확인**

```bash
flutter analyze lib/features/calendar/presentation/pages/calendar_page.dart
```

Expected: date_bottom_sheet.dart 없음 에러만 나면 정상 진행 가능.

---

## Task 7: DateBottomSheet + NewEventTypeSheet + EventListTile + CompleteEventDialog

**Files:**
- Create: `lib/features/calendar/presentation/widgets/date_bottom_sheet.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/features/calendar/presentation/widgets/date_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../calendar/domain/entities/calendar_data.dart';
import '../../../calendar/domain/entities/event_entity.dart';
import '../providers/calendar_providers.dart';
import 'color_picker_row.dart';

// ── DateBottomSheet ────────────────────────────────────────────────
class DateBottomSheet extends ConsumerWidget {
  const DateBottomSheet({
    super.key,
    required this.date,
    required this.onAddPressed,
  });

  final DateTime date;
  final VoidCallback onAddPressed;

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(calendarDataProvider);
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final weekdayStr = weekdays[date.weekday % 7];
    final lunarStr = ''; // TODO: 음력 변환 라이브러리 연결 시 교체

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 드래그 핸들
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // 날짜 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${date.month}월 ${date.day}일 ($weekdayStr)',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny_outlined,
                          size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '맑음',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            // 이벤트 리스트
            Expanded(
              child: calendarAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
                data: (data) {
                  final events = [
                    ...data.events
                        .where((e) => _isSameDay(e.startAt, date)),
                    ...data.habits
                        .where((e) => _isSameDay(e.startAt, date)),
                  ];
                  if (events.isEmpty) {
                    return Center(
                      child: Text(
                        '등록된 일정이 없어요',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    itemCount: events.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) => EventListTile(
                      event: events[i],
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(
                            '/home/event/${events[i].id}');
                      },
                    ),
                  );
                },
              ),
            ),
            // + FAB
            Padding(
              padding: EdgeInsets.only(
                  right: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: FloatingActionButton(
                  backgroundColor: const Color(0xFF7C6AFA),
                  onPressed: onAddPressed,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── EventListTile ──────────────────────────────────────────────────
class EventListTile extends ConsumerWidget {
  const EventListTile({
    super.key,
    required this.event,
    required this.onTap,
  });

  final EventEntity event;
  final VoidCallback onTap;

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ColorPickerRow.fromHex(event.color);
    final isDone = event.status == EventStatus.done;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmtTime(event.startAt)} ~ ${_fmtTime(event.endAt)}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (!isDone)
              ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(completeEventUseCaseProvider)
                      .call(CompleteEventParams(eventId: event.id));
                  ref.invalidate(calendarDataProvider);
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          CompleteEventDialog(eventId: event.id),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6AFA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('일정 완료'),
              )
            else
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(AppRoutes.recordPath(event.id));
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF7C6AFA),
                ),
                child: const Text('기록하기',
                    style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── CompleteEventDialog ────────────────────────────────────────────
class CompleteEventDialog extends StatelessWidget {
  const CompleteEventDialog({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      title: const Text('🎉 일정을 완료했어요!',
          style: TextStyle(fontSize: 16)),
      content: const Text('기록을 남겨볼까요?',
          style: TextStyle(fontSize: 14, color: Colors.grey)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('건너뛰기',
              style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(); // DateBottomSheet 닫기
            context.push(AppRoutes.recordPath(eventId));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C6AFA),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('기록하기 →',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ── NewEventTypeBottomSheet ────────────────────────────────────────
class NewEventTypeBottomSheet extends StatelessWidget {
  const NewEventTypeBottomSheet({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '새로운 일정',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _TypeTile(
            icon: Icons.calendar_today_outlined,
            iconBg: const Color(0xFFEDE9FF),
            iconColor: const Color(0xFF7C6AFA),
            title: '일정',
            subtitle: '단일 일정 (약속 등)',
            onTap: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.eventCreate);
            },
          ),
          const SizedBox(height: 10),
          _TypeTile(
            icon: Icons.swap_horiz_rounded,
            iconBg: const Color(0xFFFFEDE9),
            iconColor: const Color(0xFFFF7043),
            title: '구간',
            subtitle: '이틀 이상 진행되는 일정',
            onTap: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.rangeCreate);
            },
          ),
          const SizedBox(height: 10),
          _TypeTile(
            icon: Icons.palette_outlined,
            iconBg: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFFFA000),
            title: '꾸미기',
            subtitle: '오늘 칸을 꾸며보세요',
            onTap: () {
              Navigator.of(context).pop();
              final dateStr =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              context.push('/home/drawing/$dateStr');
            },
          ),
        ],
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.grey.shade50,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style:
              const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right,
          color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 2: 필요한 import 확인 — CompleteEventParams**

`calendar_providers.dart`를 열어서 `completeEventUseCaseProvider` 이름과 `CompleteEventParams` import 경로 확인. `date_bottom_sheet.dart` 상단에 추가:
```dart
import '../../../calendar/domain/usecases/complete_event_usecase.dart';
```

- [ ] **Step 3: 분석 확인**

```bash
flutter analyze lib/features/calendar/presentation/widgets/date_bottom_sheet.dart
```

---

## Task 8: EventCreatePage 디자인 재작성

**Files:**
- Modify: `lib/features/calendar/presentation/pages/event_create_page.dart`

기존 비즈니스 로직(`_submit()`, controllers, providers 호출)은 유지하고 UI 레이아웃만 교체.

- [ ] **Step 1: build() 메서드와 관련 위젯 교체**

기존 파일에서 `build()` 이하만 아래로 교체 (로직 메서드 `_submit()`, `_showError()`, 컨트롤러는 그대로 유지):

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '일정 추가',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(
                        color: Color(0xFF7C6AFA),
                        fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // 제목
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: '제목을 입력하세요',
                hintStyle: TextStyle(
                    fontSize: 18, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '제목을 입력해주세요' : null,
            ),
            const Divider(),
            const SizedBox(height: 8),

            // 컬러 설정
            _SectionLabel('컬러 설정'),
            const SizedBox(height: 10),
            ColorPickerRow(
              selected: _color,
              onChanged: (hex) => setState(() => _color = hex),
            ),
            const SizedBox(height: 20),

            // 시작/종료
            _SettingTile(
              icon: Icons.access_time_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DateTimePicker(
                      label: '시작',
                      value: _startAt,
                      onChanged: (dt) =>
                          setState(() => _startAt = dt)),
                  const SizedBox(height: 8),
                  _DateTimePicker(
                      label: '종료',
                      value: _endAt,
                      onChanged: (dt) =>
                          setState(() => _endAt = dt)),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 장소
            _SettingTile(
              icon: Icons.location_on_outlined,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(
                        hintText: '장소 설정',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.push(AppRoutes.aiMidpoint),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF7C6AFA).withOpacity(0.1),
                      foregroundColor: const Color(0xFF7C6AFA),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('*AI 중간지점'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 알림
            _SettingTile(
              icon: Icons.alarm_outlined,
              label: '알림 설정',
              trailing: const Text('09:00',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              onTap: () {}, // TODO: 시간 picker
            ),
            const SizedBox(height: 4),

            // 반복
            _SettingTile(
              icon: Icons.repeat_outlined,
              label: '반복 설정',
              trailing: const Text('없음',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              onTap: () {}, // TODO: 반복 picker
            ),
            const SizedBox(height: 4),

            // D-Day
            _SettingTile(
              icon: Icons.star_border_outlined,
              label: 'D-Day 설정',
              trailing: Switch(
                value: false,
                onChanged: (_) {},
                activeColor: const Color(0xFF7C6AFA),
              ),
            ),
            const SizedBox(height: 4),

            // 친구 태그
            _SettingTile(
              icon: Icons.person_add_alt_outlined,
              child: TextFormField(
                decoration: const InputDecoration(
                  hintText: '친구를 태그하세요',
                  border: InputBorder.none,
                  isDense: true,
                  suffixText: '@',
                ),
              ),
            ),
            const SizedBox(height: 4),

            // 메모
            _SettingTile(
              icon: Icons.edit_note_outlined,
              child: TextFormField(
                controller: _memoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '메모를 입력하세요',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── 공유 섹션 위젯 ───────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87),
      );
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    this.label,
    this.child,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String? label;
  final Widget? child;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: child ??
                  Text(label ?? '',
                      style: const TextStyle(fontSize: 14)),
            ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              const Icon(Icons.chevron_right,
                  color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker(
      {required this.label,
      required this.value,
      required this.onChanged});
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        if (time == null) return;
        onChanged(date.copyWith(
            hour: time.hour, minute: time.minute, second: 0));
      },
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          Text(
            '${value.month}월 ${value.day}일 ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: import 추가**

파일 상단에 추가:
```dart
import '../../../../core/router/app_routes.dart';
import '../widgets/color_picker_row.dart';
```

- [ ] **Step 3: 분석 확인**

```bash
flutter analyze lib/features/calendar/presentation/pages/event_create_page.dart
```

---

## Task 9: RangeCreatePage + MiniCalendarPicker

**Files:**
- Create: `lib/features/calendar/presentation/widgets/mini_calendar_picker.dart`
- Create: `lib/features/calendar/presentation/pages/range_create_page.dart`

- [ ] **Step 1: MiniCalendarPicker 생성**

```dart
// lib/features/calendar/presentation/widgets/mini_calendar_picker.dart
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
    _viewMonth =
        DateTime(DateTime.now().year, DateTime.now().month);
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
    final weeks =
        List.generate(dates.length ~/ 7, (i) => dates.sublist(i * 7, i * 7 + 7));

    return Column(
      children: [
        // 월 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() {
                _viewMonth = DateTime(
                    _viewMonth.year, _viewMonth.month - 1);
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
                _viewMonth = DateTime(
                    _viewMonth.year, _viewMonth.month + 1);
              }),
            ),
          ],
        ),
        // 요일 헤더
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
        // 날짜 그리드
        ...weeks.map((week) => Row(
              children: week.map((day) {
                final isStart = _start != null && _isSameDay(day, _start!);
                final isEnd = _end != null && _isSameDay(day, _end!);
                final inRange = _isInRange(day);
                final isCurrent = day.month == _viewMonth.month;

                return Expanded(
                  child: GestureDetector(
                    onTap: isCurrent ? () => _onDayTap(day) : null,
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: inRange
                            ? const Color(0xFF7C6AFA).withOpacity(0.12)
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
```

- [ ] **Step 2: RangeCreatePage 생성**

```dart
// lib/features/calendar/presentation/pages/range_create_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/usecases/create_event_usecase.dart';
import '../providers/calendar_providers.dart';
import '../widgets/color_picker_row.dart';
import '../widgets/mini_calendar_picker.dart';

class RangeCreatePage extends ConsumerStatefulWidget {
  const RangeCreatePage({super.key});

  @override
  ConsumerState<RangeCreatePage> createState() => _RangeCreatePageState();
}

class _RangeCreatePageState extends ConsumerState<RangeCreatePage> {
  final _titleCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _color = '#7C6AFA';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기간을 선택해주세요')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      await ref.read(createEventUseCaseProvider).call(
            CreateEventParams(
              event: EventEntity(
                id: '',
                userId: '',
                title: _titleCtrl.text.trim(),
                startAt: _startDate!,
                endAt: _endDate!,
                color: _color,
                isDday: false,
                status: EventStatus.pending,
                visibility: EventVisibility.public,
                createdAt: now,
                eventType: EventType.range,
              ),
            ),
          );
      ref.invalidate(calendarDataProvider);
      if (mounted) context.pop();
    } on CalendarFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('구간을 만드는 데 실패했습니다.'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '날짜 선택';
    return '${dt.month}월 ${dt.day}일 (${['일', '월', '화', '수', '목', '금', '토'][dt.weekday % 7]})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text('구간 추가',
            style: TextStyle(
                color: Colors.black87, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('저장',
                    style: TextStyle(
                        color: Color(0xFF7C6AFA),
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // 제목
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              hintText: '제목 (예: 제주도 여행 ✈)',
              hintStyle:
                  TextStyle(fontSize: 18, color: Colors.grey),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const Divider(),
          const SizedBox(height: 16),

          // 기간 선택 (미니 캘린더)
          const Text('기간 선택',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: MiniCalendarPicker(
              selectedStart: _startDate,
              selectedEnd: _endDate,
              onRangeSelected: (s, e) =>
                  setState(() {
                    _startDate = s;
                    _endDate = e;
                  }),
            ),
          ),
          const SizedBox(height: 16),

          // 시작/종료 표시 칩
          Row(
            children: [
              Expanded(
                child: _DateChip(
                    label: '시작', value: _fmtDate(_startDate)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateChip(
                    label: '종료', value: _fmtDate(_endDate)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 컬러
          const Text('컬러 설정',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ColorPickerRow(
            selected: _color,
            onChanged: (hex) => setState(() => _color = hex),
          ),
          const SizedBox(height: 20),

          // 장소
          _RowTile(
            icon: Icons.location_on_outlined,
            child: Row(
              children: [
                const Expanded(
                  child: Text('장소 설정',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () =>
                      context.push(AppRoutes.aiMidpoint),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6AFA)
                        .withOpacity(0.1),
                    foregroundColor: const Color(0xFF7C6AFA),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    textStyle:
                        const TextStyle(fontSize: 12),
                  ),
                  child: const Text('*AI 중간지점'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // 친구 태그
          _RowTile(
            icon: Icons.person_add_alt_outlined,
            child: const Text('친구 태그',
                style:
                    TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          const SizedBox(height: 4),

          // 알림
          _RowTile(
            icon: Icons.alarm_outlined,
            child: const Text('알림 시간',
                style:
                    TextStyle(fontSize: 14, color: Colors.grey)),
            trailing: const Text('09:00',
                style:
                    TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile(
      {required this.icon, required this.child, this.trailing});
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(child: child),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
```

---

## Task 10: DrawingPage 디자인 재작성 + StickerGridWidget

**Files:**
- Create: `lib/features/calendar/presentation/widgets/sticker_grid_widget.dart`
- Modify: `lib/features/calendar/presentation/pages/drawing_page.dart`

- [ ] **Step 1: StickerGridWidget 생성**

```dart
// lib/features/calendar/presentation/widgets/sticker_grid_widget.dart
import 'package:flutter/material.dart';

const kStickers = [
  '☕', '📚', '🌷', '🎵', '✨', '🌙',
  '💝', '🎂', '🌈', '⭐', '🌮', '🌿',
];

class StickerGridWidget extends StatelessWidget {
  const StickerGridWidget({super.key, required this.onStickerSelected});
  final ValueChanged<String> onStickerSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: kStickers.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => onStickerSelected(kStickers[i]),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(kStickers[i], style: const TextStyle(fontSize: 22)),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: DrawingPage 전체 재작성**

```dart
// lib/features/calendar/presentation/pages/drawing_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/drawing_entity.dart';
import '../../domain/usecases/save_drawing_usecase.dart';
import '../providers/calendar_providers.dart';
import '../widgets/sticker_grid_widget.dart';

class DrawingPage extends ConsumerStatefulWidget {
  const DrawingPage({super.key, required this.date});
  final String date;

  @override
  ConsumerState<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends ConsumerState<DrawingPage> {
  final List<DrawingStroke> _strokes = [];
  List<List<double>> _currentPoints = [];
  Color _bgColor = const Color(0xFFE8E0FF);
  Color _strokeColor = Colors.black87;
  double _strokeWidth = 4.0;
  bool _handwritingMode = false;
  bool _isLoading = false;
  final List<_PlacedSticker> _stickers = [];
  bool _showStickerPanel = false;

  static const _bgColors = [
    Color(0xFFFFF9C4), // 노랑
    Color(0xFFE8E0FF), // 보라
    Color(0xFFFFE0E0), // 분홍
    Color(0xFFE0F7E9), // 초록
    Color(0xFF263238), // 검정
  ];

  static const _colorHexMap = {
    Colors.black87: '#1A1A1A',
    Colors.red: '#FF0000',
    Colors.blue: '#1565C0',
    Colors.green: '#2E7D32',
    Colors.orange: '#FF6D00',
    Colors.white: '#FFFFFF',
  };

  DateTime get _parsedDate {
    final p = widget.date.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      await ref.read(saveDrawingUseCaseProvider).call(
            SaveDrawingParams(
              drawing: DrawingEntity(
                id: '',
                userId: '',
                drawDate: _parsedDate,
                strokes: _strokes,
                updatedAt: now,
              ),
            ),
          );
      if (mounted) context.pop();
    } on DrawingFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('저장에 실패했습니다.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _parsedDate;
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final isDark = _bgColor.computeLuminance() < 0.3;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text('꾸미기',
            style: TextStyle(
                color: Colors.black87, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('저장',
                    style: TextStyle(
                        color: Color(0xFF7C6AFA),
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 캔버스
          Expanded(
            child: GestureDetector(
              onPanStart: _handwritingMode
                  ? (details) {
                      setState(() {
                        _currentPoints = [
                          [details.localPosition.dx, details.localPosition.dy]
                        ];
                      });
                    }
                  : null,
              onPanUpdate: _handwritingMode
                  ? (details) {
                      setState(() {
                        _currentPoints = [
                          ..._currentPoints,
                          [details.localPosition.dx, details.localPosition.dy],
                        ];
                      });
                    }
                  : null,
              onPanEnd: _handwritingMode
                  ? (_) {
                      if (_currentPoints.isNotEmpty) {
                        final hex = _colorHexMap[_strokeColor] ??
                            '#${_strokeColor.value.toRadixString(16).padLeft(8, '0')}';
                        setState(() {
                          _strokes.add(DrawingStroke(
                            color: hex,
                            width: _strokeWidth,
                            points: List.from(_currentPoints),
                          ));
                          _currentPoints = [];
                        });
                      }
                    }
                  : null,
              child: Container(
                color: _bgColor,
                child: Stack(
                  children: [
                    // 날짜 표시
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white.withOpacity(0.7)
                                  : const Color(0xFF7C6AFA),
                            ),
                          ),
                          Text(
                            '${weekdays[d.weekday % 7]}요일',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 동기부여 문구
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Text(
                        '오늘도 화이팅!',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.4)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    // 스티커
                    ..._stickers.map((s) => Positioned(
                          left: s.x,
                          top: s.y,
                          child: GestureDetector(
                            onPanUpdate: (d) {
                              setState(() {
                                s.x += d.delta.dx;
                                s.y += d.delta.dy;
                              });
                            },
                            child: Text(s.emoji,
                                style:
                                    const TextStyle(fontSize: 36)),
                          ),
                        )),
                    // 손글씨 캔버스
                    if (_handwritingMode)
                      CustomPaint(
                        painter: _CanvasPainter(
                          strokes: _strokes,
                          currentPoints: _currentPoints,
                          currentColor: _strokeColor,
                          currentWidth: _strokeWidth,
                        ),
                        child: const SizedBox.expand(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // 하단 툴패널
          _BottomToolPanel(
            bgColors: _bgColors,
            selectedBg: _bgColor,
            onBgChanged: (c) => setState(() => _bgColor = c),
            handwritingMode: _handwritingMode,
            onHandwritingToggle: (v) =>
                setState(() => _handwritingMode = v),
            showStickerPanel: _showStickerPanel,
            onStickerToggle: () =>
                setState(() => _showStickerPanel = !_showStickerPanel),
            onStickerSelected: (emoji) {
              setState(() {
                _stickers.add(_PlacedSticker(
                  emoji: emoji,
                  x: 100 + (_stickers.length * 20) % 200,
                  y: 100 + (_stickers.length * 15) % 150,
                ));
                _showStickerPanel = false;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _PlacedSticker {
  _PlacedSticker({required this.emoji, required this.x, required this.y});
  final String emoji;
  double x;
  double y;
}

class _BottomToolPanel extends StatelessWidget {
  const _BottomToolPanel({
    required this.bgColors,
    required this.selectedBg,
    required this.onBgChanged,
    required this.handwritingMode,
    required this.onHandwritingToggle,
    required this.showStickerPanel,
    required this.onStickerToggle,
    required this.onStickerSelected,
  });

  final List<Color> bgColors;
  final Color selectedBg;
  final ValueChanged<Color> onBgChanged;
  final bool handwritingMode;
  final ValueChanged<bool> onHandwritingToggle;
  final bool showStickerPanel;
  final VoidCallback onStickerToggle;
  final ValueChanged<String> onStickerSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStickerPanel)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('스티커',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  const SizedBox(height: 8),
                  StickerGridWidget(
                      onStickerSelected: onStickerSelected),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('배경',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                const SizedBox(height: 8),
                Row(
                  children: bgColors
                      .map((c) => GestureDetector(
                            onTap: () => onBgChanged(c),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 150),
                              width: 36,
                              height: 36,
                              margin:
                                  const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius:
                                    BorderRadius.circular(8),
                                border: selectedBg == c
                                    ? Border.all(
                                        color:
                                            const Color(0xFF7C6AFA),
                                        width: 2)
                                    : Border.all(
                                        color: Colors.grey.shade200),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: const Text('기타',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.edit_outlined,
                            size: 18, color: Colors.black54),
                        SizedBox(width: 8),
                        Text('손글씨',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87)),
                      ],
                    ),
                    Switch(
                      value: handwritingMode,
                      onChanged: onHandwritingToggle,
                      activeColor: const Color(0xFF7C6AFA),
                    ),
                  ],
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.format_color_text,
                      size: 18, color: Colors.black54),
                  title: const Text('스티커',
                      style: TextStyle(fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.grey),
                  onTap: onStickerToggle,
                ),
              ],
            ),
          ),
          SizedBox(
              height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  const _CanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
  });

  final List<DrawingStroke> strokes;
  final List<List<double>> currentPoints;
  final Color currentColor;
  final double currentWidth;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      Color c;
      try {
        c = Color(int.parse(s.color.replaceFirst('#', '0xFF')));
      } catch (_) {
        c = Colors.black87;
      }
      _drawPoints(canvas, s.points, c, s.width);
    }
    if (currentPoints.isNotEmpty) {
      _drawPoints(
          canvas, currentPoints, currentColor, currentWidth);
    }
  }

  void _drawPoints(Canvas canvas, List<List<double>> pts,
      Color color, double width) {
    if (pts.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(pts[0][0], pts[0][1]);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i][0], pts[i][1]);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CanvasPainter old) => true;
}
```

---

## Task 11: RecordPage

**Files:**
- Create: `lib/features/calendar/presentation/pages/record_page.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/features/calendar/presentation/pages/record_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RecordPage extends ConsumerStatefulWidget {
  const RecordPage({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage> {
  final _contentCtrl = TextEditingController();
  bool _isPublic = true;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      setState(() => _selectedImage = File(xFile.path));
    }
  }

  Future<void> _submit() async {
    if (_contentCtrl.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력하거나 사진을 추가해주세요')),
      );
      return;
    }
    setState(() => _isLoading = true);
    // TODO: ref.read(createPostUseCaseProvider).call(...)
    // 피드 팀 Provider 연결 후 구현
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기록이 저장되었습니다.')),
      );
      context.pop();
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text('기록하기',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('완료',
                    style: TextStyle(
                        color: Color(0xFF7C6AFA),
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 이벤트 이름 헤더 (eventId 기반 — 실제 연결 시 provider로)
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF7C6AFA),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '일정 · ${widget.eventId}',
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7C6AFA),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 본문 입력
          TextField(
            controller: _contentCtrl,
            maxLines: 8,
            style: const TextStyle(fontSize: 16, height: 1.6),
            decoration: const InputDecoration(
              hintText: '오늘의 기록을 남겨보세요...',
              hintStyle:
                  TextStyle(fontSize: 16, color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 16),

          // 사진 추가
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                image: _selectedImage != null
                    ? DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            size: 36,
                            color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('탭하여 사진 추가',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13)),
                      ],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 24),

          // 전체 공유 토글
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('전체 공유',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    Text('피드에 노출돼요',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Switch(
                  value: _isPublic,
                  onChanged: (v) =>
                      setState(() => _isPublic = v),
                  activeColor: const Color(0xFF7C6AFA),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Task 12: AIMidpointPage

**Files:**
- Create: `lib/features/map/presentation/pages/ai_midpoint_page.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/features/map/presentation/pages/ai_midpoint_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AiMidpointPage extends StatefulWidget {
  const AiMidpointPage({super.key});

  @override
  State<AiMidpointPage> createState() => _AiMidpointPageState();
}

class _AiMidpointPageState extends State<AiMidpointPage> {
  String _calcBasis = '대중교통 최적화';
  int _selectedIndex = 0;

  static const _calcOptions = [
    '대중교통 최적화',
    '직선 거리',
    '도보 최적화',
  ];

  // 샘플 데이터 — 실제 연결 시 AIMidpointUseCase provider로 교체
  static const _mockPlaces = [
    _MidpointPlace(
      rank: 1,
      name: '고속터미널역',
      lines: '3, 7, 9호선',
      avgMinutes: 30,
    ),
    _MidpointPlace(
      rank: 2,
      name: '강남구청역',
      lines: '7호선',
      avgMinutes: 32,
    ),
    _MidpointPlace(
      rank: 3,
      name: '신논현역',
      lines: '9호선',
      avgMinutes: 35,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7C6AFA).withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '*AI',
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7C6AFA),
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '중간지점 검색',
              style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final place = _mockPlaces[_selectedIndex];
              context.pop(place.name);
            },
            child: const Text('✓',
                style: TextStyle(
                    color: Color(0xFF7C6AFA),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 지도 플레이스홀더
          Container(
            height: 220,
            color: const Color(0xFFE8F0FE),
            child: Stack(
              children: [
                const Center(
                  child: Text(
                    '🗺️',
                    style: TextStyle(fontSize: 60),
                  ),
                ),
                // 참가자 핀 시뮬레이션
                Positioned(
                  left: 60,
                  bottom: 60,
                  child: _MapPin(label: '나·강남역', color: const Color(0xFF7C6AFA)),
                ),
                Positioned(
                  right: 60,
                  top: 40,
                  child: _MapPin(label: 'Friend(B)·잠실역',
                      color: const Color(0xFFFF9800)),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C6AFA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '+ AI 추천 중간지점',
                        style: TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 하단 패널
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, -2))
                ],
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 참가자
                  const Text('참가자',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ParticipantChip(
                          initial: '나', label: '강남역',
                          color: const Color(0xFF7C6AFA)),
                      const SizedBox(width: 8),
                      _ParticipantChip(
                          initial: 'B', label: '잠실역',
                          color: const Color(0xFFFF9800)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 계산 기준
                  const Text('계산 기준',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _calcOptions.map((opt) {
                        final isSelected = _calcBasis == opt;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _calcBasis = opt),
                          child: Container(
                            margin:
                                const EdgeInsets.only(right: 8),
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF7C6AFA)
                                  : Colors.grey.shade100,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              opt,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 추천 중간지점 리스트
                  const Text('추천 중간지점',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                  const SizedBox(height: 8),
                  ..._mockPlaces.asMap().entries.map((e) {
                    final i = e.key;
                    final p = e.value;
                    final isSelected = _selectedIndex == i;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedIndex = i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF7C6AFA)
                                  .withOpacity(0.08)
                              : const Color(0xFFF5F5F5),
                          borderRadius:
                              BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFF7C6AFA),
                                  width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF7C6AFA)
                                    : Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${p.rank}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${p.lines} · 대중교통 이동 최적 (평균 ${p.avgMinutes}분)',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // 하단 버튼
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                          child: const Text('이전으로',
                              style: TextStyle(
                                  color: Colors.black87)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final place =
                                _mockPlaces[_selectedIndex];
                            context.pop(place.name);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF7C6AFA),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                          child: const Text(
                            '이 장소로 설정',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MidpointPlace {
  const _MidpointPlace({
    required this.rank,
    required this.name,
    required this.lines,
    required this.avgMinutes,
  });
  final int rank;
  final String name;
  final String lines;
  final int avgMinutes;
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 10)),
        ),
        Container(
          width: 2,
          height: 10,
          color: color,
        ),
      ],
    );
  }
}

class _ParticipantChip extends StatelessWidget {
  const _ParticipantChip(
      {required this.initial,
      required this.label,
      required this.color});
  final String initial;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: color,
            child: Text(initial,
                style: const TextStyle(
                    color: Colors.white, fontSize: 10)),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
```

---

## Task 13: Router 연결

**Files:**
- Modify: `lib/core/router/app_router.dart`

- [ ] **Step 1: import 추가 (파일 상단)**

```dart
import '../../features/calendar/presentation/pages/range_create_page.dart';
import '../../features/calendar/presentation/pages/record_page.dart';
import '../../features/map/presentation/pages/ai_midpoint_page.dart';
```

- [ ] **Step 2: 라우트 추가 — home ShellRoute routes 안에 추가**

기존 `drawing/:date` GoRoute 아래에 추가:
```dart
GoRoute(
  path: 'range/create',
  builder: (_, _) => const RangeCreatePage(),
),
GoRoute(
  path: 'event/:eventId/record',
  builder: (_, s) => RecordPage(
    eventId: s.pathParameters['eventId']!,
  ),
),
```

- [ ] **Step 3: 단독 경로 추가 — notifications GoRoute 아래에 추가**

```dart
GoRoute(
  path: AppRoutes.aiMidpoint,
  builder: (_, _) => const AiMidpointPage(),
),
```

- [ ] **Step 4: 최종 분석**

```bash
flutter analyze
```

Expected: No issues.

- [ ] **Step 5: 빌드 확인**

```bash
flutter build apk --debug --dart-define-from-file=env.json 2>&1 | tail -20
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

---

## 체크리스트 (PR 전 확인)

- [ ] `data/`, `domain/`, `providers/` 파일 수정 없음
- [ ] Navigator.of(context).push 사용 없음 (context.push 사용)
- [ ] 새 경로 모두 AppRoutes 상수에 추가됨
- [ ] FutureProvider 내 ref.read 사용 확인
- [ ] flutter analyze 에러 없음
- [ ] `table_calendar` import 전체 제거됨
