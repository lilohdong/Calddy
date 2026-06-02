import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/usecases/update_avatar_use_case.dart';
import '../../domain/usecases/update_nickname_use_case.dart';
import '../providers/user_providers.dart';
import '../widgets/profile_theme.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _nicknameCtrl;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;

  bool get _isLengthOk => _nicknameCtrl.text.trim().length >= 2;
  bool get _isNoSpecialChar {
    final t = _nicknameCtrl.text.trim();
    return t.isEmpty || RegExp(r'^[a-zA-Z0-9가-힣_]+$').hasMatch(t);
  }
  bool get _isNicknameValid => _isLengthOk && _isNoSpecialChar;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final authUser = ref.read(currentUserProvider);
    _nicknameCtrl = TextEditingController(
      text: profile?.nickname ?? authUser?.nickname ?? '',
    );
    _nicknameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    File? tempFile;
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
      final cacheDir = await getTemporaryDirectory();
      final tempPath = '${cacheDir.path}/calddy_avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);

      await ref
          .read(updateAvatarUseCaseProvider)
          .call(UpdateAvatarParams(filePath: tempPath));

      ref.invalidate(currentUserProfileProvider);
    } on UserFailure catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('이미지 업로드 실패\n$e');
    } finally {
      try { tempFile?.deleteSync(); } catch (_) {}
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    final nickname = _nicknameCtrl.text.trim();
    final profile  = ref.read(currentUserProfileProvider).valueOrNull;
    final authUser = ref.read(currentUserProvider);
    final current  = profile?.nickname ?? authUser?.nickname ?? '';

    if (nickname == current) {
      context.pop();
      return;
    }

    if (!_isNicknameValid) {
      _showError('닉네임 조건을 확인해주세요.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(updateNicknameUseCaseProvider)
          .call(UpdateNicknameParams(nickname: nickname));
      ref.invalidate(currentUserProfileProvider);
      if (mounted) context.pop();
    } on NicknameChangeCooldownFailure catch (e) {
      _showError(e.message);
    } on NicknameTakenFailure catch (e) {
      _showError(e.message);
    } on UserFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('저장에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile   = ref.watch(currentUserProfileProvider).valueOrNull;
    final authUser  = ref.watch(currentUserProvider);
    final avatarUrl = profile?.avatarUrl ?? authUser?.avatarUrl;
    final nickname  = profile?.nickname  ?? authUser?.nickname ?? '';
    final typed     = _nicknameCtrl.text.trim();
    final hasTyped  = typed.isNotEmpty;

    return Scaffold(
      backgroundColor: ProfileTheme.bg,
      appBar: AppBar(
        backgroundColor: ProfileTheme.bg,
        elevation: 0,
        centerTitle: true,
        title: const Text('프로필 수정',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 52,
                                backgroundColor: ProfileTheme.primaryLight,
                                backgroundImage: avatarUrl != null
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl == null
                                    ? Text(
                                        nickname.isNotEmpty
                                            ? nickname[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: ProfileTheme.primary,
                                        ),
                                      )
                                    : null,
                              ),
                              if (_isUploadingAvatar)
                                Positioned.fill(
                                  child: CircleAvatar(
                                    radius: 52,
                                    backgroundColor:
                                        Colors.black.withValues(alpha: 0.3),
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: ProfileTheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '프로필 이미지 변경',
                          style: TextStyle(
                              color: ProfileTheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'JPG, PNG 파일, 5MB 이하',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    decoration: BoxDecoration(
                      color: ProfileTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 8,
                            offset: Offset(0, 2)),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('닉네임',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFAAAAAA),
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nicknameCtrl,
                          maxLength: 20,
                          decoration: InputDecoration(
                            counterText: '${typed.length}/20',
                            counterStyle: const TextStyle(
                                color: Color(0xFFBBBBBB), fontSize: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE8E4F8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE8E4F8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: ProfileTheme.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            suffixIcon: typed.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    color: Colors.grey,
                                    onPressed: () => _nicknameCtrl.clear(),
                                  )
                                : null,
                          ),
                        ),
                        if (hasTyped) ...[
                          const SizedBox(height: 10),
                          _ValidationRow(ok: _isLengthOk, text: '2자 이상 입력해주세요.'),
                          const SizedBox(height: 4),
                          _ValidationRow(
                              ok: _isNoSpecialChar,
                              text: '특수문자는 사용할 수 없어요.'),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProfileTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('저장',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationRow extends StatelessWidget {
  const _ValidationRow({required this.ok, required this.text});
  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ok ? Icons.check : Icons.close,
            size: 14, color: ok ? Colors.green : Colors.redAccent),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize: 12,
                color: ok ? Colors.green : Colors.redAccent)),
      ],
    );
  }
}
