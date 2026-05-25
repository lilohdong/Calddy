import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../providers/friend_providers.dart';

class MergeCalendarPage extends ConsumerWidget {
  const MergeCalendarPage({super.key, required this.friendId});

  final String friendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(mergeCalendarProvider(friendId));
    final suggestAsync = ref.watch(suggestedSlotProvider(friendId));

    return Scaffold(
      appBar: AppBar(title: const Text('합쳐 보기')),
      body: ListView(
        children: [
          // 추천 일정
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('추천 날짜', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          suggestAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ListTile(
              title: Text(e is FriendFailure ? e.message : '불러오기 실패'),
            ),
            data: (slot) => slot == null
                ? const ListTile(title: Text('30일 내 공통 빈 시간이 없습니다.'))
                : ListTile(
                    leading: const Icon(Icons.star_outline, color: Colors.orange),
                    title: Text(_fmtDate(slot.startAt)),
                    subtitle: Text(
                      '${_fmtTime(slot.startAt)} ~ ${_fmtTime(slot.endAt)}',
                    ),
                    trailing: TextButton(
                      onPressed: () => context.push(AppRoutes.appointmentCreate),
                      child: const Text('약속 잡기'),
                    ),
                  ),
          ),

          const Divider(),

          // 전체 빈 시간대
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('공통 빈 시간 전체', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          slotsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ListTile(
              title: Text(e is FriendFailure ? e.message : '불러오기 실패'),
            ),
            data: (slots) {
              if (slots.isEmpty) {
                return const ListTile(title: Text('공통 빈 시간이 없습니다.'));
              }
              return Column(
                children: slots
                    .map((s) => ListTile(
                          title: Text(_fmtDate(s.startAt)),
                          subtitle: Text(
                            '${_fmtTime(s.startAt)} ~ ${_fmtTime(s.endAt)}',
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) => '${dt.month}월 ${dt.day}일 (${_weekday(dt.weekday)})';
  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  String _weekday(int w) => ['월', '화', '수', '목', '금', '토', '일'][w - 1];
}
