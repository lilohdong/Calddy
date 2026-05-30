import 'package:flutter/material.dart';

const kStickers = [
  '☕', '📚', '🌷', '🎵', '✨', '🌙',
  '💝', '🎂', '🌈', '⭐', '🌮', '🌿',
];

class StickerGridWidget extends StatelessWidget {
  const StickerGridWidget({super.key, required this.onStickerSelected});
  final ValueChanged<String> onStickerSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: kStickers.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => onStickerSelected(kStickers[i]),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(kStickers[i], style: const TextStyle(fontSize: 22)),
          ),
        ),
      ),
    );
  }
}
