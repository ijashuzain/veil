import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veil/app/services/local_storage_services/local_storage_services.dart';
import 'package:veil/src/features/social/models/follow_request.dart';
import 'package:veil/src/features/social/models/user_profile_summary.dart';
import 'package:veil/src/features/social/models/user_relationship.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/shared/models/content_item.dart';

void main() {
  const item = ContentItem(
    id: 'movie-505642',
    remoteId: 505642,
    mediaType: 'movie',
    title: 'Black Panther: Wakanda Forever',
    subtitle: 'Movie',
    year: 2022,
    genre: 'Action / Adventure',
    type: 'Movie',
    rating: 7.1,
    palette: [Colors.black, Colors.red],
    glyph: Icons.movie_rounded,
    description: 'Wakanda fights to protect itself.',
    imdbId: 'tt9114286',
    posterUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
    backdropUrl: 'https://image.tmdb.org/t/p/w780/backdrop.jpg',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  test('logs watched films with rating, review, and tags', () async {
    final repository = SocialRepository();

    final entry = await repository.logWatched(
      item,
      rating: 4.5,
      review: 'A moving sequel with scale.',
      tags: const ['marvel', 'rewatch'],
    );

    expect(entry.tmdbId, 505642);
    expect(entry.imdbId, 'tt9114286');
    expect(entry.rating, 4.5);
    expect(entry.review, 'A moving sequel with scale.');
    expect(entry.tags, ['marvel', 'rewatch']);
    expect((await repository.diary()).single.id, entry.id);
    expect(
      (await repository.diary()).single.toContentItem().imdbId,
      'tt9114286',
    );
    expect((await repository.reviews()).single.review, entry.review);
  });

  test('toggles watchlist and favorite using TMDB item snapshots', () async {
    final repository = SocialRepository();

    final watchlistEntry = await repository.toggleWatchlist(item);
    final favoriteEntry = await repository.toggleFavorite(item);

    expect(watchlistEntry.inWatchlist, isTrue);
    expect(favoriteEntry.isFavorite, isTrue);
    expect((await repository.watchlist()).single.title, item.title);
    expect((await repository.favorites()).single.title, item.title);
  });

  test('updates an existing film entry instead of duplicating it', () async {
    final repository = SocialRepository();

    await repository.logWatched(item, rating: 3);
    await repository.logWatched(item, rating: 5, review: 'Even better later.');

    final entries = await repository.entries();
    expect(entries, hasLength(1));
    expect(entries.single.rating, 5);
    expect(entries.single.review, 'Even better later.');
  });

  test('rating a film uses half to five stars and marks it watched', () async {
    final repository = SocialRepository();

    final low = await repository.rate(item, rating: -1);
    final high = await repository.rate(item, rating: 9);

    expect(low.rating, .5);
    expect(high.rating, 5);
    expect((await repository.diary()).single.watchedOn, isNotNull);
  });

  test('rating a film supports half-star steps', () async {
    final repository = SocialRepository();

    final half = await repository.rate(item, rating: .5);
    final roundedHalf = await repository.rate(item, rating: 4.2);

    expect(half.rating, .5);
    expect(roundedHalf.rating, 4);
  });

  test('removing watched clears the saved rating', () async {
    final repository = SocialRepository();

    await repository.rate(item, rating: 4);
    final entry = await repository.setWatched(item, watched: false);

    expect(entry.watchedOn, isNull);
    expect(entry.rating, 0);
    expect(await repository.diary(), isEmpty);
  });

  test('removing watched updates legacy imported title-only entries', () async {
    final repository = SocialRepository();
    final legacyImported = SocialEntry(
      id: 'movie_black_panther_wakanda_forever_2022',
      userId: 'letterboxd-import',
      mediaType: 'movie',
      title: item.title,
      year: item.year,
      type: 'Movie',
      rating: 4,
      watchedOn: DateTime(2024, 2, 1),
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    await repository.importSocialEntries([legacyImported]);
    final legacyEntry = (await repository.diary()).single;
    final updated = await repository.setWatched(
      legacyEntry.toContentItem(),
      watched: false,
    );

    expect(updated.id, legacyEntry.id);
    expect(updated.watchedOn, isNull);
    expect(updated.rating, 0);
    expect(await repository.diary(), isEmpty);
    expect(await repository.entries(), hasLength(1));
  });

  test(
    'rating a watchlisted film marks watched and removes watchlist',
    () async {
      final repository = SocialRepository();

      await repository.setWatchlist(item, inWatchlist: true);
      final entry = await repository.rate(item, rating: 4);

      expect(entry.watchedOn, isNotNull);
      expect(entry.inWatchlist, isFalse);
      expect(entry.rating, 4);
      expect(await repository.watchlist(), isEmpty);
    },
  );

  test('adding to watchlist clears watched date and rating', () async {
    final repository = SocialRepository();

    await repository.rate(item, rating: 4);
    final entry = await repository.setWatchlist(item, inWatchlist: true);

    expect(entry.inWatchlist, isTrue);
    expect(entry.watchedOn, isNull);
    expect(entry.rating, 0);
    expect(await repository.diary(), isEmpty);
  });

  test('rate review stores watch kind and custom tags', () async {
    final repository = SocialRepository();

    final entry = await repository.rateReview(
      item,
      rating: 4.5,
      review: 'Sharp and heartfelt.',
      tags: const ['first-time', 'mind-bending'],
    );

    expect(entry.rating, 4.5);
    expect(entry.review, 'Sharp and heartfelt.');
    expect(entry.tags, ['first-time', 'mind-bending']);
    expect(entry.watchedOn, isNotNull);
  });

  test('rate review replaces watch kind and preserves custom tags', () async {
    final repository = SocialRepository();

    await repository.rateReview(
      item,
      rating: 4,
      review: 'First pass.',
      tags: const ['first-time', 'mind-bending'],
    );
    final updated = await repository.rateReview(
      item,
      rating: 5,
      review: 'Better on rewatch.',
      tags: const ['rewatch'],
    );

    expect(updated.rating, 5);
    expect(updated.review, 'Better on rewatch.');
    expect(updated.tags, ['rewatch', 'mind-bending']);
  });

  test('searches local user profiles by display name', () async {
    final repository = SocialRepository();

    await repository.cacheUserProfile(
      const UserProfileSummary(userId: 'member-2', displayName: 'Mira Kapoor'),
    );

    final results = await repository.searchUserProfiles('mira');

    expect(results, hasLength(1));
    expect(results.single.userId, 'member-2');
    expect(results.single.displayName, 'Mira Kapoor');
  });

  test(
    'blocking a user hides their reviews comments and profile search locally',
    () async {
      final viewer = SocialRepository(localUserId: 'viewer');
      final blockedMember = SocialRepository(localUserId: 'member-2');

      await viewer.cacheUserProfile(
        const UserProfileSummary(
          userId: 'member-2',
          displayName: 'Mira Kapoor',
        ),
      );
      final blockedReview = await blockedMember.rateReview(
        item,
        rating: 4,
        review: 'Not for me.',
        tags: const ['first-time'],
      );
      await blockedMember.addReviewComment(blockedReview, 'Comment body');

      expect(await viewer.searchUserProfiles('mira'), hasLength(1));
      expect(await viewer.globalReviews(), hasLength(1));
      expect(await viewer.reviewComments(blockedReview), hasLength(1));

      await viewer.blockUser('member-2', displayName: 'Mira Kapoor');

      expect(await viewer.blockedUserIds(), contains('member-2'));
      expect(await viewer.searchUserProfiles('mira'), isEmpty);
      expect(await viewer.globalReviews(), isEmpty);
      expect(await viewer.reviewComments(blockedReview), isEmpty);
    },
  );

  test(
    'follow requests wait for acceptance and notify both participants',
    () async {
      final bob = SocialRepository(localUserId: 'bob');
      final alice = SocialRepository(localUserId: 'alice');

      await bob.followUser(
        'alice',
        requesterDisplayName: 'Bob',
        recipientDisplayName: 'Alice',
      );

      expect(await bob.isFollowing('alice'), isFalse);
      expect(
        (await bob.relationshipWith('alice')).status,
        UserRelationshipStatus.requested,
      );
      expect(await alice.followRequestsForAlerts(), hasLength(1));

      final incoming = (await alice.followRequestsForAlerts()).single;
      expect(incoming.status, FollowRequestStatus.pending);
      expect(incoming.requesterId, 'bob');
      expect(incoming.requesterDisplayName, 'Bob');

      await alice.acceptFollowRequest(incoming.id);

      expect(await bob.isFollowing('alice'), isTrue);
      expect(await bob.following('bob'), ['alice']);
      expect(await alice.followers('alice'), ['bob']);
      expect(
        (await bob.relationshipWith('alice')).status,
        UserRelationshipStatus.following,
      );
      expect(
        (await alice.relationshipWith('bob')).status,
        UserRelationshipStatus.followsMe,
      );

      final accepted = (await bob.followRequestsForAlerts()).single;
      expect(accepted.status, FollowRequestStatus.accepted);
      expect(accepted.recipientDisplayName, 'Alice');

      await bob.markFollowRequestNoticeRead(accepted.id);

      expect(await bob.followRequestsForAlerts(), isEmpty);

      await alice.followUser(
        'bob',
        requesterDisplayName: 'Alice',
        recipientDisplayName: 'Bob',
      );

      expect(await alice.isFollowing('bob'), isTrue);
      expect(await bob.friends('bob'), ['alice']);
      expect(
        (await bob.relationshipWith('alice')).status,
        UserRelationshipStatus.friends,
      );

      await bob.unfollowUser('alice');

      expect(await bob.isFollowing('alice'), isFalse);
      expect(await bob.following('bob'), isEmpty);
      expect(await alice.followers('alice'), isEmpty);
      expect(await bob.followers('bob'), ['alice']);
      expect(
        (await bob.relationshipWith('alice')).status,
        UserRelationshipStatus.followsMe,
      );
    },
  );

  test('cancels declines and blocks follow requests locally', () async {
    final charlie = SocialRepository(localUserId: 'charlie');
    final dora = SocialRepository(localUserId: 'dora');

    await charlie.followUser('dora');

    expect(
      (await charlie.relationshipWith('dora')).status,
      UserRelationshipStatus.requested,
    );
    expect(await dora.followRequestsForAlerts(), hasLength(1));

    await charlie.cancelFollowRequest('dora');

    expect(await dora.followRequestsForAlerts(), isEmpty);
    expect(
      (await charlie.relationshipWith('dora')).status,
      UserRelationshipStatus.none,
    );

    await charlie.followUser('dora');
    final request = (await dora.followRequestsForAlerts()).single;

    await dora.declineFollowRequest(request.id);

    expect(await charlie.isFollowing('dora'), isFalse);
    expect(await dora.followRequestsForAlerts(), isEmpty);
    expect(
      (await charlie.relationshipWith('dora')).status,
      UserRelationshipStatus.none,
    );

    await dora.blockUser('charlie');
    await charlie.followUser('dora');

    expect(await dora.followRequestsForAlerts(), isEmpty);
  });

  test('suggests movies to friends and marks suggestions read', () async {
    final alice = SocialRepository(localUserId: 'alice');
    final bob = SocialRepository(localUserId: 'bob');
    final charlie = SocialRepository(localUserId: 'charlie');

    await bob.followUser(
      'alice',
      requesterDisplayName: 'Bob',
      recipientDisplayName: 'Alice',
    );
    await alice.acceptFollowRequest(
      (await alice.followRequestsForAlerts()).single.id,
    );
    await alice.followUser(
      'bob',
      requesterDisplayName: 'Alice',
      recipientDisplayName: 'Bob',
    );

    await alice.suggestMovie(
      item,
      recipientIds: const ['bob', 'charlie'],
      senderDisplayName: 'Alice',
    );

    final suggestions = await bob.movieSuggestions();

    expect(suggestions, hasLength(1));
    expect(suggestions.single.senderId, 'alice');
    expect(suggestions.single.senderDisplayName, 'Alice');
    expect(suggestions.single.content.title, item.title);
    expect(suggestions.single.isUnread, isTrue);

    await bob.markMovieSuggestionRead(suggestions.single.id);

    expect((await bob.movieSuggestions()).single.isUnread, isFalse);
    expect(await charlie.movieSuggestions(), isEmpty);
  });

  test('local review like comment and delete update review state', () async {
    final repository = SocialRepository();

    final review = await repository.rateReview(
      item,
      rating: 4,
      review: 'Loved this.',
      tags: const ['first-time'],
    );

    final liked = await repository.toggleReviewLike(review);
    expect(liked.liked, isTrue);
    expect(liked.likeCount, 1);

    final helpful = await repository.toggleReviewHelpful(liked);
    expect(helpful.helpful, isTrue);
    expect(helpful.helpfulCount, 1);

    final commented = await repository.addReviewComment(
      helpful,
      'Same here',
      isSpoiler: true,
    );
    expect(commented.commentCount, 1);

    final comments = await repository.reviewComments(commented);
    expect(comments, hasLength(1));
    expect(comments.single.body, 'Same here');
    expect(comments.single.isSpoiler, isTrue);

    final replied = await repository.addReviewComment(
      commented,
      'Replying to this',
      parentCommentId: comments.single.id,
    );
    expect(replied.commentCount, 2);

    final thread = await repository.reviewComments(replied);
    expect(thread, hasLength(2));
    expect(thread.last.parentCommentId, comments.single.id);

    final deleted = await repository.deleteReview(replied);
    expect(deleted.review, isEmpty);
    expect(deleted.rating, 4);
    expect(deleted.watchedOn, isNotNull);
    expect(await repository.reviews(), isEmpty);
  });

  test(
    'local account deletion keeps reviews but removes private library and follows',
    () async {
      final repository = SocialRepository();

      final review = await repository.rateReview(
        item,
        rating: 4,
        review: 'Keep this public review.',
        tags: const ['first-time'],
      );
      await repository.toggleWatchlist(
        item.copyWith(
          id: 'movie-watchlist',
          remoteId: 22,
          imdbId: 'tt0000022',
          title: 'Saved',
        ),
      );
      await repository.toggleFavorite(
        item.copyWith(
          id: 'movie-favorite',
          remoteId: 23,
          imdbId: 'tt0000023',
          title: 'Favorite',
        ),
      );
      await repository.followUser('member-2');
      await LocalStorage.setString(
        'veil_user_follows_v1',
        jsonEncode([
          {'follower_id': 'local-user', 'following_id': 'member-2'},
          {'follower_id': 'member-3', 'following_id': 'local-user'},
          {'follower_id': 'member-4', 'following_id': 'member-5'},
        ]),
      );

      await repository.deleteCurrentAccount(reason: 'Leaving for now');

      final entries = await repository.entries();
      expect(entries, hasLength(1));
      expect(entries.single.id, review.id);
      expect(entries.single.review, 'Keep this public review.');
      expect(entries.single.authorDisplayName, 'Deleted user');
      expect(entries.single.rating, 4);
      expect(entries.single.watchedOn, isNull);
      expect(entries.single.inWatchlist, isFalse);
      expect(entries.single.isFavorite, isFalse);
      expect(await repository.diary(), isEmpty);
      expect(await repository.watchlist(), isEmpty);
      expect(await repository.favorites(), isEmpty);
      expect(await repository.following('local-user'), isEmpty);
      expect(await repository.followers('local-user'), isEmpty);
      expect(await repository.following('member-4'), ['member-5']);
    },
  );

  test(
    'imports Letterboxd diary rows by TMDB id without duplicating',
    () async {
      final repository = SocialRepository();

      await repository.setWatchlist(item, inWatchlist: true);
      final imported = _importedEntry(
        rating: 4.5,
        review: 'A moving sequel with scale.',
        tags: const ['rewatch', 'marvel'],
        watchedOn: DateTime(2024, 2, 1),
      );

      final result = await repository.importSocialEntries([imported]);
      final entries = await repository.entries();

      expect(result.added, 0);
      expect(result.updated, 1);
      expect(entries, hasLength(1));
      expect(entries.single.tmdbId, 505642);
      expect(entries.single.rating, 4.5);
      expect(entries.single.review, 'A moving sequel with scale.');
      expect(entries.single.tags, ['rewatch', 'marvel']);
      expect(entries.single.watchedOn, DateTime(2024, 2, 1));
      expect(entries.single.inWatchlist, isFalse);
    },
  );

  test('imports Letterboxd watchlist rows as watchlist-only state', () async {
    final repository = SocialRepository();

    await repository.rate(item, rating: 4);
    final imported = _importedEntry(inWatchlist: true);

    final result = await repository.importSocialEntries([imported]);
    final entry = (await repository.entries()).single;

    expect(result.added, 0);
    expect(result.updated, 1);
    expect(entry.inWatchlist, isTrue);
    expect(entry.rating, 0);
    expect(entry.review, isEmpty);
    expect(entry.watchedOn, isNull);
    expect(await repository.diary(), isEmpty);
  });
}

SocialEntry _importedEntry({
  double rating = 0,
  String review = '',
  List<String> tags = const [],
  DateTime? watchedOn,
  bool inWatchlist = false,
}) {
  return SocialEntry(
    id: 'movie_505642',
    userId: 'letterboxd-import',
    tmdbId: 505642,
    imdbId: 'tt9114286',
    mediaType: 'movie',
    title: 'Black Panther: Wakanda Forever',
    subtitle: 'Movie',
    year: 2022,
    genre: 'Action / Adventure',
    type: 'Movie',
    tmdbRating: 7.1,
    posterUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
    backdropUrl: 'https://image.tmdb.org/t/p/w780/backdrop.jpg',
    description: 'Wakanda fights to protect itself.',
    rating: rating,
    review: review,
    tags: tags,
    watchedOn: watchedOn,
    inWatchlist: inWatchlist,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}
