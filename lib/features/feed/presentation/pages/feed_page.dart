import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/calddy_logo.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notification/domain/entities/notification_entity.dart';
import '../../../notification/domain/usecases/mark_notification_read_use_case.dart';
import '../../../notification/presentation/providers/notification_providers.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/usecases/delete_post_usecase.dart';
import '../../domain/usecases/toggle_post_like_usecase.dart';
import '../providers/feed_providers.dart';
import '../utils/feed_ui_helpers.dart';

// ── 색상 상수 ──────────────────────────────────────────────────────────────────
const _kPurple = Color(0xFF7C6AFA);
const _kPurpleLight = Color(0xFFEDE9FF);

// ── 날짜 포맷 헬퍼 ─────────────────────────────────────────────────────────────
String _fmtDate(DateTime dt) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month]} ${dt.day}, ${dt.year}';
}

// ══════════════════════════════════════════════════════════════════════════════
// FeedPage
// ══════════════════════════════════════════════════════════════════════════════

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  DateTime _selectedDate = DateTime.now();

  // DateTime.now()는 build()에서 한 번 캡처 후 전달 — 자정 edge-case 방어
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _prevDay() =>
      setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
  void _nextDay() {
    if (_isSameDay(_selectedDate, DateTime.now())) return;
    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPurple),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _toggleLike(PostEntity post) async {
    final notifier =
        ref.read(feedByDateProvider(_selectedDate).notifier);
    // 낙관적 업데이트: DB 응답 전에 UI 즉시 반영 (피드 전체 재로드 없음)
    notifier.optimisticToggleLike(post.id, post.isLikedByMe);
    try {
      await ref.read(togglePostLikeUseCaseProvider).call(
            TogglePostLikeParams(
              postId: post.id,
              currentlyLiked: post.isLikedByMe,
            ),
          );
    } on FeedFailure catch (e) {
      // 실패 시 원래 상태로 복원
      notifier.revertToggleLike(post.id, post.isLikedByMe, post.likesCount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await ref
          .read(deletePostUseCaseProvider)
          .call(DeletePostParams(postId: postId));
      ref.invalidate(feedByDateProvider(_selectedDate));
    } on FeedFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showBell() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) => const _NotificationPopover(),
    );
  }

  void _showPostMenu(BuildContext ctx, PostEntity post, bool isMyPost) {
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostMenuSheet(
        post: post,
        isMyPost: isMyPost,
        onDelete: () => _deletePost(post.id),
        onEdit: () => ctx.push(AppRoutes.postEditPath(post.id), extra: post),
        onReport: () => _showReportSheet(ctx, post.id),
      ),
    );
  }

  void _showReportSheet(BuildContext ctx, String postId) {
    ctx.push(AppRoutes.postReportPath(postId));
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedByDateProvider(_selectedDate));
    final currentUser = ref.watch(currentUserProvider);
    // build 한 프레임 내에서 now를 한 번만 캡처 → 자정 edge-case 방어
    // (날짜 이동 탭 이벤트인 _nextDay는 탭 시점의 최신 DateTime.now()를 사용하는 것이 맞음)
    final now = DateTime.now();
    final isAtLatest = _isSameDay(_selectedDate, now);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      appBar: _FeedAppBar(onBellTap: _showBell),
      body: Column(
        children: [
          // ── 날짜 선택 바 ──────────────────────────────────────────
          _DateBar(
            date: _selectedDate,
            onPrev: _prevDay,
            onNext: _nextDay,
            onTap: _pickDate,
            isAtLatest: isAtLatest,
          ),

          // ── 피드 리스트 ───────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: _kPurple,
              onRefresh: () async {
                await ref.read(feedByDateProvider(_selectedDate).notifier).refresh();
              },
              child: feedAsync.when(
                // 로딩·에러도 ListView로 감싸 pull-to-refresh 활성화
                loading: () => ListView(children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator(color: _kPurple)),
                ]),
                error: (e, _) => ListView(children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      e is FeedFailure ? e.message : '불러오기 실패',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ]),
                data: (posts) {
                  if (posts.isEmpty) {
                    return _EmptyFeed(onGoCalendar: () => context.go(AppRoutes.home));
                  }
                  final notifier =
                      ref.read(feedByDateProvider(_selectedDate).notifier);
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 88),
                    itemCount: posts.length + 1, // 마지막: fetchMore 트리거
                    itemBuilder: (_, i) {
                      if (i == posts.length) {
                        // 마지막 아이템 렌더 시 다음 페이지 로드
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (notifier.hasMore) notifier.fetchMore();
                        });
                        return notifier.hasMore
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: _kPurple, strokeWidth: 2),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      final post = posts[i];
                      final isMyPost = currentUser?.id == post.userId;
                      return _PostCard(
                        post: post,
                        isMyPost: isMyPost,
                        onLike: () => _toggleLike(post),
                        onMenu: () => _showPostMenu(context, post, isMyPost),
                        onTap: () => context.push(
                            AppRoutes.postDetailPath(post.id), extra: post),
                        onComment: () => context.push(
                            AppRoutes.postDetailPath(post.id), extra: post),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),

    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AppBar
// ══════════════════════════════════════════════════════════════════════════════

class _FeedAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _FeedAppBar({required this.onBellTap});

  final VoidCallback onBellTap;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);
    final unread = notifAsync.valueOrNull?.where((n) => !n.isRead).length ?? 0;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: 20,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CaldyLogo(size: 24),
          const SizedBox(width: 8),
          const Text(
            'Calddy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _kPurple,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded,
                  color: Color(0xFF333333), size: 26),
              onPressed: onBellTap,
            ),
            if (unread > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 날짜 선택 바
// ══════════════════════════════════════════════════════════════════════════════

class _DateBar extends StatelessWidget {
  const _DateBar({
    required this.date,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
    required this.isAtLatest,
  });

  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTap;
  final bool isAtLatest;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF555555)),
            iconSize: 22,
            onPressed: onPrev,
            splashRadius: 18,
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _kPurpleLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 13, color: _kPurple),
                  const SizedBox(width: 6),
                  Text(
                    _fmtDate(date),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isAtLatest
                  ? Colors.grey.shade300
                  : const Color(0xFF555555),
            ),
            iconSize: 22,
            onPressed: isAtLatest ? null : onNext,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 게시물 카드
// ══════════════════════════════════════════════════════════════════════════════

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.isMyPost,
    required this.onLike,
    required this.onMenu,
    required this.onTap,
    required this.onComment,
  });

  final PostEntity post;
  final bool isMyPost;
  final VoidCallback onLike;
  final VoidCallback onMenu;
  final VoidCallback onTap;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final color = avatarColor(post.userId);
    final initial = post.authorNickname?.isNotEmpty == true
        ? post.authorNickname![0].toUpperCase()
        : avatarInitial(post.userId);
    final relativeTime = fmtRelative(post.createdAt);
    final isPrivate = post.visibility == PostVisibility.private;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더: 아바타 + 이름 + 시간 + ... ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
              child: Row(
                children: [
                  // 아바타
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 이름 + 시간
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.authorNickname ?? '알 수 없음',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            if (isPrivate) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.lock_outline,
                                  size: 12, color: Colors.grey),
                            ],
                          ],
                        ),
                        Text(
                          relativeTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFAAAAAA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ... 메뉴
                  IconButton(
                    icon: const Icon(Icons.more_horiz_rounded,
                        color: Color(0xFFAAAAAA), size: 22),
                    onPressed: onMenu,
                    splashRadius: 18,
                  ),
                ],
              ),
            ),

            // ── 내용 ──────────────────────────────────────────────
            if (post.content != null && post.content!.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  post.content!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                    height: 1.5,
                  ),
                ),
              ),

            // ── 이미지 ────────────────────────────────────────────
            if (post.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: Colors.grey),
                  ),
                ),
              ),

            // ── 하단: 좋아요 + 댓글 ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 14, 12),
              child: Row(
                children: [
                  // 좋아요
                  _ActionBtn(
                    icon: post.isLikedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: '${post.likesCount}',
                    color: post.isLikedByMe
                        ? const Color(0xFFFF4D6D)
                        : const Color(0xFFAAAAAA),
                    onTap: onLike,
                  ),
                  const SizedBox(width: 4),
                  // 댓글
                  _ActionBtn(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '댓글',
                    color: const Color(0xFFAAAAAA),
                    onTap: onComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 빈 피드 상태
// ══════════════════════════════════════════════════════════════════════════════

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.onGoCalendar});

  final VoidCallback onGoCalendar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CaldyLogo(size: 56),
          const SizedBox(height: 20),
          const Text(
            '오늘 하루를 기록하고\n공유 해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onGoCalendar,
            icon: const Icon(Icons.calendar_month_outlined,
                size: 16, color: _kPurple),
            label: const Text('캘린더로 이동',
                style: TextStyle(color: _kPurple, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kPurple),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 공용 바텀시트 래퍼 (흰 배경 + 위쪽 둥근 모서리 + SafeArea + 핸들)
// ══════════════════════════════════════════════════════════════════════════════

class _BottomSheetWrapper extends StatelessWidget {
  const _BottomSheetWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 게시물 ... 메뉴 바텀시트
// ══════════════════════════════════════════════════════════════════════════════

class _PostMenuSheet extends StatelessWidget {
  const _PostMenuSheet({
    required this.post,
    required this.isMyPost,
    required this.onDelete,
    required this.onEdit,
    required this.onReport,
  });

  final PostEntity post;
  final bool isMyPost;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMyPost) ...[
            _SheetItem(
              icon: Icons.edit_outlined,
              label: '수정',
              onTap: () {
                context.pop();
                onEdit();
              },
            ),
            _SheetItem(
              icon: Icons.delete_outline_rounded,
              label: '삭제',
              color: Colors.red,
              onTap: () {
                context.pop();
                _confirmDelete(context);
              },
            ),
          ] else ...[
            _SheetItem(
              icon: Icons.flag_outlined,
              label: '신고',
              color: Colors.red,
              onTap: () {
                context.pop();
                onReport();
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('게시글 삭제'),
        content: const Text('이 게시글을 삭제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  const _SheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF333333);
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w500)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: onTap,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 알림 팝오버 (말풍선 꼬리)
// ══════════════════════════════════════════════════════════════════════════════

class _NotificationPopover extends ConsumerWidget {
  const _NotificationPopover();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);
    final mq = MediaQuery.of(context);
    final topOffset = mq.padding.top + 56 + 6.0;

    return Padding(
      padding: EdgeInsets.only(top: topOffset, right: 8),
      child: Align(
        alignment: Alignment.topRight,
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 꼬리 삼각형
              const Padding(
                padding: EdgeInsets.only(right: 18),
                child: CustomPaint(
                  painter: _PopoverTailPainter(),
                  size: Size(16, 9),
                ),
              ),
              // 패널
              Container(
                width: mq.size.width * 0.82,
                constraints: BoxConstraints(
                  maxHeight: mq.size.height * 0.55,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 헤더 ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                      child: Row(
                        children: [
                          const Text(
                            '알림',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const Spacer(),
                          // 전체 읽기
                          notifAsync.maybeWhen(
                            data: (notifs) {
                              final hasUnread =
                                  notifs.any((n) => !n.isRead);
                              return TextButton(
                                onPressed: hasUnread
                                    ? () async {
                                        await ref.read(
                                            markAllNotificationsReadUseCaseProvider)
                                            .call(NoParams());
                                        ref.invalidate(notificationsProvider);
                                      }
                                    : null,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  '전체 읽기',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasUnread
                                        ? _kPurple
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              );
                            },
                            orElse: () => const SizedBox(),
                          ),
                          // 구분선
                          Text('|',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade300)),
                          // 전체 삭제
                          TextButton(
                            onPressed: () async {
                              await ref
                                  .read(
                                      deleteAllNotificationsUseCaseProvider)
                                  .call(NoParams());
                              ref.invalidate(notificationsProvider);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '전체 삭제',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // ── 목록 ───────────────────────────────────────
                    Flexible(
                      child: notifAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: _kPurple)),
                        ),
                        error: (_, __) => const Padding(
                          padding: EdgeInsets.all(24),
                          child:
                              Center(child: Text('알림을 불러올 수 없어요')),
                        ),
                        data: (notifs) {
                          if (notifs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text('새로운 알림이 없어요',
                                    style:
                                        TextStyle(color: Colors.grey)),
                              ),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: notifs.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, indent: 16, endIndent: 16),
                            itemBuilder: (_, i) => _NotifTile(
                              notif: notifs[i],
                              onTap: () async {
                                // 이동할 경로를 async 전에 미리 캡처
                                final route = _routeFor(notifs[i]);
                                // 읽음 처리 (fire-and-forget, UI 블로킹 없음)
                                if (!notifs[i].isRead) {
                                  unawaited(ref
                                      .read(markNotificationReadUseCaseProvider)
                                      .call(MarkNotificationReadParams(
                                          notificationId: notifs[i].id))
                                      .then((_) => ref.invalidate(
                                          notificationsProvider)));
                                }
                                // 팝오버 닫기 + 페이지 이동 (동기적으로 연속 실행)
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  if (route != null) context.push(route);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 알림 타입 + relatedId → 이동할 경로
  String? _routeFor(NotificationEntity notif) {
    switch (notif.type) {
      case NotificationType.friendRequest:
        return AppRoutes.friends;
      case NotificationType.appointmentInvite:
      case NotificationType.appointmentAccepted:
      case NotificationType.appointmentRejected:
      case NotificationType.suggestNewDate:
        final id = notif.relatedId;
        return id != null
            ? AppRoutes.appointmentDetailPath(id)
            : AppRoutes.home;
      case NotificationType.postLiked:
      case NotificationType.postCommented:
        final id = notif.relatedId;
        return id != null ? AppRoutes.postDetailPath(id) : AppRoutes.feed;
    }
  }
}

class _PopoverTailPainter extends CustomPainter {
  const _PopoverTailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notif, required this.onTap});

  final NotificationEntity notif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: notif.isRead
                    ? Colors.grey.shade100
                    : const Color(0xFFEDE9FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _notifIcon(notif.type),
                color: notif.isRead ? Colors.grey.shade400 : _kPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: notif.isRead
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  if (notif.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notif.body,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    _timeAgo(notif.createdAt),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            // 미읽음 도트
            if (!notif.isRead)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _kPurple,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}/${dt.day}';
  }

  IconData _notifIcon(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return Icons.person_add_outlined;
      case NotificationType.appointmentInvite:
        return Icons.event_outlined;
      case NotificationType.appointmentAccepted:
        return Icons.check_circle_outline;
      case NotificationType.appointmentRejected:
        return Icons.cancel_outlined;
      case NotificationType.suggestNewDate:
        return Icons.update_outlined;
      case NotificationType.postLiked:
        return Icons.favorite_border_rounded;
      case NotificationType.postCommented:
        return Icons.chat_bubble_outline_rounded;
    }
  }
}
