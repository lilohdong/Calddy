import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../calendar/domain/entities/event_entity.dart';
import '../../../calendar/domain/usecases/complete_event_usecase.dart';
import '../providers/calendar_providers.dart';
import 'color_picker_row.dart';

// 세션 내 기록 완료한 이벤트 ID 추적
final _recordedEventIds = <String>{};

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
                error: (err, stack) => const SizedBox(),
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
                    separatorBuilder: (context2, index2) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) => EventListTile(
                      event: events[i],
                      onTap: () {
                        context.pop();
                        context.push(
                            AppRoutes.eventDetailPath(events[i].id));
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
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
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
                  try {
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
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('완료 처리에 실패했습니다.')),
                      );
                    }
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
            else ...[
              if (_recordedEventIds.contains(event.id))
                TextButton(
                  onPressed: () async {
                    context.pop();
                    final result = await context.push<bool>(
                      AppRoutes.recordPath(event.id),
                      extra: true,
                    );
                    if (result == true) {
                      _recordedEventIds.add(event.id);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                  child: const Text('수정', style: TextStyle(fontSize: 12)),
                )
              else
                TextButton(
                  onPressed: () async {
                    context.pop();
                    final result = await context.push<bool>(
                        AppRoutes.recordPath(event.id));
                    if (result == true) {
                      _recordedEventIds.add(event.id);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7C6AFA),
                  ),
                  child: const Text('기록하기',
                      style: TextStyle(fontSize: 12)),
                ),
            ],
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
          onPressed: () => context.pop(),
          child: const Text('건너뛰기',
              style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            context.pop();
            context.pop(); // DateBottomSheet 닫기
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
              context.pop();
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
              context.pop();
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
              context.pop();
              final dateStr =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              context.push(AppRoutes.drawingPath(dateStr));
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
