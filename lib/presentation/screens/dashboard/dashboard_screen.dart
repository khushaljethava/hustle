import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/common/app_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/service_locator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String get _currency => sl<ValueNotifier<String>>().value;

  @override
  void initState() {
    super.initState();
    sl<ValueNotifier<String>>().addListener(_onCurrencyChanged);
    context.read<DashboardBloc>().add(LoadDashboard());
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
        title: const Text('Analytics'),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is! DashboardLoaded) {
            return const Center(child: Text('No data yet'));
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<DashboardBloc>().add(LoadDashboard()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildEarningsChart(context, state),
                const SizedBox(height: 16),
                _buildMetricsGrid(context, state),
                const SizedBox(height: 16),
                _buildTimeBreakdown(context, state),
                const SizedBox(height: 16),
                _buildTaskStats(context, state),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEarningsChart(BuildContext context, DashboardLoaded state) {
    if (state.monthlyChart.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Earnings Trend', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 40),
            const Center(child: Text('No data yet', style: TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Earnings Trend', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Last 6 months',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: state.monthlyChart.fold(0.0, (max, m) {
                  final earned = (m['earned'] as num).toDouble();
                  return earned > max ? earned : max;
                }) * 1.3,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= state.monthlyChart.length) return const SizedBox();
                        final month = state.monthlyChart[value.toInt()]['month'] as String;
                        final parts = month.split('-');
                        const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                        final monthIndex = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
                        return Text(
                          months[monthIndex],
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withValues(alpha:0.1),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: state.monthlyChart.asMap().entries.map((e) {
                  final earned = (e.value['earned'] as num).toDouble();
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: earned,
                        color: AppTheme.primaryColor,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, DashboardLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Key Metrics', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total Earned',
                  value: Formatters.formatCurrency(state.totalEarned, _currency),
                  icon: Icons.account_balance_wallet,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'This Month',
                  value: Formatters.formatCurrency(state.monthlyEarned, _currency),
                  icon: Icons.calendar_today,
                  color: AppTheme.primaryColor,
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
                  label: 'Outstanding',
                  value: Formatters.formatCurrency(state.outstanding, _currency),
                  subtitle: '${state.unpaidInvoices} invoice(s)',
                  icon: Icons.pending,
                  color: state.overdueInvoices > 0 ? AppTheme.errorColor : AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Week Hours',
                  value: Formatters.formatDurationDecimal(state.weekHours),
                  icon: Icons.access_time,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBreakdown(BuildContext context, DashboardLoaded state) {
    final billable = state.billablePercentage;
    final nonBillable = 100 - billable;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Time Breakdown (Today)', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (state.todayHours == Duration.zero)
            const Center(child: Text('No time tracked today', style: TextStyle(color: Colors.grey)))
          else ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 120,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: [
                          PieChartSectionData(
                            value: billable,
                            color: AppTheme.primaryColor,
                            title: '${billable.toStringAsFixed(0)}%',
                            radius: 40,
                            titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          PieChartSectionData(
                            value: nonBillable,
                            color: Colors.grey.withValues(alpha:0.3),
                            title: '${nonBillable.toStringAsFixed(0)}%',
                            radius: 35,
                            titleStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendItem(color: AppTheme.primaryColor, label: 'Billable', value: '${billable.toStringAsFixed(0)}%'),
                      const SizedBox(height: 12),
                      _LegendItem(color: Colors.grey, label: 'Non-billable', value: '${nonBillable.toStringAsFixed(0)}%'),
                      const SizedBox(height: 12),
                      _LegendItem(
                        color: AppTheme.successColor,
                        label: 'Total Today',
                        value: Formatters.formatDurationHours(state.todayHours),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskStats(BuildContext context, DashboardLoaded state) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Task Overview', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              _TaskStatItem(
                count: state.pendingTasks,
                label: 'Pending',
                color: Colors.orange,
              ),
              _TaskStatItem(
                count: state.inProgressTasks,
                label: 'Active',
                color: AppTheme.primaryColor,
              ),
              _TaskStatItem(
                count: state.completedTasksToday,
                label: 'Completed',
                color: AppTheme.successColor,
              ),
              _TaskStatItem(
                count: state.totalClients,
                label: 'Clients',
                color: AppTheme.secondaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

class _TaskStatItem extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _TaskStatItem({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
