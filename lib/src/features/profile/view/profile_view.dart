import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/auth/utils/auth_display_name.dart';
import 'package:veil/src/features/auth/view_model/auth_view_model/auth_view_model.dart';
import 'package:veil/src/features/letterboxd/view/letterboxd_import_export_sheet.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/features/social/view_model/social_library_view_model/social_library_view_model.dart';
import 'package:veil/src/shared/components/veil_sheet.dart';
import 'package:veil/src/shared/components/veil_toast.dart';
import 'package:veil/src/shared/layout/adaptive_content.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  var _following = <String>[];
  var _followers = <String>[];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadFollows);
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialLibraryViewModelProvider);
    final auth = ref.watch(authViewModelProvider);
    final authVm = ref.read(authViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: VeilColors.bg0,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          0,
          VeilLayout.pageTopPadding(context),
          0,
          28,
        ),
        child: AdaptiveContent(
          maxWidth: VeilLayout.readableMaxWidth(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              _ProfileHeader(
                displayName: authDisplayName(auth.user),
                handle: auth.user?.email ?? '@veil',
                watched: social.diary.length,
                favorites: social.favorites.length,
                following: _following.length,
                followers: _followers.length,
                onFollowingTap: () => _openMembersPage(
                  title: 'Following',
                  users: _following,
                  emptyText: 'Not following anyone yet',
                  actionLabel: 'Following',
                ),
                onFollowersTap: () => _openMembersPage(
                  title: 'Followers',
                  users: _followers,
                  emptyText: 'No followers yet',
                  actionLabel: 'Follows you',
                ),
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                children: [
                  _SettingsRow(
                    icon: Icons.history_rounded,
                    label: 'My Activity',
                    onTap: () => _openActivityPage(social.entries),
                  ),
                  _SettingsRow(
                    icon: Icons.import_export_rounded,
                    label: 'Import/Export',
                    onTap: _openLetterboxdTools,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                children: [
                  _SettingsRow(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () => _openLegalPage(
                      title: 'Privacy Policy',
                      body:
                          'Veil stores your account, watch activity, follows, reviews, likes, and comments so the app can sync your library and social activity.',
                    ),
                  ),
                  _SettingsRow(
                    icon: Icons.description_outlined,
                    label: 'Terms and Condition',
                    onTap: () => _openLegalPage(
                      title: 'Terms and Condition',
                      body:
                          'Use Veil for personal movie and series discovery, logging, and reviews. Keep reviews and comments respectful.',
                    ),
                  ),
                  _SettingsRow(
                    key: const ValueKey('delete-account-row'),
                    icon: Icons.delete_forever_rounded,
                    label: 'Delete Account',
                    destructive: true,
                    onTap: () => _deleteAccount(authVm),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await authVm.signOut();
                    if (context.mounted) const OnboardingRoute().go(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VeilColors.red,
                    side: BorderSide(
                      color: VeilColors.red.withValues(alpha: .45),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        VeilTheme.controlRadius,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Sign out',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadFollows() async {
    final repository = ref.read(socialRepositoryProvider);
    final userId = repository.currentUserId;
    final following = await repository.following(userId);
    final followers = await repository.followers(userId);
    if (!mounted) return;
    setState(() {
      _following = following;
      _followers = followers;
    });
  }

  void _openLetterboxdTools() {
    showVeilBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VeilColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => const LetterboxdImportExportSheet(),
    );
  }

  void _openMembersPage({
    required String title,
    required List<String> users,
    required String emptyText,
    required String actionLabel,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProfileMembersPage(
          title: title,
          users: users,
          emptyText: emptyText,
          actionLabel: actionLabel,
        ),
      ),
    );
  }

  void _openActivityPage(List<SocialEntry> entries) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProfileActivityPage(entries: entries),
      ),
    );
  }

  void _openLegalPage({required String title, required String body}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProfileLegalPage(title: title, body: body),
      ),
    );
  }

  Future<void> _deleteAccount(AuthViewModel authVm) async {
    final reason = await showVeilBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VeilColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => const _DeleteAccountReasonSheet(),
    );
    if (!mounted || reason == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: VeilColors.panel,
          title: const Text('Delete account?'),
          content: const Text(
            'Your profile will be anonymized and private library activity will be removed. Reviews, likes, and comments stay visible as Deleted user.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('confirm-delete-account'),
              style: FilledButton.styleFrom(backgroundColor: VeilColors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete account'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) return;

    try {
      await ref
          .read(socialLibraryViewModelProvider.notifier)
          .deleteCurrentAccount(reason: reason);
      await authVm.signOut();
      if (!mounted) return;
      try {
        const OnboardingRoute().go(context);
      } catch (_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (error) {
      if (!mounted) return;
      showVeilToast(context, 'Could not delete account. Please try again.');
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.handle,
    required this.watched,
    required this.favorites,
    required this.following,
    required this.followers,
    required this.onFollowingTap,
    required this.onFollowersTap,
  });

  final String displayName;
  final String handle;
  final int watched;
  final int favorites;
  final int following;
  final int followers;
  final VoidCallback onFollowingTap;
  final VoidCallback onFollowersTap;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isEmpty
        ? 'V'
        : displayName.substring(0, 1).toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.panel.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: VeilColors.hairlineStrong),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: VeilColors.panelRaised,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        handle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: VeilColors.text3,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: VeilColors.hairline),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Stat(number: '$watched', label: 'Watched'),
                ),
                Expanded(
                  child: _Stat(number: '$favorites', label: 'Favorites'),
                ),
                Expanded(
                  child: _Stat(
                    number: '$following',
                    label: 'Following',
                    onTap: onFollowingTap,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    number: '$followers',
                    label: 'Followers',
                    onTap: onFollowersTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.panel.withValues(alpha: .84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VeilColors.hairlineStrong),
      ),
      child: Column(
        children: [
          for (final entry in children.indexed) ...[
            entry.$2,
            if (entry.$1 != children.length - 1)
              const Divider(height: 1, color: VeilColors.hairline),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? VeilColors.red : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: destructive ? VeilColors.red : VeilColors.text3,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMembersPage extends StatelessWidget {
  const _ProfileMembersPage({
    required this.title,
    required this.users,
    required this.emptyText,
    required this.actionLabel,
  });

  final String title;
  final List<String> users;
  final String emptyText;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final countLabel = users.length == 1
        ? '1 member'
        : '${users.length} members';
    return Scaffold(
      backgroundColor: VeilColors.bg1,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          0,
          VeilLayout.pageTopPadding(context),
          0,
          28,
        ),
        child: AdaptiveContent(
          maxWidth: VeilLayout.readableMaxWidth(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(title: title, subtitle: countLabel),
              const SizedBox(height: 18),
              _MemberList(
                users: users,
                emptyText: emptyText,
                actionLabel: actionLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileActivityPage extends StatelessWidget {
  const _ProfileActivityPage({required this.entries});

  final List<SocialEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeilColors.bg1,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          0,
          VeilLayout.pageTopPadding(context),
          0,
          28,
        ),
        child: AdaptiveContent(
          maxWidth: VeilLayout.readableMaxWidth(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PageHeader(title: 'My Activity'),
              const SizedBox(height: 18),
              _ActivityList(entries: entries),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLegalPage extends StatelessWidget {
  const _ProfileLegalPage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VeilColors.bg1,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          0,
          VeilLayout.pageTopPadding(context),
          0,
          28,
        ),
        child: AdaptiveContent(
          maxWidth: VeilLayout.readableMaxWidth(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(title: title),
              const SizedBox(height: 18),
              Text(
                body,
                style: const TextStyle(
                  color: VeilColors.text2,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left_rounded),
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: VeilColors.panel,
            side: const BorderSide(color: VeilColors.hairline),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: VeilColors.text3,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DeleteAccountReasonSheet extends StatefulWidget {
  const _DeleteAccountReasonSheet();

  @override
  State<_DeleteAccountReasonSheet> createState() =>
      _DeleteAccountReasonSheetState();
}

class _DeleteAccountReasonSheetState extends State<_DeleteAccountReasonSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Delete account',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Tell us why you are leaving.',
              style: TextStyle(color: VeilColors.text3, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('delete-account-reason'),
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Reason',
                hintStyle: const TextStyle(color: VeilColors.text3),
                filled: true,
                fillColor: VeilColors.bg2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: VeilColors.hairline),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final reason = _controller.text.trim();
                  if (reason.isEmpty) return;
                  Navigator.of(context).pop(reason);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: VeilColors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberList extends StatelessWidget {
  const _MemberList({
    required this.users,
    required this.emptyText,
    required this.actionLabel,
  });

  final List<String> users;
  final String emptyText;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return _EmptyPanel(text: emptyText);
    }
    return Column(
      children: [
        for (final userId in users)
          _MemberRow(userId: userId, actionLabel: actionLabel),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.userId, required this.actionLabel});

  final String userId;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => UserProfileRoute(id: userId).push(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VeilColors.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: VeilColors.hairline),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: VeilColors.red.withValues(alpha: .18),
              child: const Icon(Icons.person_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName(userId),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: VeilColors.text3,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              actionLabel,
              style: const TextStyle(
                color: VeilColors.text3,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.entries});

  final List<SocialEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyPanel(text: 'No activity yet');
    }
    return Column(
      children: [
        for (final entry in entries.take(6))
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VeilColors.panel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: VeilColors.hairline),
            ),
            child: Row(
              children: [
                Icon(
                  entry.review.trim().isEmpty
                      ? Icons.visibility_rounded
                      : Icons.rate_review_rounded,
                  color: VeilColors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.review.trim().isEmpty
                        ? 'Watched ${entry.title}'
                        : 'Reviewed ${entry.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VeilColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: Text(
        text,
        style: const TextStyle(color: VeilColors.text3, fontSize: 12),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.number, required this.label, this.onTap});

  final String number;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Text(
              number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: VeilColors.text4, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

String _displayName(String userId) {
  final count = userId.length < 8 ? userId.length : 8;
  return '@${userId.substring(0, count)}';
}
