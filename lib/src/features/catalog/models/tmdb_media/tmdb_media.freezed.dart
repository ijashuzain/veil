// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmdb_media.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TmdbMedia {

 int get id;@JsonKey(name: 'media_type', readValue: _readMediaType) String get mediaType;@JsonKey(name: 'imdb_id') String? get imdbId;@JsonKey(readValue: _readTitle) String get title; String get overview;@JsonKey(name: 'poster_path') String? get posterPath;@JsonKey(name: 'backdrop_path') String? get backdropPath;@JsonKey(name: 'release_date', readValue: _readReleaseDate) String get releaseDate;@JsonKey(name: 'vote_average') double get voteAverage;@JsonKey(name: 'genre_ids') List<int> get genreIds;
/// Create a copy of TmdbMedia
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmdbMediaCopyWith<TmdbMedia> get copyWith => _$TmdbMediaCopyWithImpl<TmdbMedia>(this as TmdbMedia, _$identity);

  /// Serializes this TmdbMedia to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmdbMedia&&(identical(other.id, id) || other.id == id)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.imdbId, imdbId) || other.imdbId == imdbId)&&(identical(other.title, title) || other.title == title)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.releaseDate, releaseDate) || other.releaseDate == releaseDate)&&(identical(other.voteAverage, voteAverage) || other.voteAverage == voteAverage)&&const DeepCollectionEquality().equals(other.genreIds, genreIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,mediaType,imdbId,title,overview,posterPath,backdropPath,releaseDate,voteAverage,const DeepCollectionEquality().hash(genreIds));

@override
String toString() {
  return 'TmdbMedia(id: $id, mediaType: $mediaType, imdbId: $imdbId, title: $title, overview: $overview, posterPath: $posterPath, backdropPath: $backdropPath, releaseDate: $releaseDate, voteAverage: $voteAverage, genreIds: $genreIds)';
}


}

/// @nodoc
abstract mixin class $TmdbMediaCopyWith<$Res>  {
  factory $TmdbMediaCopyWith(TmdbMedia value, $Res Function(TmdbMedia) _then) = _$TmdbMediaCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'media_type', readValue: _readMediaType) String mediaType,@JsonKey(name: 'imdb_id') String? imdbId,@JsonKey(readValue: _readTitle) String title, String overview,@JsonKey(name: 'poster_path') String? posterPath,@JsonKey(name: 'backdrop_path') String? backdropPath,@JsonKey(name: 'release_date', readValue: _readReleaseDate) String releaseDate,@JsonKey(name: 'vote_average') double voteAverage,@JsonKey(name: 'genre_ids') List<int> genreIds
});




}
/// @nodoc
class _$TmdbMediaCopyWithImpl<$Res>
    implements $TmdbMediaCopyWith<$Res> {
  _$TmdbMediaCopyWithImpl(this._self, this._then);

  final TmdbMedia _self;
  final $Res Function(TmdbMedia) _then;

/// Create a copy of TmdbMedia
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? mediaType = null,Object? imdbId = freezed,Object? title = null,Object? overview = null,Object? posterPath = freezed,Object? backdropPath = freezed,Object? releaseDate = null,Object? voteAverage = null,Object? genreIds = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,imdbId: freezed == imdbId ? _self.imdbId : imdbId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,overview: null == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,releaseDate: null == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String,voteAverage: null == voteAverage ? _self.voteAverage : voteAverage // ignore: cast_nullable_to_non_nullable
as double,genreIds: null == genreIds ? _self.genreIds : genreIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [TmdbMedia].
extension TmdbMediaPatterns on TmdbMedia {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TmdbMedia value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TmdbMedia() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TmdbMedia value)  $default,){
final _that = this;
switch (_that) {
case _TmdbMedia():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TmdbMedia value)?  $default,){
final _that = this;
switch (_that) {
case _TmdbMedia() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'media_type', readValue: _readMediaType)  String mediaType, @JsonKey(name: 'imdb_id')  String? imdbId, @JsonKey(readValue: _readTitle)  String title,  String overview, @JsonKey(name: 'poster_path')  String? posterPath, @JsonKey(name: 'backdrop_path')  String? backdropPath, @JsonKey(name: 'release_date', readValue: _readReleaseDate)  String releaseDate, @JsonKey(name: 'vote_average')  double voteAverage, @JsonKey(name: 'genre_ids')  List<int> genreIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TmdbMedia() when $default != null:
return $default(_that.id,_that.mediaType,_that.imdbId,_that.title,_that.overview,_that.posterPath,_that.backdropPath,_that.releaseDate,_that.voteAverage,_that.genreIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'media_type', readValue: _readMediaType)  String mediaType, @JsonKey(name: 'imdb_id')  String? imdbId, @JsonKey(readValue: _readTitle)  String title,  String overview, @JsonKey(name: 'poster_path')  String? posterPath, @JsonKey(name: 'backdrop_path')  String? backdropPath, @JsonKey(name: 'release_date', readValue: _readReleaseDate)  String releaseDate, @JsonKey(name: 'vote_average')  double voteAverage, @JsonKey(name: 'genre_ids')  List<int> genreIds)  $default,) {final _that = this;
switch (_that) {
case _TmdbMedia():
return $default(_that.id,_that.mediaType,_that.imdbId,_that.title,_that.overview,_that.posterPath,_that.backdropPath,_that.releaseDate,_that.voteAverage,_that.genreIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'media_type', readValue: _readMediaType)  String mediaType, @JsonKey(name: 'imdb_id')  String? imdbId, @JsonKey(readValue: _readTitle)  String title,  String overview, @JsonKey(name: 'poster_path')  String? posterPath, @JsonKey(name: 'backdrop_path')  String? backdropPath, @JsonKey(name: 'release_date', readValue: _readReleaseDate)  String releaseDate, @JsonKey(name: 'vote_average')  double voteAverage, @JsonKey(name: 'genre_ids')  List<int> genreIds)?  $default,) {final _that = this;
switch (_that) {
case _TmdbMedia() when $default != null:
return $default(_that.id,_that.mediaType,_that.imdbId,_that.title,_that.overview,_that.posterPath,_that.backdropPath,_that.releaseDate,_that.voteAverage,_that.genreIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TmdbMedia extends TmdbMedia {
  const _TmdbMedia({this.id = 0, @JsonKey(name: 'media_type', readValue: _readMediaType) this.mediaType = 'movie', @JsonKey(name: 'imdb_id') this.imdbId, @JsonKey(readValue: _readTitle) this.title = 'Untitled', this.overview = '', @JsonKey(name: 'poster_path') this.posterPath, @JsonKey(name: 'backdrop_path') this.backdropPath, @JsonKey(name: 'release_date', readValue: _readReleaseDate) this.releaseDate = '', @JsonKey(name: 'vote_average') this.voteAverage = 0, @JsonKey(name: 'genre_ids') final  List<int> genreIds = const []}): _genreIds = genreIds,super._();
  factory _TmdbMedia.fromJson(Map<String, dynamic> json) => _$TmdbMediaFromJson(json);

@override@JsonKey() final  int id;
@override@JsonKey(name: 'media_type', readValue: _readMediaType) final  String mediaType;
@override@JsonKey(name: 'imdb_id') final  String? imdbId;
@override@JsonKey(readValue: _readTitle) final  String title;
@override@JsonKey() final  String overview;
@override@JsonKey(name: 'poster_path') final  String? posterPath;
@override@JsonKey(name: 'backdrop_path') final  String? backdropPath;
@override@JsonKey(name: 'release_date', readValue: _readReleaseDate) final  String releaseDate;
@override@JsonKey(name: 'vote_average') final  double voteAverage;
 final  List<int> _genreIds;
@override@JsonKey(name: 'genre_ids') List<int> get genreIds {
  if (_genreIds is EqualUnmodifiableListView) return _genreIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genreIds);
}


/// Create a copy of TmdbMedia
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmdbMediaCopyWith<_TmdbMedia> get copyWith => __$TmdbMediaCopyWithImpl<_TmdbMedia>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TmdbMediaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmdbMedia&&(identical(other.id, id) || other.id == id)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.imdbId, imdbId) || other.imdbId == imdbId)&&(identical(other.title, title) || other.title == title)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.releaseDate, releaseDate) || other.releaseDate == releaseDate)&&(identical(other.voteAverage, voteAverage) || other.voteAverage == voteAverage)&&const DeepCollectionEquality().equals(other._genreIds, _genreIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,mediaType,imdbId,title,overview,posterPath,backdropPath,releaseDate,voteAverage,const DeepCollectionEquality().hash(_genreIds));

@override
String toString() {
  return 'TmdbMedia(id: $id, mediaType: $mediaType, imdbId: $imdbId, title: $title, overview: $overview, posterPath: $posterPath, backdropPath: $backdropPath, releaseDate: $releaseDate, voteAverage: $voteAverage, genreIds: $genreIds)';
}


}

/// @nodoc
abstract mixin class _$TmdbMediaCopyWith<$Res> implements $TmdbMediaCopyWith<$Res> {
  factory _$TmdbMediaCopyWith(_TmdbMedia value, $Res Function(_TmdbMedia) _then) = __$TmdbMediaCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'media_type', readValue: _readMediaType) String mediaType,@JsonKey(name: 'imdb_id') String? imdbId,@JsonKey(readValue: _readTitle) String title, String overview,@JsonKey(name: 'poster_path') String? posterPath,@JsonKey(name: 'backdrop_path') String? backdropPath,@JsonKey(name: 'release_date', readValue: _readReleaseDate) String releaseDate,@JsonKey(name: 'vote_average') double voteAverage,@JsonKey(name: 'genre_ids') List<int> genreIds
});




}
/// @nodoc
class __$TmdbMediaCopyWithImpl<$Res>
    implements _$TmdbMediaCopyWith<$Res> {
  __$TmdbMediaCopyWithImpl(this._self, this._then);

  final _TmdbMedia _self;
  final $Res Function(_TmdbMedia) _then;

/// Create a copy of TmdbMedia
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? mediaType = null,Object? imdbId = freezed,Object? title = null,Object? overview = null,Object? posterPath = freezed,Object? backdropPath = freezed,Object? releaseDate = null,Object? voteAverage = null,Object? genreIds = null,}) {
  return _then(_TmdbMedia(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,imdbId: freezed == imdbId ? _self.imdbId : imdbId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,overview: null == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,releaseDate: null == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String,voteAverage: null == voteAverage ? _self.voteAverage : voteAverage // ignore: cast_nullable_to_non_nullable
as double,genreIds: null == genreIds ? _self._genreIds : genreIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

// dart format on
