import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:veil/src/core/router/route_paths.dart';
import 'package:veil/src/features/alerts/view/alerts_view.dart';
import 'package:veil/src/features/auth/view/reset_password_view.dart';
import 'package:veil/src/features/catalog/view/see_all_view.dart';
import 'package:veil/src/features/detail/view/detail_view.dart';
import 'package:veil/src/features/onboarding/view/onboarding_view.dart';
import 'package:veil/src/features/player/view/player_view.dart';
import 'package:veil/src/features/search/view/search_view.dart';
import 'package:veil/src/features/shell/view/veil_shell_view.dart';
import 'package:veil/src/features/user_profile/view/user_profile_view.dart';
import 'package:veil/src/shared/data/mock_catalog.dart';
import 'package:veil/src/shared/models/content_item.dart';

part 'app_router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter({required bool skipOnboarding, Uri? initialUri}) {
  final initialResetErrorMessage = initialUri == null
      ? null
      : passwordResetAuthErrorMessageFromUri(initialUri);
  final initialLocation = resolveInitialAppLocation(
    skipOnboarding: skipOnboarding,
    currentUri: initialUri,
  );
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    overridePlatformDefaultLocation:
        initialUri != null && isPasswordResetRecoveryUri(initialUri),
    routes: [
      GoRoute(
        path: RoutePaths.resetPassword,
        builder: (context, state) {
          return ResetPasswordView(
            initialErrorMessage:
                passwordResetAuthErrorMessageFromUri(state.uri) ??
                initialResetErrorMessage,
          );
        },
      ),
      ...$appRoutes,
    ],
  );
}

String resolveInitialAppLocation({
  required bool skipOnboarding,
  Uri? currentUri,
}) {
  final uri = currentUri ?? Uri.base;
  if (isPasswordResetRecoveryUri(uri)) return RoutePaths.resetPassword;

  return skipOnboarding ? RoutePaths.home : RoutePaths.onboarding;
}

bool isPasswordResetRecoveryUri(Uri uri) {
  if (uri.path == RoutePaths.resetPassword) return true;
  if (_queryLooksLikePasswordRecovery(uri.queryParameters)) return true;
  if (passwordResetAuthErrorMessageFromUri(uri) != null) return true;
  if (uri.fragment.isEmpty) return false;

  final fragmentUri = Uri.tryParse(uri.fragment);
  if (fragmentUri?.path == RoutePaths.resetPassword) return true;
  if (fragmentUri != null &&
      _queryLooksLikePasswordRecovery(fragmentUri.queryParameters)) {
    return true;
  }

  try {
    return _queryLooksLikePasswordRecovery(Uri.splitQueryString(uri.fragment));
  } on FormatException {
    return uri.fragment.contains(RoutePaths.resetPassword);
  }
}

bool _queryLooksLikePasswordRecovery(Map<String, String> query) {
  return query['type'] == 'recovery';
}

String? passwordResetAuthErrorMessageFromUri(Uri uri) {
  for (final query in _authCallbackQueries(uri)) {
    if (!_queryLooksLikeExpiredPasswordReset(query)) continue;

    return 'This reset link is invalid or has expired. Please request a new password reset link.';
  }

  return null;
}

List<Map<String, String>> _authCallbackQueries(Uri uri) {
  final queries = <Map<String, String>>[uri.queryParameters];
  final fragment = uri.fragment;
  if (fragment.isEmpty) return queries;

  final fragmentUri = Uri.tryParse(fragment);
  if (fragmentUri != null) {
    queries.add(fragmentUri.queryParameters);
  }

  try {
    queries.add(Uri.splitQueryString(fragment));
  } on FormatException {
    // Some auth providers put a path in the fragment; those are covered by
    // Uri.tryParse above.
  }

  return queries;
}

bool _queryLooksLikeExpiredPasswordReset(Map<String, String> query) {
  final error = query['error']?.toLowerCase();
  final errorCode = query['error_code']?.toLowerCase();
  final description = query['error_description']?.toLowerCase() ?? '';
  return error == 'access_denied' &&
      (errorCode == 'otp_expired' ||
          description.contains('invalid or has expired') ||
          description.contains('expired'));
}

@TypedGoRoute<OnboardingRoute>(path: RoutePaths.onboarding)
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  const OnboardingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const OnboardingView();
  }
}

@TypedGoRoute<VeilShellRoute>(path: RoutePaths.home)
class VeilShellRoute extends GoRouteData with $VeilShellRoute {
  const VeilShellRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const VeilShellView();
  }
}

@TypedGoRoute<DetailRoute>(path: RoutePaths.detail)
class DetailRoute extends GoRouteData with $DetailRoute {
  const DetailRoute({required this.id, this.$extra});

  final String id;
  final ContentItem? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return DetailView(item: $extra ?? VeilCatalog.byId(id));
  }
}

@TypedGoRoute<PlayerRoute>(path: RoutePaths.player)
class PlayerRoute extends GoRouteData with $PlayerRoute {
  const PlayerRoute({required this.id, this.$extra});

  final String id;
  final ContentItem? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return PlayerView(item: $extra ?? VeilCatalog.byId(id));
  }
}

@TypedGoRoute<SearchRoute>(path: RoutePaths.search)
class SearchRoute extends GoRouteData with $SearchRoute {
  const SearchRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SearchView(showBack: true);
  }
}

@TypedGoRoute<AlertsRoute>(path: RoutePaths.alerts)
class AlertsRoute extends GoRouteData with $AlertsRoute {
  const AlertsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AlertsView(showBack: true);
  }
}

@TypedGoRoute<SeeAllRoute>(path: RoutePaths.seeAll)
class SeeAllRoute extends GoRouteData with $SeeAllRoute {
  const SeeAllRoute({required this.section, this.genreId, this.title});

  final String section;
  final int? genreId;
  final String? title;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SeeAllView(section: section, genreId: genreId, title: title);
  }
}

@TypedGoRoute<UserProfileRoute>(path: RoutePaths.userProfile)
class UserProfileRoute extends GoRouteData with $UserProfileRoute {
  const UserProfileRoute({required this.id, this.displayName});

  final String id;
  final String? displayName;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return UserProfileView(userId: id, displayName: displayName);
  }
}
