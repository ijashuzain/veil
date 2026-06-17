class AppEnvironment {
  const AppEnvironment._();

  static const privacyPolicyUrl =
      'https://www.vexellab.com/veil/privacy-policy/';

  static const termsAndConditionsUrl =
      'https://www.vexellab.com/veil/terms-and-conditions/';

  static const accountDeletionUrl =
      'https://www.vexellab.com/veil/account-deletion/';

  static const supportUrl = 'https://www.vexellab.com/veil/support/';

  static const tmdbAttributionUrl = 'https://www.themoviedb.org/';

  static const _tmdbReadAccessTokenFromEnv = String.fromEnvironment(
    'TMDB_READ_ACCESS_TOKEN',
  );

  static const _tmdbApiKeyFromEnv = String.fromEnvironment('TMDB_API_KEY');

  static const _tmdbBaseUrlFromEnv = String.fromEnvironment('TMDB_BASE_URL');

  static const tmdbDirectBaseUrl = 'https://api.themoviedb.org/3';

  static String get tmdbReadAccessToken => _tmdbReadAccessTokenFromEnv;

  static String get tmdbApiKey => _tmdbApiKeyFromEnv;

  static String get tmdbBaseUrl {
    if (_tmdbBaseUrlFromEnv.trim().isNotEmpty) {
      return _withoutTrailingSlash(_tmdbBaseUrlFromEnv.trim());
    }
    if (supabaseUrl.trim().isNotEmpty) {
      return '${_withoutTrailingSlash(supabaseUrl)}/functions/v1/tmdb/3';
    }
    return tmdbDirectBaseUrl;
  }

  static bool get usesTmdbProxy {
    final host = Uri.tryParse(tmdbBaseUrl)?.host.toLowerCase();
    return host != null && host != 'api.themoviedb.org';
  }

  static bool get hasTmdbCredentials =>
      usesTmdbProxy || tmdbReadAccessToken.isNotEmpty || tmdbApiKey.isNotEmpty;

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

  static String _withoutTrailingSlash(String value) {
    var result = value;
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
