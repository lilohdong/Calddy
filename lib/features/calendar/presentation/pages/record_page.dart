import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../feed/domain/entities/post_entity.dart';
import '../../../feed/domain/usecases/create_post_usecase.dart';
import '../../../feed/presentation/providers/feed_providers.dart';

class RecordPage extends ConsumerStatefulWidget {
  const RecordPage({super.key, required this.eventId, this.isEditing = false});
  final String eventId;
  final bool isEditing;

  @override
  ConsumerState<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage> {
  final _contentCtrl = TextEditingController();
  bool _isPublic = true;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      setState(() => _selectedImage = File(xFile.path));
    }
  }

  Future<void> _submit() async {
    if (_contentCtrl.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력하거나 사진을 추가해주세요')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      List<int>? imageBytes;
      String? imageExtension;
      if (_selectedImage != null) {
        imageBytes = await _selectedImage!.readAsBytes();
        final ext = _selectedImage!.path.split('.').last.toLowerCase();
        imageExtension = ext.isEmpty ? 'jpg' : ext;
      }

      await ref.read(createPostUseCaseProvider).call(
        CreatePostParams(
          content: _contentCtrl.text.trim().isEmpty
              ? null
              : _contentCtrl.text.trim(),
          imageBytes: imageBytes,
          imageExtension: imageExtension,
          visibility: _isPublic
              ? PostVisibility.public
              : PostVisibility.private,
          feedDate: DateTime.now(),
          eventId: widget.eventId,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('피드에 기록이 올라갔어요! 🎉')),
        );
        context.pop(true); // return true = recorded successfully
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('저장에 실패했습니다: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.isEditing ? '기록 수정하기' : '기록하기',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    widget.isEditing ? '수정' : '완료',
                    style: const TextStyle(
                        color: Color(0xFF7C6AFA), fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 이벤트 이름 헤더
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF7C6AFA),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '일정 · ${widget.eventId}',
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7C6AFA),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 본문 입력
          TextField(
            controller: _contentCtrl,
            maxLines: 8,
            style: const TextStyle(fontSize: 16, height: 1.6),
            decoration: const InputDecoration(
              hintText: '오늘의 기록을 남겨보세요...',
              hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 16),

          // 사진 추가
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                image: _selectedImage != null
                    ? DecorationImage(
                        image: FileImage(_selectedImage!), fit: BoxFit.cover)
                    : null,
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            size: 36, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          '탭하여 사진 추가',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 24),

          // 전체 공유 토글
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('전체 공유',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('피드에 노출돼요',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Switch(
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                  activeThumbColor: const Color(0xFF7C6AFA),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
