// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Status {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Status);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Status()';
}


}

/// @nodoc
class $StatusCopyWith<$Res>  {
$StatusCopyWith(Status _, $Res Function(Status) __);
}


/// Adds pattern-matching-related methods to [Status].
extension StatusPatterns on Status {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StatusInitial value)?  initial,TResult Function( StatusLoading value)?  loading,TResult Function( StatusTemporary value)?  temporary,TResult Function( StatusSuccess value)?  success,TResult Function( StatusFailure value)?  failure,TResult Function( StatusAuthFailure value)?  authFailure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StatusInitial() when initial != null:
return initial(_that);case StatusLoading() when loading != null:
return loading(_that);case StatusTemporary() when temporary != null:
return temporary(_that);case StatusSuccess() when success != null:
return success(_that);case StatusFailure() when failure != null:
return failure(_that);case StatusAuthFailure() when authFailure != null:
return authFailure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StatusInitial value)  initial,required TResult Function( StatusLoading value)  loading,required TResult Function( StatusTemporary value)  temporary,required TResult Function( StatusSuccess value)  success,required TResult Function( StatusFailure value)  failure,required TResult Function( StatusAuthFailure value)  authFailure,}){
final _that = this;
switch (_that) {
case StatusInitial():
return initial(_that);case StatusLoading():
return loading(_that);case StatusTemporary():
return temporary(_that);case StatusSuccess():
return success(_that);case StatusFailure():
return failure(_that);case StatusAuthFailure():
return authFailure(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StatusInitial value)?  initial,TResult? Function( StatusLoading value)?  loading,TResult? Function( StatusTemporary value)?  temporary,TResult? Function( StatusSuccess value)?  success,TResult? Function( StatusFailure value)?  failure,TResult? Function( StatusAuthFailure value)?  authFailure,}){
final _that = this;
switch (_that) {
case StatusInitial() when initial != null:
return initial(_that);case StatusLoading() when loading != null:
return loading(_that);case StatusTemporary() when temporary != null:
return temporary(_that);case StatusSuccess() when success != null:
return success(_that);case StatusFailure() when failure != null:
return failure(_that);case StatusAuthFailure() when authFailure != null:
return authFailure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function()?  temporary,TResult Function( dynamic data)?  success,TResult Function( String errorMessage)?  failure,TResult Function( String errorMessage)?  authFailure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StatusInitial() when initial != null:
return initial();case StatusLoading() when loading != null:
return loading();case StatusTemporary() when temporary != null:
return temporary();case StatusSuccess() when success != null:
return success(_that.data);case StatusFailure() when failure != null:
return failure(_that.errorMessage);case StatusAuthFailure() when authFailure != null:
return authFailure(_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function()  temporary,required TResult Function( dynamic data)  success,required TResult Function( String errorMessage)  failure,required TResult Function( String errorMessage)  authFailure,}) {final _that = this;
switch (_that) {
case StatusInitial():
return initial();case StatusLoading():
return loading();case StatusTemporary():
return temporary();case StatusSuccess():
return success(_that.data);case StatusFailure():
return failure(_that.errorMessage);case StatusAuthFailure():
return authFailure(_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function()?  temporary,TResult? Function( dynamic data)?  success,TResult? Function( String errorMessage)?  failure,TResult? Function( String errorMessage)?  authFailure,}) {final _that = this;
switch (_that) {
case StatusInitial() when initial != null:
return initial();case StatusLoading() when loading != null:
return loading();case StatusTemporary() when temporary != null:
return temporary();case StatusSuccess() when success != null:
return success(_that.data);case StatusFailure() when failure != null:
return failure(_that.errorMessage);case StatusAuthFailure() when authFailure != null:
return authFailure(_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class StatusInitial extends Status {
  const StatusInitial(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Status.initial()';
}


}




/// @nodoc


class StatusLoading extends Status {
  const StatusLoading(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Status.loading()';
}


}




/// @nodoc


class StatusTemporary extends Status {
  const StatusTemporary(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusTemporary);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Status.temporary()';
}


}




/// @nodoc


class StatusSuccess extends Status {
  const StatusSuccess({this.data}): super._();
  

 final  dynamic data;

/// Create a copy of Status
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatusSuccessCopyWith<StatusSuccess> get copyWith => _$StatusSuccessCopyWithImpl<StatusSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusSuccess&&const DeepCollectionEquality().equals(other.data, data));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'Status.success(data: $data)';
}


}

/// @nodoc
abstract mixin class $StatusSuccessCopyWith<$Res> implements $StatusCopyWith<$Res> {
  factory $StatusSuccessCopyWith(StatusSuccess value, $Res Function(StatusSuccess) _then) = _$StatusSuccessCopyWithImpl;
@useResult
$Res call({
 dynamic data
});




}
/// @nodoc
class _$StatusSuccessCopyWithImpl<$Res>
    implements $StatusSuccessCopyWith<$Res> {
  _$StatusSuccessCopyWithImpl(this._self, this._then);

  final StatusSuccess _self;
  final $Res Function(StatusSuccess) _then;

/// Create a copy of Status
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = freezed,}) {
  return _then(StatusSuccess(
data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}


}

/// @nodoc


class StatusFailure extends Status {
  const StatusFailure(this.errorMessage): super._();
  

 final  String errorMessage;

/// Create a copy of Status
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatusFailureCopyWith<StatusFailure> get copyWith => _$StatusFailureCopyWithImpl<StatusFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusFailure&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,errorMessage);

@override
String toString() {
  return 'Status.failure(errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $StatusFailureCopyWith<$Res> implements $StatusCopyWith<$Res> {
  factory $StatusFailureCopyWith(StatusFailure value, $Res Function(StatusFailure) _then) = _$StatusFailureCopyWithImpl;
@useResult
$Res call({
 String errorMessage
});




}
/// @nodoc
class _$StatusFailureCopyWithImpl<$Res>
    implements $StatusFailureCopyWith<$Res> {
  _$StatusFailureCopyWithImpl(this._self, this._then);

  final StatusFailure _self;
  final $Res Function(StatusFailure) _then;

/// Create a copy of Status
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorMessage = null,}) {
  return _then(StatusFailure(
null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StatusAuthFailure extends Status {
  const StatusAuthFailure(this.errorMessage): super._();
  

 final  String errorMessage;

/// Create a copy of Status
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatusAuthFailureCopyWith<StatusAuthFailure> get copyWith => _$StatusAuthFailureCopyWithImpl<StatusAuthFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusAuthFailure&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,errorMessage);

@override
String toString() {
  return 'Status.authFailure(errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $StatusAuthFailureCopyWith<$Res> implements $StatusCopyWith<$Res> {
  factory $StatusAuthFailureCopyWith(StatusAuthFailure value, $Res Function(StatusAuthFailure) _then) = _$StatusAuthFailureCopyWithImpl;
@useResult
$Res call({
 String errorMessage
});




}
/// @nodoc
class _$StatusAuthFailureCopyWithImpl<$Res>
    implements $StatusAuthFailureCopyWith<$Res> {
  _$StatusAuthFailureCopyWithImpl(this._self, this._then);

  final StatusAuthFailure _self;
  final $Res Function(StatusAuthFailure) _then;

/// Create a copy of Status
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorMessage = null,}) {
  return _then(StatusAuthFailure(
null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
