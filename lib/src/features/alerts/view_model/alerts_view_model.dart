import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/features/social/models/follow_request.dart';
import 'package:veil/src/features/social/models/movie_suggestion.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/shared/models/alert_item.dart';
import 'package:veil/src/shared/models/content_item.dart';

part 'alerts_view_model.freezed.dart';
part 'alerts_view_model.g.dart';

@freezed
abstract class AlertsViewState with _$AlertsViewState {
  const AlertsViewState._();

  const factory AlertsViewState({
    @Default([]) List<AlertItem> alerts,
    @Default([]) List<FollowRequest> followRequests,
    @Default([]) List<MovieSuggestion> suggestions,
    @Default(Status.initial()) Status loadStatus,
  }) = _AlertsViewState;

  factory AlertsViewState.initial() => const AlertsViewState();

  int get unreadCount => alerts.where((alert) => alert.unread).length;

  int get suggestionUnreadCount =>
      suggestions.where((suggestion) => suggestion.isUnread).length;
}

@riverpod
class AlertsViewModel extends _$AlertsViewModel {
  @override
  AlertsViewState build() {
    Future.microtask(load);
    return AlertsViewState.initial();
  }

  Future<void> load() async {
    if (state.loadStatus is StatusLoading) return;

    try {
      state = state.copyWith(loadStatus: const Status.loading());
      final repository = ref.read(tmdbRepositoryProvider);
      final socialRepository = ref.read(socialRepositoryProvider);
      final results = await Future.wait<List<ContentItem>>([
        repository.trending(),
        repository.upcomingMovies(),
        repository.airingTodayTv(),
        repository.topRatedMovies(),
        repository.popularMovies(),
      ]);
      final socialResults = await _loadSocialAlerts(socialRepository);

      state = state.copyWith(
        alerts: _buildAlerts(
          trending: results[0],
          upcoming: results[1],
          airingToday: results[2],
          topRated: results[3],
          popular: results[4],
        ),
        followRequests: socialResults.followRequests,
        suggestions: socialResults.suggestions,
        loadStatus: const Status.success(),
      );
    } catch (error) {
      state = state.copyWith(
        alerts: const [],
        loadStatus: Status.failure(error.toString()),
      );
    }
  }

  void markAllRead() {
    final unreadSuggestions = state.suggestions
        .where((suggestion) => suggestion.isUnread)
        .toList();
    state = state.copyWith(
      alerts: [for (final alert in state.alerts) alert.copyWith(unread: false)],
      suggestions: [
        for (final suggestion in state.suggestions)
          suggestion.copyWith(readAt: suggestion.readAt ?? DateTime.now()),
      ],
    );
    final repository = ref.read(socialRepositoryProvider);
    for (final suggestion in unreadSuggestions) {
      unawaited(repository.markMovieSuggestionRead(suggestion.id));
    }
  }

  Future<void> markSuggestionRead(String suggestionId) async {
    final repository = ref.read(socialRepositoryProvider);
    await repository.markMovieSuggestionRead(suggestionId);
    state = state.copyWith(
      suggestions: [
        for (final suggestion in state.suggestions)
          suggestion.id == suggestionId
              ? suggestion.copyWith(readAt: DateTime.now())
              : suggestion,
      ],
    );
  }

  Future<void> acceptFollowRequest(String requestId) async {
    await ref.read(socialRepositoryProvider).acceptFollowRequest(requestId);
    await load();
  }

  Future<void> declineFollowRequest(String requestId) async {
    await ref.read(socialRepositoryProvider).declineFollowRequest(requestId);
    await load();
  }

  Future<_SocialAlertsResult> _loadSocialAlerts(
    SocialRepository repository,
  ) async {
    try {
      final results = await Future.wait<Object>([
        repository.followRequestsForAlerts(),
        repository.movieSuggestions(),
      ]);
      return _SocialAlertsResult(
        followRequests: results[0] as List<FollowRequest>,
        suggestions: results[1] as List<MovieSuggestion>,
      );
    } catch (_) {
      return const _SocialAlertsResult();
    }
  }

  List<AlertItem> _buildAlerts({
    required List<ContentItem> trending,
    required List<ContentItem> upcoming,
    required List<ContentItem> airingToday,
    required List<ContentItem> topRated,
    required List<ContentItem> popular,
  }) {
    final alerts = <AlertItem>[];
    final usedIds = <String>{};

    for (final item in trending.take(2)) {
      _addAlert(
        alerts,
        usedIds,
        item,
        tag: 'TRENDING',
        title: '${item.title} is climbing the global chart',
        time: 'Now',
      );
    }

    _addFirst(
      alerts,
      usedIds,
      upcoming,
      tag: 'COMING SOON',
      title: (item) => '${item.title} is coming soon',
      time: 'This week',
    );

    _addFirst(
      alerts,
      usedIds,
      airingToday,
      tag: 'NEW EPISODE',
      title: (item) => '${item.title} has a fresh episode today',
      time: 'Today',
    );

    _addFirst(
      alerts,
      usedIds,
      topRated,
      tag: 'CRITICS PICK',
      title: (item) => '${item.title} is one of the top rated picks',
      time: 'Updated today',
    );

    if (alerts.length < 5) {
      _addFirst(
        alerts,
        usedIds,
        popular,
        tag: 'POPULAR',
        title: (item) => '${item.title} is popular with viewers',
        time: 'Updated today',
      );
    }

    return alerts;
  }

  void _addFirst(
    List<AlertItem> alerts,
    Set<String> usedIds,
    List<ContentItem> items, {
    required String tag,
    required String Function(ContentItem item) title,
    required String time,
  }) {
    final item = items.where((item) => !usedIds.contains(item.id)).firstOrNull;
    if (item == null) return;
    _addAlert(alerts, usedIds, item, tag: tag, title: title(item), time: time);
  }

  void _addAlert(
    List<AlertItem> alerts,
    Set<String> usedIds,
    ContentItem item, {
    required String tag,
    required String title,
    required String time,
  }) {
    if (!usedIds.add(item.id)) return;

    alerts.add(
      AlertItem(
        content: item,
        tag: tag,
        title: title,
        time: time,
        unread: true,
      ),
    );
  }
}

class _SocialAlertsResult {
  const _SocialAlertsResult({
    this.followRequests = const [],
    this.suggestions = const [],
  });

  final List<FollowRequest> followRequests;
  final List<MovieSuggestion> suggestions;
}
