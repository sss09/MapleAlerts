import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/providers/money_profile_provider.dart';

/// Shows the RRSP setup bottom sheet: province, income, deduction limit, and
/// amount contributed — the inputs the engine needs for room + tax savings.
Future<void> showRrspSetupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => const RrspSetupSheet(),
  );
}

/// Visible content of the RRSP setup sheet. Public for direct widget testing.
class RrspSetupSheet extends ConsumerStatefulWidget {
  const RrspSetupSheet({super.key});

  @override
  ConsumerState<RrspSetupSheet> createState() => _RrspSetupSheetState();
}

class _RrspSetupSheetState extends ConsumerState<RrspSetupSheet> {
  Province? _province;
  late final TextEditingController _incomeCtrl;
  late final TextEditingController _limitCtrl;
  late final TextEditingController _contributedCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = ref.read(moneyProfileProvider);
    _province = p.province;
    _incomeCtrl = TextEditingController(text: _money(p.annualIncome));
    _limitCtrl = TextEditingController(text: _money(p.rrspDeductionLimit));
    _contributedCtrl = TextEditingController(text: _money(p.rrspContributed));
  }

  static String _money(double? v) =>
      v == null ? '' : (v == v.truncate() ? v.truncate().toString() : v.toString());

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _limitCtrl.dispose();
    _contributedCtrl.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', ''));

  Future<void> _save() async {
    final province = _province;
    final income = _parse(_incomeCtrl);
    final limit = _parse(_limitCtrl);
    final contributed = _parse(_contributedCtrl);

    if (province == null) {
      setState(() => _error = 'Choose your province.');
      return;
    }
    if (income == null || income < 0) {
      setState(() => _error = 'Enter your annual income.');
      return;
    }
    if (limit == null || limit < 0) {
      setState(() => _error = 'Enter your RRSP deduction limit (from your NOA).');
      return;
    }
    if (contributed == null || contributed < 0) {
      setState(() => _error = 'Enter what you have contributed (0 if none).');
      return;
    }

    await ref.read(moneyProfileProvider.notifier).setRrspInputs(
          province: province,
          annualIncome: income,
          deductionLimit: limit,
          contributed: contributed,
        );

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
                  StrokeIcon(name: 'wallet', size: 16, color: accent),
                  const SizedBox(width: 7),
                  Text(
                    'Your RRSP',
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
                'We’ll show your unused room and the tax it could save at your '
                'marginal rate.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: colors.muted),
              ),
              const SizedBox(height: 16),

              _Label('Province', colors: colors),
              const SizedBox(height: 6),
              _ProvinceField(
                value: _province,
                colors: colors,
                onChanged: (p) => setState(() => _province = p),
              ),
              const SizedBox(height: 14),

              _Label('Annual income', colors: colors),
              const SizedBox(height: 6),
              _NumberField(controller: _incomeCtrl, hint: 'e.g. 80000', colors: colors, prefix: r'$'),
              const SizedBox(height: 14),

              _Label('RRSP deduction limit (from your CRA NOA)', colors: colors),
              const SizedBox(height: 6),
              _NumberField(controller: _limitCtrl, hint: 'e.g. 50000', colors: colors, prefix: r'$'),
              const SizedBox(height: 14),

              _Label('Contributed so far', colors: colors),
              const SizedBox(height: 6),
              _NumberField(controller: _contributedCtrl, hint: r'e.g. 20000   (0 if none)', colors: colors, prefix: r'$'),

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

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.colors});
  final String text;
  final MapleColors colors;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.muted,
        ),
      );
}

class _ProvinceField extends StatelessWidget {
  const _ProvinceField({
    required this.value,
    required this.colors,
    required this.onChanged,
  });

  final Province? value;
  final MapleColors colors;
  final ValueChanged<Province?> onChanged;

  @override
  Widget build(BuildContext context) {
    return MapleSurface(
      level: MapleSurfaceLevel.solid,
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Province>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF101D26),
          hint: Text(
            'Select your province',
            style: TextStyle(fontSize: 15, color: colors.faint),
          ),
          icon: Icon(Icons.keyboard_arrow_down, color: colors.muted),
          style: TextStyle(fontSize: 15, color: colors.text),
          items: [
            for (final p in Province.values)
              DropdownMenuItem(
                value: p,
                child: Text(p.displayName,
                    style: TextStyle(color: colors.text)),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
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
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
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
