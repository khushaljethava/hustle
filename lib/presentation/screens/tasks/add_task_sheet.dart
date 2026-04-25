import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/task/task_bloc.dart';
import '../../blocs/client/client_bloc.dart';
import '../../../data/models/client_model.dart';
import '../../../core/theme/app_theme.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _rateController = TextEditingController();

  String _priority = 'medium';
  ClientModel? _selectedClient;
  DateTime? _dueDate;
  bool _isBillable = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('New Task', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Task title *',
                prefixIcon: Icon(Icons.task_alt),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Title is required' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
                prefixIcon: Icon(Icons.notes),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Text('Priority', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _PrioritySelector(
              selected: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            const SizedBox(height: 16),
            BlocBuilder<ClientBloc, ClientState>(
              builder: (context, state) {
                final clients = state is ClientLoaded ? state.clients : <ClientModel>[];
                return DropdownButtonFormField<ClientModel>(
                  value: _selectedClient,
                  decoration: const InputDecoration(
                    hintText: 'Client (optional)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No client')),
                    ...clients.map((c) => DropdownMenuItem(value: c, child: Text(c.name))),
                  ],
                  onChanged: (c) {
                    setState(() {
                      _selectedClient = c;
                      if (c != null && _rateController.text.isEmpty) {
                        _rateController.text = c.defaultRate.toString();
                      }
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'Hourly rate',
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickDueDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today),
                        hintText: 'Due date',
                      ),
                      child: Text(
                        _dueDate != null
                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                            : 'Due date',
                        style: TextStyle(
                          color: _dueDate != null
                              ? null
                              : Theme.of(context).hintColor,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: _isBillable,
                  onChanged: (v) => setState(() => _isBillable = v),
                  activeColor: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text('Billable task', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Create Task'),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<TaskBloc>().add(CreateTask(
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      clientId: _selectedClient?.id,
      clientName: _selectedClient?.name,
      priority: _priority,
      hourlyRate: _rateController.text.isNotEmpty ? double.tryParse(_rateController.text) : null,
      dueDate: _dueDate,
      isBillable: _isBillable,
    ));

    Navigator.of(context).pop();
  }
}

class _PrioritySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PrioritySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final priorities = [
      ('low', 'Low', Colors.grey),
      ('medium', 'Medium', AppTheme.infoColor),
      ('high', 'High', AppTheme.warningColor),
      ('urgent', 'Urgent', AppTheme.errorColor),
    ];

    return Row(
      children: priorities.map((p) {
        final (value, label, color) = p;
        final isSelected = selected == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha:0.15) : Colors.grey.withValues(alpha:0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected ? Border.all(color: color, width: 1.5) : null,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? color : Colors.grey,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
