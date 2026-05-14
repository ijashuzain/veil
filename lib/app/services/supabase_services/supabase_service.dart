import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veil/src/core/config/app_environment.dart';

class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static const authOptions = FlutterAuthClientOptions(
    authFlowType: AuthFlowType.implicit,
  );

  static bool get isConfigured => AppEnvironment.hasSupabaseCredentials;

  static bool get isInitialized => _initialized;

  static bool get hasActiveSession => client?.auth.currentSession != null;

  static User? get currentUser => client?.auth.currentUser;

  static Future<void> init() async {
    if (!isConfigured) {
      log('Supabase is not configured; authentication will be unavailable.');
      return;
    }
    if (_initialized) {
      log(
        'Supabase already initialized. hasSession=$hasActiveSession '
        'userId=${_shortUserId(currentUser?.id)}',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: AppEnvironment.supabaseUrl,
        anonKey: AppEnvironment.supabaseAnonKey,
        authOptions: authOptions,
      );
      _initialized = true;
      log(
        'Supabase initialized. hasSession=$hasActiveSession '
        'userId=${_shortUserId(currentUser?.id)}',
      );
    } catch (error, stackTrace) {
      log(
        'Supabase initialization failed; using local social storage.',
        error: error,
        stackTrace: stackTrace,
      );
      _initialized = false;
    }
  }

  static SupabaseClient? get client {
    if (!_initialized) return null;
    return Supabase.instance.client;
  }

  static String _shortUserId(String? id) {
    if (id == null || id.isEmpty) return 'none';
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }
}
