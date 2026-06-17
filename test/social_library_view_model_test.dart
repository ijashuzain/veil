import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/app/services/api_services/api_service.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/features/social/view_model/social_library_view_model/social_library_view_model.dart';
import 'package:veil/src/shared/models/content_item.dart';

void main() {
  test(
    'social library hides Disney and Pixar entries for tester account',
    () async {
      final container = ProviderContainer(
        overrides: [
          socialRepositoryProvider.overrideWithValue(
            _FakeSocialRepository(
              entriesResult: [
                _entry(id: 'movie_100', tmdbId: 100, title: 'Frozen'),
                _entry(
                  id: 'tv_94605',
                  tmdbId: 94605,
                  title: 'Arcane',
                  mediaType: 'tv',
                  type: 'TV Show',
                ),
              ],
              globalReviewsResult: [
                _entry(id: 'movie_862', tmdbId: 862, title: 'Toy Story'),
                _entry(id: 'movie_603', tmdbId: 603, title: 'The Matrix'),
              ],
            ),
          ),
          tmdbRepositoryProvider.overrideWithValue(
            _HiddenIdTmdbRepository(hiddenIds: {'movie:100', 'movie:862'}),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(socialLibraryViewModelProvider.notifier).load();

      final state = container.read(socialLibraryViewModelProvider);
      expect(state.entries.map((entry) => entry.title), ['Arcane']);
      expect(state.globalReviews.map((entry) => entry.title), ['The Matrix']);
    },
  );
}

SocialEntry _entry({
  required String id,
  required int tmdbId,
  required String title,
  String mediaType = 'movie',
  String type = 'Movie',
}) {
  final now = DateTime(2026);
  return SocialEntry(
    id: id,
    userId: 'user-1',
    tmdbId: tmdbId,
    mediaType: mediaType,
    title: title,
    subtitle: mediaType == 'tv' ? 'Series' : 'Movie',
    year: 2026,
    genre: 'Drama',
    type: type,
    tmdbRating: 8,
    description: '$title description',
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeSocialRepository extends SocialRepository {
  _FakeSocialRepository({
    required this.entriesResult,
    required this.globalReviewsResult,
  }) : super();

  final List<SocialEntry> entriesResult;
  final List<SocialEntry> globalReviewsResult;

  @override
  Future<List<SocialEntry>> entries() async => entriesResult;

  @override
  Future<List<SocialEntry>> globalReviews() async => globalReviewsResult;
}

class _HiddenIdTmdbRepository extends TmdbRepository {
  _HiddenIdTmdbRepository({required this.hiddenIds}) : super(api: Api());

  final Set<String> hiddenIds;

  @override
  Future<bool> shouldHideForCurrentUser(ContentItem item) async {
    final mediaType = item.mediaType == 'tv' ? 'tv' : 'movie';
    return hiddenIds.contains('$mediaType:${item.remoteId}');
  }
}
