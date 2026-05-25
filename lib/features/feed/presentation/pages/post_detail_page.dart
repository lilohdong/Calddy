import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/usecases/create_comment_usecase.dart';
import '../../domain/usecases/delete_comment_usecase.dart';
import '../../domain/usecases/update_comment_usecase.dart';
import '../providers/feed_providers.dart';

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    final controller = TextEditingController(text: comment.content);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('댓글 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(hintText: '댓글 내용'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final newContent = controller.text.trim();
    if (newContent.isEmpty || newContent == comment.content) return;
    try {
      await ref.read(updateCommentUseCaseProvider).call(
            UpdateCommentParams(
              commentId: comment.id,
              content: newContent,
            ),
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

    return Scaffold(
      appBar: AppBar(title: const Text('게시물 상세')),
      body: Column(
        children: [
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(e is FeedFailure ? e.message : '댓글 불러오기 실패'),
              ),
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(child: Text('댓글이 없습니다.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) => _CommentTile(
                    comment: comments[i],
                    onEdit: () => _editComment(comments[i]),
                    onDelete: () => _deleteComment(comments[i].id),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _createComment(),
                    decoration: const InputDecoration(
                      hintText: '댓글을 입력하세요',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _createComment,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onEdit,
    required this.onDelete,
  });

  final CommentEntity comment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(comment.content),
      subtitle: Text(_fmt(comment.createdAt)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
          IconButton(
              icon: const Icon(Icons.delete_outline), onPressed: onDelete),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
