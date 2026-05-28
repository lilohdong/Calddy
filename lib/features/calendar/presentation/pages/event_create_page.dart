import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/usecases/create_event_usecase.dart';
import '../providers/calendar_providers.dart';

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
  DateTime _endAt =
      DateTime.now().copyWith(second: 0, millisecond: 0).add(const Duration(hours: 1));
  String _color = '#7C6AFA';
  bool _isLoading = false;

  static const _colorOptions = [
    '#7C6AFA',
    '#FC8181',
    '#68D391',
    '#63B3ED',
    '#F6AD55',
    '#B794F4',
  ];

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
      final now = DateTime.now();
      await ref.read(createEventUseCaseProvider).call(
            CreateEventParams(
              event: EventEntity(
                id: '',
                userId: '',
                title: _titleCtrl.text.trim(),
                location: _locationCtrl.text.trim().isEmpty
                    ? null
                    : _locationCtrl.text.trim(),
                startAt: _startAt,
                endAt: _endAt,
                color: _color,
                isDday: false,
                memo: _memoCtrl.text.trim().isEmpty
                    ? null
                    : _memoCtrl.text.trim(),
                status: EventStatus.pending,
                visibility: EventVisibility.public,
                createdAt: now,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 만들기'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 제목
            const _Label('제목'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: '일정 이름을 입력하세요',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '제목을 입력해주세요' : null,
            ),
            const SizedBox(height: 20),

            // 시작
            const _Label('시작'),
            const SizedBox(height: 6),
            _DateTimePicker(
              value: _startAt,
              onChanged: (dt) => setState(() => _startAt = dt),
            ),
            const SizedBox(height: 16),

            // 종료
            const _Label('종료'),
            const SizedBox(height: 6),
            _DateTimePicker(
              value: _endAt,
              onChanged: (dt) => setState(() => _endAt = dt),
            ),
            const SizedBox(height: 20),

            // 색상
            const _Label('색상'),
            const SizedBox(height: 8),
            Row(
              children: _colorOptions.map((hex) {
                final c = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                final isSelected = _color == hex;
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
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
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 장소
            const _Label('장소 (선택)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                hintText: '장소를 입력하세요',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 메모
            const _Label('메모 (선택)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _memoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '메모를 입력하세요',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('일정 저장'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13));
}

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker({required this.value, required this.onChanged});
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
        onChanged(
            date.copyWith(hour: time.hour, minute: time.minute, second: 0));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
            const SizedBox(width: 10),
            Text(
              DateFormat('yyyy년 MM월 dd일  HH:mm').format(value),
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
