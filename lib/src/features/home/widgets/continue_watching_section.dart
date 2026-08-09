import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/playback_history/models/playback_history_entry.dart';
import 'package:veil/src/shared/components/poster_art.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';

class ContinueWatchingSection extends StatelessWidget {
  const ContinueWatchingSection({
    super.key,
    required this.entries,
    required this.editing,
    required this.onPlay,
    required this.onRemove,
    required this.onToggleEditing,
  });

  final List<PlaybackHistoryEntry> entries;
  final bool editing;
  final ValueChanged<PlaybackHistoryEntry> onPlay;
  final ValueChanged<String> onRemove;
  final VoidCallback onToggleEditing;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: VeilLayout.pageGutter(context),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('Continue Watching', style: context.sectionTitle),
              ),
              IconButton(
                key: const ValueKey('continue-watching-edit'),
                tooltip: editing ? 'Done editing' : 'Edit Continue Watching',
                onPressed: onToggleEditing,
                icon: Icon(
                  editing ? Icons.check_rounded : Icons.edit_rounded,
                  size: 20,
                ),
                color: editing ? VeilColors.gold : VeilColors.text2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: VeilLayout.pageGutter(context),
            ),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _HistoryCard(
                entry: entry,
                editing: editing,
                onPlay: () => onPlay(entry),
                onRemove: () => onRemove(entry.entryKey),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.entry,
    required this.editing,
    required this.onPlay,
    required this.onRemove,
  });

  final PlaybackHistoryEntry entry;
  final bool editing;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final item = entry.toContentItem();
    final mediaType = entry.mediaType.toLowerCase();
    final type = entry.type.toLowerCase();
    final isTv =
        mediaType == 'tv' || type.contains('tv') || type.contains('series');

    return SizedBox(
      width: 204,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('continue-watching-card-${entry.entryKey}'),
              borderRadius: BorderRadius.circular(12),
              onTap: editing ? null : onPlay,
              child: Stack(
                children: [
                  BackdropArt(
                    item: item,
                    width: 204,
                    height: 116,
                    radius: 12,
                    child: editing
                        ? null
                        : Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .58),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const SizedBox.square(
                                dimension: 38,
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 21,
                                ),
                              ),
                            ),
                          ),
                  ),
                  if (editing)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IconButton(
                        key: ValueKey(
                          'continue-watching-remove-${entry.entryKey}',
                        ),
                        tooltip: 'Remove ${entry.title}',
                        onPressed: onRemove,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: .68),
                          minimumSize: const Size.square(34),
                          maximumSize: const Size.square(34),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isTv ? 'S${entry.season} · E${entry.episode}' : 'Recently started',
            style: const TextStyle(color: VeilColors.text3, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
