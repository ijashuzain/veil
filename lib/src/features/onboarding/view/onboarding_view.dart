import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/auth/view_model/auth_view_model/auth_view_model.dart';
import 'package:veil/src/shared/components/poster_art.dart';
import 'package:veil/src/shared/components/veil_toast.dart';
import 'package:veil/src/shared/components/veil_logo.dart';
import 'package:veil/src/shared/data/mock_catalog.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key, this.onGetStarted});

  final VoidCallback? onGetStarted;

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _handledAuthenticatedUser = false;
  bool _isRecoveringPassword = false;
  bool _resetLinkSent = false;
  String _resetEmail = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final authVm = ref.read(authViewModelProvider.notifier);
    final posters = VeilCatalog.items.take(12).toList();
    final isBusy = auth.authStatus is StatusLoading;
    final isResetLinkSent = _resetLinkSent;
    final isForgotPassword = _isRecoveringPassword && !isResetLinkSent;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final breakpoint = VeilBreakpoint.of(context);
    final gutter = VeilLayout.pageGutter(context);
    final scrollTopPadding = screenHeight < 700 ? 70.0 : 92.0;
    ref.listen<AuthViewState>(authViewModelProvider, (previous, next) {
      final nextError = next.authStatus.errorMessage;
      final previousError = previous?.authStatus.errorMessage ?? '';
      if (nextError.isNotEmpty && nextError != previousError) {
        log('Onboarding auth error: $nextError');
        showVeilToast(context, nextError);
      }
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        log('Onboarding received authenticated auth state.');
        _completeAuthenticationFlow();
      }
    });
    if (auth.isAuthenticated && !_handledAuthenticatedUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        log('Onboarding found restored authenticated user.');
        _completeAuthenticationFlow();
      });
    }
    return Scaffold(
      backgroundColor: VeilColors.bg0,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Stack(
          children: [
            Positioned.fill(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(gutter, 34, gutter, 0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: switch (breakpoint) {
                    VeilBreakpoint.mobile => 3,
                    VeilBreakpoint.tablet => 4,
                    VeilBreakpoint.desktop => 6,
                  },
                  mainAxisSpacing: 7,
                  crossAxisSpacing: 7,
                  childAspectRatio: 2 / 3,
                ),
                itemCount: posters.length,
                itemBuilder: (context, index) => Opacity(
                  opacity: .82,
                  child: PosterArt(
                    item: posters[index],
                    width: 110,
                    height: 165,
                    radius: 6,
                    showTitle: false,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .18),
                      VeilColors.bg0.withValues(alpha: .65),
                      VeilColors.bg0,
                    ],
                    stops: const [.05, .55, .78],
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: VeilLogo(size: 26, center: true),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  scrollTopPadding,
                  gutter,
                  keyboardInset + 28,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight - keyboardInset - 130,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: breakpoint.isMobile ? double.infinity : 460,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: VeilColors.bg2.withValues(alpha: .80),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: VeilColors.hairline),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .42),
                              blurRadius: 28,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(26, 28, 26, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isResetLinkSent) ...[
                                const Icon(
                                  Icons.mark_email_read_outlined,
                                  color: VeilColors.red,
                                  size: 36,
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Reset link sent',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'We sent a password reset link to $_resetEmail.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: VeilColors.text3,
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                              ] else if (isForgotPassword) ...[
                                const Text(
                                  'Reset your password',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Enter your account email and we will send you a secure reset link.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: VeilColors.text3,
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                              ] else ...[
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: const TextSpan(
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      height: 1.14,
                                    ),
                                    children: [
                                      TextSpan(text: 'Log '),
                                      TextSpan(
                                        text: 'every',
                                        style: TextStyle(color: VeilColors.red),
                                      ),
                                      TextSpan(text: ' film\nyou watch'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'your watch diary - reimagined',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: VeilColors.text3,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Discover movies, log watched titles,\nrate stories, and share thoughtful reviews.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: VeilColors.text3,
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              if (!isResetLinkSent &&
                                  auth.isSignUp &&
                                  !isForgotPassword) ...[
                                _AuthField(
                                  controller: _nameController,
                                  hint: 'Name',
                                  icon: Icons.person_outline_rounded,
                                  keyboardType: TextInputType.name,
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (!isResetLinkSent)
                                _AuthField(
                                  controller: _emailController,
                                  hint: 'Email',
                                  icon: Icons.mail_outline_rounded,
                                ),
                              if (!isResetLinkSent && !isForgotPassword) ...[
                                const SizedBox(height: 10),
                                _AuthField(
                                  controller: _passwordController,
                                  hint: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: true,
                                ),
                              ],
                              if (auth.authStatus.errorMessage.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  auth.authStatus.errorMessage,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: VeilColors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: isBusy
                                      ? null
                                      : () => _submitAuthAction(
                                          authVm,
                                          isForgotPassword: isForgotPassword,
                                          isResetLinkSent: isResetLinkSent,
                                        ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: VeilColors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  child: Text(
                                    _primaryButtonLabel(
                                      auth: auth,
                                      isBusy: isBusy,
                                      isForgotPassword: isForgotPassword,
                                      isResetLinkSent: isResetLinkSent,
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              if (!isResetLinkSent) ...[
                                const SizedBox(height: 14),
                                if (!auth.isSignUp && !isForgotPassword)
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 12,
                                    runSpacing: 0,
                                    children: [
                                      TextButton(
                                        onPressed: isBusy
                                            ? null
                                            : () => _showForgotPassword(authVm),
                                        child: const Text(
                                          'Forgot password?',
                                          style: TextStyle(
                                            color: VeilColors.text2,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: isBusy
                                            ? null
                                            : authVm.toggleMode,
                                        child: const Text(
                                          'New here? Create account',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  TextButton(
                                    onPressed: isBusy
                                        ? null
                                        : () {
                                            if (isForgotPassword) {
                                              _showLogin(authVm);
                                            } else {
                                              authVm.toggleMode();
                                            }
                                          },
                                    child: Text(
                                      isForgotPassword
                                          ? 'Back to login'
                                          : 'Already have an account? Sign in',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _completeAuthenticationFlow() {
    if (_handledAuthenticatedUser) return;
    _handledAuthenticatedUser = true;
    final callback = widget.onGetStarted;
    if (callback != null) {
      callback();
    } else {
      const VeilShellRoute().go(context);
    }
  }

  void _showForgotPassword(AuthViewModel authVm) {
    authVm.clearStatus();
    _passwordController.clear();
    setState(() {
      _isRecoveringPassword = true;
      _resetLinkSent = false;
      _resetEmail = '';
    });
  }

  void _showLogin(AuthViewModel authVm) {
    authVm.clearStatus();
    setState(() {
      _isRecoveringPassword = false;
      _resetLinkSent = false;
      _resetEmail = '';
    });
  }

  Future<void> _submitAuthAction(
    AuthViewModel authVm, {
    required bool isForgotPassword,
    required bool isResetLinkSent,
  }) async {
    if (isResetLinkSent) {
      _showLogin(authVm);
      return;
    }
    if (isForgotPassword) {
      final email = _emailController.text.trim();
      final sent = await authVm.sendPasswordReset(email: email);
      if (!mounted || !sent) return;
      setState(() {
        _resetEmail = email;
        _resetLinkSent = true;
      });
      return;
    }

    await authVm.submit(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );
  }

  String _primaryButtonLabel({
    required AuthViewState auth,
    required bool isBusy,
    required bool isForgotPassword,
    required bool isResetLinkSent,
  }) {
    if (isBusy) return 'Please wait...';
    if (isResetLinkSent) return 'Back to login';
    if (isForgotPassword) return 'Send reset link';
    return auth.isSignUp ? 'Create account' : 'Sign in';
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType:
          keyboardType ??
          (obscure
              ? TextInputType.visiblePassword
              : TextInputType.emailAddress),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: VeilColors.text3),
        prefixIcon: Icon(icon, color: VeilColors.text3, size: 19),
        filled: true,
        fillColor: VeilColors.bg1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VeilColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VeilColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VeilColors.red),
        ),
      ),
    );
  }
}
