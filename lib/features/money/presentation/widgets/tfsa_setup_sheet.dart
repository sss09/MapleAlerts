import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/providers/money_profile_provider.dart';

/// Shows the TFSA setup bottom sheet: the two numbers the engine needs to
/// compute room — birth year and total contributions.
Future<void> showTfsaSetupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => const TfsaSetupSheet(),
  );
}

/// The visible content of the TFSA setup sheet. Public so widget tests can pump
/// it directly without going through [showModalBottomSheet].
class TfsaSetupSheet extends ConsumerStatefulWidget {
  const TfsaSetupSheet({super.key});

  @override
  ConsumerState<TfsaSetupSheet> createState() => _TfsaSetupSheetState();
}

class _TfsaSetupSheetState extends ConsumerState<TfsaSetupSheet> {
  late final TextEditingController _birthYearCtrl;
  late final TextEditingController _contributedCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(moneyProfileProvider);
    _birthYearCtrl = TextEditingController(
      text: profile.birthYear?.toString() ?? '',
    );
    _contributedCtrl = TextEditingController(
      text: profile.tfsaContributed == null
          ? ''
          : _trimZeros(profile.tfsaContributed!),
    );
  }

  static String _trimZeros(double v) =>
      v == v.truncate() ? v.truncate().toString() : v.toString();

  @override
  void dispose() {
    _birthYearCtrl.dispose();
    _contributedCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final thisYear = DateTime.now().year;
    final year = int.tryParse(_birthYearCtrl.text.trim());
    final contributed =
        double.tryParse(_contributedCtrl.text.trim().replaceAll(',', ''));

    if (year == null || year < 1900 || year > thisYear) {
      setState(() => _error = 'Enter a valid birth year.');
      return;
    }
    if (contributed == null || contributed < 0) {
      setState(() => _error = 'Enter your total contributions (0 if none).');
      return;
    }

    await ref.read(moneyProfileProvider.notifier).setBirthYear(year);
    await ref
        .read(moneyProfileProvider.notifier)
        .setTfsaContributed(contributed);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;

    const sheetBg = Color(0xF00D161F);
    const handleColor = Color(0x3D9CB2C8);
    const topBorderColor = Color(0x249CB2C8);
    final accent = colors.accent;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: sheetBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          border: Border(top: BorderSide(color: topBorderColor, width: 1)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 30,
        ),
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

              Row(
                children: [
                  StrokeIcon(name: 'sparkle', size: 16, color: accent),
                  const SizedBox(width: 7),
                  Text(
                    'Your TFSA room',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Two numbers and we’ll track your room and warn you before the '
                'CRA penalizes an over-contribution.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: colors.muted),
              ),
              const SizedBox(height: 16),

              _FieldLabel('Year you were born', colors: colors),
              const SizedBox(height: 6),
              _NumberField(
                controller: _birthYearCtrl,
                hint: 'e.g. 1990',
                colors: colors,
                decimal: false,
              ),
              const SizedBox(height: 14),

              _FieldLabel('Total ever contributed to your TFSA',
                  colors: colors),
              const SizedBox(height: 6),
              _NumberField(
                controller: _contributedCtrl,
                hint: r'e.g. 42000   (enter 0 if none)',
                colors: colors,
                decimal: true,
                prefix: r'$',
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],

              const SizedBox(height: 20),
              GestureDetector(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.26),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF06231C),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.colors});
  final String text;
  final MapleColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors.muted,
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.hint,
    required this.colors,
    required this.decimal,
    this.prefix,
  });

  final TextEditingController controller;
  final String hint;
  final MapleColors colors;
  final bool decimal;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return MapleSurface(
      level: MapleSurfaceLevel.solid,
      radius: 16,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: TextField(
        controller: controller,
        keyboardType:
            TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
          ),
        ],
        style: TextStyle(fontSize: 16, color: colors.text),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          prefixText: prefix,
          prefixStyle: TextStyle(fontSize: 16, color: colors.muted),
          hintText: hint,
          hintStyle: TextStyle(fontSize: 15, color: colors.faint),
        ),
      ),
    );
  }
}
