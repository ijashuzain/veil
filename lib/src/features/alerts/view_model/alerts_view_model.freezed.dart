// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alerts_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlertsViewState {

 List<AlertItem> get alerts; List<FollowRequest> get followRequests; List<MovieSuggestion> get suggestions; Status get loadStatus;
/// Create a copy of AlertsViewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlertsViewStateCopyWith<AlertsViewState> get copyWith => _$AlertsViewStateCopyWithImpl<AlertsViewState>(this as AlertsViewState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlertsViewState&&const DeepCollectionEquality().equals(other.alerts, alerts)&&const DeepCollectionEquality().equals(other.followRequests, followRequests)&&const DeepCollectionEquality().equals(other.suggestions, suggestions)&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(alerts),const DeepCollectionEquality().hash(followRequests),const DeepCollectionEquality().hash(suggestions),loadStatus);

@override
String toString() {
  return 'AlertsViewState(alerts: $alerts, followRequests: $followRequests, suggestions: $suggestions, loadStatus: $loadStatus)';
}


}

/// @nodoc
abstract mixin class $AlertsViewStateCopyWith<$Res>  {
  factory $AlertsViewStateCopyWith(AlertsViewState value, $Res Function(AlertsViewState) _then) = _$AlertsViewStateCopyWithImpl;
@useResult
$Res call({
 List<AlertItem> alerts, List<FollowRequest> followRequests, List<MovieSuggestion> suggestions, Status loadStatus
});


$StatusCopyWith<$Res> get loadStatus;

}
/// @nodoc
class _$AlertsViewStateCopyWithImpl<$Res>
    implements $AlertsViewStateCopyWith<$Res> {
  _$AlertsViewStateCopyWithImpl(this._self, this._then);

  final AlertsViewState _self;
  final $Res Function(AlertsViewState) _then;

/// Create a copy of AlertsViewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? alerts = null,Object? followRequests = null,Object? suggestions = null,Object? loadStatus = null,}) {
  return _then(_self.copyWith(
alerts: null == alerts ? _self.alerts : alerts // ignore: cast_nullable_to_non_nullable
as List<AlertItem>,followRequests: null == followRequests ? _self.followRequests : followRequests // ignore: cast_nullable_to_non_nullable
as List<FollowRequest>,suggestions: null == suggestions ? _self.suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<MovieSuggestion>,loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as Status,
  ));
}
/// Create a copy of AlertsViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatusCopyWith<$Res> get loadStatus {
  
  return $StatusCopyWith<$Res>(_self.loadStatus, (value) {
    return _then(_self.copyWith(loadStatus: value));
  });
}
}


/// Adds pattern-matching-related methods to [AlertsViewState].
extension AlertsViewStatePatterns on AlertsViewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AlertsViewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AlertsViewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AlertsViewState value)  $default,){
final _that = this;
switch (_that) {
case _AlertsViewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AlertsViewState value)?  $default,){
final _that = this;
switch (_that) {
case _AlertsViewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AlertItem> alerts,  List<FollowRequest> followRequests,  List<MovieSuggestion> suggestions,  Status loadStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AlertsViewState() when $default != null:
return $default(_that.alerts,_that.followRequests,_that.suggestions,_that.loadStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AlertItem> alerts,  List<FollowRequest> followRequests,  List<MovieSuggestion> suggestions,  Status loadStatus)  $default,) {final _that = this;
switch (_that) {
case _AlertsViewState():
return $default(_that.alerts,_that.followRequests,_that.suggestions,_that.loadStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AlertItem> alerts,  List<FollowRequest> followRequests,  List<MovieSuggestion> suggestions,  Status loadStatus)?  $default,) {final _that = this;
switch (_that) {
case _AlertsViewState() when $default != null:
return $default(_that.alerts,_that.followRequests,_that.suggestions,_that.loadStatus);case _:
  return null;

}
}

}

/// @nodoc


class _AlertsViewState extends AlertsViewState {
  const _AlertsViewState({final  List<AlertItem> alerts = const [], final  List<FollowRequest> followRequests = const [], final  List<MovieSuggestion> suggestions = const [], this.loadStatus = const Status.initial()}): _alerts = alerts,_followRequests = followRequests,_suggestions = suggestions,super._();
  

 final  List<AlertItem> _alerts;
@override@JsonKey() List<AlertItem> get alerts {
  if (_alerts is EqualUnmodifiableListView) return _alerts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alerts);
}

 final  List<FollowRequest> _followRequests;
@override@JsonKey() List<FollowRequest> get followRequests {
  if (_followRequests is EqualUnmodifiableListView) return _followRequests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_followRequests);
}

 final  List<MovieSuggestion> _suggestions;
@override@JsonKey() List<MovieSuggestion> get suggestions {
  if (_suggestions is EqualUnmodifiableListView) return _suggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_suggestions);
}

@override@JsonKey() final  Status loadStatus;

/// Create a copy of AlertsViewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlertsViewStateCopyWith<_AlertsViewState> get copyWith => __$AlertsViewStateCopyWithImpl<_AlertsViewState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AlertsViewState&&const DeepCollectionEquality().equals(other._alerts, _alerts)&&const DeepCollectionEquality().equals(other._followRequests, _followRequests)&&const DeepCollectionEquality().equals(other._suggestions, _suggestions)&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_alerts),const DeepCollectionEquality().hash(_followRequests),const DeepCollectionEquality().hash(_suggestions),loadStatus);

@override
String toString() {
  return 'AlertsViewState(alerts: $alerts, followRequests: $followRequests, suggestions: $suggestions, loadStatus: $loadStatus)';
}


}

/// @nodoc
abstract mixin class _$AlertsViewStateCopyWith<$Res> implements $AlertsViewStateCopyWith<$Res> {
  factory _$AlertsViewStateCopyWith(_AlertsViewState value, $Res Function(_AlertsViewState) _then) = __$AlertsViewStateCopyWithImpl;
@override @useResult
$Res call({
 List<AlertItem> alerts, List<FollowRequest> followRequests, List<MovieSuggestion> suggestions, Status loadStatus
});


@override $StatusCopyWith<$Res> get loadStatus;

}
/// @nodoc
class __$AlertsViewStateCopyWithImpl<$Res>
    implements _$AlertsViewStateCopyWith<$Res> {
  __$AlertsViewStateCopyWithImpl(this._self, this._then);

  final _AlertsViewState _self;
  final $Res Function(_AlertsViewState) _then;

/// Create a copy of AlertsViewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? alerts = null,Object? followRequests = null,Object? suggestions = null,Object? loadStatus = null,}) {
  return _then(_AlertsViewState(
alerts: null == alerts ? _self._alerts : alerts // ignore: cast_nullable_to_non_nullable
as List<AlertItem>,followRequests: null == followRequests ? _self._followRequests : followRequests // ignore: cast_nullable_to_non_nullable
as List<FollowRequest>,suggestions: null == suggestions ? _self._suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<MovieSuggestion>,loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as Status,
  ));
}

/// Create a copy of AlertsViewState
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
