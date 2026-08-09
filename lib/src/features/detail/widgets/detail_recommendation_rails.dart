import 'package:flutter/material.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/shared/components/content_cards.dart';
import 'package:veil/src/shared/models/content_item.dart';

class DetailRecommendationRails extends StatelessWidget {
  const DetailRecommendationRails({
    super.key,
    required this.recommendations,
    required this.similar,
    this.currentItem,
  });

  final List<ContentItem> recommendations;
  final List<ContentItem> similar;
  final ContentItem? currentItem;

  @override
  Widget build(BuildContext context) {
    final visibleRecommendations = recommendations
        .where((item) => !_isCurrentItem(item))
        .toList();
    final seenSimilar = visibleRecommendations.map(_mediaIdentity).toSet();
    final uniqueSimilar = <ContentItem>[];
    for (final item in similar) {
      if (_isCurrentItem(item)) continue;
      if (seenSimilar.add(_mediaIdentity(item))) uniqueSimilar.add(item);
    }

    if (visibleRecommendations.isEmpty && uniqueSimilar.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (visibleRecommendations.isNotEmpty)
            _RecommendationRail(
              title: 'Recommended for you',
              railKey: const ValueKey('detail-recommendations-rail'),
              items: visibleRecommendations,
            ),
          if (visibleRecommendations.isNotEmpty && uniqueSimilar.isNotEmpty)
            const SizedBox(height: 28),
          if (uniqueSimilar.isNotEmpty)
            _RecommendationRail(
              title: 'More like this',
              railKey: const ValueKey('detail-similar-rail'),
              items: uniqueSimilar,
            ),
        ],
      ),
    );
  }

  bool _isCurrentItem(ContentItem item) {
    final current = currentItem;
    if (current == null) return false;

    final sameIdentity =
        item.remoteId != null &&
        current.remoteId != null &&
        _mediaIdentity(item) == _mediaIdentity(current);
    final sameTitle =
        item.title.trim().toLowerCase() == current.title.trim().toLowerCase();
    return sameIdentity || sameTitle;
  }
}

String _mediaIdentity(ContentItem item) {
  return '${item.mediaType}:${item.remoteId}';
}

class _RecommendationRail extends StatelessWidget {
  const _RecommendationRail({
    required this.title,
    required this.railKey,
    required this.items,
  });

  final String title;
  final Key railKey;
  final List<ContentItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.sectionTitle),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.separated(
            key: railKey,
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return PosterCard(
                key: ValueKey('$railKey-${item.id}'),
                item: item,
                onTap: () =>
                    DetailRoute(id: item.id, $extra: item).push(context),
              );
            },
          ),
        ),
      ],
    );
  }
}
