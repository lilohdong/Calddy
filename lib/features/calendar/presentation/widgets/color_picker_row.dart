import 'package:flutter/material.dart';

const kColorOptions = [
  '#7C6AFA', '#4CAF50', '#FF9800', '#9C27B0', '#F44336', '#FFC107',
];

class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    super.key,
    required this.selected,
    required this.onChanged,
    this.options = kColorOptions,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final List<String> options;

  static Color fromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF7C6AFA);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...options.map((hex) {
          final c = fromHex(hex);
          final isSelected = selected == hex;
          return GestureDetector(
            onTap: () => onChanged(hex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: isSelected
                    ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          );
        }),
        GestureDetector(
          onTap: () async {
            // TODO: 커스텀 색상 picker 연결 (추후 확장)
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.add, size: 18, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
