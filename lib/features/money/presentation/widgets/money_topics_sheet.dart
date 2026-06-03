import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/features/money/presentation/money_topic.dart';
import 'package:maple_alerts/providers/enabled_topics_provider.dart';

/// Shows the "Track more" sheet — enable/disable which found-money topics
/// appear on Home.
Future<void> showMoneyTopicsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => const MoneyTopicsSheet(),
  );
}

/// Visible content of the topics manager. Public for direct widget testing.
class MoneyTopicsSheet extends ConsumerWidget {
  const MoneyTopicsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final enabled = ref.watch(enabledTopicsProvider);

    const sheetBg = Color(0xF00D161F);
    const handleColor = Color(0x3D9CB2C8);
    const topBorderColor = Color(0x249CB2C8);

    return SafeArea(
      child: Container(
        // Scroll within a capped height — six topic rows overflow short
        // viewports (small phones / landscape) otherwise.
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
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
              'What should we track?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick the money areas that apply to you. You can change this anytime.',
              style: TextStyle(fontSize: 12.5, height: 1.4, color: colors.muted),
            ),
            const SizedBox(height: 14),
            for (final topic in MoneyTopic.values) ...[
              _TopicRow(
                topic: topic,
                enabled: enabled.contains(topic),
                colors: colors,
                onChanged: (v) => ref
                    .read(enabledTopicsProvider.notifier)
                    .setEnabled(topic, v),
              ),
              const SizedBox(height: 8),
            ],
          ],
          ),
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.topic,
    required this.enabled,
    required this.colors,
    required this.onChanged,
  });

  final MoneyTopic topic;
  final bool enabled;
  final MapleColors colors;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MapleSurface(
      level: MapleSurfaceLevel.minimal,
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          StrokeIcon(name: topic.icon, size: 18, color: colors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  topic.blurb,
                  style: TextStyle(fontSize: 12, color: colors.muted),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: colors.accent,
          ),
        ],
      ),
    );
  }
}
