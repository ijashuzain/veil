import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil/app/services/supabase_services/supabase_service.dart';
import 'app_access_config.dart';

class AppAccessRepository {
  AppAccessRepository({
    Future<Map<String, dynamic>?> Function()? fetch,
    Future<SharedPreferences> Function()? preferences,
    DateTime Function()? now,
  }) : fetch = fetch ?? _fetch,
       preferences = preferences ?? SharedPreferences.getInstance,
       now = now ?? DateTime.now;

  static const cacheKey = 'app_access_config_v1';
  static const cacheLifetime = Duration(hours: 6);
  final Future<Map<String, dynamic>?> Function() fetch;
  final Future<SharedPreferences> Function() preferences;
  final DateTime Function() now;

  static Future<Map<String, dynamic>?> _fetch() async {
    final client = SupabaseService.client;
    if (client == null) throw StateError('Supabase unavailable');
    return await client
        .from('app_config')
        .select()
        .eq('id', true)
        .maybeSingle();
  }

  Future<AppAccessConfig> load() async {
    SharedPreferences? prefs;
    try {
      prefs = await preferences().timeout(const Duration(seconds: 1));
    } catch (_) {
      /* Storage is optional. */
    }
    try {
      final row = await fetch().timeout(const Duration(seconds: 5));
      // A successful missing row explicitly disables configuration.
      final config = row == null
          ? const AppAccessConfig()
          : AppAccessConfig.fromJson(row);
      try {
        await prefs?.setString(
          cacheKey,
          jsonEncode({
            'savedAt': now().toUtc().toIso8601String(),
            'config': config.toJson(),
          }),
        );
      } catch (_) {
        /* Keep the freshly fetched policy. */
      }
      return config;
    } catch (_) {
      try {
        final raw = prefs?.getString(cacheKey);
        if (raw != null) {
          final cached = jsonDecode(raw) as Map<String, dynamic>;
          final age = now().difference(
            DateTime.parse(cached['savedAt'] as String),
          );
          if (!age.isNegative && age < cacheLifetime) {
            return AppAccessConfig.fromJson(
              cached['config'] as Map<String, dynamic>,
            );
          }
        }
      } catch (_) {
        /* Invalid caches must not lock out the app. */
      }
      return const AppAccessConfig();
    }
  }
}
