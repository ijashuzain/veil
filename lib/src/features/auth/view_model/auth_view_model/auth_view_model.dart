import 'dart:async';
import 'dart:developer';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veil/src/core/config/app_environment.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/auth/repository/auth_repository.dart';

part 'auth_view_model.freezed.dart';
part 'auth_view_model.g.dart';

@freezed
abstract class AuthViewState with _$AuthViewState {
  const AuthViewState._();

  const factory AuthViewState({
    User? user,
    @Default(false) bool isSignUp,
    @Default(Status.initial()) Status authStatus,
  }) = _AuthViewState;

  bool get isAuthenticated => user != null;
}

@riverpod
class AuthViewModel extends _$AuthViewModel {
  StreamSubscription<AuthState>? _subscription;

  @override
  AuthViewState build() {
    final repository = ref.watch(authRepositoryProvider);
    final currentUser = repository.currentUser;
    log('AuthViewModel.build restoredUser=${_shortUserId(currentUser?.id)}');
    _subscription = repository.authStateChanges.listen((event) {
      log(
        'AuthViewModel.authState event=${event.event} '
        'userId=${_shortUserId(event.session?.user.id)} '
        'hasSession=${event.session != null}',
      );
      state = state.copyWith(user: event.session?.user);
    });
    ref.onDispose(() => _subscription?.cancel());
    return AuthViewState(user: currentUser);
  }

  void toggleMode() {
    state = state.copyWith(isSignUp: !state.isSignUp);
  }

  void clearStatus() {
    state = state.copyWith(authStatus: const Status.initial());
  }

  Future<void> submit({
    required String email,
    required String password,
    String displayName = '',
  }) async {
    final mode = state.isSignUp ? 'signUp' : 'signIn';
    log('AuthViewModel.submit started mode=$mode email=${_safeEmail(email)}');
    try {
      if (email.trim().isEmpty) {
        log('AuthViewModel.submit validation failed: missing email.');
        state = state.copyWith(
          authStatus: const Status.failure('Please enter your email.'),
        );
        return;
      }
      if (password.isEmpty) {
        log('AuthViewModel.submit validation failed: missing password.');
        state = state.copyWith(
          authStatus: const Status.failure('Please enter your password.'),
        );
        return;
      }
      if (state.isSignUp && displayName.trim().isEmpty) {
        log('AuthViewModel.submit validation failed: missing display name.');
        state = state.copyWith(
          authStatus: const Status.failure('Please enter your name.'),
        );
        return;
      }
      state = state.copyWith(authStatus: const Status.loading());
      final repository = ref.read(authRepositoryProvider);
      final user = state.isSignUp
          ? await repository.signUp(
              email: email,
              password: password,
              displayName: displayName,
            )
          : await repository.signIn(email: email, password: password);
      if (user == null) {
        log('AuthViewModel.submit completed without a user.');
        state = state.copyWith(
          authStatus: const Status.failure(
            'Login did not return a user session. Please try again.',
          ),
        );
        return;
      }
      log('AuthViewModel.submit success userId=${_shortUserId(user.id)}');
      state = state.copyWith(user: user, authStatus: const Status.success());
    } catch (error) {
      final message = _messageFromError(error);
      log('AuthViewModel.submit failed: $message', error: error);
      state = state.copyWith(authStatus: Status.failure(message));
    }
  }

  Future<void> signOut() async {
    log('AuthViewModel.signOut started.');
    await ref.read(authRepositoryProvider).signOut();
    state = state.copyWith(user: null, authStatus: const Status.initial());
    log('AuthViewModel.signOut complete.');
  }

  Future<bool> sendPasswordReset({
    required String email,
    String? redirectTo,
  }) async {
    final trimmedEmail = email.trim();
    log(
      'AuthViewModel.sendPasswordReset started email=${_safeEmail(trimmedEmail)}',
    );
    try {
      if (trimmedEmail.isEmpty) {
        log(
          'AuthViewModel.sendPasswordReset validation failed: missing email.',
        );
        state = state.copyWith(
          authStatus: const Status.failure('Please enter your email.'),
        );
        return false;
      }
      state = state.copyWith(authStatus: const Status.loading());
      await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(
            email: trimmedEmail,
            redirectTo: redirectTo ?? AppEnvironment.passwordResetRedirectUrl,
          );
      state = state.copyWith(authStatus: Status.success(data: trimmedEmail));
      log('AuthViewModel.sendPasswordReset success.');
      return true;
    } catch (error) {
      final message = _messageFromError(error);
      log('AuthViewModel.sendPasswordReset failed: $message', error: error);
      state = state.copyWith(authStatus: Status.failure(message));
      return false;
    }
  }

  Future<bool> updatePassword(String password) async {
    log('AuthViewModel.updatePassword started.');
    try {
      if (password.isEmpty) {
        state = state.copyWith(
          authStatus: const Status.failure('Please enter a new password.'),
        );
        return false;
      }
      if (password.length < 6) {
        state = state.copyWith(
          authStatus: const Status.failure(
            'Password must be at least 6 characters.',
          ),
        );
        return false;
      }
      state = state.copyWith(authStatus: const Status.loading());
      await ref.read(authRepositoryProvider).updatePassword(password);
      state = state.copyWith(authStatus: const Status.success());
      log('AuthViewModel.updatePassword success.');
      return true;
    } catch (error) {
      final message = _messageFromError(error);
      log('AuthViewModel.updatePassword failed: $message', error: error);
      state = state.copyWith(authStatus: Status.failure(message));
      return false;
    }
  }

  Future<bool> completePasswordReset(String password) async {
    log('AuthViewModel.completePasswordReset started.');
    try {
      if (password.isEmpty) {
        state = state.copyWith(
          authStatus: const Status.failure('Please enter a new password.'),
        );
        return false;
      }
      if (password.length < 6) {
        state = state.copyWith(
          authStatus: const Status.failure(
            'Password must be at least 6 characters.',
          ),
        );
        return false;
      }
      state = state.copyWith(authStatus: const Status.loading());
      final repository = ref.read(authRepositoryProvider);
      await repository.updatePassword(password);
      await repository.signOut();
      state = state.copyWith(user: null, authStatus: const Status.success());
      log('AuthViewModel.completePasswordReset success.');
      return true;
    } catch (error) {
      final message = _messageFromError(error);
      log('AuthViewModel.completePasswordReset failed: $message', error: error);
      state = state.copyWith(authStatus: Status.failure(message));
      return false;
    }
  }
}

String _messageFromError(Object error) {
  if (error is AuthSessionMissingException) {
    return 'This reset link is invalid or has expired. Please request a new password reset link.';
  }
  if (error is AuthException) return error.message;
  return error.toString();
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
