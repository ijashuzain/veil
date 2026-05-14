import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';
import 'package:veil/app/services/local_storage_services/local_storage_services.dart';
import 'package:veil/app/services/supabase_services/supabase_service.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/services/shorebird_update_service.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/shared/components/shorebird_update_gate.dart';

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
  const VeilApp({
    super.key,
    this.skipOnboarding = false,
    this.initialUri,
    this.shorebirdUpdateService,
  });

  final bool skipOnboarding;
  final Uri? initialUri;
  final ShorebirdUpdateService? shorebirdUpdateService;

  @override
  State<VeilApp> createState() => _VeilAppState();
}

class _VeilAppState extends State<VeilApp> {
  late final _router = createRouter(
    skipOnboarding: widget.skipOnboarding,
    initialUri: widget.initialUri,
  );
  late final _shorebirdUpdateService =
      widget.shorebirdUpdateService ??
      (kIsWeb
          ? const NoopShorebirdUpdateService()
          : ShorebirdCodePushUpdateService());

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
          builder: (context, child) {
            return ShorebirdUpdateGate(
              updateService: _shorebirdUpdateService,
              child: child ?? const SizedBox.shrink(),
            );
          },
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
