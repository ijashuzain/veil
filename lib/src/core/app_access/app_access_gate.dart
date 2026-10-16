import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_access_config.dart';
import 'app_access_repository.dart';

class AppAccessGate extends StatefulWidget {
  const AppAccessGate({
    super.key,
    required this.child,
    this.load,
    this.readBuild,
    this.openStore,
    this.onAllowed,
    this.platform,
    this.web,
  });
  final Widget child;
  final Future<AppAccessConfig> Function()? load;
  final Future<String> Function()? readBuild;
  final Future<bool> Function(Uri)? openStore;
  final VoidCallback? onAllowed;
  final TargetPlatform? platform;
  final bool? web;

  @override
  State<AppAccessGate> createState() => _AppAccessGateState();
}

class _AppAccessGateState extends State<AppAccessGate>
    with WidgetsBindingObserver {
  late final _repository = AppAccessRepository();
  AppAccessConfig _config = const AppAccessConfig();
  AppAccessStatus _status = AppAccessStatus.allowed;
  bool _initializing = true;
  bool _checking = false;
  bool _openingStore = false;
  bool _active = true;
  bool _allowedNotified = false;
  String? _storeError;
  String? _build;
  Timer? _retryTimer;

  TargetPlatform get _platform => widget.platform ?? defaultTargetPlatform;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      unawaited(_check());
    } else {
      _retryTimer?.cancel();
    }
  }

  Future<String> _readBuild() async {
    try {
      return await (widget.readBuild?.call() ??
              PackageInfo.fromPlatform().then((info) => info.buildNumber))
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      return '';
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    _retryTimer?.cancel();
    setState(() => _checking = true);
    final buildFuture = _build == null || _build!.isEmpty
        ? _readBuild()
        : Future.value(_build!);
    AppAccessConfig config;
    try {
      config = await (widget.load?.call() ?? _repository.load());
    } catch (_) {
      config = _config;
    }
    final build = await buildFuture;
    if (!mounted) return;
    setState(() {
      _build = build;
      _config = config;
      _status = config.status(
        platform: _platform,
        build: build,
        web: widget.web ?? kIsWeb,
      );
      _initializing = false;
      _checking = false;
    });
    if (_status == AppAccessStatus.allowed) {
      if (!_allowedNotified) {
        _allowedNotified = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _status == AppAccessStatus.allowed) {
            widget.onAllowed?.call();
          }
        });
      }
    } else {
      _allowedNotified = false;
      if (_active) {
        _retryTimer = Timer(
          const Duration(minutes: 1),
          () => unawaited(_check()),
        );
      }
    }
  }

  Future<void> _update() async {
    final url = _config.storeUrl(_platform);
    if (url == null || _openingStore) return;
    setState(() {
      _openingStore = true;
      _storeError = null;
    });
    var opened = false;
    try {
      opened =
          await (widget.openStore?.call(url) ??
              launchUrl(url, mode: LaunchMode.externalApplication));
    } catch (_) {
      /* Show a retryable error below. */
    }
    if (!mounted) return;
    setState(() {
      _openingStore = false;
      if (!opened) _storeError = 'Could not open the store. Please try again.';
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initializing && _status == AppAccessStatus.allowed) {
      return widget.child;
    }
    final maintenance = _status == AppAccessStatus.maintenance;
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const ValueKey('app-access-blocker'),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _initializing
                      ? const [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text('Checking app availability…'),
                        ]
                      : [
                          Icon(
                            maintenance
                                ? Icons.construction_rounded
                                : Icons.system_update_rounded,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            maintenance
                                ? 'Under maintenance'
                                : 'Update required',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            maintenance
                                ? (_config.message.trim().isEmpty
                                      ? const AppAccessConfig().message
                                      : _config.message)
                                : 'A newer version of Veil is required to continue. Please update from the store.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          if (!maintenance)
                            FilledButton(
                              onPressed: _openingStore ? null : _update,
                              child: Text(
                                _openingStore ? 'Opening store…' : 'Update',
                              ),
                            ),
                          OutlinedButton(
                            onPressed: _checking ? null : _check,
                            child: Text(_checking ? 'Checking…' : 'Retry'),
                          ),
                          if (_storeError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _storeError!,
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
