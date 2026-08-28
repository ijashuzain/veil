import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:veil/src/shared/components/ads/native_ad_list.dart';
import 'package:veil/src/shared/components/ads/native_template_ad.dart';

class NativeAdSliverGrid<T> extends StatelessWidget {
  const NativeAdSliverGrid({
    super.key,
    required this.items,
    required this.keyPrefix,
    required this.gridDelegate,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.adPadding = const EdgeInsets.symmetric(vertical: 20),
    this.gridKey,
  });

  final List<T> items;
  final String keyPrefix;
  final SliverGridDelegate gridDelegate;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry adPadding;
  final Key? gridKey;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final slivers = <Widget>[];
    for (var start = 0; start < items.length; start += NativeAdList.frequency) {
      final end = math.min(start + NativeAdList.frequency, items.length);
      slivers.add(
        SliverPadding(
          padding: padding,
          sliver: SliverGrid.builder(
            key: start == 0
                ? gridKey
                : ValueKey('$keyPrefix-grid-${start + 1}'),
            gridDelegate: gridDelegate,
            itemCount: end - start,
            itemBuilder: (context, chunkIndex) {
              final index = start + chunkIndex;
              return itemBuilder(context, items[index], index);
            },
          ),
        ),
      );
      if (end % NativeAdList.frequency == 0) {
        slivers.add(
          SliverToBoxAdapter(
            key: ValueKey('$keyPrefix-native-after-$end'),
            child: NativeTemplateAd(padding: adPadding),
          ),
        );
      }
    }

    return SliverMainAxisGroup(slivers: slivers);
  }
}
