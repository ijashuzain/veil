import 'package:flutter/material.dart';

enum PlayerControlGlyph { sound, muted, fullscreen, exitFullscreen }

/// Paint critical media controls directly so old PWA icon-font caches cannot
/// leave working buttons invisible after a web deployment.
class PlayerControlIcon extends StatelessWidget {
  const PlayerControlIcon(this.glyph, {super.key});
  final PlayerControlGlyph glyph;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size.square(23), painter: _GlyphPainter(glyph));
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph);
  final PlayerControlGlyph glyph;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    if (glyph == PlayerControlGlyph.sound ||
        glyph == PlayerControlGlyph.muted) {
      path.moveTo(3, 9);
      path.lineTo(7, 9);
      path.lineTo(12, 5);
      path.lineTo(12, 19);
      path.lineTo(7, 15);
      path.lineTo(3, 15);
      path.close();
      if (glyph == PlayerControlGlyph.muted) {
        path.moveTo(16, 9);
        path.lineTo(21, 15);
        path.moveTo(21, 9);
        path.lineTo(16, 15);
      } else {
        path.moveTo(16, 8);
        path.quadraticBezierTo(20, 12, 16, 16);
        path.moveTo(19, 5);
        path.quadraticBezierTo(25, 12, 19, 19);
      }
    } else {
      for (final x in [0.0, 24.0]) {
        for (final y in [0.0, 24.0]) {
          final dx = x == 0 ? 1.0 : -1.0;
          final dy = y == 0 ? 1.0 : -1.0;
          final inset = glyph == PlayerControlGlyph.fullscreen ? 4.0 : 9.0;
          final end = glyph == PlayerControlGlyph.fullscreen ? 9.0 : 4.0;
          path.moveTo(x + dx * end, y + dy * inset);
          path.lineTo(x + dx * inset, y + dy * inset);
          path.lineTo(x + dx * inset, y + dy * end);
        }
      }
    }
    canvas.drawPath(path, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) => oldDelegate.glyph != glyph;
}
