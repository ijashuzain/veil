import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/social/models/follow_request.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/shared/components/veil_segmented_tabs.dart';
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
  var _following = <String>[];
  var _followers = <String>[];
  var _loading = true;
  var _isFollowing = false;
  var _isSelf = false;
  FollowRequestStatus? _followRequestStatus;
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
                  isFollowing: _isFollowing,
                  followRequestStatus: _followRequestStatus,
                  onFollowToggle: _toggleFollow,
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
                      isFollowingViewer: _isFollowing,
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
      final entries = await repository.entriesForUser(widget.userId);
      final following = await repository.following(widget.userId);
      final followers = await repository.followers(widget.userId);
      final isFollowing = await repository.isFollowing(widget.userId);
      final followRequestStatus = await repository.followRequestStatus(
        widget.userId,
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _following = following;
        _followers = followers;
        _isFollowing = isFollowing;
        _followRequestStatus = followRequestStatus;
        _isSelf = widget.userId == repository.currentUserId;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final repository = ref.read(socialRepositoryProvider);
    if (_isFollowing) {
      await repository.unfollowUser(widget.userId);
    } else {
      if (_followRequestStatus == FollowRequestStatus.pending) return;
      await repository.followUser(
        widget.userId,
        recipientDisplayName: widget.displayName ?? _displayName(widget.userId),
      );
    }
    await _load();
  }
}

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
    required this.isFollowing,
    required this.followRequestStatus,
    required this.onFollowToggle,
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
  final bool isFollowing;
  final FollowRequestStatus? followRequestStatus;
  final VoidCallback? onFollowToggle;
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
                      final isPending =
                          followRequestStatus == FollowRequestStatus.pending;
                      final label = isFollowing
                          ? 'Unfollow'
                          : isPending
                          ? 'Requested'
                          : 'Follow';
                      return OutlinedButton(
                        onPressed: isPending ? null : onFollowToggle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isFollowing || isPending
                              ? VeilColors.text2
                              : Colors.white,
                          disabledForegroundColor: VeilColors.text3,
                          side: BorderSide(
                            color: isFollowing || isPending
                                ? VeilColors.hairlineStrong
                                : VeilColors.red,
                          ),
                          backgroundColor: isFollowing || isPending
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
    required this.isFollowingViewer,
  });

  final _ProfileTab tab;
  final List<String> following;
  final List<String> followers;
  final List<SocialEntry> activity;
  final bool isFollowingViewer;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      _ProfileTab.following => _MemberList(
        users: following,
        emptyText: 'Not following anyone yet',
        actionLabel: 'Following',
      ),
      _ProfileTab.followers => _MemberList(
        users: followers,
        emptyText: 'No followers yet',
        actionLabel: isFollowingViewer ? 'Follows you' : 'Follow back',
      ),
      _ProfileTab.activity => _ActivityList(entries: activity),
    };
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
    if (users.isEmpty) return _EmptyPanel(text: emptyText);
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
