import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class FakePlaybackPlatform extends InAppWebViewPlatform {
  final controller = FakePlaybackController();
  late PlatformInAppWebViewWidgetCreationParams params;

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) {
    this.params = params;
    return _FakePlaybackWidget(params, controller);
  }

  InAppWebViewController get _controller =>
      InAppWebViewController.fromPlatform(platform: controller);

  Future<NavigationActionPolicy?> navigate(
    String url, {
    bool isMainFrame = true,
  }) async => params.shouldOverrideUrlLoading?.call(
    _controller,
    NavigationAction(
      request: URLRequest(url: WebUri(url)),
      isForMainFrame: isMainFrame,
    ),
  );

  void httpError(Uri url, {int statusCode = 404}) =>
      params.onReceivedHttpError?.call(
        _controller,
        WebResourceRequest(url: WebUri.uri(url)),
        WebResourceResponse(statusCode: statusCode),
      );

  void pageFinished(String url) =>
      params.onLoadStop?.call(_controller, WebUri(url));

  void mediaReady() => controller.handlers['veilMediaReady']?.call([]);

  void awaitingPlay() => controller.handlers['veilAwaitingPlay']?.call([]);

  void playRequested() => controller.handlers['veilPlayRequested']?.call([]);

  void mediaError(int code) =>
      controller.handlers['veilMediaError']?.call([code]);

  Future<WebResourceResponse?> intercept(String url) async => params
      .shouldInterceptRequest
      ?.call(_controller, WebResourceRequest(url: WebUri(url)));

  Future<bool?> popup(String url) async => params.onCreateWindow?.call(
    _controller,
    CreateWindowAction(
      windowId: 1,
      request: URLRequest(url: WebUri(url)),
      isForMainFrame: true,
    ),
  );
}

class FakePlaybackController extends PlatformInAppWebViewController {
  FakePlaybackController()
    : super.implementation(
        const PlatformInAppWebViewControllerCreationParams(id: 'test'),
      );

  final List<String> htmlLoads = [];
  final List<Uri> requestLoads = [];
  final Map<String, JavaScriptHandlerCallback> handlers = {};

  @override
  void addJavaScriptHandler({
    required String handlerName,
    required JavaScriptHandlerCallback callback,
  }) {
    handlers[handlerName] = callback;
  }

  @override
  void dispose({bool isKeepAlive = false}) {}
}

class _FakePlaybackWidget extends PlatformInAppWebViewWidget {
  _FakePlaybackWidget(
    PlatformInAppWebViewWidgetCreationParams params,
    this.controller,
  ) : super.implementation(params) {
    final data = params.initialData?.data;
    if (data != null) controller.htmlLoads.add(data);
    final url = params.initialUrlRequest?.url;
    if (url != null) controller.requestLoads.add(url.uriValue);
    params.onWebViewCreated?.call(controllerFromPlatform(controller));
  }

  final FakePlaybackController controller;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      params.controllerFromPlatform!(controller) as T;

  @override
  void dispose() {}
}
