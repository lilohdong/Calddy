import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/report_entity.dart';
import '../../domain/usecases/report_use_case.dart';
import '../providers/report_providers.dart';

const _kPurple = Color(0xFF7C6AFA);
const _kPurpleLight = Color(0xFFEDE9FF);

class ReportPostPage extends ConsumerStatefulWidget {
  const ReportPostPage({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<ReportPostPage> createState() => _ReportPostPageState();
}

class _ReportPostPageState extends ConsumerState<ReportPostPage> {
  String? _selected;
  bool _loading = false;
  bool _done = false;

  static const _reasons = [
    ('스팸 또는 광고', '원치 않는 광고, 홍보, 도배 콘텐츠'),
    ('혐오 발언 또는 차별', '누군가를 비하하거나 차별하는 내용'),
    ('폭력 또는 위험한 내용', '폭력, 자해, 위험 행위 등을 조장하는 내용'),
    ('불법 또는 규제 대상 콘텐츠', '불법 상품, 행위, 규제 대상 정보 등'),
    ('개인정보 노출', '타인의 개인정보를 게시한 경우'),
    ('기타', '기타 문제'),
  ];

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(reportUseCaseProvider).call(
            ReportParams(
              targetType: ReportTargetType.post,
              targetId: widget.postId,
              reason: _selected!,
            ),
          );
      if (mounted) setState(() => _done = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고 중 오류가 발생했어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _buildDone(context);
    return _buildForm(context);
  }

  Widget _buildDone(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '신고 완료',
          style: TextStyle(
              color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: _kPurpleLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: _kPurple, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              '신고가 접수되었습니다',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            Text(
              '신고해주셔서 감사합니다.\n검토 후 커뮤니티 가이드에 따라 조치하겠습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade500, height: 1.5),
            ),
            const Spacer(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('확인',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: const Text('취소',
              style: TextStyle(color: Colors.black54, fontSize: 15)),
        ),
        leadingWidth: 60,
        title: const Text(
          '신고',
          style: TextStyle(
              color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: (_selected != null && !_loading) ? _submit : null,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPurple),
                  )
                : Text(
                    '다음',
                    style: TextStyle(
                      color: _selected != null
                          ? _kPurple
                          : Colors.grey.shade400,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이 게시물을 신고하는 이유는?',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 4),
            Text(
              '신고 내용은 Calddy의 커뮤니티 가이드에 따라 검토됩니다.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            ..._reasons.map((item) => _RadioReasonTile(
                  title: item.$1,
                  subtitle: item.$2,
                  selected: _selected == item.$1,
                  onTap: () => setState(() => _selected = item.$1),
                )),
            const SizedBox(height: 16),
            Text(
              '허위 신고 시 서비스 이용에 제한이 있을 수 있습니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioReasonTile extends StatelessWidget {
  const _RadioReasonTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _kPurple : Colors.grey.shade300,
                  width: selected ? 6 : 2,
                ),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
