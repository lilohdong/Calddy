import 'package:flutter/material.dart';

/// Calddy 브랜드 로고 위젯 (CustomPainter 기반)
/// [size] 는 높이 기준. 너비는 size * 1.4 로 자동 설정됨.
class CaldyLogo extends StatelessWidget {
  const CaldyLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.4,
      height: size,
      child: CustomPaint(painter: const _CaldyLogoPainter()),
    );
  }
}

class _CaldyLogoPainter extends CustomPainter {
  const _CaldyLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shader = const LinearGradient(
      colors: [Color(0xFF7B80FF), Color(0xFFAA82F4)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = shader;

    // ── 왼쪽 루프 ──────────────────────────────────────────────────────────────
    final leftPath = Path()
      ..moveTo(w * 0.50, h * 0.50)
      ..cubicTo(
        w * 0.44, h * -0.04,
        w * 0.02, h * -0.04,
        w * 0.10, h * 0.50,
      )
      ..cubicTo(
        w * 0.02, h * 1.04,
        w * 0.44, h * 1.04,
        w * 0.50, h * 0.50,
      );

    // ── 오른쪽 루프 ────────────────────────────────────────────────────────────
    final rightPath = Path()
      ..moveTo(w * 0.50, h * 0.50)
      ..cubicTo(
        w * 0.56, h * -0.04,
        w * 0.98, h * -0.04,
        w * 0.90, h * 0.50,
      )
      ..cubicTo(
        w * 0.98, h * 1.04,
        w * 0.56, h * 1.04,
        w * 0.50, h * 0.50,
      );

    // ── 내부 웨이브 (로고 특유의 겹침 효과) ────────────────────────────────────
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.13
      ..strokeCap = StrokeCap.round
      ..shader = shader;

    final leftInner = Path()
      ..moveTo(w * 0.50, h * 0.50)
      ..cubicTo(
        w * 0.35, h * 0.25,
        w * 0.22, h * 0.32,
        w * 0.19, h * 0.50,
      )
      ..cubicTo(
        w * 0.22, h * 0.68,
        w * 0.35, h * 0.75,
        w * 0.50, h * 0.50,
      );

    final rightInner = Path()
      ..moveTo(w * 0.50, h * 0.50)
      ..cubicTo(
        w * 0.65, h * 0.25,
        w * 0.78, h * 0.32,
        w * 0.81, h * 0.50,
      )
      ..cubicTo(
        w * 0.78, h * 0.68,
        w * 0.65, h * 0.75,
        w * 0.50, h * 0.50,
      );

    canvas
      ..drawPath(leftPath, paint)
      ..drawPath(rightPath, paint)
      ..drawPath(leftInner, innerPaint)
      ..drawPath(rightInner, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
