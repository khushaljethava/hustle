import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/client/client_bloc.dart';
import '../../../data/models/client_model.dart';
import '../../../core/constants/app_constants.dart';

class AddClientSheet extends StatefulWidget {
  final ClientModel? client;

  const AddClientSheet({super.key, this.client});

  @override
  State<AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<AddClientSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.client?.name);
  late final _emailController = TextEditingController(text: widget.client?.email);
  late final _phoneController = TextEditingController(text: widget.client?.phone);
  late final _companyController = TextEditingController(text: widget.client?.company);
  late final _rateController = TextEditingController(
    text: widget.client?.defaultRate.toString() ?? '50',
  );
  late String _currency = widget.client?.currency ?? 'USD';

  bool get _isEditing => widget.client != null;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomPad),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha:0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(_isEditing ? 'Edit Client' : 'New Client', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                autofocus: !_isEditing,
                decoration: const InputDecoration(
                  hintText: 'Client name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v?.trim().isEmpty == true ? 'Name is required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  hintText: 'Company (optional)',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email (optional)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Phone (optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text('Default Rate', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _rateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Hourly rate',
                        prefixText:
                            AppConstants.currencySymbols[_currency] ?? _currency,
                      ),
                      validator: (v) => v?.isEmpty == true || double.tryParse(v!) == null
                          ? 'Valid rate required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      isExpanded: true,
                      decoration: const InputDecoration(hintText: 'Currency'),
                      items: AppConstants.currencySymbols.keys
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (c) => setState(() => _currency = c!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isEditing ? 'Save Changes' : 'Add Client'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_isEditing) {
      context.read<ClientBloc>().add(UpdateClient(
        widget.client!.copyWith(
          name: _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
          defaultRate: double.parse(_rateController.text),
          currency: _currency,
        ),
      ));
    } else {
      context.read<ClientBloc>().add(CreateClient(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
        defaultRate: double.parse(_rateController.text),
        currency: _currency,
      ));
    }

    Navigator.of(context).pop();
  }
}
