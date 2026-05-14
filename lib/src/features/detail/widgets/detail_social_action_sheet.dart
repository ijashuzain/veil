import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/detail/widgets/detail_review_sheet.dart';
import 'package:veil/src/shared/models/content_item.dart';

typedef DetailSetWatched =
    Future<void> Function({required bool watched, required double rating});
typedef DetailSetWatchlist = Future<void> Function({required bool inWatchlist});
typedef DetailRate = Future<void> Function({required double rating});
typedef DetailReviewOpen = void Function({required double rating});
typedef DetailSuggestOpen = void Function();

class DetailSocialActionSheet extends StatefulWidget {
  const DetailSocialActionSheet({
    super.key,
    required this.item,
    required this.isWatched,
    required this.isFavorite,
    required this.isInWatchlist,
    required this.rating,
    required this.onSetWatched,
    required this.onToggleFavorite,
    required this.onSetWatchlist,
    required this.onRate,
    required this.onOpenReview,
    required this.onOpenSuggest,
  });

  final ContentItem item;
  final bool isWatched;
  final bool isFavorite;
  final bool isInWatchlist;
  final double rating;
  final DetailSetWatched onSetWatched;
  final Future<void> Function() onToggleFavorite;
  final DetailSetWatchlist onSetWatchlist;
  final DetailRate onRate;
  final DetailReviewOpen onOpenReview;
  final DetailSuggestOpen onOpenSuggest;

  @override
  State<DetailSocialActionSheet> createState() =>
      _DetailSocialActionSheetState();
}

class _DetailSocialActionSheetState extends State<DetailSocialActionSheet> {
  late bool _watched;
  late bool _favorite;
  late bool _watchlist;
  late double _selectedRating;

  @override
  void initState() {
    super.initState();
    _watched = widget.isWatched;
    _favorite = widget.isFavorite;
    _watchlist = widget.isInWatchlist;
    _selectedRating = widget.rating.roundToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DecoratedBox(
        key: const ValueKey('detail-social-action-panel'),
        decoration: const BoxDecoration(
          color: VeilColors.panel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          border: Border(top: BorderSide(color: VeilColors.hairline)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: VeilColors.hairlineStrong,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            widget.item.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (widget.item.year > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${widget.item.year}',
                              style: const TextStyle(
                                color: VeilColors.text3,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SheetActionButton(
                        icon: Icons.visibility_outlined,
                        label: 'Watched',
                        selected: _watched,
                        onTap: _toggleWatched,
                      ),
                    ),
                    Expanded(
                      child: _SheetActionButton(
                        icon: Icons.favorite_border_rounded,
                        selectedIcon: Icons.favorite_rounded,
                        label: 'Favorite',
                        selected: _favorite,
                        onTap: _toggleFavorite,
                      ),
                    ),
                    Expanded(
                      child: _SheetActionButton(
                        icon: Icons.watch_later_outlined,
                        selectedIcon: Icons.watch_later_rounded,
                        label: 'Watchlist',
                        selected: _watchlist,
                        onTap: _toggleWatchlist,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 26, color: VeilColors.hairline),
                const Text(
                  'Rate',
                  style: TextStyle(
                    color: VeilColors.text2,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                DetailStarRatingSelector(
                  rating: _selectedRating,
                  size: 38,
                  onChanged: _rate,
                ),
                const Divider(height: 30, color: VeilColors.hairline),
                _SheetRowButton(
                  label: 'Review',
                  onTap: () => widget.onOpenReview(rating: _selectedRating),
                ),
                _SheetRowButton(label: 'Suggest', onTap: widget.onOpenSuggest),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleWatched() async {
    final next = !_watched;
    setState(() {
      _watched = next;
      if (next) {
        _watchlist = false;
      } else {
        _selectedRating = 0;
      }
    });
    await widget.onSetWatched(watched: next, rating: _selectedRating);
  }

  Future<void> _toggleFavorite() async {
    setState(() => _favorite = !_favorite);
    await widget.onToggleFavorite();
  }

  Future<void> _toggleWatchlist() async {
    final next = !_watchlist;
    setState(() {
      _watchlist = next;
      if (next) {
        _watched = false;
        _selectedRating = 0;
      }
    });
    await widget.onSetWatchlist(inWatchlist: next);
  }

  Future<void> _rate(double value) async {
    setState(() {
      _selectedRating = value;
      _watched = true;
      _watchlist = false;
    });
    await widget.onRate(rating: value);
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? VeilColors.panelRaised : Colors.transparent,
          borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
          border: Border.all(
            color: selected
                ? VeilColors.red.withValues(alpha: .34)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? selectedIcon ?? icon : icon,
              color: selected ? VeilColors.red : VeilColors.text2,
              size: 30,
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : VeilColors.text2,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetRowButton extends StatelessWidget {
  const _SheetRowButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: VeilColors.text2,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
