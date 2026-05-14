// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ContentDetail {

 ContentItem get item; String get tagline; String get status; String get studio; String get certification; String get homepage; String get originalLanguage; String get spokenLanguages; String get releaseDate; int get seasons; int get episodes; List<ContentVideo> get videos; List<CastMember> get cast; List<ContentReview> get reviews; List<ContentItem> get recommendations; List<ContentItem> get similar; List<String> get watchProviders; List<String> get backdropUrls;
/// Create a copy of ContentDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentDetailCopyWith<ContentDetail> get copyWith => _$ContentDetailCopyWithImpl<ContentDetail>(this as ContentDetail, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentDetail&&(identical(other.item, item) || other.item == item)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.status, status) || other.status == status)&&(identical(other.studio, studio) || other.studio == studio)&&(identical(other.certification, certification) || other.certification == certification)&&(identical(other.homepage, homepage) || other.homepage == homepage)&&(identical(other.originalLanguage, originalLanguage) || other.originalLanguage == originalLanguage)&&(identical(other.spokenLanguages, spokenLanguages) || other.spokenLanguages == spokenLanguages)&&(identical(other.releaseDate, releaseDate) || other.releaseDate == releaseDate)&&(identical(other.seasons, seasons) || other.seasons == seasons)&&(identical(other.episodes, episodes) || other.episodes == episodes)&&const DeepCollectionEquality().equals(other.videos, videos)&&const DeepCollectionEquality().equals(other.cast, cast)&&const DeepCollectionEquality().equals(other.reviews, reviews)&&const DeepCollectionEquality().equals(other.recommendations, recommendations)&&const DeepCollectionEquality().equals(other.similar, similar)&&const DeepCollectionEquality().equals(other.watchProviders, watchProviders)&&const DeepCollectionEquality().equals(other.backdropUrls, backdropUrls));
}


@override
int get hashCode => Object.hash(runtimeType,item,tagline,status,studio,certification,homepage,originalLanguage,spokenLanguages,releaseDate,seasons,episodes,const DeepCollectionEquality().hash(videos),const DeepCollectionEquality().hash(cast),const DeepCollectionEquality().hash(reviews),const DeepCollectionEquality().hash(recommendations),const DeepCollectionEquality().hash(similar),const DeepCollectionEquality().hash(watchProviders),const DeepCollectionEquality().hash(backdropUrls));

@override
String toString() {
  return 'ContentDetail(item: $item, tagline: $tagline, status: $status, studio: $studio, certification: $certification, homepage: $homepage, originalLanguage: $originalLanguage, spokenLanguages: $spokenLanguages, releaseDate: $releaseDate, seasons: $seasons, episodes: $episodes, videos: $videos, cast: $cast, reviews: $reviews, recommendations: $recommendations, similar: $similar, watchProviders: $watchProviders, backdropUrls: $backdropUrls)';
}


}

/// @nodoc
abstract mixin class $ContentDetailCopyWith<$Res>  {
  factory $ContentDetailCopyWith(ContentDetail value, $Res Function(ContentDetail) _then) = _$ContentDetailCopyWithImpl;
@useResult
$Res call({
 ContentItem item, String tagline, String status, String studio, String certification, String homepage, String originalLanguage, String spokenLanguages, String releaseDate, int seasons, int episodes, List<ContentVideo> videos, List<CastMember> cast, List<ContentReview> reviews, List<ContentItem> recommendations, List<ContentItem> similar, List<String> watchProviders, List<String> backdropUrls
});




}
/// @nodoc
class _$ContentDetailCopyWithImpl<$Res>
    implements $ContentDetailCopyWith<$Res> {
  _$ContentDetailCopyWithImpl(this._self, this._then);

  final ContentDetail _self;
  final $Res Function(ContentDetail) _then;

/// Create a copy of ContentDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? item = null,Object? tagline = null,Object? status = null,Object? studio = null,Object? certification = null,Object? homepage = null,Object? originalLanguage = null,Object? spokenLanguages = null,Object? releaseDate = null,Object? seasons = null,Object? episodes = null,Object? videos = null,Object? cast = null,Object? reviews = null,Object? recommendations = null,Object? similar = null,Object? watchProviders = null,Object? backdropUrls = null,}) {
  return _then(_self.copyWith(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as ContentItem,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,studio: null == studio ? _self.studio : studio // ignore: cast_nullable_to_non_nullable
as String,certification: null == certification ? _self.certification : certification // ignore: cast_nullable_to_non_nullable
as String,homepage: null == homepage ? _self.homepage : homepage // ignore: cast_nullable_to_non_nullable
as String,originalLanguage: null == originalLanguage ? _self.originalLanguage : originalLanguage // ignore: cast_nullable_to_non_nullable
as String,spokenLanguages: null == spokenLanguages ? _self.spokenLanguages : spokenLanguages // ignore: cast_nullable_to_non_nullable
as String,releaseDate: null == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String,seasons: null == seasons ? _self.seasons : seasons // ignore: cast_nullable_to_non_nullable
as int,episodes: null == episodes ? _self.episodes : episodes // ignore: cast_nullable_to_non_nullable
as int,videos: null == videos ? _self.videos : videos // ignore: cast_nullable_to_non_nullable
as List<ContentVideo>,cast: null == cast ? _self.cast : cast // ignore: cast_nullable_to_non_nullable
as List<CastMember>,reviews: null == reviews ? _self.reviews : reviews // ignore: cast_nullable_to_non_nullable
as List<ContentReview>,recommendations: null == recommendations ? _self.recommendations : recommendations // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,similar: null == similar ? _self.similar : similar // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,watchProviders: null == watchProviders ? _self.watchProviders : watchProviders // ignore: cast_nullable_to_non_nullable
as List<String>,backdropUrls: null == backdropUrls ? _self.backdropUrls : backdropUrls // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ContentDetail].
extension ContentDetailPatterns on ContentDetail {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContentDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContentDetail() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContentDetail value)  $default,){
final _that = this;
switch (_that) {
case _ContentDetail():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContentDetail value)?  $default,){
final _that = this;
switch (_that) {
case _ContentDetail() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ContentItem item,  String tagline,  String status,  String studio,  String certification,  String homepage,  String originalLanguage,  String spokenLanguages,  String releaseDate,  int seasons,  int episodes,  List<ContentVideo> videos,  List<CastMember> cast,  List<ContentReview> reviews,  List<ContentItem> recommendations,  List<ContentItem> similar,  List<String> watchProviders,  List<String> backdropUrls)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContentDetail() when $default != null:
return $default(_that.item,_that.tagline,_that.status,_that.studio,_that.certification,_that.homepage,_that.originalLanguage,_that.spokenLanguages,_that.releaseDate,_that.seasons,_that.episodes,_that.videos,_that.cast,_that.reviews,_that.recommendations,_that.similar,_that.watchProviders,_that.backdropUrls);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ContentItem item,  String tagline,  String status,  String studio,  String certification,  String homepage,  String originalLanguage,  String spokenLanguages,  String releaseDate,  int seasons,  int episodes,  List<ContentVideo> videos,  List<CastMember> cast,  List<ContentReview> reviews,  List<ContentItem> recommendations,  List<ContentItem> similar,  List<String> watchProviders,  List<String> backdropUrls)  $default,) {final _that = this;
switch (_that) {
case _ContentDetail():
return $default(_that.item,_that.tagline,_that.status,_that.studio,_that.certification,_that.homepage,_that.originalLanguage,_that.spokenLanguages,_that.releaseDate,_that.seasons,_that.episodes,_that.videos,_that.cast,_that.reviews,_that.recommendations,_that.similar,_that.watchProviders,_that.backdropUrls);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ContentItem item,  String tagline,  String status,  String studio,  String certification,  String homepage,  String originalLanguage,  String spokenLanguages,  String releaseDate,  int seasons,  int episodes,  List<ContentVideo> videos,  List<CastMember> cast,  List<ContentReview> reviews,  List<ContentItem> recommendations,  List<ContentItem> similar,  List<String> watchProviders,  List<String> backdropUrls)?  $default,) {final _that = this;
switch (_that) {
case _ContentDetail() when $default != null:
return $default(_that.item,_that.tagline,_that.status,_that.studio,_that.certification,_that.homepage,_that.originalLanguage,_that.spokenLanguages,_that.releaseDate,_that.seasons,_that.episodes,_that.videos,_that.cast,_that.reviews,_that.recommendations,_that.similar,_that.watchProviders,_that.backdropUrls);case _:
  return null;

}
}

}

/// @nodoc


class _ContentDetail extends ContentDetail {
  const _ContentDetail({required this.item, this.tagline = '', this.status = '', this.studio = '', this.certification = '', this.homepage = '', this.originalLanguage = '', this.spokenLanguages = '', this.releaseDate = '', this.seasons = 0, this.episodes = 0, final  List<ContentVideo> videos = const [], final  List<CastMember> cast = const [], final  List<ContentReview> reviews = const [], final  List<ContentItem> recommendations = const [], final  List<ContentItem> similar = const [], final  List<String> watchProviders = const [], final  List<String> backdropUrls = const []}): _videos = videos,_cast = cast,_reviews = reviews,_recommendations = recommendations,_similar = similar,_watchProviders = watchProviders,_backdropUrls = backdropUrls,super._();
  

@override final  ContentItem item;
@override@JsonKey() final  String tagline;
@override@JsonKey() final  String status;
@override@JsonKey() final  String studio;
@override@JsonKey() final  String certification;
@override@JsonKey() final  String homepage;
@override@JsonKey() final  String originalLanguage;
@override@JsonKey() final  String spokenLanguages;
@override@JsonKey() final  String releaseDate;
@override@JsonKey() final  int seasons;
@override@JsonKey() final  int episodes;
 final  List<ContentVideo> _videos;
@override@JsonKey() List<ContentVideo> get videos {
  if (_videos is EqualUnmodifiableListView) return _videos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_videos);
}

 final  List<CastMember> _cast;
@override@JsonKey() List<CastMember> get cast {
  if (_cast is EqualUnmodifiableListView) return _cast;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cast);
}

 final  List<ContentReview> _reviews;
@override@JsonKey() List<ContentReview> get reviews {
  if (_reviews is EqualUnmodifiableListView) return _reviews;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reviews);
}

 final  List<ContentItem> _recommendations;
@override@JsonKey() List<ContentItem> get recommendations {
  if (_recommendations is EqualUnmodifiableListView) return _recommendations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recommendations);
}

 final  List<ContentItem> _similar;
@override@JsonKey() List<ContentItem> get similar {
  if (_similar is EqualUnmodifiableListView) return _similar;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_similar);
}

 final  List<String> _watchProviders;
@override@JsonKey() List<String> get watchProviders {
  if (_watchProviders is EqualUnmodifiableListView) return _watchProviders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_watchProviders);
}

 final  List<String> _backdropUrls;
@override@JsonKey() List<String> get backdropUrls {
  if (_backdropUrls is EqualUnmodifiableListView) return _backdropUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_backdropUrls);
}


/// Create a copy of ContentDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContentDetailCopyWith<_ContentDetail> get copyWith => __$ContentDetailCopyWithImpl<_ContentDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContentDetail&&(identical(other.item, item) || other.item == item)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.status, status) || other.status == status)&&(identical(other.studio, studio) || other.studio == studio)&&(identical(other.certification, certification) || other.certification == certification)&&(identical(other.homepage, homepage) || other.homepage == homepage)&&(identical(other.originalLanguage, originalLanguage) || other.originalLanguage == originalLanguage)&&(identical(other.spokenLanguages, spokenLanguages) || other.spokenLanguages == spokenLanguages)&&(identical(other.releaseDate, releaseDate) || other.releaseDate == releaseDate)&&(identical(other.seasons, seasons) || other.seasons == seasons)&&(identical(other.episodes, episodes) || other.episodes == episodes)&&const DeepCollectionEquality().equals(other._videos, _videos)&&const DeepCollectionEquality().equals(other._cast, _cast)&&const DeepCollectionEquality().equals(other._reviews, _reviews)&&const DeepCollectionEquality().equals(other._recommendations, _recommendations)&&const DeepCollectionEquality().equals(other._similar, _similar)&&const DeepCollectionEquality().equals(other._watchProviders, _watchProviders)&&const DeepCollectionEquality().equals(other._backdropUrls, _backdropUrls));
}


@override
int get hashCode => Object.hash(runtimeType,item,tagline,status,studio,certification,homepage,originalLanguage,spokenLanguages,releaseDate,seasons,episodes,const DeepCollectionEquality().hash(_videos),const DeepCollectionEquality().hash(_cast),const DeepCollectionEquality().hash(_reviews),const DeepCollectionEquality().hash(_recommendations),const DeepCollectionEquality().hash(_similar),const DeepCollectionEquality().hash(_watchProviders),const DeepCollectionEquality().hash(_backdropUrls));

@override
String toString() {
  return 'ContentDetail(item: $item, tagline: $tagline, status: $status, studio: $studio, certification: $certification, homepage: $homepage, originalLanguage: $originalLanguage, spokenLanguages: $spokenLanguages, releaseDate: $releaseDate, seasons: $seasons, episodes: $episodes, videos: $videos, cast: $cast, reviews: $reviews, recommendations: $recommendations, similar: $similar, watchProviders: $watchProviders, backdropUrls: $backdropUrls)';
}


}

/// @nodoc
abstract mixin class _$ContentDetailCopyWith<$Res> implements $ContentDetailCopyWith<$Res> {
  factory _$ContentDetailCopyWith(_ContentDetail value, $Res Function(_ContentDetail) _then) = __$ContentDetailCopyWithImpl;
@override @useResult
$Res call({
 ContentItem item, String tagline, String status, String studio, String certification, String homepage, String originalLanguage, String spokenLanguages, String releaseDate, int seasons, int episodes, List<ContentVideo> videos, List<CastMember> cast, List<ContentReview> reviews, List<ContentItem> recommendations, List<ContentItem> similar, List<String> watchProviders, List<String> backdropUrls
});




}
/// @nodoc
class __$ContentDetailCopyWithImpl<$Res>
    implements _$ContentDetailCopyWith<$Res> {
  __$ContentDetailCopyWithImpl(this._self, this._then);

  final _ContentDetail _self;
  final $Res Function(_ContentDetail) _then;

/// Create a copy of ContentDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? item = null,Object? tagline = null,Object? status = null,Object? studio = null,Object? certification = null,Object? homepage = null,Object? originalLanguage = null,Object? spokenLanguages = null,Object? releaseDate = null,Object? seasons = null,Object? episodes = null,Object? videos = null,Object? cast = null,Object? reviews = null,Object? recommendations = null,Object? similar = null,Object? watchProviders = null,Object? backdropUrls = null,}) {
  return _then(_ContentDetail(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as ContentItem,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,studio: null == studio ? _self.studio : studio // ignore: cast_nullable_to_non_nullable
as String,certification: null == certification ? _self.certification : certification // ignore: cast_nullable_to_non_nullable
as String,homepage: null == homepage ? _self.homepage : homepage // ignore: cast_nullable_to_non_nullable
as String,originalLanguage: null == originalLanguage ? _self.originalLanguage : originalLanguage // ignore: cast_nullable_to_non_nullable
as String,spokenLanguages: null == spokenLanguages ? _self.spokenLanguages : spokenLanguages // ignore: cast_nullable_to_non_nullable
as String,releaseDate: null == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String,seasons: null == seasons ? _self.seasons : seasons // ignore: cast_nullable_to_non_nullable
as int,episodes: null == episodes ? _self.episodes : episodes // ignore: cast_nullable_to_non_nullable
as int,videos: null == videos ? _self._videos : videos // ignore: cast_nullable_to_non_nullable
as List<ContentVideo>,cast: null == cast ? _self._cast : cast // ignore: cast_nullable_to_non_nullable
as List<CastMember>,reviews: null == reviews ? _self._reviews : reviews // ignore: cast_nullable_to_non_nullable
as List<ContentReview>,recommendations: null == recommendations ? _self._recommendations : recommendations // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,similar: null == similar ? _self._similar : similar // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,watchProviders: null == watchProviders ? _self._watchProviders : watchProviders // ignore: cast_nullable_to_non_nullable
as List<String>,backdropUrls: null == backdropUrls ? _self._backdropUrls : backdropUrls // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$ContentVideo {

 String get key; String get name; String get site; String get type; bool get official;
/// Create a copy of ContentVideo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentVideoCopyWith<ContentVideo> get copyWith => _$ContentVideoCopyWithImpl<ContentVideo>(this as ContentVideo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentVideo&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.site, site) || other.site == site)&&(identical(other.type, type) || other.type == type)&&(identical(other.official, official) || other.official == official));
}


@override
int get hashCode => Object.hash(runtimeType,key,name,site,type,official);

@override
String toString() {
  return 'ContentVideo(key: $key, name: $name, site: $site, type: $type, official: $official)';
}


}

/// @nodoc
abstract mixin class $ContentVideoCopyWith<$Res>  {
  factory $ContentVideoCopyWith(ContentVideo value, $Res Function(ContentVideo) _then) = _$ContentVideoCopyWithImpl;
@useResult
$Res call({
 String key, String name, String site, String type, bool official
});




}
/// @nodoc
class _$ContentVideoCopyWithImpl<$Res>
    implements $ContentVideoCopyWith<$Res> {
  _$ContentVideoCopyWithImpl(this._self, this._then);

  final ContentVideo _self;
  final $Res Function(ContentVideo) _then;

/// Create a copy of ContentVideo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? name = null,Object? site = null,Object? type = null,Object? official = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,site: null == site ? _self.site : site // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,official: null == official ? _self.official : official // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ContentVideo].
extension ContentVideoPatterns on ContentVideo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContentVideo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContentVideo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContentVideo value)  $default,){
final _that = this;
switch (_that) {
case _ContentVideo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContentVideo value)?  $default,){
final _that = this;
switch (_that) {
case _ContentVideo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String name,  String site,  String type,  bool official)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContentVideo() when $default != null:
return $default(_that.key,_that.name,_that.site,_that.type,_that.official);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String name,  String site,  String type,  bool official)  $default,) {final _that = this;
switch (_that) {
case _ContentVideo():
return $default(_that.key,_that.name,_that.site,_that.type,_that.official);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String name,  String site,  String type,  bool official)?  $default,) {final _that = this;
switch (_that) {
case _ContentVideo() when $default != null:
return $default(_that.key,_that.name,_that.site,_that.type,_that.official);case _:
  return null;

}
}

}

/// @nodoc


class _ContentVideo extends ContentVideo {
  const _ContentVideo({required this.key, required this.name, required this.site, required this.type, this.official = false}): super._();
  

@override final  String key;
@override final  String name;
@override final  String site;
@override final  String type;
@override@JsonKey() final  bool official;

/// Create a copy of ContentVideo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContentVideoCopyWith<_ContentVideo> get copyWith => __$ContentVideoCopyWithImpl<_ContentVideo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContentVideo&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.site, site) || other.site == site)&&(identical(other.type, type) || other.type == type)&&(identical(other.official, official) || other.official == official));
}


@override
int get hashCode => Object.hash(runtimeType,key,name,site,type,official);

@override
String toString() {
  return 'ContentVideo(key: $key, name: $name, site: $site, type: $type, official: $official)';
}


}

/// @nodoc
abstract mixin class _$ContentVideoCopyWith<$Res> implements $ContentVideoCopyWith<$Res> {
  factory _$ContentVideoCopyWith(_ContentVideo value, $Res Function(_ContentVideo) _then) = __$ContentVideoCopyWithImpl;
@override @useResult
$Res call({
 String key, String name, String site, String type, bool official
});




}
/// @nodoc
class __$ContentVideoCopyWithImpl<$Res>
    implements _$ContentVideoCopyWith<$Res> {
  __$ContentVideoCopyWithImpl(this._self, this._then);

  final _ContentVideo _self;
  final $Res Function(_ContentVideo) _then;

/// Create a copy of ContentVideo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? name = null,Object? site = null,Object? type = null,Object? official = null,}) {
  return _then(_ContentVideo(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,site: null == site ? _self.site : site // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,official: null == official ? _self.official : official // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$CastMember {

 String get name; String get role; String? get profileUrl;
/// Create a copy of CastMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CastMemberCopyWith<CastMember> get copyWith => _$CastMemberCopyWithImpl<CastMember>(this as CastMember, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CastMember&&(identical(other.name, name) || other.name == name)&&(identical(other.role, role) || other.role == role)&&(identical(other.profileUrl, profileUrl) || other.profileUrl == profileUrl));
}


@override
int get hashCode => Object.hash(runtimeType,name,role,profileUrl);

@override
String toString() {
  return 'CastMember(name: $name, role: $role, profileUrl: $profileUrl)';
}


}

/// @nodoc
abstract mixin class $CastMemberCopyWith<$Res>  {
  factory $CastMemberCopyWith(CastMember value, $Res Function(CastMember) _then) = _$CastMemberCopyWithImpl;
@useResult
$Res call({
 String name, String role, String? profileUrl
});




}
/// @nodoc
class _$CastMemberCopyWithImpl<$Res>
    implements $CastMemberCopyWith<$Res> {
  _$CastMemberCopyWithImpl(this._self, this._then);

  final CastMember _self;
  final $Res Function(CastMember) _then;

/// Create a copy of CastMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? role = null,Object? profileUrl = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,profileUrl: freezed == profileUrl ? _self.profileUrl : profileUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CastMember].
extension CastMemberPatterns on CastMember {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CastMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CastMember() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CastMember value)  $default,){
final _that = this;
switch (_that) {
case _CastMember():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CastMember value)?  $default,){
final _that = this;
switch (_that) {
case _CastMember() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String role,  String? profileUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CastMember() when $default != null:
return $default(_that.name,_that.role,_that.profileUrl);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String role,  String? profileUrl)  $default,) {final _that = this;
switch (_that) {
case _CastMember():
return $default(_that.name,_that.role,_that.profileUrl);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String role,  String? profileUrl)?  $default,) {final _that = this;
switch (_that) {
case _CastMember() when $default != null:
return $default(_that.name,_that.role,_that.profileUrl);case _:
  return null;

}
}

}

/// @nodoc


class _CastMember extends CastMember {
  const _CastMember({required this.name, required this.role, this.profileUrl}): super._();
  

@override final  String name;
@override final  String role;
@override final  String? profileUrl;

/// Create a copy of CastMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CastMemberCopyWith<_CastMember> get copyWith => __$CastMemberCopyWithImpl<_CastMember>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CastMember&&(identical(other.name, name) || other.name == name)&&(identical(other.role, role) || other.role == role)&&(identical(other.profileUrl, profileUrl) || other.profileUrl == profileUrl));
}


@override
int get hashCode => Object.hash(runtimeType,name,role,profileUrl);

@override
String toString() {
  return 'CastMember(name: $name, role: $role, profileUrl: $profileUrl)';
}


}

/// @nodoc
abstract mixin class _$CastMemberCopyWith<$Res> implements $CastMemberCopyWith<$Res> {
  factory _$CastMemberCopyWith(_CastMember value, $Res Function(_CastMember) _then) = __$CastMemberCopyWithImpl;
@override @useResult
$Res call({
 String name, String role, String? profileUrl
});




}
/// @nodoc
class __$CastMemberCopyWithImpl<$Res>
    implements _$CastMemberCopyWith<$Res> {
  __$CastMemberCopyWithImpl(this._self, this._then);

  final _CastMember _self;
  final $Res Function(_CastMember) _then;

/// Create a copy of CastMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? role = null,Object? profileUrl = freezed,}) {
  return _then(_CastMember(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,profileUrl: freezed == profileUrl ? _self.profileUrl : profileUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ContentReview {

 String get author; String get content; double get rating;
/// Create a copy of ContentReview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentReviewCopyWith<ContentReview> get copyWith => _$ContentReviewCopyWithImpl<ContentReview>(this as ContentReview, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentReview&&(identical(other.author, author) || other.author == author)&&(identical(other.content, content) || other.content == content)&&(identical(other.rating, rating) || other.rating == rating));
}


@override
int get hashCode => Object.hash(runtimeType,author,content,rating);

@override
String toString() {
  return 'ContentReview(author: $author, content: $content, rating: $rating)';
}


}

/// @nodoc
abstract mixin class $ContentReviewCopyWith<$Res>  {
  factory $ContentReviewCopyWith(ContentReview value, $Res Function(ContentReview) _then) = _$ContentReviewCopyWithImpl;
@useResult
$Res call({
 String author, String content, double rating
});




}
/// @nodoc
class _$ContentReviewCopyWithImpl<$Res>
    implements $ContentReviewCopyWith<$Res> {
  _$ContentReviewCopyWithImpl(this._self, this._then);

  final ContentReview _self;
  final $Res Function(ContentReview) _then;

/// Create a copy of ContentReview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? author = null,Object? content = null,Object? rating = null,}) {
  return _then(_self.copyWith(
author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ContentReview].
extension ContentReviewPatterns on ContentReview {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContentReview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContentReview() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContentReview value)  $default,){
final _that = this;
switch (_that) {
case _ContentReview():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContentReview value)?  $default,){
final _that = this;
switch (_that) {
case _ContentReview() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String author,  String content,  double rating)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContentReview() when $default != null:
return $default(_that.author,_that.content,_that.rating);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String author,  String content,  double rating)  $default,) {final _that = this;
switch (_that) {
case _ContentReview():
return $default(_that.author,_that.content,_that.rating);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String author,  String content,  double rating)?  $default,) {final _that = this;
switch (_that) {
case _ContentReview() when $default != null:
return $default(_that.author,_that.content,_that.rating);case _:
  return null;

}
}

}

/// @nodoc


class _ContentReview extends ContentReview {
  const _ContentReview({required this.author, required this.content, this.rating = 0}): super._();
  

@override final  String author;
@override final  String content;
@override@JsonKey() final  double rating;

/// Create a copy of ContentReview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContentReviewCopyWith<_ContentReview> get copyWith => __$ContentReviewCopyWithImpl<_ContentReview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContentReview&&(identical(other.author, author) || other.author == author)&&(identical(other.content, content) || other.content == content)&&(identical(other.rating, rating) || other.rating == rating));
}


@override
int get hashCode => Object.hash(runtimeType,author,content,rating);

@override
String toString() {
  return 'ContentReview(author: $author, content: $content, rating: $rating)';
}


}

/// @nodoc
abstract mixin class _$ContentReviewCopyWith<$Res> implements $ContentReviewCopyWith<$Res> {
  factory _$ContentReviewCopyWith(_ContentReview value, $Res Function(_ContentReview) _then) = __$ContentReviewCopyWithImpl;
@override @useResult
$Res call({
 String author, String content, double rating
});




}
/// @nodoc
class __$ContentReviewCopyWithImpl<$Res>
    implements _$ContentReviewCopyWith<$Res> {
  __$ContentReviewCopyWithImpl(this._self, this._then);

  final _ContentReview _self;
  final $Res Function(_ContentReview) _then;

/// Create a copy of ContentReview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? author = null,Object? content = null,Object? rating = null,}) {
  return _then(_ContentReview(
author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
