import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A circular progress ring with an optional glow effect and a centred child.
///
/// Ported from the `Ring` component in `docs/design/ux-design-1/ui.jsx`.
/// Uses [CustomPaint] so no external dependency is required.
///
/// The ring draws:
///   1. A full-circle [track] behind the progress arc.
///   2. An arc from −90° (top) sweeping `2π × progress` clockwise in [color].
///   3. When [glow] is true, the same arc is drawn below with a
///      [MaskFilter.blur] for the atmospheric glow seen in the design.
///
/// An optional [child] is stacked and centred inside the ring.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    this.progress = 0.5,
    this.size = 38,
    this.strokeWidth = 3,
    required this.color,
    this.track = const Color(0x249CB2C8),
    this.glow = true,
    this.child,
    super.key,
  });

  /// Completion fraction — clamped to [0, 1].
  final double progress;

  /// Outer dimension of the ring in logical pixels (width = height = [size]).
  final double size;

  /// Stroke width for both the track and progress arc (default 3).
  final double strokeWidth;

  /// Colour of the progress arc.
  final Color color;

  /// Colour of the full-circle background track (default: muted slate 14%).
  final Color track;

  /// Whether to draw a blurred glow layer beneath the progress arc.
  final bool glow;

  /// Optional widget centred inside the ring (e.g. a countdown label).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final painter = _RingPainter(
      progress: progress,
      strokeWidth: strokeWidth,
      color: color,
      track: track,
      glow: glow,
    );

    Widget ring = CustomPaint(
      size: Size(size, size),
      painter: painter,
    );

    if (child != null) {
      ring = Stack(
        alignment: Alignment.center,
        children: [
          ring,
          child!,
        ],
      );
    }

    return SizedBox(width: size, height: size, child: ring);
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.track,
    required this.glow,
  });

  final double progress;
  final double strokeWidth;
  final Color color;
  final Color track;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // 1. Track — full circle.
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    const startAngle = -math.pi / 2; // top of circle

    if (sweep <= 0) return;

    // 2. Glow layer — blurred copy of the arc drawn first (beneath the solid arc).
    if (glow) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        glowPaint,
      );
    }

    // 3. Solid progress arc on top.
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.track != track ||
      old.strokeWidth != strokeWidth ||
      old.glow != glow;
}
