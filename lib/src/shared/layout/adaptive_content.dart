import 'package:flutter/material.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';

class AdaptiveContent extends StatelessWidget {
  const AdaptiveContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? VeilLayout.contentMaxWidth(context),
        ),
        child: Padding(
          padding:
              padding ??
              EdgeInsets.symmetric(horizontal: VeilLayout.pageGutter(context)),
          child: child,
        ),
      ),
    );
  }
}

class AdaptiveSliverPadding extends StatelessWidget {
  const AdaptiveSliverPadding({
    super.key,
    required this.sliver,
    this.top = 0,
    this.bottom = 0,
  });

  final Widget sliver;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        VeilLayout.pageGutter(context),
        top,
        VeilLayout.pageGutter(context),
        bottom,
      ),
      sliver: sliver,
    );
  }
}
