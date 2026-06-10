import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/providers/money_profile_provider.dart';

const _months = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Shows the mortgage setup sheet: renewal date picker.
Future<void> showMortgageSetupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => const MortgageSetupSheet(),
  );
}

/// Visible content of the mortgage setup sheet. Public for direct widget testing.
class MortgageSetupSheet extends ConsumerStatefulWidget {
  const MortgageSetupSheet({super.key});

  @override
  ConsumerState<MortgageSetupSheet> createState() => _MortgageSetupSheetState();
}

class _MortgageSetupSheetState extends ConsumerState<MortgageSetupSheet> {
  DateTime? _renewalDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = ref.read(moneyProfileProvider);
    _renewalDate = p.mortgageRenewalDate;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _renewalDate ?? now.add(const Duration(days: 365)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) setState(() => _renewalDate = picked);
  }

  Future<void> _save() async {
    if (_renewalDate == null) {
      setState(() => _error = 'Pick your mortgage renewal date.');
      return;
    }
    await ref
        .read(moneyProfileProvider.notifier)
        .setMortgageRenewalDate(_renewalDate!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    const sheetBg = Color(0xF00D161F);
    const handleColor = Color(0x3D9CB2C8);
    const topBorderColor = Color(0x249CB2C8);
    final accent = colors.accent;
    final d = _renewalDate;

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
                    'Track mortgage renewal',
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
                "We'll warn you when it's time to start comparing rates — "
                'most lenders hold a rate for 90–120 days.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: colors.muted),
              ),
              const SizedBox(height: 16),
              Text(
                'Renewal date',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.muted,
                ),
              ),
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
                        d == null
                            ? 'Pick a date'
                            : '${_months[d.month]} ${d.day}, ${d.year}',
                        style: TextStyle(
                          fontSize: 16,
                          color: d == null ? colors.faint : colors.text,
                        ),
                      ),
                    ],
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
