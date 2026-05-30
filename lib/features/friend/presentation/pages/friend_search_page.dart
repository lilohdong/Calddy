import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/searched_user_entity.dart';
import '../../domain/usecases/accept_friend_request_use_case.dart';
import '../../domain/usecases/cancel_friend_request_use_case.dart';
import '../../domain/usecases/search_users_use_case.dart';
import '../../domain/usecases/send_friend_request_use_case.dart';
import '../providers/friend_providers.dart';

class FriendSearchPage extends ConsumerStatefulWidget {
  const FriendSearchPage({super.key});

  @override
  ConsumerState<FriendSearchPage> createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends ConsumerState<FriendSearchPage> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  AsyncValue<List<SearchedUserEntity>> _results = const AsyncValue.data([]);
  final _loadingIds = <String>{};

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    if (v.trim().length < 2) {
      setState(() => _results = const AsyncValue.data([]));
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _search(v),
    );
  }

  Future<void> _search(String q) async {
    setState(() => _results = const AsyncValue.loading());
    try {
      final data = await ref
          .read(searchUsersUseCaseProvider)
          .call(SearchUsersParams(query: q));
      if (mounted) setState(() => _results = AsyncValue.data(data));
    } catch (e, st) {
      if (mounted) setState(() => _results = AsyncValue.error(e, st));
    }
  }

  Future<void> _sendRequest(String userId) async {
    setState(() => _loadingIds.add(userId));
    try {
      await ref
          .read(sendFriendRequestUseCaseProvider)
          .call(SendFriendRequestParams(addresseeId: userId));
      if (_ctrl.text.trim().length >= 2) await _search(_ctrl.text);
    } on FriendFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _loadingIds.remove(userId));
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    setState(() => _loadingIds.add(requestId));
    try {
      await ref
          .read(cancelFriendRequestUseCaseProvider)
          .call(CancelFriendRequestParams(requestId: requestId));
      if (_ctrl.text.trim().length >= 2) await _search(_ctrl.text);
    } on FriendFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _loadingIds.remove(requestId));
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    setState(() => _loadingIds.add(requestId));
    try {
      await ref
          .read(acceptFriendRequestUseCaseProvider)
          .call(AcceptFriendRequestParams(requestId: requestId));
      if (_ctrl.text.trim().length >= 2) await _search(_ctrl.text);
    } on FriendFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _loadingIds.remove(requestId));
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
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
        title: const Text(
          '친구 검색',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: '닉네임으로 검색',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF7C6AFA), size: 22),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _ctrl.clear();
                          _onChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF4F3FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _results.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  e is FriendFailure ? e.message : '오류가 발생했습니다.',
                ),
              ),
              data: (results) {
                if (_ctrl.text.trim().length < 2) {
                  return _Placeholder(
                    icon: Icons.search,
                    message: '닉네임을 입력하면 친구를 찾을 수 있어요',
                  );
                }
                if (results.isEmpty) {
                  return _Placeholder(
                    icon: Icons.person_search_outlined,
                    message: '검색 결과가 없습니다',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        '검색 결과 · ${results.length}명',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final user = results[i];
                          return _SearchResultRow(
                            user: user,
                            isLoading: _loadingIds.contains(user.id) ||
                                _loadingIds
                                    .contains(user.pendingRequestId),
                            onSend: () => _sendRequest(user.id),
                            onCancel: () {
                              if (user.pendingRequestId != null) {
                                _cancelRequest(user.pendingRequestId!);
                              }
                            },
                            onAccept: () {
                              if (user.pendingRequestId != null) {
                                _acceptRequest(user.pendingRequestId!);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.user,
    required this.isLoading,
    required this.onSend,
    required this.onCancel,
    required this.onAccept,
  });

  final SearchedUserEntity user;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final VoidCallback onAccept;

  static const _palette = [
    Color(0xFF9B8FF5),
    Color(0xFF6EC6B8),
    Color(0xFF5BB5E8),
    Color(0xFFF5A623),
    Color(0xFFF07DB3),
  ];

  Color get _color => _palette[user.id.hashCode.abs() % _palette.length];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: _color.withOpacity(0.18),
            child: Text(
              user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.nickname,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            _ActionChip(user: user, onSend: onSend, onCancel: onCancel, onAccept: onAccept),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.user,
    required this.onSend,
    required this.onCancel,
    required this.onAccept,
  });

  final SearchedUserEntity user;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return switch (user.relationStatus) {
      FriendRelationStatus.none => _Chip(
          label: '친구 추가',
          bg: const Color(0xFF7C6AFA),
          fg: Colors.white,
          onTap: onSend,
        ),
      FriendRelationStatus.requestSent => _Chip(
          label: '요청 중',
          bg: const Color(0xFFEDE9FF),
          fg: const Color(0xFF7C6AFA),
          onTap: onCancel,
        ),
      FriendRelationStatus.requestReceived => _Chip(
          label: '수락하기',
          bg: const Color(0xFFE8F5E9),
          fg: const Color(0xFF43A047),
          onTap: onAccept,
        ),
      FriendRelationStatus.friend => _Chip(
          label: '친구',
          bg: Colors.grey.shade100,
          fg: Colors.grey.shade500,
          onTap: null,
        ),
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
