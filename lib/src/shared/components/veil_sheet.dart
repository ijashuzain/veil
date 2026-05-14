import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';

Future<T?> showVeilBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  Color backgroundColor = Colors.transparent,
  ShapeBorder? shape,
  Clip clipBehavior = Clip.none,
}) {
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, animation, _) {
      return _VeilBlurredBottomSheetRoute<T>(
        animation: animation,
        builder: builder,
        isScrollControlled: isScrollControlled,
        isDismissible: isDismissible,
        backgroundColor: backgroundColor,
        shape: shape,
        clipBehavior: clipBehavior,
      );
    },
  );
}

class _VeilBlurredBottomSheetRoute<T> extends StatelessWidget {
  const _VeilBlurredBottomSheetRoute({
    required this.animation,
    required this.builder,
    required this.isScrollControlled,
    required this.isDismissible,
    required this.backgroundColor,
    required this.shape,
    required this.clipBehavior,
  });

  final Animation<double> animation;
  final WidgetBuilder builder;
  final bool isScrollControlled;
  final bool isDismissible;
  final Color backgroundColor;
  final ShapeBorder? shape;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final heightLimit = MediaQuery.sizeOf(context).height * 9 / 16;
    Widget sheet = Material(
      type: backgroundColor == Colors.transparent && shape == null
          ? MaterialType.transparency
          : MaterialType.canvas,
      color: backgroundColor == Colors.transparent && shape == null
          ? null
          : backgroundColor,
      shape: shape,
      clipBehavior: clipBehavior,
      child: builder(context),
    );
    if (!isScrollControlled) {
      sheet = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: heightLimit),
        child: sheet,
      );
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isDismissible
                ? () => Navigator.of(context).maybePop()
                : null,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: const ColoredBox(color: Color(0x8A000000)),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .08),
                end: Offset.zero,
              ).animate(curved),
              child: sheet,
            ),
          ),
        ),
      ],
    );
  }
}

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
