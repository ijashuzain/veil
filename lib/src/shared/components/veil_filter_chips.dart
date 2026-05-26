import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';

class VeilChoiceChip extends StatelessWidget {
  const VeilChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.leadingIcon,
    this.compact = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? VeilColors.gold : VeilColors.text2;
    final borderColor = selected
        ? VeilColors.red.withValues(alpha: .58)
        : VeilColors.hairline;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
          child: Container(
            height: compact ? VeilTheme.chipHeight : 40,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 7 : 9,
            ),
            decoration: BoxDecoration(
              color: selected ? VeilColors.redSoft : VeilColors.panelRaised,
              borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
              border: Border.all(color: borderColor),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: VeilColors.red.withValues(alpha: .12),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leadingIcon != null || selected) ...[
                  Icon(
                    leadingIcon ?? Icons.check_rounded,
                    color: selected ? VeilColors.gold : VeilColors.text3,
                    size: compact ? 14 : 16,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
