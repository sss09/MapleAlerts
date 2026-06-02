import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/providers/money_profile_provider.dart';

/// Shows the FHSA setup sheet: total contributed to date.
Future<void> showFhsaSetupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => const FhsaSetupSheet(),
  );
}

/// Visible content of the FHSA setup sheet. Public for direct widget testing.
class FhsaSetupSheet extends ConsumerStatefulWidget {
  const FhsaSetupSheet({super.key});

  @override
  ConsumerState<FhsaSetupSheet> createState() => _FhsaSetupSheetState();
}

class _FhsaSetupSheetState extends ConsumerState<FhsaSetupSheet> {
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    final v = ref.read(moneyProfileProvider).fhsaContributed;
    _ctrl = TextEditingController(
      text: v == null
          ? ''
          : (v == v.truncate() ? v.truncate().toString() : v.toString()),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_ctrl.text.trim().replaceAll(',', ''));
    if (amount == null || amount < 0) {
      setState(() => _error = 'Enter your total FHSA contributions (0 if none).');
      return;
    }
    await ref.read(moneyProfileProvider.notifier).setFhsaContributed(amount);
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
                  StrokeIcon(name: 'home', size: 16, color: accent),
                  const SizedBox(width: 7),
                  Text(
                    'Your FHSA',
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
                'First Home Savings Account: \$8,000/year, \$40,000 lifetime — '
                'deductible like an RRSP and tax-free for a first home.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: colors.muted),
              ),
              const SizedBox(height: 16),
              Text('Total contributed to date',
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
                  controller: _ctrl,
                  autofocus: true,
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
                    hintText: 'e.g. 8000   (0 if none yet)',
                    hintStyle: TextStyle(fontSize: 15, color: colors.faint),
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
