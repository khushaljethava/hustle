import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/time_entry_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/client_repository.dart';

// Events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {}

// States
abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final double monthlyEarned;
  final double outstanding;
  final double totalEarned;
  final int unpaidInvoices;
  final int overdueInvoices;
  final Duration todayHours;
  final Duration weekHours;
  final double billablePercentage;
  final int pendingTasks;
  final int inProgressTasks;
  final int completedTasksToday;
  final int totalClients;
  final List<Map<String, dynamic>> monthlyChart;
  final double potentialEarnings;

  const DashboardLoaded({
    required this.monthlyEarned,
    required this.outstanding,
    required this.totalEarned,
    required this.unpaidInvoices,
    required this.overdueInvoices,
    required this.todayHours,
    required this.weekHours,
    required this.billablePercentage,
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.completedTasksToday,
    required this.totalClients,
    required this.monthlyChart,
    required this.potentialEarnings,
  });

  @override
  List<Object?> get props => [monthlyEarned, outstanding, todayHours, pendingTasks];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final InvoiceRepository _invoiceRepository;
  final TimeEntryRepository _timeRepository;
  final TaskRepository _taskRepository;
  final ClientRepository _clientRepository;

  DashboardBloc(
    this._invoiceRepository,
    this._timeRepository,
    this._taskRepository,
    this._clientRepository,
  ) : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
  }

  Future<void> _onLoad(LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // Run all queries in parallel
      final results = await Future.wait([
        _invoiceRepository.getDashboardStats(),
        _timeRepository.getDashboardStats(startDate: todayStart, endDate: now),
        _timeRepository.getDashboardStats(startDate: weekStart, endDate: now),
        _timeRepository.getDashboardStats(startDate: monthStart, endDate: now),
        _taskRepository.getStatusCounts(),
        _invoiceRepository.getMonthlyEarnings(6),
        _clientRepository.getAll(),
        _timeRepository.getForDate(now),
      ]);

      final invoiceStats = results[0] as Map<String, dynamic>;
      final todayTimeStats = results[1] as Map<String, dynamic>;
      final weekTimeStats = results[2] as Map<String, dynamic>;
      final clients = results[6] as List;
      final monthlyChart = results[5] as List<Map<String, dynamic>>;
      final taskCounts = results[4] as Map<String, int>;

      final todaySeconds = todayTimeStats['billableSeconds'] as int;
      final todayNonBillable = todayTimeStats['nonBillableSeconds'] as int;
      final weekSeconds = (weekTimeStats['billableSeconds'] as int) + (weekTimeStats['nonBillableSeconds'] as int);
      final totalTodaySeconds = todaySeconds + todayNonBillable;
      final billablePercent = totalTodaySeconds > 0 ? (todaySeconds / totalTodaySeconds) * 100 : 0.0;

      emit(DashboardLoaded(
        monthlyEarned: (invoiceStats['monthlyEarned'] as num).toDouble(),
        outstanding: (invoiceStats['outstanding'] as num).toDouble(),
        totalEarned: (invoiceStats['totalEarned'] as num).toDouble(),
        unpaidInvoices: invoiceStats['unpaidCount'] as int,
        overdueInvoices: invoiceStats['overdueCount'] as int,
        todayHours: Duration(seconds: todaySeconds + todayNonBillable),
        weekHours: Duration(seconds: weekSeconds),
        billablePercentage: billablePercent,
        pendingTasks: taskCounts['pending'] ?? 0,
        inProgressTasks: taskCounts['in_progress'] ?? 0,
        completedTasksToday: taskCounts['completed'] ?? 0,
        totalClients: clients.length,
        monthlyChart: monthlyChart,
        potentialEarnings: (todayTimeStats['potentialEarnings'] as num).toDouble(),
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
