import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import 'package:veil/app/services/api_services/api_service.dart';
import 'package:veil/app/services/local_storage_services/local_storage_services.dart';
import 'package:veil/main.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/auth/repository/auth_repository.dart';
import 'package:veil/src/features/auth/view_model/premium_view_model/premium_view_model.dart';
import 'package:veil/src/features/auth/view_model/auth_view_model/auth_view_model.dart';
import 'package:veil/src/features/alerts/view/alerts_view.dart';
import 'package:veil/src/features/catalog/models/content_detail/content_detail.dart';
import 'package:veil/src/features/catalog/view/see_all_view.dart';
import 'package:veil/src/features/home/view_model/home_view_model/home_view_model.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/features/detail/utils/playback_entry_url.dart';
import 'package:veil/src/features/detail/view/detail_view.dart';
import 'package:veil/src/features/detail/view_model/detail_view_model/detail_view_model.dart';
import 'package:veil/src/features/embeded_player/view/player.dart';
import 'package:veil/src/features/embeded_player/utils/redirect_url_extractor.dart';
import 'package:veil/src/features/embeded_player/utils/compact_web_player_policy.dart';
import 'package:veil/src/features/profile/view/profile_view.dart';
import 'package:veil/src/features/reviews/view/reviews_view.dart';
import 'package:veil/src/features/search/view/search_view.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/features/social/view/diary_view.dart';
import 'package:veil/src/features/search/view_model/search_view_model/search_view_model.dart';
import 'package:veil/src/features/social/models/follow_request.dart';
import 'package:veil/src/features/social/models/user_profile_summary.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/view_model/social_library_view_model/social_library_view_model.dart';
import 'package:veil/src/features/user_profile/view/user_profile_view.dart';
import 'package:veil/src/shared/models/content_item.dart';
import 'package:veil/src/shared/components/veil_filter_chips.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  setUp(() {
    WebViewPlatform.instance = _FakeWebViewPlatform();
  });

  testWidgets('onboarding describes a movie logging app', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeViewModelProvider.overrideWithValue(_homeState)],
        child: const VeilApp(),
      ),
    );

    expect(find.text('VEIL'), findsWidgets);
    expect(find.textContaining('your watch diary'), findsOneWidget);
    expect(find.textContaining('streaming'), findsNothing);
  });

  testWidgets('sign up asks for a display name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeViewModelProvider.overrideWithValue(_homeState)],
        child: const VeilApp(),
      ),
    );

    await tester.tap(find.text('New here? Create account'));
    await tester.pump();

    expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('sign up form does not overflow when keyboard is open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeViewModelProvider.overrideWithValue(_homeState)],
        child: const VeilApp(),
      ),
    );

    await tester.tap(find.text('New here? Create account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('restored session skips onboarding', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeViewModelProvider.overrideWithValue(_homeState),
          authRepositoryProvider.overrideWithValue(
            _SessionAuthRepository(_user(displayName: 'Ijas Huzain')),
          ),
        ],
        child: const VeilApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Tonight on Veil'), findsOneWidget);
    expect(find.text('Log every film\nyou watch'), findsNothing);
  });

  testWidgets('login failure shows a visible toast', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeViewModelProvider.overrideWithValue(_homeState),
          authRepositoryProvider.overrideWithValue(
            _FailingAuthRepository('Invalid login credentials'),
          ),
        ],
        child: const VeilApp(),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'a@b.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'wrong');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, VeilColors.red);
    expect(find.textContaining('Invalid login credentials'), findsWidgets);
  });

  testWidgets('veil choice chip uses compact neutral selected styling', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: VeilColors.bg1,
          body: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                VeilChoiceChip(
                  label: 'Action',
                  selected: true,
                  leadingIcon: Icons.check_rounded,
                ),
                SizedBox(width: 8),
                VeilChoiceChip(label: 'Drama', selected: false),
              ],
            ),
          ),
        ),
      ),
    );

    final selected = tester.widget<Container>(
      find
          .descendant(
            of: find.widgetWithText(VeilChoiceChip, 'Action'),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = selected.decoration! as BoxDecoration;

    expect(decoration.color, VeilColors.redSoft);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(VeilTheme.controlRadius),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('home feed removes streaming sections and uses top search', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeViewModelProvider.overrideWithValue(_homeState),
          searchViewModelProvider.overrideWithValue(
            const SearchViewState(
              results: [_arcane],
              genres: ['Action', 'Drama', 'Science Fiction'],
            ),
          ),
        ],
        child: const VeilApp(skipOnboarding: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Tonight on Veil'), findsOneWidget);
    expect(find.text('Global trending'), findsOneWidget);
    expect(find.text('Continue watching'), findsNothing);
    expect(find.text('Browse by mood'), findsNothing);
    expect(find.text('Action'), findsWidgets);
    expect(find.text('Search'), findsNothing);
    expect(find.text('Alerts'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Black Panther: Wakanda Forever'), findsWidgets);

    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Search'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('home greeting uses the signed in user display name', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeViewModelProvider.overrideWithValue(_homeState),
          authViewModelProvider.overrideWithValue(
            AuthViewState(user: _user(displayName: 'Ijas Huzain')),
          ),
        ],
        child: const VeilApp(skipOnboarding: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Hello, Ijas Huzain'), findsOneWidget);
    expect(find.text('Hello, Aman'), findsNothing);
  });

  testWidgets('selected home genre uses vertical results without a title', (
    tester,
  ) async {
    const selectedGenre = TmdbGenre(id: 99, name: 'Neo Noir');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeViewModelProvider.overrideWithValue(
            _homeState.copyWith(
              genres: const [selectedGenre],
              selectedGenre: selectedGenre,
              genreResults: const [_wakanda, _arcane],
              genreStatus: const Status.success(),
            ),
          ),
        ],
        child: const VeilApp(skipOnboarding: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Neo Noir'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('genre-result-movie-505642')),
      findsOneWidget,
    );

    final horizontalLists = tester
        .widgetList<ListView>(find.byType(ListView))
        .where((list) => list.scrollDirection == Axis.horizontal)
        .length;
    expect(horizontalLists, 0);
  });

  testWidgets('pinned home genres stay below the status bar', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeViewModelProvider.overrideWithValue(_homeState)],
        child: const VeilApp(skipOnboarding: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -360));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      tester.getTopLeft(find.text('All').first).dy,
      greaterThanOrEqualTo(47),
    );
  });

  testWidgets('profile does not expose TMDB account linking', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeViewModelProvider.overrideWithValue(_homeState)],
        child: const VeilApp(skipOnboarding: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('TMDB account'), findsNothing);
    expect(find.text('Connect TMDB'), findsNothing);
    expect(find.text('Disconnect TMDB'), findsNothing);
    expect(
      find.text(
        'This product uses the TMDB API but is not endorsed or certified by TMDB.',
      ),
      findsNothing,
    );
  });

  testWidgets('app router stays stable through responsive metric changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeViewModelProvider.overrideWithValue(_homeState)],
        child: const VeilApp(skipOnboarding: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final delegateBefore = tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .routerConfig;

    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final delegateAfter = tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .routerConfig;

    expect(identical(delegateAfter, delegateBefore), isTrue);
  });

  testWidgets('imperative routes survive responsive metric changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeViewModelProvider.overrideWithValue(_homeState)],
        child: const VeilApp(skipOnboarding: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Manual overlay route')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Manual overlay route'), findsOneWidget);

    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Manual overlay route'), findsOneWidget);
  });

  testWidgets('opens detail and fullscreen web player', (tester) async {
    final enrichedItem = _wakanda.copyWith(imdbId: 'tt9114286');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_wakanda).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(enrichedItem)),
          ),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          home: DetailView(
            item: _wakanda,
            redirectUrlExtractor: (_) async =>
                Uri.parse('https://streamimdb.ru/embed/movie/tt9114286'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Clips'), findsWidgets);

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.byKey(const ValueKey('detail-playback-server-panel')),
      findsOneWidget,
    );
    expect(find.text('Server 1'), findsOneWidget);
    expect(find.text('Server 2'), findsOneWidget);
    expect(find.text('Current source'), findsNothing);
    expect(find.text('vidsrc.to'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('playback-server-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(FullscreenLandscapeWebPlayer), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    final player = tester.widget<FullscreenLandscapeWebPlayer>(
      find.byType(FullscreenLandscapeWebPlayer),
    );
    expect(player.fallbackUrls.map((url) => url.toString()), [
      'https://vsembed.ru/embed/movie?imdb=tt9114286',
    ]);
  });

  testWidgets('detail hero uses title first and hides absent trending rank', (
    tester,
  ) async {
    final item = _arcane.copyWith(
      title: 'The Boys',
      subtitle: 'Never meet your heroes.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(item).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(item)),
          ),
        ],
        child: MaterialApp(
          home: DetailView(item: item, onPlay: () {}),
        ),
      ),
    );
    await tester.pump();

    final title = tester.widget<Text>(find.text('The Boys'));
    expect(title.style?.fontSize, 32);
    final subtitle = tester.widget<Text>(find.text('Never meet your heroes.'));
    expect(subtitle.style?.fontSize, 13);
    expect(find.text('THE BOYS'), findsNothing);
    expect(find.textContaining('ON TRENDING'), findsNothing);
  });

  testWidgets('detail shows TMDB-backed trending rank', (tester) async {
    final item = _arcane.copyWith(
      title: 'The Boys',
      subtitle: 'Never meet your heroes.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(
            _RankingTmdbRepository(
              detailResult: ContentDetail.fallback(item),
              trendingItems: [_wakanda, item],
            ),
          ),
        ],
        child: MaterialApp(
          home: DetailView(item: item, onPlay: () {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('ON TRENDING #2'), findsOneWidget);
  });

  testWidgets('detail clips use TMDB videos with clean YouTube labels', (
    tester,
  ) async {
    final item = _wakanda.copyWith(
      title: 'The Boys',
      subtitle: 'Never meet your heroes.',
    );
    final detail = ContentDetail(
      item: item,
      videos: const [
        ContentVideo(
          key: 'abc123',
          name: 'Official Trailer',
          site: 'YouTube',
          type: 'Trailer',
          official: true,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(
            item,
          ).overrideWithValue(DetailViewState(detail: detail)),
        ],
        child: MaterialApp(
          home: DetailView(item: item, onPlay: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Clips'), findsOneWidget);
    expect(find.text('Episodes'), findsNothing);
    expect(find.text('Official Trailer'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.textContaining('trailer key'), findsNothing);
  });

  testWidgets('detail shows floating play only for premium users', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_wakanda).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(_wakanda)),
          ),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          home: DetailView(item: _wakanda, onPlay: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('premium-play-fab')), findsOneWidget);
  });

  testWidgets('detail hides floating play for non-premium users', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_wakanda).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(_wakanda)),
          ),
          currentUserIsPremiumProvider.overrideWith((ref) async => false),
        ],
        child: MaterialApp(
          home: DetailView(item: _wakanda, onPlay: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('premium-play-fab')), findsNothing);
  });

  testWidgets('detail play button shows loading while resolving redirect', (
    tester,
  ) async {
    final enrichedItem = _wakanda.copyWith(imdbId: 'tt9114286');
    final redirectCompleter = Completer<Uri>();
    var redirectCalls = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_wakanda).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(enrichedItem)),
          ),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          home: DetailView(
            item: _wakanda,
            redirectUrlExtractor: (_) {
              redirectCalls += 1;
              return redirectCompleter.future;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Server 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('playback-server-1')));
    await tester.pump();

    expect(find.text('Loading'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Loading'));
    await tester.pump();

    expect(redirectCalls, 1);
  });

  testWidgets('detail play button uses enriched TMDB IMDb id', (tester) async {
    String? requestedUrl;
    final enrichedItem = _wakanda.copyWith(imdbId: 'tt16431404');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_wakanda).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(enrichedItem)),
          ),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          home: DetailView(
            item: _wakanda,
            redirectUrlExtractor: (url) async {
              requestedUrl = url;
              return Uri.parse('https://streamimdb.ru/embed/movie/tt16431404');
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const ValueKey('playback-server-1')));
    await tester.pump();

    expect(requestedUrl, 'https://www.playimdb.com/title/tt16431404/');
  });

  testWidgets('detail server two opens cinesrc tv embed', (tester) async {
    final enrichedItem = _arcane.copyWith(imdbId: 'tt0944947');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_arcane).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(enrichedItem)),
          ),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(home: DetailView(item: _arcane)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const ValueKey('playback-server-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final player = tester.widget<FullscreenLandscapeWebPlayer>(
      find.byType(FullscreenLandscapeWebPlayer),
    );
    expect(player.url, 'https://cinesrc.st/embed/tv/94605?s=1&e=1');
    expect(player.fallbackUrls, isEmpty);
  });

  testWidgets(
    'detail server two stays embedded when compact web externalizes',
    (tester) async {
      final enrichedItem = _arcane.copyWith(imdbId: 'tt0944947');
      var launcherCalls = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            detailViewModelProvider(_arcane).overrideWithValue(
              DetailViewState(detail: ContentDetail.fallback(enrichedItem)),
            ),
            currentUserIsPremiumProvider.overrideWith((ref) async => true),
          ],
          child: MaterialApp(
            home: DetailView(
              item: _arcane,
              externalPlaybackPolicy:
                  ({required isWeb, required viewportWidth}) => true,
              externalPlayerLauncher: (_) async {
                launcherCalls += 1;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Play'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.byKey(const ValueKey('playback-server-2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(launcherCalls, 0);
      final player = tester.widget<FullscreenLandscapeWebPlayer>(
        find.byType(FullscreenLandscapeWebPlayer),
      );
      expect(player.url, 'https://cinesrc.st/embed/tv/94605?s=1&e=1');
      expect(player.fallbackUrls, isEmpty);
    },
  );

  testWidgets(
    'detail play button stays loading while external urls are checked',
    (tester) async {
      final enrichedItem = _wakanda.copyWith(imdbId: 'tt9114286');
      final launcherCompleter = Completer<bool>();
      var launcherCalls = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            detailViewModelProvider(_wakanda).overrideWithValue(
              DetailViewState(detail: ContentDetail.fallback(enrichedItem)),
            ),
            currentUserIsPremiumProvider.overrideWith((ref) async => true),
          ],
          child: MaterialApp(
            home: DetailView(
              item: _wakanda,
              redirectUrlExtractor: (_) async =>
                  Uri.parse('https://streamimdb.ru/embed/movie/tt9114286'),
              externalPlaybackPolicy:
                  ({required isWeb, required viewportWidth}) => true,
              externalPlayerLauncher: (_) {
                launcherCalls += 1;
                return launcherCompleter.future;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Play'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.byKey(const ValueKey('playback-server-1')));
      await tester.pump();

      expect(launcherCalls, 1);
      expect(find.text('Loading'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      launcherCompleter.complete(true);
      await tester.pump();
    },
  );

  test(
    'redirect extractor skips browser-forbidden prefetch on web path',
    () async {
      final uri = await extractRedirectUrl(
        'https://www.playimdb.com/title/tt1190634/',
        skipNetwork: true,
      );

      expect(uri.toString(), 'https://playimdb.com/title/tt1190634/');
    },
  );

  test('web playback entry url bypasses the tracker wrapper', () {
    expect(
      playbackEntryUrl(
        imdbId: 'tt28650488',
        isWeb: true,
        contentType: 'Movie',
      ).toString(),
      'https://streamimdb.ru/embed/movie/tt28650488',
    );
    expect(
      playbackEntryUrl(
        imdbId: 'tt1190634',
        isWeb: true,
        contentType: 'TV Show',
      ).toString(),
      'https://streamimdb.ru/embed/tv/tt1190634',
    );
    expect(
      playbackEntryUrl(imdbId: 'tt28650488', isWeb: false).toString(),
      'https://www.playimdb.com/title/tt28650488/',
    );
  });

  test('cinesrc playback urls use movie and tv tmdb embeds', () {
    expect(
      cinesrcPlaybackUrl(tmdbId: 505642, contentType: 'Movie').toString(),
      'https://cinesrc.st/embed/movie/505642',
    );
    expect(
      cinesrcPlaybackUrl(
        tmdbId: 94605,
        contentType: 'TV Show',
        season: 2,
        episode: 3,
      ).toString(),
      'https://cinesrc.st/embed/tv/94605?s=2&e=3',
    );
  });

  test('playback fallback urls only include vsembed for movies', () {
    expect(
      playbackFallbackUrls(
        imdbId: 'tt8385148',
        tmdbId: 522931,
        contentType: 'Movie',
      ).map((url) => url.toString()),
      ['https://vsembed.ru/embed/movie?imdb=tt8385148'],
    );
  });

  test('playback fallback urls only include vsembed for episodes', () {
    expect(
      playbackFallbackUrls(
        imdbId: 'tt13157618',
        tmdbId: 114472,
        contentType: 'TV Show',
        season: 1,
        episode: 2,
      ).map((url) => url.toString()),
      ['https://vsembed.ru/embed/tv?imdb=tt13157618&season=1&episode=2'],
    );
  });

  test('playback fallback urls keep existing vsembed tv episode shape', () {
    expect(
      playbackFallbackUrls(
        imdbId: 'tt0944947',
        contentType: 'TV Show',
        season: 2,
        episode: 1,
      ).first.toString(),
      'https://vsembed.ru/embed/tv?imdb=tt0944947&season=2&episode=1',
    );
  });

  testWidgets('mobile player loads vsembed fallback after current url 404', (
    tester,
  ) async {
    final platform = _FakeWebViewPlatform();
    WebViewPlatform.instance = platform;
    final primaryUrl = Uri.parse('https://streamimdb.ru/embed/movie/tt9114286');
    final fallbackUrl = Uri.parse(
      'https://vsembed.ru/embed/movie?imdb=tt9114286',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FullscreenLandscapeWebPlayer(
          url: primaryUrl.toString(),
          fallbackUrls: [fallbackUrl],
          showCloseButton: false,
        ),
      ),
    );
    await tester.pump();

    expect(platform.controller.htmlLoads, hasLength(1));
    expect(
      platform.controller.htmlLoads.single,
      contains(primaryUrl.toString()),
    );

    platform.navigationDelegate.onHttpError?.call(
      HttpResponseError(
        request: WebResourceRequest(uri: primaryUrl),
        response: WebResourceResponse(uri: primaryUrl, statusCode: 404),
      ),
    );
    await tester.pump();

    expect(platform.controller.htmlLoads, hasLength(2));
    expect(
      platform.controller.htmlLoads.last,
      contains(htmlEscape.convert(fallbackUrl.toString())),
    );
  });

  test('compact web player opens outside the fragile iframe path', () {
    expect(shouldOpenPlayerExternally(isWeb: true, viewportWidth: 390), isTrue);
    expect(shouldOpenPlayerExternally(isWeb: true, viewportWidth: 699), isTrue);
    expect(
      shouldOpenPlayerExternally(isWeb: true, viewportWidth: 700),
      isFalse,
    );
    expect(
      shouldOpenPlayerExternally(isWeb: false, viewportWidth: 390),
      isFalse,
    );
  });

  test('compact web launch keeps the primary url first', () {
    final primaryUrl = Uri.parse('https://streamimdb.ru/embed/movie/x');
    final fallbackUrl = Uri.parse('https://vsembed.ru/embed/movie?imdb=x');

    expect(
      compactWebPlaybackLaunchUrl(
        primaryUrl: primaryUrl,
        fallbackUrls: [fallbackUrl],
      ),
      primaryUrl,
    );
    expect(
      compactWebPlaybackLaunchUrl(
        primaryUrl: primaryUrl,
        fallbackUrls: const [],
      ),
      primaryUrl,
    );
  });

  test('checked playback launch skips confirmed 404 urls', () async {
    final primaryUrl = Uri.parse('https://streamimdb.ru/embed/movie/x');
    final fallbackUrl = Uri.parse('https://vsembed.ru/embed/movie?imdb=x');
    final openedUrl = await firstNon404PlaybackLaunchUrl(
      urls: [primaryUrl, fallbackUrl],
      statusCodeForUrl: (url) async => url == primaryUrl ? 404 : 200,
    );

    expect(openedUrl, fallbackUrl);
  });

  test('checked playback launch keeps urls with unknown status', () async {
    final primaryUrl = Uri.parse('https://streamimdb.ru/embed/movie/x');
    final fallbackUrl = Uri.parse('https://vsembed.ru/embed/movie?imdb=x');
    final openedUrl = await firstNon404PlaybackLaunchUrl(
      urls: [primaryUrl, fallbackUrl],
      statusCodeForUrl: (_) async => null,
    );

    expect(openedUrl, primaryUrl);
  });

  test('checked playback launch returns null when every url is 404', () async {
    final primaryUrl = Uri.parse('https://streamimdb.ru/embed/movie/x');
    final fallbackUrl = Uri.parse('https://vsembed.ru/embed/movie?imdb=x');
    final openedUrl = await firstNon404PlaybackLaunchUrl(
      urls: [primaryUrl, fallbackUrl],
      statusCodeForUrl: (_) async => 404,
    );

    expect(openedUrl, isNull);
  });

  test('checked playback launch rejects provider unavailable pages', () async {
    final vsembedUrl = Uri.parse('https://vsembed.ru/embed/movie?imdb=x');
    final openedUrl = await firstNon404PlaybackLaunchUrl(
      urls: [vsembedUrl],
      statusCodeForUrl: (_) async => 200,
      responseBodyForUrl: (_) async => 'This media unavailable at the moment',
    );

    expect(openedUrl, isNull);
  });

  testWidgets('detail uses one unified social action sheet', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_wakanda).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(_wakanda)),
          ),
        ],
        child: MaterialApp(
          home: DetailView(item: _wakanda, onPlay: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Rate, log, review + more'), findsOneWidget);
    expect(find.text('Log'), findsNothing);

    await tester.ensureVisible(find.text('Rate, log, review + more'));
    await tester.pump();
    await tester.tap(find.text('Rate, log, review + more'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Watched'), findsOneWidget);
    expect(find.text('Favorite'), findsOneWidget);
    expect(find.text('Like'), findsNothing);
    expect(find.text('Watchlist'), findsOneWidget);
    expect(find.text('Rate'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Suggest'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
    expect(
      find.byKey(const ValueKey('detail-social-action-panel')),
      findsOneWidget,
    );
  });

  testWidgets('detail review save is disabled without rating and text', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_wakanda).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(_wakanda)),
          ),
        ],
        child: MaterialApp(
          home: DetailView(item: _wakanda, onPlay: () {}),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Rate, log, review + more'));
    await tester.pump();
    await tester.tap(find.text('Rate, log, review + more'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Add to lists'), findsNothing);
    expect(find.text('Change poster/backdrop'), findsNothing);
    expect(find.text('Share to Instagram'), findsNothing);
    expect(find.text('Share'), findsNothing);

    await tester.tap(find.text('Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final save = tester.widget<TextButton>(
      find.byKey(const ValueKey('detail-review-save')),
    );
    expect(save.onPressed, isNull);
    expect(find.text('Tags, comma separated'), findsOneWidget);
  });

  testWidgets('detail action sheet keeps watch kind only in review flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_wakanda).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(_wakanda)),
          ),
        ],
        child: MaterialApp(
          home: DetailView(item: _wakanda, onPlay: () {}),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Rate, log, review + more'));
    await tester.pump();
    await tester.tap(find.text('Rate, log, review + more'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('First-time watch'), findsNothing);
    expect(find.text('Rewatch'), findsNothing);

    await tester.tap(find.text('Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('First-time watch'), findsOneWidget);
    expect(find.text('Rewatch'), findsOneWidget);
  });

  testWidgets('detail reviews tab shows app reviews with actions', (
    tester,
  ) async {
    final review = _socialEntry(
      _wakanda,
      rating: 4,
    ).copyWith(review: 'Our app review matters.');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_wakanda).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(_wakanda)),
          ),
          socialLibraryViewModelProvider.overrideWithValue(
            SocialLibraryViewState(globalReviews: [review], entries: [review]),
          ),
        ],
        child: MaterialApp(
          home: DetailView(item: _wakanda, onPlay: () {}),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Reviews'));
    await tester.tap(find.text('Reviews'));
    await tester.pump();

    expect(find.text('Our app review matters.'), findsOneWidget);
    expect(find.text('Like'), findsOneWidget);
    expect(find.text('Comment'), findsOneWidget);
    expect(find.byTooltip('Delete review'), findsOneWidget);
  });

  testWidgets('diary uses top tabs with a compact four-column grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    final repository = SocialRepository();
    await repository.logWatched(_wakanda, rating: 4, review: 'Huge scale.');
    await repository.toggleWatchlist(_arcane);
    await repository.toggleFavorite(_wakanda);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [socialRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: DiaryView()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Watched'), findsOneWidget);
    expect(find.text('Watchlist'), findsWidgets);
    expect(find.text('Favorites'), findsWidgets);
    expect(find.text('Reviews'), findsNothing);
    expect(find.text('See all'), findsNothing);

    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid).first);
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 4);
    expect(delegate.childAspectRatio, .58);
  });

  testWidgets('reviews and alerts use diary segmented tab styling', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    final repository = SocialRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [socialRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ReviewsView()),
      ),
    );
    await tester.pump();

    _expectDiarySegmentStyle(tester, find.text('Community'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(_FakeTmdbRepository()),
        ],
        child: const MaterialApp(home: AlertsView(showBack: true)),
      ),
    );
    await tester.pump();

    _expectDiarySegmentStyle(tester, find.text('Alert'));
  });

  testWidgets('diary swipes horizontally between tabs', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialLibraryViewModelProvider.overrideWithValue(
            SocialLibraryViewState(
              entries: [
                _socialEntry(_wakanda, rating: 4),
                _socialEntry(_arcane, inWatchlist: true),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: DiaryView()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.textContaining('watched ·'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('diary-tab-swipe-area')),
      const Offset(-260, 0),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.textContaining('watchlist ·'), findsOneWidget);
  });

  testWidgets('diary opens v2 filter sheet with grouped controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialLibraryViewModelProvider.overrideWithValue(
            SocialLibraryViewState(
              entries: [
                _socialEntry(_wakanda, rating: 4),
                _socialEntry(_arcane, rating: 3),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: DiaryView()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('Filter'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Filter & sort'), findsOneWidget);
    expect(find.text('Sort by'), findsOneWidget);
    expect(find.text('Genre'), findsOneWidget);
    expect(find.text('Minimum rating'), findsOneWidget);
    expect(find.text('Release year'), findsOneWidget);
  });

  testWidgets('modal bottom sheets blur the background barrier', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialLibraryViewModelProvider.overrideWithValue(
            SocialLibraryViewState(
              entries: [
                _socialEntry(_wakanda, rating: 4),
                _socialEntry(_arcane, rating: 3),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: DiaryView()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('Filter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('Filter & sort'), findsOneWidget);
  });

  testWidgets('diary applies minimum rating from filter sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final lowRated = _socialEntry(_wakanda, rating: 3);
    final highRated = _socialEntry(_arcane, rating: 4.5);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialLibraryViewModelProvider.overrideWithValue(
            SocialLibraryViewState(entries: [lowRated, highRated]),
          ),
        ],
        child: const MaterialApp(home: DiaryView()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('Filter'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final ratingFilter = find.byKey(const ValueKey('diary-filter-rating-4.0'));
    await tester.ensureVisible(ratingFilter);
    await tester.tap(ratingFilter);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(find.byKey(const ValueKey('diary-filter-show-results')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(ValueKey('diary-entry-${lowRated.id}')), findsNothing);
    expect(find.byKey(ValueKey('diary-entry-${highRated.id}')), findsOneWidget);
    expect(find.text('4.0+'), findsWidgets);
  });

  testWidgets('diary watchlist footers show year instead of stars', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialLibraryViewModelProvider.overrideWithValue(
            SocialLibraryViewState(
              entries: [_socialEntry(_arcane, inWatchlist: true, rating: 4)],
            ),
          ),
        ],
        child: const MaterialApp(home: DiaryView()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('Watchlist').last);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('2021'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('see all grid does not overflow on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialLibraryViewModelProvider.overrideWithValue(
            SocialLibraryViewState(
              entries: [
                _socialEntry(_wakanda, inWatchlist: true),
                _socialEntry(
                  _arcane.copyWith(title: 'Avatar Aang: The Last Airbender'),
                  inWatchlist: true,
                ),
                _socialEntry(
                  _wakanda.copyWith(title: 'Demon Slayer: Infinity Castle'),
                  inWatchlist: true,
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(
          home: SeeAllView(section: 'watchlist', title: 'Action'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
    expect(find.text('Action'), findsWidgets);

    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid).first);
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.childAspectRatio, lessThanOrEqualTo(.50));
  });

  testWidgets('detail social actions use a visible top toast', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_wakanda).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(_wakanda)),
          ),
        ],
        child: MaterialApp(
          home: DetailView(item: _wakanda, onPlay: () {}),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Rate, log, review + more'));
    await tester.pump();
    await tester.tap(find.text('Rate, log, review + more'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Watched'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.margin, isNotNull);
    expect(snackBar.backgroundColor, VeilColors.red);
    expect(snackBar.content, isA<Text>());
    final content = snackBar.content as Text;
    expect(content.style?.color, Colors.white);
  });

  testWidgets('top search page renders TMDB results and genres', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeViewModelProvider.overrideWithValue(_homeState),
          searchViewModelProvider.overrideWithValue(
            const SearchViewState(
              results: [_arcane],
              genres: ['Action', 'Drama', 'Science Fiction'],
            ),
          ),
        ],
        child: const VeilApp(skipOnboarding: true),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Top results'), findsOneWidget);
    expect(find.text('Arcane'), findsWidgets);
    expect(find.text('Science Fiction'), findsOneWidget);
  });

  testWidgets('search scopes between all, users, and films', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchViewModelProvider.overrideWithValue(
            const SearchViewState(
              query: 'member',
              results: [_arcane],
              genres: ['Action'],
            ),
          ),
          socialLibraryViewModelProvider.overrideWithValue(
            SocialLibraryViewState(
              globalReviews: [
                _socialEntry(_wakanda).copyWith(userId: 'member-1'),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: SearchView()),
      ),
    );
    await tester.pump();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Films'), findsOneWidget);
    expect(find.text('Cast'), findsOneWidget);
    expect(find.text('Top results'), findsOneWidget);
    expect(find.text('Users'), findsWidgets);

    await tester.tap(find.text('Users').first);
    await tester.pump();

    expect(find.text('Top results'), findsNothing);
    expect(find.text('Arcane'), findsNothing);
    expect(find.text('@member-1'), findsOneWidget);

    await tester.tap(find.text('Films'));
    await tester.pump();

    expect(find.text('Top results'), findsOneWidget);
    expect(find.text('Arcane'), findsWidgets);
  });

  testWidgets('search hides the signed in app user by display name', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchViewModelProvider.overrideWithValue(
            const SearchViewState(query: 'ijas'),
          ),
          socialRepositoryProvider.overrideWithValue(SocialRepository()),
          socialLibraryViewModelProvider.overrideWithValue(
            SocialLibraryViewState(entries: [_socialEntry(_wakanda)]),
          ),
          authViewModelProvider.overrideWithValue(
            AuthViewState(user: _user(displayName: 'Ijas Huzain')),
          ),
        ],
        child: const MaterialApp(home: SearchView()),
      ),
    );
    await tester.pump();

    expect(find.text('App users'), findsNothing);
    expect(find.text('Ijas Huzain'), findsNothing);
  });

  testWidgets('search finds app directory users by display name', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchViewModelProvider.overrideWithValue(
            const SearchViewState(
              query: 'mira',
              users: [
                UserProfileSummary(
                  userId: 'member-2',
                  displayName: 'Mira Kapoor',
                ),
              ],
            ),
          ),
          socialRepositoryProvider.overrideWithValue(SocialRepository()),
          socialLibraryViewModelProvider.overrideWithValue(
            const SocialLibraryViewState(),
          ),
        ],
        child: const MaterialApp(home: SearchView()),
      ),
    );
    await tester.pump();

    expect(find.text('App users'), findsOneWidget);
    expect(find.text('Mira Kapoor'), findsOneWidget);
  });

  testWidgets('search hides hardcoded siyana user from results', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchViewModelProvider.overrideWithValue(
            const SearchViewState(
              query: 'si',
              users: [
                UserProfileSummary(
                  userId: 'member-siyana',
                  displayName: 'Siyana',
                ),
                UserProfileSummary(
                  userId: 'member-simon',
                  displayName: 'Simon Baker',
                ),
              ],
            ),
          ),
          socialRepositoryProvider.overrideWithValue(SocialRepository()),
          socialLibraryViewModelProvider.overrideWithValue(
            const SocialLibraryViewState(),
          ),
        ],
        child: const MaterialApp(home: SearchView()),
      ),
    );
    await tester.pump();

    expect(find.text('App users'), findsOneWidget);
    expect(find.text('Simon Baker'), findsOneWidget);
    expect(find.text('Siyana'), findsNothing);
  });

  testWidgets('reviews view supports local like comment and delete', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    final repository = SocialRepository();
    await repository.rateReview(
      _wakanda,
      rating: 4,
      review: 'My local review.',
      tags: const ['first-time'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [socialRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ReviewsView()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('My reviews'));
    await tester.pump();

    expect(find.text('My local review.'), findsOneWidget);
    await tester.tap(find.text('Like'));
    await tester.pump();
    expect(find.text('Liked'), findsOneWidget);

    await tester.tap(find.text('Comment'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Great take');
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    final postComment = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Post comment'),
    );
    postComment.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('1 comment'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete review').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('My local review.'), findsNothing);
    expect(await repository.reviews(), isEmpty);
  });

  testWidgets('mobile secondary pages use home-like top spacing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding.zero;
    tester.view.viewPadding = FakeViewPadding.zero;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    final repository = SocialRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialRepositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(
            _SessionAuthRepository(_user(displayName: 'Ijas Huzain')),
          ),
        ],
        child: const MaterialApp(home: DiaryView()),
      ),
    );
    await tester.pump();
    expect(tester.getTopLeft(find.text('Diary')).dy, lessThan(36));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialRepositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(
            _SessionAuthRepository(_user(displayName: 'Ijas Huzain')),
          ),
        ],
        child: const MaterialApp(home: ReviewsView()),
      ),
    );
    await tester.pump();
    expect(tester.getTopLeft(find.text('Reviews').first).dy, lessThan(36));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialRepositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(
            _SessionAuthRepository(_user(displayName: 'Ijas Huzain')),
          ),
        ],
        child: const MaterialApp(home: ProfileView()),
      ),
    );
    await tester.pump();
    expect(tester.getTopLeft(find.text('Profile')).dy, lessThan(36));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(_FakeTmdbRepository()),
          socialRepositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(
            _SessionAuthRepository(_user(displayName: 'Ijas Huzain')),
          ),
        ],
        child: const MaterialApp(home: SearchView(showBack: true)),
      ),
    );
    await tester.pump();
    expect(tester.getTopLeft(find.text('Search')).dy, lessThan(36));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(_FakeTmdbRepository()),
        ],
        child: const MaterialApp(home: AlertsView(showBack: true)),
      ),
    );
    await tester.pump();
    expect(tester.getTopLeft(find.text('Alerts')).dy, lessThan(36));
  });

  testWidgets('search records and clears recent searches', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(_FakeTmdbRepository()),
          socialLibraryViewModelProvider.overrideWithValue(
            const SocialLibraryViewState(),
          ),
        ],
        child: const MaterialApp(home: SearchView()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Find films, cast + crew, members...'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'arcane');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('arcane'), findsWidgets);
    expect(find.text('Clear recent'), findsOneWidget);

    await tester.tap(find.text('Clear recent'));
    await tester.pump();

    expect(find.text('Recent searches'), findsNothing);
  });

  testWidgets('profile uses settings sections and dedicated follow pages', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    final repository = SocialRepository();
    await repository.followUser(
      'member-2',
      requesterDisplayName: 'Ijas Huzain',
      recipientDisplayName: 'Mira',
    );
    final memberRepository = SocialRepository(localUserId: 'member-2');
    await memberRepository.acceptFollowRequest(
      (await memberRepository.followRequestsForAlerts()).single.id,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialRepositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(
            _SessionAuthRepository(_user(displayName: 'Ijas Huzain')),
          ),
        ],
        child: const MaterialApp(home: ProfileView()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Following'), findsWidgets);
    expect(find.text('Followers'), findsWidgets);
    expect(find.text('Reviews'), findsNothing);
    expect(find.text('Activity'), findsNothing);
    expect(find.text('My Activity'), findsOneWidget);
    expect(find.text('Import/Export'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms and Condition'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsNothing);
    expect(find.text('@member-2'), findsNothing);

    await tester.tap(find.text('Following').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('1 member'), findsOneWidget);
    expect(find.text('@member-2'), findsOneWidget);
  });

  testWidgets('profile delete account asks for reason and confirmation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    final repository = SocialRepository();
    final authRepository = _RecordingAuthRepository(
      _user(displayName: 'Ijas Huzain'),
    );
    await repository.rateReview(
      _wakanda,
      rating: 4,
      review: 'Keep public review.',
      tags: const ['first-time'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialRepositoryProvider.overrideWithValue(repository),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const MaterialApp(home: ProfileView()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.byKey(const ValueKey('delete-account-row')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Delete account'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('delete-account-reason')),
      'Leaving for now',
    );
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Delete account?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-delete-account')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(authRepository.signedOut, isTrue);
    expect((await repository.reviews()).single.review, 'Keep public review.');
  });

  testWidgets('user profile sends a follow request to members', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    final repository = SocialRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [socialRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: UserProfileView(userId: 'member-2', displayName: 'Mira'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Follow'), findsOneWidget);

    await tester.tap(find.text('Follow'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(await repository.isFollowing('member-2'), isFalse);
    expect(
      await repository.followRequestStatus('member-2'),
      FollowRequestStatus.pending,
    );
    expect(find.text('Requested'), findsOneWidget);
  });

  testWidgets('responsive shell keeps bottom navigation on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeViewModelProvider.overrideWithValue(_homeState),
          authViewModelProvider.overrideWithValue(
            AuthViewState(user: _user(displayName: 'Ijas Huzain')),
          ),
        ],
        child: const VeilApp(skipOnboarding: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
  });

  testWidgets('responsive shell uses navigation rail on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeViewModelProvider.overrideWithValue(_homeState),
          authViewModelProvider.overrideWithValue(
            AuthViewState(user: _user(displayName: 'Ijas Huzain')),
          ),
        ],
        child: const VeilApp(skipOnboarding: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Diary'), findsOneWidget);
  });

  testWidgets('home renders primary feed on desktop without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeViewModelProvider.overrideWithValue(_homeState),
          authViewModelProvider.overrideWithValue(
            AuthViewState(user: _user(displayName: 'Ijas Huzain')),
          ),
        ],
        child: const VeilApp(skipOnboarding: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Tonight on Veil'), findsOneWidget);
    expect(find.text('Global trending'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('diary grid expands beyond phone columns on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialLibraryViewModelProvider.overrideWithValue(
            SocialLibraryViewState(
              entries: [
                _socialEntry(_wakanda, rating: 4),
                _socialEntry(_arcane, rating: 4.5),
                _socialEntry(
                  _wakanda.copyWith(id: 'm3', remoteId: 3),
                  rating: 3.5,
                ),
                _socialEntry(
                  _arcane.copyWith(id: 'm4', remoteId: 4),
                  rating: 5,
                ),
                _socialEntry(
                  _wakanda.copyWith(id: 'm5', remoteId: 5),
                  rating: 4.2,
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: DiaryView()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final grid = tester.widget<SliverGrid>(find.byType(SliverGrid).first);
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, greaterThan(4));
    expect(delegate.childAspectRatio, .62);
    expect(tester.takeException(), isNull);
  });
}

const _wakanda = ContentItem(
  id: 'movie-505642',
  remoteId: 505642,
  mediaType: 'movie',
  title: 'Black Panther: Wakanda Forever',
  subtitle: 'Movie',
  year: 2022,
  genre: 'Action / Adventure',
  type: 'Movie',
  rating: 7.1,
  palette: [Colors.black, Colors.red],
  glyph: Icons.movie_rounded,
  description: 'Wakanda fights to protect itself.',
  posterUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
  backdropUrl: 'https://image.tmdb.org/t/p/w780/backdrop.jpg',
  trailerKey: 'abc123',
);

const _arcane = ContentItem(
  id: 'tv-94605',
  remoteId: 94605,
  mediaType: 'tv',
  title: 'Arcane',
  subtitle: 'Series',
  year: 2021,
  genre: 'Animation / Drama',
  type: 'TV Show',
  rating: 9.0,
  palette: [Colors.black, Colors.blue],
  glyph: Icons.live_tv_rounded,
  description: 'Two sisters fight from opposite sides of a divided city.',
);

const _homeState = HomeViewState(
  featured: _wakanda,
  globalTrending: [_wakanda, _arcane],
  newThisWeek: [_wakanda],
  popularMovies: [_wakanda],
  topRatedMovies: [_wakanda],
  topRatedTv: [_arcane],
  airingToday: [_arcane],
  genres: [
    TmdbGenre(id: 28, name: 'Action'),
    TmdbGenre(id: 18, name: 'Drama'),
  ],
);

User _user({String? displayName, String email = 'ijas@example.com'}) {
  return User(
    id: 'user-1',
    appMetadata: const {},
    userMetadata: displayName == null
        ? const {}
        : {'display_name': displayName},
    aud: 'authenticated',
    email: email,
    createdAt: '2026-05-02T00:00:00Z',
  );
}

SocialEntry _socialEntry(
  ContentItem item, {
  bool inWatchlist = false,
  bool isFavorite = false,
  double rating = 0,
}) {
  final now = DateTime(2026);
  return SocialEntry.fromContentItem(
    item,
    rating: rating,
    inWatchlist: inWatchlist,
    isFavorite: isFavorite,
    watchedOn: now,
  );
}

class _FailingAuthRepository extends AuthRepository {
  const _FailingAuthRepository(this.message);

  final String message;

  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    throw AuthException(message);
  }
}

class _SessionAuthRepository extends AuthRepository {
  const _SessionAuthRepository(this.user);

  final User user;

  @override
  User? get currentUser => user;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();
}

class _RecordingAuthRepository extends AuthRepository {
  _RecordingAuthRepository(this.user);

  final User user;
  bool signedOut = false;

  @override
  User? get currentUser => signedOut ? null : user;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

void _expectDiarySegmentStyle(WidgetTester tester, Finder labelFinder) {
  final segment = tester.widget<AnimatedContainer>(
    find.ancestor(of: labelFinder, matching: find.byType(AnimatedContainer)),
  );
  final decoration = segment.decoration! as BoxDecoration;

  expect(segment.constraints, BoxConstraints.tightFor(height: 34));
  expect(decoration.color, VeilColors.panelRaised);
  expect(decoration.borderRadius, BorderRadius.circular(7));
}

class _RankingTmdbRepository extends TmdbRepository {
  _RankingTmdbRepository({
    required this.detailResult,
    required this.trendingItems,
  }) : super(api: Api(), readAccessToken: 'test-token');

  final ContentDetail detailResult;
  final List<ContentItem> trendingItems;

  @override
  Future<ContentDetail> detail(ContentItem item) async => detailResult;

  @override
  Future<List<ContentItem>> trending() async => trendingItems;
}

class _FakeTmdbRepository extends TmdbRepository {
  _FakeTmdbRepository() : super(api: Api(), readAccessToken: 'test-token');

  @override
  Future<List<ContentItem>> trending() async => const [_wakanda];

  @override
  Future<List<ContentItem>> popularMovies() async => const [_wakanda];

  @override
  Future<List<ContentItem>> upcomingMovies() async => const [_wakanda];

  @override
  Future<List<ContentItem>> topRatedMovies() async => const [_wakanda];

  @override
  Future<List<ContentItem>> airingTodayTv() async => const [_arcane];

  @override
  Future<List<String>> genres() async => const ['Action', 'Drama'];

  @override
  Future<List<ContentItem>> search(String query) async => const [_arcane];
}

class _FakeWebViewPlatform extends WebViewPlatform {
  late final _FakeWebViewController controller;
  late final _FakeNavigationDelegate navigationDelegate;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    controller = _FakeWebViewController(params);
    return controller;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    navigationDelegate = _FakeNavigationDelegate(params);
    return navigationDelegate;
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return _FakeWebViewWidget(params);
  }
}

class _FakeWebViewController extends PlatformWebViewController {
  _FakeWebViewController(super.params) : super.implementation();

  final List<String> htmlLoads = [];

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> setOnConsoleMessage(
    void Function(JavaScriptConsoleMessage message) onConsoleMessage,
  ) async {}

  @override
  Future<String?> getUserAgent() async => 'FakeWebView/1.0';

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    htmlLoads.add(html);
  }
}

class _FakeNavigationDelegate extends PlatformNavigationDelegate {
  _FakeNavigationDelegate(super.params) : super.implementation();

  HttpResponseErrorCallback? onHttpError;

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback onHttpError) async {
    this.onHttpError = onHttpError;
  }

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {}

  @override
  Future<void> setOnHttpAuthRequest(
    HttpAuthRequestCallback onHttpAuthRequest,
  ) async {}

  @override
  Future<void> setOnSSlAuthError(SslAuthErrorCallback onSslAuthError) async {}
}

class _FakeWebViewWidget extends PlatformWebViewWidget {
  _FakeWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}
