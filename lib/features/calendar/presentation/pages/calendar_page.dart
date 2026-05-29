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
