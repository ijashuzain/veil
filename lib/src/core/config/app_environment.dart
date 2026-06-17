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

  static const _tmdbImageBaseUrlFromEnv = String.fromEnvironment(
    'TMDB_IMAGE_BASE_URL',
  );

  static const tmdbDirectBaseUrl = 'https://api.themoviedb.org/3';

  static const tmdbDirectImageBaseUrl = 'https://image.tmdb.org/t/p';

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

  static String get tmdbImageBaseUrl {
    if (_tmdbImageBaseUrlFromEnv.trim().isNotEmpty) {
      return _withoutTrailingSlash(_tmdbImageBaseUrlFromEnv.trim());
    }
    if (supabaseUrl.trim().isNotEmpty) {
      return '${_withoutTrailingSlash(supabaseUrl)}/functions/v1/tmdb-image/t/p';
    }
    return tmdbDirectImageBaseUrl;
  }

  static String? tmdbImageUrl(String size, String? path) {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final imagePath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    return '${_withoutTrailingSlash(tmdbImageBaseUrl)}/$size/$imagePath';
  }

  static String resolveTmdbImageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.toLowerCase() != 'image.tmdb.org') return url;

    final segments = uri.pathSegments;
    if (segments.length < 4 || segments[0] != 't' || segments[1] != 'p') {
      return url;
    }

    final size = segments[2];
    final path = segments.sublist(3).join('/');
    return tmdbImageUrl(size, path) ?? url;
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
