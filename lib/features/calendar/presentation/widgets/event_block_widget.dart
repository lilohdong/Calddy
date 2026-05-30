import 'package:flutter/material.dart';
import '../../../calendar/domain/entities/event_entity.dart';
import 'color_picker_row.dart';

class EventBlockWidget extends StatelessWidget {
  const EventBlockWidget({super.key, required this.event});
  final EventEntity event;

  // Returns black or white depending on background luminance
  static Color _contrastColor(Color bg) {
    return bg.computeLuminance() > 0.35 ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final color = ColorPickerRow.fromHex(event.color);
    final textColor = _contrastColor(color);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        event.title,
        style: TextStyle(
          fontSize: 9,
          color: textColor,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
