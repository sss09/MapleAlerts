import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/providers/money_profile_provider.dart';

/// Shows the CCB setup bottom sheet: children by age band + family net income.
Future<void> showCcbSetupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => const CcbSetupSheet(),
  );
}

/// Visible content of the CCB setup sheet. Public for direct widget testing.
class CcbSetupSheet extends ConsumerStatefulWidget {
  const CcbSetupSheet({super.key});

  @override
  ConsumerState<CcbSetupSheet> createState() => _CcbSetupSheetState();
}

class _CcbSetupSheetState extends ConsumerState<CcbSetupSheet> {
  late int _under6;
  late int _age6to17;
  late final TextEditingController _incomeCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = ref.read(moneyProfileProvider);
    _under6 = p.kidsUnder6 ?? 0;
    _age6to17 = p.kids6to17 ?? 0;
    _incomeCtrl = TextEditingController(
      text: p.familyNetIncome == null
          ? ''
          : (p.familyNetIncome == p.familyNetIncome!.truncate()
              ? p.familyNetIncome!.truncate().toString()
              : p.familyNetIncome!.toString()),
    );
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final income =
        double.tryParse(_incomeCtrl.text.trim().replaceAll(',', ''));
    if (income == null || income < 0) {
      setState(() => _error = 'Enter your family net income.');
      return;
    }

    await ref.read(moneyProfileProvider.notifier).setCcbInputs(
          kidsUnder6: _under6,
          kids6to17: _age6to17,
          familyNetIncome: income,
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
                  StrokeIcon(name: 'family', size: 16, color: accent),
                  const SizedBox(width: 7),
                  Text(
                    'Canada Child Benefit',
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
                'Tax-free monthly support for families. We estimate it from your '
                'kids’ ages and family net income.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: colors.muted),
              ),
              const SizedBox(height: 16),

              _Stepper(
                label: 'Children under 6',
                value: _under6,
                colors: colors,
                accent: accent,
                onChanged: (v) => setState(() => _under6 = v),
              ),
              const SizedBox(height: 10),
              _Stepper(
                label: 'Children aged 6–17',
                value: _age6to17,
                colors: colors,
                accent: accent,
                onChanged: (v) => setState(() => _age6to17 = v),
              ),
              const SizedBox(height: 16),

              Text(
                'Adjusted family net income',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.muted,
                ),
              ),
              const SizedBox(height: 6),
              MapleSurface(
                level: MapleSurfaceLevel.solid,
                radius: 16,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: TextField(
                  controller: _incomeCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: TextStyle(fontSize: 16, color: colors.text),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    prefixText: r'$',
                    prefixStyle: TextStyle(fontSize: 16, color: colors.muted),
                    hintText: 'e.g. 65000   (both spouses combined)',
                    hintStyle: TextStyle(fontSize: 15, color: colors.faint),
                  ),
                ),
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

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.colors,
    required this.accent,
    required this.onChanged,
  });

  final String label;
  final int value;
  final MapleColors colors;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return MapleSurface(
      level: MapleSurfaceLevel.minimal,
      radius: 16,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: colors.text),
            ),
          ),
          _RoundButton(
            icon: Icons.remove,
            color: colors,
            accent: accent,
            onTap: value > 0 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _RoundButton(
            icon: Icons.add,
            color: colors,
            accent: accent,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.color,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final MapleColors color;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.surface2,
          border: Border.all(
            color: enabled ? accent.withValues(alpha: 0.4) : color.line,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? accent : color.faint,
        ),
      ),
    );
  }
}
