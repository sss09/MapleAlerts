import 'dart:ui';

import 'package:flutter/material.dart';

import '../design_theme.dart';
import '../tokens/maple_aurora.dart';
import '../tokens/maple_colors.dart';

/// An animated aurora atmosphere background.
///
/// Renders three layers stacked inside a [Stack(fit: StackFit.expand)]:
///   1. A radial-gradient base layer from [MapleAurora.baseStops].
///   2. Per-[AuroraBlob] blurred radial circles (optionally animated).
///   3. A linear fog-veil overlay for atmospheric depth.
///
/// Aurora resolution order (first non-null wins):
///   [aurora] → `Theme.of(context).extension<MapleAurora>()` → [DesignTheme.fog.aurora].
///
/// When [motion] is true AND [MediaQuery.of(context).disableAnimations] is
/// false, each blob drifts gently on a 24 s repeating reverse controller.
/// Call sites that contain infinite animations should use
/// `await tester.pump(Duration(milliseconds: 16))` rather than
/// `pumpAndSettle` to avoid test hangs.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    this.aurora,
    this.motion = true,
    this.parallax = 0,
    super.key,
  });

  /// Override the aurora palette. If null the theme extension is used.
  final MapleAurora? aurora;

  /// Whether to animate the blob positions. Defaults to true.
  final bool motion;

  /// Vertical parallax offset in logical pixels (applied as `parallax * 0.05`).
  final double parallax;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    // Start animation if motion is requested; it will be gated by
    // MediaQuery in build() as well, but we start it unconditionally
    // so a didChangeDependencies update can turn it on without a rebuild.
    if (widget.motion) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AuroraBackground old) {
    super.didUpdateWidget(old);
    if (widget.motion && !old.motion) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.motion && old.motion) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  MapleAurora _resolveAurora(BuildContext context) {
    return widget.aurora ??
        Theme.of(context).extension<MapleAurora>() ??
        DesignTheme.fog.aurora;
  }

  @override
  Widget build(BuildContext context) {
    final aurora = _resolveAurora(context);
    final animate =
        widget.motion && !MediaQuery.of(context).disableAnimations;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final colors = Theme.of(context).extension<MapleColors>();

    // In light mode the dark night-sky base stops are replaced with a soft
    // wash derived from the canvas tokens; the translucent aurora blobs then
    // read as gentle colour hints rather than glowing lights.
    final List<Color> baseStops = isLight
        ? <Color>[
            (colors?.surface2 ?? const Color(0xFFEAF0EE)),
            (colors?.canvas ?? const Color(0xFFF4F7F6)),
            (colors?.canvas ?? const Color(0xFFF4F7F6)),
          ]
        : aurora.baseStops;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. Base radial gradient ──────────────────────────────────────
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -1.2),
              radius: 1.3,
              colors: baseStops,
            ),
          ),
        ),

        // ── 2. Atmospheric blobs ─────────────────────────────────────────
        for (var i = 0; i < aurora.blobs.length; i++)
          _BlobLayer(
            blob: aurora.blobs[i],
            parallax: widget.parallax,
            animate: animate,
            animation: _anim,
            index: i,
          ),

        // ── 3. Fog veil ──────────────────────────────────────────────────
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isLight
                  ? const [
                      Color(0x0AFFFFFF), // 4 %  white
                      Color(0x40F4F7F6), // 25 % canvas
                      Color(0x99F4F7F6), // 60 % canvas
                    ]
                  : const [
                      Color(0x1A080E16), // 10 %
                      Color(0x4D070C14), // 30 %
                      Color(0x9E060B12), // 62 %
                    ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A single aurora blob rendered as a blurred radial circle.
class _BlobLayer extends StatelessWidget {
  const _BlobLayer({
    required this.blob,
    required this.parallax,
    required this.animate,
    required this.animation,
    required this.index,
  });

  final AuroraBlob blob;
  final double parallax;
  final bool animate;
  final Animation<double> animation;
  final int index;

  @override
  Widget build(BuildContext context) {
    // Nudge offsets differ per blob so they drift independently.
    final nudgeX = (index.isEven ? 1.0 : -1.0) * 6.0;
    final nudgeY = (index % 3 == 0 ? 1.0 : -1.0) * 8.0;

    final baseOffsetY = -parallax * 0.05;

    Widget circle = Container(
      width: blob.size,
      height: blob.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            blob.color,
            blob.color.withValues(alpha: 0),
          ],
          stops: const [0, 0.7],
        ),
      ),
    );

    circle = ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: circle,
    );

    if (animate) {
      return AnimatedBuilder(
        animation: animation,
        builder: (_, child) {
          final t = animation.value;
          return Align(
            alignment: blob.position,
            child: Transform.translate(
              offset: Offset(
                nudgeX * t,
                baseOffsetY + nudgeY * t,
              ),
              child: child,
            ),
          );
        },
        child: circle,
      );
    }

    return Align(
      alignment: blob.position,
      child: Transform.translate(
        offset: Offset(0, baseOffsetY),
        child: circle,
      ),
    );
  }
}
