import 'package:flutter/material.dart';

/// Calddy 브랜드 로고 위젯.
/// [size]는 높이 기준이며 가로는 이미지 비율에 따라 자동 조정됩니다.
class CaldyLogo extends StatelessWidget {
  const CaldyLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/Calddy_logo.png',
      height: size,
      fit: BoxFit.contain,
    );
  }
}
