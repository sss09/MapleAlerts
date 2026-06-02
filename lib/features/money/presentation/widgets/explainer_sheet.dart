import 'package:flutter/material.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

/// Shows a plain-language explainer in a bottom sheet.
Future<void> showExplainerSheet(BuildContext context, Explainer explainer) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => ExplainerSheet(explainer: explainer),
  );
}

class ExplainerSheet extends StatelessWidget {
  const ExplainerSheet({required this.explainer, super.key});

  final Explainer explainer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    const sheetBg = Color(0xF00D161F);
    const handleColor = Color(0x3D9CB2C8);
    const topBorderColor = Color(0x249CB2C8);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: sheetBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          border: Border(top: BorderSide(color: topBorderColor, width: 1)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Text(
                explainer.title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                  letterSpacing: -0.02 * 21,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                explainer.summary,
                style: TextStyle(fontSize: 14.5, height: 1.5, color: colors.muted),
              ),
              const SizedBox(height: 16),
              for (final p in explainer.points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: StrokeIcon(
                            name: 'check', size: 15, color: colors.accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p,
                          style: TextStyle(
                              fontSize: 13.5, height: 1.45, color: colors.text),
                        ),
                      ),
                    ],
                  ),
                ),
              if (explainer.provinceNote != null) ...[
                const SizedBox(height: 6),
                Text(
                  explainer.provinceNote!,
                  style: TextStyle(
                      fontSize: 12.5, height: 1.4, color: colors.muted),
                ),
              ],
              const SizedBox(height: 14),
              Divider(height: 1, color: colors.line),
              const SizedBox(height: 12),
              for (final s in explainer.sources)
                Text(
                  '${s.label} · ${s.value} · ${s.source}',
                  style: TextStyle(fontSize: 11.5, color: colors.faint),
                ),
              const SizedBox(height: 8),
              Text(
                'Informational, not financial advice.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: colors.faint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
