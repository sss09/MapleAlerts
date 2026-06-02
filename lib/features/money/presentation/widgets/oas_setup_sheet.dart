import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/providers/money_profile_provider.dart';

/// Shows the OAS setup sheet: birth year + income (reuses existing profile
/// fields — both also feed the TFSA/RRSP cards).
Future<void> showOasSetupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => const OasSetupSheet(),
  );
}

/// Visible content of the OAS setup sheet. Public for direct widget testing.
class OasSetupSheet extends ConsumerStatefulWidget {
  const OasSetupSheet({super.key});

  @override
  ConsumerState<OasSetupSheet> createState() => _OasSetupSheetState();
}

class _OasSetupSheetState extends ConsumerState<OasSetupSheet> {
  late final TextEditingController _birthYearCtrl;
  late final TextEditingController _incomeCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = ref.read(moneyProfileProvider);
    _birthYearCtrl =
        TextEditingController(text: p.birthYear?.toString() ?? '');
    _incomeCtrl = TextEditingController(
      text: p.annualIncome == null
          ? ''
          : (p.annualIncome == p.annualIncome!.truncate()
              ? p.annualIncome!.truncate().toString()
              : p.annualIncome!.toString()),
    );
  }

  @override
  void dispose() {
    _birthYearCtrl.dispose();
    _incomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final thisYear = DateTime.now().year;
    final year = int.tryParse(_birthYearCtrl.text.trim());
    final income = double.tryParse(_incomeCtrl.text.trim().replaceAll(',', ''));

    if (year == null || year < 1900 || year > thisYear) {
      setState(() => _error = 'Enter a valid birth year.');
      return;
    }
    if (income == null || income < 0) {
      setState(() => _error = 'Enter your net income.');
      return;
    }

    await ref.read(moneyProfileProvider.notifier).setBirthYear(year);
    await ref.read(moneyProfileProvider.notifier).setAnnualIncome(income);

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
                  StrokeIcon(name: 'bell', size: 16, color: accent),
                  const SizedBox(width: 7),
                  Text(
                    'OAS clawback check',
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
                'OAS gets reduced (15%) once net income passes the threshold. '
                'We’ll tell you if and by how much.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: colors.muted),
              ),
              const SizedBox(height: 16),
              _Label('Year you were born', colors: colors),
              const SizedBox(height: 6),
              _Field(controller: _birthYearCtrl, hint: 'e.g. 1956', colors: colors),
              const SizedBox(height: 14),
              _Label('Net income', colors: colors),
              const SizedBox(height: 6),
              _Field(
                  controller: _incomeCtrl,
                  hint: 'e.g. 95000',
                  colors: colors,
                  prefix: r'$'),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.error)),
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
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF06231C),
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

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.colors});
  final String text;
  final MapleColors colors;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: colors.muted),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.colors,
    this.prefix,
  });
  final TextEditingController controller;
  final String hint;
  final MapleColors colors;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return MapleSurface(
      level: MapleSurfaceLevel.solid,
      radius: 16,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
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
