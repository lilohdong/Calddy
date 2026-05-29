import 'package:flutter/material.dart';
import '../../../calendar/domain/entities/event_entity.dart';
import 'color_picker_row.dart';

class EventBlockWidget extends StatelessWidget {
  const EventBlockWidget({super.key, required this.event});
  final EventEntity event;

  @override
  Widget build(BuildContext context) {
    final color = ColorPickerRow.fromHex(event.color);
    final timeStr =
        '${event.startAt.hour.toString().padLeft(2, '0')}:${event.startAt.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.white,
              height: 1.1,
            ),
            maxLines: 1,
          ),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
