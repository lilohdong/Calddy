import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/friend_entity.dart';
import '../../domain/entities/searched_user_entity.dart';
import '../../domain/usecases/accept_friend_request_use_case.dart';
import '../../domain/usecases/cancel_friend_request_use_case.dart';
import '../../domain/usecases/delete_friend_use_case.dart';
import '../../domain/usecases/reject_friend_request_use_case.dart';
import '../../domain/usecases/search_users_use_case.dart';
import '../../domain/usecases/send_friend_request_use_case.dart';
import '../providers/friend_providers.dart';
import '../widgets/friend_list_tile.dart';
import '../widgets/friend_request_tile.dart';
import '../widgets/search_result_tile.dart';

class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String _query = '';
  AsyncValue<List<SearchedUserEntity>> _searchResults = const AsyncValue.data([]);
  final _loadingIds = <String>{};
  FriendSortType _sortType = FriendSortType.alphabetical;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() { _query = ''; _searchResults = const AsyncValue.data([]); });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() { _query = query; _searchResults = const AsyncValue.loading(); });
    try {
      final results = await ref.read(searchUsersUseCaseProvider)
          .call(SearchUsersParams(query: query));
      if (mounted) setState(() => _searchResults = AsyncValue.data(results));
    } catch (e, st) {
      if (mounted) setState(() => _searchResults = AsyncValue.error(e, st));
    }
  }

  Future<void> _sendRequest(String addresseeId) async {
    setState(() => _loadingIds.add(addresseeId));
    try {
      await ref.read(sendFriendRequestUseCaseProvider)
          .call(SendFriendRequestParams(addresseeId: addresseeId));
      if (_query.isNotEmpty) await _search(_query);
    } on FriendFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError(const UnknownFriendFailure().message);
    } finally {
      if (mounted) setState(() => _loadingIds.remove(addresseeId));
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    setState(() => _loadingIds.add(requestId));
    try {
      await ref.read(cancelFriendRequestUseCaseProvider)
          .call(CancelFriendRequestParams(requestId: requestId));
      if (_query.isNotEmpty) await _search(_query);
    } on FriendFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError(const UnknownFriendFailure().message);
    } finally {
      if (mounted) setState(() => _loadingIds.remove(requestId));
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    setState(() => _loadingIds.add(requestId));
    try {
      await ref.read(acceptFriendRequestUseCaseProvider)
          .call(AcceptFriendRequestParams(requestId: requestId));
      ref..invalidate(incomingRequestsProvider)..invalidate(friendsProvider);
      if (_query.isNotEmpty) await _search(_query);
    } on FriendFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError(const UnknownFriendFailure().message);
    } finally {
      if (mounted) setState(() => _loadingIds.remove(requestId));
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    setState(() => _loadingIds.add(requestId));
    try {
      await ref.read(rejectFriendRequestUseCaseProvider)
          .call(RejectFriendRequestParams(requestId: requestId));
      ref.invalidate(incomingRequestsProvider);
    } on FriendFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError(const UnknownFriendFailure().message);
    } finally {
      if (mounted) setState(() => _loadingIds.remove(requestId));
    }
  }

  Future<void> _deleteFriend(String friendId) async {
    try {
      await ref.read(deleteFriendUseCaseProvider)
          .call(DeleteFriendParams(friendId: friendId));
      ref.invalidate(friendsProvider);
    } on FriendFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError(const UnknownFriendFailure().message);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: '닉네임으로 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _searchController.clear(); _onSearchChanged('');
                      })
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: _query.isNotEmpty ? _buildSearchResults() : _buildFriendList(),
    );
  }

  Widget _buildSearchResults() {
    return _searchResults.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e is FriendFailure ? e.message : '오류가 발생했습니다.')),
      data: (results) => results.isEmpty
          ? const Center(child: Text('검색 결과가 없습니다.'))
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (_, i) {
                final user = results[i];
                return SearchResultTile(
                  user: user,
                  isLoading: _loadingIds.contains(user.id) || _loadingIds.contains(user.pendingRequestId),
                  onSendRequest: () => _sendRequest(user.id),
                  onCancelRequest: () {
                    if (user.pendingRequestId != null) _cancelRequest(user.pendingRequestId!);
                  },
                  onAcceptRequest: () {
                    if (user.pendingRequestId != null) _acceptRequest(user.pendingRequestId!);
                  },
                );
              },
            ),
    );
  }

  Widget _buildFriendList() {
    final requestsAsync = ref.watch(incomingRequestsProvider);
    final friendsAsync = ref.watch(friendsProvider(_sortType));

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(incomingRequestsProvider)
          ..invalidate(friendsProvider(_sortType));
      },
      child: ListView(
        children: [
          // 받은 친구 요청
          ...requestsAsync.when(
            loading: () => [],
            error: (_, _) => [],
            data: (requests) {
              if (requests.isEmpty) return [];
              return [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('친구 요청', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...requests.map((req) => FriendRequestTile(
                      request: req,
                      isLoading: _loadingIds.contains(req.id),
                      onAccept: () => _acceptRequest(req.id),
                      onReject: () => _rejectRequest(req.id),
                    )),
                const Divider(),
              ];
            },
          ),

          // 친구 목록
          ...friendsAsync.when(
            loading: () => [const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))],
            error: (e, _) => [Center(child: Text(e is FriendFailure ? e.message : '불러오기 실패'))],
            data: (friends) {
              if (friends.isEmpty) {
                return [const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('아직 친구가 없습니다.')))];
              }
              return [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(
                    children: [
                      const Text('친구', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.sort, size: 16),
                        label: Text(
                          _sortType == FriendSortType.alphabetical ? '가나다순' : '빈시간순',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setState(() {
                            _sortType = _sortType == FriendSortType.alphabetical
                                ? FriendSortType.freeTimeOverlap
                                : FriendSortType.alphabetical;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                ...friends.map((f) => FriendListTile(
                      friend: f,
                      onTap: () => context.push(
                        AppRoutes.friendCalendar.replaceFirst(':friendId', f.friendId),
                      ),
                      onMerge: () => context.push(
                        AppRoutes.mergeCalendar.replaceFirst(':friendId', f.friendId),
                      ),
                      onDelete: () => _deleteFriend(f.friendId),
                    )),
              ];
            },
          ),
        ],
      ),
    );
  }
}
