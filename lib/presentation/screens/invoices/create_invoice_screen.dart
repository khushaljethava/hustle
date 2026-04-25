import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../blocs/invoice/invoice_bloc.dart';
import '../../blocs/client/client_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pro_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/client_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../di/service_locator.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  ClientModel? _client;
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  double _taxRate = 0;
  final _notesController = TextEditingController();
  final List<_LineItem> _items = [_LineItem()];

  // Pro features
  String? _selectedCurrency;   // null = use client currency
  bool _isRecurring = false;
  String _recurringInterval = AppConstants.recurringMonthly;
  String _template = AppConstants.templateClassic;

  bool get _isPro => sl<ProService>().isProUser;
  String get _effectiveCurrency => _selectedCurrency ?? _client?.currency ?? AppConstants.defaultCurrency;

  @override
  void initState() {
    super.initState();
    context.read<ClientBloc>().add(LoadClients());
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.amount);
  double get _taxAmount => _subtotal * (_taxRate / 100);
  double get _total => _subtotal + _taxAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Invoice'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader('Client'),
            BlocBuilder<ClientBloc, ClientState>(
              builder: (context, state) {
                final clients = state is ClientLoaded ? state.clients : <ClientModel>[];
                return DropdownButtonFormField<ClientModel>(
                  value: _client,
                  decoration: const InputDecoration(
                    hintText: 'Select client *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: clients.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (c) => setState(() => _client = c),
                  validator: (v) => v == null ? 'Please select a client' : null,
                );
              },
            ),
            const SizedBox(height: 16),
            _sectionHeader('Dates'),
            Row(
              children: [
                Expanded(child: _datePicker('Issue Date', _issueDate, (d) => setState(() => _issueDate = d))),
                const SizedBox(width: 12),
                Expanded(child: _datePicker('Due Date', _dueDate, (d) => setState(() => _dueDate = d))),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionHeader('Line Items'),
                TextButton.icon(
                  onPressed: () => setState(() => _items.add(_LineItem())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            ..._items.asMap().entries.map((e) => _LineItemRow(
              item: e.value,
              index: e.key,
              canRemove: _items.length > 1,
              onRemove: () => setState(() => _items.removeAt(e.key)),
              onChanged: () => setState(() {}),
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Tax Rate:'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: '0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(suffix: Text('%')),
                    onChanged: (v) => setState(() => _taxRate = double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _TotalRow(label: 'Subtotal', amount: _subtotal, currency: _effectiveCurrency),
            if (_taxRate > 0)
              _TotalRow(
                label: 'Tax ($_taxRate%)',
                amount: _taxAmount,
                currency: _effectiveCurrency,
              ),
            const SizedBox(height: 8),
            _TotalRow(
              label: 'Total',
              amount: _total,
              currency: _effectiveCurrency,
              isBold: true,
            ),
            const SizedBox(height: 16),
            _sectionHeader('Notes'),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Payment terms, notes, etc.'),
            ),
            const SizedBox(height: 24),
            // ── Pro options ────────────────────────────────────────────
            _ProSection(
              isPro: _isPro,
              selectedCurrency: _selectedCurrency,
              isRecurring: _isRecurring,
              recurringInterval: _recurringInterval,
              template: _template,
              onCurrencyChanged: (v) => setState(() => _selectedCurrency = v),
              onRecurringChanged: (v) => setState(() => _isRecurring = v),
              onIntervalChanged: (v) => setState(() => _recurringInterval = v),
              onTemplateChanged: (v) => setState(() => _template = v),
              onUpgradeTap: () => Navigator.pushNamed(context, '/paywall'),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _submit,
            child: Text('Create Invoice • ${Formatters.formatCurrency(_total, _client?.currency ?? 'USD')}'),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }

  Widget _datePicker(String label, DateTime date, ValueChanged<DateTime> onPick) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(Formatters.formatDate(date)),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_items.any((i) => i.description.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all line items')),
      );
      return;
    }

    final invoiceId = _uuid.v4();
    final items = _items.map((item) => InvoiceItemModel(
      id: _uuid.v4(),
      invoiceId: invoiceId,
      description: item.description,
      quantity: item.quantity,
      rate: item.rate,
      amount: item.amount,
    )).toList();

    context.read<InvoiceBloc>().add(CreateInvoice(
      clientId: _client!.id,
      clientName: _client!.name,
      clientEmail: _client!.email,
      items: items,
      taxRate: _taxRate,
      currency: _effectiveCurrency,
      issueDate: _issueDate,
      dueDate: _dueDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isRecurring: _isPro && _isRecurring,
      recurringInterval: _isPro && _isRecurring ? _recurringInterval : null,
      template: _isPro ? _template : AppConstants.templateClassic,
    ));

    Navigator.of(context).pop();
  }
}

class _LineItem {
  String description = '';
  double quantity = 1;
  double rate = 0;
  double get amount => quantity * rate;
}

class _LineItemRow extends StatefulWidget {
  final _LineItem item;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _LineItemRow({
    required this.item,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_LineItemRow> createState() => _LineItemRowState();
}

class _LineItemRowState extends State<_LineItemRow> {
  late final _descController = TextEditingController(text: widget.item.description);
  late final _qtyController = TextEditingController(text: widget.item.quantity.toString());
  late final _rateController = TextEditingController(text: widget.item.rate == 0 ? '' : widget.item.rate.toString());

  @override
  void dispose() {
    _descController.dispose();
    _qtyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha:0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _descController,
                  decoration: const InputDecoration(hintText: 'Description'),
                  onChanged: (v) {
                    widget.item.description = v;
                    widget.onChanged();
                  },
                ),
              ),
              if (widget.canRemove)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.errorColor, size: 20),
                  onPressed: widget.onRemove,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Qty/Hrs'),
                  onChanged: (v) {
                    widget.item.quantity = double.tryParse(v) ?? 1;
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Rate (\$)'),
                  onChanged: (v) {
                    widget.item.rate = double.tryParse(v) ?? 0;
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Amount'),
                  child: Text(
                    Formatters.formatCurrency(widget.item.amount, 'USD'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final bool isBold;

  const _TotalRow({
    required this.label,
    required this.amount,
    required this.currency,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
            ),
          ),
          Text(
            Formatters.formatCurrency(amount, currency),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 20 : 15,
              color: isBold ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pro Features Section ──────────────────────────────────────────────────────

class _ProSection extends StatelessWidget {
  final bool isPro;
  final String? selectedCurrency;
  final bool isRecurring;
  final String recurringInterval;
  final String template;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<bool> onRecurringChanged;
  final ValueChanged<String> onIntervalChanged;
  final ValueChanged<String> onTemplateChanged;
  final VoidCallback onUpgradeTap;

  const _ProSection({
    required this.isPro,
    required this.selectedCurrency,
    required this.isRecurring,
    required this.recurringInterval,
    required this.template,
    required this.onCurrencyChanged,
    required this.onRecurringChanged,
    required this.onIntervalChanged,
    required this.onTemplateChanged,
    required this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Pro Options', style: theme.textTheme.headlineSmall),
            const SizedBox(width: 8),
            if (!isPro)
              GestureDetector(
                onTap: onUpgradeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'UPGRADE',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Currency override
        DropdownButtonFormField<String>(
          value: selectedCurrency,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Currency Override',
            prefixIcon: const Icon(Icons.currency_exchange),
            enabled: isPro,
            suffixIcon: !isPro
                ? const Icon(Icons.lock_outline, size: 18, color: AppTheme.onSurfaceMutedLight)
                : null,
          ),
          hint: const Text('Use client currency (default)'),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('Use client currency')),
            ...AppConstants.currencySymbols.keys.map(
              (c) => DropdownMenuItem(value: c, child: Text('$c  ${AppConstants.currencySymbols[c]}')),
            ),
          ],
          onChanged: isPro ? onCurrencyChanged : null,
        ),
        const SizedBox(height: 16),
        // Recurring toggle
        SwitchListTile(
          value: isPro && isRecurring,
          onChanged: isPro ? onRecurringChanged : null,
          title: const Text('Recurring Invoice'),
          subtitle: Text(isPro ? 'Auto-generate on schedule' : 'Pro feature'),
          secondary: const Icon(Icons.repeat),
          contentPadding: EdgeInsets.zero,
          activeColor: AppTheme.primaryColor,
        ),
        if (isPro && isRecurring) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: recurringInterval,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Repeat Every',
              prefixIcon: Icon(Icons.schedule),
            ),
            items: const [
              DropdownMenuItem(value: AppConstants.recurringWeekly, child: Text('Weekly')),
              DropdownMenuItem(value: AppConstants.recurringMonthly, child: Text('Monthly')),
              DropdownMenuItem(value: AppConstants.recurringQuarterly, child: Text('Quarterly')),
            ],
            onChanged: (v) => onIntervalChanged(v!),
          ),
        ],
        const SizedBox(height: 16),
        // Template picker
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Template',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _TemplateChip(
                  label: 'Classic',
                  value: AppConstants.templateClassic,
                  selected: template,
                  color: AppTheme.primaryColor,
                  enabled: isPro,
                  onTap: isPro ? () => onTemplateChanged(AppConstants.templateClassic) : onUpgradeTap,
                ),
                const SizedBox(width: 8),
                _TemplateChip(
                  label: 'Modern',
                  value: AppConstants.templateModern,
                  selected: template,
                  color: const Color(0xFF1E293B),
                  enabled: isPro,
                  onTap: isPro ? () => onTemplateChanged(AppConstants.templateModern) : onUpgradeTap,
                ),
                const SizedBox(width: 8),
                _TemplateChip(
                  label: 'Minimal',
                  value: AppConstants.templateMinimal,
                  selected: template,
                  color: Colors.grey,
                  enabled: isPro,
                  onTap: isPro ? () => onTemplateChanged(AppConstants.templateMinimal) : onUpgradeTap,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!enabled)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.lock_outline, size: 12, color: AppTheme.onSurfaceMutedLight),
              ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
