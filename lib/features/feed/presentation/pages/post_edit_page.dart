import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/usecases/update_post_usecase.dart';
import '../providers/feed_providers.dart';

const _kPurple = Color(0xFF7C6AFA);

/// 게시글 수정 페이지
class PostEditPage extends ConsumerStatefulWidget {
  const PostEditPage({super.key, required this.post});

  final PostEntity post;

  @override
  ConsumerState<PostEditPage> createState() => _PostEditPageState();
}

class _PostEditPageState extends ConsumerState<PostEditPage> {
  late final TextEditingController _contentController;
  late PostVisibility _visibility;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content ?? '');
    _visibility = widget.post.visibility;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(updatePostUseCaseProvider).call(
            UpdatePostParams(
              postId: widget.post.id,
              content: content,
              visibility: _visibility,
            ),
          );
      if (mounted) context.pop(true); // true = 수정됨
    } on FeedFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF333333)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '게시글 수정',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isLoading ? null : _submit,
              style: TextButton.styleFrom(
                backgroundColor: _kPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('저장', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 내용 입력
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 8,
                style: const TextStyle(fontSize: 15, height: 1.5),
                decoration: const InputDecoration(
                  hintText: '내용을 수정하세요...',
                  hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 공개 범위
            const Text(
              '공개 범위',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _VisibilityChip(
                  label: '전체 공개',
                  icon: Icons.public_rounded,
                  selected: _visibility == PostVisibility.public,
                  onTap: () => setState(() => _visibility = PostVisibility.public),
                ),
                const SizedBox(width: 10),
                _VisibilityChip(
                  label: '나만 보기',
                  icon: Icons.lock_outline_rounded,
                  selected: _visibility == PostVisibility.private,
                  onTap: () => setState(() => _visibility = PostVisibility.private),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEDE9FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _kPurple : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: selected ? _kPurple : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? _kPurple : Colors.grey.shade600,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
