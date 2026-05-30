import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/alert.dart';
import '../../models/mortgage.dart';
import '../../providers/alerts_provider.dart';
import '../../services/database_service.dart';
import '../../utils/date_helpers.dart';

class AddMortgageScreen extends ConsumerStatefulWidget {
  const AddMortgageScreen({super.key});

  @override
  ConsumerState<AddMortgageScreen> createState() => _AddMortgageScreenState();
}

class _AddMortgageScreenState extends ConsumerState<AddMortgageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lenderCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _interestRateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _renewalDate =
      DateTime.now().add(const Duration(days: 365));
  String _mortgageType = 'Fixed';
  bool _saving = false;

  @override
  void dispose() {
    _lenderCtrl.dispose();
    _amountCtrl.dispose();
    _interestRateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRenewalDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _renewalDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
    );
    if (picked != null) {
      setState(() => _renewalDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      const uuid = Uuid();
      final mortgageId = uuid.v4();
      final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
      final rate = double.tryParse(_interestRateCtrl.text) ?? 0.0;
      final lender = _lenderCtrl.text.trim();

      final mortgage = Mortgage(
        id: mortgageId,
        lender: lender,
        amount: amount,
        renewalDate: _renewalDate,
        interestRate: rate,
        mortgageType: _mortgageType.toLowerCase(),
        notes: _notesCtrl.text.trim(),
      );

      final alert = Alert(
        id: 'mortgage_$mortgageId',
        title: 'Mortgage Renewal — $lender',
        description:
            'Your ${_mortgageType.toLowerCase()} mortgage with $lender '
            'is up for renewal on ${formatDate(_renewalDate)}. '
            'Start shopping rates 120 days early.',
        type: AlertType.mortgage,
        deadline: _renewalDate,
        reminderEnabled: true,
        isPremium: false,
        metadata: {'mortgageId': mortgageId},
      );

      await DatabaseService.instance.insertMortgage(mortgage);
      await ref.read(alertsProvider.notifier).addAlert(alert);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving mortgage: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Mortgage')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _lenderCtrl,
              decoration: const InputDecoration(
                labelText: 'Lender *',
                hintText: 'e.g. RBC, TD, Scotiabank',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Mortgage Amount (\$) *',
                hintText: '500000',
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
              onTap: _pickRenewalDate,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Renewal Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(formatDate(_renewalDate)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _interestRateCtrl,
              decoration: const InputDecoration(
                labelText: 'Interest Rate (%) — optional',
                hintText: '5.25',
                suffixText: '%',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _mortgageType,
              decoration: const InputDecoration(labelText: 'Mortgage Type'),
              items: ['Fixed', 'Variable']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _mortgageType = v);
              },
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
                    : const Text('Save Mortgage'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
