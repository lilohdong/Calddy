import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/usecases/create_event_usecase.dart';
import '../providers/calendar_providers.dart';
import '../widgets/color_picker_row.dart';

class EventCreatePage extends ConsumerStatefulWidget {
  const EventCreatePage({super.key});

  @override
  ConsumerState<EventCreatePage> createState() => _EventCreatePageState();
}

class _EventCreatePageState extends ConsumerState<EventCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  DateTime _startAt = DateTime.now().copyWith(second: 0, millisecond: 0);
  DateTime _endAt = DateTime.now()
      .copyWith(second: 0, millisecond: 0)
      .add(const Duration(hours: 1));
  String _color = '#7C6AFA';
  bool _isLoading = false;
  bool _isDday = false;
  int? _notifyBeforeMin = 60;
  RecurrenceType? _recurrenceType;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final currentUserId =
          Supabase.instance.client.auth.currentUser?.id ?? '';
      final now = DateTime.now();
      await ref.read(createEventUseCaseProvider).call(
            CreateEventParams(
              event: EventEntity(
                id: '',
                userId: currentUserId,
                title: _titleCtrl.text.trim(),
                location: _locationCtrl.text.trim().isEmpty
                    ? null
                    : _locationCtrl.text.trim(),
                startAt: _startAt,
                endAt: _endAt,
                color: _color,
                isDday: _isDday,
                memo: _memoCtrl.text.trim().isEmpty
                    ? null
                    : _memoCtrl.text.trim(),
                notifyBeforeMin: _notifyBeforeMin,
                status: EventStatus.pending,
                visibility: EventVisibility.public,
                createdAt: now,
                recurrenceType: _recurrenceType,
              ),
            ),
          );
      ref.invalidate(calendarDataProvider);
      if (mounted) context.pop();
    } on CalendarFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('일정을 만드는 데 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showAlarmPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        const options = [
          (label: '없음', minutes: null as int?),
          (label: '5분 전', minutes: 5 as int?),
          (label: '15분 전', minutes: 15 as int?),
          (label: '30분 전', minutes: 30 as int?),
          (label: '1시간 전', minutes: 60 as int?),
          (label: '1일 전', minutes: 1440 as int?),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text('알림 설정',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...options.map((opt) => ListTile(
                    title: Text(opt.label),
                    trailing: _notifyBeforeMin == opt.minutes
                        ? const Icon(Icons.check, color: Color(0xFF7C6AFA))
                        : null,
                    onTap: () {
                      setState(() => _notifyBeforeMin = opt.minutes);
                      Navigator.of(context).pop();
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showRepeatPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final options = [
          (label: '없음', type: null as RecurrenceType?),
          (label: '매일', type: RecurrenceType.daily as RecurrenceType?),
          (label: '매주', type: RecurrenceType.weekly as RecurrenceType?),
          (label: '매월', type: RecurrenceType.monthly as RecurrenceType?),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text('반복 설정',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...options.map((opt) => ListTile(
                    title: Text(opt.label),
                    trailing: _recurrenceType == opt.type
                        ? const Icon(Icons.check, color: Color(0xFF7C6AFA))
                        : null,
                    onTap: () {
                      setState(() => _recurrenceType = opt.type);
                      Navigator.of(context).pop();
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _alarmLabel() {
    if (_notifyBeforeMin == null) return '없음';
    if (_notifyBeforeMin == 5) return '5분 전';
    if (_notifyBeforeMin == 15) return '15분 전';
    if (_notifyBeforeMin == 30) return '30분 전';
    if (_notifyBeforeMin == 60) return '1시간 전';
    if (_notifyBeforeMin == 1440) return '1일 전';
    return '$_notifyBeforeMin분 전';
  }

  String _repeatLabel() {
    switch (_recurrenceType) {
      case RecurrenceType.daily:
        return '매일';
      case RecurrenceType.weekly:
        return '매주';
      case RecurrenceType.monthly:
        return '매월';
      case null:
        return '없음';
    }
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
        title: const Text('일정 추가',
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
                hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '제목을 입력해주세요' : null,
            ),
            const Divider(),
            const SizedBox(height: 12),

            // 컬러
            const _Label('컬러 설정'),
            const SizedBox(height: 10),
            ColorPickerRow(
              selected: _color,
              onChanged: (hex) => setState(() => _color = hex),
            ),
            const SizedBox(height: 16),

            // 시작/종료
            _SettingCard(
              icon: Icons.access_time_outlined,
              child: Column(
                children: [
                  _DateTimeRow(
                    label: '시작',
                    value: _startAt,
                    onChanged: (dt) => setState(() {
                      _startAt = dt;
                      if (_endAt.isBefore(_startAt)) {
                        _endAt = _startAt.add(const Duration(hours: 1));
                      }
                    }),
                  ),
                  const Divider(height: 16),
                  _DateTimeRow(
                    label: '종료',
                    value: _endAt,
                    onChanged: (dt) => setState(() => _endAt = dt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 장소
            _SettingCard(
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
                    onPressed: () => context.push(AppRoutes.aiMidpoint),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF7C6AFA).withValues(alpha: 0.1),
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
            const SizedBox(height: 8),

            // 알림
            _SettingCard(
              icon: Icons.alarm_outlined,
              onTap: _showAlarmPicker,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('알림', style: TextStyle(fontSize: 14)),
                  Text(_alarmLabel(),
                      style:
                          const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 반복
            _SettingCard(
              icon: Icons.repeat_outlined,
              onTap: _showRepeatPicker,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('반복', style: TextStyle(fontSize: 14)),
                  Text(_repeatLabel(),
                      style:
                          const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // D-Day
            _SettingCard(
              icon: Icons.star_border_outlined,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('D-Day 설정', style: TextStyle(fontSize: 14)),
                  Switch(
                    value: _isDday,
                    onChanged: (v) => setState(() => _isDday = v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF7C6AFA),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 메모
            _SettingCard(
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── 공통 헬퍼 위젯 ──────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
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

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.child,
    this.onTap,
  });

  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(child: child),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final dateStr =
        '${value.year}년 ${value.month}월 ${value.day}일 (${weekdays[value.weekday % 7]})';
    final timeStr =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF7C6AFA),
              ),
            ),
            child: child!,
          ),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF7C6AFA),
              ),
            ),
            child: child!,
          ),
        );
        if (time == null) return;
        onChanged(
            date.copyWith(hour: time.hour, minute: time.minute, second: 0));
      },
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Text(dateStr, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7C6AFA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(timeStr,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7C6AFA),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
