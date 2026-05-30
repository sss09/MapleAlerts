import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/alert.dart';
import '../../models/gic_investment.dart';
import '../../providers/alerts_provider.dart';
import '../../services/database_service.dart';
import '../../utils/date_helpers.dart';

class AddGicScreen extends ConsumerStatefulWidget {
  const AddGicScreen({super.key});

  @override
  ConsumerState<AddGicScreen> createState() => _AddGicScreenState();
}

class _AddGicScreenState extends ConsumerState<AddGicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _institutionCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _interestRateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  int _termMonths = 12;
  bool _saving = false;

  static const _termOptions = [3, 6, 9, 12, 18, 24, 36, 60];

  DateTime get _maturityDate =>
      _purchaseDate.add(Duration(days: _termMonths * 30));

  @override
  void dispose() {
    _institutionCtrl.dispose();
    _amountCtrl.dispose();
    _interestRateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      const uuid = Uuid();
      final gicId = uuid.v4();
      final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
      final rate = double.tryParse(_interestRateCtrl.text) ?? 0.0;

      final gic = GicInvestment(
        id: gicId,
        institution: _institutionCtrl.text.trim(),
        amount: amount,
        purchaseDate: _purchaseDate,
        termMonths: _termMonths,
        interestRate: rate,
        notes: _notesCtrl.text.trim(),
      );

      final alert = Alert(
        id: 'gic_$gicId',
        title: 'GIC Matures — ${_institutionCtrl.text.trim()}',
        description:
            'Your \$${_amountCtrl.text} GIC at ${_institutionCtrl.text.trim()} '
            'matures on ${formatDate(_maturityDate)}.',
        type: AlertType.gic,
        deadline: _maturityDate,
        reminderEnabled: true,
        isPremium: false,
        metadata: {'gicId': gicId},
      );

      await DatabaseService.instance.insertGic(gic);
      await ref.read(alertsProvider.notifier).addAlert(alert);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving GIC: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add GIC')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _institutionCtrl,
              decoration: const InputDecoration(
                labelText: 'Institution *',
                hintText: 'e.g. EQ Bank, RBC',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Amount (\$) *',
                hintText: '10000',
                prefixText: '\$ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickPurchaseDate,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Purchase Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(formatDate(_purchaseDate)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _termMonths,
              decoration: const InputDecoration(labelText: 'Term'),
              items: _termOptions
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m < 12
                            ? '$m months'
                            : m == 12
                                ? '1 year'
                                : '${m ~/ 12} years${m % 12 != 0 ? ' ${m % 12} months' : ''}'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _termMonths = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _interestRateCtrl,
              decoration: const InputDecoration(
                labelText: 'Interest Rate (%) — optional',
                hintText: '4.5',
                suffixText: '%',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes — optional',
                hintText: 'Any additional details',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.event, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Matures on: ${formatDate(_maturityDate)}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save GIC'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
