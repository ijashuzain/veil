import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';

class VeilSheetScaffold extends StatelessWidget {
  const VeilSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.trailing,
    this.footer,
    this.maxHeightFactor = .86,
  });

  final String title;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final Widget? footer;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height * maxHeightFactor - 40)
        .clamp(360.0, double.infinity);

    return SafeArea(
      top: false,
      bottom: false,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: VeilColors.bg2,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(VeilTheme.sheetRadius),
            ),
            border: Border(top: BorderSide(color: VeilColors.hairline)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: VeilColors.bg4,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    SizedBox(width: 72, child: Align(child: leading)),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: VeilColors.text1,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: trailing,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: VeilColors.hairline),
              Expanded(child: child),
              if (footer != null) ...[
                const Divider(height: 1, color: VeilColors.hairline),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: footer,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
