import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/auth/view_model/auth_view_model/auth_view_model.dart';
import 'package:veil/src/shared/components/veil_logo.dart';

class ResetPasswordView extends ConsumerStatefulWidget {
  const ResetPasswordView({
    super.key,
    this.onBackToLogin,
    this.initialErrorMessage,
  });

  final VoidCallback? onBackToLogin;
  final String? initialErrorMessage;

  @override
  ConsumerState<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends ConsumerState<ResetPasswordView> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _localError = '';
  bool _updated = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialErrorMessage = widget.initialErrorMessage?.trim();
    late final Widget resetContent;

    if (initialErrorMessage != null && initialErrorMessage.isNotEmpty) {
      resetContent = _ResetLinkExpired(
        message: initialErrorMessage,
        onBackToLogin: _backToLogin,
      );
    } else if (_updated) {
      resetContent = _ResetSuccess(onBackToLogin: _backToLogin);
    } else {
      final auth = ref.watch(authViewModelProvider);
      final authVm = ref.read(authViewModelProvider.notifier);
      final isBusy = auth.authStatus is StatusLoading;
      final error = _localError.isNotEmpty
          ? _localError
          : auth.authStatus.errorMessage;

      resetContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VeilLogo(size: 26, center: true),
          const SizedBox(height: 22),
          const Text(
            'Create a new password',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Choose a new password for your Veil account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: VeilColors.text3,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          _ResetPasswordField(
            controller: _passwordController,
            hint: 'New password',
          ),
          const SizedBox(height: 10),
          _ResetPasswordField(
            controller: _confirmPasswordController,
            hint: 'Confirm password',
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: VeilColors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isBusy ? null : () => _updatePassword(authVm),
              style: FilledButton.styleFrom(
                backgroundColor: VeilColors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                isBusy ? 'Please wait...' : 'Update password',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: isBusy ? null : _backToLogin,
            child: const Text(
              'Back to login',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: VeilColors.bg0,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: VeilColors.bg2.withValues(alpha: .86),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: VeilColors.hairline),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 28, 26, 22),
                  child: resetContent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updatePassword(AuthViewModel authVm) async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (password != confirmPassword) {
      setState(() => _localError = 'Passwords do not match.');
      return;
    }

    setState(() => _localError = '');
    final updated = await authVm.completePasswordReset(password);
    if (!mounted || !updated) return;
    setState(() => _updated = true);
  }

  void _backToLogin() {
    final callback = widget.onBackToLogin;
    if (callback != null) {
      callback();
      return;
    }
    const OnboardingRoute().go(context);
  }
}

class _ResetSuccess extends StatelessWidget {
  const _ResetSuccess({required this.onBackToLogin});

  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, color: VeilColors.red, size: 40),
        const SizedBox(height: 14),
        const Text(
          'Password updated',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'You can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: VeilColors.text3, fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onBackToLogin,
            style: FilledButton.styleFrom(
              backgroundColor: VeilColors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              'Login',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResetLinkExpired extends StatelessWidget {
  const _ResetLinkExpired({required this.message, required this.onBackToLogin});

  final String message;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.link_off_rounded, color: VeilColors.red, size: 40),
        const SizedBox(height: 14),
        const Text(
          'Reset link expired',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: VeilColors.text3,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onBackToLogin,
            style: FilledButton.styleFrom(
              backgroundColor: VeilColors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              'Back to login',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResetPasswordField extends StatelessWidget {
  const _ResetPasswordField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: VeilColors.text3),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: VeilColors.text3,
          size: 19,
        ),
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
