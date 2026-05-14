import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/alerts/view_model/alerts_view_model.dart';
import 'package:veil/src/features/social/models/follow_request.dart';
import 'package:veil/src/features/social/models/movie_suggestion.dart';
import 'package:veil/src/shared/components/poster_art.dart';
import 'package:veil/src/shared/models/alert_item.dart';
import 'package:veil/src/shared/layout/adaptive_content.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';

class AlertsView extends ConsumerStatefulWidget {
  const AlertsView({super.key, this.showBack = false});

  final bool showBack;

  @override
  ConsumerState<AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends ConsumerState<AlertsView> {
  var _tab = _AlertsTab.alerts;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(alertsViewModelProvider);
    final unread = state.unreadCount;
    final alerts = state.alerts;
    final followRequests = state.followRequests;
    final suggestions = state.suggestions;
    final isLoading = state.loadStatus is StatusLoading;
    final error = state.loadStatus.errorMessage;
    final hasAnyContent =
        alerts.isNotEmpty ||
        followRequests.isNotEmpty ||
        suggestions.isNotEmpty;
    final subtitle = state.suggestionUnreadCount == 0
        ? '$unread new from TMDB'
        : '$unread new from TMDB · ${state.suggestionUnreadCount} suggestions';

    return Scaffold(
      backgroundColor: VeilColors.bg1,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          0,
          VeilLayout.pageTopPadding(context),
          0,
          28,
        ),
        child: AdaptiveContent(
          maxWidth: VeilLayout.readableMaxWidth(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.showBack) ...[
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alerts',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: VeilColors.text3,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: unread == 0
                        ? null
                        : () => ref
                              .read(alertsViewModelProvider.notifier)
                              .markAllRead(),
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark read'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _AlertsTabs(
                selected: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
              ),
              const SizedBox(height: 14),
              if (isLoading && !hasAnyContent)
                const _AlertsSkeleton()
              else if (error.isNotEmpty && !hasAnyContent)
                _AlertsMessage(
                  title: 'Unable to load alerts.',
                  message: error,
                  actionLabel: 'Retry',
                  onAction: () =>
                      ref.read(alertsViewModelProvider.notifier).load(),
                )
              else if (_tab == _AlertsTab.alerts &&
                  alerts.isEmpty &&
                  followRequests.isEmpty)
                _AlertsMessage(
                  title: 'No alerts right now.',
                  message:
                      'New releases, episodes, and trending updates will appear here.',
                  actionLabel: 'Refresh',
                  onAction: () =>
                      ref.read(alertsViewModelProvider.notifier).load(),
                )
              else if (_tab == _AlertsTab.suggestions && suggestions.isEmpty)
                _AlertsMessage(
                  title: 'No suggestions yet.',
                  message:
                      'Movies and shows suggested by friends will appear here.',
                  actionLabel: 'Refresh',
                  onAction: () =>
                      ref.read(alertsViewModelProvider.notifier).load(),
                )
              else if (_tab == _AlertsTab.alerts) ...[
                for (final request in followRequests)
                  _FollowRequestTile(request: request),
                for (final alert in alerts) _TmdbAlertTile(alert: alert),
              ] else
                for (final suggestion in suggestions)
                  _SuggestionTile(suggestion: suggestion),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AlertsTab {
  alerts('Alert'),
  suggestions('Suggestions');

  const _AlertsTab(this.label);

  final String label;
}

class _AlertsTabs extends StatelessWidget {
  const _AlertsTabs({required this.selected, required this.onChanged});

  final _AlertsTab selected;
  final ValueChanged<_AlertsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.bg2,
        borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: Row(
        children: [
          for (final tab in _AlertsTab.values)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(tab),
                borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: selected == tab ? VeilColors.panelRaised : null,
                    borderRadius: BorderRadius.circular(
                      VeilTheme.controlRadius,
                    ),
                  ),
                  child: Text(
                    tab.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected == tab ? Colors.white : VeilColors.text3,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FollowRequestTile extends ConsumerWidget {
  const _FollowRequestTile({required this.request});

  final FollowRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = request.status == FollowRequestStatus.pending;
    final name = request.requesterDisplayName.trim().isEmpty
        ? _displayName(request.requesterId)
        : request.requesterDisplayName.trim();
    final acceptedName = request.recipientDisplayName.trim().isEmpty
        ? _displayName(request.recipientId)
        : request.recipientDisplayName.trim();
    final title = isPending
        ? '$name sent you a follow request'
        : '$acceptedName accepted your follow request';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VeilColors.bg2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: VeilColors.red.withValues(alpha: .18),
            foregroundColor: Colors.white,
            child: const Icon(Icons.person_add_alt_1_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FOLLOW',
                  style: TextStyle(
                    color: VeilColors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .9,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.32,
                  ),
                ),
              ],
            ),
          ),
          if (isPending) ...[
            TextButton(
              onPressed: () => ref
                  .read(alertsViewModelProvider.notifier)
                  .declineFollowRequest(request.id),
              child: const Text('Decline'),
            ),
            FilledButton(
              onPressed: () => ref
                  .read(alertsViewModelProvider.notifier)
                  .acceptFollowRequest(request.id),
              style: FilledButton.styleFrom(backgroundColor: VeilColors.red),
              child: const Text('Accept'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionTile extends ConsumerWidget {
  const _SuggestionTile({required this.suggestion});

  final MovieSuggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = suggestion.content;
    final sender = suggestion.senderDisplayName.trim().isEmpty
        ? _displayName(suggestion.senderId)
        : suggestion.senderDisplayName.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          await ref
              .read(alertsViewModelProvider.notifier)
              .markSuggestionRead(suggestion.id);
          if (!context.mounted) return;
          DetailRoute(id: item.id, $extra: item).push(context);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: suggestion.isUnread
                ? VeilColors.red.withValues(alpha: .07)
                : VeilColors.bg2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: suggestion.isUnread
                  ? VeilColors.red.withValues(alpha: .18)
                  : VeilColors.hairline,
            ),
          ),
          child: Row(
            children: [
              PosterArt(
                item: item,
                width: 48,
                height: 70,
                radius: 6,
                showTitle: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SUGGESTION',
                      style: TextStyle(
                        color: VeilColors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .9,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$sender suggested ${item.title} for you',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.32,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.metadata,
                      style: const TextStyle(
                        color: VeilColors.text3,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (suggestion.isUnread)
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: VeilColors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TmdbAlertTile extends StatelessWidget {
  const _TmdbAlertTile({required this.alert});

  final AlertItem alert;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => DetailRoute(
          id: alert.content.id,
          $extra: alert.content,
        ).push(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: alert.unread
                ? VeilColors.red.withValues(alpha: .07)
                : VeilColors.bg2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: alert.unread
                  ? VeilColors.red.withValues(alpha: .18)
                  : VeilColors.hairline,
            ),
          ),
          child: Row(
            children: [
              PosterArt(
                item: alert.content,
                width: 56,
                height: 80,
                radius: 6,
                showTitle: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.tag,
                      style: const TextStyle(
                        color: VeilColors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .9,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.32,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.time,
                      style: const TextStyle(
                        color: VeilColors.text3,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (alert.unread)
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: VeilColors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _displayName(String userId) {
  final count = userId.length < 8 ? userId.length : 8;
  return '@${userId.substring(0, count)}';
}

class _AlertsSkeleton extends StatelessWidget {
  const _AlertsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < 4; index++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 104,
            decoration: BoxDecoration(
              color: VeilColors.bg2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: VeilColors.hairline),
            ),
          ),
      ],
    );
  }
}

class _AlertsMessage extends StatelessWidget {
  const _AlertsMessage({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VeilColors.bg2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: VeilColors.text3, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
