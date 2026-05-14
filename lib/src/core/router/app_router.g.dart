// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $onboardingRoute,
  $veilShellRoute,
  $detailRoute,
  $playerRoute,
  $searchRoute,
  $alertsRoute,
  $seeAllRoute,
  $userProfileRoute,
];

RouteBase get $onboardingRoute => GoRouteData.$route(
  path: '/onboarding',
  factory: $OnboardingRoute._fromState,
);

mixin $OnboardingRoute on GoRouteData {
  static OnboardingRoute _fromState(GoRouterState state) =>
      const OnboardingRoute();

  @override
  String get location => GoRouteData.$location('/onboarding');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $veilShellRoute =>
    GoRouteData.$route(path: '/', factory: $VeilShellRoute._fromState);

mixin $VeilShellRoute on GoRouteData {
  static VeilShellRoute _fromState(GoRouterState state) =>
      const VeilShellRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $detailRoute =>
    GoRouteData.$route(path: '/detail/:id', factory: $DetailRoute._fromState);

mixin $DetailRoute on GoRouteData {
  static DetailRoute _fromState(GoRouterState state) => DetailRoute(
    id: state.pathParameters['id']!,
    $extra: state.extra as ContentItem?,
  );

  DetailRoute get _self => this as DetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/detail/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $playerRoute =>
    GoRouteData.$route(path: '/player/:id', factory: $PlayerRoute._fromState);

mixin $PlayerRoute on GoRouteData {
  static PlayerRoute _fromState(GoRouterState state) => PlayerRoute(
    id: state.pathParameters['id']!,
    $extra: state.extra as ContentItem?,
  );

  PlayerRoute get _self => this as PlayerRoute;

  @override
  String get location =>
      GoRouteData.$location('/player/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $searchRoute =>
    GoRouteData.$route(path: '/search', factory: $SearchRoute._fromState);

mixin $SearchRoute on GoRouteData {
  static SearchRoute _fromState(GoRouterState state) => const SearchRoute();

  @override
  String get location => GoRouteData.$location('/search');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $alertsRoute =>
    GoRouteData.$route(path: '/alerts', factory: $AlertsRoute._fromState);

mixin $AlertsRoute on GoRouteData {
  static AlertsRoute _fromState(GoRouterState state) => const AlertsRoute();

  @override
  String get location => GoRouteData.$location('/alerts');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $seeAllRoute => GoRouteData.$route(
  path: '/see-all/:section',
  factory: $SeeAllRoute._fromState,
);

mixin $SeeAllRoute on GoRouteData {
  static SeeAllRoute _fromState(GoRouterState state) => SeeAllRoute(
    section: state.pathParameters['section']!,
    genreId: _$convertMapValue(
      'genre-id',
      state.uri.queryParameters,
      int.tryParse,
    ),
    title: state.uri.queryParameters['title'],
  );

  SeeAllRoute get _self => this as SeeAllRoute;

  @override
  String get location => GoRouteData.$location(
    '/see-all/${Uri.encodeComponent(_self.section)}',
    queryParams: {
      if (_self.genreId != null) 'genre-id': _self.genreId!.toString(),
      if (_self.title != null) 'title': _self.title,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

RouteBase get $userProfileRoute => GoRouteData.$route(
  path: '/users/:id',
  factory: $UserProfileRoute._fromState,
);

mixin $UserProfileRoute on GoRouteData {
  static UserProfileRoute _fromState(GoRouterState state) => UserProfileRoute(
    id: state.pathParameters['id']!,
    displayName: state.uri.queryParameters['display-name'],
  );

  UserProfileRoute get _self => this as UserProfileRoute;

  @override
  String get location => GoRouteData.$location(
    '/users/${Uri.encodeComponent(_self.id)}',
    queryParams: {
      if (_self.displayName != null) 'display-name': _self.displayName,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
