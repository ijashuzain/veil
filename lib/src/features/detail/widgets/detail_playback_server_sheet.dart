import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';

class DetailPlaybackServerSheet extends StatelessWidget {
  const DetailPlaybackServerSheet({
    super.key,
    required this.title,
    required this.year,
    required this.onServerOne,
    required this.onServerTwo,
    required this.onServerThree,
  });

  final String title;
  final int year;
  final VoidCallback onServerOne;
  final VoidCallback onServerTwo;
  final VoidCallback onServerThree;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DecoratedBox(
        key: const ValueKey('detail-playback-server-panel'),
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
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (year > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '$year',
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
                const SizedBox(height: 12),
                _ServerButton(
                  key: const ValueKey('playback-server-1'),
                  icon: Icons.play_circle_fill_rounded,
                  title: 'Server 1',
                  onTap: onServerOne,
                ),
                const SizedBox(height: 10),
                _ServerButton(
                  key: const ValueKey('playback-server-2'),
                  icon: Icons.connected_tv_rounded,
                  title: 'Server 2',
                  onTap: onServerTwo,
                ),
                const SizedBox(height: 10),
                _ServerButton(
                  key: const ValueKey('playback-server-3'),
                  icon: Icons.video_file_rounded,
                  title: 'Server 3',
                  onTap: onServerThree,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DetailEpisodeSelectionSheet extends StatefulWidget {
  const DetailEpisodeSelectionSheet({
    super.key,
    required this.title,
    required this.year,
    required this.seasons,
    required this.episodes,
    required this.onPlay,
  });

  final String title;
  final int year;
  final int seasons;
  final int episodes;
  final void Function(int season, int episode) onPlay;

  @override
  State<DetailEpisodeSelectionSheet> createState() =>
      _DetailEpisodeSelectionSheetState();
}

class _DetailEpisodeSelectionSheetState
    extends State<DetailEpisodeSelectionSheet> {
  var _season = 1;
  var _episode = 1;

  int? get _maxSeason => widget.seasons > 0 ? widget.seasons : null;
  int? get _maxEpisode => widget.episodes > 0 ? widget.episodes : null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DecoratedBox(
        key: const ValueKey('detail-season-episode-panel'),
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
                            widget.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (widget.year > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${widget.year}',
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
                const SizedBox(height: 16),
                _EpisodeStepper(
                  label: 'Season $_season',
                  decrementKey: const ValueKey('playback-season-decrement'),
                  incrementKey: const ValueKey('playback-season-increment'),
                  canDecrement: _season > 1,
                  canIncrement: _maxSeason == null || _season < _maxSeason!,
                  onDecrement: () => setState(() => _season--),
                  onIncrement: () => setState(() => _season++),
                ),
                const SizedBox(height: 10),
                _EpisodeStepper(
                  label: 'Episode $_episode',
                  decrementKey: const ValueKey('playback-episode-decrement'),
                  incrementKey: const ValueKey('playback-episode-increment'),
                  canDecrement: _episode > 1,
                  canIncrement: _maxEpisode == null || _episode < _maxEpisode!,
                  onDecrement: () => setState(() => _episode--),
                  onIncrement: () => setState(() => _episode++),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('playback-season-episode-play'),
                    onPressed: () => widget.onPlay(_season, _episode),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play episode'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodeStepper extends StatelessWidget {
  const _EpisodeStepper({
    required this.label,
    required this.decrementKey,
    required this.incrementKey,
    required this.canDecrement,
    required this.canIncrement,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final Key decrementKey;
  final Key incrementKey;
  final bool canDecrement;
  final bool canIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.panelRaised,
        borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              key: decrementKey,
              tooltip: 'Decrease',
              onPressed: canDecrement ? onDecrement : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              key: incrementKey,
              tooltip: 'Increase',
              onPressed: canIncrement ? onIncrement : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerButton extends StatelessWidget {
  const _ServerButton({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VeilColors.panelRaised,
      borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 38,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: VeilColors.bg3,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: VeilColors.red, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, color: VeilColors.text3),
            ],
          ),
        ),
      ),
    );
  }
}
