import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/shared/models/content_item.dart';

typedef LetterboxdMovieResolver =
    Future<ContentItem?> Function({
      int? tmdbId,
      String? imdbId,
      String title,
      int year,
    });

class LetterboxdTmdbLinkService {
  const LetterboxdTmdbLinkService({required this.resolveMovie});

  factory LetterboxdTmdbLinkService.fromRepository(TmdbRepository repository) {
    return LetterboxdTmdbLinkService(resolveMovie: repository.resolveMovie);
  }

  final LetterboxdMovieResolver resolveMovie;

  Future<LetterboxdTmdbLinkResult> link(List<SocialEntry> entries) async {
    final linkedEntries = <SocialEntry>[];
    var linkedCount = 0;
    var unresolvedCount = 0;

    for (final entry in entries) {
      if (entry.mediaType != 'movie') {
        linkedEntries.add(entry);
        continue;
      }

      final item = await _safeResolve(entry);
      if (item == null) {
        unresolvedCount++;
        continue;
      }

      linkedCount++;
      linkedEntries.add(_entryFromResolvedItem(entry, item));
    }

    return LetterboxdTmdbLinkResult(
      entries: linkedEntries,
      linkedCount: linkedCount,
      unresolvedCount: unresolvedCount,
    );
  }

  Future<ContentItem?> _safeResolve(SocialEntry entry) async {
    try {
      return await resolveMovie(
        tmdbId: entry.tmdbId,
        imdbId: entry.imdbId,
        title: entry.title,
        year: entry.year,
      );
    } catch (_) {
      return null;
    }
  }

  SocialEntry _entryFromResolvedItem(SocialEntry imported, ContentItem item) {
    return SocialEntry.fromContentItem(
      item,
      userId: imported.userId,
      rating: imported.rating,
      review: imported.review,
      tags: imported.tags,
      watchedOn: imported.watchedOn,
      isFavorite: imported.isFavorite,
      inWatchlist: imported.inWatchlist,
    ).copyWith(
      createdAt: imported.createdAt,
      updatedAt: DateTime.now(),
      imdbId: item.imdbId ?? imported.imdbId,
      liked: imported.liked,
      likeCount: imported.likeCount,
      commentCount: imported.commentCount,
    );
  }
}

class LetterboxdTmdbLinkResult {
  const LetterboxdTmdbLinkResult({
    required this.entries,
    required this.linkedCount,
    required this.unresolvedCount,
  });

  final List<SocialEntry> entries;
  final int linkedCount;
  final int unresolvedCount;
}
