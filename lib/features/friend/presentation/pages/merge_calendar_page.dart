import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/free_slot_entity.dart';
import '../../domain/entities/friend_calendar_event_entity.dart';
import '../../domain/entities/friend_entity.dart';
import '../providers/friend_providers.dart';
import '../widgets/friend_avatar_chip.dart';

class MergeCalendarPage extends ConsumerStatefulWidget {
  const MergeCalendarPage({super.key});

  @override
  ConsumerState<MergeCalendarPage> createState() => _MergeCalendarPageState();
}

class _MergeCalendarPageState extends ConsumerState<MergeCalendarPage> {
  final Set<String> _selectedIds = {};
  bool _initialised = false;
  DateTime _current = DateTime(DateTime.now().year, DateTime.now().month);
  int? _recommendedDay;

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
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
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.friends),
            child: const Text(
              '완료',
              style: TextStyle(
                color: Color(0xFF7C6AFA),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: friendsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(e is FriendFailure ? e.message : '불러오기 실패')),
        data: (friends) {
          // 첫 진입 시 전체 친구 선택
          if (!_initialised && friends.isNotEmpty) {
            _initialised = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(
                () => _selectedIds.addAll(friends.map((f) => f.friendId)),
              );
            });
          }

          final indexedFriends = friends.asMap().entries.toList();
          final selectedIndexed = indexedFriends
              .where((e) => _selectedIds.contains(e.value.friendId))
              .toList();

          final friendIdsKey = _selectedIds.join(',');
          final slotsAsync = _selectedIds.isNotEmpty
              ? ref.watch(mergeCalendarProvider(friendIdsKey))
              : const AsyncValue<List<FreeSlotEntity>>.data([]);

          // 각 친구의 공개 일정
          final Map<String, List<FriendCalendarEventEntity>> friendEvents = {};
          for (final entry in indexedFriends) {
            ref.watch(friendCalendarProvider(entry.value.friendId)).whenData(
                  (evs) => friendEvents[entry.value.friendId] = evs,
                );
          }

          // 빈 날짜 계산
          final freeDays = <int>{};
          slotsAsync.whenData((slots) {
            for (final s in slots) {
              if (s.startAt.year == _current.year &&
                  s.startAt.month == _current.month) {
                freeDays.add(s.startAt.day);
              }
            }
            if (freeDays.isNotEmpty && _recommendedDay == null) {
              final sorted = freeDays.toList()..sort();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _recommendedDay = sorted.first);
              });
            }
          });

          return Column(
            children: [
              // 상단: 친구 선택 + 범례
              Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Text(
                        '${_selectedIds.length}명을 선택했어요',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 친구 선택 스크롤
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: friends.map((f) {
                          final isSelected = _selectedIds.contains(f.friendId);
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
                              }),
                              child: Opacity(
                                opacity: isSelected ? 1.0 : 0.4,
                                child: FriendAvatarChip(
                                  friend: f,
                                  isSelected: isSelected,
                                  showOverlapBadge: false,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // 범례
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          _LegendDot(
                            color: const Color(0xFF7C6AFA),
                            label: '내 일정',
                          ),
                          ...selectedIndexed.map((e) => _LegendDot(
                                color: _friendColor(e.key),
                                label:
                                    e.value.friendProfile.nickname ?? '',
                              )),
                          _LegendDot(
                            color: const Color(0xFF8CC98A),
                            label: '모두 비어있음',
                            isOutlined: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 달력 + 하단 버튼
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 달력 카드
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
                          }),
                          freeDays: freeDays,
                          recommendedDay: _recommendedDay,
                          selectedFriends: selectedIndexed
                              .map((e) => (
                                    friend: e.value,
                                    color: _friendColor(e.key),
                                    events: friendEvents[e.value.friendId] ?? [],
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
    required this.selectedFriends,
    required this.onSelectDay,
  });

  final DateTime current;
  final void Function(DateTime) onMonthChanged;
  final Set<int> freeDays;
  final int? recommendedDay;
  final List<_FriendSlot> selectedFriends;
  final void Function(int) onSelectDay;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(current.year, current.month);
    final firstWeekday = DateTime(current.year, current.month, 1).weekday % 7;
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final now = DateTime.now();

    // 이벤트 맵: day → list of (color, title)
    final Map<int, List<({Color color, String title})>> eventMap = {};
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
        // 월 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () =>
                  onMonthChanged(DateTime(current.year, current.month - 1)),
              child: const Icon(Icons.chevron_left, size: 24, color: Colors.grey),
            ),
            Text(
              '${current.year}년 ${current.month}월 ▾',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            GestureDetector(
              onTap: () =>
                  onMonthChanged(DateTime(current.year, current.month + 1)),
              child:
                  const Icon(Icons.chevron_right, size: 24, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 요일 헤더
        Row(
          children: weekdays.asMap().entries.map((e) => Expanded(
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
          )).toList(),
        ),
        const SizedBox(height: 6),
        // 날짜 그리드
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
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                children: dayEvents.take(2).map((e) => Container(
                                  margin: const EdgeInsets.only(top: 1),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: e.color.withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(3),
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
                                )).toList(),
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                      ],
                    ),
                  ),
                  // 추천 날짜 툴팁
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 12,
                                  color: Color(0xFF7C6AFA)),
                              const SizedBox(width: 4),
                              const Text(
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
