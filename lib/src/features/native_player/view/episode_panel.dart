import 'package:flutter/material.dart';
import 'package:veil/src/features/native_player/repository/episode_repository.dart';
import 'package:veil/src/features/native_player/view/player_controls.dart';

class PlayerEpisodePanel extends StatefulWidget {
  const PlayerEpisodePanel({
    super.key,
    required this.repository,
    required this.seriesId,
    required this.season,
    required this.episode,
    required this.onSelect,
    required this.onClose,
  });
  final EpisodeRepository repository;
  final int seriesId;
  final int season;
  final int episode;
  final ValueChanged<PlayerEpisode> onSelect;
  final VoidCallback onClose;
  @override
  State<PlayerEpisodePanel> createState() => _PlayerEpisodePanelState();
}

class _PlayerEpisodePanelState extends State<PlayerEpisodePanel> {
  late int _season = widget.season;
  List<PlayerSeason> _seasons = [];
  List<PlayerEpisode> _episodes = [];
  bool _dropdown = false;
  bool _loading = true;
  bool _error = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() => _loading = true);
    try {
      if (_seasons.isEmpty) {
        try {
          _seasons = await widget.repository.seasons(widget.seriesId);
        } catch (_) {}
      }
      if (_seasons.isEmpty) {
        _seasons = [PlayerSeason(widget.season, widget.episode)];
      }
      final episodes = await widget.repository.episodes(
        widget.seriesId,
        _season,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _episodes = episodes;
        _loading = false;
        _error = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      final count =
          _seasons
              .where((s) => s.number == _season)
              .firstOrNull
              ?.episodeCount ??
          0;
      setState(() {
        _episodes = List.generate(
          count,
          (i) => PlayerEpisode(season: _season, number: i + 1),
        );
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: playerOverlayColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Episodes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            PlayerAction(
              icon: Icons.close,
              label: 'Close episodes',
              onTap: widget.onClose,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: GestureDetector(
            key: const ValueKey('native-season-dropdown'),
            onTap: () => setState(() => _dropdown = !_dropdown),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Season $_season',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Icon(
                    _dropdown ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_dropdown)
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final season in _seasons)
                  PlayerPanelRow(
                    key: ValueKey('native-season-${season.number}'),
                    label: 'Season ${season.number}',
                    selected: _season == season.number,
                    onTap: () {
                      setState(() {
                        _season = season.number;
                        _dropdown = false;
                      });
                      _load();
                    },
                  ),
              ],
            ),
          )
        else if (_loading)
          const Expanded(
            child: Center(
              child: Text(
                'Loading episodes…',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
          )
        else ...[
          if (_error)
            PlayerAction(
              text: 'Details unavailable · Retry',
              label: 'Retry episode details',
              onTap: _load,
            ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final episode in _episodes)
                  PlayerPanelRow(
                    key: ValueKey('native-episode-${episode.number}'),
                    label: episode.label,
                    selected:
                        episode.season == widget.season &&
                        episode.number == widget.episode,
                    onTap: () => widget.onSelect(episode),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (episode.name.trim().isNotEmpty &&
                                  episode.name.trim().toLowerCase() !=
                                      'episode ${episode.number}')
                                Text(
                                  'Episode ${episode.number}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              Text(
                                episode.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_episodes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No episode data available.',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
