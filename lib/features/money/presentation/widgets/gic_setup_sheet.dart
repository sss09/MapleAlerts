import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/providers/money_profile_provider.dart';

const _months = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Shows the GIC setup sheet: principal amount + maturity date.
Future<void> showGicSetupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => const GicSetupSheet(),
  );
}

/// Visible content of the GIC setup sheet. Public for direct widget testing.
class GicSetupSheet extends ConsumerStatefulWidget {
  const GicSetupSheet({super.key});

  @override
  ConsumerState<GicSetupSheet> createState() => _GicSetupSheetState();
}

class _GicSetupSheetState extends ConsumerState<GicSetupSheet> {
  late final TextEditingController _amountCtrl;
  DateTime? _maturity;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = ref.read(moneyProfileProvider);
    _amountCtrl = TextEditingController(
      text: p.gicAmount == null
          ? ''
          : (p.gicAmount == p.gicAmount!.truncate()
              ? p.gicAmount!.truncate().toString()
              : p.gicAmount!.toString()),
    );
    _maturity = p.gicMaturityDate;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _maturity ?? now.add(const Duration(days: 30)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 15),
    );
    if (picked != null) setState(() => _maturity = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter the GIC amount.');
      return;
    }
    if (_maturity == null) {
      setState(() => _error = 'Pick the maturity date.');
      return;
    }
    await ref
        .read(moneyProfileProvider.notifier)
        .setGic(amount: amount, maturityDate: _maturity!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    const sheetBg = Color(0xF00D161F);
    const handleColor = Color(0x3D9CB2C8);
    const topBorderColor = Color(0x249CB2C8);
    final accent = colors.accent;
    final m = _maturity;

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
                  StrokeIcon(name: 'clock', size: 16, color: accent),
                  const SizedBox(width: 7),
                  Text(
                    'Track a GIC',
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
                'We’ll flag it as maturity nears and suggest where to move the '
                'cash so it keeps growing tax-sheltered.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: colors.muted),
              ),
              const SizedBox(height: 16),
              Text('GIC amount',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.muted)),
              const SizedBox(height: 6),
              MapleSurface(
                level: MapleSurfaceLevel.solid,
                radius: 16,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                  ],
                  style: TextStyle(fontSize: 16, color: colors.text),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    prefixText: r'$',
                    prefixStyle: TextStyle(fontSize: 16, color: colors.muted),
                    hintText: 'e.g. 20000',
                    hintStyle: TextStyle(fontSize: 15, color: colors.faint),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Maturity date',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.muted)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDate,
                behavior: HitTestBehavior.opaque,
                child: MapleSurface(
                  level: MapleSurfaceLevel.solid,
                  radius: 16,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: colors.muted),
                      const SizedBox(width: 12),
                      Text(
                        m == null
                            ? 'Pick a date'
                            : '${_months[m.month]} ${m.day}, ${m.year}',
                        style: TextStyle(
                          fontSize: 16,
                          color: m == null ? colors.faint : colors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
