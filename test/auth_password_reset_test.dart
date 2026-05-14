import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veil/app/services/supabase_services/supabase_service.dart';
import 'package:veil/src/core/config/app_environment.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/router/route_paths.dart';
import 'package:veil/src/features/auth/repository/auth_repository.dart';
import 'package:veil/src/features/auth/view/reset_password_view.dart';
import 'package:veil/src/features/onboarding/view/onboarding_view.dart';

void main() {
  test('reset password deep link survives app startup routing', () {
    expect(
      resolveInitialAppLocation(
        skipOnboarding: false,
        currentUri: Uri.parse('https://veil-12353.web.app/reset-password'),
      ),
      RoutePaths.resetPassword,
    );
    expect(
      resolveInitialAppLocation(
        skipOnboarding: true,
        currentUri: Uri.parse('https://veil-12353.web.app/'),
      ),
      RoutePaths.home,
    );
  });

  test('reset password recovery tokens route to reset page from root', () {
    expect(
      resolveInitialAppLocation(
        skipOnboarding: false,
        currentUri: Uri.parse(
          'https://veil.vexellab.com/#access_token=token&type=recovery',
        ),
      ),
      RoutePaths.resetPassword,
    );
    expect(
      resolveInitialAppLocation(
        skipOnboarding: true,
        currentUri: Uri.parse(
          'https://veil.vexellab.com/?code=abc&type=recovery',
        ),
      ),
      RoutePaths.resetPassword,
    );
  });

  test('expired reset links route to reset page with friendly error', () {
    final expiredLinkUri = Uri.parse(
      'https://veil.vexellab.com/'
      '#error=access_denied&error_code=otp_expired&'
      'error_description=Email+link+is+invalid+or+has+expired',
    );

    expect(
      resolveInitialAppLocation(
        skipOnboarding: false,
        currentUri: expiredLinkUri,
      ),
      RoutePaths.resetPassword,
    );
    expect(
      passwordResetAuthErrorMessageFromUri(expiredLinkUri),
      'This reset link is invalid or has expired. Please request a new password reset link.',
    );
  });

  test('password reset callbacks override browser startup route', () {
    final expiredLinkRouter = createRouter(
      skipOnboarding: false,
      initialUri: Uri.parse(
        'https://veil.vexellab.com/'
        '#error=access_denied&error_code=otp_expired&'
        'error_description=Email+link+is+invalid+or+has+expired',
      ),
    );
    addTearDown(expiredLinkRouter.dispose);

    final regularRouter = createRouter(
      skipOnboarding: false,
      initialUri: Uri.parse('https://veil.vexellab.com/'),
    );
    addTearDown(regularRouter.dispose);

    expect(expiredLinkRouter.overridePlatformDefaultLocation, isTrue);
    expect(regularRouter.overridePlatformDefaultLocation, isFalse);
  });

  testWidgets('reset password shows expired link message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResetPasswordView(
          initialErrorMessage:
              'This reset link is invalid or has expired. Please request a new password reset link.',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Reset link expired'), findsOneWidget);
    expect(find.textContaining('Please request a new'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'New password'), findsNothing);
    expect(find.text('Back to login'), findsOneWidget);
  });

  test('password reset redirect uses current web origin by default', () {
    expect(
      AppEnvironment.passwordResetRedirectUrlFor(
        Uri.parse('https://veil.vexellab.com/profile'),
      ),
      'https://veil.vexellab.com/reset-password',
    );
  });

  test('password reset emails use browser-independent auth links', () {
    expect(SupabaseService.authOptions.authFlowType, AuthFlowType.implicit);
  });

  testWidgets('forgot password sends reset link and returns to login', (
    tester,
  ) async {
    final repository = _PasswordResetAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: OnboardingView(onGetStarted: _noop)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Forgot password?'));
    await tester.pump();

    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.text('Password'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'ijas@example.com',
    );
    await tester.tap(find.text('Send reset link'));
    await tester.pump();
    await tester.pump();

    expect(repository.resetEmail, 'ijas@example.com');
    expect(repository.redirectTo, AppEnvironment.passwordResetRedirectUrl);
    expect(find.text('Reset link sent'), findsOneWidget);
    expect(find.textContaining('ijas@example.com'), findsOneWidget);

    await tester.tap(find.text('Back to login'));
    await tester.pump();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
  });

  testWidgets('reset password updates password and returns to login', (
    tester,
  ) async {
    final repository = _PasswordResetAuthRepository();
    var returnedToLogin = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: ResetPasswordView(onBackToLogin: () => returnedToLogin = true),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, 'New password'),
      'new-secret-123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm password'),
      'new-secret-123',
    );
    await tester.tap(find.text('Update password'));
    await tester.pump();
    await tester.pump();

    expect(repository.updatedPassword, 'new-secret-123');
    expect(repository.signedOut, isTrue);
    expect(find.text('Password updated'), findsOneWidget);

    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(returnedToLogin, isTrue);
  });

  testWidgets('reset password requires matching passwords', (tester) async {
    final repository = _PasswordResetAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ResetPasswordView()),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, 'New password'),
      'new-secret-123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm password'),
      'different-secret',
    );
    await tester.tap(find.text('Update password'));
    await tester.pump();
    await tester.pump();

    expect(repository.updatedPassword, isNull);
    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('reset password explains missing recovery session', (
    tester,
  ) async {
    final repository = _PasswordResetAuthRepository()
      ..throwMissingSessionOnUpdate = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ResetPasswordView()),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, 'New password'),
      'new-secret-123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm password'),
      'new-secret-123',
    );
    await tester.tap(find.text('Update password'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'This reset link is invalid or has expired. Please request a new password reset link.',
      ),
      findsOneWidget,
    );
  });
}

void _noop() {}

class _PasswordResetAuthRepository extends AuthRepository {
  String? resetEmail;
  String? redirectTo;
  String? updatedPassword;
  bool signedOut = false;
  bool throwMissingSessionOnUpdate = false;

  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<void> requestPasswordReset({
    required String email,
    required String redirectTo,
  }) async {
    resetEmail = email;
    this.redirectTo = redirectTo;
  }

  @override
  Future<void> updatePassword(String password) async {
    if (throwMissingSessionOnUpdate) {
      throw AuthSessionMissingException();
    }
    updatedPassword = password;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}
