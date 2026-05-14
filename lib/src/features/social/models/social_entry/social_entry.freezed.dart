// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'social_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SocialEntry {

 String get id; String get userId; int? get tmdbId; String? get imdbId; String get mediaType; String get title; String get subtitle; int get year; String get genre; String get type; double get tmdbRating; String? get posterUrl; String? get backdropUrl; String get description; double get rating; String get review; List<String> get tags; DateTime? get watchedOn; bool get isFavorite; bool get inWatchlist; bool get liked; int get likeCount; int get commentCount; String get authorDisplayName; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of SocialEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocialEntryCopyWith<SocialEntry> get copyWith => _$SocialEntryCopyWithImpl<SocialEntry>(this as SocialEntry, _$identity);

  /// Serializes this SocialEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocialEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.imdbId, imdbId) || other.imdbId == imdbId)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.year, year) || other.year == year)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.type, type) || other.type == type)&&(identical(other.tmdbRating, tmdbRating) || other.tmdbRating == tmdbRating)&&(identical(other.posterUrl, posterUrl) || other.posterUrl == posterUrl)&&(identical(other.backdropUrl, backdropUrl) || other.backdropUrl == backdropUrl)&&(identical(other.description, description) || other.description == description)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.review, review) || other.review == review)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.watchedOn, watchedOn) || other.watchedOn == watchedOn)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.inWatchlist, inWatchlist) || other.inWatchlist == inWatchlist)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.authorDisplayName, authorDisplayName) || other.authorDisplayName == authorDisplayName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,tmdbId,imdbId,mediaType,title,subtitle,year,genre,type,tmdbRating,posterUrl,backdropUrl,description,rating,review,const DeepCollectionEquality().hash(tags),watchedOn,isFavorite,inWatchlist,liked,likeCount,commentCount,authorDisplayName,createdAt,updatedAt]);

@override
String toString() {
  return 'SocialEntry(id: $id, userId: $userId, tmdbId: $tmdbId, imdbId: $imdbId, mediaType: $mediaType, title: $title, subtitle: $subtitle, year: $year, genre: $genre, type: $type, tmdbRating: $tmdbRating, posterUrl: $posterUrl, backdropUrl: $backdropUrl, description: $description, rating: $rating, review: $review, tags: $tags, watchedOn: $watchedOn, isFavorite: $isFavorite, inWatchlist: $inWatchlist, liked: $liked, likeCount: $likeCount, commentCount: $commentCount, authorDisplayName: $authorDisplayName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SocialEntryCopyWith<$Res>  {
  factory $SocialEntryCopyWith(SocialEntry value, $Res Function(SocialEntry) _then) = _$SocialEntryCopyWithImpl;
@useResult
$Res call({
 String id, String userId, int? tmdbId, String? imdbId, String mediaType, String title, String subtitle, int year, String genre, String type, double tmdbRating, String? posterUrl, String? backdropUrl, String description, double rating, String review, List<String> tags, DateTime? watchedOn, bool isFavorite, bool inWatchlist, bool liked, int likeCount, int commentCount, String authorDisplayName, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$SocialEntryCopyWithImpl<$Res>
    implements $SocialEntryCopyWith<$Res> {
  _$SocialEntryCopyWithImpl(this._self, this._then);

  final SocialEntry _self;
  final $Res Function(SocialEntry) _then;

/// Create a copy of SocialEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? tmdbId = freezed,Object? imdbId = freezed,Object? mediaType = null,Object? title = null,Object? subtitle = null,Object? year = null,Object? genre = null,Object? type = null,Object? tmdbRating = null,Object? posterUrl = freezed,Object? backdropUrl = freezed,Object? description = null,Object? rating = null,Object? review = null,Object? tags = null,Object? watchedOn = freezed,Object? isFavorite = null,Object? inWatchlist = null,Object? liked = null,Object? likeCount = null,Object? commentCount = null,Object? authorDisplayName = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as int?,imdbId: freezed == imdbId ? _self.imdbId : imdbId // ignore: cast_nullable_to_non_nullable
as String?,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,genre: null == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,tmdbRating: null == tmdbRating ? _self.tmdbRating : tmdbRating // ignore: cast_nullable_to_non_nullable
as double,posterUrl: freezed == posterUrl ? _self.posterUrl : posterUrl // ignore: cast_nullable_to_non_nullable
as String?,backdropUrl: freezed == backdropUrl ? _self.backdropUrl : backdropUrl // ignore: cast_nullable_to_non_nullable
as String?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,review: null == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,watchedOn: freezed == watchedOn ? _self.watchedOn : watchedOn // ignore: cast_nullable_to_non_nullable
as DateTime?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,inWatchlist: null == inWatchlist ? _self.inWatchlist : inWatchlist // ignore: cast_nullable_to_non_nullable
as bool,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,authorDisplayName: null == authorDisplayName ? _self.authorDisplayName : authorDisplayName // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SocialEntry].
extension SocialEntryPatterns on SocialEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SocialEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SocialEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SocialEntry value)  $default,){
final _that = this;
switch (_that) {
case _SocialEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SocialEntry value)?  $default,){
final _that = this;
switch (_that) {
case _SocialEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  int? tmdbId,  String? imdbId,  String mediaType,  String title,  String subtitle,  int year,  String genre,  String type,  double tmdbRating,  String? posterUrl,  String? backdropUrl,  String description,  double rating,  String review,  List<String> tags,  DateTime? watchedOn,  bool isFavorite,  bool inWatchlist,  bool liked,  int likeCount,  int commentCount,  String authorDisplayName,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SocialEntry() when $default != null:
return $default(_that.id,_that.userId,_that.tmdbId,_that.imdbId,_that.mediaType,_that.title,_that.subtitle,_that.year,_that.genre,_that.type,_that.tmdbRating,_that.posterUrl,_that.backdropUrl,_that.description,_that.rating,_that.review,_that.tags,_that.watchedOn,_that.isFavorite,_that.inWatchlist,_that.liked,_that.likeCount,_that.commentCount,_that.authorDisplayName,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  int? tmdbId,  String? imdbId,  String mediaType,  String title,  String subtitle,  int year,  String genre,  String type,  double tmdbRating,  String? posterUrl,  String? backdropUrl,  String description,  double rating,  String review,  List<String> tags,  DateTime? watchedOn,  bool isFavorite,  bool inWatchlist,  bool liked,  int likeCount,  int commentCount,  String authorDisplayName,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SocialEntry():
return $default(_that.id,_that.userId,_that.tmdbId,_that.imdbId,_that.mediaType,_that.title,_that.subtitle,_that.year,_that.genre,_that.type,_that.tmdbRating,_that.posterUrl,_that.backdropUrl,_that.description,_that.rating,_that.review,_that.tags,_that.watchedOn,_that.isFavorite,_that.inWatchlist,_that.liked,_that.likeCount,_that.commentCount,_that.authorDisplayName,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  int? tmdbId,  String? imdbId,  String mediaType,  String title,  String subtitle,  int year,  String genre,  String type,  double tmdbRating,  String? posterUrl,  String? backdropUrl,  String description,  double rating,  String review,  List<String> tags,  DateTime? watchedOn,  bool isFavorite,  bool inWatchlist,  bool liked,  int likeCount,  int commentCount,  String authorDisplayName,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SocialEntry() when $default != null:
return $default(_that.id,_that.userId,_that.tmdbId,_that.imdbId,_that.mediaType,_that.title,_that.subtitle,_that.year,_that.genre,_that.type,_that.tmdbRating,_that.posterUrl,_that.backdropUrl,_that.description,_that.rating,_that.review,_that.tags,_that.watchedOn,_that.isFavorite,_that.inWatchlist,_that.liked,_that.likeCount,_that.commentCount,_that.authorDisplayName,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SocialEntry extends SocialEntry {
  const _SocialEntry({required this.id, this.userId = 'local-user', this.tmdbId, this.imdbId, this.mediaType = 'movie', required this.title, this.subtitle = '', this.year = 0, this.genre = '', this.type = 'Movie', this.tmdbRating = 0, this.posterUrl, this.backdropUrl, this.description = '', this.rating = 0, this.review = '', final  List<String> tags = const [], this.watchedOn, this.isFavorite = false, this.inWatchlist = false, this.liked = false, this.likeCount = 0, this.commentCount = 0, this.authorDisplayName = '', required this.createdAt, required this.updatedAt}): _tags = tags,super._();
  factory _SocialEntry.fromJson(Map<String, dynamic> json) => _$SocialEntryFromJson(json);

@override final  String id;
@override@JsonKey() final  String userId;
@override final  int? tmdbId;
@override final  String? imdbId;
@override@JsonKey() final  String mediaType;
@override final  String title;
@override@JsonKey() final  String subtitle;
@override@JsonKey() final  int year;
@override@JsonKey() final  String genre;
@override@JsonKey() final  String type;
@override@JsonKey() final  double tmdbRating;
@override final  String? posterUrl;
@override final  String? backdropUrl;
@override@JsonKey() final  String description;
@override@JsonKey() final  double rating;
@override@JsonKey() final  String review;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  DateTime? watchedOn;
@override@JsonKey() final  bool isFavorite;
@override@JsonKey() final  bool inWatchlist;
@override@JsonKey() final  bool liked;
@override@JsonKey() final  int likeCount;
@override@JsonKey() final  int commentCount;
@override@JsonKey() final  String authorDisplayName;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of SocialEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SocialEntryCopyWith<_SocialEntry> get copyWith => __$SocialEntryCopyWithImpl<_SocialEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SocialEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SocialEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.imdbId, imdbId) || other.imdbId == imdbId)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.year, year) || other.year == year)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.type, type) || other.type == type)&&(identical(other.tmdbRating, tmdbRating) || other.tmdbRating == tmdbRating)&&(identical(other.posterUrl, posterUrl) || other.posterUrl == posterUrl)&&(identical(other.backdropUrl, backdropUrl) || other.backdropUrl == backdropUrl)&&(identical(other.description, description) || other.description == description)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.review, review) || other.review == review)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.watchedOn, watchedOn) || other.watchedOn == watchedOn)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.inWatchlist, inWatchlist) || other.inWatchlist == inWatchlist)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.authorDisplayName, authorDisplayName) || other.authorDisplayName == authorDisplayName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,userId,tmdbId,imdbId,mediaType,title,subtitle,year,genre,type,tmdbRating,posterUrl,backdropUrl,description,rating,review,const DeepCollectionEquality().hash(_tags),watchedOn,isFavorite,inWatchlist,liked,likeCount,commentCount,authorDisplayName,createdAt,updatedAt]);

@override
String toString() {
  return 'SocialEntry(id: $id, userId: $userId, tmdbId: $tmdbId, imdbId: $imdbId, mediaType: $mediaType, title: $title, subtitle: $subtitle, year: $year, genre: $genre, type: $type, tmdbRating: $tmdbRating, posterUrl: $posterUrl, backdropUrl: $backdropUrl, description: $description, rating: $rating, review: $review, tags: $tags, watchedOn: $watchedOn, isFavorite: $isFavorite, inWatchlist: $inWatchlist, liked: $liked, likeCount: $likeCount, commentCount: $commentCount, authorDisplayName: $authorDisplayName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SocialEntryCopyWith<$Res> implements $SocialEntryCopyWith<$Res> {
  factory _$SocialEntryCopyWith(_SocialEntry value, $Res Function(_SocialEntry) _then) = __$SocialEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, int? tmdbId, String? imdbId, String mediaType, String title, String subtitle, int year, String genre, String type, double tmdbRating, String? posterUrl, String? backdropUrl, String description, double rating, String review, List<String> tags, DateTime? watchedOn, bool isFavorite, bool inWatchlist, bool liked, int likeCount, int commentCount, String authorDisplayName, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$SocialEntryCopyWithImpl<$Res>
    implements _$SocialEntryCopyWith<$Res> {
  __$SocialEntryCopyWithImpl(this._self, this._then);

  final _SocialEntry _self;
  final $Res Function(_SocialEntry) _then;

/// Create a copy of SocialEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? tmdbId = freezed,Object? imdbId = freezed,Object? mediaType = null,Object? title = null,Object? subtitle = null,Object? year = null,Object? genre = null,Object? type = null,Object? tmdbRating = null,Object? posterUrl = freezed,Object? backdropUrl = freezed,Object? description = null,Object? rating = null,Object? review = null,Object? tags = null,Object? watchedOn = freezed,Object? isFavorite = null,Object? inWatchlist = null,Object? liked = null,Object? likeCount = null,Object? commentCount = null,Object? authorDisplayName = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_SocialEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as int?,imdbId: freezed == imdbId ? _self.imdbId : imdbId // ignore: cast_nullable_to_non_nullable
as String?,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,genre: null == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,tmdbRating: null == tmdbRating ? _self.tmdbRating : tmdbRating // ignore: cast_nullable_to_non_nullable
as double,posterUrl: freezed == posterUrl ? _self.posterUrl : posterUrl // ignore: cast_nullable_to_non_nullable
as String?,backdropUrl: freezed == backdropUrl ? _self.backdropUrl : backdropUrl // ignore: cast_nullable_to_non_nullable
as String?,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,review: null == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,watchedOn: freezed == watchedOn ? _self.watchedOn : watchedOn // ignore: cast_nullable_to_non_nullable
as DateTime?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,inWatchlist: null == inWatchlist ? _self.inWatchlist : inWatchlist // ignore: cast_nullable_to_non_nullable
as bool,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,authorDisplayName: null == authorDisplayName ? _self.authorDisplayName : authorDisplayName // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
