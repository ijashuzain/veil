import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';
import 'package:veil/app/services/local_storage_services/local_storage_services.dart';
import 'package:veil/app/services/supabase_services/supabase_service.dart';
import 'package:veil/src/core/providers/ad_providers.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialUri = Uri.base;
  await LocalStorage.init();
  await SupabaseService.init();
  final hasPersistedSession = SupabaseService.hasActiveSession;
  runApp(
    ProviderScope(
      child: VeilApp(
        skipOnboarding: hasPersistedSession,
        initialUri: initialUri,
      ),
    ),
  );
}

class VeilApp extends StatefulWidget {
  const VeilApp({super.key, this.skipOnboarding = false, this.initialUri});

  final bool skipOnboarding;
  final Uri? initialUri;

  @override
  State<VeilApp> createState() => _VeilAppState();
}

class _VeilAppState extends State<VeilApp> {
  late final _router = createRouter(
    skipOnboarding: widget.skipOnboarding,
    initialUri: widget.initialUri,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final container = ProviderScope.containerOf(context, listen: false);
      unawaited(container.read(adControllerProvider.notifier).initialize());
    });
  }

  @override
  Widget build(BuildContext context) {
    return TheResponsiveBuilder(
      baselineWidth: 390,
      baselineHeight: 844,
      builder: (context, orientation, screenType) {
        return MaterialApp.router(
          title: 'Veil',
          debugShowCheckedModeBanner: false,
          theme: VeilTheme.dark(),
          routerConfig: _router,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
        );
      },
    );
  }
}
