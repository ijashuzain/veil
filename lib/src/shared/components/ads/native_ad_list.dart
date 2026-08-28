import 'package:flutter/material.dart';
import 'package:veil/src/shared/components/ads/native_template_ad.dart';

class NativeAdList<T> extends StatelessWidget {
  const NativeAdList({
    super.key,
    required this.items,
    required this.keyPrefix,
    required this.itemBuilder,
    this.adPadding = const EdgeInsets.symmetric(vertical: 18),
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  static const frequency = 12;

  final List<T> items;
  final String keyPrefix;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final EdgeInsetsGeometry adPadding;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          itemBuilder(context, items[index], index),
          if ((index + 1) % frequency == 0)
            NativeTemplateAd(
              key: ValueKey('$keyPrefix-native-after-${index + 1}'),
              padding: adPadding,
            ),
        ],
      ],
    );
  }
}
