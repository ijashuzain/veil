const compactWebPlayerBreakpoint = 700.0;

bool shouldOpenPlayerExternally({
  required bool isWeb,
  required double viewportWidth,
}) {
  return isWeb && viewportWidth < compactWebPlayerBreakpoint;
}
