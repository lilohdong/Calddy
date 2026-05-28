import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/usecases/create_post_usecase.dart';
import '../providers/feed_providers.dart';

class PostCreatePage extends ConsumerStatefulWidget {
  const PostCreatePage({super.key});

  @override
  ConsumerState<PostCreatePage> createState() => _PostCreatePageState();
}

class _PostCreatePageState extends ConsumerState<PostCreatePage> {
  final _contentController = TextEditingController();
  PostVisibility _visibility = PostVisibility.public;
  bool _isLoading = false;

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
      await ref.read(createPostUseCaseProvider).call(
            CreatePostParams(
              content: content,
              visibility: _visibility,
              feedDate: DateTime.now(),
            ),
          );
      if (mounted) context.pop();
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
      appBar: AppBar(
        title: const Text('게시글 작성'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('게시'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '내용을 입력하세요...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('공개 범위'),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('전체 공개'),
                  selected: _visibility == PostVisibility.public,
                  onSelected: (_) =>
                      setState(() => _visibility = PostVisibility.public),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('비공개'),
                  selected: _visibility == PostVisibility.private,
                  onSelected: (_) =>
                      setState(() => _visibility = PostVisibility.private),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
