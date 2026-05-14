import 'package:freezed_annotation/freezed_annotation.dart';

part 'status.freezed.dart';

@freezed
abstract class Status with _$Status {
  const Status._();

  const factory Status.initial() = StatusInitial;
  const factory Status.loading() = StatusLoading;
  const factory Status.temporary() = StatusTemporary;
  const factory Status.success({dynamic data}) = StatusSuccess;
  const factory Status.failure(String errorMessage) = StatusFailure;
  const factory Status.authFailure(String errorMessage) = StatusAuthFailure;

  dynamic get data => maybeWhen(success: (data) => data, orElse: () => null);

  String get errorMessage => maybeWhen(
    failure: (message) => message,
    authFailure: (message) => message,
    orElse: () => '',
  );
}
