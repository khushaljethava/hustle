import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/task/task_bloc.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/undo_snackbar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/task_model.dart';
import 'add_task_sheet.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(const LoadTasks());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _FilterChips(
            selected: _filter,
            onChanged: (f) {
              setState(() => _filter = f);
              context.read<TaskBloc>().add(LoadTasks(
                statusFilter: f == 'all' ? null : f,
              ));
            },
          ),
        ),
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.errorColor),
            );
          }
        },
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = state is TaskLoaded
              ? state.tasks
              : state is TaskOperationSuccess
                  ? state.tasks
                  : <TaskModel>[];

          if (tasks.isEmpty) {
            return EmptyState(
              icon: Icons.task_alt,
              title: 'No tasks yet',
              subtitle: _filter == 'all'
                  ? 'Create your first task to get started'
                  : 'No ${_filter.replaceAll('_', ' ')} tasks',
              actionLabel: _filter == 'all' ? 'New Task' : null,
              onAction: _filter == 'all' ? () => _showAddTask(context) : null,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final task = tasks[i];
              return _TaskCard(
                task: task,
                onStatusChange: (status) {
                  context
                      .read<TaskBloc>()
                      .add(UpdateTaskStatus(task.id, status));
                },
                onDelete: () {
                  context.read<TaskBloc>().add(DeleteTask(task.id));
                  showUndoSnackBar(
                    context,
                    message: 'Task deleted',
                    onUndo: () => context.read<TaskBloc>().add(
                          CreateTask(
                            title: task.title,
                            description: task.description,
                            clientId: task.clientId,
                            clientName: task.clientName,
                            priority: task.priority,
                            hourlyRate: task.hourlyRate,
                            estimatedHours: task.estimatedHours,
                            dueDate: task.dueDate,
                            isBillable: task.isBillable,
                          ),
                        ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'tasks_fab',
        onPressed: () => _showAddTask(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TaskBloc>(),
        child: const AddTaskSheet(),
      ),
    );
  }

  void _showFilterSheet() {}
}

class _FilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all', 'All'),
      ('pending', 'Pending'),
      ('in_progress', 'Active'),
      ('completed', 'Done'),
    ];

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: filters.map((f) {
          final (value, label) = f;
          final isSelected = selected == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onChanged(value),
              selectedColor: AppTheme.primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final ValueChanged<String> onStatusChange;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.isCompleted;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
      ),
      onDismissed: (_) => onDelete(),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AccessibleCheckbox(
                  value: isCompleted,
                  semanticsLabel: isCompleted ? 'Mark ${task.title} incomplete' : 'Mark ${task.title} complete',
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    onStatusChange(v ? 'completed' : 'pending');
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted
                          ? theme.colorScheme.onSurface.withValues(alpha:0.4)
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                PriorityBadge(task.priority),
              ],
            ),
            if (task.description != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Text(
                  task.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha:0.5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Row(
                children: [
                  if (task.clientName != null) ...[
                    Icon(Icons.person_outline, size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha:0.4)),
                    const SizedBox(width: 4),
                    Text(
                      task.clientName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor.withValues(alpha:0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: task.isOverdue ? AppTheme.errorColor : theme.colorScheme.onSurface.withValues(alpha:0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.formatRelativeDue(task.dueDate!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: task.isOverdue ? AppTheme.errorColor : theme.colorScheme.onSurface.withValues(alpha:0.5),
                        fontWeight: task.isOverdue ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (!isCompleted)
                    _StatusButton(
                      status: task.status,
                      onToggle: () {
                        final next = task.isPending ? 'in_progress' : 'completed';
                        onStatusChange(next);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String status;
  final VoidCallback onToggle;

  const _StatusButton({required this.status, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isPending
              ? AppTheme.primaryColor.withValues(alpha:0.1)
              : AppTheme.successColor.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPending ? Icons.play_arrow : Icons.check,
              size: 12,
              color: isPending ? AppTheme.primaryColor : AppTheme.successColor,
            ),
            const SizedBox(width: 4),
            Text(
              isPending ? 'Start' : 'Complete',
              style: TextStyle(
                color: isPending ? AppTheme.primaryColor : AppTheme.successColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
