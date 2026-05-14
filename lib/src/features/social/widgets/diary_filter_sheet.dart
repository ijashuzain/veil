import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/shared/components/veil_filter_chips.dart';
import 'package:veil/src/shared/components/veil_sheet.dart';

enum DiarySortMode {
  recent('Recent'),
  highestRated('Highest rated'),
  lowestRated('Lowest rated'),
  az('A-Z'),
  year('Year');

  const DiarySortMode(this.label);

  final String label;
}

enum DiaryYearFilter {
  any('Any year'),
  from2024('2024+'),
  from2020('2020s'),
  from2010('2010s'),
  from2000('2000s'),
  older('Older');

  const DiaryYearFilter(this.label);

  final String label;

  bool matches(int year) {
    return switch (this) {
      DiaryYearFilter.any => true,
      DiaryYearFilter.from2024 => year >= 2024,
      DiaryYearFilter.from2020 => year >= 2020,
      DiaryYearFilter.from2010 => year >= 2010 && year < 2020,
      DiaryYearFilter.from2000 => year >= 2000 && year < 2010,
      DiaryYearFilter.older => year > 0 && year < 2000,
    };
  }
}

class DiaryFilterState {
  const DiaryFilterState({
    this.genre,
    this.minimumRating = 0,
    this.sortMode = DiarySortMode.recent,
    this.yearFilter = DiaryYearFilter.any,
  });

  final String? genre;
  final double minimumRating;
  final DiarySortMode sortMode;
  final DiaryYearFilter yearFilter;

  int get activeCount {
    return (genre == null ? 0 : 1) +
        (minimumRating <= 0 ? 0 : 1) +
        (sortMode == DiarySortMode.recent ? 0 : 1) +
        (yearFilter == DiaryYearFilter.any ? 0 : 1);
  }

  DiaryFilterState copyWith({
    String? genre,
    bool clearGenre = false,
    double? minimumRating,
    DiarySortMode? sortMode,
    DiaryYearFilter? yearFilter,
  }) {
    return DiaryFilterState(
      genre: clearGenre ? null : genre ?? this.genre,
      minimumRating: minimumRating ?? this.minimumRating,
      sortMode: sortMode ?? this.sortMode,
      yearFilter: yearFilter ?? this.yearFilter,
    );
  }
}

class DiaryFilterSheet extends StatefulWidget {
  const DiaryFilterSheet({
    super.key,
    required this.initial,
    required this.genres,
    required this.resultCountFor,
  });

  final DiaryFilterState initial;
  final List<String> genres;
  final int Function(DiaryFilterState filters) resultCountFor;

  @override
  State<DiaryFilterSheet> createState() => _DiaryFilterSheetState();
}

class _DiaryFilterSheetState extends State<DiaryFilterSheet> {
  late DiaryFilterState _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final resultCount = widget.resultCountFor(_draft);

    return VeilSheetScaffold(
      title: 'Filter & sort',
      leading: TextButton(
        onPressed: () => setState(() => _draft = const DiaryFilterState()),
        style: TextButton.styleFrom(
          foregroundColor: VeilColors.text3,
          padding: EdgeInsets.zero,
        ),
        child: const Text('Reset'),
      ),
      trailing: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close_rounded),
        color: VeilColors.text2,
        visualDensity: VisualDensity.compact,
      ),
      footer: SizedBox(
        width: double.infinity,
        child: FilledButton(
          key: const ValueKey('diary-filter-show-results'),
          onPressed: () => Navigator.of(context).pop(_draft),
          style: FilledButton.styleFrom(
            backgroundColor: VeilColors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text('Show $resultCount results'),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        children: [
          _SheetGroup(
            title: 'Sort by',
            icon: Icons.sort_rounded,
            children: [
              for (final sort in DiarySortMode.values)
                VeilChoiceChip(
                  label: sort.label,
                  selected: _draft.sortMode == sort,
                  onTap: () =>
                      setState(() => _draft = _draft.copyWith(sortMode: sort)),
                ),
            ],
          ),
          _SheetGroup(
            title: 'Minimum rating',
            children: [
              for (final rating in const [0.0, 2.0, 3.0, 4.0, 4.5])
                VeilChoiceChip(
                  key: ValueKey('diary-filter-rating-$rating'),
                  label: rating == 0
                      ? 'Any rating'
                      : '${rating.toStringAsFixed(1)}+',
                  selected: _draft.minimumRating == rating,
                  onTap: () => setState(
                    () => _draft = _draft.copyWith(minimumRating: rating),
                  ),
                ),
            ],
          ),
          _SheetGroup(
            title: 'Genre',
            children: [
              VeilChoiceChip(
                label: 'All genres',
                selected: _draft.genre == null,
                onTap: () =>
                    setState(() => _draft = _draft.copyWith(clearGenre: true)),
              ),
              for (final genre in widget.genres)
                VeilChoiceChip(
                  label: genre,
                  selected: _draft.genre == genre,
                  onTap: () =>
                      setState(() => _draft = _draft.copyWith(genre: genre)),
                ),
            ],
          ),
          _SheetGroup(
            title: 'Release year',
            children: [
              for (final filter in DiaryYearFilter.values)
                VeilChoiceChip(
                  label: filter.label,
                  selected: _draft.yearFilter == filter,
                  onTap: () => setState(
                    () => _draft = _draft.copyWith(yearFilter: filter),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetGroup extends StatelessWidget {
  const _SheetGroup({required this.title, required this.children, this.icon});

  final String title;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: VeilColors.hairline)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 15, color: VeilColors.text3),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      color: VeilColors.text3,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: children),
            ],
          ),
        ),
      ),
    );
  }
}
