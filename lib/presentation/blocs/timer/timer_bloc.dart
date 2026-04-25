import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/time_entry_model.dart';
import '../../../data/repositories/time_entry_repository.dart';

// Events
abstract class TimerEvent extends Equatable {
  const TimerEvent();
  @override
  List<Object?> get props => [];
}

class LoadTimerState extends TimerEvent {}

class StartTimer extends TimerEvent {
  final String? taskId;
  final String? taskTitle;
  final String? clientId;
  final String? clientName;
  final double? hourlyRate;
  final bool isBillable;

  const StartTimer({
    this.taskId,
    this.taskTitle,
    this.clientId,
    this.clientName,
    this.hourlyRate,
    this.isBillable = true,
  });

  @override
  List<Object?> get props => [taskId, clientId];
}

class StopTimer extends TimerEvent {}

class TimerTick extends TimerEvent {
  final Duration elapsed;
  const TimerTick(this.elapsed);
  @override
  List<Object?> get props => [elapsed];
}

class LoadTodayEntries extends TimerEvent {}

class DeleteTimeEntry extends TimerEvent {
  final String entryId;
  const DeleteTimeEntry(this.entryId);
  @override
  List<Object?> get props => [entryId];
}

class AddManualEntry extends TimerEvent {
  final DateTime startTime;
  final DateTime endTime;
  final String? taskId;
  final String? taskTitle;
  final String? clientId;
  final String? clientName;
  final String? notes;
  final double? hourlyRate;
  final bool isBillable;

  const AddManualEntry({
    required this.startTime,
    required this.endTime,
    this.taskId,
    this.taskTitle,
    this.clientId,
    this.clientName,
    this.notes,
    this.hourlyRate,
    this.isBillable = true,
  });

  @override
  List<Object?> get props => [startTime, endTime, taskId, clientId, notes];
}

// States
abstract class TimerState extends Equatable {
  const TimerState();
  @override
  List<Object?> get props => [];
}

class TimerInitial extends TimerState {}

class TimerRunning extends TimerState {
  final TimeEntryModel entry;
  final Duration elapsed;
  final List<TimeEntryModel> todayEntries;

  const TimerRunning({
    required this.entry,
    required this.elapsed,
    required this.todayEntries,
  });

  @override
  List<Object?> get props => [entry, elapsed, todayEntries];
}

class TimerStopped extends TimerState {
  final List<TimeEntryModel> todayEntries;
  final Duration totalToday;
  final double potentialEarnings;

  const TimerStopped({
    required this.todayEntries,
    required this.totalToday,
    required this.potentialEarnings,
  });

  @override
  List<Object?> get props => [todayEntries, totalToday, potentialEarnings];
}

class TimerError extends TimerState {
  final String message;
  const TimerError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class TimerBloc extends Bloc<TimerEvent, TimerState> {
  final TimeEntryRepository _repository;
  Timer? _ticker;

  TimerBloc(this._repository) : super(TimerInitial()) {
    on<LoadTimerState>(_onLoad);
    on<StartTimer>(_onStart);
    on<StopTimer>(_onStop);
    on<TimerTick>(_onTick);
    on<LoadTodayEntries>(_onLoadToday);
    on<DeleteTimeEntry>(_onDeleteEntry);
    on<AddManualEntry>(_onAddManualEntry);
  }

  Future<void> _onLoad(LoadTimerState event, Emitter<TimerState> emit) async {
    try {
      final running = await _repository.getRunningEntry();
      final today = await _repository.getForDate(DateTime.now());

      if (running != null) {
        _startTicker(running);
        final elapsed = DateTime.now().difference(running.startTime);
        emit(TimerRunning(entry: running, elapsed: elapsed, todayEntries: today));
      } else {
        final stats = _calculateStats(today);
        emit(TimerStopped(
          todayEntries: today,
          totalToday: stats.$1,
          potentialEarnings: stats.$2,
        ));
      }
    } catch (e) {
      emit(TimerError(e.toString()));
    }
  }

  Future<void> _onStart(StartTimer event, Emitter<TimerState> emit) async {
    try {
      final entry = await _repository.startTimer(
        taskId: event.taskId,
        taskTitle: event.taskTitle,
        clientId: event.clientId,
        clientName: event.clientName,
        hourlyRate: event.hourlyRate,
        isBillable: event.isBillable,
      );
      final today = await _repository.getForDate(DateTime.now());
      _startTicker(entry);
      emit(TimerRunning(entry: entry, elapsed: Duration.zero, todayEntries: today));
    } catch (e) {
      emit(TimerError(e.toString()));
    }
  }

  Future<void> _onStop(StopTimer event, Emitter<TimerState> emit) async {
    try {
      _stopTicker();
      await _repository.stopRunningTimer();
      final today = await _repository.getForDate(DateTime.now());
      final stats = _calculateStats(today);
      emit(TimerStopped(
        todayEntries: today,
        totalToday: stats.$1,
        potentialEarnings: stats.$2,
      ));
    } catch (e) {
      emit(TimerError(e.toString()));
    }
  }

  void _onTick(TimerTick event, Emitter<TimerState> emit) {
    if (state is TimerRunning) {
      final current = state as TimerRunning;
      emit(TimerRunning(
        entry: current.entry,
        elapsed: event.elapsed,
        todayEntries: current.todayEntries,
      ));
    }
  }

  Future<void> _onLoadToday(LoadTodayEntries event, Emitter<TimerState> emit) async {
    try {
      final today = await _repository.getForDate(DateTime.now());
      final running = await _repository.getRunningEntry();
      if (running != null && state is TimerRunning) {
        final current = state as TimerRunning;
        emit(TimerRunning(entry: current.entry, elapsed: current.elapsed, todayEntries: today));
      } else {
        final stats = _calculateStats(today);
        emit(TimerStopped(
          todayEntries: today,
          totalToday: stats.$1,
          potentialEarnings: stats.$2,
        ));
      }
    } catch (e) {
      emit(TimerError(e.toString()));
    }
  }

  Future<void> _onDeleteEntry(DeleteTimeEntry event, Emitter<TimerState> emit) async {
    try {
      await _repository.delete(event.entryId);
      add(LoadTodayEntries());
    } catch (e) {
      emit(TimerError(e.toString()));
    }
  }

  Future<void> _onAddManualEntry(
    AddManualEntry event,
    Emitter<TimerState> emit,
  ) async {
    try {
      await _repository.addManualEntry(
        startTime: event.startTime,
        endTime: event.endTime,
        taskId: event.taskId,
        taskTitle: event.taskTitle,
        clientId: event.clientId,
        clientName: event.clientName,
        notes: event.notes,
        hourlyRate: event.hourlyRate,
        isBillable: event.isBillable,
      );
      add(LoadTodayEntries());
    } catch (e) {
      emit(TimerError(e.toString()));
    }
  }

  void _startTicker(TimeEntryModel entry) {
    _stopTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(entry.startTime);
      add(TimerTick(elapsed));
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  (Duration, double) _calculateStats(List<TimeEntryModel> entries) {
    Duration total = Duration.zero;
    double earnings = 0;
    for (final entry in entries) {
      if (entry.endTime != null) {
        total += entry.actualDuration;
        earnings += entry.earnings;
      }
    }
    return (total, earnings);
  }

  @override
  Future<void> close() {
    _stopTicker();
    return super.close();
  }
}
