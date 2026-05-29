import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../calendar/domain/entities/event_entity.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../friend/domain/entities/friend_entity.dart';
import '../../../friend/presentation/providers/friend_providers.dart';
import '../../domain/usecases/create_appointment_use_case.dart';
import '../providers/appointment_providers.dart';

class AppointmentCreatePage extends ConsumerStatefulWidget {
  const AppointmentCreatePage({super.key});

  @override
  ConsumerState<AppointmentCreatePage> createState() =>
      _AppointmentCreatePageState();
}

class _AppointmentCreatePageState
    extends ConsumerState<AppointmentCreatePage> {
  EventEntity? _selectedEvent;
  final Set<String> _selectedFriendIds = {};
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_selectedEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연결할 일정을 선택해주세요.')),
      );
      return;
    }
    if (_selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구를 1명 이상 선택해주세요.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(createAppointmentUseCaseProvider).call(
            CreateAppointmentParams(
              eventId: _selectedEvent!.id,
              inviteeIds: _selectedFriendIds.toList(),
            ),
          );
      if (mounted) context.pop();
    } on AppointmentFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('약속 만들기에 실패했습니다.');
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
    final calendarAsync = ref.watch(calendarDataProvider);
    final friendsAsync =
        ref.watch(friendsProvider(FriendSortType.alphabetical));

    return Scaffold(
      appBar: AppBar(
        title: const Text('약속 만들기'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('보내기'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 일정 선택
          const Text('연결할 일정',
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          calendarAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const Text('일정을 불러오지 못했습니다.'),
            data: (data) {
              if (data.events.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('등록된 일정이 없습니다.',
                      style: TextStyle(color: Colors.grey)),
                );
              }
              return Column(
                children: data.events.map((e) {
                  final isSelected = _selectedEvent?.id == e.id;
                  return RadioListTile<EventEntity>(
                    value: e,
                    groupValue: _selectedEvent,
                    onChanged: (v) => setState(() => _selectedEvent = v),
                    title: Text(e.title),
                    subtitle: Text(
                        '${e.startAt.month}/${e.startAt.day} ${_fmtTime(e.startAt)}'),
                    activeColor: Colors.deepPurple,
                    selected: isSelected,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // 친구 선택
          const Text('초대할 친구',
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          friendsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const Text('친구 목록을 불러오지 못했습니다.'),
            data: (friends) {
              if (friends.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('친구가 없습니다.',
                      style: TextStyle(color: Colors.grey)),
                );
              }
              return Column(
                children: friends.map((f) {
                  return CheckboxListTile(
                    value: _selectedFriendIds.contains(f.friendId),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedFriendIds.add(f.friendId);
                        } else {
                          _selectedFriendIds.remove(f.friendId);
                        }
                      });
                    },
                    title: Text(f.friendId),
                    activeColor: Colors.deepPurple,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: const Text('약속 보내기'),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
