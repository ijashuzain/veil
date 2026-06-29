import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/models/user_profile_summary.dart';
import 'package:veil/src/features/social/models/user_relationship.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/features/social/view_model/social_library_view_model/social_library_view_model.dart';
import 'package:veil/src/features/social/widgets/community_report_sheet.dart';
import 'package:veil/src/shared/components/veil_segmented_tabs.dart';
import 'package:veil/src/shared/components/veil_sheet.dart';
import 'package:veil/src/shared/components/veil_toast.dart';
import 'package:veil/src/shared/layout/adaptive_content.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';

class UserProfileView extends ConsumerStatefulWidget {
  const UserProfileView({super.key, required this.userId, this.displayName});

  final String userId;
  final String? displayName;

  @override
  ConsumerState<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends ConsumerState<UserProfileView> {
  var _entries = <SocialEntry>[];
  var _following = <UserProfileSummary>[];
  var _followers = <UserProfileSummary>[];
  var _loading = true;
  var _isSelf = false;
  UserRelationship? _relationship;
  var _tab = _ProfileTab.followers;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final diary = _entries.where((entry) => entry.watchedOn != null).length;
    final reviews = _entries.where((entry) => entry.review.isNotEmpty).length;
    final favorites = _entries.where((entry) => entry.isFavorite).length;
    final name = widget.displayName ?? _displayName(widget.userId);
    final contentWidth = VeilLayout.readableMaxWidth(context);

    return Scaffold(
      backgroundColor: VeilColors.bg1,
      body: RefreshIndicator(
        color: VeilColors.red,
        backgroundColor: VeilColors.bg2,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AdaptiveContent(
                maxWidth: contentWidth,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 22, 0, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: Colors.white,
                      ),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (!_isSelf)
                        PopupMenuButton<_UserProfileMenuAction>(
                          tooltip: 'More actions',
                          color: VeilColors.panelRaised,
                          icon: const Icon(
                            Icons.more_horiz_rounded,
                            color: VeilColors.text2,
                          ),
                          onSelected: (action) {
                            switch (action) {
                              case _UserProfileMenuAction.report:
                                _reportUser();
                                return;
                              case _UserProfileMenuAction.block:
                                _confirmBlockUser();
                                return;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _UserProfileMenuAction.report,
                              child: Text('Report user'),
                            ),
                            PopupMenuItem(
                              value: _UserProfileMenuAction.block,
                              child: Text('Block user'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AdaptiveContent(
                maxWidth: contentWidth,
                child: _UserProfileHeader(
                  userId: widget.userId,
                  displayName: name,
                  diary: diary,
                  reviews: reviews,
                  favorites: favorites,
                  following: _following.length,
                  followers: _followers.length,
                  isSelf: _isSelf,
                  relationship: _relationship,
                  onRelationshipAction: _handleRelationshipAction,
                  onFollowingTap: () =>
                      setState(() => _tab = _ProfileTab.following),
                  onFollowersTap: () =>
                      setState(() => _tab = _ProfileTab.followers),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AdaptiveContent(
                maxWidth: contentWidth,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: VeilSegmentedTabs<_ProfileTab>(
                    selected: _tab,
                    segments: [
                      for (final tab in _ProfileTab.values)
                        VeilSegment(value: tab, label: tab.label),
                    ],
                    onChanged: (tab) => setState(() => _tab = tab),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            if (_loading)
              SliverToBoxAdapter(
                child: AdaptiveContent(
                  maxWidth: contentWidth,
                  child: const LinearProgressIndicator(
                    color: VeilColors.red,
                    backgroundColor: VeilColors.bg2,
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: AdaptiveContent(
                  maxWidth: contentWidth,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 110),
                    child: _ProfileTabContent(
                      tab: _tab,
                      following: _following,
                      followers: _followers,
                      activity: _entries,
                      onRelationshipChanged: _load,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repository = ref.read(socialRepositoryProvider);
      final tmdbRepository = ref.read(tmdbRepositoryProvider);
      final entries = await _filterHiddenEntries(
        await repository.entriesForUser(widget.userId),
        tmdbRepository,
      );
      final followingIds = await repository.following(widget.userId);
      final followersIds = await repository.followers(widget.userId);
      final following = await repository.userProfilesForIds(followingIds);
      final followers = await repository.userProfilesForIds(followersIds);
      final relationship = await repository.relationshipWith(widget.userId);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _following = following;
        _followers = followers;
        _isSelf = widget.userId == repository.currentUserId;
        _relationship = relationship;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<List<SocialEntry>> _filterHiddenEntries(
    List<SocialEntry> entries,
    TmdbRepository tmdbRepository,
  ) async {
    final filtered = await Future.wait<SocialEntry?>(
      entries.map((entry) async {
        if (await tmdbRepository.shouldHideForCurrentUser(
          entry.toContentItem(),
        )) {
          return null;
        }
        return entry;
      }),
    );
    return filtered.whereType<SocialEntry>().toList();
  }

  Future<void> _handleRelationshipAction() async {
    final repository = ref.read(socialRepositoryProvider);
    final relationship = _relationship;
    switch (relationship?.status) {
      case UserRelationshipStatus.requested:
        await repository.cancelFollowRequest(widget.userId);
        break;
      case UserRelationshipStatus.following:
      case UserRelationshipStatus.friends:
        await repository.unfollowUser(widget.userId);
        break;
      case UserRelationshipStatus.incomingRequest:
        final requestId = relationship?.incomingRequest?.id;
        if (requestId != null && requestId.isNotEmpty) {
          await repository.acceptFollowRequest(requestId);
        }
        break;
      case UserRelationshipStatus.none:
      case UserRelationshipStatus.followsMe:
      case null:
        await repository.followUser(
          widget.userId,
          recipientDisplayName:
              widget.displayName ?? _displayName(widget.userId),
        );
        break;
      case UserRelationshipStatus.self:
      case UserRelationshipStatus.blocked:
        return;
    }
    await _load();
  }

  void _reportUser() {
    showVeilBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CommunityReportSheet(
        title: 'Report user',
        subjectLabel: 'this member',
        onSubmit: (reason, details) async {
          await ref
              .read(socialLibraryViewModelProvider.notifier)
              .reportUser(widget.userId, reason: reason, details: details);
          if (!mounted) return;
          showVeilToast(
            context,
            'Report submitted. We will review it shortly.',
          );
        },
      ),
    );
  }

  Future<void> _confirmBlockUser() async {
    final name = widget.displayName ?? _displayName(widget.userId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: VeilColors.panel,
          title: const Text('Block user?'),
          content: Text(
            'You will stop seeing posts, comments, and profile activity from $name.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: VeilColors.red),
              child: const Text('Block user'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    await ref
        .read(socialLibraryViewModelProvider.notifier)
        .blockUser(widget.userId, displayName: name);
    if (!mounted) return;
    showVeilToast(context, '$name has been blocked.');
    Navigator.of(context).maybePop();
  }
}

enum _UserProfileMenuAction { report, block }

enum _ProfileTab {
  following('Following'),
  followers('Followers'),
  activity('Activity');

  const _ProfileTab(this.label);

  final String label;
}

class _UserProfileHeader extends StatelessWidget {
  const _UserProfileHeader({
    required this.userId,
    required this.displayName,
    required this.diary,
    required this.reviews,
    required this.favorites,
    required this.following,
    required this.followers,
    required this.isSelf,
    required this.relationship,
    required this.onRelationshipAction,
    required this.onFollowingTap,
    required this.onFollowersTap,
  });

  final String userId;
  final String displayName;
  final int diary;
  final int reviews;
  final int favorites;
  final int following;
  final int followers;
  final bool isSelf;
  final UserRelationship? relationship;
  final VoidCallback? onRelationshipAction;
  final VoidCallback onFollowingTap;
  final VoidCallback onFollowersTap;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isEmpty
        ? 'V'
        : displayName.substring(0, 1).toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VeilColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: VeilColors.red.withValues(alpha: .18),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 4),
                      Text(
                        _displayName(userId),
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
                if (!isSelf) ...[
                  const SizedBox(width: 10),
                  Builder(
                    builder: (context) {
                      final status = relationship?.status;
                      final label = _relationshipActionLabel(status);
                      final isPassive =
                          status == UserRelationshipStatus.blocked;
                      final isMuted =
                          status == UserRelationshipStatus.requested ||
                          status == UserRelationshipStatus.following ||
                          status == UserRelationshipStatus.friends ||
                          isPassive;
                      return OutlinedButton(
                        onPressed: isPassive ? null : onRelationshipAction,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isMuted
                              ? VeilColors.text2
                              : Colors.white,
                          disabledForegroundColor: VeilColors.text3,
                          side: BorderSide(
                            color: isMuted
                                ? VeilColors.hairlineStrong
                                : VeilColors.red,
                          ),
                          backgroundColor: isMuted
                              ? Colors.transparent
                              : VeilColors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 9,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: VeilColors.hairline),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Stat(number: '$diary', label: 'Watched'),
                ),
                Expanded(
                  child: _Stat(number: '$reviews', label: 'Reviews'),
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

class _ProfileTabContent extends StatelessWidget {
  const _ProfileTabContent({
    required this.tab,
    required this.following,
    required this.followers,
    required this.activity,
    required this.onRelationshipChanged,
  });

  final _ProfileTab tab;
  final List<UserProfileSummary> following;
  final List<UserProfileSummary> followers;
  final List<SocialEntry> activity;
  final Future<void> Function() onRelationshipChanged;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      _ProfileTab.following => _MemberList(
        users: following,
        emptyText: 'Not following anyone yet',
        onRelationshipChanged: onRelationshipChanged,
      ),
      _ProfileTab.followers => _MemberList(
        users: followers,
        emptyText: 'No followers yet',
        onRelationshipChanged: onRelationshipChanged,
      ),
      _ProfileTab.activity => _ActivityList(entries: activity),
    };
  }
}

class _MemberList extends StatelessWidget {
  const _MemberList({
    required this.users,
    required this.emptyText,
    required this.onRelationshipChanged,
  });

  final List<UserProfileSummary> users;
  final String emptyText;
  final Future<void> Function() onRelationshipChanged;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return _EmptyPanel(text: emptyText);
    return Column(
      children: [
        for (final user in users)
          _MemberRow(
            key: ValueKey(user.userId),
            user: user,
            onRelationshipChanged: onRelationshipChanged,
          ),
      ],
    );
  }
}

class _MemberRow extends ConsumerStatefulWidget {
  const _MemberRow({
    super.key,
    required this.user,
    required this.onRelationshipChanged,
  });

  final UserProfileSummary user;
  final Future<void> Function() onRelationshipChanged;

  @override
  ConsumerState<_MemberRow> createState() => _MemberRowState();
}

class _MemberRowState extends ConsumerState<_MemberRow> {
  UserRelationship? _relationship;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadRelationship);
  }

  @override
  void didUpdateWidget(covariant _MemberRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.userId != widget.user.userId) {
      _relationship = null;
      Future.microtask(_loadRelationship);
    }
  }

  Future<void> _loadRelationship() async {
    final relationship = await ref
        .read(socialRepositoryProvider)
        .relationshipWith(widget.user.userId);
    if (!mounted) return;
    setState(() => _relationship = relationship);
  }

  Future<void> _runAction() async {
    final relationship = _relationship;
    if (relationship == null || _loading) return;
    setState(() => _loading = true);
    final repository = ref.read(socialRepositoryProvider);
    switch (relationship.status) {
      case UserRelationshipStatus.requested:
        await repository.cancelFollowRequest(widget.user.userId);
        break;
      case UserRelationshipStatus.following:
      case UserRelationshipStatus.friends:
        await repository.unfollowUser(widget.user.userId);
        break;
      case UserRelationshipStatus.incomingRequest:
        final requestId = relationship.incomingRequest?.id;
        if (requestId != null && requestId.isNotEmpty) {
          await repository.acceptFollowRequest(requestId);
        }
        break;
      case UserRelationshipStatus.none:
      case UserRelationshipStatus.followsMe:
        await repository.followUser(
          widget.user.userId,
          recipientDisplayName: widget.user.displayName,
        );
        break;
      case UserRelationshipStatus.self:
      case UserRelationshipStatus.blocked:
        break;
    }
    await _loadRelationship();
    await widget.onRelationshipChanged();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final relationship = _relationship;
    final label = _relationshipActionLabel(relationship?.status);
    final showAction =
        relationship != null &&
        relationship.status != UserRelationshipStatus.self &&
        relationship.status != UserRelationshipStatus.blocked;
    return InkWell(
      onTap: () => UserProfileRoute(
        id: widget.user.userId,
        displayName: widget.user.displayName,
      ).push(context),
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
                    widget.user.displayName.trim().isEmpty
                        ? _displayName(widget.user.userId)
                        : widget.user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _displayName(widget.user.userId),
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
            if (showAction)
              TextButton(
                onPressed: _loading ? null : _runAction,
                child: Text(label),
              ),
          ],
        ),
      ),
    );
  }
}

String _relationshipActionLabel(UserRelationshipStatus? status) {
  return switch (status) {
    UserRelationshipStatus.requested => 'Requested',
    UserRelationshipStatus.followsMe => 'Follow Back',
    UserRelationshipStatus.following => 'Following',
    UserRelationshipStatus.friends => 'Friends',
    UserRelationshipStatus.incomingRequest => 'Accept',
    UserRelationshipStatus.blocked => 'Blocked',
    UserRelationshipStatus.self => 'You',
    UserRelationshipStatus.none || null => 'Follow',
  };
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.entries});

  final List<SocialEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const _EmptyPanel(text: 'No activity yet');
    return Column(
      children: [
        for (final entry in entries.take(8))
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
