import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/timer/timer_bloc.dart';
import '../../blocs/task/task_bloc.dart';
import '../../widgets/common/app_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/service_locator.dart';
import '../tasks/add_task_sheet.dart';
import '../../../core/services/pro_service.dart';
import '../dashboard/dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTimer;
  final VoidCallback? onNavigateToTasks;

  const HomeScreen({super.key, this.onNavigateToTimer, this.onNavigateToTasks});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String get _currency => sl<ValueNotifier<String>>().value;

  @override
  void initState() {
    super.initState();
    sl<ValueNotifier<String>>().addListener(_onCurrencyChanged);
    context.read<DashboardBloc>().add(LoadDashboard());
    context.read<TimerBloc>().add(LoadTimerState());
    context.read<TaskBloc>().add(LoadTodayTasks());
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
    final theme = Theme.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<DashboardBloc>().add(LoadDashboard());
          context.read<TimerBloc>().add(LoadTimerState());
          context.read<TaskBloc>().add(LoadTodayTasks());
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: false,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getGreetingIcon(),
                          size: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getGreeting(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Dashboard',
                      style: theme.textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  tooltip: 'Profile',
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _buildTimerCard(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _buildEarningsSection(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _buildTasksSection(context),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppTheme.bottomScrollPadding)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_fab',
        onPressed: () => _showAddTask(context),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_outlined;
    if (hour < 17) return Icons.wb_cloudy_outlined;
    return Icons.nightlight_round_outlined;
  }

  Widget _buildTimerCard(BuildContext context) {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, state) {
        if (state is TimerRunning) {
          return _RunningTimerCard(
            state: state,
            onStop: () => context.read<TimerBloc>().add(StopTimer()),
          );
        }
        return _IdleTimerCard(
          onStart: () => widget.onNavigateToTimer?.call(),
        );
      },
    );
  }

  Widget _buildEarningsSection(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const _LoadingStats();
        }
        if (state is! DashboardLoaded) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Month', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Earned',
                      value: Formatters.formatCurrency(state.monthlyEarned, _currency),
                      icon: Icons.trending_up,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Outstanding',
                      value: Formatters.formatCurrency(state.outstanding, _currency),
                      subtitle: '${state.unpaidInvoices} invoice${state.unpaidInvoices != 1 ? 's' : ''}',
                      icon: Icons.schedule,
                      color: state.overdueInvoices > 0 ? AppTheme.errorColor : AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatCard(
                      label: "Today's Hours",
                      value: Formatters.formatDurationDecimal(state.todayHours),
                      subtitle: '${state.billablePercentage.toStringAsFixed(0)}% billable',
                      icon: Icons.access_time,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Potential',
                      value: Formatters.formatCurrency(state.potentialEarnings, _currency),
                      subtitle: 'from today',
                      icon: Icons.monetization_on,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  if (sl<ProService>().isProUser) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    );
                  } else {
                    Navigator.pushNamed(context, '/paywall');
                  }
                },
                icon: sl<ProService>().isProUser
                    ? const Icon(Icons.bar_chart, size: 16)
                    : const Icon(Icons.lock_outline, size: 16),
                label: const Text('View Full Analytics'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTasksSection(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is! TaskLoaded) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Tasks", style: Theme.of(context).textTheme.headlineSmall),
                TextButton(
                  onPressed: widget.onNavigateToTasks,
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.tasks.isEmpty)
              const _EmptyTasks()
            else
              ...state.tasks.take(5).map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _HomeTaskItem(task: task),
                  )),
          ],
        );
      },
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

}

class _RunningTimerCard extends StatelessWidget {
  final TimerRunning state;
  final VoidCallback onStop;

  const _RunningTimerCard({required this.state, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha:0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.secondaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Timer Running',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.formatDuration(state.elapsed),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                if (state.entry.taskTitle != null)
                  Text(
                    state.entry.taskTitle!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onStop();
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.stop_rounded, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleTimerCard extends StatelessWidget {
  final VoidCallback onStart;

  const _IdleTimerCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onStart,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Timer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Track your work time',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.5),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.3),
          ),
        ],
      ),
    );
  }
}

class _HomeTaskItem extends StatelessWidget {
  final dynamic task;

  const _HomeTaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.status == 'completed';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AccessibleCheckbox(
            value: isCompleted,
            semanticsLabel: isCompleted ? 'Mark ${task.title} incomplete' : 'Mark ${task.title} complete',
            onChanged: (v) {
              HapticFeedback.lightImpact();
              context.read<TaskBloc>().add(UpdateTaskStatus(
                task.id,
                v ? 'completed' : 'pending',
              ));
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted
                        ? theme.colorScheme.onSurface.withValues(alpha:0.4)
                        : null,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.clientName != null)
                  Text(
                    task.clientName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor.withValues(alpha:0.7),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PriorityBadge(task.priority),
        ],
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.task_alt, size: 40, color: AppTheme.successColor),
          const SizedBox(height: 12),
          Text(
            "You're all caught up!",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'No tasks due today',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingStats extends StatelessWidget {
  const _LoadingStats();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This Month', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ShimmerCard()),
            const SizedBox(width: 12),
            Expanded(child: _ShimmerCard()),
          ],
        ),
      ],
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
