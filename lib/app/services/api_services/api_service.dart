import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veil/app/services/api_services/api_logger.dart';

part 'api_service.g.dart';

@riverpod
Api api(Ref ref) {
  return Api();
}

class Api {
  Api({ApiLogger? logger}) {
    final apiLogger = logger ?? ApiLogger();
    general = _createClient(apiLogger);
    profile = _createClient(apiLogger);
    tokenRefresh = _createClient(apiLogger);
  }

  late final Dio general;
  late final Dio profile;
  late final Dio tokenRefresh;

  Dio _createClient(ApiLogger logger) {
    return Dio(_baseOptions())..interceptors.add(logger);
  }

  BaseOptions _baseOptions() {
    return BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
    );
  }
}
