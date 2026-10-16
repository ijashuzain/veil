import 'package:flutter/material.dart';

const playerOverlayColor = Color(0xFF101415);
const playerAccent = Color(0xFFFFD34E);

class PlayerAction extends StatelessWidget {
  const PlayerAction({
    super.key,
    this.icon,
    this.text,
    required this.label,
    this.onTap,
    this.selected = false,
    this.color,
    this.size = 44,
    this.iconSize = 23,
    this.child,
  });
  final IconData? icon;
  final String? text;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final Color? color;
  final double size;
  final double iconSize;
  final Widget? child;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    enabled: onTap != null,
    child: MouseRegion(
      cursor: onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minWidth: size, minHeight: size),
          padding: EdgeInsets.symmetric(horizontal: size < 44 ? 6 : 10),
          alignment: Alignment.center,
          child:
              child ??
              (icon != null
                  ? Icon(
                      icon,
                      size: iconSize,
                      color:
                          color ??
                          (onTap == null
                              ? Colors.white30
                              : selected
                              ? playerAccent
                              : Colors.white),
                    )
                  : Text(
                      text ?? label,
                      style: TextStyle(
                        color: selected ? playerAccent : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    )),
        ),
      ),
    ),
  );
}

class PlayerSeekBar extends StatelessWidget {
  const PlayerSeekBar({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });
  final double value;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      double at(double x) => (x / box.maxWidth).clamp(0.0, 1.0) * max;
      final ratio = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
      var pending = value;
      return Semantics(
        label: 'Seek',
        value: '${(ratio * 100).round()} percent',
        increasedValue:
            '${(max > 0 ? ((value + 10000) / max * 100).clamp(0, 100) : 0).round()} percent',
        decreasedValue:
            '${(max > 0 ? ((value - 10000) / max * 100).clamp(0, 100) : 0).round()} percent',
        onIncrease: () => onChangeEnd((value + 10000).clamp(0.0, max)),
        onDecrease: () => onChangeEnd((value - 10000).clamp(0.0, max)),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (e) => onChangeEnd(at(e.localPosition.dx)),
          onHorizontalDragUpdate: (e) {
            pending = at(e.localPosition.dx);
            onChanged(pending);
          },
          onHorizontalDragEnd: (_) => onChangeEnd(pending),
          child: SizedBox(
            height: 32,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(height: 3, color: playerAccent),
                ),
                Positioned(
                  left: (ratio * (box.maxWidth - 14)).clamp(0.0, box.maxWidth),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: playerAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class PlayerPanelRow extends StatelessWidget {
  const PlayerPanelRow({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.child,
  });
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Widget? child;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    selected: selected,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: .08)
              : Colors.transparent,
          border: const Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            Expanded(
              child:
                  child ??
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? playerAccent : Colors.white,
                      fontSize: 13,
                    ),
                  ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, color: playerAccent, size: 17),
          ],
        ),
      ),
    ),
  );
}
