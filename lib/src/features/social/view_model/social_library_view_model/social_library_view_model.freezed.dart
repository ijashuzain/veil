// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'social_library_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SocialLibraryViewState {

 List<SocialEntry> get entries; List<SocialEntry> get globalReviews; Status get loadStatus; Status get saveStatus;
/// Create a copy of SocialLibraryViewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocialLibraryViewStateCopyWith<SocialLibraryViewState> get copyWith => _$SocialLibraryViewStateCopyWithImpl<SocialLibraryViewState>(this as SocialLibraryViewState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocialLibraryViewState&&const DeepCollectionEquality().equals(other.entries, entries)&&const DeepCollectionEquality().equals(other.globalReviews, globalReviews)&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.saveStatus, saveStatus) || other.saveStatus == saveStatus));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(entries),const DeepCollectionEquality().hash(globalReviews),loadStatus,saveStatus);

@override
String toString() {
  return 'SocialLibraryViewState(entries: $entries, globalReviews: $globalReviews, loadStatus: $loadStatus, saveStatus: $saveStatus)';
}


}

/// @nodoc
abstract mixin class $SocialLibraryViewStateCopyWith<$Res>  {
  factory $SocialLibraryViewStateCopyWith(SocialLibraryViewState value, $Res Function(SocialLibraryViewState) _then) = _$SocialLibraryViewStateCopyWithImpl;
@useResult
$Res call({
 List<SocialEntry> entries, List<SocialEntry> globalReviews, Status loadStatus, Status saveStatus
});


$StatusCopyWith<$Res> get loadStatus;$StatusCopyWith<$Res> get saveStatus;

}
/// @nodoc
class _$SocialLibraryViewStateCopyWithImpl<$Res>
    implements $SocialLibraryViewStateCopyWith<$Res> {
  _$SocialLibraryViewStateCopyWithImpl(this._self, this._then);

  final SocialLibraryViewState _self;
  final $Res Function(SocialLibraryViewState) _then;

/// Create a copy of SocialLibraryViewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entries = null,Object? globalReviews = null,Object? loadStatus = null,Object? saveStatus = null,}) {
  return _then(_self.copyWith(
entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<SocialEntry>,globalReviews: null == globalReviews ? _self.globalReviews : globalReviews // ignore: cast_nullable_to_non_nullable
as List<SocialEntry>,loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as Status,saveStatus: null == saveStatus ? _self.saveStatus : saveStatus // ignore: cast_nullable_to_non_nullable
as Status,
  ));
}
/// Create a copy of SocialLibraryViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatusCopyWith<$Res> get loadStatus {
  
  return $StatusCopyWith<$Res>(_self.loadStatus, (value) {
    return _then(_self.copyWith(loadStatus: value));
  });
}/// Create a copy of SocialLibraryViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatusCopyWith<$Res> get saveStatus {
  
  return $StatusCopyWith<$Res>(_self.saveStatus, (value) {
    return _then(_self.copyWith(saveStatus: value));
  });
}
}


/// Adds pattern-matching-related methods to [SocialLibraryViewState].
extension SocialLibraryViewStatePatterns on SocialLibraryViewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SocialLibraryViewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SocialLibraryViewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SocialLibraryViewState value)  $default,){
final _that = this;
switch (_that) {
case _SocialLibraryViewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SocialLibraryViewState value)?  $default,){
final _that = this;
switch (_that) {
case _SocialLibraryViewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SocialEntry> entries,  List<SocialEntry> globalReviews,  Status loadStatus,  Status saveStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SocialLibraryViewState() when $default != null:
return $default(_that.entries,_that.globalReviews,_that.loadStatus,_that.saveStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SocialEntry> entries,  List<SocialEntry> globalReviews,  Status loadStatus,  Status saveStatus)  $default,) {final _that = this;
switch (_that) {
case _SocialLibraryViewState():
return $default(_that.entries,_that.globalReviews,_that.loadStatus,_that.saveStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SocialEntry> entries,  List<SocialEntry> globalReviews,  Status loadStatus,  Status saveStatus)?  $default,) {final _that = this;
switch (_that) {
case _SocialLibraryViewState() when $default != null:
return $default(_that.entries,_that.globalReviews,_that.loadStatus,_that.saveStatus);case _:
  return null;

}
}

}

/// @nodoc


class _SocialLibraryViewState extends SocialLibraryViewState {
  const _SocialLibraryViewState({final  List<SocialEntry> entries = const [], final  List<SocialEntry> globalReviews = const [], this.loadStatus = const Status.initial(), this.saveStatus = const Status.initial()}): _entries = entries,_globalReviews = globalReviews,super._();
  

 final  List<SocialEntry> _entries;
@override@JsonKey() List<SocialEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

 final  List<SocialEntry> _globalReviews;
@override@JsonKey() List<SocialEntry> get globalReviews {
  if (_globalReviews is EqualUnmodifiableListView) return _globalReviews;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_globalReviews);
}

@override@JsonKey() final  Status loadStatus;
@override@JsonKey() final  Status saveStatus;

/// Create a copy of SocialLibraryViewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SocialLibraryViewStateCopyWith<_SocialLibraryViewState> get copyWith => __$SocialLibraryViewStateCopyWithImpl<_SocialLibraryViewState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SocialLibraryViewState&&const DeepCollectionEquality().equals(other._entries, _entries)&&const DeepCollectionEquality().equals(other._globalReviews, _globalReviews)&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.saveStatus, saveStatus) || other.saveStatus == saveStatus));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_globalReviews),loadStatus,saveStatus);

@override
String toString() {
  return 'SocialLibraryViewState(entries: $entries, globalReviews: $globalReviews, loadStatus: $loadStatus, saveStatus: $saveStatus)';
}


}

/// @nodoc
abstract mixin class _$SocialLibraryViewStateCopyWith<$Res> implements $SocialLibraryViewStateCopyWith<$Res> {
  factory _$SocialLibraryViewStateCopyWith(_SocialLibraryViewState value, $Res Function(_SocialLibraryViewState) _then) = __$SocialLibraryViewStateCopyWithImpl;
@override @useResult
$Res call({
 List<SocialEntry> entries, List<SocialEntry> globalReviews, Status loadStatus, Status saveStatus
});


@override $StatusCopyWith<$Res> get loadStatus;@override $StatusCopyWith<$Res> get saveStatus;

}
/// @nodoc
class __$SocialLibraryViewStateCopyWithImpl<$Res>
    implements _$SocialLibraryViewStateCopyWith<$Res> {
  __$SocialLibraryViewStateCopyWithImpl(this._self, this._then);

  final _SocialLibraryViewState _self;
  final $Res Function(_SocialLibraryViewState) _then;

/// Create a copy of SocialLibraryViewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entries = null,Object? globalReviews = null,Object? loadStatus = null,Object? saveStatus = null,}) {
  return _then(_SocialLibraryViewState(
entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<SocialEntry>,globalReviews: null == globalReviews ? _self._globalReviews : globalReviews // ignore: cast_nullable_to_non_nullable
as List<SocialEntry>,loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as Status,saveStatus: null == saveStatus ? _self.saveStatus : saveStatus // ignore: cast_nullable_to_non_nullable
as Status,
  ));
}

/// Create a copy of SocialLibraryViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatusCopyWith<$Res> get loadStatus {
  
  return $StatusCopyWith<$Res>(_self.loadStatus, (value) {
    return _then(_self.copyWith(loadStatus: value));
  });
}/// Create a copy of SocialLibraryViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatusCopyWith<$Res> get saveStatus {
  
  return $StatusCopyWith<$Res>(_self.saveStatus, (value) {
    return _then(_self.copyWith(saveStatus: value));
  });
}
}

// dart format on
