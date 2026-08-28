import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import 'package:veil/app/services/api_services/api_service.dart';
import 'package:veil/app/services/ad_services/ad_service.dart';
import 'package:veil/app/services/local_storage_services/local_storage_services.dart';
import 'package:veil/main.dart';
import 'package:veil/src/core/providers/ad_providers.dart';
import 'package:veil/src/core/router/route_paths.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/auth/repository/auth_repository.dart';
import 'package:veil/src/features/auth/view_model/premium_view_model/premium_view_model.dart';
import 'package:veil/src/features/auth/view_model/auth_view_model/auth_view_model.dart';
import 'package:veil/src/features/alerts/view/alerts_view.dart';
import 'package:veil/src/features/alerts/view_model/alerts_view_model.dart';
import 'package:veil/src/features/catalog/models/content_detail/content_detail.dart';
import 'package:veil/src/features/catalog/models/curated_collection.dart';
import 'package:veil/src/features/catalog/models/tmdb_watch_provider.dart';
import 'package:veil/src/features/catalog/view/provider_view.dart';
import 'package:veil/src/features/catalog/view/see_all_view.dart';
import 'package:veil/src/features/catalog/view_model/curated_collection_providers.dart';
import 'package:veil/src/features/catalog/view_model/provider_catalog_providers.dart';
import 'package:veil/src/features/home/view_model/home_view_model/home_view_model.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/features/detail/utils/playback_entry_url.dart';
import 'package:veil/src/features/detail/view/detail_view.dart';
import 'package:veil/src/features/detail/view_model/detail_view_model/detail_view_model.dart';
import 'package:veil/src/features/detail/widgets/detail_recommendation_rails.dart';
import 'package:veil/src/features/detail/widgets/detail_review_sheet.dart';
import 'package:veil/src/features/detail/widgets/detail_social_action_sheet.dart';
import 'package:veil/src/features/detail/widgets/detail_suggestion_sheet.dart';
import 'package:veil/src/features/embeded_player/view/direct_video_player.dart';
import 'package:veil/src/features/embeded_player/view/player.dart';
import 'package:veil/src/features/embeded_player/utils/compact_web_player_policy.dart';
import 'package:veil/src/features/home/view/home_view.dart';
import 'package:veil/src/features/home/widgets/curated_collection_section.dart';
import 'package:veil/src/features/home/widgets/watch_provider_section.dart';
import 'package:veil/src/features/playback_history/models/playback_history_entry.dart';
import 'package:veil/src/features/playback_history/repository/playback_history_repository.dart';
import 'package:veil/src/features/playback_history/view_model/playback_history_view_model.dart';
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
import 'package:veil/src/shared/models/playback_request.dart';
import 'package:veil/src/shared/models/alert_item.dart';
import 'package:veil/src/shared/components/content_cards.dart';
import 'package:veil/src/shared/components/poster_art.dart';
import 'package:veil/src/shared/components/skeleton.dart';
import 'package:veil/src/shared/components/veil_filter_chips.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  final emptyAlertsOverride = alertsViewModelProvider.overrideWithValue(
    const AlertsViewState(),
  );
  final emptyHomeDiscoveryOverrides = [
    watchProvidersProvider.overrideWith((ref) async => const []),
    curatedCollectionsProvider.overrideWith((ref) async => const []),
  ];

  setUp(() {
    WebViewPlatform.instance = _FakeWebViewPlatform();
  });

  testWidgets('onboarding describes a movie logging app', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
        ],
        child: const VeilApp(),
      ),
    );

    expect(find.text('VEIL'), findsWidgets);
    expect(find.textContaining('Discover movies'), findsOneWidget);
    expect(find.textContaining('streaming'), findsNothing);
  });

  testWidgets('sign up asks for a display name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
        ],
        child: const VeilApp(),
      ),
    );

    await tester.tap(find.text('New here? Create account'));
    await tester.pump();

    expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('sign up requires terms acceptance before account creation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
        ],
        child: const VeilApp(),
      ),
    );

    await tester.tap(find.text('New here? Create account'));
    await tester.pump();

    final agreementText = find.byWidgetPredicate((widget) {
      return widget is RichText &&
          widget.text.toPlainText() ==
              'I agree to the Terms and Privacy Policy';
    });
    expect(agreementText, findsOneWidget);

    final agreementSpan =
        tester.widget<RichText>(agreementText).text as TextSpan;
    final agreementChildren = agreementSpan.children!.whereType<TextSpan>();
    expect(
      agreementChildren.singleWhere((span) => span.text == 'Terms').recognizer,
      isNotNull,
    );
    expect(
      agreementChildren
          .singleWhere((span) => span.text == 'Privacy Policy')
          .recognizer,
      isNotNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Create account'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Create account'),
          )
          .onPressed,
      isNotNull,
    );
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
        overrides: [
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
        ],
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
          ...emptyHomeDiscoveryOverrides,
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

    expect(find.byKey(const ValueKey('home-cinematic-hero')), findsOneWidget);
    expect(find.text('Log every film\nyou watch'), findsNothing);
  });

  testWidgets('login failure shows a visible toast', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...emptyHomeDiscoveryOverrides,
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

  testWidgets('login password field toggles visibility', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
        ],
        child: const VeilApp(),
      ),
    );

    final passwordField = find.widgetWithText(TextField, 'Password');
    expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
    expect(find.byTooltip('Show password'), findsOneWidget);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
    expect(find.byTooltip('Hide password'), findsOneWidget);

    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();

    expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
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
          ...emptyHomeDiscoveryOverrides,
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

    expect(find.text('Tonight on Veil'), findsNothing);
    expect(find.textContaining('Hello,'), findsNothing);
    expect(find.byKey(const ValueKey('home-cinematic-hero')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Global trending'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Global trending'), findsOneWidget);
    expect(find.text('Continue watching'), findsNothing);
    expect(find.text('Browse by mood'), findsNothing);
    expect(find.text('Action'), findsWidgets);
    expect(find.text('Search'), findsNothing);
    expect(find.text('Alerts'), findsNothing);
    expect(find.text('Home'), findsOneWidget);

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, 1000),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('home-hero-search')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Search'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('home hero removes greeting regardless of signed in user', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
          authViewModelProvider.overrideWithValue(
            AuthViewState(user: _user(displayName: 'Ijas Huzain')),
          ),
        ],
        child: const VeilApp(skipOnboarding: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.textContaining('Hello,'), findsNothing);
    expect(find.text('Tonight on Veil'), findsNothing);
    expect(find.text('Hello, Aman'), findsNothing);
  });

  testWidgets(
    'selected home genre uses phone poster grid without a title and opens Detail',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const selectedGenre = TmdbGenre(id: 99, name: 'Neo Noir');
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeView()),
          GoRoute(
            path: RoutePaths.detail,
            builder: (_, state) =>
                Scaffold(body: Text('Opened ${state.pathParameters['id']}')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emptyAlertsOverride,
            authViewModelProvider.overrideWithValue(const AuthViewState()),
            playbackHistoryViewModelProvider.overrideWithValue(const []),
            homeViewModelProvider.overrideWithValue(
              _homeState.copyWith(
                globalTrending: const [_wakanda],
                genres: const [selectedGenre],
                selectedGenre: selectedGenre,
                genreResults: const [_wakanda, _arcane],
                genreStatus: const Status.success(),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      expect(find.text('Neo Noir'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
      final grid = tester.widget<SliverGrid>(
        find.byKey(const ValueKey('home-genre-grid')),
      );
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
      expect(delegate.mainAxisSpacing, 20);
      expect(delegate.crossAxisSpacing, 12);
      expect(delegate.childAspectRatio, .49);
      expect(find.byType(PosterCard), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('genre-result-movie-505642')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('genre-result-tv-94605')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      for (final item in const [_wakanda, _arcane]) {
        final card = tester.widget<PosterCard>(
          find.byKey(ValueKey('genre-result-${item.id}')),
        );
        expect(card.onTap, isNotNull);
      }

      await tester.tap(find.byKey(const ValueKey('genre-result-movie-505642')));
      await tester.pumpAndSettle();
      expect(find.text('Opened movie-505642'), findsOneWidget);
    },
  );

  testWidgets(
    'selected home genre uses expanded poster grid without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const selectedGenre = TmdbGenre(id: 99, name: 'Neo Noir');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emptyAlertsOverride,
            authViewModelProvider.overrideWithValue(const AuthViewState()),
            playbackHistoryViewModelProvider.overrideWithValue(const []),
            homeViewModelProvider.overrideWithValue(
              _homeState.copyWith(
                genres: const [selectedGenre],
                selectedGenre: selectedGenre,
                genreResults: const [_wakanda, _arcane],
                genreStatus: const Status.success(),
              ),
            ),
          ],
          child: const MaterialApp(home: HomeView()),
        ),
      );
      await tester.pump();

      final grid = tester.widget<SliverGrid>(
        find.byKey(const ValueKey('home-genre-grid')),
      );
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 6);
      expect(delegate.childAspectRatio, .49);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selected home genre loading uses responsive poster grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const selectedGenre = TmdbGenre(id: 99, name: 'Neo Noir');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...emptyHomeDiscoveryOverrides,
          emptyAlertsOverride,
          authViewModelProvider.overrideWithValue(const AuthViewState()),
          playbackHistoryViewModelProvider.overrideWithValue(const []),
          homeViewModelProvider.overrideWithValue(
            _homeState.copyWith(
              genres: const [selectedGenre],
              selectedGenre: selectedGenre,
              genreResults: const [],
              genreStatus: const Status.loading(),
            ),
          ),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pump();

    var grid = tester.widget<SliverGrid>(
      find.byKey(const ValueKey('home-genre-loading-grid')),
    );
    var delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    expect(delegate.mainAxisSpacing, 20);
    expect(delegate.crossAxisSpacing, 12);
    expect(delegate.childAspectRatio, .49);
    expect(find.byType(SkeletonBox), findsWidgets);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pump();

    grid = tester.widget<SliverGrid>(
      find.byKey(const ValueKey('home-genre-loading-grid')),
    );
    delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected home genre pagination keeps appended posters visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _PagedHomeTmdbRepository({
      1: const [_wakanda],
      2: const [_arcane],
      3: const [],
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...emptyHomeDiscoveryOverrides,
          emptyAlertsOverride,
          authViewModelProvider.overrideWithValue(const AuthViewState()),
          playbackHistoryViewModelProvider.overrideWithValue(const []),
          tmdbRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Action'));
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('genre-result-movie-505642')),
      findsOneWidget,
    );
    expect(find.text('Load more'), findsOneWidget);

    await tester.tap(find.text('Load more'));
    await tester.pump();
    await tester.pump();

    expect(repository.requestedPages, [1, 2]);
    expect(
      find.byKey(const ValueKey('genre-result-movie-505642')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('genre-result-tv-94605')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pinned home genres stay below the status bar', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
        ],
        child: const VeilApp(skipOnboarding: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final categories = find.byKey(const ValueKey('home-category-tabs'));
    expect(categories, findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-pinned-category-bar')),
      findsNothing,
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(categories, findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-pinned-category-bar')),
      findsOneWidget,
    );
    expect(tester.getTopLeft(categories).dy, closeTo(47, .01));
  });

  testWidgets('profile shows support and account links', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
        ],
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
    expect(find.text('Letterboxd Import/Export'), findsOneWidget);
    expect(find.text('Support & Safety'), findsOneWidget);
    expect(find.text('Privacy choices'), findsNothing);
    expect(find.textContaining('This product uses TMDB'), findsNothing);
  });

  testWidgets('profile exposes required AdMob privacy choices', (tester) async {
    final adService = _PrivacyAdService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
          adServiceProvider.overrideWithValue(adService),
        ],
        child: const VeilApp(skipOnboarding: true),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pump();

    expect(find.text('Privacy choices'), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-adaptive-banner')), findsNothing);
    await tester.tap(find.text('Privacy choices'));
    await tester.pump();
    expect(adService.privacyCalls, 1);
  });

  testWidgets('app router stays stable through responsive metric changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
        ],
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
        overrides: [
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
        ],
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

  testWidgets('detail server two launches movie playback request', (
    tester,
  ) async {
    final enrichedItem = _wakanda.copyWith(imdbId: 'tt9114286');
    PlaybackRequest? launched;

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
            playbackLauncher: (_, request) async {
              launched = request;
              return true;
            },
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
    expect(find.text('Server 3'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('detail-playback-server-panel')),
        matching: find.textContaining('Cinejoy'),
      ),
      findsNothing,
    );
    expect(find.text('Current source'), findsNothing);
    expect(find.text('vidsrc.to'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('playback-server-2')));
    await tester.pump();

    expect(launched?.server, PlaybackServer.two);
    expect(launched?.item.remoteId, 505642);
    expect(launched?.season, 1);
    expect(launched?.episode, 1);
  });

  testWidgets('detail server two records successful playback request', (
    tester,
  ) async {
    final historyRepository = _RecordingPlaybackHistoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_wakanda).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(_wakanda)),
          ),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
          authViewModelProvider.overrideWithValue(AuthViewState(user: _user())),
          playbackHistoryRepositoryProvider.overrideWithValue(
            historyRepository,
          ),
        ],
        child: MaterialApp(
          home: DetailView(
            item: _wakanda,
            playbackLauncher: (_, request) async => true,
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

    expect(historyRepository.requests, hasLength(1));
    expect(historyRepository.requests.single.server, PlaybackServer.two);
    expect(historyRepository.requests.single.item.remoteId, 505642);
  });

  testWidgets('detail server two does not record rejected playback request', (
    tester,
  ) async {
    final historyRepository = _RecordingPlaybackHistoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_wakanda).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(_wakanda)),
          ),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
          authViewModelProvider.overrideWithValue(AuthViewState(user: _user())),
          playbackHistoryRepositoryProvider.overrideWithValue(
            historyRepository,
          ),
        ],
        child: MaterialApp(
          home: DetailView(
            item: _wakanda,
            playbackLauncher: (_, request) async => false,
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

    expect(historyRepository.requests, isEmpty);
    expect(find.text('Player is not available right now.'), findsOneWidget);
  });

  testWidgets('detail server two does not record launcher exceptions', (
    tester,
  ) async {
    final historyRepository = _RecordingPlaybackHistoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_wakanda).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(_wakanda)),
          ),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
          authViewModelProvider.overrideWithValue(AuthViewState(user: _user())),
          playbackHistoryRepositoryProvider.overrideWithValue(
            historyRepository,
          ),
        ],
        child: MaterialApp(
          home: DetailView(
            item: _wakanda,
            playbackLauncher: (_, request) async {
              throw StateError('launcher failed');
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

    expect(historyRepository.requests, isEmpty);
    expect(find.text('Player is not available right now.'), findsOneWidget);
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
    expect(
      find.byKey(const ValueKey('detail-native-after-description')),
      findsOneWidget,
    );
  });

  testWidgets(
    'detail recommendations show headings, dedupe, persist across tabs, and route taps',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final currentDuplicate = _wakanda.copyWith(id: 'current-copy');
      final recommendationDuplicate = _arcane.copyWith(
        id: 'recommendation-copy',
        title: 'Duplicate recommendation',
      );
      final sameRemoteDifferentType = _arcane.copyWith(
        id: 'movie-94605',
        mediaType: 'movie',
        type: 'Movie',
        title: 'Arcane Movie',
      );
      final similarDuplicate = _historyMovie.copyWith(
        id: 'similar-copy',
        title: 'Duplicate similar',
      );
      final detail = ContentDetail(
        item: _wakanda,
        recommendations: [_arcane, currentDuplicate],
        similar: [
          recommendationDuplicate,
          sameRemoteDifferentType,
          _historyMovie,
          similarDuplicate,
          currentDuplicate,
        ],
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const DetailView(item: _wakanda),
          ),
          GoRoute(
            path: RoutePaths.detail,
            builder: (_, state) =>
                Scaffold(body: Text('Opened ${state.pathParameters['id']}')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            detailViewModelProvider(
              _wakanda,
            ).overrideWithValue(DetailViewState(detail: detail)),
            currentUserIsPremiumProvider.overrideWith((ref) async => false),
            socialLibraryViewModelProvider.overrideWithValue(
              const SocialLibraryViewState(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.text('Detail'));
      await tester.pump();
      await tester.tap(find.text('Detail'));
      await tester.pump();
      await tester.ensureVisible(find.text('Recommended for you'));
      await tester.pump();

      expect(find.byType(DetailRecommendationRails), findsOneWidget);
      expect(find.text('Recommended for you'), findsOneWidget);
      expect(find.text('More like this'), findsOneWidget);
      expect(find.text(_arcane.title), findsOneWidget);
      expect(find.text('Arcane Movie'), findsOneWidget);
      expect(find.text(_historyMovie.title), findsOneWidget);
      expect(find.text('Duplicate recommendation'), findsNothing);
      expect(find.text('Duplicate similar'), findsNothing);
      expect(find.text(_wakanda.title), findsOneWidget);
      expect(find.byType(PosterCard), findsNWidgets(3));
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text(_arcane.title));
      await tester.tap(find.text(_arcane.title));
      await tester.pumpAndSettle();

      expect(find.text('Opened tv-94605'), findsOneWidget);
    },
  );

  testWidgets('detail recommendations render nothing when empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DetailRecommendationRails(recommendations: [], similar: []),
        ),
      ),
    );

    expect(find.byType(DetailRecommendationRails), findsOneWidget);
    expect(find.text('Recommended for you'), findsNothing);
    expect(find.text('More like this'), findsNothing);
    expect(find.byType(PosterCard), findsNothing);
    expect(find.byType(ListView), findsNothing);
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

  testWidgets('detail server two launches selected tv episode', (tester) async {
    const detail = ContentDetail(item: _arcane, seasons: 3, episodes: 24);
    PlaybackRequest? launched;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(
            _arcane,
          ).overrideWithValue(const DetailViewState(detail: detail)),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          home: DetailView(
            item: _arcane,
            playbackLauncher: (_, request) async {
              launched = request;
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

    expect(
      find.byKey(const ValueKey('detail-season-episode-panel')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('playback-season-increment')));
    await tester.tap(find.byKey(const ValueKey('playback-episode-increment')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('playback-season-episode-play')),
    );
    await tester.pump();

    expect(launched?.server, PlaybackServer.two);
    expect(launched?.item.remoteId, 94605);
    expect(launched?.season, 2);
    expect(launched?.episode, 2);
  });

  testWidgets('detail server two works without an IMDb id', (tester) async {
    PlaybackRequest? launched;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_wakanda).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(_wakanda)),
          ),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          home: DetailView(
            item: _wakanda,
            playbackLauncher: (_, request) async {
              launched = request;
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

    expect(_wakanda.imdbId, isNull);
    expect(launched?.server, PlaybackServer.two);
    expect(launched?.item.remoteId, 505642);
  });

  testWidgets('detail server three opens cinesrc tv embed', (tester) async {
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
    await tester.tap(find.byKey(const ValueKey('playback-server-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final player = tester.widget<FullscreenLandscapeWebPlayer>(
      find.byType(FullscreenLandscapeWebPlayer),
    );
    expect(player.url, 'https://cinesrc.st/embed/tv/94605?s=1&e=1');
    expect(player.fallbackUrls, isEmpty);
  });

  testWidgets('detail server four appears in playback server sheet', (
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
        child: const MaterialApp(home: DetailView(item: _wakanda)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const ValueKey('playback-server-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('playback-server-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('playback-server-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('playback-server-4')), findsOneWidget);
  });

  testWidgets('detail server four opens movie VidLink in web player', (
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
        child: const MaterialApp(home: DetailView(item: _wakanda)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const ValueKey('playback-server-4')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(FullscreenLandscapeDirectVideoPlayer), findsNothing);
    final player = tester.widget<FullscreenLandscapeWebPlayer>(
      find.byType(FullscreenLandscapeWebPlayer),
    );
    expect(
      player.url,
      'https://vidlink.pro/movie/505642?player=jw&primaryColor=FFFFFF&secondaryColor=253034&iconColor=FFFFFF',
    );
    expect(player.fallbackUrls, isEmpty);
    expect(player.loadAsPage, isTrue);
  });

  testWidgets('detail server four asks for tv episode before VidLink playback', (
    tester,
  ) async {
    const detail = ContentDetail(item: _arcane, seasons: 3, episodes: 24);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(
            _arcane,
          ).overrideWithValue(const DetailViewState(detail: detail)),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(home: DetailView(item: _arcane)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const ValueKey('playback-server-4')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(FullscreenLandscapeDirectVideoPlayer), findsNothing);
    expect(
      find.byKey(const ValueKey('detail-season-episode-panel')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('playback-season-increment')));
    await tester.tap(find.byKey(const ValueKey('playback-episode-increment')));
    await tester.tap(find.byKey(const ValueKey('playback-episode-increment')));
    await tester.pump();

    expect(find.text('Season 2'), findsOneWidget);
    expect(find.text('Episode 3'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('playback-season-episode-play')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(FullscreenLandscapeDirectVideoPlayer), findsNothing);
    final player = tester.widget<FullscreenLandscapeWebPlayer>(
      find.byType(FullscreenLandscapeWebPlayer),
    );
    expect(
      player.url,
      'https://vidlink.pro/tv/94605/2/3?player=jw&primaryColor=FFFFFF&secondaryColor=253034&iconColor=FFFFFF',
    );
    expect(player.fallbackUrls, isEmpty);
    expect(player.loadAsPage, isTrue);
  });

  testWidgets('detail server four shows unavailable when TMDB id is missing', (
    tester,
  ) async {
    final item = _wakanda.copyWith(remoteId: 0, imdbId: 'tt9114286');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(item).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(item)),
          ),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(home: DetailView(item: item)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const ValueKey('playback-server-4')));
    await tester.pump();

    expect(
      find.text('TMDB id is not available for this title yet.'),
      findsOneWidget,
    );
    expect(find.byType(FullscreenLandscapeDirectVideoPlayer), findsNothing);
    expect(find.byType(FullscreenLandscapeWebPlayer), findsNothing);
  });

  testWidgets('detail server one asks for tv episode before Vidsrc playback', (
    tester,
  ) async {
    const detail = ContentDetail(item: _arcane, seasons: 3, episodes: 24);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(
            _arcane,
          ).overrideWithValue(const DetailViewState(detail: detail)),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(home: DetailView(item: _arcane)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const ValueKey('playback-server-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(FullscreenLandscapeDirectVideoPlayer), findsNothing);
    expect(
      find.byKey(const ValueKey('detail-season-episode-panel')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('playback-season-increment')));
    await tester.tap(find.byKey(const ValueKey('playback-episode-increment')));
    await tester.tap(find.byKey(const ValueKey('playback-episode-increment')));
    await tester.pump();

    expect(find.text('Season 2'), findsOneWidget);
    expect(find.text('Episode 3'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('playback-season-episode-play')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(FullscreenLandscapeDirectVideoPlayer), findsNothing);
    final player = tester.widget<FullscreenLandscapeWebPlayer>(
      find.byType(FullscreenLandscapeWebPlayer),
    );
    expect(
      player.url,
      'https://vidsrc-embed.ru/embed/tv?tmdb=94605&season=2&episode=3&autoplay=1&autonext=1',
    );
    expect(player.fallbackUrls, isEmpty);
    expect(player.loadAsPage, isTrue);
  });

  testWidgets('detail server one uses IMDb fallback for tv episode', (
    tester,
  ) async {
    final item = _arcane.copyWith(remoteId: 0, imdbId: 'tt0944947');
    final detail = ContentDetail(item: item, seasons: 3, episodes: 24);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(
            item,
          ).overrideWithValue(DetailViewState(detail: detail)),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(home: DetailView(item: item)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const ValueKey('playback-server-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.byKey(const ValueKey('playback-season-increment')));
    await tester.tap(find.byKey(const ValueKey('playback-episode-increment')));
    await tester.tap(find.byKey(const ValueKey('playback-episode-increment')));
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('playback-season-episode-play')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(FullscreenLandscapeDirectVideoPlayer), findsNothing);
    final player = tester.widget<FullscreenLandscapeWebPlayer>(
      find.byType(FullscreenLandscapeWebPlayer),
    );
    expect(
      player.url,
      'https://vidsrc-embed.ru/embed/tv?imdb=tt0944947&season=2&episode=3&autoplay=1&autonext=1',
    );
    expect(player.fallbackUrls, isEmpty);
    expect(player.loadAsPage, isTrue);
  });

  testWidgets('detail server one opens movie Vidsrc embed in web player', (
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
        child: const MaterialApp(home: DetailView(item: _wakanda)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const ValueKey('playback-server-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(FullscreenLandscapeDirectVideoPlayer), findsNothing);
    final player = tester.widget<FullscreenLandscapeWebPlayer>(
      find.byType(FullscreenLandscapeWebPlayer),
    );
    expect(
      player.url,
      'https://vidsrc-embed.ru/embed/movie?tmdb=505642&autoplay=1',
    );
    expect(player.fallbackUrls, isEmpty);
    expect(player.loadAsPage, isTrue);
  });

  testWidgets(
    'detail server sheet shows unavailable when playback ids are missing',
    (tester) async {
      final item = _wakanda.copyWith(remoteId: 0);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            detailViewModelProvider(item).overrideWithValue(
              DetailViewState(detail: ContentDetail.fallback(item)),
            ),
            currentUserIsPremiumProvider.overrideWith((ref) async => true),
          ],
          child: MaterialApp(home: DetailView(item: item)),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Play'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        find.text('Playback id is not available for this title yet.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('detail-playback-server-panel')),
        findsNothing,
      );
      expect(find.byType(FullscreenLandscapeDirectVideoPlayer), findsNothing);
      expect(find.byType(FullscreenLandscapeWebPlayer), findsNothing);
    },
  );

  testWidgets('detail server three stays embedded', (tester) async {
    final enrichedItem = _arcane.copyWith(imdbId: 'tt0944947');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_arcane).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(enrichedItem)),
          ),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
        ],
        child: const MaterialApp(home: DetailView(item: _arcane)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const ValueKey('playback-server-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final player = tester.widget<FullscreenLandscapeWebPlayer>(
      find.byType(FullscreenLandscapeWebPlayer),
    );
    expect(player.url, 'https://cinesrc.st/embed/tv/94605?s=1&e=1');
    expect(player.fallbackUrls, isEmpty);
  });

  testWidgets('detail server two keeps play loading while launcher runs', (
    tester,
  ) async {
    final launcherCompleter = Completer<bool>();
    var launcherCalls = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          detailViewModelProvider(_wakanda).overrideWithValue(
            DetailViewState(detail: ContentDetail.fallback(_wakanda)),
          ),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          home: DetailView(
            item: _wakanda,
            playbackLauncher: (_, request) {
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
    await tester.tap(find.byKey(const ValueKey('playback-server-2')));
    await tester.pump();

    expect(launcherCalls, 1);
    expect(find.text('Loading'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    launcherCompleter.complete(true);
    await tester.pump();
    expect(find.text('Play'), findsOneWidget);
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

  test('vidsrc playback urls use tmdb first and imdb fallback', () {
    expect(
      vidsrcPlaybackUrl(tmdbId: 505642, contentType: 'Movie').toString(),
      'https://vidsrc-embed.ru/embed/movie?tmdb=505642&autoplay=1',
    );
    expect(
      vidsrcPlaybackUrl(
        tmdbId: 0,
        imdbId: 'tt9114286',
        contentType: 'Movie',
      ).toString(),
      'https://vidsrc-embed.ru/embed/movie?imdb=tt9114286&autoplay=1',
    );
    expect(
      vidsrcPlaybackUrl(
        tmdbId: 94605,
        imdbId: 'tt0944947',
        contentType: 'TV Show',
        season: 2,
        episode: 3,
      ).toString(),
      'https://vidsrc-embed.ru/embed/tv?tmdb=94605&season=2&episode=3&autoplay=1&autonext=1',
    );
    expect(
      vidsrcPlaybackUrl(
        imdbId: 'tt0944947',
        contentType: 'Series',
        season: 0,
        episode: -1,
      ).toString(),
      'https://vidsrc-embed.ru/embed/tv?imdb=tt0944947&season=1&episode=1&autoplay=1&autonext=1',
    );
    expect(vidsrcPlaybackUrl(contentType: 'Movie'), isNull);
  });

  test('vidlink playback urls use tmdb movie and tv paths', () {
    expect(
      vidlinkPlaybackUrl(tmdbId: 505642, contentType: 'Movie').toString(),
      'https://vidlink.pro/movie/505642?player=jw&primaryColor=FFFFFF&secondaryColor=253034&iconColor=FFFFFF',
    );
    expect(
      vidlinkPlaybackUrl(
        tmdbId: 94605,
        contentType: 'TV Show',
        season: 2,
        episode: 3,
      ).toString(),
      'https://vidlink.pro/tv/94605/2/3?player=jw&primaryColor=FFFFFF&secondaryColor=253034&iconColor=FFFFFF',
    );
    expect(
      vidlinkPlaybackUrl(
        tmdbId: 94605,
        contentType: 'Series',
        season: 0,
        episode: -1,
      ).toString(),
      'https://vidlink.pro/tv/94605/1/1?player=jw&primaryColor=FFFFFF&secondaryColor=253034&iconColor=FFFFFF',
    );
    expect(vidlinkPlaybackUrl(tmdbId: 0, contentType: 'Movie'), isNull);
    expect(vidlinkPlaybackUrl(contentType: 'Movie'), isNull);
  });

  test('cine direct playback urls use movie and episode hls playlists', () {
    expect(
      cineDirectPlaybackUrl(tmdbId: 505642, contentType: 'Movie').toString(),
      'https://verlsbmdqggejpfmvzue.supabase.co/functions/v1/proxy?url='
      'https%3A%2F%2Fcine.su%2Fv1%2Fstream%2Fmaster%2Fmovie%2F505642.m3u8',
    );
    expect(
      cineDirectPlaybackUrl(
        tmdbId: 94605,
        contentType: 'TV Show',
        season: 2,
        episode: 3,
      ).toString(),
      'https://verlsbmdqggejpfmvzue.supabase.co/functions/v1/proxy?url='
      'https%3A%2F%2Fcine.su%2Fv1%2Fstream%2Fmaster%2Ftv%2F94605%2F2%2F3.m3u8',
    );
    expect(
      cineDirectPlaybackUrl(
        tmdbId: 94605,
        contentType: 'Series',
        season: 0,
        episode: -1,
      ).toString(),
      'https://verlsbmdqggejpfmvzue.supabase.co/functions/v1/proxy?url='
      'https%3A%2F%2Fcine.su%2Fv1%2Fstream%2Fmaster%2Ftv%2F94605%2F1%2F1.m3u8',
    );
  });

  test('vidnest playback urls use movie and episode embeds', () {
    expect(
      vidnestPlaybackUrl(tmdbId: 1336770, contentType: 'Movie').toString(),
      'https://vidnest.fun/movie/1336770?muted=0&mute=0&volume=100',
    );
    expect(
      vidnestPlaybackUrl(
        tmdbId: 94605,
        contentType: 'TV Show',
        season: 2,
        episode: 3,
      ).toString(),
      'https://vidnest.fun/tv/94605/2/3?muted=0&mute=0&volume=100',
    );
    expect(
      vidnestPlaybackUrl(
        tmdbId: 94605,
        contentType: 'Series',
        season: 0,
        episode: -1,
      ).toString(),
      'https://vidnest.fun/tv/94605/1/1?muted=0&mute=0&volume=100',
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
      contains(htmlEscape.convert(primaryUrl.toString())),
    );
    expect(
      platform.controller.htmlLoads.single,
      contains('allow-popups allow-popups-to-escape-sandbox'),
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

  testWidgets('mobile player can load Vidsrc as a top-level page', (
    tester,
  ) async {
    final platform = _FakeWebViewPlatform();
    WebViewPlatform.instance = platform;
    final vidsrcUrl = Uri.parse(
      'https://vidsrc-embed.ru/embed/movie?tmdb=505642&autoplay=1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FullscreenLandscapeWebPlayer(
          url: vidsrcUrl.toString(),
          loadAsPage: true,
          showCloseButton: false,
        ),
      ),
    );
    await tester.pump();

    expect(platform.controller.htmlLoads, isEmpty);
    expect(platform.controller.requestLoads, [vidsrcUrl]);
    expect(
      await platform.navigationDelegate.onNavigationRequest?.call(
        NavigationRequest(url: vidsrcUrl.toString(), isMainFrame: true),
      ),
      NavigationDecision.navigate,
    );
    expect(
      await platform.navigationDelegate.onNavigationRequest?.call(
        const NavigationRequest(
          url: 'https://vsembed.ru/embed/movie?tmdb=505642&autoplay=1',
          isMainFrame: true,
        ),
      ),
      NavigationDecision.navigate,
    );
    expect(
      await platform.navigationDelegate.onNavigationRequest?.call(
        const NavigationRequest(
          url: 'https://ads.example.com/landing',
          isMainFrame: true,
        ),
      ),
      NavigationDecision.prevent,
    );
    expect(
      await platform.navigationDelegate.onNavigationRequest?.call(
        const NavigationRequest(
          url: 'https://cloudorchestranova.com/rcp/player',
          isMainFrame: false,
        ),
      ),
      NavigationDecision.navigate,
    );
  });

  testWidgets('server two mobile player allows Cinejoy watch paths', (
    tester,
  ) async {
    final platform = _FakeWebViewPlatform();
    WebViewPlatform.instance = platform;
    final cinejoyUrl = Uri.parse('https://cinejoy.to/watch/movie/1284041');

    await tester.pumpWidget(
      MaterialApp(
        home: FullscreenLandscapeWebPlayer(
          url: cinejoyUrl.toString(),
          loadAsPage: true,
          showCloseButton: false,
        ),
      ),
    );
    await tester.pump();

    expect(platform.controller.htmlLoads, isEmpty);
    expect(platform.controller.requestLoads, [cinejoyUrl]);
    expect(
      await platform.navigationDelegate.onNavigationRequest?.call(
        NavigationRequest(url: cinejoyUrl.toString(), isMainFrame: true),
      ),
      NavigationDecision.navigate,
    );
    expect(
      await platform.navigationDelegate.onNavigationRequest?.call(
        const NavigationRequest(
          url: 'https://cinejoy.to/watch/tv/94997/2/2',
          isMainFrame: true,
        ),
      ),
      NavigationDecision.navigate,
    );
    expect(
      await platform.navigationDelegate.onNavigationRequest?.call(
        const NavigationRequest(
          url: 'https://cinejoy.to/browse',
          isMainFrame: true,
        ),
      ),
      NavigationDecision.prevent,
    );
    expect(
      await platform.navigationDelegate.onNavigationRequest?.call(
        const NavigationRequest(url: 'https://ad.example/', isMainFrame: true),
      ),
      NavigationDecision.prevent,
    );
  });

  testWidgets('server four mobile player can load VidLink as a top-level page', (
    tester,
  ) async {
    final platform = _FakeWebViewPlatform();
    WebViewPlatform.instance = platform;
    final vidlinkUrl = Uri.parse(
      'https://vidlink.pro/movie/505642?player=jw&primaryColor=FFFFFF&secondaryColor=253034&iconColor=FFFFFF',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FullscreenLandscapeWebPlayer(
          url: vidlinkUrl.toString(),
          loadAsPage: true,
          showCloseButton: false,
        ),
      ),
    );
    await tester.pump();

    expect(platform.controller.htmlLoads, isEmpty);
    expect(platform.controller.requestLoads, [vidlinkUrl]);
    expect(
      await platform.navigationDelegate.onNavigationRequest?.call(
        NavigationRequest(url: vidlinkUrl.toString(), isMainFrame: true),
      ),
      NavigationDecision.navigate,
    );
    expect(
      await platform.navigationDelegate.onNavigationRequest?.call(
        const NavigationRequest(
          url:
              'https://vidlink.pro/tv/94605/2/3?player=jw&primaryColor=FFFFFF&secondaryColor=253034&iconColor=FFFFFF',
          isMainFrame: true,
        ),
      ),
      NavigationDecision.navigate,
    );
    expect(
      await platform.navigationDelegate.onNavigationRequest?.call(
        const NavigationRequest(
          url: 'https://vidlink.pro/anime/5/1/sub',
          isMainFrame: true,
        ),
      ),
      NavigationDecision.prevent,
    );
    expect(
      await platform.navigationDelegate.onNavigationRequest?.call(
        const NavigationRequest(
          url: 'https://ads.example.com/landing',
          isMainFrame: true,
        ),
      ),
      NavigationDecision.prevent,
    );
    expect(
      await platform.navigationDelegate.onNavigationRequest?.call(
        const NavigationRequest(
          url: 'https://cloudorchestranova.com/rcp/player',
          isMainFrame: false,
        ),
      ),
      NavigationDecision.navigate,
    );
  });

  testWidgets('direct mobile player renders video html without an iframe', (
    tester,
  ) async {
    final platform = _FakeWebViewPlatform();
    WebViewPlatform.instance = platform;
    final streamUrl = Uri.parse(
      'https://cine.su/v1/stream/master/tv/94605/1/1.m3u8',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FullscreenLandscapeDirectVideoPlayer(
          url: streamUrl.toString(),
          showCloseButton: false,
        ),
      ),
    );
    await tester.pump();

    expect(platform.controller.htmlLoads, hasLength(1));
    expect(platform.controller.htmlLoads.single, contains('<video'));
    expect(platform.controller.htmlLoads.single, isNot(contains('<iframe')));
    expect(
      platform.controller.htmlLoads.single,
      contains('https://cdn.jsdelivr.net/npm/hls.js@latest'),
    );
    expect(
      platform.controller.htmlLoads.single.indexOf('window.Hls.isSupported()'),
      lessThan(
        platform.controller.htmlLoads.single.indexOf('const nativeSupport'),
      ),
    );
    expect(
      platform.controller.htmlLoads.single,
      contains('"${streamUrl.toString()}"'),
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
          ...emptyHomeDiscoveryOverrides,
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

  testWidgets('search back button uses Veil glass navigation style', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchViewModelProvider.overrideWithValue(const SearchViewState()),
          socialLibraryViewModelProvider.overrideWithValue(
            const SocialLibraryViewState(),
          ),
        ],
        child: const MaterialApp(home: SearchView(showBack: true)),
      ),
    );
    await tester.pump();

    final button = tester.widget<IconButton>(
      find.byKey(const ValueKey('search-back-button')),
    );
    expect(button.style?.shape?.resolve({}), isA<CircleBorder>());
    expect(
      button.style?.backgroundColor?.resolve({}),
      VeilColors.panel.withValues(alpha: .72),
    );
    expect(button.style?.minimumSize?.resolve({}), const Size.square(38));
    expect(button.style?.maximumSize?.resolve({}), const Size.square(38));
    expect(
      button.style?.side?.resolve({})?.color,
      Colors.white.withValues(alpha: .20),
    );
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

    await tester.tap(find.text('Helpful'));
    await tester.pump();
    expect((await repository.reviews()).single.helpful, isTrue);

    await tester.tap(find.text('Comment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Comments'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Great take');
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Post'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Great take'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('1 comment'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete review').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('My local review.'), findsNothing);
    expect(await repository.reviews(), isEmpty);
  });

  testWidgets('review thread supports spoiler comments and replies', (
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
      review: 'Spoiler friendly discussion.',
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
    await tester.tap(find.text('Comment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.enterText(find.byType(TextField).last, 'Secret ending');
    await tester.tap(find.text('Spoiler'));
    await tester.pump();
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Post'))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Spoiler hidden - tap to reveal'), findsOneWidget);
    expect(find.text('Secret ending'), findsNothing);

    await tester.tap(find.text('Spoiler hidden - tap to reveal'));
    await tester.pump();
    expect(find.text('Secret ending'), findsOneWidget);

    await tester.tap(find.text('Reply'));
    await tester.pump();
    expect(find.textContaining('Replying to'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Reply body');
    await tester.pump();
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Post'))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Reply body'), findsOneWidget);
    final review = (await repository.reviews()).single;
    final comments = await repository.reviewComments(review);
    expect(comments, hasLength(2));
    expect(comments.first.isSpoiler, isTrue);
    expect(comments.last.parentCommentId, comments.first.id);
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

  testWidgets('search records opened result titles as recent searches', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: RoutePaths.search,
      routes: [
        GoRoute(path: RoutePaths.search, builder: (_, _) => const SearchView()),
        GoRoute(
          path: RoutePaths.detail,
          builder: (_, _) => const Scaffold(body: Text('Detail opened')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(_FakeTmdbRepository()),
          socialLibraryViewModelProvider.overrideWithValue(
            const SocialLibraryViewState(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Find films, cast + crew, members...'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'arcane');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Arcane'), findsOneWidget);
    expect(find.text('Recent searches'), findsNothing);

    await tester.tap(find.text('Arcane'));
    await tester.pumpAndSettle();

    expect(find.text('Detail opened'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Arcane'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'arcane',
      ),
      findsNothing,
    );
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
    expect(find.text('My Activity'), findsNothing);
    expect(find.text('Letterboxd Import/Export'), findsOneWidget);
    expect(find.text('Support & Safety'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms and Conditions'), findsOneWidget);
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

  testWidgets('user profile supports follow back friends and unfollow states', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    final repository = SocialRepository();
    final memberRepository = SocialRepository(localUserId: 'member-2');

    await memberRepository.followUser(
      'local-user',
      requesterDisplayName: 'Mira',
      recipientDisplayName: 'Ijas Huzain',
    );
    await repository.acceptFollowRequest(
      (await repository.followRequestsForAlerts()).single.id,
    );

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

    expect(find.text('Follow Back'), findsOneWidget);

    await tester.tap(find.text('Follow Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Friends'), findsOneWidget);

    await tester.tap(find.text('Friends'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Follow Back'), findsOneWidget);
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
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
          authViewModelProvider.overrideWithValue(
            AuthViewState(user: _user(displayName: 'Ijas Huzain')),
          ),
        ],
        child: const VeilApp(skipOnboarding: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final navigation = find.byKey(const ValueKey('mobile-shell-navigation'));
    final homePill = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('shell-tab-home')),
    );
    final decoration = homePill.decoration! as BoxDecoration;
    final border = decoration.border! as Border;

    expect(find.byType(NavigationRail), findsNothing);
    expect(navigation, findsOneWidget);
    expect(find.byKey(const ValueKey('shell-adaptive-banner')), findsOneWidget);
    expect(
      find.descendant(of: navigation, matching: find.text('Home')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigation, matching: find.text('Diary')),
      findsNothing,
    );
    for (final icon in const [
      Icons.home_rounded,
      Icons.menu_book_rounded,
      Icons.rate_review_outlined,
      Icons.person_outline_rounded,
    ]) {
      expect(
        find.descendant(of: navigation, matching: find.byIcon(icon)),
        findsOneWidget,
      );
    }
    expect(decoration.color, Colors.white.withValues(alpha: .16));
    expect(decoration.color, isNot(VeilColors.red));
    expect(border.top.color, Colors.white24);
    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: navigation,
              matching: find.byIcon(Icons.home_rounded),
            ),
          )
          .color,
      Colors.white,
    );
    expect(
      tester
          .widget<Text>(
            find.descendant(of: navigation, matching: find.text('Home')),
          )
          .style
          ?.color,
      Colors.white,
    );
    expect(tester.getRect(navigation).left, greaterThanOrEqualTo(0));
    expect(tester.getRect(navigation).right, lessThanOrEqualTo(390));

    await tester.tap(find.byKey(const ValueKey('shell-tab-reviews')));
    await tester.pump();

    expect(
      find.descendant(of: navigation, matching: find.text('Reviews')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navigation, matching: find.text('Home')),
      findsNothing,
    );

    expect(tester.takeException(), isNull);
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
          ...emptyHomeDiscoveryOverrides,
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
    expect(find.byKey(const ValueKey('shell-adaptive-banner')), findsOneWidget);
  });

  testWidgets('poster card rating renders only below title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: PosterCard(item: _wakanda)),
        ),
      ),
    );

    expect(find.text(_wakanda.rating.toStringAsFixed(1)), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: PosterCard(item: _wakanda, showMeta: false)),
        ),
      ),
    );

    expect(find.text(_wakanda.rating.toStringAsFixed(1)), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('provider screen watches and shows only selected tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = _ProviderCatalogTmdbRepository((request) {
      return switch (request.mediaType) {
        'movie' => const [_wakanda],
        'tv' => const [_arcane],
        _ => fail('Unexpected provider request: $request'),
      };
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tmdbRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: ProviderView(providerId: 8, providerName: 'Netflix'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(repository.requests, [(providerId: 8, mediaType: 'movie', page: 1)]);
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byKey(const ValueKey('provider-media-tabs')), findsOneWidget);
    expect(
      tester
          .widget<SliverPersistentHeader>(
            find.byKey(const ValueKey('provider-media-tabs-header')),
          )
          .pinned,
      isTrue,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('provider-media-tabs-header')),
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
    expect(find.text('Streaming catalog'), findsNothing);
    expect(find.textContaining('Streaming availability'), findsNothing);
    expect(find.textContaining('Catalog data by TMDB'), findsNothing);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.title, isNotNull);
    expect(appBar.backgroundColor, Colors.transparent);
    expect(appBar.scrolledUnderElevation, 0);
    final backButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('provider-back-button')),
    );
    expect(backButton.style?.shape?.resolve({}), isA<CircleBorder>());
    expect(
      backButton.style?.backgroundColor?.resolve({}),
      VeilColors.panel.withValues(alpha: .72),
    );
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    final logo = tester.widget<Container>(
      find.byKey(const ValueKey('provider-header-logo')),
    );
    expect(logo.padding, isNull);
    final logoDecoration = logo.decoration! as BoxDecoration;
    expect(logoDecoration.color, isNull);

    expect(find.text(_wakanda.title), findsOneWidget);
    expect(find.text(_arcane.title), findsNothing);
    expect(find.byKey(const ValueKey('provider-tab-movies')), findsOneWidget);
    expect(find.byKey(const ValueKey('provider-tab-tv')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('provider-tab-tv')));
    await tester.pump();
    await tester.pump();

    expect(repository.requests, [
      (providerId: 8, mediaType: 'movie', page: 1),
      (providerId: 8, mediaType: 'tv', page: 1),
    ]);
    expect(find.text(_wakanda.title), findsNothing);
    expect(find.text(_arcane.title), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('provider-tab-movies')));
    await tester.pump();
    await tester.pump();

    expect(repository.requests, [
      (providerId: 8, mediaType: 'movie', page: 1),
      (providerId: 8, mediaType: 'tv', page: 1),
    ]);
    expect(find.text(_wakanda.title), findsOneWidget);
    expect(find.text(_arcane.title), findsNothing);
  });

  testWidgets('provider compact identity follows catalog scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const providerName =
        'A Provider Name Long Enough To Require Compact Title Ellipsis';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(
            _ProviderCatalogTmdbRepository(
              (_) => _providerCatalogItems('provider-collapse', 30),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ProviderView(providerId: 8, providerName: providerName),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final collapsedIdentity = find.byKey(
      const ValueKey('provider-collapsed-identity'),
    );
    Opacity collapsedOpacity() => tester.widget<Opacity>(collapsedIdentity);
    List<Transform> collapsedTransforms() => tester
        .widgetList<Transform>(
          find.descendant(
            of: collapsedIdentity,
            matching: find.byType(Transform),
          ),
        )
        .toList();

    expect(collapsedOpacity().opacity, 0);
    expect(
      tester
          .widget<ExcludeSemantics>(
            find.ancestor(
              of: collapsedIdentity,
              matching: find.byType(ExcludeSemantics),
            ),
          )
          .excluding,
      isTrue,
    );
    expect(collapsedTransforms()[0].transform.getTranslation().y, 8);
    expect(collapsedTransforms()[1].transform.entry(0, 0), .94);
    expect(
      tester.getSize(find.byKey(const ValueKey('provider-collapsed-logo'))),
      const Size.square(38),
    );
    final collapsedName = tester.widget<Text>(
      find.descendant(of: collapsedIdentity, matching: find.text(providerName)),
    );
    expect(collapsedName.maxLines, 1);
    expect(collapsedName.overflow, TextOverflow.ellipsis);
    final initialHeaderTop = tester
        .getTopLeft(find.byKey(const ValueKey('provider-header-logo')))
        .dy;

    await tester.drag(
      find.byKey(const ValueKey('provider-catalog-list')),
      const Offset(0, -60),
    );
    await tester.pump();

    expect(collapsedOpacity().opacity, closeTo(60 / 88, .001));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('provider-header-logo'))).dy,
      lessThan(initialHeaderTop),
    );

    await tester.drag(
      find.byKey(const ValueKey('provider-catalog-list')),
      const Offset(0, -120),
    );
    await tester.pump();

    expect(collapsedOpacity().opacity, 1);
    expect(
      tester
          .widget<ExcludeSemantics>(
            find.ancestor(
              of: collapsedIdentity,
              matching: find.byType(ExcludeSemantics),
            ),
          )
          .excluding,
      isFalse,
    );
    expect(collapsedTransforms()[0].transform.getTranslation().y, 0);
    expect(collapsedTransforms()[1].transform.entry(0, 0), 1);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('provider-media-tabs'))).dy,
      closeTo(tester.getBottomLeft(find.byType(AppBar)).dy + 12, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider screen handles selected empty error and retry states', (
    tester,
  ) async {
    var tvLoads = 0;
    final repository = _ProviderCatalogTmdbRepository((request) {
      if (request.mediaType == 'movie') return const [];
      tvLoads += 1;
      if (tvLoads == 1) throw StateError('TV unavailable');
      return const [_arcane];
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tmdbRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: ProviderView(providerId: 8, providerName: 'Netflix'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('No movies available in the US.'), findsOneWidget);
    expect(find.text('No TV series available in the US.'), findsNothing);
    expect(
      repository.requests
          .where((request) => request.mediaType == 'movie')
          .length,
      1,
    );
    expect(tvLoads, 0);

    await tester.tap(find.byKey(const ValueKey('provider-tab-tv')));
    await tester.pump();
    await tester.pump();

    expect(find.text('No movies available in the US.'), findsNothing);
    expect(find.text('Unable to load TV Series.'), findsOneWidget);
    expect(find.byKey(const ValueKey('provider-tv-retry')), findsOneWidget);
    expect(tvLoads, 1);

    await tester.tap(find.byKey(const ValueKey('provider-tv-retry')));
    await tester.pump();
    await tester.pump();

    expect(tvLoads, 2);
    expect(find.text(_arcane.title), findsOneWidget);
    expect(find.byKey(const ValueKey('provider-tv-retry')), findsNothing);
  });

  testWidgets('provider screen grid uses responsive poster columns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(
            _ProviderCatalogTmdbRepository((_) => const [_wakanda, _arcane]),
          ),
        ],
        child: const MaterialApp(
          home: ProviderView(providerId: 8, providerName: 'Netflix'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    var grid = tester.widget<SliverGrid>(
      find.byKey(const ValueKey('provider-catalog-grid')),
    );
    var delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    expect(delegate.childAspectRatio, .49);
    expect(find.byType(PosterCard), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pump();

    grid = tester.widget<SliverGrid>(
      find.byKey(const ValueKey('provider-catalog-grid')),
    );
    delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider screen loading skeleton matches poster grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final movies = Completer<List<ContentItem>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(
            _ProviderCatalogTmdbRepository((_) => movies.future),
          ),
        ],
        child: const MaterialApp(
          home: ProviderView(providerId: 8, providerName: 'Netflix'),
        ),
      ),
    );
    await tester.pump();

    final grid = tester.widget<SliverGrid>(
      find.byKey(const ValueKey('provider-catalog-loading-grid')),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    expect(delegate.mainAxisSpacing, 20);
    expect(delegate.crossAxisSpacing, 12);
    expect(delegate.childAspectRatio, .49);
    expect(find.byType(SkeletonBox), findsWidgets);

    movies.complete(const []);
    await tester.pump();
  });

  testWidgets(
    'provider screen loads page 2 once and preserves items for retry',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final page1 = _providerCatalogItems('provider-page-1', 30);
      final firstPage2 = Completer<List<ContentItem>>();
      var page2Attempts = 0;
      final repository = _ProviderCatalogTmdbRepository((request) {
        if (request.page == 1) return page1;
        page2Attempts += 1;
        if (page2Attempts == 1) return firstPage2.future;
        return _providerCatalogItems('provider-page-2', 1);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [tmdbRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(
            home: ProviderView(providerId: 8, providerName: 'Netflix'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.drag(
        find.byKey(const ValueKey('provider-catalog-list')),
        const Offset(0, -3000),
      );
      await tester.pump();

      expect(
        repository.requests.where((request) => request.page == 2).length,
        1,
      );
      expect(
        find.byKey(const ValueKey('provider-load-more-progress')),
        findsOneWidget,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProviderView)),
      );
      final provider = providerCatalogProvider(8, 'movie');
      expect(container.read(provider).items, page1);

      firstPage2.completeError(StateError('page 2 unavailable'));
      await tester.pump();
      await tester.pump();

      expect(container.read(provider).items, page1);
      expect(container.read(provider).loadMoreError, isNotEmpty);
      expect(
        find.byKey(
          const ValueKey('provider-catalog-ad-grid'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('provider-load-more-retry')),
        findsOneWidget,
      );

      final retry = find.byKey(const ValueKey('provider-load-more-retry'));
      await tester.ensureVisible(retry);
      await tester.pump();
      await tester.tap(retry);
      await tester.pump();
      await tester.pump();

      expect(
        repository.requests.where((request) => request.page == 2).length,
        2,
      );
      expect(container.read(provider).items, hasLength(page1.length + 1));
      expect(container.read(provider).loadMoreError, isEmpty);
      expect(
        find.byKey(const ValueKey('provider-load-more-retry')),
        findsNothing,
      );
    },
  );

  testWidgets('provider screen poster opens Detail without phone overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const ProviderView(providerId: 8, providerName: 'Netflix'),
        ),
        GoRoute(
          path: RoutePaths.detail,
          builder: (_, state) =>
              Scaffold(body: Text('Opened ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmdbRepositoryProvider.overrideWithValue(
            _ProviderCatalogTmdbRepository((_) => const [_wakanda]),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.tap(
      find.byKey(const ValueKey('provider-catalog-item-movie-505642')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Opened movie-505642'), findsOneWidget);
  });

  testWidgets('home provider tester skips provider subscription', (
    tester,
  ) async {
    var providerBuilds = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWithValue(
            AuthViewState(user: _user(email: ' Tester@VexelLab.com ')),
          ),
          watchProvidersProvider.overrideWith((ref) async {
            providerBuilds += 1;
            return const [];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: WatchProviderSection())),
      ),
    );
    await tester.pump();

    expect(providerBuilds, 0);
    expect(find.byKey(const ValueKey('watch-provider-list')), findsNothing);
    expect(
      find.byKey(const ValueKey('watch-provider-loading-list')),
      findsNothing,
    );
  });

  testWidgets('home provider normal user loads compact cells', (tester) async {
    var providerBuilds = 0;
    const providers = [
      TmdbWatchProvider(
        id: 1,
        name: 'Netflix',
        logoPath: '/netflix.png',
        displayPriority: 1,
      ),
      TmdbWatchProvider(
        id: 2,
        name: 'Prime Video',
        logoPath: '',
        displayPriority: 2,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWithValue(
            AuthViewState(user: _user(email: 'viewer@example.com')),
          ),
          watchProvidersProvider.overrideWith((ref) async {
            providerBuilds += 1;
            return providers;
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: WatchProviderSection())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(providerBuilds, 1);
    expect(find.byKey(const ValueKey('watch-provider-list')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('watch-provider-1'))).width,
      64,
    );

    final box = tester.widget<Container>(
      find.byKey(const ValueKey('watch-provider-image-1')),
    );
    expect(box.constraints?.maxWidth, 58);
    expect(box.constraints?.maxHeight, 58);
    expect(box.padding, isNull);
    expect(box.clipBehavior, Clip.antiAlias);
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, isNull);
    expect(decoration.borderRadius, BorderRadius.circular(12));
    final border = decoration.border! as Border;
    expect(border.top.color, VeilColors.hairlineStrong);
    expect(border.top.width, 1);

    final image = tester.widget<CachedNetworkImage>(
      find.descendant(
        of: find.byKey(const ValueKey('watch-provider-image-1')),
        matching: find.byType(CachedNetworkImage),
      ),
    );
    expect(image.fit, BoxFit.cover);

    final fallback = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byKey(const ValueKey('watch-provider-image-2')),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(fallback.color, VeilColors.bg3);
    final fallbackText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('watch-provider-image-2')),
        matching: find.text('P'),
      ),
    );
    expect(fallbackText.style?.color, Colors.white);
  });

  testWidgets('home provider rail caps items and opens typed provider route', (
    tester,
  ) async {
    final providers = [
      for (var id = 1; id <= 13; id++)
        TmdbWatchProvider(
          id: id,
          name: id == 1 ? 'Netflix' : 'Provider $id',
          logoPath: '',
          displayPriority: id,
        ),
    ];
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeView()),
        GoRoute(
          path: RoutePaths.provider,
          builder: (_, state) => Scaffold(
            body: Text(
              'Provider ${state.pathParameters['id']} '
              '${state.uri.queryParameters['name']}',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emptyAlertsOverride,
          homeViewModelProvider.overrideWithValue(_homeState),
          watchProvidersProvider.overrideWith((ref) async => providers),
          curatedCollectionsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('watch-provider-1')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Watch by provider'), findsNothing);
    expect(find.byKey(const ValueKey('watch-provider-retry')), findsNothing);
    expect(find.byKey(const ValueKey('watch-provider-1')), findsOneWidget);
    final list = tester.widget<ListView>(
      find.byKey(const ValueKey('watch-provider-list')),
    );
    final delegate = list.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegate.childCount, 12 * 2 - 1);

    await tester.tap(find.byKey(const ValueKey('watch-provider-1')));
    await tester.pumpAndSettle();

    expect(find.text('Provider 1 Netflix'), findsOneWidget);
  });

  testWidgets('home provider loading shows skeleton rail without heading', (
    tester,
  ) async {
    final providers = Completer<List<TmdbWatchProvider>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchProvidersProvider.overrideWith((ref) => providers.future),
        ],
        child: const MaterialApp(home: Scaffold(body: WatchProviderSection())),
      ),
    );
    await tester.pump();

    expect(find.text('Watch by provider'), findsNothing);
    expect(find.byKey(const ValueKey('watch-provider-retry')), findsNothing);
    expect(find.byKey(const ValueKey('watch-provider-list')), findsNothing);
    expect(
      find.byKey(const ValueKey('watch-provider-loading-list')),
      findsOneWidget,
    );
    expect(find.byType(SkeletonBox), findsNWidgets(5));
    for (var index = 0; index < 5; index++) {
      final skeleton = tester.widget<SkeletonBox>(
        find.byKey(ValueKey('watch-provider-loading-$index')),
      );
      expect(skeleton.width, 58);
      expect(skeleton.height, 58);
      expect(skeleton.radius, 12);
    }

    providers.complete(const []);
    await tester.pump();
  });

  testWidgets('home provider error renders nothing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchProvidersProvider.overrideWith(
            (ref) async => throw StateError('Provider list unavailable'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: WatchProviderSection())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Watch by provider'), findsNothing);
    expect(find.byKey(const ValueKey('watch-provider-retry')), findsNothing);
    expect(find.byKey(const ValueKey('watch-provider-list')), findsNothing);
    expect(
      find.byKey(const ValueKey('watch-provider-loading-list')),
      findsNothing,
    );
    expect(find.byType(SkeletonBox), findsNothing);
  });

  testWidgets('home provider failure remains isolated from primary rails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emptyAlertsOverride,
          homeViewModelProvider.overrideWithValue(_homeState),
          watchProvidersProvider.overrideWith(
            (ref) async => throw StateError('Provider list unavailable'),
          ),
          curatedCollectionsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Global trending'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Watch by provider'), findsNothing);
    expect(find.byKey(const ValueKey('watch-provider-retry')), findsNothing);
    expect(find.byKey(const ValueKey('watch-provider-list')), findsNothing);
    expect(
      find.byKey(const ValueKey('watch-provider-loading-list')),
      findsNothing,
    );
    expect(find.text('Global trending'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('curated metadata loading has no overall heading', (
    tester,
  ) async {
    final collections = Completer<List<CuratedCollection>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curatedCollectionsProvider.overrideWith((ref) => collections.future),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CuratedCollectionSection()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Curated collections'), findsNothing);
    expect(
      find.byKey(const ValueKey('curated-collection-choices')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('curated-collection-retry')),
      findsNothing,
    );
    expect(find.byType(SkeletonBox), findsNWidgets(3));

    collections.complete(const []);
    await tester.pump();
  });

  testWidgets('curated metadata error stays compact without overall heading', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curatedCollectionsProvider.overrideWith(
            (ref) async => throw StateError('Collections unavailable'),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CuratedCollectionSection()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Curated collections'), findsNothing);
    expect(find.text('Curated collections are unavailable.'), findsNothing);
    expect(find.text('Unable to load this collection.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('curated-collection-retry')),
      findsOneWidget,
    );
    expect(find.byType(SkeletonBox), findsNothing);
  });

  testWidgets('curated selector loads only selected family and swaps rail', (
    tester,
  ) async {
    var firstLoads = 0;
    var secondLoads = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curatedCollectionsProvider.overrideWith(
            (ref) async => _curatedCollections,
          ),
          curatedCollectionItemsProvider('first').overrideWith((ref) async {
            firstLoads += 1;
            return const [_wakanda];
          }),
          curatedCollectionItemsProvider('second').overrideWith((ref) async {
            secondLoads += 1;
            return const [_arcane];
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: CuratedCollectionSection()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(firstLoads, 1);
    expect(secondLoads, 0);
    expect(find.text('Curated collections'), findsNothing);
    expect(find.text('First collection'), findsOneWidget);
    expect(find.text('Second collection'), findsOneWidget);
    expect(find.text('First collection description.'), findsNothing);
    expect(find.text('Second collection description.'), findsNothing);
    expect(find.text(_wakanda.title), findsOneWidget);
    expect(find.text(_arcane.title), findsNothing);
    expect(
      find.byKey(const ValueKey('curated-collection-heading-first')),
      findsNothing,
    );
    expect(
      tester
          .getRect(find.byKey(const ValueKey('curated-collection-choices')))
          .bottom,
      lessThan(
        tester
            .getRect(find.byKey(const ValueKey('curated-collection-items')))
            .top,
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('curated-collection-choice-second')),
    );
    await tester.pump();
    await tester.pump();

    expect(firstLoads, 1);
    expect(secondLoads, 1);
    expect(find.text(_wakanda.title), findsNothing);
    expect(find.text(_arcane.title), findsOneWidget);
    expect(
      find.byKey(const ValueKey('curated-collection-heading-first')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('curated-collection-heading-second')),
      findsNothing,
    );
    expect(find.text('First collection description.'), findsNothing);
    expect(find.text('Second collection description.'), findsNothing);
  });

  testWidgets('curated selection retains old posters until new data arrives', (
    tester,
  ) async {
    final secondItems = Completer<List<ContentItem>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curatedCollectionsProvider.overrideWith(
            (ref) async => _curatedCollections,
          ),
          curatedCollectionItemsProvider(
            'first',
          ).overrideWith((ref) async => const [_wakanda]),
          curatedCollectionItemsProvider(
            'second',
          ).overrideWith((ref) => secondItems.future),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CuratedCollectionSection()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('curated-collection-choice-second')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('curated-collection-heading-first')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('curated-collection-heading-second')),
      findsNothing,
    );
    expect(find.text('First collection'), findsOneWidget);
    expect(find.text('Second collection'), findsOneWidget);
    expect(find.text('First collection description.'), findsNothing);
    expect(find.text('Second collection description.'), findsNothing);
    expect(
      find.byKey(const ValueKey('curated-collection-item-movie-505642')),
      findsOneWidget,
    );
    expect(find.text(_wakanda.title), findsOneWidget);
    expect(find.text(_arcane.title), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    secondItems.complete(const [_arcane]);
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('curated-collection-heading-first')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('curated-collection-heading-second')),
      findsNothing,
    );
    expect(find.text('First collection description.'), findsNothing);
    expect(find.text('Second collection description.'), findsNothing);
    expect(find.text(_wakanda.title), findsNothing);
    expect(find.text(_arcane.title), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('curated selection error retains old rail and retries request', (
    tester,
  ) async {
    var secondLoads = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curatedCollectionsProvider.overrideWith(
            (ref) async => _curatedCollections,
          ),
          curatedCollectionItemsProvider(
            'first',
          ).overrideWith((ref) async => const [_wakanda]),
          curatedCollectionItemsProvider('second').overrideWith((ref) async {
            secondLoads += 1;
            if (secondLoads == 1) throw StateError('Collection unavailable');
            return const [_arcane];
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CuratedCollectionSection()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('curated-collection-choice-second')),
    );
    await tester.pump();
    await tester.pump();

    expect(secondLoads, 1);
    expect(
      find.byKey(const ValueKey('curated-collection-heading-first')),
      findsNothing,
    );
    expect(find.text('First collection description.'), findsNothing);
    expect(find.text('Second collection description.'), findsNothing);
    expect(find.text(_wakanda.title), findsOneWidget);
    expect(find.text(_arcane.title), findsNothing);
    expect(
      find.byKey(const ValueKey('curated-collection-retry')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('curated-collection-retry')));
    await tester.pump();
    expect(find.text(_wakanda.title), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pump();

    expect(secondLoads, 2);
    expect(
      find.byKey(const ValueKey('curated-collection-heading-second')),
      findsNothing,
    );
    expect(find.text(_wakanda.title), findsNothing);
    expect(find.text(_arcane.title), findsOneWidget);
  });

  testWidgets('curated item failure retries locally and recovers', (
    tester,
  ) async {
    var loads = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curatedCollectionsProvider.overrideWith(
            (ref) async => _curatedCollections.take(1).toList(),
          ),
          curatedCollectionItemsProvider('first').overrideWith((ref) async {
            loads += 1;
            if (loads == 1) throw StateError('Collection unavailable');
            return const [_wakanda];
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CuratedCollectionSection()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(loads, 1);
    expect(
      find.byKey(const ValueKey('curated-collection-retry')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('curated-collection-retry')));
    await tester.pump();
    await tester.pump();

    expect(loads, 2);
    expect(find.text(_wakanda.title), findsOneWidget);
    expect(
      find.byKey(const ValueKey('curated-collection-retry')),
      findsNothing,
    );
  });

  testWidgets('curated refresh retains prior data with compact progress', (
    tester,
  ) async {
    var loads = 0;
    final refresh = Completer<List<ContentItem>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curatedCollectionsProvider.overrideWith(
            (ref) async => _curatedCollections.take(1).toList(),
          ),
          curatedCollectionItemsProvider('first').overrideWith((ref) async {
            loads += 1;
            if (loads == 1) return const [_wakanda];
            return refresh.future;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CuratedCollectionSection()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CuratedCollectionSection)),
    );
    container.invalidate(curatedCollectionItemsProvider('first'));
    await tester.pump();

    expect(find.text(_wakanda.title), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    refresh.complete(const [_arcane]);
    await tester.pump();
    await tester.pump();

    expect(find.text(_wakanda.title), findsNothing);
    expect(find.text(_arcane.title), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('curated empty state remains local', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curatedCollectionsProvider.overrideWith(
            (ref) async => _curatedCollections.take(1).toList(),
          ),
          curatedCollectionItemsProvider(
            'first',
          ).overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CuratedCollectionSection()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('No curated titles available.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('curated Detail tap opens selected TMDB identity', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: CuratedCollectionSection()),
        ),
        GoRoute(
          path: RoutePaths.detail,
          builder: (_, state) =>
              Scaffold(body: Text('Opened ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curatedCollectionsProvider.overrideWith(
            (ref) async => _curatedCollections.take(1).toList(),
          ),
          curatedCollectionItemsProvider(
            'first',
          ).overrideWith((ref) async => const [_wakanda]),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('curated-collection-item-movie-505642')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Opened movie-505642'), findsOneWidget);
  });

  testWidgets('curated failure leaves existing Home rails available', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emptyAlertsOverride,
          watchProvidersProvider.overrideWith((ref) async => const []),
          homeViewModelProvider.overrideWithValue(_homeState),
          curatedCollectionsProvider.overrideWith(
            (ref) async => _curatedCollections.take(1).toList(),
          ),
          curatedCollectionItemsProvider(
            'first',
          ).overrideWith((ref) async => throw StateError('Shegu unavailable')),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('curated-collection-retry')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.byKey(const ValueKey('curated-collection-retry')),
      findsOneWidget,
    );
    expect(find.text('Global trending'), findsOneWidget);
    expect(find.text(_wakanda.title), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home keeps curated compact between new and popular', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emptyAlertsOverride,
          watchProvidersProvider.overrideWith((ref) async => const []),
          homeViewModelProvider.overrideWithValue(_homeState),
          curatedCollectionsProvider.overrideWith(
            (ref) async => _curatedCollections,
          ),
          curatedCollectionItemsProvider(
            'first',
          ).overrideWith((ref) async => const [_wakanda, _arcane]),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Popular movies'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    final newThisWeekY = tester.getCenter(find.text('New this week')).dy;
    final curatedTabsY = tester
        .getCenter(find.byKey(const ValueKey('curated-collection-choices')))
        .dy;
    final popularMoviesY = tester.getCenter(find.text('Popular movies')).dy;
    expect(newThisWeekY, lessThan(curatedTabsY));
    expect(curatedTabsY, lessThan(popularMoviesY));
    expect(find.text('Curated collections'), findsNothing);
    expect(find.text('First collection description.'), findsNothing);
    expect(find.text('Second collection description.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home hero is full bleed and complete on phone and desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emptyAlertsOverride,
          ...emptyHomeDiscoveryOverrides,
          playbackHistoryViewModelProvider.overrideWithValue(const []),
          homeViewModelProvider.overrideWithValue(
            const HomeViewState(
              globalTrending: [_arcane],
              genres: [TmdbGenre(id: 18, name: 'Drama')],
            ),
          ),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pump();

    void expectCinematicGeometry({
      required double width,
      required double height,
    }) {
      final hero = find.byKey(const ValueKey('home-cinematic-hero'));
      final overlap = find.byKey(const ValueKey('home-hero-category-overlap'));
      final categories = find.byKey(const ValueKey('home-category-tabs'));
      final heroRect = tester.getRect(hero);
      expect(heroRect.left, 0);
      expect(heroRect.top, 0);
      expect(heroRect.width, width);
      expect(heroRect.height, closeTo(height, .01));
      expect(categories, findsOneWidget);
      expect(
        tester.getTopLeft(categories).dy,
        closeTo(heroRect.bottom - 32, .01),
      );
      expect(tester.getSize(categories).height, 52);
      expect(tester.getSize(overlap).height, closeTo(height + 52 - 32, .01));
      final backdrop = tester.widget<BackdropArt>(
        find.descendant(of: hero, matching: find.byType(BackdropArt)).first,
      );
      expect(backdrop.radius, 0);
      expect(backdrop.width, double.infinity);
      expect(backdrop.height, closeTo(height, .01));
    }

    expectCinematicGeometry(width: 390, height: 844 * .51);
    expect(find.text('Tonight on Veil'), findsNothing);
    expect(find.textContaining('Hello,'), findsNothing);
    expect(find.byKey(const ValueKey('home-hero-logo')), findsNothing);
    expect(find.byKey(const ValueKey('home-hero-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-hero-alerts')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-hero-view')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-hero-add')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('home-hero-view'))).height,
      44,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('home-hero-add'))),
      const Size.square(44),
    );
    expect(find.byTooltip('Add to Veil'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-hero-info')), findsNothing);
    expect(
      find.byKey(const ValueKey('home-hero-horizontal-vignette')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-hero-bottom-blend')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-hero-top-contrast')),
      findsOneWidget,
    );
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Play'), findsNothing);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byKey(const ValueKey('home-hero-dots')), findsNothing);
    expect(find.byKey(const ValueKey('home-hero-dot-0')), findsNothing);
    expect(find.text('ARCANE'), findsOneWidget);
    final overview = tester.widget<Text>(find.text(_arcane.description));
    expect(overview.maxLines, 3);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pump();

    expectCinematicGeometry(width: 1200, height: 465);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home hero skeleton is full bleed with zero radius', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emptyAlertsOverride,
          ...emptyHomeDiscoveryOverrides,
          playbackHistoryViewModelProvider.overrideWithValue(const []),
          homeViewModelProvider.overrideWithValue(const HomeViewState()),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pump();

    final skeletonFinder = find.byKey(const ValueKey('home-hero-skeleton'));
    final skeleton = tester.widget<SkeletonBox>(skeletonFinder);
    expect(tester.getTopLeft(skeletonFinder), Offset.zero);
    expect(tester.getSize(skeletonFinder).width, 390);
    expect(tester.getSize(skeletonFinder).height, closeTo(844 * .51, .01));
    expect(skeleton.radius, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'home hero quick add and actions preserve routes without playback',
    (tester) async {
      var playbackLaunches = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => HomeView(
              playbackLauncher: (_, _) async {
                playbackLaunches += 1;
                return true;
              },
            ),
          ),
          GoRoute(
            path: RoutePaths.detail,
            builder: (_, state) =>
                Scaffold(body: Text('Detail ${state.pathParameters['id']}')),
          ),
          GoRoute(
            path: RoutePaths.search,
            builder: (_, _) => const Scaffold(body: Text('Search destination')),
          ),
          GoRoute(
            path: RoutePaths.alerts,
            builder: (_, _) => const Scaffold(body: Text('Alerts destination')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertsViewModelProvider.overrideWithValue(
              const AlertsViewState(
                alerts: [
                  AlertItem(
                    content: _arcane,
                    tag: 'TRENDING',
                    title: 'Arcane is trending',
                    time: 'Now',
                    unread: true,
                  ),
                ],
              ),
            ),
            ...emptyHomeDiscoveryOverrides,
            playbackHistoryViewModelProvider.overrideWithValue(const []),
            homeViewModelProvider.overrideWithValue(
              const HomeViewState(globalTrending: [_arcane]),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      final alertsControl = tester.widget<ActionCircle>(
        find.byKey(const ValueKey('home-hero-alerts')),
      );
      expect(alertsControl.badge, isTrue);

      await tester.tap(find.byKey(const ValueKey('home-hero-view')));
      await tester.pumpAndSettle();
      expect(find.text('Detail tv-94605'), findsOneWidget);
      router.go('/');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('home-hero-add')));
      await tester.pump();
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(playbackLaunches, 0);
      expect(
        find.byKey(const ValueKey('detail-social-action-panel')),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('home-hero-search')));
      await tester.pumpAndSettle();
      expect(find.text('Search destination'), findsOneWidget);
      router.go('/');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('home-hero-alerts')));
      await tester.pumpAndSettle();
      expect(find.text('Alerts destination'), findsOneWidget);
    },
  );

  testWidgets('home hero quick add seeds unified social action panel', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    final repository = SocialRepository();
    await repository.setWatched(_wakanda, watched: true, rating: 4);
    await repository.toggleFavorite(_wakanda);

    await _pumpHomeHeroQuickAdd(tester, repository);
    await tester.tap(find.byKey(const ValueKey('home-hero-add')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('detail-social-action-panel')),
      findsOneWidget,
    );
    for (final label in const [
      'Watched',
      'Favorite',
      'Watchlist',
      'Rate',
      'Review',
      'Suggest',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    final sheet = tester.widget<DetailSocialActionSheet>(
      find.byType(DetailSocialActionSheet),
    );
    expect(sheet.item.id, _wakanda.id);
    expect(sheet.isWatched, isTrue);
    expect(sheet.isFavorite, isTrue);
    expect(sheet.isInWatchlist, isFalse);
    expect(sheet.rating, 4);
    expect(find.byType(DetailView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home hero quick add wires social library mutations', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    final repository = SocialRepository();

    await _pumpHomeHeroQuickAdd(tester, repository);
    await tester.tap(find.byKey(const ValueKey('home-hero-add')));
    await tester.pump();
    final sheet = tester.widget<DetailSocialActionSheet>(
      find.byType(DetailSocialActionSheet),
    );

    await sheet.onSetWatched(watched: true, rating: 3.5);
    var entry = (await repository.entries()).single;
    expect(entry.watchedOn, isNotNull);
    expect(entry.rating, 3.5);

    await sheet.onToggleFavorite();
    entry = (await repository.entries()).single;
    expect(entry.isFavorite, isTrue);

    await sheet.onSetWatchlist(inWatchlist: true);
    entry = (await repository.entries()).single;
    expect(entry.inWatchlist, isTrue);
    expect(entry.watchedOn, isNull);
    expect(entry.rating, 0);

    await sheet.onRate(rating: 4.5);
    entry = (await repository.entries()).single;
    expect(entry.inWatchlist, isFalse);
    expect(entry.watchedOn, isNotNull);
    expect(entry.rating, 4.5);
    expect(entry.isFavorite, isTrue);
  });

  testWidgets('home hero quick add opens review and suggestion flows', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    final repository = SocialRepository();
    await repository.rate(_wakanda, rating: 4);

    await _pumpHomeHeroQuickAdd(tester, repository);
    await tester.tap(find.byKey(const ValueKey('home-hero-add')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('detail-social-action-panel')),
      findsNothing,
    );
    final reviewSheet = tester.widget<DetailReviewSheet>(
      find.byType(DetailReviewSheet),
    );
    expect(reviewSheet.item.id, _wakanda.id);
    expect(reviewSheet.initialRating, 4);

    await tester.enterText(
      find.widgetWithText(TextField, 'Tags, comma separated'),
      'festival, drama',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Add review...'),
      'Still powerful.',
    );
    await tester.tap(find.text('Rewatch'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('detail-review-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final saved = (await repository.entries()).single;
    expect(saved.review, 'Still powerful.');
    expect(saved.rating, 4);
    expect(saved.tags, containsAll(['rewatch', 'festival', 'drama']));
    expect(saved.watchedOn, isNotNull);
    expect(saved.inWatchlist, isFalse);

    await tester.tap(find.byKey(const ValueKey('home-hero-add')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Suggest'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final suggestionSheet = tester.widget<DetailSuggestionSheet>(
      find.byType(DetailSuggestionSheet),
    );
    expect(suggestionSheet.item.id, _wakanda.id);
    expect(find.text('No friends yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home hero rotates and wraps across top five without dots', (
    tester,
  ) async {
    final heroItems = [
      for (var index = 1; index <= 6; index++) _heroItem(index),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emptyAlertsOverride,
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(
            HomeViewState(globalTrending: heroItems),
          ),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pump();

    expect(find.text('HERO 1'), findsOneWidget);
    final switcher = tester.widget<AnimatedSwitcher>(
      find.byKey(const ValueKey('home-hero-switcher')),
    );
    expect(switcher.duration, const Duration(milliseconds: 500));
    for (var index = 0; index < 5; index++) {
      expect(find.byKey(ValueKey('home-hero-dot-$index')), findsNothing);
    }
    expect(find.byKey(const ValueKey('home-hero-dot-5')), findsNothing);

    for (final title in const [
      'HERO 2',
      'HERO 3',
      'HERO 4',
      'HERO 5',
      'HERO 1',
    ]) {
      await tester.pump(const Duration(seconds: 7));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(title), findsOneWidget);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('home hero fade respects reduced motion', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emptyAlertsOverride,
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(
            HomeViewState(globalTrending: [_heroItem(1), _heroItem(2)]),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: HomeView(),
          ),
        ),
      ),
    );
    await tester.pump();

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byKey(const ValueKey('home-hero-switcher')),
    );
    expect(switcher.duration, Duration.zero);

    await tester.pump(const Duration(seconds: 7));
    await tester.pump();
    expect(find.text('HERO 2'), findsOneWidget);
  });

  testWidgets('home continue watching displays honest history and removes', (
    tester,
  ) async {
    final repository = await _seedPlaybackHistory();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emptyAlertsOverride,
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
          authViewModelProvider.overrideWithValue(AuthViewState(user: _user())),
          playbackHistoryRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pump();

    final edit = find.byKey(const ValueKey('continue-watching-edit'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
    await tester.pump();

    expect(find.text('Continue Watching'), findsOneWidget);
    expect(find.text('Recently started'), findsOneWidget);
    expect(find.text('S2 · E3'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('left'), findsNothing);

    await tester.tap(edit);
    await tester.pump();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(
      find.byKey(ValueKey('continue-watching-remove-${_historyMovieKey()}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('continue-watching-remove-${_historyTvKey()}')),
      findsOneWidget,
    );

    await tester.tap(edit);
    await tester.pump();
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);

    await tester.tap(edit);
    await tester.pump();
    final removeMovie = find.byKey(
      ValueKey('continue-watching-remove-${_historyMovieKey()}'),
    );
    await tester.tap(removeMovie);
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeView)),
    );
    expect(container.read(playbackHistoryViewModelProvider), hasLength(1));
    expect(find.text('History Movie'), findsNothing);
    expect(find.text('History TV'), findsOneWidget);
  });

  testWidgets(
    'home continue watching relaunches exact request and reorders on success',
    (tester) async {
      final repository = await _seedPlaybackHistory();
      PlaybackRequest? launched;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emptyAlertsOverride,
            ...emptyHomeDiscoveryOverrides,
            homeViewModelProvider.overrideWithValue(_homeState),
            authViewModelProvider.overrideWithValue(
              AuthViewState(user: _user()),
            ),
            playbackHistoryRepositoryProvider.overrideWithValue(repository),
            currentUserIsPremiumProvider.overrideWith((ref) async => true),
          ],
          child: MaterialApp(
            home: HomeView(
              playbackLauncher: (_, request) async {
                launched = request;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final historyCard = find.byKey(
        ValueKey('continue-watching-card-${_historyTvKey()}'),
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
      await tester.pump();

      await tester.tap(historyCard);
      await tester.pump();

      expect(launched?.item.remoteId, _historyTv.remoteId);
      expect(launched?.item.mediaType, 'tv');
      expect(launched?.server, PlaybackServer.two);
      expect(launched?.season, 2);
      expect(launched?.episode, 3);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeView)),
      );
      expect(
        container.read(playbackHistoryViewModelProvider).first.tmdbId,
        _historyTv.remoteId,
      );
    },
  );

  testWidgets('home continue watching blocks non-premium relaunch', (
    tester,
  ) async {
    final repository = await _seedPlaybackHistory();
    var launchCalls = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emptyAlertsOverride,
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
          authViewModelProvider.overrideWithValue(AuthViewState(user: _user())),
          playbackHistoryRepositoryProvider.overrideWithValue(repository),
          currentUserIsPremiumProvider.overrideWith((ref) async => false),
        ],
        child: MaterialApp(
          home: HomeView(
            playbackLauncher: (_, _) async {
              launchCalls += 1;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final historyCard = find.byKey(
      ValueKey('continue-watching-card-${_historyMovieKey()}'),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
    await tester.pump();

    await tester.tap(historyCard);
    await tester.pump();

    expect(launchCalls, 0);
    expect(
      find.text('Premium access is required to continue watching.'),
      findsOneWidget,
    );
  });

  testWidgets('home continue watching toasts when relaunch fails', (
    tester,
  ) async {
    final repository = await _seedPlaybackHistory();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emptyAlertsOverride,
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
          authViewModelProvider.overrideWithValue(AuthViewState(user: _user())),
          playbackHistoryRepositoryProvider.overrideWithValue(repository),
          currentUserIsPremiumProvider.overrideWith((ref) async => true),
        ],
        child: const MaterialApp(
          home: HomeView(playbackLauncher: _rejectPlayback),
        ),
      ),
    );
    await tester.pump();

    final historyCard = find.byKey(
      ValueKey('continue-watching-card-${_historyMovieKey()}'),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
    await tester.pump();

    await tester.tap(historyCard);
    await tester.pump();

    expect(find.text('Player is not available right now.'), findsOneWidget);
  });

  testWidgets('home continue watching is absent for empty history', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emptyAlertsOverride,
          ...emptyHomeDiscoveryOverrides,
          homeViewModelProvider.overrideWithValue(_homeState),
          authViewModelProvider.overrideWithValue(AuthViewState(user: _user())),
          playbackHistoryRepositoryProvider.overrideWithValue(
            PlaybackHistoryRepository(),
          ),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pump();

    expect(find.text('Continue Watching'), findsNothing);
    expect(find.byKey(const ValueKey('continue-watching-edit')), findsNothing);
  });

  testWidgets(
    'home continue watching renders on mobile and desktop without overflow',
    (tester) async {
      final repository = await _seedPlaybackHistory();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            emptyAlertsOverride,
            ...emptyHomeDiscoveryOverrides,
            homeViewModelProvider.overrideWithValue(_homeState),
            authViewModelProvider.overrideWithValue(
              AuthViewState(user: _user()),
            ),
            playbackHistoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: HomeView()),
        ),
      );
      await tester.pump();
      expect(find.text('Continue Watching'), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(1200, 900);
      await tester.pump();
      expect(find.text('Continue Watching'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('home renders primary feed on desktop without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...emptyHomeDiscoveryOverrides,
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
    expect(find.text('Tonight on Veil'), findsNothing);
    expect(find.byKey(const ValueKey('home-cinematic-hero')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Global trending'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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

const _curatedCollections = [
  CuratedCollection(
    id: 'first',
    title: 'First collection',
    description: 'First collection description.',
    tags: ['movies'],
  ),
  CuratedCollection(
    id: 'second',
    title: 'Second collection',
    description: 'Second collection description.',
    tags: ['tv'],
  ),
];

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

const _historyMovie = ContentItem(
  id: 'movie-1284041',
  remoteId: 1284041,
  mediaType: 'movie',
  title: 'History Movie',
  subtitle: 'Movie',
  year: 2026,
  genre: 'Drama',
  type: 'Movie',
  rating: 7.4,
  palette: [Colors.black, Colors.red],
  glyph: Icons.movie_rounded,
  description: 'A movie playback history fixture.',
);

const _historyTv = ContentItem(
  id: 'tv-94997',
  remoteId: 94997,
  mediaType: 'tv',
  title: 'History TV',
  subtitle: 'Series',
  year: 2026,
  genre: 'Mystery',
  type: 'TV Show',
  rating: 8.1,
  palette: [Colors.black, Colors.blue],
  glyph: Icons.live_tv_rounded,
  description: 'A TV playback history fixture.',
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

ContentItem _heroItem(int index) {
  return ContentItem(
    id: 'hero-$index',
    remoteId: 1000 + index,
    mediaType: 'movie',
    title: 'Hero $index',
    subtitle: 'Movie',
    year: 2026,
    genre: 'Drama',
    type: 'Movie',
    rating: 7,
    palette: const [Colors.black, Colors.red],
    glyph: Icons.movie_rounded,
    description: 'Hero fixture $index.',
  );
}

Future<void> _pumpHomeHeroQuickAdd(
  WidgetTester tester,
  SocialRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        alertsViewModelProvider.overrideWithValue(const AlertsViewState()),
        watchProvidersProvider.overrideWith((ref) async => const []),
        curatedCollectionsProvider.overrideWith((ref) async => const []),
        playbackHistoryViewModelProvider.overrideWithValue(const []),
        homeViewModelProvider.overrideWithValue(
          const HomeViewState(globalTrending: [_wakanda]),
        ),
        socialRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: HomeView(playbackLauncher: _rejectPlayback),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<PlaybackHistoryRepository> _seedPlaybackHistory() async {
  final movieEntry = PlaybackHistoryEntry.fromRequest(
    const PlaybackRequest(item: _historyMovie, server: PlaybackServer.four),
    DateTime.utc(2026, 8, 8, 13),
  );
  final tvEntry = PlaybackHistoryEntry.fromRequest(
    const PlaybackRequest(
      item: _historyTv,
      server: PlaybackServer.two,
      season: 2,
      episode: 3,
    ),
    DateTime.utc(2026, 8, 8, 12),
  );
  SharedPreferences.setMockInitialValues({
    PlaybackHistoryRepository.storageKeyFor('user-1'): jsonEncode([
      movieEntry.toJson(),
      tvEntry.toJson(),
    ]),
  });
  await LocalStorage.init();
  return PlaybackHistoryRepository(now: () => DateTime.utc(2026, 8, 8, 14));
}

String _historyMovieKey() {
  return PlaybackHistoryEntry.fromRequest(
    const PlaybackRequest(item: _historyMovie, server: PlaybackServer.four),
    DateTime.utc(2026),
  ).entryKey;
}

String _historyTvKey() {
  return PlaybackHistoryEntry.fromRequest(
    const PlaybackRequest(
      item: _historyTv,
      server: PlaybackServer.two,
      season: 2,
      episode: 3,
    ),
    DateTime.utc(2026),
  ).entryKey;
}

Future<bool> _rejectPlayback(
  BuildContext context,
  PlaybackRequest request,
) async {
  return false;
}

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

typedef _ProviderCatalogRequest = ({
  int providerId,
  String mediaType,
  int page,
});

List<ContentItem> _providerCatalogItems(String prefix, int count) {
  return List.generate(
    count,
    (index) => ContentItem(
      id: '$prefix-$index',
      remoteId: 700000 + index,
      mediaType: 'movie',
      title: 'Provider title $index',
      subtitle: 'Movie',
      year: 2026,
      genre: 'Drama',
      type: 'Movie',
      rating: 7,
      palette: const [Colors.black, Colors.blueGrey],
      glyph: Icons.movie_rounded,
      description: 'Provider catalog fixture.',
    ),
  );
}

class _ProviderCatalogTmdbRepository extends TmdbRepository {
  _ProviderCatalogTmdbRepository(this.handler)
    : super(api: Api(), usesServerProxy: true);

  final FutureOr<List<ContentItem>> Function(_ProviderCatalogRequest request)
  handler;
  final List<_ProviderCatalogRequest> requests = [];

  @override
  Future<List<ContentItem>> discoverByProvider({
    required int providerId,
    required String mediaType,
    String region = 'US',
    int page = 1,
  }) async {
    final request = (providerId: providerId, mediaType: mediaType, page: page);
    requests.add(request);
    return handler(request);
  }
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

class _RecordingPlaybackHistoryRepository extends PlaybackHistoryRepository {
  final requests = <PlaybackRequest>[];

  @override
  List<PlaybackHistoryEntry> load(String userId) => const [];

  @override
  Future<List<PlaybackHistoryEntry>> record(
    String userId,
    PlaybackRequest request,
  ) async {
    requests.add(request);
    return const [];
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

class _PagedHomeTmdbRepository extends TmdbRepository {
  _PagedHomeTmdbRepository(this.pages) : super(api: Api());

  final Map<int, List<ContentItem>> pages;
  final List<int> requestedPages = [];

  @override
  Future<List<ContentItem>> trending() async => const [];

  @override
  Future<List<ContentItem>> upcomingMovies() async => const [];

  @override
  Future<List<ContentItem>> popularMovies() async => const [];

  @override
  Future<List<ContentItem>> topRatedMovies() async => const [];

  @override
  Future<List<ContentItem>> topRatedTv() async => const [];

  @override
  Future<List<ContentItem>> airingTodayTv() async => const [];

  @override
  Future<List<TmdbGenre>> genresDetailed() async {
    return const [TmdbGenre(id: 28, name: 'Action')];
  }

  @override
  Future<List<ContentItem>> sectionPage(
    String section, {
    int page = 1,
    int? genreId,
    double minRating = 0,
  }) async {
    requestedPages.add(page);
    return pages[page] ?? const [];
  }
}

class _PrivacyAdService implements AdService {
  var privacyCalls = 0;

  @override
  Future<AdState> initialize() async {
    return const AdState(canRequestAds: false, privacyOptionsRequired: true);
  }

  @override
  Future<LoadedAd?> loadAdaptiveBanner(double width) async => null;

  @override
  Future<LoadedAd?> loadNative() async => null;

  @override
  Future<AdState> showPrivacyOptions() async {
    privacyCalls += 1;
    return initialize();
  }
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
  final List<Uri> requestLoads = [];

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

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    requestLoads.add(params.uri);
  }
}

class _FakeNavigationDelegate extends PlatformNavigationDelegate {
  _FakeNavigationDelegate(super.params) : super.implementation();

  NavigationRequestCallback? onNavigationRequest;
  HttpResponseErrorCallback? onHttpError;

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {
    this.onNavigationRequest = onNavigationRequest;
  }

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
