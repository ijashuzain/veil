// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:veil/src/features/detail/utils/playback_entry_url.dart';

@JS('window.location.assign')
external void _assignLocation(JSString url);

Future<bool> openExternalPlayer(String url) {
  return openExternalPlayerCandidates([Uri.parse(url)]);
}

Future<bool> openExternalPlayerCandidates(List<Uri> urls) async {
  final launchUrl = await firstNon404PlaybackLaunchUrl(
    urls: urls,
    statusCodeForUrl: _directStatusCodeForUrl,
    responseBodyForUrl: _responseBodyForUrl,
  );
  if (launchUrl == null) return false;

  _assignLocation(launchUrl.toString().toJS);
  return true;
}

Future<int?> _directStatusCodeForUrl(Uri url) async {
  try {
    final response = await html.HttpRequest.request(
      url.toString(),
      method: 'HEAD',
      withCredentials: false,
    ).timeout(const Duration(seconds: 2));
    return response.status;
  } catch (error) {
    debugPrint('Cannot directly pre-check player URL ${url.host}: $error');
    return null;
  }
}

Future<String?> _responseBodyForUrl(Uri url) async {
  final allOriginsBody = await _allOriginsBodyForUrl(url);
  if (allOriginsBody != null) return allOriginsBody;

  return _jinaBodyForUrl(url);
}

Future<String?> _allOriginsBodyForUrl(Uri url) async {
  try {
    final proxyUrl = Uri.https('api.allorigins.win', '/get', {
      'url': url.toString(),
    });
    final response = await html.HttpRequest.request(
      proxyUrl.toString(),
      method: 'GET',
      withCredentials: false,
    ).timeout(const Duration(seconds: 5));
    final body = response.responseText;
    if (body == null || body.isEmpty) return null;

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;

    final contents = decoded['contents'];
    if (contents is String) return contents;
  } catch (error) {
    debugPrint('Cannot AllOrigins pre-check player URL ${url.host}: $error');
  }

  return null;
}

Future<String?> _jinaBodyForUrl(Uri url) async {
  try {
    final proxyUrl = Uri.parse('https://r.jina.ai/http://${url.toString()}');
    final response = await html.HttpRequest.request(
      proxyUrl.toString(),
      method: 'GET',
      withCredentials: false,
    ).timeout(const Duration(seconds: 5));
    final body = response.responseText;
    if (body != null && body.isNotEmpty) return body;
  } catch (error) {
    debugPrint('Cannot Jina pre-check player URL ${url.host}: $error');
  }

  return null;
}
