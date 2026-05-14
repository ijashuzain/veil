import 'package:flutter/material.dart';
import 'package:veil/src/core/services/shorebird_update_service.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/shared/components/veil_logo.dart';

class ShorebirdUpdateGate extends StatefulWidget {
  const ShorebirdUpdateGate({
    super.key,
    required this.updateService,
    required this.child,
  });

  final ShorebirdUpdateService updateService;
  final Widget child;

  @override
  State<ShorebirdUpdateGate> createState() => _ShorebirdUpdateGateState();
}

class _ShorebirdUpdateGateState extends State<ShorebirdUpdateGate> {
  ShorebirdPatchStage? _stage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForPatch());
  }

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      ShorebirdPatchStage.checking => const _UpdateStatusScreen(
        title: 'Checking for updates',
        message: 'Looking for the latest Veil patch.',
        busy: true,
      ),
      ShorebirdPatchStage.downloading => const _UpdateStatusScreen(
        title: 'Downloading update',
        message: 'Installing the latest Veil patch.',
        busy: true,
      ),
      ShorebirdPatchStage.restartRequired => const _UpdateStatusScreen(
        title: 'Update installed',
        message: 'Restart Veil to apply the latest patch.',
      ),
      _ => widget.child,
    };
  }

  Future<void> _checkForPatch() async {
    final result = await widget.updateService.checkAndDownloadPatch(
      onStageChanged: (stage) {
        if (!mounted) return;
        setState(() => _stage = stage);
      },
    );
    if (!mounted) return;
    setState(() {
      _stage = result.restartRequired
          ? ShorebirdPatchStage.restartRequired
          : null;
    });
  }
}

class _UpdateStatusScreen extends StatelessWidget {
  const _UpdateStatusScreen({
    required this.title,
    required this.message,
    this.busy = false,
  });

  final String title;
  final String message;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VeilColors.bg0,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VeilLogo(size: 30, center: true),
                const SizedBox(height: 24),
                if (busy) ...[
                  const SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: VeilColors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: VeilColors.text3,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
