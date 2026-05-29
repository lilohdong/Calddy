import 'package:flutter/material.dart';
import '../../../../core/widgets/calddy_logo.dart';

// ── 색상 상수 ────────────────────────────────────────────────────────────────

const kAuthPurple = Color(0xFF7C6AFA);
const kAuthPurpleLight = Color(0xFFEDE9FF);
const kAuthBg = Color(0xFFF8F7FF);

// ── 로고 박스 ─────────────────────────────────────────────────────────────────

class AuthLogoBox extends StatelessWidget {
  const AuthLogoBox({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: kAuthPurple.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: CaldyLogo(size: size * 0.46),
      ),
    );
  }
}

// ── 입력 필드 ─────────────────────────────────────────────────────────────────

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? Colors.red.shade400 : Colors.grey.shade300,
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: enabled,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
              prefixIcon: Icon(prefixIcon, color: Colors.grey.shade400, size: 20),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade400),
            ),
          ),
        ],
      ],
    );
  }
}

// ── 보라색 버튼 ───────────────────────────────────────────────────────────────

class AuthPurpleButton extends StatelessWidget {
  const AuthPurpleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isActive = enabled && !isLoading;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isActive ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: kAuthPurple,
          disabledBackgroundColor: kAuthPurple.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

// ── 또는 구분선 ────────────────────────────────────────────────────────────────

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('또는', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }
}

// ── Google 버튼 ───────────────────────────────────────────────────────────────

class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google 'G' 로고 텍스트 근사
            const Text(
              'G',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4285F4),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Google로 로그인',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 아이콘 서클 (비밀번호 찾기 등) ────────────────────────────────────────────

class AuthIconCircle extends StatelessWidget {
  const AuthIconCircle({
    super.key,
    required this.icon,
    this.size = 80,
    this.iconSize = 36,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: kAuthPurpleLight,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: kAuthPurple, size: iconSize),
    );
  }
}
