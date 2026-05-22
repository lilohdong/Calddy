import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../providers/friend_providers.dart';

class FriendCalendarPage extends ConsumerWidget {
  const FriendCalendarPage({super.key, required this.friendId});

  final String friendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(friendCalendarProvider(friendId));

    return Scaffold(
      appBar: AppBar(title: const Text('친구 공개 일정')),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e is FriendFailure ? e.message : '불러오기 실패'),
        ),
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('이번 달 공개 일정이 없습니다.'));
          }
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (_, i) {
              final event = events[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _parseColor(event.color),
                  radius: 6,
                ),
                title: Text(event.title),
                subtitle: Text(
                  '${_fmt(event.startAt)} ~ ${_fmt(event.endAt)}',
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
