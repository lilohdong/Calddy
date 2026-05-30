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
  bool _isSaving = false;

  // 편집 상태 (항상 편집 모드)
  bool _initialized = false;
  String? _editTitle;
  String? _editColor;
  DateTime? _editStartAt;
  DateTime? _editEndAt;

  void _initEditOnce(EventEntity event) {
    if (_initialized) return;
    // setState 없이 초기값 세팅 — 최초 data 로드 시 단 한 번만 실행
    // build 외부(didChangeDependencies 등)로 옮기기 어려운 구조이므로
    // _initialized 플래그로 멱등성 보장
    _initialized = true;
    _editTitle = event.title;
    _editColor = event.color;
    _editStartAt = event.startAt;
    _editEndAt = event.endAt;
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
    if (title.isEmpty) {
      _showError('제목을 입력해주세요.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = original.copyWith(
        title: title,
        color: _editColor ?? original.color,
        startAt: _editStartAt ?? original.startAt,
        endAt: _editEndAt ?? original.endAt,
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
        title: const Text(
          '일정 상세',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          calendarAsync.when(
            loading: () => const SizedBox(),
            error: (_, e2) => const SizedBox(),
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
          _initEditOnce(event);
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

// ── 편집 뷰 (항상 표시) ──────────────────────────────────────────────────────
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
              borderSide: BorderSide(
                  color: color.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: color.withValues(alpha: 0.3)),
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
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('저장'),
        ),
      ],
    );
  }
}

// ── 공통 위젯 ────────────────────────────────────────────────────────────────
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
