import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../friend/domain/entities/friend_entity.dart';
import '../../../friend/presentation/providers/friend_providers.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/location_input.dart';
import '../../domain/entities/midpoint_result_entity.dart';
import '../../domain/entities/place_entity.dart';
import '../providers/map_providers.dart';

class AiMidpointPage extends ConsumerStatefulWidget {
  const AiMidpointPage({
    super.key,
    this.friendId,
    this.friendIds,
    this.appointmentId,
  });

  /// 일반 태그: 단일 친구 ID
  final String? friendId;

  /// 합쳐보기: 다중 친구 ID 목록
  final List<String>? friendIds;

  /// 약속 ID — 제공 시 실제 백엔드 API 사용
  final String? appointmentId;

  @override
  ConsumerState<AiMidpointPage> createState() => _AiMidpointPageState();
}

class _AiMidpointPageState extends ConsumerState<AiMidpointPage> {
  // 0: 대기 중 (친구 응답 기다림), 1: 결과 표시
  int _step = 0;
  String _myLocation = '';
  String _friendLocation = '';
  bool _friendInputManually = false;
  String _calcBasis = '대중교통 최적화';
  int _selectedIndex = 0;

  /// 다중 친구 모드 여부
  bool get _isMulti =>
      widget.friendIds != null && widget.friendIds!.isNotEmpty;

  /// 계산하기 버튼 활성화 조건
  bool get _canCalculate {
    if (_myLocation.trim().isEmpty) return false;
    if (widget.appointmentId != null) return true; // 백엔드 모드: 내 위치만 있으면 됨
    if (_isMulti) return true; // 다중 친구 모드: 내 위치만 있으면 계산 (친구 입력 UI 미구현)
    return _friendInputManually && _friendLocation.trim().isNotEmpty;
  }

  static const _calcOptions = ['대중교통 최적화', '직선 거리', '도보 최적화'];

  @override
  Widget build(BuildContext context) {
    final allIds = _isMulti
        ? widget.friendIds!
        : (widget.friendId != null ? [widget.friendId!] : <String>[]);

    final friendsAsync = allIds.isNotEmpty
        ? ref.watch(friendsProvider(FriendSortType.alphabetical))
        : const AsyncValue<List<FriendEntity>>.data([]);

    // 단일 친구 (기존 호환)
    final FriendEntity? taggedFriend = _isMulti
        ? null
        : friendsAsync.maybeWhen(
            data: (list) => list
                .where((f) => f.friendId == widget.friendId)
                .firstOrNull,
            orElse: () => null,
          );

    // 다중 친구 목록
    final List<FriendEntity> taggedFriends = _isMulti
        ? friendsAsync.maybeWhen(
            data: (list) =>
                list.where((f) => allIds.contains(f.friendId)).toList(),
            orElse: () => [],
          )
        : [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7C6AFA).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('*AI',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7C6AFA),
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            const Text('중간지점 검색',
                style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
          ],
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: _step == 0
          ? (_isMulti
              ? _buildWaitingStepMulti(taggedFriends)
              : _buildWaitingStep(taggedFriend))
          : _buildResultStep(),
    );
  }

  // ── Step 0: 대기 화면 ──────────────────────────────────────────────
  Widget _buildWaitingStep(FriendEntity? friend) {
    final friendName = friend?.friendProfile.nickname ?? '친구';
    final friendAvatar = friend?.friendProfile.avatarUrl;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          // 친구 아바타
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C6AFA).withValues(alpha: 0.1),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C6AFA).withValues(alpha: 0.2),
                ),
              ),
              CircleAvatar(
                radius: 32,
                backgroundColor:
                    const Color(0xFF7C6AFA).withValues(alpha: 0.3),
                backgroundImage: friendAvatar != null
                    ? NetworkImage(friendAvatar)
                    : null,
                child: friendAvatar == null
                    ? Text(
                        friendName[0],
                        style: const TextStyle(
                            fontSize: 28,
                            color: Color(0xFF7C6AFA),
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '$friendName님에게 알림을 보냈어요',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '출발 장소 설정을 기다리고 있습니다...',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // 내 출발지 설정
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFF7C6AFA),
                      child: const Text('나',
                          style: TextStyle(
                              fontSize: 10, color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    const Text('내 출발 장소',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _myLocation = v),
                  decoration: InputDecoration(
                    hintText: '출발 장소를 입력하세요 (예: 강남역)',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF7C6AFA)),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        size: 18, color: Color(0xFF7C6AFA)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 친구 출발지 대기 / 직접 입력
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          const Color(0xFF7C6AFA).withValues(alpha: 0.2),
                      backgroundImage: friendAvatar != null
                          ? NetworkImage(friendAvatar)
                          : null,
                      child: friendAvatar == null
                          ? Text(
                              friendName[0],
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF7C6AFA),
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$friendName님의 출발 장소',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          const SizedBox(height: 2),
                          if (!_friendInputManually)
                            Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('설정 기다리는 중...',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade400)),
                              ],
                            )
                          else
                            Text(
                              _friendLocation.isEmpty
                                  ? '직접 입력 중...'
                                  : _friendLocation,
                              style: TextStyle(
                                fontSize: 12,
                                color: _friendLocation.isEmpty
                                    ? Colors.grey.shade400
                                    : Colors.black87,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // 내가 대신 입력하기 버튼
                    if (!_friendInputManually)
                      TextButton(
                        onPressed: () =>
                            setState(() => _friendInputManually = true),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF7C6AFA),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                        child: const Text('내가 대신\n입력하기',
                            textAlign: TextAlign.center),
                      ),
                  ],
                ),
                if (_friendInputManually) ...[
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => _friendLocation = v),
                    decoration: InputDecoration(
                      hintText:
                          '$friendName님의 출발 장소 입력 (예: 홍대입구역)',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF7C6AFA)),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      prefixIcon: const Icon(Icons.location_on_outlined,
                          size: 18, color: Color(0xFFFF9800)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),

          // 계산하기 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _canCalculate ? () => setState(() => _step = 1) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6AFA),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('중간지점 계산하기',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: Text('취소하기',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Step 0 (다중 친구): 대기 화면 ────────────────────────────────────
  static const _multiAvatarColors = [
    Color(0xFF7C6AFA),
    Color(0xFF5BB5E8),
    Color(0xFF6EC6B8),
    Color(0xFFF5A623),
    Color(0xFFF07DB3),
  ];

  Widget _buildWaitingStepMulti(List<FriendEntity> friends) {
    final names = friends.isEmpty
        ? '친구들'
        : friends.map((f) => f.friendProfile.nickname ?? '?').join(', ');

    const avatarColors = _multiAvatarColors;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          // 다중 친구 아바타 행
          if (friends.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: friends.asMap().entries.map((entry) {
                final i = entry.key;
                final f = entry.value;
                final name = f.friendProfile.nickname ?? '?';
                final color = avatarColors[i % avatarColors.length];
                final avatar = f.friendProfile.avatarUrl;
                return Transform.translate(
                  offset: Offset(i * -10.0, 0),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.25),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: color.withValues(alpha: 0.3),
                      backgroundImage:
                          avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null
                          ? Text(
                              name[0],
                              style: TextStyle(
                                fontSize: 20,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C6AFA).withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.people_alt_rounded,
                  size: 36, color: Color(0xFF7C6AFA)),
            ),

          const SizedBox(height: 20),
          Text(
            '$names님에게\n출발 장소 설정을 요청했어요',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '모두 설정하면 중간지점을 계산할게요',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // 내 출발지
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFF7C6AFA),
                      child: Text('나',
                          style:
                              TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                    SizedBox(width: 8),
                    Text('내 출발 장소',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _myLocation = v),
                  decoration: InputDecoration(
                    hintText: '출발 장소를 입력하세요 (예: 강남역)',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF7C6AFA)),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        size: 18, color: Color(0xFF7C6AFA)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 친구들 대기 상태
          ...friends.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            final name = f.friendProfile.nickname ?? '?';
            final color = avatarColors[i % avatarColors.length];
            final avatar = f.friendProfile.avatarUrl;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: color.withValues(alpha: 0.25),
                    backgroundImage:
                        avatar != null ? NetworkImage(avatar) : null,
                    child: avatar == null
                        ? Text(name[0],
                            style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$name님의 출발 장소',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            SizedBox(
                              width: 11,
                              height: 11,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('설정 기다리는 중...',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade400)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _canCalculate ? () => setState(() => _step = 1) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C6AFA),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('중간지점 계산하기',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: Text('취소하기',
                style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  /// 직접 입력 모드의 locations 빌드 (currentUser + 친구)
  List<LocationInput> _buildDirectLocations(
      String myNickname, String friendNickname) {
    final myId =
        Supabase.instance.client.auth.currentUser?.id ?? 'me';
    final friendId = widget.friendId ?? 'friend';
    return [
      LocationInput(userId: myId, nickname: myNickname, address: _myLocation),
      LocationInput(
          userId: friendId,
          nickname: friendNickname,
          address: _friendLocation),
    ];
  }

  // ── Step 1: 결과 화면 ──────────────────────────────────────────────
  Widget _buildResultStep() {
    // Mode A: appointmentId 있으면 기존 provider 사용
    if (widget.appointmentId != null) {
      return _buildRealResultStep(widget.appointmentId!);
    }
    // Mode B: 직접 입력 → 새 midpointDirectProvider 사용
    if (_myLocation.isNotEmpty && _friendLocation.isNotEmpty) {
      return _buildDirectResultStep();
    }
    return _buildMockResultStep();
  }

  /// Mode B 결과 화면 — midpointDirectProvider 사용
  Widget _buildDirectResultStep() {
    // 친구 정보 가져오기
    final friendsAsync =
        ref.watch(friendsProvider(FriendSortType.alphabetical));
    final friendNickname = friendsAsync.maybeWhen(
      data: (list) =>
          list
              .where((f) => f.friendId == widget.friendId)
              .firstOrNull
              ?.friendProfile
              .nickname ??
          '친구',
      orElse: () => '친구',
    );

    final myNickname =
        Supabase.instance.client.auth.currentUser?.email?.split('@').first ??
            '나';

    final locations = _buildDirectLocations(myNickname, friendNickname);
    // String 키 사용 — List는 참조 동등성이라 매 build마다 재시작됨
    final locationsKey = LocationInput.listToKey(locations);
    final midpointAsync = ref.watch(midpointDirectProvider(locationsKey));

    return midpointAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('중간지점 계산 중...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                  '중간지점을 계산할 수 없어요\n${e is MapFailure ? e.message : e.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _step = 0),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6AFA),
                    foregroundColor: Colors.white),
                child: const Text('다시 입력하기'),
              ),
            ],
          ),
        ),
      ),
      data: (midpoint) {
        final recommendAsync = ref.watch(recommendPlaceProvider(midpoint));
        return recommendAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('장소 추천 중...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('장소 추천을 불러오지 못했어요',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _step = 0),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C6AFA),
                        foregroundColor: Colors.white),
                    child: const Text('다시 입력하기'),
                  ),
                ],
              ),
            ),
          ),
          data: (recommendation) => _buildResultContent(
            midpoint: midpoint,
            places: recommendation.places,
          ),
        );
      },
    );
  }

  /// 백엔드 연동 결과 화면 (appointmentId 있을 때)
  Widget _buildRealResultStep(String appointmentId) {
    final midpointAsync = ref.watch(midpointProvider(appointmentId));

    return midpointAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                  '중간지점을 계산할 수 없어요\n${e is MapFailure ? e.message : e.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _step = 0),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      ),
      data: (midpoint) {
        final recommendAsync = ref.watch(recommendPlaceProvider(midpoint));
        return recommendAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('장소 추천을 불러오지 못했어요',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _step = 0),
                    child: const Text('돌아가기'),
                  ),
                ],
              ),
            ),
          ),
          data: (recommendation) => _buildResultContent(
            midpoint: midpoint,
            places: recommendation.places,
          ),
        );
      },
    );
  }

  Widget _buildResultContent({
    required MidpointResultEntity midpoint,
    required List<PlaceEntity> places,
  }) {
    return Column(
      children: [
        // 네이버 지도
        SizedBox(
          height: 200,
          child: NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(midpoint.lat, midpoint.lng),
                zoom: 13,
              ),
            ),
            onMapReady: (controller) {
              // 중간지점 마커
              controller.addOverlay(NMarker(
                id: 'midpoint',
                position: NLatLng(midpoint.lat, midpoint.lng),
                caption: const NOverlayCaption(text: 'AI 추천 중간지점'),
              ));
              // 추천 장소 마커
              for (int i = 0; i < places.length && i < 3; i++) {
                final p = places[i];
                controller.addOverlay(NMarker(
                  id: 'place_$i',
                  position: NLatLng(p.lat, p.lng),
                  caption: NOverlayCaption(text: '${i + 1}. ${p.name}'),
                ));
              }
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 참여자 이동 시간
              if (midpoint.participants.isNotEmpty) ...[
                const Text('참여자 예상 이동 시간',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: midpoint.participants.map((p) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EEFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${p.nickname} · ${p.travelMinutes ?? '?'}분',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5B50D6)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              const Text('추천 중간지점',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              ...places.asMap().entries.map((e) {
                final i = e.key;
                final p = e.value;
                final isSelected = _selectedIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: _PlaceTile(
                    rank: i + 1,
                    name: p.name,
                    address: p.address,
                    distance: p.distanceFromMidpoint,
                    isSelected: isSelected,
                  ),
                );
              }),
              const SizedBox(height: 16),
              _ActionButtons(
                onPrev: () => setState(() => _step = 0),
                onConfirm: places.isEmpty
                    ? null
                    : () => context.pop(places[_selectedIndex].name),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Mock 결과 화면 (appointmentId 없을 때)
  Widget _buildMockResultStep() {
    final mockPlaces = [
      _MockPlace(rank: 1, name: '고속터미널역', sub: '3, 7, 9호선 · 평균 30분'),
      _MockPlace(rank: 2, name: '강남구청역', sub: '7호선 · 평균 32분'),
      _MockPlace(rank: 3, name: '신논현역', sub: '9호선 · 평균 35분'),
    ];

    return Column(
      children: [
        // 지도 플레이스홀더
        Container(
          height: 180,
          color: const Color(0xFFE8F0FE),
          child: Stack(
            children: [
              const Center(
                  child: Text('🗺️', style: TextStyle(fontSize: 60))),
              Positioned(
                left: 60,
                bottom: 50,
                child: _MapPin(
                    label: '나·${_myLocation.isEmpty ? '내 위치' : _myLocation}',
                    color: const Color(0xFF7C6AFA)),
              ),
              Positioned(
                right: 60,
                top: 40,
                child: _MapPin(
                    label: '친구·${_friendLocation.isEmpty ? '출발지' : _friendLocation}',
                    color: const Color(0xFFFF9800)),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C6AFA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('+ AI 추천 중간지점',
                      style: TextStyle(
                          color: Colors.white, fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('계산 기준',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _calcOptions.map((opt) {
                    final isSelected = _calcBasis == opt;
                    return GestureDetector(
                      onTap: () => setState(() => _calcBasis = opt),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF7C6AFA)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(opt,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('추천 중간지점',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              ...mockPlaces.asMap().entries.map((e) {
                final i = e.key;
                final p = e.value;
                final isSelected = _selectedIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: _PlaceTile(
                    rank: p.rank,
                    name: p.name,
                    address: p.sub,
                    isSelected: isSelected,
                  ),
                );
              }),
              const SizedBox(height: 16),
              _ActionButtons(
                onPrev: () => setState(() => _step = 0),
                onConfirm: () =>
                    context.pop(mockPlaces[_selectedIndex].name),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MockPlace {
  const _MockPlace({required this.rank, required this.name, required this.sub});
  final int rank;
  final String name;
  final String sub;
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({
    required this.rank,
    required this.name,
    required this.address,
    required this.isSelected,
    this.distance,
  });
  final int rank;
  final String name;
  final String address;
  final bool isSelected;
  final double? distance;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF7C6AFA).withValues(alpha: 0.08)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: const Color(0xFF7C6AFA), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF7C6AFA)
                  : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$rank',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                if (distance != null)
                  Text('중간지점에서 ${distance!.toStringAsFixed(0)}m',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey))
                else
                  Text(address,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onPrev, required this.onConfirm});
  final VoidCallback onPrev;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onPrev,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('이전으로',
                style: TextStyle(color: Colors.black87)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C6AFA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('이 장소로 설정'),
          ),
        ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 10)),
        ),
        Container(width: 2, height: 10, color: color),
      ],
    );
  }
}
