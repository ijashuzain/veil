import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/shared/models/content_item.dart';
import 'package:veil/src/shared/utils/veil_rating.dart';

typedef DetailReviewSave =
    Future<void> Function({
      required double rating,
      required String review,
      required List<String> tags,
    });

const detailWatchKindTags = {'first-time', 'rewatch'};

List<String> buildDetailReviewTags(String watchKind, String rawTags) {
  final tags = <String>[watchKind];
  for (final part in rawTags.split(',')) {
    final tag = part.trim();
    if (tag.isEmpty || detailWatchKindTags.contains(tag)) continue;
    if (!tags.contains(tag)) tags.add(tag);
  }
  return tags;
}

class DetailReviewSheet extends StatefulWidget {
  const DetailReviewSheet({
    super.key,
    required this.item,
    required this.initialRating,
    required this.initialWatchTag,
    required this.onSave,
  });

  final ContentItem item;
  final double initialRating;
  final String initialWatchTag;
  final DetailReviewSave onSave;

  @override
  State<DetailReviewSheet> createState() => _DetailReviewSheetState();
}

class _DetailReviewSheetState extends State<DetailReviewSheet> {
  late final TextEditingController _reviewController;
  late final TextEditingController _tagController;
  late double _rating;
  late String _watchTag;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController();
    _tagController = TextEditingController();
    _rating = widget.initialRating;
    _watchTag = widget.initialWatchTag;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave =
        !_saving && _rating >= .5 && _reviewController.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DecoratedBox(
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const Expanded(
                      child: Text(
                        'I Watched...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('detail-review-save'),
                      onPressed: canSave ? _save : null,
                      child: Text(_saving ? 'Saving' : 'Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MovieRow(item: widget.item),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: VeilColors.text3,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Today',
                      style: TextStyle(color: VeilColors.text2),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Like',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {},
                      icon: const Icon(
                        Icons.favorite_border_rounded,
                        color: VeilColors.text3,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: VeilColors.hairline),
                Row(
                  children: [
                    const SizedBox(
                      width: 78,
                      child: Text(
                        'Rate',
                        style: TextStyle(
                          color: VeilColors.text2,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: DetailStarRatingSelector(
                        rating: _rating,
                        size: 30,
                        onChanged: (value) => setState(() => _rating = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DetailWatchKindToggle(
                  value: _watchTag,
                  onChanged: (value) => setState(() => _watchTag = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tagController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Tags, comma separated'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reviewController,
                  onChanged: (_) => setState(() {}),
                  minLines: 5,
                  maxLines: 8,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Add review...'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: VeilColors.text3),
      filled: true,
      fillColor: VeilColors.panelRaised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
        borderSide: const BorderSide(color: VeilColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
        borderSide: const BorderSide(color: VeilColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
        borderSide: const BorderSide(color: VeilColors.red),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(
      rating: _rating,
      review: _reviewController.text.trim(),
      tags: buildDetailReviewTags(_watchTag, _tagController.text),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

class _MovieRow extends StatelessWidget {
  const _MovieRow({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 60,
          decoration: BoxDecoration(
            color: VeilColors.panelRaised,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: VeilColors.hairline),
          ),
          child: const Icon(Icons.movie_filter_rounded, color: VeilColors.red),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                [
                  if (item.year > 0) '${item.year}',
                  item.genre,
                ].where((part) => part.isNotEmpty).join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: VeilColors.text3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DetailStarRatingSelector extends StatelessWidget {
  const DetailStarRatingSelector({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 30,
  });

  final double rating;
  final ValueChanged<double> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: normalizeVeilRating(rating, allowUnrated: true),
      minRating: .5,
      maxRating: 5,
      allowHalfRating: true,
      glow: false,
      itemCount: 5,
      itemSize: size,
      unratedColor: VeilColors.bg4,
      itemBuilder: (context, _) =>
          const Icon(Icons.star_rounded, color: VeilColors.gold),
      onRatingUpdate: onChanged,
    );
  }
}

class DetailWatchKindToggle extends StatelessWidget {
  const DetailWatchKindToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: 'first-time',
          icon: Icon(Icons.visibility_outlined),
          label: Text('First-time watch'),
        ),
        ButtonSegment(
          value: 'rewatch',
          icon: Icon(Icons.replay_rounded),
          label: Text('Rewatch'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (values) => onChanged(values.single),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : VeilColors.text3,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? VeilColors.panelRaised
              : VeilColors.panel,
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? VeilColors.red.withValues(alpha: .46)
                : VeilColors.hairline,
          ),
        ),
        iconColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? VeilColors.red
              : VeilColors.text3,
        ),
      ),
    );
  }
}
