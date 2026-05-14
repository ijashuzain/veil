// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'detail_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DetailViewState {

 ContentDetail get detail; int? get trendingRank; Status get loadStatus;
/// Create a copy of DetailViewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetailViewStateCopyWith<DetailViewState> get copyWith => _$DetailViewStateCopyWithImpl<DetailViewState>(this as DetailViewState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetailViewState&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.trendingRank, trendingRank) || other.trendingRank == trendingRank)&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus));
}


@override
int get hashCode => Object.hash(runtimeType,detail,trendingRank,loadStatus);

@override
String toString() {
  return 'DetailViewState(detail: $detail, trendingRank: $trendingRank, loadStatus: $loadStatus)';
}


}

/// @nodoc
abstract mixin class $DetailViewStateCopyWith<$Res>  {
  factory $DetailViewStateCopyWith(DetailViewState value, $Res Function(DetailViewState) _then) = _$DetailViewStateCopyWithImpl;
@useResult
$Res call({
 ContentDetail detail, int? trendingRank, Status loadStatus
});


$ContentDetailCopyWith<$Res> get detail;$StatusCopyWith<$Res> get loadStatus;

}
/// @nodoc
class _$DetailViewStateCopyWithImpl<$Res>
    implements $DetailViewStateCopyWith<$Res> {
  _$DetailViewStateCopyWithImpl(this._self, this._then);

  final DetailViewState _self;
  final $Res Function(DetailViewState) _then;

/// Create a copy of DetailViewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? detail = null,Object? trendingRank = freezed,Object? loadStatus = null,}) {
  return _then(_self.copyWith(
detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as ContentDetail,trendingRank: freezed == trendingRank ? _self.trendingRank : trendingRank // ignore: cast_nullable_to_non_nullable
as int?,loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as Status,
  ));
}
/// Create a copy of DetailViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContentDetailCopyWith<$Res> get detail {
  
  return $ContentDetailCopyWith<$Res>(_self.detail, (value) {
    return _then(_self.copyWith(detail: value));
  });
}/// Create a copy of DetailViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatusCopyWith<$Res> get loadStatus {
  
  return $StatusCopyWith<$Res>(_self.loadStatus, (value) {
    return _then(_self.copyWith(loadStatus: value));
  });
}
}


/// Adds pattern-matching-related methods to [DetailViewState].
extension DetailViewStatePatterns on DetailViewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DetailViewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DetailViewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DetailViewState value)  $default,){
final _that = this;
switch (_that) {
case _DetailViewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DetailViewState value)?  $default,){
final _that = this;
switch (_that) {
case _DetailViewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ContentDetail detail,  int? trendingRank,  Status loadStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DetailViewState() when $default != null:
return $default(_that.detail,_that.trendingRank,_that.loadStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ContentDetail detail,  int? trendingRank,  Status loadStatus)  $default,) {final _that = this;
switch (_that) {
case _DetailViewState():
return $default(_that.detail,_that.trendingRank,_that.loadStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ContentDetail detail,  int? trendingRank,  Status loadStatus)?  $default,) {final _that = this;
switch (_that) {
case _DetailViewState() when $default != null:
return $default(_that.detail,_that.trendingRank,_that.loadStatus);case _:
  return null;

}
}

}

/// @nodoc


class _DetailViewState extends DetailViewState {
  const _DetailViewState({required this.detail, this.trendingRank, this.loadStatus = const Status.initial()}): super._();
  

@override final  ContentDetail detail;
@override final  int? trendingRank;
@override@JsonKey() final  Status loadStatus;

/// Create a copy of DetailViewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DetailViewStateCopyWith<_DetailViewState> get copyWith => __$DetailViewStateCopyWithImpl<_DetailViewState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DetailViewState&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.trendingRank, trendingRank) || other.trendingRank == trendingRank)&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus));
}


@override
int get hashCode => Object.hash(runtimeType,detail,trendingRank,loadStatus);

@override
String toString() {
  return 'DetailViewState(detail: $detail, trendingRank: $trendingRank, loadStatus: $loadStatus)';
}


}

/// @nodoc
abstract mixin class _$DetailViewStateCopyWith<$Res> implements $DetailViewStateCopyWith<$Res> {
  factory _$DetailViewStateCopyWith(_DetailViewState value, $Res Function(_DetailViewState) _then) = __$DetailViewStateCopyWithImpl;
@override @useResult
$Res call({
 ContentDetail detail, int? trendingRank, Status loadStatus
});


@override $ContentDetailCopyWith<$Res> get detail;@override $StatusCopyWith<$Res> get loadStatus;

}
/// @nodoc
class __$DetailViewStateCopyWithImpl<$Res>
    implements _$DetailViewStateCopyWith<$Res> {
  __$DetailViewStateCopyWithImpl(this._self, this._then);

  final _DetailViewState _self;
  final $Res Function(_DetailViewState) _then;

/// Create a copy of DetailViewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? detail = null,Object? trendingRank = freezed,Object? loadStatus = null,}) {
  return _then(_DetailViewState(
detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as ContentDetail,trendingRank: freezed == trendingRank ? _self.trendingRank : trendingRank // ignore: cast_nullable_to_non_nullable
as int?,loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as Status,
  ));
}

/// Create a copy of DetailViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContentDetailCopyWith<$Res> get detail {
  
  return $ContentDetailCopyWith<$Res>(_self.detail, (value) {
    return _then(_self.copyWith(detail: value));
  });
}/// Create a copy of DetailViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatusCopyWith<$Res> get loadStatus {
  
  return $StatusCopyWith<$Res>(_self.loadStatus, (value) {
    return _then(_self.copyWith(loadStatus: value));
  });
}
}

// dart format on
