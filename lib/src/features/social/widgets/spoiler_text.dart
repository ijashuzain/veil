import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';

class SpoilerText extends StatefulWidget {
  const SpoilerText({
    super.key,
    required this.text,
    required this.isSpoiler,
    this.style,
    this.maxLines,
  });

  final String text;
  final bool isSpoiler;
  final TextStyle? style;
  final int? maxLines;

  @override
  State<SpoilerText> createState() => _SpoilerTextState();
}

class _SpoilerTextState extends State<SpoilerText> {
  var _revealed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isSpoiler || _revealed) {
      return Text(
        widget.text,
        maxLines: widget.maxLines,
        overflow: widget.maxLines == null ? null : TextOverflow.ellipsis,
        style: widget.style,
      );
    }

    return InkWell(
      onTap: () => setState(() => _revealed = true),
      borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: VeilColors.redSoft,
          borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
          border: Border.all(color: VeilColors.red.withValues(alpha: .38)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_off_rounded,
              color: VeilColors.gold,
              size: 17,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Spoiler hidden - tap to reveal',
                style: TextStyle(
                  color: VeilColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
