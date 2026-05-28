import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/usecases/create_comment_usecase.dart';
import '../../domain/usecases/delete_comment_usecase.dart';
import '../../domain/usecases/toggle_post_like_usecase.dart';
import '../../domain/usecases/update_comment_usecase.dart';
import '../providers/feed_providers.dart';

const _kPurple = Color(0xFF7C6AFA);

// 아바타 색 팔레트
const _kAvatarColors = [
  Color(0xFF7C6AFA), Color(0xFFFF7043), Color(0xFF26A69A),
  Color(0xFFEC407A), Color(0xFF42A5F5), Color(0xFF66BB6A),
  Color(0xFFAB47BC), Color(0xFFFF7043),
];

Color _avatarColor(String userId) =>
    _kAvatarColors[userId.hashCode.abs() % _kAvatarColors.length];

String _avatarInitial(String userId) =>
    userId.isNotEmpty ? userId[0].toUpperCase() : '?';

String _fmtRelative(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  return '${diff.inDays}일 전';
}

// ══════════════════════════════════════════════════════════════════════════════
// PostDetailPage
// ══════════════════════════════════════════════════════════════════════════════

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({super.key, required this.postId, this.post});

  final String postId;
  final PostEntity? post; // FeedPage에서 extra로 전달

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _controller = TextEditingController();
  bool _submitting = false;

  // 게시물 좋아요 상태 (extra로 받은 값에서 시작, 낙관적 업데이트)
  late bool _liked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _liked = widget.post?.isLikedByMe ?? false;
    _likeCount = widget.post?.likesCount ?? 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    // 낙관적 업데이트
    setState(() {
      if (_liked) {
        _liked = false;
        _likeCount = (_likeCount - 1).clamp(0, 999999);
      } else {
        _liked = true;
        _likeCount++;
      }
    });
    try {
      await ref.read(togglePostLikeUseCaseProvider).call(
            TogglePostLikeParams(
              postId: widget.postId,
              currentlyLiked: !_liked, // toggled 전 상태
            ),
          );
    } on FeedFailure catch (_) {
      // 롤백
      setState(() {
        if (_liked) {
          _liked = false;
          _likeCount = (_likeCount - 1).clamp(0, 999999);
        } else {
          _liked = true;
          _likeCount++;
        }
      });
    }
  }

  Future<void> _createComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(createCommentUseCaseProvider).call(
            CreateCommentParams(postId: widget.postId, content: content),
          );
      _controller.clear();
      ref.invalidate(commentsProvider(widget.postId));
    } on FeedFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await ref
          .read(deleteCommentUseCaseProvider)
          .call(DeleteCommentParams(commentId: commentId));
      ref.invalidate(commentsProvider(widget.postId));
    } on FeedFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editComment(CommentEntity comment) async {
    final ctrl = TextEditingController(text: comment.content);
    final saved = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentEditSheet(controller: ctrl),
    );
    if (saved == null || saved.trim().isEmpty || saved == comment.content) return;
    try {
      await ref.read(updateCommentUseCaseProvider).call(
            UpdateCommentParams(commentId: comment.id, content: saved.trim()),
          );
      ref.invalidate(commentsProvider(widget.postId));
    } on FeedFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Color(0xFF333333)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '게시물',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── 게시물 헤더 ──────────────────────────────────
                SliverToBoxAdapter(
                  child: _PostHeader(
                    post: widget.post,
                    postId: widget.postId,
                    liked: _liked,
                    likeCount: _likeCount,
                    onLike: _toggleLike,
                  ),
                ),

                // ── 댓글 헤더 ─────────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '댓글',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ),

                // ── 댓글 목록 ─────────────────────────────────────
                commentsAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                          child: CircularProgressIndicator(color: _kPurple)),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                            e is FeedFailure ? e.message : '댓글 불러오기 실패'),
                      ),
                    ),
                  ),
                  data: (comments) {
                    if (comments.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              '첫 댓글을 남겨보세요!',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 14),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _CommentCard(
                          comment: comments[i],
                          isMyComment:
                              currentUser?.id == comments[i].userId,
                          onEdit: () => _editComment(comments[i]),
                          onDelete: () => _deleteComment(comments[i].id),
                        ),
                        childCount: comments.length,
                      ),
                    );
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),

          // ── 댓글 입력 바 ─────────────────────────────────────────
          _CommentInputBar(
            controller: _controller,
            submitting: _submitting,
            onSubmit: _createComment,
          ),
        ],
      ),
    );
  }
}

// ── 게시물 헤더 ────────────────────────────────────────────────────────────────

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    required this.postId,
    required this.liked,
    required this.likeCount,
    required this.onLike,
  });

  final PostEntity? post;
  final String postId;
  final bool liked;
  final int likeCount;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    if (post == null) return const SizedBox.shrink();
    final p = post!;
    final color = _avatarColor(p.userId);
    final initial = _avatarInitial(p.userId);
    final relTime = _fmtRelative(p.createdAt);

    return Container(
      margin: const EdgeInsets.all(16),
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
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.userId.length > 8
                            ? p.userId.substring(0, 8)
                            : p.userId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        relTime,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFAAAAAA)),
                      ),
                    ],
                  ),
                ),
                if (p.visibility == PostVisibility.private)
                  const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
              ],
            ),
          ),

          // 내용
          if (p.content != null && p.content!.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                p.content!,
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF333333), height: 1.6),
              ),
            ),

          // 이미지
          if (p.imageUrl != null)
            ClipRRect(
              child: Image.network(
                p.imageUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: Colors.grey),
                ),
              ),
            ),

          // 좋아요 + 댓글 수
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 14, 12),
            child: Row(
              children: [
                InkWell(
                  onTap: onLike,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 20,
                          color: liked
                              ? const Color(0xFFFF4D6D)
                              : const Color(0xFFAAAAAA),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$likeCount',
                          style: TextStyle(
                            fontSize: 13,
                            color: liked
                                ? const Color(0xFFFF4D6D)
                                : const Color(0xFFAAAAAA),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 댓글 카드 ──────────────────────────────────────────────────────────────────

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.isMyComment,
    required this.onEdit,
    required this.onDelete,
  });

  final CommentEntity comment;
  final bool isMyComment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(comment.userId);
    final initial = _avatarInitial(comment.userId);
    final relTime = _fmtRelative(comment.createdAt);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아바타
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.userId.length > 8
                            ? comment.userId.substring(0, 8)
                            : comment.userId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        relTime,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFAAAAAA)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF333333),
                        height: 1.4),
                  ),
                ],
              ),
            ),
            // 내 댓글인 경우 ... 메뉴
            if (isMyComment)
              _CommentMenu(onEdit: onEdit, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

class _CommentMenu extends StatelessWidget {
  const _CommentMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          color: Color(0xFFCCCCCC), size: 18),
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('수정')),
        PopupMenuItem(
          value: 'delete',
          child: Text('삭제', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

// ── 댓글 수정 시트 ─────────────────────────────────────────────────────────────

class _CommentEditSheet extends StatelessWidget {
  const _CommentEditSheet({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '댓글 수정',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                maxLines: null,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '댓글을 수정하세요',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('취소',
                        style: TextStyle(color: Color(0xFF555555))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('저장',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 댓글 입력 바 ───────────────────────────────────────────────────────────────

class _CommentInputBar extends StatelessWidget {
  const _CommentInputBar({
    required this.controller,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '댓글을 입력하세요...',
                  hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: submitting ? null : onSubmit,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: submitting ? Colors.grey.shade300 : _kPurple,
                shape: BoxShape.circle,
              ),
              child: submitting
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
