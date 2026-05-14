import 'package:flutter/material.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/shared/components/poster_art.dart';
import 'package:veil/src/shared/components/ratings_display.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';

enum DiaryGridFooter { stars, year, favorite }

class DiaryPosterGrid extends StatelessWidget {
  const DiaryPosterGrid({
    super.key,
    required this.entries,
    required this.footer,
  });

  final List<SocialEntry> entries;
  final DiaryGridFooter footer;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: VeilLayout.pageGutter(context)),
      sliver: SliverGrid.builder(
        itemCount: entries.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: VeilLayout.diaryGridColumns(context),
          mainAxisSpacing: 15,
          crossAxisSpacing: VeilBreakpoint.of(context).isMobile ? 9 : 14,
          childAspectRatio: VeilBreakpoint.of(context).isDesktop ? .62 : .58,
        ),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return DiaryPosterGridTile(
            key: ValueKey('diary-entry-${entry.id}'),
            entry: entry,
            footer: footer,
          );
        },
      ),
    );
  }
}

class DiaryPosterGridTile extends StatelessWidget {
  const DiaryPosterGridTile({
    super.key,
    required this.entry,
    required this.footer,
  });

  final SocialEntry entry;
  final DiaryGridFooter footer;

  @override
  Widget build(BuildContext context) {
    final item = entry.toContentItem();
    return InkWell(
      onTap: () => DetailRoute(id: item.id, $extra: item).push(context),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: PosterArt(
              item: item,
              width: double.infinity,
              height: double.infinity,
              radius: 7,
              showTitle: false,
            ),
          ),
          const SizedBox(height: 5),
          _Footer(entry: entry, footer: footer),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.entry, required this.footer});

  final SocialEntry entry;
  final DiaryGridFooter footer;

  @override
  Widget build(BuildContext context) {
    return switch (footer) {
      DiaryGridFooter.stars => SizedBox(
        height: 14,
        child: Center(
          child: entry.rating <= 0
              ? const SizedBox.shrink()
              : VeilStarRating(rating: entry.rating, size: 13),
        ),
      ),
      DiaryGridFooter.year => SizedBox(
        height: 14,
        child: Text(
          '${entry.year}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: VeilColors.text3,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: .4,
          ),
        ),
      ),
      DiaryGridFooter.favorite => const SizedBox(
        height: 14,
        child: Icon(Icons.favorite_rounded, color: VeilColors.red, size: 12),
      ),
    };
  }
}
