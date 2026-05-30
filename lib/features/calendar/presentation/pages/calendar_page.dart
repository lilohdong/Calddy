import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notification/domain/entities/notification_entity.dart';
import '../../../notification/presentation/providers/notification_providers.dart';
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
          context.pop();
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
    return '${m.year}년 ${m.month}월';
  }

  void _showBell() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) => const _NotificationPopover(),
    );
  }

  void _showYearMonthPicker() {
    final current = ref.read(selectedMonthProvider);
    showDialog(
      context: context,
      builder: (ctx) => _YearMonthPickerDialog(
        initialYear: current.year,
        initialMonth: current.month,
        onSelected: (year, month) {
          ref.read(selectedMonthProvider.notifier).state =
              DateTime(year, month);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(calendarDataProvider);
    final user = ref.watch(currentUserProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final drawingThumbnails = ref.watch(
      drawingThumbnailsForMonthProvider(selectedMonth),
    ).maybeWhen(
      data: (map) => map,
      orElse: () => <String, String?>{},
    );
    final hasUnread = ref.watch(notificationsProvider).maybeWhen(
      data: (list) => list.any((n) => !n.isRead),
      orElse: () => false,
    );

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
            GestureDetector(
              onTap: _showYearMonthPicker,
              child: Text(
                _headerTitle(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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
                onPressed: _showBell,
              ),
              if (hasUnread)
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
        data: (data) => GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            final selectedMonth = ref.read(selectedMonthProvider);
            if (details.primaryVelocity! < -200) {
              ref.read(selectedMonthProvider.notifier).state =
                  DateTime(selectedMonth.year, selectedMonth.month + 1);
            } else if (details.primaryVelocity! > 200) {
              ref.read(selectedMonthProvider.notifier).state =
                  DateTime(selectedMonth.year, selectedMonth.month - 1);
            }
          },
          child: CalendarGridWidget(
            year: selectedMonth.year,
            month: selectedMonth.month,
            data: data,
            selectedDay: _selectedDay,
            onDaySelected: _onDaySelected,
            drawingThumbnails: drawingThumbnails,
          ),
        ),
      ),
    );
  }
}

class _YearMonthPickerDialog extends StatefulWidget {
  const _YearMonthPickerDialog({
    required this.initialYear,
    required this.initialMonth,
    required this.onSelected,
  });

  final int initialYear;
  final int initialMonth;
  final void Function(int year, int month) onSelected;

  @override
  State<_YearMonthPickerDialog> createState() => _YearMonthPickerDialogState();
}

class _YearMonthPickerDialogState extends State<_YearMonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(10, (i) => now.year - 5 + i);
    const months = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월',
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '날짜 이동',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // 연도 선택
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: years.map((y) {
                  final isSelected = y == _selectedYear;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedYear = y),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF7C6AFA)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$y년',
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : Colors.black87,
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
            const SizedBox(height: 12),
            // 월 선택 (3x4 그리드)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (_, i) {
                final m = i + 1;
                final isSelected = m == _selectedMonth;
                return GestureDetector(
                  onTap: () {
                    widget.onSelected(_selectedYear, m);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF7C6AFA)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        months[i],
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기',
                  style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 알림 팝오버 (말풍선 꼬리)
// ══════════════════════════════════════════════════════════════════════════════

const _kPurple = Color(0xFF7C6AFA);

class _NotificationPopover extends ConsumerWidget {
  const _NotificationPopover();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);
    final mq = MediaQuery.of(context);
    final topOffset = mq.padding.top + 56 + 6.0;

    return Padding(
      padding: EdgeInsets.only(top: topOffset, right: 8),
      child: Align(
        alignment: Alignment.topRight,
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 꼬리 삼각형 — 벨 아이콘 아래에 오도록 우측 정렬
              const Padding(
                padding: EdgeInsets.only(right: 18),
                child: CustomPaint(
                  painter: _PopoverTailPainter(),
                  size: Size(16, 9),
                ),
              ),
              // 패널
              Container(
                width: mq.size.width * 0.72,
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Text(
                        '알림',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: notifAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                              child: CircularProgressIndicator(color: _kPurple)),
                        ),
                        error: (_, __) => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('알림을 불러올 수 없어요')),
                        ),
                        data: (notifs) {
                          if (notifs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 28),
                              child: Center(
                                child: Text('새로운 알림이 없어요',
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: notifs.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, indent: 16, endIndent: 16),
                            itemBuilder: (_, i) => _NotifTile(notif: notifs[i]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopoverTailPainter extends CustomPainter {
  const _PopoverTailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notif});

  final NotificationEntity notif;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: notif.isRead
              ? Colors.grey.shade100
              : const Color(0xFFEDE9FF),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _notifIcon(notif.type),
          color: notif.isRead ? Colors.grey : _kPurple,
          size: 20,
        ),
      ),
      title: Text(
        notif.title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w600,
          color: const Color(0xFF1A1A2E),
        ),
      ),
      subtitle: Text(
        notif.body,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  IconData _notifIcon(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return Icons.person_add_outlined;
      case NotificationType.appointmentInvite:
        return Icons.event_outlined;
      case NotificationType.appointmentAccepted:
        return Icons.check_circle_outline;
      case NotificationType.appointmentRejected:
        return Icons.cancel_outlined;
      case NotificationType.suggestNewDate:
        return Icons.update_outlined;
      case NotificationType.postLiked:
        return Icons.favorite_border_rounded;
      case NotificationType.postCommented:
        return Icons.chat_bubble_outline_rounded;
    }
  }
}
