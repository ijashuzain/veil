import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';

class DetailPlaybackServerSheet extends StatelessWidget {
  const DetailPlaybackServerSheet({
    super.key,
    required this.title,
    required this.year,
    required this.onServerOne,
    required this.onServerTwo,
  });

  final String title;
  final int year;
  final VoidCallback onServerOne;
  final VoidCallback onServerTwo;

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
              ],
            ),
          ),
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
