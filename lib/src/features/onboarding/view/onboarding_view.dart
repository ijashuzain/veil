import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veil/src/core/config/app_environment.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/auth/view_model/auth_view_model/auth_view_model.dart';
import 'package:veil/src/shared/components/veil_toast.dart';
import 'package:veil/src/shared/components/veil_logo.dart';
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
  bool _acceptedTerms = false;
  bool _passwordVisible = false;
  String _resetEmail = '';
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _openExternalUrl(AppEnvironment.termsAndConditionsUrl);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openExternalUrl(AppEnvironment.privacyPolicyUrl);
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final authVm = ref.read(authViewModelProvider.notifier);
    final isBusy = auth.authStatus is StatusLoading;
    final isResetLinkSent = _resetLinkSent;
    final isForgotPassword = _isRecoveringPassword && !isResetLinkSent;
    final needsTermsAcceptance =
        auth.isSignUp && !isForgotPassword && !isResetLinkSent;
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
                          color: VeilColors.panel.withValues(alpha: .88),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: VeilColors.hairlineStrong),
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
                                const VeilLogo(size: 18, center: true),
                                Gap(24.dp),
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      height: 1.14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: auth.isSignUp
                                            ? 'Sign Up'
                                            : 'Sign In',
                                      ),
                                      // TextSpan(
                                      //   text: 'every',
                                      //   style: TextStyle(color: VeilColors.red),
                                      // ),
                                      // TextSpan(text: ' film\nyou watch'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Discover movies, log watched titles,\nrate stories, and share thoughtful reviews.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: VeilColors.text3,
                                    fontSize: 12,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
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
                                  obscure: !_passwordVisible,
                                  keyboardType: TextInputType.visiblePassword,
                                  suffixIcon: IconButton(
                                    tooltip: _passwordVisible
                                        ? 'Hide password'
                                        : 'Show password',
                                    onPressed: isBusy
                                        ? null
                                        : () => setState(
                                            () => _passwordVisible =
                                                !_passwordVisible,
                                          ),
                                    icon: Icon(
                                      _passwordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: VeilColors.text3,
                                      size: 20,
                                    ),
                                  ),
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
                              if (needsTermsAcceptance) ...[
                                const SizedBox(height: 12),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: VeilColors.panelRaised,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: VeilColors.hairline,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      2,
                                      4,
                                      4,
                                      4,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CheckboxListTile.adaptive(
                                          value: _acceptedTerms,
                                          dense: true,
                                          visualDensity: VisualDensity.compact,
                                          contentPadding: EdgeInsets.zero,
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          activeColor: VeilColors.red,
                                          onChanged: isBusy
                                              ? null
                                              : (value) => setState(
                                                  () => _acceptedTerms =
                                                      value ?? false,
                                                ),
                                          title: RichText(
                                            text: TextSpan(
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.normal,
                                                height: 1.3,
                                              ),
                                              children: [
                                                const TextSpan(
                                                  text: 'I agree to the ',
                                                ),
                                                TextSpan(
                                                  text: 'Terms',
                                                  recognizer: _termsRecognizer,
                                                  style: const TextStyle(
                                                    color: VeilColors.red,
                                                  ),
                                                ),
                                                const TextSpan(text: ' and '),
                                                TextSpan(
                                                  text: 'Privacy Policy',
                                                  recognizer:
                                                      _privacyRecognizer,
                                                  style: const TextStyle(
                                                    color: VeilColors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed:
                                      isBusy ||
                                          (needsTermsAcceptance &&
                                              !_acceptedTerms)
                                      ? null
                                      : () => _submitAuthAction(
                                          authVm,
                                          isForgotPassword: isForgotPassword,
                                          isResetLinkSent: isResetLinkSent,
                                        ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: VeilColors.red,
                                    foregroundColor: Colors.black,
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
                              // if (!isResetLinkSent) ...[
                              //   const Text(
                              //     'This product uses TMDB and the TMDB APIs',
                              //     textAlign: TextAlign.center,
                              //     style: TextStyle(
                              //       color: VeilColors.text3,
                              //       fontSize: 10,
                              //       height: 1.45,
                              //     ),
                              //   ),
                              // ],
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
      _passwordVisible = false;
    });
  }

  void _showLogin(AuthViewModel authVm) {
    authVm.clearStatus();
    setState(() {
      _isRecoveringPassword = false;
      _resetLinkSent = false;
      _resetEmail = '';
      _passwordVisible = false;
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

  Future<void> _openExternalUrl(String url) async {
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted || opened) return;
      showVeilToast(context, 'Could not open that page right now.');
    } catch (_) {
      if (!mounted) return;
      showVeilToast(context, 'Could not open that page right now.');
    }
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

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
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: VeilColors.panelRaised,
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
