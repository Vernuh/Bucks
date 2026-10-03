import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/debt.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/formatters.dart';

const _navy = Color(0xFF17213F);
const _blue = Color(0xFF1688F5);
const _red = Color(0xFFE74C3C);

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// "1,250.50" / "1250.5" / " 500 " -> number, or null if it isn't one.
double? parseAmount(String text) {
  final cleaned = text.replaceAll(',', '').replaceAll('\u20b1', '').trim();
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

final _amountFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));

// ---------------------------------------------------------------------------
// Add / edit
// ---------------------------------------------------------------------------

/// Opens the Add Debt dialog ([existing] == null) or the Edit dialog.
/// Saving goes through [AppStateProvider]; this function only shows the
/// result.
Future<void> showDebtFormDialog(
  BuildContext context, {
  Debt? existing,
  DebtType initialType = DebtType.iOwe,
}) async {
  final message = await showDialog<String>(
    context: context,
    builder: (_) => _DebtFormDialog(
      existing: existing,
      initialType: initialType,
    ),
  );
  if (message != null && context.mounted) _toast(context, message);
}

class _DebtFormDialog extends StatefulWidget {
  final Debt? existing;
  final DebtType initialType;

  const _DebtFormDialog({required this.existing, required this.initialType});

  @override
  State<_DebtFormDialog> createState() => _DebtFormDialogState();
}

class _DebtFormDialogState extends State<_DebtFormDialog> {
  late final TextEditingController _title;
  late final TextEditingController _person;
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  late DebtType _type;
  DateTime? _due;

  String? _titleError;
  String? _amountError;
  String? _formError;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _type = d?.type ?? widget.initialType;
    _title = TextEditingController(text: d?.title ?? '');
    _person = TextEditingController(text: d?.personName ?? '');
    _amount = TextEditingController(
        text: d == null ? '' : _plainNumber(d.originalAmount));
    _notes = TextEditingController(text: d?.notes ?? '');
    _due = d?.dueDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _person.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  static String _plainNumber(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _due = picked);
  }

  void _save() {
    final title = _title.text.trim();
    final amount = parseAmount(_amount.text);

    String? titleError;
    String? amountError;
    if (title.isEmpty) titleError = 'Enter a short title, like "Laptop installment".';
    if (amount == null) {
      amountError = 'Enter the amount as a number.';
    } else if (amount <= 0) {
      amountError = 'The amount must be greater than 0.';
    } else if (_editing && roundMoney(amount) < widget.existing!.amountPaid) {
      amountError = 'It can\'t be less than the '
          '${formatPeso(widget.existing!.amountPaid)} already paid.';
    }
    if (titleError != null || amountError != null) {
      setState(() {
        _titleError = titleError;
        _amountError = amountError;
        _formError = null;
      });
      return;
    }

    final app = context.read<AppStateProvider>();
    final result = _editing
        ? app.updateDebt(
            widget.existing!.id,
            title: title,
            personName: _person.text,
            originalAmount: amount!,
            dueDate: _due,
            notes: _notes.text,
          )
        : app.addDebt(
            type: _type,
            title: title,
            personName: _person.text,
            amount: amount!,
            dueDate: _due,
            notes: _notes.text,
          );
    if (result.success) {
      Navigator.pop(context, result.message);
    } else {
      setState(() {
        _titleError = null;
        _amountError = null;
        _formError = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final owe = _type == DebtType.iOwe;
    final paid = widget.existing?.amountPaid ?? 0;

    return AlertDialog(
      scrollable: true,
      title: Text(_editing ? 'Edit Debt' : 'Add Debt'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_editing) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('I Owe'),
                  selected: _type == DebtType.iOwe,
                  onSelected: (_) => setState(() => _type = DebtType.iOwe),
                ),
                ChoiceChip(
                  label: const Text('Owed to Me'),
                  selected: _type == DebtType.owedToMe,
                  onSelected: (_) => setState(() => _type = DebtType.owedToMe),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(80)],
            decoration: InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. Laptop installment',
              errorText: _titleError,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _person,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            decoration: InputDecoration(
              labelText: 'Person / Organization (optional)',
              hintText: owe ? 'Who do you owe? e.g. Juan' : 'Who owes you? e.g. Juan',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_amountFormatter],
            decoration: InputDecoration(
              labelText: 'Original amount',
              prefixText: '\u20b1 ',
              errorText: _amountError,
              helperText:
                  _editing && paid > 0 ? 'Already paid: ${formatPeso(paid)}' : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(
                    _due == null ? 'Due date (optional)' : formatDate(_due!),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_due != null)
                IconButton(
                  tooltip: 'Clear due date',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _due = null),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(300)],
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 8),
            Text(_formError!, style: const TextStyle(color: _red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _save,
          child: Text(_editing ? 'Save Changes' : 'Save Debt'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Record payment
// ---------------------------------------------------------------------------

Future<void> showRecordPaymentDialog(BuildContext context, Debt debt) async {
  final message = await showDialog<String>(
    context: context,
    builder: (_) => _PaymentDialog(debt: debt),
  );
  if (message != null && context.mounted) _toast(context, message);
}

class _PaymentDialog extends StatefulWidget {
  final Debt debt;
  const _PaymentDialog({required this.debt});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _amount = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final remaining = widget.debt.remaining;
    final amount = parseAmount(_amount.text);
    if (amount == null) {
      setState(() => _error = 'Enter the amount as a number.');
      return;
    }
    if (amount <= 0) {
      setState(() => _error = 'The payment must be greater than 0.');
      return;
    }
    if (roundMoney(amount) > remaining) {
      setState(() => _error = 'That\'s more than the ${formatPeso(remaining)} left.');
      return;
    }
    final result = context
        .read<AppStateProvider>()
        .recordDebtPayment(widget.debt.id, amount);
    if (result.success) {
      Navigator.pop(context, result.message);
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final debt = widget.debt;
    final received = debt.type == DebtType.owedToMe;
    return AlertDialog(
      scrollable: true,
      title: const Text('Record Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(debt.title,
              style: const TextStyle(color: _navy, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${formatPeso(debt.remaining)} remaining'),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_amountFormatter],
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: 'How much?',
              helperText: received
                  ? 'Only record money you actually received.'
                  : 'Only record money you actually paid.',
              prefixText: '\u20b1 ',
              errorText: _error,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() {
                _amount.text = debt.remaining == debt.remaining.roundToDouble()
                    ? debt.remaining.round().toString()
                    : debt.remaining.toStringAsFixed(2);
                _error = null;
              }),
              child: const Text('Use full remaining amount'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('Save Payment', style: TextStyle(color: _blue)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Delete
// ---------------------------------------------------------------------------

Future<void> confirmDeleteDebt(BuildContext context, Debt debt) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete this debt?'),
      content:
          const Text('All tracking information for this debt will be removed.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete', style: TextStyle(color: _red)),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final result = context.read<AppStateProvider>().deleteDebt(debt.id);
  _toast(context, result.message);
}
