import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/timer/timer_bloc.dart';
import '../../blocs/task/task_bloc.dart';
import '../../blocs/client/client_bloc.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/undo_snackbar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/client_model.dart';
import '../../../data/models/time_entry_model.dart';
import '../../../di/service_locator.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  TaskModel? _selectedTask;
  ClientModel? _selectedClient;

  String get _currency => sl<ValueNotifier<String>>().value;

  @override
  void initState() {
    super.initState();
    sl<ValueNotifier<String>>().addListener(_onCurrencyChanged);
    context.read<TimerBloc>().add(LoadTimerState());
    context.read<TaskBloc>().add(const LoadTasks(statusFilter: 'pending'));
    context.read<ClientBloc>().add(LoadClients());
  }

  void _onCurrencyChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    sl<ValueNotifier<String>>().removeListener(_onCurrencyChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showManualEntry(context),
            tooltip: 'Manual Entry',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTimerSection(context),
          Expanded(child: _buildEntriesList(context)),
        ],
      ),
    );
  }

  Widget _buildTimerSection(BuildContext context) {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, state) {
        final isRunning = state is TimerRunning;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isRunning
                ? const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isRunning ? null : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isRunning
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha:0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              RepaintBoundary(
                child: Text(
                  isRunning
                      ? Formatters.formatDuration(state.elapsed)
                      : '00:00',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: isRunning ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (isRunning && state.entry.taskTitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.entry.taskTitle!,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                if (state.entry.clientName != null)
                  Text(
                    state.entry.clientName!,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
              ],
              if (!isRunning) ...[
                const SizedBox(height: 16),
                _buildTaskSelector(context),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isRunning) ...[
                    _TimerButton(
                      icon: Icons.stop_rounded,
                      label: 'Stop',
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.read<TimerBloc>().add(StopTimer());
                      },
                      size: 72,
                    ),
                  ] else ...[
                    _TimerButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'Start',
                      color: Colors.white,
                      backgroundColor: AppTheme.primaryColor,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _startTimer(context);
                      },
                      size: 72,
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskSelector(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, taskState) {
        final tasks = taskState is TaskLoaded ? taskState.tasks : <TaskModel>[];
        return Column(
          children: [
            DropdownButtonFormField<TaskModel>(
              value: _selectedTask,
              decoration: InputDecoration(
                hintText: 'Select task (optional)',
                prefixIcon: const Icon(Icons.task_alt),
                fillColor: Colors.grey.withValues(alpha:0.08),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('No task')),
                ...tasks.map((t) => DropdownMenuItem(value: t, child: Text(t.title))),
              ],
              onChanged: (t) {
                setState(() {
                  _selectedTask = t;
                  if (t?.clientId != null) {
                    final clients = (context.read<ClientBloc>().state as ClientLoaded?)?.clients ?? [];
                    _selectedClient = clients.firstWhere(
                      (c) => c.id == t!.clientId,
                      orElse: () => _selectedClient!,
                    );
                  }
                });
              },
            ),
            if (_selectedTask == null) ...[
              const SizedBox(height: 8),
              BlocBuilder<ClientBloc, ClientState>(
                builder: (context, clientState) {
                  final clients = clientState is ClientLoaded ? clientState.clients : <ClientModel>[];
                  return DropdownButtonFormField<ClientModel>(
                    value: _selectedClient,
                    decoration: InputDecoration(
                      hintText: 'Select client (optional)',
                      prefixIcon: const Icon(Icons.person_outline),
                      fillColor: Colors.grey.withValues(alpha:0.08),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No client')),
                      ...clients.map((c) => DropdownMenuItem(value: c, child: Text(c.name))),
                    ],
                    onChanged: (c) => setState(() => _selectedClient = c),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEntriesList(BuildContext context) {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, state) {
        List<TimeEntryModel> entries = [];
        Duration totalToday = Duration.zero;
        double earnings = 0;

        if (state is TimerRunning) {
          entries = state.todayEntries;
        } else if (state is TimerStopped) {
          entries = state.todayEntries;
          totalToday = state.totalToday;
          earnings = state.potentialEarnings;
        }

        final completedEntries = entries.where((e) => e.endTime != null).toList();

        if (completedEntries.isEmpty && state is! TimerRunning) {
          return const Center(
            child: Text(
              'No entries today\nStart the timer to track time',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          children: [
            if (state is TimerStopped && totalToday > Duration.zero)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text('Total Today', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              Formatters.formatDurationHours(totalToday),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text('Potential Earnings', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              Formatters.formatCurrency(earnings, _currency),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Today's Log", style: Theme.of(context).textTheme.headlineSmall),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: completedEntries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final entry = completedEntries[i];
                  return _TimeEntryCard(
                    entry: entry,
                    currency: _currency,
                    onDelete: () {
                      context
                          .read<TimerBloc>()
                          .add(DeleteTimeEntry(entry.id));
                      showUndoSnackBar(
                        context,
                        message: 'Time entry deleted',
                        onUndo: () => context.read<TimerBloc>().add(
                              AddManualEntry(
                                startTime: entry.startTime,
                                endTime: entry.endTime!,
                                taskId: entry.taskId,
                                taskTitle: entry.taskTitle,
                                clientId: entry.clientId,
                                clientName: entry.clientName,
                                notes: entry.notes,
                                hourlyRate: entry.hourlyRate,
                                isBillable: entry.isBillable,
                              ),
                            ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _startTimer(BuildContext context) {
    context.read<TimerBloc>().add(StartTimer(
      taskId: _selectedTask?.id,
      taskTitle: _selectedTask?.title,
      clientId: _selectedTask?.clientId ?? _selectedClient?.id,
      clientName: _selectedTask?.clientName ?? _selectedClient?.name,
      hourlyRate: _selectedTask?.hourlyRate ?? _selectedClient?.defaultRate,
      isBillable: _selectedTask?.isBillable ?? true,
    ));
  }

  void _showManualEntry(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<TimerBloc>(),
        child: const _ManualEntryDialog(),
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;
  final double size;

  const _TimerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: size * 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _TimeEntryCard extends StatelessWidget {
  final TimeEntryModel entry;
  final String currency;
  final VoidCallback onDelete;

  const _TimeEntryCard({
    required this.entry,
    required this.currency,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: entry.isBillable ? AppTheme.primaryColor : Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.taskTitle ?? 'Untracked',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${Formatters.formatTime(entry.startTime)} → ${Formatters.formatTime(entry.endTime!)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.formatDurationHours(entry.actualDuration),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (entry.isBillable && entry.hourlyRate != null)
                Text(
                  Formatters.formatCurrency(entry.earnings, currency),
                  style: const TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ManualEntryDialog extends StatefulWidget {
  const _ManualEntryDialog();

  @override
  State<_ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<_ManualEntryDialog> {
  final DateTime _today = DateTime.now();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    final oneHourAgo = now.replacing(
      hour: (now.hour - 1) % 24 < 0 ? 23 : (now.hour - 1) % 24,
    );
    _startTime = oneHourAgo;
    _endTime = now;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  DateTime _combine(TimeOfDay t) => DateTime(
        _today.year,
        _today.month,
        _today.day,
        t.hour,
        t.minute,
      );

  void _submit() {
    final start = _combine(_startTime);
    var end = _combine(_endTime);
    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }
    context.read<TimerBloc>().add(AddManualEntry(
          startTime: start,
          endTime: end,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manual Time Entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Start Time'),
            trailing: Text(Formatters.formatTime(_combine(_startTime))),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _startTime);
              if (t != null) setState(() => _startTime = t);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('End Time'),
            trailing: Text(Formatters.formatTime(_combine(_endTime))),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _endTime);
              if (t != null) setState(() => _endTime = t);
            },
          ),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(hintText: 'Notes (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
