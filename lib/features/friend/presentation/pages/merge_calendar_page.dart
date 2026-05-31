import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/free_slot_entity.dart';
import '../../domain/entities/friend_calendar_event_entity.dart';
import '../../domain/entities/friend_entity.dart';
import '../providers/friend_providers.dart';

class MergeCalendarPage extends ConsumerStatefulWidget {
  const MergeCalendarPage({super.key});

  @override
  ConsumerState<MergeCalendarPage> createState() => _MergeCalendarPageState();
}

class _MergeCalendarPageState extends ConsumerState<MergeCalendarPage> {
  final Set<String> _selectedIds = {};
  DateTime _current = DateTime(DateTime.now().year, DateTime.now().month);
  int? _recommendedDay;
  bool _autoNavigated = false; // 빈 날짜 달로 자동 이동 여부

  static const _palette = [
    Color(0xFF5BB5E8),
    Color(0xFF6EC6B8),
    Color(0xFFF5A623),
    Color(0xFFF07DB3),
    Color(0xFFB0A4F5),
  ];

  Color _friendColor(int index) => _palette[index % _palette.length];

  @override
  Widget build(BuildContext context) {
    final friendsAsync =
        ref.watch(friendsProvider(FriendSortType.freeTimeOverlap));

    // 내 유저 ID
    final myId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.black87,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '친구와 일정 합치기',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: friendsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(e is FriendFailure ? e.message : '불러오기 실패')),
        data: (friends) {
          final indexedFriends = friends.asMap().entries.toList();
          final selectedIndexed = indexedFriends
              .where((e) => _selectedIds.contains(e.value.friendId))
              .toList();

          final friendIdsKey = _selectedIds.join(',');
          final slotsAsync = _selectedIds.isNotEmpty
              ? ref.watch(mergeCalendarProvider(friendIdsKey))
              : const AsyncValue<List<FreeSlotEntity>>.data([]);

          // ── 내 공개 일정 ──────────────────────────────────────
          List<FriendCalendarEventEntity> myEvents = [];
          if (myId != null) {
            ref.watch(friendCalendarProvider(myId)).whenData(
              (evs) => myEvents = evs,
            );
          }

          // ── 친구 공개 일정 ────────────────────────────────────
          final Map<String, List<FriendCalendarEventEntity>> friendEvents = {};
          for (final entry in indexedFriends) {
            ref.watch(friendCalendarProvider(entry.value.friendId)).whenData(
              (evs) => friendEvents[entry.value.friendId] = evs,
            );
          }

          // ── 빈 날짜 계산 — 슬롯 범위 내 모든 날짜 추가 ──────
          final freeDays = <int>{};
          slotsAsync.whenData((slots) {
            for (final s in slots) {
              var d = DateTime(
                  s.startAt.year, s.startAt.month, s.startAt.day);
              final endDay =
                  DateTime(s.endAt.year, s.endAt.month, s.endAt.day);
              while (!d.isAfter(endDay)) {
                if (d.year == _current.year && d.month == _current.month) {
                  freeDays.add(d.day);
                }
                d = d.add(const Duration(days: 1));
              }
            }

            // 현재 달에 빈 날짜가 없으면 첫 번째 빈 날짜 달로 자동 이동
            if (freeDays.isEmpty && slots.isNotEmpty && !_autoNavigated) {
              final firstSlot = slots.first;
              final targetMonth = DateTime(
                  firstSlot.startAt.year, firstSlot.startAt.month);
              if (targetMonth != _current) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _current = targetMonth;
                      _autoNavigated = true;
                    });
                  }
                });
              }
            }

            // 추천 날짜: 빈 날짜 중 랜덤 1개 (미설정 시에만)
            if (freeDays.isNotEmpty && _recommendedDay == null) {
              final list = freeDays.toList();
              final pick = list[Random().nextInt(list.length)];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _recommendedDay = pick);
              });
            }
          });

          final selectedCount = _selectedIds.length;

          return Column(
            children: [
              // 상단 친구 선택 + 범례 (고정 높이)
              Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Text(
                        selectedCount == 0
                            ? '친구를 선택해주세요'
                            : '$selectedCount명을 선택했어요',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selectedCount == 0
                              ? Colors.grey.shade400
                              : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 88,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: friends.length,
                        itemBuilder: (_, idx) {
                          final f = friends[idx];
                          final isSelected =
                              _selectedIds.contains(f.friendId);
                          final nickname = f.friendProfile.nickname ?? '?';
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                if (isSelected) {
                                  _selectedIds.remove(f.friendId);
                                } else {
                                  _selectedIds.add(f.friendId);
                                }
                                _recommendedDay = null;
                                _autoNavigated = false;
                              }),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? const Color(0xFFEDE9FF)
                                          : Colors.grey.shade100,
                                      border: isSelected
                                          ? Border.all(
                                              color: const Color(0xFF7C6AFA),
                                              width: 2.5,
                                            )
                                          : Border.all(
                                              color: Colors.grey.shade300,
                                              width: 1,
                                            ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        nickname.isNotEmpty
                                            ? nickname[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFF7C6AFA)
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    nickname.length > 5
                                        ? '${nickname.substring(0, 5)}…'
                                        : nickname,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected
                                          ? const Color(0xFF7C6AFA)
                                          : Colors.grey.shade500,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 범례 (고정 높이)
                    SizedBox(
                      height: 36,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _LegendDot(
                              color: const Color(0xFF7C6AFA),
                              label: '내 일정',
                            ),
                            ...selectedIndexed.map((e) => Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: _LegendDot(
                                    color: _friendColor(e.key),
                                    label:
                                        e.value.friendProfile.nickname ?? '',
                                  ),
                                )),
                            const SizedBox(width: 16),
                            _LegendDot(
                              color: const Color(0xFF8CC98A),
                              label: '모두 비어있음',
                              isOutlined: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // 달력
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _MergeCalendarGrid(
                          current: _current,
                          onMonthChanged: (d) => setState(() {
                            _current = d;
                            _recommendedDay = null;
                            _autoNavigated = false;
                          }),
                          freeDays: freeDays,
                          recommendedDay: _recommendedDay,
                          myEvents: myEvents,
                          selectedFriends: selectedIndexed
                              .map((e) => (
                                    friend: e.value,
                                    color: _friendColor(e.key),
                                    events:
                                        friendEvents[e.value.friendId] ?? [],
                                  ))
                              .toList(),
                          onSelectDay: (d) =>
                              setState(() => _recommendedDay = d),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Text(
                          '· 모두 비어있는 날은 연두색으로 표시돼요!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.friends),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6AFA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('확인 완료'),
            ),
          ),
        ),
      ),
    );
  }
}

typedef _FriendSlot = ({
  FriendEntity friend,
  Color color,
  List<FriendCalendarEventEntity> events,
});

class _MergeCalendarGrid extends StatelessWidget {
  const _MergeCalendarGrid({
    required this.current,
    required this.onMonthChanged,
    required this.freeDays,
    required this.recommendedDay,
    required this.myEvents,
    required this.selectedFriends,
    required this.onSelectDay,
  });

  final DateTime current;
  final void Function(DateTime) onMonthChanged;
  final Set<int> freeDays;
  final int? recommendedDay;
  final List<FriendCalendarEventEntity> myEvents;
  final List<_FriendSlot> selectedFriends;
  final void Function(int) onSelectDay;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(current.year, current.month);
    final firstWeekday =
        DateTime(current.year, current.month, 1).weekday % 7;
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final now = DateTime.now();

    // 이벤트 맵: day → list of (color, title)
    final Map<int, List<({Color color, String title})>> eventMap = {};

    // 내 일정 (보라색)
    for (final e in myEvents) {
      if (e.startAt.year == current.year && e.startAt.month == current.month) {
        eventMap
            .putIfAbsent(e.startAt.day, () => [])
            .add((color: const Color(0xFF7C6AFA), title: e.title));
      }
    }

    // 친구 일정
    for (final fw in selectedFriends) {
      for (final e in fw.events) {
        if (e.startAt.year == current.year &&
            e.startAt.month == current.month) {
          eventMap
              .putIfAbsent(e.startAt.day, () => [])
              .add((color: fw.color, title: e.title));
        }
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () =>
                  onMonthChanged(DateTime(current.year, current.month - 1)),
              child: const Icon(Icons.chevron_left,
                  size: 24, color: Colors.grey),
            ),
            Text(
              '${current.year}년 ${current.month}월 ▾',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16),
            ),
            GestureDetector(
              onTap: () =>
                  onMonthChanged(DateTime(current.year, current.month + 1)),
              child: const Icon(Icons.chevron_right,
                  size: 24, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: weekdays
              .asMap()
              .entries
              .map((e) => Expanded(
                    child: Center(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: e.key == 0
                              ? Colors.red.shade300
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.65,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (_, i) {
            if (i < firstWeekday) return const SizedBox();
            final day = i - firstWeekday + 1;
            final isToday = now.year == current.year &&
                now.month == current.month &&
                now.day == day;
            final isFree = freeDays.contains(day);
            final isRecommended = recommendedDay == day;
            final dayEvents = eventMap[day] ?? [];
            final isSunday = (i % 7) == 0;

            return GestureDetector(
              onTap: isFree ? () => onSelectDay(day) : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      color: isFree
                          ? const Color(0xFFDCF0DA)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: isRecommended
                          ? Border.all(
                              color: const Color(0xFF7C6AFA), width: 1.5)
                          : null,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 3),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: isToday
                              ? const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF7C6AFA),
                                )
                              : null,
                          child: Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isToday
                                    ? Colors.white
                                    : isSunday
                                        ? Colors.red.shade300
                                        : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        if (dayEvents.isNotEmpty)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                children: dayEvents
                                    .take(2)
                                    .map((e) => Container(
                                          margin:
                                              const EdgeInsets.only(top: 1),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: e.color.withOpacity(0.22),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            e.title,
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: e.color,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                      ],
                    ),
                  ),
                  if (isRecommended)
                    Positioned(
                      bottom: -38,
                      left: -28,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add,
                                  size: 12, color: Color(0xFF7C6AFA)),
                              SizedBox(width: 4),
                              Text(
                                '이 날짜는 어떠세요?',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.isOutlined = false,
  });

  final Color color;
  final String label;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOutlined ? const Color(0xFFDCF0DA) : color,
            border:
                isOutlined ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}
