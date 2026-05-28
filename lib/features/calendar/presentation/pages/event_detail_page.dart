import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/usecases/complete_event_usecase.dart';
import '../../domain/usecases/delete_event_usecase.dart';
import '../providers/calendar_providers.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  const EventDetailPage({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  bool _isDeleting = false;
  bool _isCompleting = false;

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('일정 삭제'),
        content: const Text('이 일정을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
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

  Future<void> _complete() async {
    setState(() => _isCompleting = true);
    try {
      await ref
          .read(completeEventUseCaseProvider)
          .call(CompleteEventParams(eventId: widget.eventId));
      ref.invalidate(calendarDataProvider);
      if (mounted) context.pop();
    } on CalendarFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('완료 처리에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isCompleting = false);
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
      appBar: AppBar(
        title: const Text('일정 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: (_isDeleting || _isCompleting) ? null : _delete,
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
          return _EventBody(
            event: event,
            isCompleting: _isCompleting,
            onComplete: event.status == EventStatus.done ? null : _complete,
          );
        },
      ),
    );
  }
}

class _EventBody extends StatelessWidget {
  const _EventBody({
    required this.event,
    required this.isCompleting,
    required this.onComplete,
  });

  final EventEntity event;
  final bool isCompleting;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    Color color;
    try {
      color = Color(int.parse(event.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      color = Colors.deepPurple;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 컬러 헤더 카드
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (event.memo != null) ...[
                const SizedBox(height: 8),
                Text(event.memo!,
                    style: const TextStyle(color: Colors.grey)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        _InfoRow(
          icon: Icons.access_time,
          label: '시작',
          value: _fmtDateTime(event.startAt),
        ),
        _InfoRow(
          icon: Icons.access_time_filled,
          label: '종료',
          value: _fmtDateTime(event.endAt),
        ),
        if (event.location != null)
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: '장소',
            value: event.location!,
          ),
        _InfoRow(
          icon: event.status == EventStatus.done
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          label: '상태',
          value: event.status == EventStatus.done ? '완료' : '예정',
          valueColor: event.status == EventStatus.done
              ? Colors.green
              : Colors.grey,
        ),
        const SizedBox(height: 32),

        if (onComplete != null)
          ElevatedButton.icon(
            onPressed: isCompleting ? null : onComplete,
            icon: isCompleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check),
            label: const Text('완료로 표시'),
          ),
      ],
    );
  }

  String _fmtDateTime(DateTime dt) =>
      DateFormat('yyyy년 MM월 dd일  HH:mm').format(dt);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 15,
                  color: valueColor,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
