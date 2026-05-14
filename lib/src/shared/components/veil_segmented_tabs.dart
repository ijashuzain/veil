import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';

class VeilSegment<T> {
  const VeilSegment({required this.value, required this.label});

  final T value;
  final String label;
}

class VeilSegmentedTabs<T> extends StatelessWidget {
  const VeilSegmentedTabs({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<VeilSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: VeilColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: Row(
        children: [
          for (final segment in segments)
            Expanded(
              child: _VeilSegmentButton(
                label: segment.label,
                selected: selected == segment.value,
                onTap: () => onChanged(segment.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _VeilSegmentButton extends StatelessWidget {
  const _VeilSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: BoxConstraints.tightFor(height: 34),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? VeilColors.panelRaised : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected
                ? VeilColors.red.withValues(alpha: .48)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? Colors.white : VeilColors.text2,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
