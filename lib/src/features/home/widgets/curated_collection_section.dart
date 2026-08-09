import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/catalog/models/curated_collection.dart';
import 'package:veil/src/features/catalog/view_model/curated_collection_providers.dart';
import 'package:veil/src/shared/components/content_cards.dart';
import 'package:veil/src/shared/components/skeleton.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';
import 'package:veil/src/shared/models/content_item.dart';

class CuratedCollectionSection extends ConsumerStatefulWidget {
  const CuratedCollectionSection({super.key});

  @override
  ConsumerState<CuratedCollectionSection> createState() =>
      _CuratedCollectionSectionState();
}

class _CuratedCollectionSectionState
    extends ConsumerState<CuratedCollectionSection> {
  String? _selectedId;
  String? _requestedId;
  List<ContentItem>? _displayedItems;

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(curatedCollectionsProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: collections.when(
        data: (choices) {
          if (choices.isEmpty) {
            return const SizedBox.shrink();
          }

          final selected = _selectedCollection(choices);
          _requestedId = selected.id;
          final items = ref.watch(curatedCollectionItemsProvider(selected.id));
          final successfulItems = switch (items) {
            AsyncData(:final value) => value,
            _ => null,
          };
          final displayedItems = successfulItems ?? _displayedItems;
          if (successfulItems != null) {
            _rememberSuccessfulItems(selected.id, successfulItems);
          }
          return _CuratedContent(
            choices: choices,
            selected: selected,
            displayedItems: displayedItems,
            items: items,
            onSelect: (id) => setState(() => _selectedId = id),
            onRetry: () =>
                ref.invalidate(curatedCollectionItemsProvider(selected.id)),
          );
        },
        loading: () => const _CuratedLoading(),
        error: (_, _) => _CuratedError(
          onRetry: () => ref.invalidate(curatedCollectionsProvider),
        ),
      ),
    );
  }

  CuratedCollection _selectedCollection(List<CuratedCollection> choices) {
    final selectedId = _selectedId;
    if (selectedId != null) {
      for (final collection in choices) {
        if (collection.id == selectedId) return collection;
      }
    }
    return choices.first;
  }

  void _rememberSuccessfulItems(String collectionId, List<ContentItem> items) {
    if (identical(_displayedItems, items)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _requestedId != collectionId) return;
      if (identical(_displayedItems, items)) return;
      setState(() => _displayedItems = items);
    });
  }
}

class _CuratedContent extends StatelessWidget {
  const _CuratedContent({
    required this.choices,
    required this.selected,
    required this.displayedItems,
    required this.items,
    required this.onSelect,
    required this.onRetry,
  });

  final List<CuratedCollection> choices;
  final CuratedCollection selected;
  final List<ContentItem>? displayedItems;
  final AsyncValue<List<ContentItem>> items;
  final ValueChanged<String> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final visibleItems = displayedItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          key: const ValueKey('curated-collection-choices'),
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: VeilLayout.pageGutter(context),
          ),
          child: Row(
            children: [
              for (final choice in choices)
                Padding(
                  padding: const EdgeInsets.only(right: 9),
                  child: ChoiceChip(
                    key: ValueKey('curated-collection-choice-${choice.id}'),
                    label: Text(choice.title),
                    selected: choice.id == selected.id,
                    onSelected: (_) => onSelect(choice.id),
                    selectedColor: Colors.white,
                    backgroundColor: VeilColors.panelRaised,
                    side: BorderSide(
                      color: choice.id == selected.id
                          ? Colors.white
                          : VeilColors.hairline,
                    ),
                    labelStyle: TextStyle(
                      color: choice.id == selected.id
                          ? Colors.black
                          : VeilColors.text2,
                      fontWeight: FontWeight.w800,
                    ),
                    showCheckmark: false,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (items.isLoading && visibleItems != null)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: VeilLayout.pageGutter(context),
            ),
            child: const LinearProgressIndicator(
              minHeight: 2,
              color: VeilColors.gold,
              backgroundColor: VeilColors.hairline,
            ),
          ),
        if (items.hasError && visibleItems != null)
          _CuratedError(onRetry: onRetry),
        if (visibleItems != null)
          if (visibleItems.isEmpty)
            const _CuratedEmpty()
          else
            _CuratedPosterRail(items: visibleItems)
        else
          items.when(
            data: (titles) {
              if (titles.isEmpty) return const _CuratedEmpty();
              return _CuratedPosterRail(items: titles);
            },
            loading: () => const _CuratedLoading(),
            error: (_, _) => _CuratedError(onRetry: onRetry),
          ),
      ],
    );
  }
}

class _CuratedPosterRail extends StatelessWidget {
  const _CuratedPosterRail({required this.items});

  final List<ContentItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        key: const ValueKey('curated-collection-items'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: VeilLayout.pageGutter(context),
        ),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return PosterCard(
            key: ValueKey('curated-collection-item-${item.id}'),
            item: item,
            onTap: () => DetailRoute(id: item.id, $extra: item).push(context),
          );
        },
      ),
    );
  }
}

class _CuratedLoading extends StatelessWidget {
  const _CuratedLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 206,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: VeilLayout.pageGutter(context),
        ),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) =>
            const SkeletonBox(width: 124, height: 206, radius: 14),
      ),
    );
  }
}

class _CuratedError extends StatelessWidget {
  const _CuratedError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: VeilLayout.pageGutter(context)),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Unable to load this collection.',
              style: TextStyle(color: VeilColors.text3),
            ),
          ),
          TextButton.icon(
            key: const ValueKey('curated-collection-retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _CuratedEmpty extends StatelessWidget {
  const _CuratedEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: VeilLayout.pageGutter(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'No curated titles available.',
            style: TextStyle(color: VeilColors.text3),
          ),
        ],
      ),
    );
  }
}
