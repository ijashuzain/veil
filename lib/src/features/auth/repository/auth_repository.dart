import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veil/app/services/supabase_services/supabase_service.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(client: SupabaseService.client);
}

class AuthRepository {
  const AuthRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  User? get currentUser => _client?.auth.currentUser;

  Stream<AuthState> get authStateChanges {
    final client = _client;
    if (client == null) return const Stream.empty();
    return client.auth.onAuthStateChange;
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    log('AuthRepository.signIn started for ${_safeEmail(email)}');
    try {
      final response = await _requireClient().auth.signInWithPassword(
        email: email,
        password: password,
      );
      log(
        'AuthRepository.signIn success userId=${_shortUserId(response.user?.id)} '
        'hasSession=${response.session != null}',
      );
      return response.user;
    } catch (error, stackTrace) {
      log(
        'AuthRepository.signIn failed for ${_safeEmail(email)}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<User?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    log('AuthRepository.signUp started for ${_safeEmail(email)}');
    try {
      final response = await _requireClient().auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName.trim()},
      );
      log(
        'AuthRepository.signUp success userId=${_shortUserId(response.user?.id)} '
        'hasSession=${response.session != null}',
      );
      return response.user;
    } catch (error, stackTrace) {
      log(
        'AuthRepository.signUp failed for ${_safeEmail(email)}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    log('AuthRepository.signOut started.');
    await _requireClient().auth.signOut();
    log('AuthRepository.signOut complete.');
  }

  Future<void> requestPasswordReset({
    required String email,
    required String redirectTo,
  }) async {
    log('AuthRepository.requestPasswordReset started for ${_safeEmail(email)}');
    try {
      await _requireClient().auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo,
      );
      log('AuthRepository.requestPasswordReset email sent.');
    } catch (error, stackTrace) {
      log(
        'AuthRepository.requestPasswordReset failed for ${_safeEmail(email)}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> updatePassword(String password) async {
    log('AuthRepository.updatePassword started.');
    try {
      await _requireClient().auth.updateUser(
        UserAttributes(password: password),
      );
      log('AuthRepository.updatePassword complete.');
    } catch (error, stackTrace) {
      log(
        'AuthRepository.updatePassword failed.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured for authentication.');
    }
    return client;
  }
}

String _safeEmail(String email) {
  final trimmed = email.trim();
  final at = trimmed.indexOf('@');
  if (at <= 1) return trimmed.isEmpty ? 'empty' : '***';
  return '${trimmed.substring(0, 1)}***${trimmed.substring(at)}';
}

String _shortUserId(String? id) {
  if (id == null || id.isEmpty) return 'none';
  if (id.length <= 8) return id;
  return '${id.substring(0, 8)}...';
}
