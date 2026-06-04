import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/usecases/delete_event_usecase.dart';
import '../../domain/usecases/update_event_usecase.dart';
import '../providers/calendar_providers.dart';
import '../widgets/color_picker_row.dart';
import '../widgets/mini_calendar_picker.dart';

// ── 알림 모드 (구간 상세용) ────────────────────────────────────────────────────
enum _AlarmMode { none, sameDay9am, thirtyMin, oneHour, oneDay, custom }

String _alarmLabel(_AlarmMode mode, TimeOfDay custom) {
  switch (mode) {
    case _AlarmMode.none:       return '없음';
    case _AlarmMode.sameDay9am: return '당일 오전 9시';
    case _AlarmMode.thirtyMin:  return '30분 전';
    case _AlarmMode.oneHour:    return '1시간 전';
    case _AlarmMode.oneDay:     return '하루 전';
    case _AlarmMode.custom:
      return '${custom.hour.toString().padLeft(2, '0')}:'
          '${custom.minute.toString().padLeft(2, '0')} 알림';
  }
}

int? _alarmToMinutes(_AlarmMode mode, TimeOfDay custom, DateTime start) {
  switch (mode) {
    case _AlarmMode.none:       return null;
    case _AlarmMode.thirtyMin:  return 30;
    case _AlarmMode.oneHour:    return 60;
    case _AlarmMode.oneDay:     return 1440;
    case _AlarmMode.sameDay9am:
      final diff = start.hour * 60 + start.minute - 9 * 60;
      return diff > 0 ? diff : null;
    case _AlarmMode.custom:
      final diff = start.hour * 60 + start.minute -
          (custom.hour * 60 + custom.minute);
      return diff > 0 ? diff : null;
  }
}

_AlarmMode _minutesToAlarmMode(int? min) {
  if (min == null) return _AlarmMode.none;
  if (min == 30)   return _AlarmMode.thirtyMin;
  if (min == 60)   return _AlarmMode.oneHour;
  if (min == 1440) return _AlarmMode.oneDay;
  return _AlarmMode.sameDay9am; // 그 외는 당일 오전 9시로 근사
}

// ══════════════════════════════════════════════════════════════════════════════
// EventDetailPage
// ══════════════════════════════════════════════════════════════════════════════
class EventDetailPage extends ConsumerStatefulWidget {
  const EventDetailPage({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  bool _isDeleting = false;
  bool _isSaving = false;

  bool _initialized = false;
  String? _editTitle;
  String? _editColor;
  DateTime? _editStartAt;
  DateTime? _editEndAt;
  // 구간 전용 필드
  String? _editLocation;
  _AlarmMode _alarmMode = _AlarmMode.sameDay9am;
  TimeOfDay _customAlarmTime = const TimeOfDay(hour: 9, minute: 0);

  void _initEditOnce(EventEntity event) {
    if (_initialized) return;
    _initialized = true;
    _editTitle    = event.title;
    _editColor    = event.color;
    _editStartAt  = event.startAt;
    _editEndAt    = event.endAt;
    _editLocation = event.location;
    _alarmMode    = _minutesToAlarmMode(event.notifyBeforeMin);
  }

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
    final title = _editTitle?.trim() ?? '';
    if (title.isEmpty) { _showError('제목을 입력해주세요.'); return; }
    setState(() => _isSaving = true);
    try {
      final notifyMin = original.eventType == EventType.range
          ? _alarmToMinutes(_alarmMode, _customAlarmTime, _editStartAt ?? original.startAt)
          : null;
      final updated = original.copyWith(
        title: title,
        color: _editColor ?? original.color,
        startAt: _editStartAt ?? original.startAt,
        endAt: _editEndAt ?? original.endAt,
        location: _editLocation?.trim().isEmpty ?? true ? null : _editLocation!.trim(),
        notifyBeforeMin: notifyMin,
      );
      await ref
          .read(updateEventUseCaseProvider)
          .call(UpdateEventParams(event: updated));
      ref.invalidate(calendarDataProvider);
      if (mounted) context.pop();
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
        title: calendarAsync.when(
          loading: () => const Text('상세',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
          error: (_, __) => const Text('상세',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
          data: (data) {
            final event = [...data.events, ...data.ranges]
                .where((e) => e.id == widget.eventId)
                .firstOrNull;
            final isRange = event?.eventType == EventType.range;
            return Text(
              isRange ? '구간 상세' : '일정 상세',
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
            );
          },
        ),
        centerTitle: true,
        actions: [
          calendarAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (data) {
              final event = [...data.events, ...data.ranges]
                  .where((e) => e.id == widget.eventId)
                  .firstOrNull;
              if (event == null) return const SizedBox();
              return IconButton(
                icon: _isDeleting
                    ? const SizedBox(
                        width: 18, height: 18,
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
          final event = [...data.events, ...data.ranges]
              .where((e) => e.id == widget.eventId)
              .firstOrNull;
          if (event == null) {
            return const Center(child: Text('일정을 찾을 수 없습니다.'));
          }
          _initEditOnce(event);

          if (event.eventType == EventType.range) {
            return _RangeEditBody(
              event: event,
              editTitle: _editTitle!,
              editColor: _editColor ?? event.color,
              editStartAt: _editStartAt ?? event.startAt,
              editEndAt: _editEndAt ?? event.endAt,
              editLocation: _editLocation ?? event.location ?? '',
              alarmMode: _alarmMode,
              customAlarmTime: _customAlarmTime,
              isSaving: _isSaving,
              onTitleChanged: (t) => setState(() => _editTitle = t),
              onColorChanged: (c) => setState(() => _editColor = c),
              onRangeChanged: (s, e2) => setState(() {
                _editStartAt = DateTime(s.year, s.month, s.day, 0, 0);
                _editEndAt   = DateTime(e2.year, e2.month, e2.day, 23, 59);
              }),
              onLocationChanged: (l) => setState(() => _editLocation = l),
              onAlarmModeChanged: (m) => setState(() => _alarmMode = m),
              onCustomAlarmTimeChanged: (t) => setState(() => _customAlarmTime = t),
              onSave: () => _saveEdit(event),
            );
          }

          return _EditBody(
            event: event,
            editTitle: _editTitle!,
            editColor: _editColor ?? event.color,
            editStartAt: _editStartAt ?? event.startAt,
            editEndAt: _editEndAt ?? event.endAt,
            isSaving: _isSaving,
            onTitleChanged: (t) => setState(() => _editTitle = t),
            onColorChanged: (c) => setState(() => _editColor = c),
            onStartChanged: (dt) => setState(() => _editStartAt = dt),
            onEndChanged: (dt) => setState(() => _editEndAt = dt),
            onSave: () => _saveEdit(event),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 구간 상세 편집 뷰
// ══════════════════════════════════════════════════════════════════════════════
class _RangeEditBody extends StatefulWidget {
  const _RangeEditBody({
    required this.event,
    required this.editTitle,
    required this.editColor,
    required this.editStartAt,
    required this.editEndAt,
    required this.editLocation,
    required this.alarmMode,
    required this.customAlarmTime,
    required this.isSaving,
    required this.onTitleChanged,
    required this.onColorChanged,
    required this.onRangeChanged,
    required this.onLocationChanged,
    required this.onAlarmModeChanged,
    required this.onCustomAlarmTimeChanged,
    required this.onSave,
  });

  final EventEntity event;
  final String editTitle;
  final String editColor;
  final DateTime editStartAt;
  final DateTime editEndAt;
  final String editLocation;
  final _AlarmMode alarmMode;
  final TimeOfDay customAlarmTime;
  final bool isSaving;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onColorChanged;
  final void Function(DateTime start, DateTime end) onRangeChanged;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<_AlarmMode> onAlarmModeChanged;
  final ValueChanged<TimeOfDay> onCustomAlarmTimeChanged;
  final VoidCallback onSave;

  @override
  State<_RangeEditBody> createState() => _RangeEditBodyState();
}

class _RangeEditBodyState extends State<_RangeEditBody> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _locationCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl    = TextEditingController(text: widget.editTitle);
    _locationCtrl = TextEditingController(text: widget.editLocation);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime dt) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return '${dt.month}월 ${dt.day}일 (${weekdays[dt.weekday % 7]})';
  }

  void _showAlarmPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            const Text('알림 설정',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...[
              (_AlarmMode.none, '없음'),
              (_AlarmMode.sameDay9am, '당일 오전 9시'),
              (_AlarmMode.thirtyMin, '30분 전'),
              (_AlarmMode.oneHour, '1시간 전'),
              (_AlarmMode.oneDay, '하루 전'),
            ].map((opt) => ListTile(
                  title: Text(opt.$2),
                  trailing: widget.alarmMode == opt.$1
                      ? const Icon(Icons.check, color: Color(0xFF7C6AFA))
                      : null,
                  onTap: () {
                    widget.onAlarmModeChanged(opt.$1);
                    Navigator.of(ctx).pop();
                  },
                )),
            ListTile(
              title: const Text('사용자화'),
              trailing: widget.alarmMode == _AlarmMode.custom
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.customAlarmTime.hour.toString().padLeft(2, '0')}:'
                          '${widget.customAlarmTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              color: Color(0xFF7C6AFA),
                              fontWeight: FontWeight.w600),
                        ),
                        const Icon(Icons.check, color: Color(0xFF7C6AFA)),
                      ],
                    )
                  : null,
              onTap: () async {
                final picked = await showTimePicker(
                  context: ctx,
                  initialTime: widget.customAlarmTime,
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.light(
                            primary: Color(0xFF7C6AFA))),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  widget.onAlarmModeChanged(_AlarmMode.custom);
                  widget.onCustomAlarmTimeChanged(picked);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = ColorPickerRow.fromHex(widget.editColor);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // ── 제목 ──────────────────────────────────────────────────────────
        TextField(
          controller: _titleCtrl,
          onChanged: widget.onTitleChanged,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            hintText: '구간 제목',
            hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const Divider(),
        const SizedBox(height: 16),

        // ── 기간 선택 (미니 캘린더) ───────────────────────────────────────
        const Text('기간 선택',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: MiniCalendarPicker(
            selectedStart: widget.editStartAt,
            selectedEnd: widget.editEndAt,
            onRangeSelected: widget.onRangeChanged,
          ),
        ),
        const SizedBox(height: 12),

        // ── 시작/종료 칩 ──────────────────────────────────────────────────
        Row(
          children: [
            Expanded(child: _DateChip(label: '시작', value: _fmtDate(widget.editStartAt))),
            const SizedBox(width: 8),
            Expanded(child: _DateChip(label: '종료', value: _fmtDate(widget.editEndAt))),
          ],
        ),
        const SizedBox(height: 20),

        // ── 컬러 ──────────────────────────────────────────────────────────
        const Text('컬러 설정',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ColorPickerRow(
          selected: widget.editColor,
          onChanged: widget.onColorChanged,
        ),
        const SizedBox(height: 20),

        // ── 장소 ──────────────────────────────────────────────────────────
        _RowTile(
          icon: Icons.location_on_outlined,
          child: TextField(
            controller: _locationCtrl,
            onChanged: widget.onLocationChanged,
            decoration: const InputDecoration(
              hintText: '장소를 입력하세요',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 4),

        // ── 알림 ──────────────────────────────────────────────────────────
        GestureDetector(
          onTap: _showAlarmPicker,
          child: _RowTile(
            icon: Icons.alarm_outlined,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _alarmLabel(widget.alarmMode, widget.customAlarmTime),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
              ],
            ),
            child: const Text('알림',
                style: TextStyle(fontSize: 14, color: Colors.black87)),
          ),
        ),
        const SizedBox(height: 32),

        // ── 저장 버튼 ─────────────────────────────────────────────────────
        ElevatedButton(
          onPressed: widget.isSaving ? null : widget.onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: widget.isSaving
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('저장', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 일정 상세 편집 뷰 (기존)
// ══════════════════════════════════════════════════════════════════════════════
class _EditBody extends StatefulWidget {
  const _EditBody({
    required this.event,
    required this.editTitle,
    required this.editColor,
    required this.editStartAt,
    required this.editEndAt,
    required this.isSaving,
    required this.onTitleChanged,
    required this.onColorChanged,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onSave,
  });

  final EventEntity event;
  final String editTitle;
  final String editColor;
  final DateTime editStartAt;
  final DateTime editEndAt;
  final bool isSaving;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime> onEndChanged;
  final VoidCallback onSave;

  @override
  State<_EditBody> createState() => _EditBodyState();
}

class _EditBodyState extends State<_EditBody> {
  late final TextEditingController _titleCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.editTitle);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final color = ColorPickerRow.fromHex(widget.editColor);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 제목
        const Text('제목',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleCtrl,
          onChanged: widget.onTitleChanged,
          decoration: InputDecoration(
            hintText: '일정 제목',
            filled: true,
            fillColor: const Color(0xFFF7F7FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF7C6AFA)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),

        // 컬러
        const Text('컬러',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 10),
        ColorPickerRow(
          selected: widget.editColor,
          onChanged: widget.onColorChanged,
        ),
        const SizedBox(height: 20),

        // 시작일
        const Text('시작일',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        _DateButton(
          value: widget.editStartAt,
          weekdays: weekdays,
          onChanged: widget.onStartChanged,
        ),
        const SizedBox(height: 16),

        // 종료일
        const Text('종료일',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        _DateButton(
          value: widget.editEndAt,
          weekdays: weekdays,
          onChanged: widget.onEndChanged,
        ),
        const SizedBox(height: 32),

        // 저장
        ElevatedButton(
          onPressed: widget.isSaving ? null : widget.onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C6AFA),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: widget.isSaving
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('저장'),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 공용 위젯
// ══════════════════════════════════════════════════════════════════════════════

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
                  fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.icon, required this.child, this.trailing});
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

// ══════════════════════════════════════════════════════════════════════════════
// 삭제 확인 다이얼로그
// ══════════════════════════════════════════════════════════════════════════════
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
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('삭제할까요?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '"$eventTitle"',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            const Text('삭제된 내용은 복구할 수 없습니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
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
