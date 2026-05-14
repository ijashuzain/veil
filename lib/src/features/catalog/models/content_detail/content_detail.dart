import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:veil/src/shared/models/content_item.dart';

part 'content_detail.freezed.dart';

@freezed
abstract class ContentDetail with _$ContentDetail {
  const ContentDetail._();

  const factory ContentDetail({
    required ContentItem item,
    @Default('') String tagline,
    @Default('') String status,
    @Default('') String studio,
    @Default('') String certification,
    @Default('') String homepage,
    @Default('') String originalLanguage,
    @Default('') String spokenLanguages,
    @Default('') String releaseDate,
    @Default(0) int seasons,
    @Default(0) int episodes,
    @Default([]) List<ContentVideo> videos,
    @Default([]) List<CastMember> cast,
    @Default([]) List<ContentReview> reviews,
    @Default([]) List<ContentItem> recommendations,
    @Default([]) List<ContentItem> similar,
    @Default([]) List<String> watchProviders,
    @Default([]) List<String> backdropUrls,
  }) = _ContentDetail;

  factory ContentDetail.fallback(ContentItem item) {
    return ContentDetail(
      item: item,
      status: 'Available',
      studio: 'TMDB',
      releaseDate: item.year.toString(),
      spokenLanguages: 'English',
    );
  }

  ContentVideo? get primaryTrailer {
    for (final video in videos) {
      if (video.isYouTube && video.type.toLowerCase() == 'trailer') {
        return video;
      }
    }
    return videos.where((video) => video.isYouTube).firstOrNull;
  }
}

@freezed
abstract class ContentVideo with _$ContentVideo {
  const ContentVideo._();

  const factory ContentVideo({
    required String key,
    required String name,
    required String site,
    required String type,
    @Default(false) bool official,
  }) = _ContentVideo;

  bool get isYouTube => site.toLowerCase() == 'youtube' && key.isNotEmpty;

  Uri? get youtubeUrl {
    if (!isYouTube) return null;
    return Uri.https('www.youtube.com', '/watch', {'v': key});
  }

  String get thumbnailUrl => 'https://img.youtube.com/vi/$key/hqdefault.jpg';
}

@freezed
abstract class CastMember with _$CastMember {
  const CastMember._();

  const factory CastMember({
    required String name,
    required String role,
    String? profileUrl,
  }) = _CastMember;
}

@freezed
abstract class ContentReview with _$ContentReview {
  const ContentReview._();

  const factory ContentReview({
    required String author,
    required String content,
    @Default(0) double rating,
  }) = _ContentReview;

  String get title {
    if (rating <= 0) return 'Audience review';
    return '${rating.toStringAsFixed(1)} / 10';
  }
}
