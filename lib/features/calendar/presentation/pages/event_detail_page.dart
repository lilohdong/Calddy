import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/usecases/delete_event_usecase.dart';
import '../../domain/usecases/update_event_usecase.dart';
import '../providers/calendar_providers.dart';
import '../widgets/color_picker_row.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  const EventDetailPage({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  bool _isDeleting = false;

  // 인라인 편집 상태
  bool _isEditing = false;
  String? _editColor;
  DateTime? _editStartAt;
  DateTime? _editEndAt;
  bool _isSaving = false;

  Future<void> _delete(EventEntity event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(eventTitle: event.title),
    );
    if (confirm != true || !mounted) return;
    setState(() => _isDeleting = true);
    try {
      await ref
          .read(deleteEventUseCaseProvider)
          .call(DeleteEventParams(eventId: widget.eventId));
      ref.invalidate(calendarDataProvider);
      if (mounted) context.pop();
    } on CalendarFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('삭제에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _saveEdit(EventEntity original) async {
    setState(() => _isSaving = true);
    try {
      final updated = original.copyWith(
        color: _editColor ?? original.color,
        startAt: _editStartAt ?? original.startAt,
        endAt: _editEndAt ?? original.endAt,
      );
      await ref
          .read(updateEventUseCaseProvider)
          .call(UpdateEventParams(event: updated));
      ref.invalidate(calendarDataProvider);
      setState(() => _isEditing = false);
    } on CalendarFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('수정에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _startEdit(EventEntity event) {
    setState(() {
      _isEditing = true;
      _editColor = event.color;
      _editStartAt = event.startAt;
      _editEndAt = event.endAt;
    });
  }

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(calendarDataProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '일정 상세',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF7C6AFA)),
              onPressed: () => calendarAsync.whenData((d) {
                final event = d.events.where((e) => e.id == widget.eventId).firstOrNull;
                if (event != null) _startEdit(event);
              }),
            ),
          calendarAsync.when(
            loading: () => const SizedBox(),
            error: (_, _s) => const SizedBox(),
            data: (data) {
              final event = data.events.where((e) => e.id == widget.eventId).firstOrNull;
              if (event == null) return const SizedBox();
              return IconButton(
                icon: _isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                      )
                    : const Icon(Icons.delete_outline_rounded, color: Colors.red),
                onPressed: _isDeleting ? null : () => _delete(event),
              );
            },
          ),
        ],
      ),
      body: calendarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text(e is CalendarFailure ? e.message : '불러오기 실패')),
        data: (data) {
          final event = data.events
              .where((e) => e.id == widget.eventId)
              .firstOrNull;
          if (event == null) {
            return const Center(child: Text('일정을 찾을 수 없습니다.'));
          }
          if (_isEditing) {
            return _EditBody(
              event: event,
              editColor: _editColor ?? event.color,
              editStartAt: _editStartAt ?? event.startAt,
              editEndAt: _editEndAt ?? event.endAt,
              isSaving: _isSaving,
              onColorChanged: (c) => setState(() => _editColor = c),
              onStartChanged: (dt) => setState(() => _editStartAt = dt),
              onEndChanged: (dt) => setState(() => _editEndAt = dt),
              onSave: () => _saveEdit(event),
              onCancel: () => setState(() => _isEditing = false),
            );
          }
          return _DetailBody(event: event);
        },
      ),
    );
  }
}

// ── 상세 뷰 ──────────────────────────────────────────────────────────────────
class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.event});
  final EventEntity event;

  @override
  Widget build(BuildContext context) {
    final color = ColorPickerRow.fromHex(event.color);
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 컬러 + 제목 헤더
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              if (event.isDday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('D-Day',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 날짜 카드
        _InfoCard(
          icon: Icons.calendar_today_outlined,
          iconColor: const Color(0xFF7C6AFA),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${event.startAt.year}년 ${event.startAt.month}월 ${event.startAt.day}일 (${weekdays[event.startAt.weekday % 7]})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              if (!_isSameDay(event.startAt, event.endAt)) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${event.endAt.year}년 ${event.endAt.month}월 ${event.endAt.day}일 (${weekdays[event.endAt.weekday % 7]})',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 장소
        if (event.location != null)
          _InfoCard(
            icon: Icons.location_on_outlined,
            iconColor: Colors.orange,
            child: Text(event.location!, style: const TextStyle(fontSize: 14)),
          ),
        if (event.location != null) const SizedBox(height: 8),

        // 메모
        if (event.memo != null)
          _InfoCard(
            icon: Icons.sticky_note_2_outlined,
            iconColor: Colors.teal,
            child: Text(event.memo!,
                style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
        if (event.memo != null) const SizedBox(height: 8),

        // 반복
        if (event.recurrenceType != null)
          _InfoCard(
            icon: Icons.repeat_outlined,
            iconColor: Colors.purple,
            child: Text(_recurrenceLabel(event),
                style: const TextStyle(fontSize: 14)),
          ),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _recurrenceLabel(EventEntity e) {
    const weekdayNames = [
      '',
      '매주 월요일',
      '매주 화요일',
      '매주 수요일',
      '매주 목요일',
      '매주 금요일',
      '매주 토요일',
      '매주 일요일',
    ];
    switch (e.recurrenceType) {
      case RecurrenceType.daily:
        return '매일 반복';
      case RecurrenceType.weekly:
        final wd = e.recurrenceDays?.firstOrNull ?? e.startAt.weekday;
        return weekdayNames[wd];
      case RecurrenceType.monthly:
        final d = e.recurrenceDays?.firstOrNull ?? e.startAt.day;
        return '매월 ${d}일'; // ignore: unnecessary_brace_in_string_interps
      case null:
        return '반복 없음';
    }
  }
}

// ── 편집 뷰 ──────────────────────────────────────────────────────────────────
class _EditBody extends StatelessWidget {
  const _EditBody({
    required this.event,
    required this.editColor,
    required this.editStartAt,
    required this.editEndAt,
    required this.isSaving,
    required this.onColorChanged,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onSave,
    required this.onCancel,
  });

  final EventEntity event;
  final String editColor;
  final DateTime editStartAt;
  final DateTime editEndAt;
  final bool isSaving;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime> onEndChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 제목 (편집 불가 — 표시만)
        Text(event.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('제목 수정은 일정 삭제 후 재생성',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        const SizedBox(height: 24),

        // 컬러
        const Text('컬러',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 10),
        ColorPickerRow(
          selected: editColor,
          onChanged: onColorChanged,
        ),
        const SizedBox(height: 20),

        // 시작일
        const Text('시작일',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        _DateButton(
          value: editStartAt,
          weekdays: weekdays,
          onChanged: onStartChanged,
        ),
        const SizedBox(height: 16),

        // 종료일
        const Text('종료일',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        _DateButton(
          value: editEndAt,
          weekdays: weekdays,
          onChanged: onEndChanged,
        ),
        const SizedBox(height: 32),

        // 저장/취소
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('취소',
                    style: TextStyle(color: Colors.black87)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isSaving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6AFA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('저장'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── 공통 위젯 ────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.value,
    required this.weekdays,
    required this.onChanged,
  });
  final DateTime value;
  final List<String> weekdays;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme:
                  const ColorScheme.light(primary: Color(0xFF7C6AFA)),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          onChanged(DateTime(
              picked.year, picked.month, picked.day, value.hour, value.minute));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF7C6AFA).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: Color(0xFF7C6AFA)),
            const SizedBox(width: 10),
            Text(
              '${value.year}년 ${value.month}월 ${value.day}일 (${weekdays[value.weekday % 7]})',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 삭제 확인 다이얼로그 ────────────────────────────────────────────────────
class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({required this.eventTitle});
  final String eventTitle;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              '일정을 삭제할까요?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '"$eventTitle"',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            const Text(
              '삭제된 일정은 복구할 수 없습니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('취소',
                        style: TextStyle(color: Colors.black87)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('삭제'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

