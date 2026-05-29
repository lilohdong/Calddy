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
  DateTime _endAt =
      DateTime.now().copyWith(second: 0, millisecond: 0).add(const Duration(hours: 1));
  String _color = '#7C6AFA';
  bool _isLoading = false;

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
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
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
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
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
                hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
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
                    onChanged: (dt) => setState(() => _startAt = dt),
                  ),
                  const SizedBox(height: 8),
                  _DateTimePicker(
                    label: '종료',
                    value: _endAt,
                    onChanged: (dt) => setState(() => _endAt = dt),
                  ),
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
            const SizedBox(height: 4),

            // 알림
            _SettingTile(
              icon: Icons.alarm_outlined,
              label: '알림 설정',
              trailing: const Text('09:00',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
            ),
            const SizedBox(height: 4),

            // 반복
            _SettingTile(
              icon: Icons.repeat_outlined,
              label: '반복 설정',
              trailing: const Text('없음',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
            ),
            const SizedBox(height: 4),

            // D-Day
            _SettingTile(
              icon: Icons.star_border_outlined,
              label: 'D-Day 설정',
              trailing: Switch(
                value: false,
                onChanged: (_) {},
                activeThumbColor: const Color(0xFF7C6AFA),
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
  });

  final IconData icon;
  final String? label;
  final Widget? child;
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
            Expanded(
              child: child ??
                  Text(label ?? '',
                      style: const TextStyle(fontSize: 14)),
            ),
            ?trailing,
          ],
        ),
      );
  }
}

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });
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
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
