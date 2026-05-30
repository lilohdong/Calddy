import 'package:flutter/material.dart';
import '../../../calendar/domain/entities/event_entity.dart';
import 'color_picker_row.dart';

class RangeBarWidget extends StatelessWidget {
  const RangeBarWidget({
    super.key,
    required this.event,
    required this.isStart,
    required this.isEnd,
  });

  final EventEntity event;
  final bool isStart;
  final bool isEnd;

  @override
  Widget build(BuildContext context) {
    final color = ColorPickerRow.fromHex(event.color);
    final textColor = color.computeLuminance() > 0.35 ? Colors.black87 : Colors.white;
    return Container(
      height: 16,
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.horizontal(
          left: isStart ? const Radius.circular(8) : Radius.zero,
          right: isEnd ? const Radius.circular(8) : Radius.zero,
        ),
      ),
      alignment: Alignment.centerLeft,
      padding: isStart ? const EdgeInsets.only(left: 6) : EdgeInsets.zero,
      child: isStart
          ? Text(
              event.title,
              style: TextStyle(
                fontSize: 9,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
    );
  }
}
