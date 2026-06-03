import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/widgets/calddy_logo.dart';
import '../../domain/entities/friend_entity.dart';
import '../../domain/usecases/accept_friend_request_use_case.dart';
import '../../domain/usecases/delete_friend_use_case.dart';
import '../../domain/usecases/reject_friend_request_use_case.dart';
import '../providers/friend_providers.dart';
import '../widgets/friend_avatar_chip.dart';
import '../widgets/friend_card.dart';
import '../widgets/friend_request_card.dart';

class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage> {
  final _loadingIds = <String>{};
  String? _expandedFriendId;

  Future<void> _acceptRequest(String requestId) async {
    setState(() => _loadingIds.add(requestId));
    try {
      await ref
          .read(acceptFriendRequestUseCaseProvider)
          .call(AcceptFriendRequestParams(requestId: requestId));
      ref
        ..invalidate(incomingRequestsProvider)
        ..invalidate(friendsProvider(FriendSortType.freeTimeOverlap));
    } on FriendFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _loadingIds.remove(requestId));
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    setState(() => _loadingIds.add(requestId));
    try {
      await ref
          .read(rejectFriendRequestUseCaseProvider)
          .call(RejectFriendRequestParams(requestId: requestId));
      ref.invalidate(incomingRequestsProvider);
    } on FriendFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _loadingIds.remove(requestId));
    }
  }

  Future<void> _deleteFriend(String friendId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('친구 삭제'),
        content: const Text('정말 친구를 삭제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(deleteFriendUseCaseProvider)
          .call(DeleteFriendParams(friendId: friendId));
      ref.invalidate(friendsProvider(FriendSortType.freeTimeOverlap));
      if (mounted && _expandedFriendId == friendId) {
        setState(() => _expandedFriendId = null);
      }
    } on FriendFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('오류가 발생했습니다.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync =
        ref.watch(friendsProvider(FriendSortType.freeTimeOverlap));
    final requestsAsync = ref.watch(incomingRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '친구',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87, size: 26),
            onPressed: () => context.push(AppRoutes.friendSearch),
          ),
        ],
      ),
      body: friendsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e is FriendFailure ? e.message : '불러오기 실패'),
        ),
        data: (friends) {
          final requests = requestsAsync.valueOrNull ?? [];
          final requestsLoading = requestsAsync.isLoading;

          // 친구도 없고 요청도 없고 로딩도 아닐 때만 빈 화면
          if (friends.isEmpty && requests.isEmpty && !requestsLoading) {
            return _EmptyState(
              onAdd: () => context.push(AppRoutes.friendSearch),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref
                ..invalidate(incomingRequestsProvider)
                ..invalidate(friendsProvider(FriendSortType.freeTimeOverlap));
            },
            child: CustomScrollView(
              slivers: [
                // 상단 가로 스크롤 아바타 (친구 있을 때만)
                if (friends.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _AvatarScrollSection(friends: friends),
                  ),

                // 친구 요청 카드 (친구 유무 관계없이 항상 표시)
                SliverToBoxAdapter(
                  child: requests.isEmpty
                      ? const SizedBox()
                      : FriendRequestCard(
                          requests: requests,
                          loadingIds: _loadingIds,
                          onAccept: _acceptRequest,
                          onReject: _rejectRequest,
                        ),
                ),

                // 친구 카드 목록
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final f = friends[i];
                      return FriendCard(
                        friend: f,
                        isExpanded: _expandedFriendId == f.friendId,
                        rank: i,
                        onToggle: () => setState(() {
                          _expandedFriendId =
                              _expandedFriendId == f.friendId
                                  ? null
                                  : f.friendId;
                        }),
                        onDelete: () => _deleteFriend(f.friendId),
                      );
                    },
                    childCount: friends.length,
                  ),
                ),

                // 친구 없고 요청만 있을 때: 하단 안내 문구
                if (friends.isEmpty && requests.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.people_alt_outlined,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            '아직 친구가 없어요',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade400),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '위 요청을 수락하거나 직접 친구를 추가해보세요',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade400),
                          ),
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: () =>
                                context.push(AppRoutes.friendSearch),
                            icon: const Icon(Icons.person_add_outlined,
                                size: 18, color: Color(0xFF7C6AFA)),
                            label: const Text(
                              '친구 추가하기',
                              style: TextStyle(
                                  color: Color(0xFF7C6AFA),
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: friendsAsync.maybeWhen(
        data: (friends) => friends.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.push(AppRoutes.mergeCalendar),
                backgroundColor: const Color(0xFF7C6AFA),
                elevation: 3,
                icon: const CaldyLogo(size: 22),
                label: const Text(
                  '나와 합쳐보기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
        orElse: () => null,
      ),
    );
  }
}

class _AvatarScrollSection extends StatelessWidget {
  const _AvatarScrollSection({required this.friends});
  final List<FriendEntity> friends;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '나와 빈 시간이 많이 겹치는 순',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: friends
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: FriendAvatarChip(
                          friend: f,
                          showOverlapBadge: true,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FF),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.people_alt_outlined,
              size: 56,
              color: Color(0xFFB0A4F5),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            '아직 친구가 없어요',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '친구를 추가하고 일정을 공유해보세요!',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 36),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_outlined, size: 20),
            label: const Text('+ 친구 추가하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C6AFA),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
