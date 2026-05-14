import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';

class ApiLogger extends Interceptor {
  ApiLogger({this.enabled = true});

  final bool enabled;
  final int chunkSize = 20;
  final int maxWidth = 90;
  static const int kInitialTab = 1;
  final bool compact = true;
  final String tabStep = '    ';
  final String _timeStampKey = '_pdl_timeStamp_';
  final bool requestHeader = true;
  final bool requestBody = true;
  final bool responseBody = true;
  final bool responseHeader = true;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_timeStampKey] = DateTime.timestamp().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    logSuccessResponse(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logErrorResponse(err);
    handler.next(err);
  }

  void logSuccessResponse(Response<dynamic> response) {
    if (!enabled) return;
    if (requestHeader) _printRequestHeader(response.requestOptions);
    if (requestBody && response.requestOptions.method != 'GET') {
      _printRequestBody(response.requestOptions);
    }

    final triggerTime = response.requestOptions.extra[_timeStampKey];
    var diff = 0;
    if (triggerTime is int) {
      diff = DateTime.timestamp().millisecondsSinceEpoch - triggerTime;
    }
    if (responseHeader) _printResponseHeader(response, diff);
    if (responseBody) _printResponse(response);
    _printLine();
  }

  void logErrorResponse(DioException error) {
    if (!enabled) return;
    final response = error.response;
    if (requestHeader) _printRequestHeader(error.requestOptions);
    if (requestBody && error.requestOptions.method != 'GET') {
      _printRequestBody(error.requestOptions);
    }

    final triggerTime = error.requestOptions.extra[_timeStampKey];
    var diff = 0;
    if (triggerTime is int) {
      diff = DateTime.timestamp().millisecondsSinceEpoch - triggerTime;
    }

    if (response != null) {
      if (responseHeader) _printResponseHeader(response, diff);
      if (responseBody) _printResponse(response);
    } else {
      _printBoxed(
        header: 'Error ║ ${error.requestOptions.method} ║ Time: $diff ms',
        text: '${_redactedUri(error.requestOptions)} | ${error.message}',
      );
    }
    _printLine();
  }

  void _printRequestBody(RequestOptions options) {
    final dynamic data = options.data;
    if (data == null) return;
    if (data is Map) {
      _printMapAsTable(_redactedMap(data), header: 'Request Body');
    } else if (data is FormData) {
      final formDataMap = <String, dynamic>{}
        ..addEntries(data.fields)
        ..addEntries(data.files);
      _printMapAsTable(
        _redactedMap(formDataMap),
        header: 'Form data | ${data.boundary}',
      );
    } else {
      _printBlock(_redactText(data.toString()));
    }
  }

  void _printBoxed({String? header, String? text}) {
    log('');
    log('╔╣ $header');
    log('║  $text');
    _printLine('╚');
  }

  void _printResponse(Response<dynamic> response) {
    final data = response.data;
    if (data == null) return;
    if (data is Map) {
      _printPrettyMap(_redactedMap(data));
    } else if (data is Uint8List) {
      log('║${_indent()}[');
      _printUint8List(data);
      log('║${_indent()}]');
    } else if (data is List) {
      log('║${_indent()}[');
      _printList(data);
      log('║${_indent()}]');
    } else {
      _printBlock(_redactText(data.toString()));
    }
  }

  void _printResponseHeader(Response<dynamic> response, int responseTime) {
    final uri = _redactedUri(response.requestOptions);
    final method = response.requestOptions.method;
    _printBoxed(
      header:
          'Response ║ $method ║ Status: ${response.statusCode} ${response.statusMessage}  ║ Time: $responseTime ms',
      text: uri.toString(),
    );
  }

  void _printRequestHeader(RequestOptions options) {
    final uri = _redactedUri(options);
    final method = options.method;
    _printBoxed(header: 'Request ║ $method ', text: uri.toString());
    if (requestHeader && options.headers.isNotEmpty) {
      _printMapAsTable(
        _redactedMap(options.headers),
        header: 'Request Headers',
      );
    }
  }

  void _printLine([String pre = '', String suf = '╝']) =>
      log('$pre${'═' * maxWidth}$suf');

  void _printKV(String? key, Object? v) {
    final pre = '╟ $key: ';
    final msg = _redactText(v.toString());

    if (pre.length + msg.length > maxWidth) {
      log(pre);
      _printBlock(msg);
    } else {
      log('$pre$msg');
    }
  }

  void _printBlock(String msg) {
    final lines = (msg.length / maxWidth).ceil();
    for (var i = 0; i < lines; ++i) {
      log(
        '${i >= 0 ? '║ ' : ''}${msg.substring(i * maxWidth, math.min<int>(i * maxWidth + maxWidth, msg.length))}',
      );
    }
  }

  String _indent([int tabCount = kInitialTab]) => tabStep * tabCount;

  void _printPrettyMap(
    Map data, {
    int initialTab = kInitialTab,
    bool isListItem = false,
    bool isLast = false,
  }) {
    var tabs = initialTab;
    final isRoot = tabs == kInitialTab;
    final initialIndent = _indent(tabs);
    tabs++;

    if (isRoot || isListItem) log('║$initialIndent{');

    for (var index = 0; index < data.length; index++) {
      final itemIsLast = index == data.length - 1;
      final keyText = data.keys.elementAt(index).toString();
      final key = '"$keyText"';
      dynamic value = data[data.keys.elementAt(index)];
      if (_isSensitiveKey(keyText)) value = '***';
      if (value is String) {
        value = '"${_redactText(value).replaceAll(RegExp(r'([\r\n])+'), ' ')}"';
      }
      if (value is Map) {
        final redactedValue = _redactedMap(value);
        if (compact && _canFlattenMap(redactedValue)) {
          log(
            '║${_indent(tabs)} $key: $redactedValue${!itemIsLast ? ',' : ''}',
          );
        } else {
          log('║${_indent(tabs)} $key: {');
          _printPrettyMap(redactedValue, initialTab: tabs);
        }
      } else if (value is List) {
        if (compact && _canFlattenList(value)) {
          log('║${_indent(tabs)} $key: ${_redactText(value.toString())}');
        } else {
          log('║${_indent(tabs)} $key: [');
          _printList(value, tabs: tabs);
          log('║${_indent(tabs)} ]${itemIsLast ? '' : ','}');
        }
      } else {
        final msg = _redactText(value.toString()).replaceAll('\n', '');
        final indent = _indent(tabs);
        final lineWidth = maxWidth - indent.length;
        if (msg.length + indent.length > lineWidth) {
          final lines = (msg.length / lineWidth).ceil();
          for (var i = 0; i < lines; ++i) {
            final multilineKey = i == 0 ? '$key:' : '';
            log(
              '║${_indent(tabs)} $multilineKey ${msg.substring(i * lineWidth, math.min<int>(i * lineWidth + lineWidth, msg.length))}',
            );
          }
        } else {
          log('║${_indent(tabs)} $key: $msg${!itemIsLast ? ',' : ''}');
        }
      }
    }

    log('║$initialIndent}${isListItem && !isLast ? ',' : ''}');
  }

  void _printList(List list, {int tabs = kInitialTab}) {
    for (var i = 0; i < list.length; i++) {
      final element = list[i];
      final isLast = i == list.length - 1;
      if (element is Map) {
        final redactedElement = _redactedMap(element);
        if (compact && _canFlattenMap(redactedElement)) {
          log('║${_indent(tabs)}  $redactedElement${!isLast ? ',' : ''}');
        } else {
          _printPrettyMap(
            redactedElement,
            initialTab: tabs + 1,
            isListItem: true,
            isLast: isLast,
          );
        }
      } else {
        log(
          '║${_indent(tabs + 2)} ${_redactText(element.toString())}${isLast ? '' : ','}',
        );
      }
    }
  }

  void _printUint8List(Uint8List list, {int tabs = kInitialTab}) {
    final chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    for (final element in chunks) {
      log('║${_indent(tabs)} ${element.join(', ')}');
    }
  }

  bool _canFlattenMap(Map map) {
    return map.values
            .where((dynamic val) => val is Map || val is List)
            .isEmpty &&
        map.toString().length < maxWidth;
  }

  bool _canFlattenList(List list) {
    return list.length < 10 && list.toString().length < maxWidth;
  }

  void _printMapAsTable(Map? map, {String? header}) {
    if (map == null || map.isEmpty) return;
    log('╔ $header ');
    for (final entry in map.entries) {
      _printKV(entry.key.toString(), entry.value);
    }
    _printLine('╚');
  }

  Uri _redactedUri(RequestOptions options) {
    final uri = options.uri;
    if (uri.queryParametersAll.isEmpty) return uri;

    return uri.replace(
      queryParameters: {
        for (final entry in uri.queryParametersAll.entries)
          entry.key: _isSensitiveKey(entry.key)
              ? '***'
              : entry.value.length == 1
              ? entry.value.single
              : entry.value,
      },
    );
  }

  Map<dynamic, dynamic> _redactedMap(Map<dynamic, dynamic> map) {
    return map.map((key, value) {
      if (_isSensitiveKey(key.toString())) return MapEntry(key, '***');
      if (value is Map) return MapEntry(key, _redactedMap(value));
      if (value is List) {
        return MapEntry(
          key,
          value.map((item) => item is Map ? _redactedMap(item) : item).toList(),
        );
      }
      if (value is String) return MapEntry(key, _redactText(value));
      return MapEntry(key, value);
    });
  }

  bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('authorization') ||
        normalized.contains('api_key') ||
        normalized.contains('apikey') ||
        normalized.contains('token') ||
        normalized.contains('password') ||
        normalized.contains('secret');
  }

  String _redactText(String text) {
    return text
        .replaceAll(RegExp(r'api_key=[^&\s]+'), 'api_key=***')
        .replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9._-]+'), 'Bearer ***');
  }
}
