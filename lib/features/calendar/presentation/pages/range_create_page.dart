import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
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
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return '${dt.month}월 ${dt.day}일 (${weekdays[dt.weekday % 7]})';
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
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
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
                        color: Color(0xFF7C6AFA), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // 제목
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              hintText: '제목 (예: 제주도 여행 ✈)',
              hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const Divider(),
          const SizedBox(height: 16),

          // 기간 선택
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
              selectedStart: _startDate,
              selectedEnd: _endDate,
              onRangeSelected: (s, e) => setState(() {
                _startDate = s;
                _endDate = e;
              }),
            ),
          ),
          const SizedBox(height: 16),

          // 시작/종료 칩
          Row(
            children: [
              Expanded(child: _DateChip(label: '시작', value: _fmtDate(_startDate))),
              const SizedBox(width: 8),
              Expanded(child: _DateChip(label: '종료', value: _fmtDate(_endDate))),
            ],
          ),
          const SizedBox(height: 20),

          // 컬러
          const Text('컬러 설정',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.aiMidpoint),
                  style: TextButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF7C6AFA).withValues(alpha: 0.1),
                    foregroundColor: const Color(0xFF7C6AFA),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    textStyle: const TextStyle(fontSize: 12),
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
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          const SizedBox(height: 4),

          // 알림
          _RowTile(
            icon: Icons.alarm_outlined,
            trailing: const Text('09:00',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            child: const Text('알림 시간',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
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
                  fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
          ?trailing,
        ],
      ),
    );
  }
}
