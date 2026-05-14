// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeViewState {

 ContentItem? get featured; List<ContentItem> get globalTrending; List<ContentItem> get newThisWeek; List<ContentItem> get popularMovies; List<ContentItem> get topRatedMovies; List<ContentItem> get topRatedTv; List<ContentItem> get airingToday; List<TmdbGenre> get genres; TmdbGenre? get selectedGenre; List<ContentItem> get genreResults; int get genrePage; bool get genreCanLoadMore; bool get genreLoadingMore; Status get loadStatus; Status get genreStatus;
/// Create a copy of HomeViewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeViewStateCopyWith<HomeViewState> get copyWith => _$HomeViewStateCopyWithImpl<HomeViewState>(this as HomeViewState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeViewState&&(identical(other.featured, featured) || other.featured == featured)&&const DeepCollectionEquality().equals(other.globalTrending, globalTrending)&&const DeepCollectionEquality().equals(other.newThisWeek, newThisWeek)&&const DeepCollectionEquality().equals(other.popularMovies, popularMovies)&&const DeepCollectionEquality().equals(other.topRatedMovies, topRatedMovies)&&const DeepCollectionEquality().equals(other.topRatedTv, topRatedTv)&&const DeepCollectionEquality().equals(other.airingToday, airingToday)&&const DeepCollectionEquality().equals(other.genres, genres)&&(identical(other.selectedGenre, selectedGenre) || other.selectedGenre == selectedGenre)&&const DeepCollectionEquality().equals(other.genreResults, genreResults)&&(identical(other.genrePage, genrePage) || other.genrePage == genrePage)&&(identical(other.genreCanLoadMore, genreCanLoadMore) || other.genreCanLoadMore == genreCanLoadMore)&&(identical(other.genreLoadingMore, genreLoadingMore) || other.genreLoadingMore == genreLoadingMore)&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.genreStatus, genreStatus) || other.genreStatus == genreStatus));
}


@override
int get hashCode => Object.hash(runtimeType,featured,const DeepCollectionEquality().hash(globalTrending),const DeepCollectionEquality().hash(newThisWeek),const DeepCollectionEquality().hash(popularMovies),const DeepCollectionEquality().hash(topRatedMovies),const DeepCollectionEquality().hash(topRatedTv),const DeepCollectionEquality().hash(airingToday),const DeepCollectionEquality().hash(genres),selectedGenre,const DeepCollectionEquality().hash(genreResults),genrePage,genreCanLoadMore,genreLoadingMore,loadStatus,genreStatus);

@override
String toString() {
  return 'HomeViewState(featured: $featured, globalTrending: $globalTrending, newThisWeek: $newThisWeek, popularMovies: $popularMovies, topRatedMovies: $topRatedMovies, topRatedTv: $topRatedTv, airingToday: $airingToday, genres: $genres, selectedGenre: $selectedGenre, genreResults: $genreResults, genrePage: $genrePage, genreCanLoadMore: $genreCanLoadMore, genreLoadingMore: $genreLoadingMore, loadStatus: $loadStatus, genreStatus: $genreStatus)';
}


}

/// @nodoc
abstract mixin class $HomeViewStateCopyWith<$Res>  {
  factory $HomeViewStateCopyWith(HomeViewState value, $Res Function(HomeViewState) _then) = _$HomeViewStateCopyWithImpl;
@useResult
$Res call({
 ContentItem? featured, List<ContentItem> globalTrending, List<ContentItem> newThisWeek, List<ContentItem> popularMovies, List<ContentItem> topRatedMovies, List<ContentItem> topRatedTv, List<ContentItem> airingToday, List<TmdbGenre> genres, TmdbGenre? selectedGenre, List<ContentItem> genreResults, int genrePage, bool genreCanLoadMore, bool genreLoadingMore, Status loadStatus, Status genreStatus
});


$StatusCopyWith<$Res> get loadStatus;$StatusCopyWith<$Res> get genreStatus;

}
/// @nodoc
class _$HomeViewStateCopyWithImpl<$Res>
    implements $HomeViewStateCopyWith<$Res> {
  _$HomeViewStateCopyWithImpl(this._self, this._then);

  final HomeViewState _self;
  final $Res Function(HomeViewState) _then;

/// Create a copy of HomeViewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? featured = freezed,Object? globalTrending = null,Object? newThisWeek = null,Object? popularMovies = null,Object? topRatedMovies = null,Object? topRatedTv = null,Object? airingToday = null,Object? genres = null,Object? selectedGenre = freezed,Object? genreResults = null,Object? genrePage = null,Object? genreCanLoadMore = null,Object? genreLoadingMore = null,Object? loadStatus = null,Object? genreStatus = null,}) {
  return _then(_self.copyWith(
featured: freezed == featured ? _self.featured : featured // ignore: cast_nullable_to_non_nullable
as ContentItem?,globalTrending: null == globalTrending ? _self.globalTrending : globalTrending // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,newThisWeek: null == newThisWeek ? _self.newThisWeek : newThisWeek // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,popularMovies: null == popularMovies ? _self.popularMovies : popularMovies // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,topRatedMovies: null == topRatedMovies ? _self.topRatedMovies : topRatedMovies // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,topRatedTv: null == topRatedTv ? _self.topRatedTv : topRatedTv // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,airingToday: null == airingToday ? _self.airingToday : airingToday // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<TmdbGenre>,selectedGenre: freezed == selectedGenre ? _self.selectedGenre : selectedGenre // ignore: cast_nullable_to_non_nullable
as TmdbGenre?,genreResults: null == genreResults ? _self.genreResults : genreResults // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,genrePage: null == genrePage ? _self.genrePage : genrePage // ignore: cast_nullable_to_non_nullable
as int,genreCanLoadMore: null == genreCanLoadMore ? _self.genreCanLoadMore : genreCanLoadMore // ignore: cast_nullable_to_non_nullable
as bool,genreLoadingMore: null == genreLoadingMore ? _self.genreLoadingMore : genreLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as Status,genreStatus: null == genreStatus ? _self.genreStatus : genreStatus // ignore: cast_nullable_to_non_nullable
as Status,
  ));
}
/// Create a copy of HomeViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatusCopyWith<$Res> get loadStatus {
  
  return $StatusCopyWith<$Res>(_self.loadStatus, (value) {
    return _then(_self.copyWith(loadStatus: value));
  });
}/// Create a copy of HomeViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatusCopyWith<$Res> get genreStatus {
  
  return $StatusCopyWith<$Res>(_self.genreStatus, (value) {
    return _then(_self.copyWith(genreStatus: value));
  });
}
}


/// Adds pattern-matching-related methods to [HomeViewState].
extension HomeViewStatePatterns on HomeViewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeViewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeViewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeViewState value)  $default,){
final _that = this;
switch (_that) {
case _HomeViewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeViewState value)?  $default,){
final _that = this;
switch (_that) {
case _HomeViewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ContentItem? featured,  List<ContentItem> globalTrending,  List<ContentItem> newThisWeek,  List<ContentItem> popularMovies,  List<ContentItem> topRatedMovies,  List<ContentItem> topRatedTv,  List<ContentItem> airingToday,  List<TmdbGenre> genres,  TmdbGenre? selectedGenre,  List<ContentItem> genreResults,  int genrePage,  bool genreCanLoadMore,  bool genreLoadingMore,  Status loadStatus,  Status genreStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeViewState() when $default != null:
return $default(_that.featured,_that.globalTrending,_that.newThisWeek,_that.popularMovies,_that.topRatedMovies,_that.topRatedTv,_that.airingToday,_that.genres,_that.selectedGenre,_that.genreResults,_that.genrePage,_that.genreCanLoadMore,_that.genreLoadingMore,_that.loadStatus,_that.genreStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ContentItem? featured,  List<ContentItem> globalTrending,  List<ContentItem> newThisWeek,  List<ContentItem> popularMovies,  List<ContentItem> topRatedMovies,  List<ContentItem> topRatedTv,  List<ContentItem> airingToday,  List<TmdbGenre> genres,  TmdbGenre? selectedGenre,  List<ContentItem> genreResults,  int genrePage,  bool genreCanLoadMore,  bool genreLoadingMore,  Status loadStatus,  Status genreStatus)  $default,) {final _that = this;
switch (_that) {
case _HomeViewState():
return $default(_that.featured,_that.globalTrending,_that.newThisWeek,_that.popularMovies,_that.topRatedMovies,_that.topRatedTv,_that.airingToday,_that.genres,_that.selectedGenre,_that.genreResults,_that.genrePage,_that.genreCanLoadMore,_that.genreLoadingMore,_that.loadStatus,_that.genreStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ContentItem? featured,  List<ContentItem> globalTrending,  List<ContentItem> newThisWeek,  List<ContentItem> popularMovies,  List<ContentItem> topRatedMovies,  List<ContentItem> topRatedTv,  List<ContentItem> airingToday,  List<TmdbGenre> genres,  TmdbGenre? selectedGenre,  List<ContentItem> genreResults,  int genrePage,  bool genreCanLoadMore,  bool genreLoadingMore,  Status loadStatus,  Status genreStatus)?  $default,) {final _that = this;
switch (_that) {
case _HomeViewState() when $default != null:
return $default(_that.featured,_that.globalTrending,_that.newThisWeek,_that.popularMovies,_that.topRatedMovies,_that.topRatedTv,_that.airingToday,_that.genres,_that.selectedGenre,_that.genreResults,_that.genrePage,_that.genreCanLoadMore,_that.genreLoadingMore,_that.loadStatus,_that.genreStatus);case _:
  return null;

}
}

}

/// @nodoc


class _HomeViewState extends HomeViewState {
  const _HomeViewState({this.featured, final  List<ContentItem> globalTrending = const [], final  List<ContentItem> newThisWeek = const [], final  List<ContentItem> popularMovies = const [], final  List<ContentItem> topRatedMovies = const [], final  List<ContentItem> topRatedTv = const [], final  List<ContentItem> airingToday = const [], final  List<TmdbGenre> genres = const [], this.selectedGenre, final  List<ContentItem> genreResults = const [], this.genrePage = 1, this.genreCanLoadMore = true, this.genreLoadingMore = false, this.loadStatus = const Status.initial(), this.genreStatus = const Status.initial()}): _globalTrending = globalTrending,_newThisWeek = newThisWeek,_popularMovies = popularMovies,_topRatedMovies = topRatedMovies,_topRatedTv = topRatedTv,_airingToday = airingToday,_genres = genres,_genreResults = genreResults,super._();
  

@override final  ContentItem? featured;
 final  List<ContentItem> _globalTrending;
@override@JsonKey() List<ContentItem> get globalTrending {
  if (_globalTrending is EqualUnmodifiableListView) return _globalTrending;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_globalTrending);
}

 final  List<ContentItem> _newThisWeek;
@override@JsonKey() List<ContentItem> get newThisWeek {
  if (_newThisWeek is EqualUnmodifiableListView) return _newThisWeek;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_newThisWeek);
}

 final  List<ContentItem> _popularMovies;
@override@JsonKey() List<ContentItem> get popularMovies {
  if (_popularMovies is EqualUnmodifiableListView) return _popularMovies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_popularMovies);
}

 final  List<ContentItem> _topRatedMovies;
@override@JsonKey() List<ContentItem> get topRatedMovies {
  if (_topRatedMovies is EqualUnmodifiableListView) return _topRatedMovies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topRatedMovies);
}

 final  List<ContentItem> _topRatedTv;
@override@JsonKey() List<ContentItem> get topRatedTv {
  if (_topRatedTv is EqualUnmodifiableListView) return _topRatedTv;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topRatedTv);
}

 final  List<ContentItem> _airingToday;
@override@JsonKey() List<ContentItem> get airingToday {
  if (_airingToday is EqualUnmodifiableListView) return _airingToday;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_airingToday);
}

 final  List<TmdbGenre> _genres;
@override@JsonKey() List<TmdbGenre> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

@override final  TmdbGenre? selectedGenre;
 final  List<ContentItem> _genreResults;
@override@JsonKey() List<ContentItem> get genreResults {
  if (_genreResults is EqualUnmodifiableListView) return _genreResults;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genreResults);
}

@override@JsonKey() final  int genrePage;
@override@JsonKey() final  bool genreCanLoadMore;
@override@JsonKey() final  bool genreLoadingMore;
@override@JsonKey() final  Status loadStatus;
@override@JsonKey() final  Status genreStatus;

/// Create a copy of HomeViewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeViewStateCopyWith<_HomeViewState> get copyWith => __$HomeViewStateCopyWithImpl<_HomeViewState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeViewState&&(identical(other.featured, featured) || other.featured == featured)&&const DeepCollectionEquality().equals(other._globalTrending, _globalTrending)&&const DeepCollectionEquality().equals(other._newThisWeek, _newThisWeek)&&const DeepCollectionEquality().equals(other._popularMovies, _popularMovies)&&const DeepCollectionEquality().equals(other._topRatedMovies, _topRatedMovies)&&const DeepCollectionEquality().equals(other._topRatedTv, _topRatedTv)&&const DeepCollectionEquality().equals(other._airingToday, _airingToday)&&const DeepCollectionEquality().equals(other._genres, _genres)&&(identical(other.selectedGenre, selectedGenre) || other.selectedGenre == selectedGenre)&&const DeepCollectionEquality().equals(other._genreResults, _genreResults)&&(identical(other.genrePage, genrePage) || other.genrePage == genrePage)&&(identical(other.genreCanLoadMore, genreCanLoadMore) || other.genreCanLoadMore == genreCanLoadMore)&&(identical(other.genreLoadingMore, genreLoadingMore) || other.genreLoadingMore == genreLoadingMore)&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.genreStatus, genreStatus) || other.genreStatus == genreStatus));
}


@override
int get hashCode => Object.hash(runtimeType,featured,const DeepCollectionEquality().hash(_globalTrending),const DeepCollectionEquality().hash(_newThisWeek),const DeepCollectionEquality().hash(_popularMovies),const DeepCollectionEquality().hash(_topRatedMovies),const DeepCollectionEquality().hash(_topRatedTv),const DeepCollectionEquality().hash(_airingToday),const DeepCollectionEquality().hash(_genres),selectedGenre,const DeepCollectionEquality().hash(_genreResults),genrePage,genreCanLoadMore,genreLoadingMore,loadStatus,genreStatus);

@override
String toString() {
  return 'HomeViewState(featured: $featured, globalTrending: $globalTrending, newThisWeek: $newThisWeek, popularMovies: $popularMovies, topRatedMovies: $topRatedMovies, topRatedTv: $topRatedTv, airingToday: $airingToday, genres: $genres, selectedGenre: $selectedGenre, genreResults: $genreResults, genrePage: $genrePage, genreCanLoadMore: $genreCanLoadMore, genreLoadingMore: $genreLoadingMore, loadStatus: $loadStatus, genreStatus: $genreStatus)';
}


}

/// @nodoc
abstract mixin class _$HomeViewStateCopyWith<$Res> implements $HomeViewStateCopyWith<$Res> {
  factory _$HomeViewStateCopyWith(_HomeViewState value, $Res Function(_HomeViewState) _then) = __$HomeViewStateCopyWithImpl;
@override @useResult
$Res call({
 ContentItem? featured, List<ContentItem> globalTrending, List<ContentItem> newThisWeek, List<ContentItem> popularMovies, List<ContentItem> topRatedMovies, List<ContentItem> topRatedTv, List<ContentItem> airingToday, List<TmdbGenre> genres, TmdbGenre? selectedGenre, List<ContentItem> genreResults, int genrePage, bool genreCanLoadMore, bool genreLoadingMore, Status loadStatus, Status genreStatus
});


@override $StatusCopyWith<$Res> get loadStatus;@override $StatusCopyWith<$Res> get genreStatus;

}
/// @nodoc
class __$HomeViewStateCopyWithImpl<$Res>
    implements _$HomeViewStateCopyWith<$Res> {
  __$HomeViewStateCopyWithImpl(this._self, this._then);

  final _HomeViewState _self;
  final $Res Function(_HomeViewState) _then;

/// Create a copy of HomeViewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? featured = freezed,Object? globalTrending = null,Object? newThisWeek = null,Object? popularMovies = null,Object? topRatedMovies = null,Object? topRatedTv = null,Object? airingToday = null,Object? genres = null,Object? selectedGenre = freezed,Object? genreResults = null,Object? genrePage = null,Object? genreCanLoadMore = null,Object? genreLoadingMore = null,Object? loadStatus = null,Object? genreStatus = null,}) {
  return _then(_HomeViewState(
featured: freezed == featured ? _self.featured : featured // ignore: cast_nullable_to_non_nullable
as ContentItem?,globalTrending: null == globalTrending ? _self._globalTrending : globalTrending // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,newThisWeek: null == newThisWeek ? _self._newThisWeek : newThisWeek // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,popularMovies: null == popularMovies ? _self._popularMovies : popularMovies // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,topRatedMovies: null == topRatedMovies ? _self._topRatedMovies : topRatedMovies // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,topRatedTv: null == topRatedTv ? _self._topRatedTv : topRatedTv // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,airingToday: null == airingToday ? _self._airingToday : airingToday // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<TmdbGenre>,selectedGenre: freezed == selectedGenre ? _self.selectedGenre : selectedGenre // ignore: cast_nullable_to_non_nullable
as TmdbGenre?,genreResults: null == genreResults ? _self._genreResults : genreResults // ignore: cast_nullable_to_non_nullable
as List<ContentItem>,genrePage: null == genrePage ? _self.genrePage : genrePage // ignore: cast_nullable_to_non_nullable
as int,genreCanLoadMore: null == genreCanLoadMore ? _self.genreCanLoadMore : genreCanLoadMore // ignore: cast_nullable_to_non_nullable
as bool,genreLoadingMore: null == genreLoadingMore ? _self.genreLoadingMore : genreLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as Status,genreStatus: null == genreStatus ? _self.genreStatus : genreStatus // ignore: cast_nullable_to_non_nullable
as Status,
  ));
}

/// Create a copy of HomeViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatusCopyWith<$Res> get loadStatus {
  
  return $StatusCopyWith<$Res>(_self.loadStatus, (value) {
    return _then(_self.copyWith(loadStatus: value));
  });
}/// Create a copy of HomeViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatusCopyWith<$Res> get genreStatus {
  
  return $StatusCopyWith<$Res>(_self.genreStatus, (value) {
    return _then(_self.copyWith(genreStatus: value));
  });
}
}

// dart format on
