import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veil/src/core/config/app_environment.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/auth/utils/auth_display_name.dart';
import 'package:veil/src/features/auth/view_model/auth_view_model/auth_view_model.dart';
import 'package:veil/src/features/auth/view_model/premium_view_model/premium_view_model.dart';
import 'package:veil/src/features/catalog/models/content_detail/content_detail.dart';
import 'package:veil/src/features/detail/utils/playback_entry_url.dart';
import 'package:veil/src/features/detail/view_model/detail_view_model/detail_view_model.dart';
import 'package:veil/src/features/detail/widgets/detail_playback_server_sheet.dart';
import 'package:veil/src/features/detail/widgets/detail_rating_panel.dart';
import 'package:veil/src/features/detail/widgets/detail_review_sheet.dart';
import 'package:veil/src/features/detail/widgets/detail_suggestion_sheet.dart';
import 'package:veil/src/features/detail/widgets/detail_social_action_sheet.dart';
import 'package:veil/src/features/embeded_player/utils/compact_web_player_policy.dart';
import 'package:veil/src/features/embeded_player/utils/direct_stream_availability.dart';
import 'package:veil/src/features/embeded_player/utils/external_player_launcher.dart';
import 'package:veil/src/features/embeded_player/utils/redirect_url_extractor.dart';
import 'package:veil/src/features/embeded_player/view/direct_video_player.dart';
import 'package:veil/src/features/embeded_player/view/player.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/features/social/view_model/social_library_view_model/social_library_view_model.dart';
import 'package:veil/src/features/social/widgets/review_thread_sheet.dart';
import 'package:veil/src/features/social/widgets/social_review_card.dart';
import 'package:veil/src/shared/components/content_cards.dart';
import 'package:veil/src/shared/components/poster_art.dart';
import 'package:veil/src/shared/components/veil_sheet.dart';
import 'package:veil/src/shared/components/veil_toast.dart';
import 'package:veil/src/shared/layout/adaptive_content.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';
import 'package:veil/src/shared/models/content_item.dart';

typedef RedirectUrlExtractor = Future<Uri> Function(String url);
typedef ClipLauncher = Future<bool> Function(Uri url);
typedef ExternalPlayerLauncher = Future<bool> Function(List<Uri> urls);
typedef ExternalPlaybackPolicy =
    bool Function({required bool isWeb, required double viewportWidth});
typedef DirectStreamAvailabilityChecker = Future<bool> Function(Uri url);

class DetailView extends ConsumerStatefulWidget {
  const DetailView({
    super.key,
    required this.item,
    this.onBack,
    this.onPlay,
    this.redirectUrlExtractor = extractRedirectUrl,
    this.clipLauncher,
    this.externalPlayerLauncher = openExternalPlayerCandidates,
    this.externalPlaybackPolicy = shouldOpenPlayerExternally,
    this.directStreamAvailabilityChecker = isDirectStreamAvailable,
  });

  final ContentItem item;
  final VoidCallback? onBack;
  final VoidCallback? onPlay;
  final RedirectUrlExtractor redirectUrlExtractor;
  final ClipLauncher? clipLauncher;
  final ExternalPlayerLauncher externalPlayerLauncher;
  final ExternalPlaybackPolicy externalPlaybackPolicy;
  final DirectStreamAvailabilityChecker directStreamAvailabilityChecker;

  @override
  ConsumerState<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<DetailView> {
  var _tab = 'Clips';
  var _isExtractingRedirectUrl = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(detailViewModelProvider(widget.item));
    final isPremium = ref.watch(currentUserIsPremiumProvider).value == true;
    final social = ref.watch(socialLibraryViewModelProvider);
    final currentUserId = ref.read(socialRepositoryProvider).currentUserId;
    final detail = state.detail;
    final item = detail.item;
    final appReviews = _appReviewsForItem(item, social);
    final isInWatchlist = social.entries.any(
      (entry) =>
          entry.inWatchlist &&
          entry.tmdbId == item.remoteId &&
          entry.mediaType == _mediaType(item),
    );
    final isFavorite = social.entries.any(
      (entry) =>
          entry.isFavorite &&
          entry.tmdbId == item.remoteId &&
          entry.mediaType == _mediaType(item),
    );
    final userEntry = social.entries
        .where(
          (entry) =>
              entry.tmdbId == item.remoteId &&
              entry.mediaType == _mediaType(item),
        )
        .firstOrNull;
    final isWatched = userEntry?.watchedOn != null;
    final userRating = userEntry?.rating ?? 0;
    final heroHeight = VeilLayout.detailHeroHeight(context);
    final gutter = VeilLayout.pageGutter(context);
    return Scaffold(
      backgroundColor: VeilColors.bg0,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [VeilColors.bg0, VeilColors.bg1, VeilColors.bg0],
            stops: [0, .52, 1],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: heroHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PosterArt(
                      item: item,
                      width: double.infinity,
                      height: heroHeight,
                      radius: 0,
                      showTitle: false,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x55000000),
                            Color(0x00000000),
                            VeilColors.bg0,
                          ],
                          stops: [0, .42, 1],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        (gutter - 6).clamp(14, gutter).toDouble(),
                        48,
                        gutter,
                        0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GlassButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: widget.onBack ?? () => context.pop(),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: gutter,
                      right: gutter,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.trendingRank != null) ...[
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: VeilColors.red,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                child: Text(
                                  'ON TRENDING #${state.trendingRank}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .7,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 11),
                          ],
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: .95,
                              letterSpacing: -.8,
                            ),
                          ),
                          if (item.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: VeilColors.text2,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .6,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('${item.year}', style: _metaStyle),
                              const Text(
                                '·',
                                style: TextStyle(color: VeilColors.text4),
                              ),
                              Text(item.genre, style: _metaStyle),
                              const Text(
                                '·',
                                style: TextStyle(color: VeilColors.text4),
                              ),
                              Text(
                                item.type == 'TV Show'
                                    ? detail.seasons > 0
                                          ? '${detail.seasons} Season${detail.seasons == 1 ? '' : 's'}'
                                          : item.runtime
                                    : item.runtime,
                                style: _metaStyle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              const MetaPill(label: '4K'),
                              const MetaPill(label: 'HDR'),
                              MetaPill(
                                label: item.rating.toStringAsFixed(1),
                                icon: Icons.star_rounded,
                              ),
                              if (detail.certification.isNotEmpty)
                                MetaPill(label: detail.certification),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (state.loadStatus is StatusLoading)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: VeilColors.red,
                  backgroundColor: VeilColors.bg2,
                ),
              AdaptiveContent(
                maxWidth: VeilLayout.readableMaxWidth(context),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isPremium)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const ValueKey('premium-play-fab'),
                            onPressed: _isExtractingRedirectUrl
                                ? null
                                : () => _openPlaybackServerSheet(detail),
                            icon: _isExtractingRedirectUrl
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              _isExtractingRedirectUrl ? 'Loading' : 'Play',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: VeilColors.red,
                              disabledBackgroundColor: VeilColors.redDeep,
                              disabledForegroundColor: Colors.white70,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      DetailRatingPanel(
                        rating: userRating,
                        isFavorite: isFavorite,
                        isInWatchlist: isInWatchlist,
                        isWatched: isWatched,
                        onTap: () => _openSocialActionSheet(
                          item,
                          isWatched: isWatched,
                          isFavorite: isFavorite,
                          isInWatchlist: isInWatchlist,
                          rating: userRating,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text.rich(
                        TextSpan(
                          text: item.description,
                          children: const [
                            TextSpan(
                              text: ' Read more',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          color: VeilColors.text2,
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Tabs(
                        active: _tab,
                        onChanged: (tab) => setState(() => _tab = tab),
                      ),
                      const SizedBox(height: 16),
                      _TabContent(
                        tab: _tab,
                        detail: detail,
                        appReviews: appReviews,
                        currentUserId: currentUserId,
                        onLikeReview: (review) => ref
                            .read(socialLibraryViewModelProvider.notifier)
                            .toggleReviewLike(review),
                        onHelpfulReview: (review) => ref
                            .read(socialLibraryViewModelProvider.notifier)
                            .toggleReviewHelpful(review),
                        onCommentReview: _openReviewCommentSheet,
                        onDeleteReview: (review) async {
                          await ref
                              .read(socialLibraryViewModelProvider.notifier)
                              .deleteReview(review);
                          if (!context.mounted) return;
                          showVeilToast(context, 'Review deleted');
                        },
                        onOpenClip: _openClip,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPlaybackServerSheet(ContentDetail detail) {
    if (_isExtractingRedirectUrl) return;

    final item = detail.item;
    final hasImdbId = item.imdbId?.trim().isNotEmpty ?? false;
    final hasTmdbId = item.remoteId != null && item.remoteId! > 0;
    if (!hasImdbId && !hasTmdbId) {
      showVeilToast(
        context,
        'Playback id is not available for this title yet.',
      );
      debugPrint(
        'Cannot open player because playback ids are missing for ${item.id}',
      );
      return;
    }

    showVeilBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DetailPlaybackServerSheet(
          title: item.title,
          year: item.year,
          onServerOne: () {
            Navigator.of(sheetContext).pop();
            _openCineDirectServerPlayerFromDetail(detail);
          },
          onServerTwo: () {
            Navigator.of(sheetContext).pop();
            _openPlayImdbServerPlayer(item);
          },
          onServerThree: () {
            Navigator.of(sheetContext).pop();
            _openCinesrcServerPlayer(item);
          },
        );
      },
    );
  }

  Future<void> _openPlayImdbServerPlayer(ContentItem item) async {
    if (_isExtractingRedirectUrl) return;

    final imdbId = item.imdbId?.trim();
    if (imdbId == null || imdbId.isEmpty) {
      showVeilToast(context, 'IMDb id is not available for this title yet.');
      debugPrint(
        'Cannot open player because IMDb id is missing for ${item.id}',
      );
      return;
    }

    setState(() => _isExtractingRedirectUrl = true);

    final entryUrl = playbackEntryUrl(
      imdbId: imdbId,
      isWeb: kIsWeb,
      contentType: item.type,
    );
    final fallbackUrls = playbackFallbackUrls(
      imdbId: imdbId,
      tmdbId: item.remoteId,
      contentType: item.type,
    );
    try {
      Uri embedUrl;
      if (kIsWeb) {
        debugPrint('Opening browser player URL for $imdbId');
        embedUrl = entryUrl;
      } else {
        debugPrint('Extracting redirect URL for $imdbId');
        embedUrl = await widget.redirectUrlExtractor(entryUrl.toString());
      }
      if (!mounted) return;

      await _openResolvedPlayerUrl(
        contentId: imdbId,
        embedUrl: embedUrl,
        fallbackUrls: fallbackUrls,
      );
    } catch (error) {
      debugPrint('Cannot resolve player URL for $imdbId: $error');
      if (mounted) {
        showVeilToast(context, 'Player is not available right now.');
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _isExtractingRedirectUrl = false);
      }
    }
  }

  Future<void> _openCinesrcServerPlayer(ContentItem item) async {
    if (_isExtractingRedirectUrl) return;

    final tmdbId = item.remoteId;
    if (tmdbId == null || tmdbId <= 0) {
      showVeilToast(context, 'TMDB id is not available for this title yet.');
      debugPrint(
        'Cannot open cinesrc player because TMDB id is missing for ${item.id}',
      );
      return;
    }

    setState(() => _isExtractingRedirectUrl = true);

    try {
      final embedUrl = cinesrcPlaybackUrl(
        tmdbId: tmdbId,
        contentType: item.type,
      );
      debugPrint('Opening cinesrc player URL for $tmdbId');
      await _openResolvedPlayerUrl(
        contentId: '$tmdbId',
        embedUrl: embedUrl,
        fallbackUrls: const [],
        forceEmbedded: true,
      );
    } catch (error) {
      debugPrint('Cannot open cinesrc player URL for $tmdbId: $error');
      if (mounted) {
        showVeilToast(context, 'Player is not available right now.');
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _isExtractingRedirectUrl = false);
      }
    }
  }

  void _openCineDirectServerPlayerFromDetail(ContentDetail detail) {
    final item = detail.item;
    if (!isTvPlaybackContent(item.type)) {
      _openCineDirectServerPlayer(item);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openCineDirectEpisodeSheet(detail);
    });
  }

  void _openCineDirectEpisodeSheet(ContentDetail detail) {
    final item = detail.item;
    showVeilBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DetailEpisodeSelectionSheet(
          title: item.title,
          year: item.year,
          seasons: detail.seasons,
          episodes: detail.episodes,
          onPlay: (season, episode) {
            Navigator.of(sheetContext).pop();
            _openCineDirectServerPlayer(item, season: season, episode: episode);
          },
        );
      },
    );
  }

  Future<void> _openCineDirectServerPlayer(
    ContentItem item, {
    int season = 1,
    int episode = 1,
  }) async {
    if (_isExtractingRedirectUrl) return;

    final tmdbId = item.remoteId;
    if (tmdbId == null || tmdbId <= 0) {
      showVeilToast(context, 'TMDB id is not available for this title yet.');
      debugPrint(
        'Cannot open cine direct player because TMDB id is missing for '
        '${item.id}',
      );
      return;
    }

    final streamUrl = cineDirectPlaybackUrl(
      tmdbId: tmdbId,
      contentType: item.type,
      season: season,
      episode: episode,
    );

    setState(() => _isExtractingRedirectUrl = true);
    try {
      final isAvailable = await widget.directStreamAvailabilityChecker(
        streamUrl,
      );
      if (!mounted) return;
      if (!isAvailable) {
        await _openVidnestFallbackPlayer(
          item,
          tmdbId: tmdbId,
          season: season,
          episode: episode,
        );
        return;
      }

      debugPrint('Opening cine direct stream URL for $tmdbId');
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => FullscreenLandscapeDirectVideoPlayer(
            url: streamUrl.toString(),
            title: item.title,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Cannot check cine direct stream for $tmdbId: $error');
      if (mounted) {
        showVeilToast(context, 'Video is not available right now.');
      }
    } finally {
      if (mounted) {
        setState(() => _isExtractingRedirectUrl = false);
      }
    }
  }

  Future<void> _openVidnestFallbackPlayer(
    ContentItem item, {
    required int tmdbId,
    required int season,
    required int episode,
  }) async {
    final embedUrl = vidnestPlaybackUrl(
      tmdbId: tmdbId,
      contentType: item.type,
      season: season,
      episode: episode,
    );

    debugPrint('Opening VidNest fallback URL for $tmdbId');
    await _openResolvedPlayerUrl(
      contentId: '$tmdbId',
      embedUrl: embedUrl,
      fallbackUrls: const [],
      forceEmbedded: true,
    );
  }

  Future<void> _openResolvedPlayerUrl({
    required String contentId,
    required Uri embedUrl,
    required List<Uri> fallbackUrls,
    bool forceEmbedded = false,
  }) async {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    if (!forceEmbedded &&
        widget.externalPlaybackPolicy(
          isWeb: kIsWeb,
          viewportWidth: viewportWidth,
        )) {
      final launchUrls = playbackLaunchUrls(
        primaryUrl: embedUrl,
        fallbackUrls: fallbackUrls,
      );
      debugPrint('Opening compact browser player URL for $contentId');
      final opened = await widget.externalPlayerLauncher(launchUrls);
      if (!opened && mounted) {
        showVeilToast(context, 'Player is not available right now.');
      }
      return;
    }

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => FullscreenLandscapeWebPlayer(
          url: embedUrl.toString(),
          fallbackUrls: fallbackUrls,
        ),
      ),
    );
  }

  void _openSocialActionSheet(
    ContentItem item, {
    required bool isWatched,
    required bool isFavorite,
    required bool isInWatchlist,
    required double rating,
  }) {
    showVeilBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final vm = ref.read(socialLibraryViewModelProvider.notifier);
        return DetailSocialActionSheet(
          item: item,
          isWatched: isWatched,
          isFavorite: isFavorite,
          isInWatchlist: isInWatchlist,
          rating: rating,
          onSetWatched: ({required watched, required rating}) async {
            await vm.setWatched(item, watched: watched, rating: rating);
            if (!mounted) return;
            showVeilToast(
              context,
              watched ? 'Marked watched' : 'Removed from watched',
            );
          },
          onToggleFavorite: () => vm.toggleFavorite(item),
          onSetWatchlist: ({required inWatchlist}) {
            return vm.setWatchlist(item, inWatchlist: inWatchlist);
          },
          onRate: ({required rating}) async {
            await vm.rate(item, rating: rating);
            if (!mounted) return;
            showVeilToast(context, 'Rating saved');
          },
          onOpenReview: ({required rating}) {
            Navigator.of(sheetContext).pop();
            _openReviewSheet(item, initialRating: rating);
          },
          onOpenSuggest: () {
            Navigator.of(sheetContext).pop();
            _openSuggestionSheet(item);
          },
        );
      },
    );
  }

  void _openSuggestionSheet(ContentItem item) {
    showVeilBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DetailSuggestionSheet(
          item: item,
          currentUserId: ref.read(socialRepositoryProvider).currentUserId,
          loadFollowers: () async {
            final repository = ref.read(socialRepositoryProvider);
            final followers = await repository.followers(
              repository.currentUserId,
            );
            return repository.userProfilesForIds(followers);
          },
          onSuggest: (recipientIds) async {
            await ref
                .read(socialRepositoryProvider)
                .suggestMovie(
                  item,
                  recipientIds: recipientIds,
                  senderDisplayName: authDisplayName(
                    ref.read(authViewModelProvider).user,
                  ),
                );
            if (!mounted) return;
            showVeilToast(context, 'Suggestion sent');
          },
        );
      },
    );
  }

  void _openReviewSheet(
    ContentItem item, {
    double initialRating = 0,
    String initialWatchTag = 'first-time',
  }) {
    showVeilBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DetailReviewSheet(
          item: item,
          initialRating: initialRating,
          initialWatchTag: initialWatchTag,
          onSave: ({required rating, required review, required tags}) async {
            await ref
                .read(socialLibraryViewModelProvider.notifier)
                .rateReview(item, rating: rating, review: review, tags: tags);
            if (!mounted) return;
            showVeilToast(context, 'Review saved');
          },
        );
      },
    );
  }

  void _openReviewCommentSheet(SocialEntry review) {
    showVeilBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReviewThreadSheet(
        review: review,
        displayName: _reviewDisplayName(review),
      ),
    );
  }

  Future<void> _openClip(ContentVideo video) async {
    final url = video.youtubeUrl;
    if (url == null) {
      showVeilToast(context, 'Clip link is not available.');
      return;
    }
    final launcher = widget.clipLauncher ?? _launchClipUrl;
    final opened = await launcher(url);
    if (!opened && mounted) {
      showVeilToast(context, 'Could not open YouTube.');
    }
  }
}

Future<bool> _launchClipUrl(Uri url) {
  return launchUrl(url, mode: LaunchMode.externalApplication);
}

String _mediaType(ContentItem item) {
  if (item.mediaType == 'tv') return 'tv';
  if (item.type.toLowerCase().contains('tv')) return 'tv';
  return 'movie';
}

List<SocialEntry> _appReviewsForItem(
  ContentItem item,
  SocialLibraryViewState social,
) {
  final reviewsByUser = <String, SocialEntry>{};
  for (final review in [...social.globalReviews, ...social.entries]) {
    if (review.review.trim().isEmpty) continue;
    if (review.tmdbId != item.remoteId) continue;
    if (review.mediaType != _mediaType(item)) continue;
    reviewsByUser['${review.userId}:${review.id}'] = review;
  }
  return reviewsByUser.values.toList();
}

String _displayName(String userId) {
  final count = userId.length < 8 ? userId.length : 8;
  return '@${userId.substring(0, count)}';
}

String _reviewDisplayName(SocialEntry review) {
  if (review.authorDisplayName.trim().isNotEmpty) {
    return review.authorDisplayName.trim();
  }
  return _displayName(review.userId);
}

const _metaStyle = TextStyle(
  color: VeilColors.text2,
  fontSize: 12,
  fontWeight: FontWeight.w600,
);

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      style: IconButton.styleFrom(
        backgroundColor: VeilColors.panel.withValues(alpha: .72),
        side: BorderSide(color: Colors.white.withValues(alpha: .20)),
        shadowColor: Colors.black.withValues(alpha: .40),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.active, required this.onChanged});

  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = ['Clips', 'Cast', 'Reviews', 'Detail'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in tabs)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                onTap: () => onChanged(tab),
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: active == tab
                        ? Colors.white
                        : VeilColors.panelRaised,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active == tab ? Colors.white : VeilColors.hairline,
                    ),
                  ),
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: active == tab ? Colors.black : VeilColors.text2,
                      fontSize: 13,
                      fontWeight: active == tab
                          ? FontWeight.w900
                          : FontWeight.w700,
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

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.tab,
    required this.detail,
    required this.appReviews,
    required this.currentUserId,
    required this.onLikeReview,
    required this.onHelpfulReview,
    required this.onCommentReview,
    required this.onDeleteReview,
    required this.onOpenClip,
  });

  final String tab;
  final ContentDetail detail;
  final List<SocialEntry> appReviews;
  final String currentUserId;
  final ValueChanged<SocialEntry> onLikeReview;
  final ValueChanged<SocialEntry> onHelpfulReview;
  final ValueChanged<SocialEntry> onCommentReview;
  final ValueChanged<SocialEntry> onDeleteReview;
  final ValueChanged<ContentVideo> onOpenClip;

  @override
  Widget build(BuildContext context) {
    if (tab == 'Cast') return _CastGrid(cast: detail.cast);
    if (tab == 'Reviews') {
      return _Reviews(
        reviews: appReviews,
        currentUserId: currentUserId,
        onLikeReview: onLikeReview,
        onHelpfulReview: onHelpfulReview,
        onCommentReview: onCommentReview,
        onDeleteReview: onDeleteReview,
      );
    }
    if (tab == 'Detail') return _Details(detail: detail);
    return _Clips(detail: detail, onOpenClip: onOpenClip);
  }
}

class _Clips extends StatelessWidget {
  const _Clips({required this.detail, required this.onOpenClip});

  final ContentDetail detail;
  final ValueChanged<ContentVideo> onOpenClip;

  @override
  Widget build(BuildContext context) {
    final item = detail.item;
    final videos = detail.videos;
    if (videos.isEmpty) {
      return const _EmptyTab(message: 'Clips are not available yet.');
    }
    return Column(
      children: [
        for (final video in videos)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              onTap: video.youtubeUrl == null ? null : () => onOpenClip(video),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackdropArt(
                    item: item.copyWith(
                      title: video.name,
                      backdropUrl: video.isYouTube
                          ? video.thumbnailUrl
                          : item.backdropUrl,
                      trailerKey: video.key,
                    ),
                    width: 108,
                    height: 66,
                    radius: 8,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.type.isEmpty ? 'Clip' : video.type,
                          style: const TextStyle(
                            color: VeilColors.text3,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          video.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          video.isYouTube
                              ? 'YouTube'
                              : video.site.isEmpty
                              ? 'Video'
                              : video.site,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: VeilColors.text3,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CastGrid extends StatelessWidget {
  const _CastGrid({required this.cast});

  final List<CastMember> cast;

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) {
      return const _EmptyTab(message: 'Cast details are not available yet.');
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: .72,
      ),
      itemCount: cast.length,
      itemBuilder: (context, index) {
        final person = cast[index];
        return Column(
          children: [
            Expanded(
              child: ClipOval(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [VeilColors.redDeep, VeilColors.bg0],
                    ),
                  ),
                  child: person.profileUrl == null
                      ? Center(
                          child: Text(
                            person.name.characters.first,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: VeilColors.text3,
                            ),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: AppEnvironment.resolveTmdbImageUrl(
                            person.profileUrl!,
                          ),
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Center(
                            child: Text(
                              person.name.characters.first,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: VeilColors.text3,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              person.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            Text(
              person.role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: VeilColors.text3, fontSize: 10),
            ),
          ],
        );
      },
    );
  }
}

class _Reviews extends StatelessWidget {
  const _Reviews({
    required this.reviews,
    required this.currentUserId,
    required this.onLikeReview,
    required this.onHelpfulReview,
    required this.onCommentReview,
    required this.onDeleteReview,
  });

  final List<SocialEntry> reviews;
  final String currentUserId;
  final ValueChanged<SocialEntry> onLikeReview;
  final ValueChanged<SocialEntry> onHelpfulReview;
  final ValueChanged<SocialEntry> onCommentReview;
  final ValueChanged<SocialEntry> onDeleteReview;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const _EmptyTab(message: 'No Veil reviews for this title yet.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final review in reviews)
          SocialReviewCard(
            review: review,
            displayName: _reviewDisplayName(review),
            showMovieTitle: false,
            onLike: () => onLikeReview(review),
            onHelpful: () => onHelpfulReview(review),
            onComment: () => onCommentReview(review),
            onDelete: review.userId == currentUserId
                ? () => onDeleteReview(review)
                : null,
          ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.detail});

  final ContentDetail detail;

  @override
  Widget build(BuildContext context) {
    final item = detail.item;
    final rows = [
      if (detail.studio.isNotEmpty) ('Studio', detail.studio),
      if (detail.status.isNotEmpty) ('Status', detail.status),
      if (detail.releaseDate.isNotEmpty) ('Released', detail.releaseDate),
      ('Runtime', item.runtime),
      ('Genre', item.genre),
      if (detail.certification.isNotEmpty)
        ('Certification', detail.certification),
      if (detail.spokenLanguages.isNotEmpty)
        ('Languages', detail.spokenLanguages),
      if (detail.originalLanguage.isNotEmpty)
        ('Original', detail.originalLanguage.toUpperCase()),
      if (detail.watchProviders.isNotEmpty)
        ('Watch on', detail.watchProviders.join(', ')),
      if (detail.seasons > 0) ('Seasons', '${detail.seasons}'),
      if (detail.episodes > 0) ('Episodes', '${detail.episodes}'),
      if (detail.homepage.isNotEmpty) ('Homepage', detail.homepage),
      ('Source', 'TMDB'),
    ];
    return Column(
      children: [
        for (final row in rows)
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: VeilColors.hairline)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(
                      row.$1,
                      style: const TextStyle(
                        color: VeilColors.text3,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: const TextStyle(color: VeilColors.text3, height: 1.4),
        ),
      ),
    );
  }
}
