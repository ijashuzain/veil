class AppEnvironment {
  const AppEnvironment._();

  static const _tmdbReadAccessTokenFromEnv = String.fromEnvironment(
    'TMDB_READ_ACCESS_TOKEN',
  );

  static const _plainTmdbApiKey = 'f71c94e31ad09d907b58754459926ecf';

  static const _tmdbApiKeyFromEnv = String.fromEnvironment('TMDB_API_KEY');

  static String get tmdbReadAccessToken => _tmdbReadAccessTokenFromEnv;

  static String get tmdbApiKey =>
      _tmdbApiKeyFromEnv.isNotEmpty ? _tmdbApiKeyFromEnv : _plainTmdbApiKey;

  static bool get hasTmdbCredentials =>
      tmdbReadAccessToken.isNotEmpty || tmdbApiKey.isNotEmpty;

  static const _plainSupabaseUrl = 'https://verlsbmdqggejpfmvzue.supabase.co';

  static const _plainSupabaseAnonKey =
      'sb_publishable_LCGRuF5KiQOg3bp1p0sffQ_S0bTrO99';

  static const _supabaseUrlFromEnv = String.fromEnvironment('SUPABASE_URL');

  static const _supabaseAnonKeyFromEnv = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static const _passwordResetRedirectUrlFromEnv = String.fromEnvironment(
    'PASSWORD_RESET_REDIRECT_URL',
  );

  static const _fallbackPasswordResetRedirectUrl =
      'https://veil-12353.web.app/reset-password';

  static const _passwordResetPath = '/reset-password';

  static String get supabaseUrl =>
      _supabaseUrlFromEnv.isNotEmpty ? _supabaseUrlFromEnv : _plainSupabaseUrl;

  static String get supabaseAnonKey => _supabaseAnonKeyFromEnv.isNotEmpty
      ? _supabaseAnonKeyFromEnv
      : _plainSupabaseAnonKey;

  static String get passwordResetRedirectUrl =>
      _passwordResetRedirectUrlFromEnv.isNotEmpty
      ? _passwordResetRedirectUrlFromEnv
      : passwordResetRedirectUrlFor(Uri.base);

  static String passwordResetRedirectUrlFor(Uri currentUri) {
    if (_passwordResetRedirectUrlFromEnv.isNotEmpty) {
      return _passwordResetRedirectUrlFromEnv;
    }
    if ((currentUri.scheme == 'http' || currentUri.scheme == 'https') &&
        currentUri.host.isNotEmpty) {
      return Uri(
        scheme: currentUri.scheme,
        host: currentUri.host,
        port: currentUri.hasPort ? currentUri.port : null,
        path: _passwordResetPath,
      ).toString();
    }

    return _fallbackPasswordResetRedirectUrl;
  }

  static bool get hasSupabaseCredentials =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
