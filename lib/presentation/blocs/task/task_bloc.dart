import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';

// Events
abstract class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {
  final String? statusFilter;
  final String? clientFilter;
  const LoadTasks({this.statusFilter, this.clientFilter});
  @override
  List<Object?> get props => [statusFilter, clientFilter];
}

class LoadTodayTasks extends TaskEvent {}

class CreateTask extends TaskEvent {
  final String title;
  final String? description;
  final String? clientId;
  final String? clientName;
  final String priority;
  final double? hourlyRate;
  final double? estimatedHours;
  final DateTime? dueDate;
  final bool isBillable;

  const CreateTask({
    required this.title,
    this.description,
    this.clientId,
    this.clientName,
    required this.priority,
    this.hourlyRate,
    this.estimatedHours,
    this.dueDate,
    this.isBillable = true,
  });

  @override
  List<Object?> get props => [title, priority, clientId];
}

class UpdateTask extends TaskEvent {
  final TaskModel task;
  const UpdateTask(this.task);
  @override
  List<Object?> get props => [task];
}

class UpdateTaskStatus extends TaskEvent {
  final String taskId;
  final String status;
  const UpdateTaskStatus(this.taskId, this.status);
  @override
  List<Object?> get props => [taskId, status];
}

class DeleteTask extends TaskEvent {
  final String taskId;
  const DeleteTask(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

// States
abstract class TaskState extends Equatable {
  const TaskState();
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}
class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<TaskModel> tasks;
  final Map<String, int> statusCounts;
  const TaskLoaded({required this.tasks, required this.statusCounts});
  @override
  List<Object?> get props => [tasks, statusCounts];
}

class TaskError extends TaskState {
  final String message;
  const TaskError(this.message);
  @override
  List<Object?> get props => [message];
}

class TaskOperationSuccess extends TaskState {
  final String message;
  final List<TaskModel> tasks;
  final Map<String, int> statusCounts;
  const TaskOperationSuccess({required this.message, required this.tasks, required this.statusCounts});
  @override
  List<Object?> get props => [message, tasks];
}

// BLoC
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _repository;
  String? _currentStatusFilter;
  String? _currentClientFilter;

  TaskBloc(this._repository) : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<LoadTodayTasks>(_onLoadTodayTasks);
    on<CreateTask>(_onCreateTask);
    on<UpdateTask>(_onUpdateTask);
    on<UpdateTaskStatus>(_onUpdateTaskStatus);
    on<DeleteTask>(_onDeleteTask);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      _currentStatusFilter = event.statusFilter;
      _currentClientFilter = event.clientFilter;
      final tasks = await _repository.getAll(
        status: event.statusFilter,
        clientId: event.clientFilter,
      );
      final counts = await _repository.getStatusCounts();
      emit(TaskLoaded(tasks: tasks, statusCounts: counts));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onLoadTodayTasks(LoadTodayTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final tasks = await _repository.getToday();
      final counts = await _repository.getStatusCounts();
      emit(TaskLoaded(tasks: tasks, statusCounts: counts));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onCreateTask(CreateTask event, Emitter<TaskState> emit) async {
    try {
      await _repository.create(
        title: event.title,
        description: event.description,
        clientId: event.clientId,
        clientName: event.clientName,
        priority: event.priority,
        hourlyRate: event.hourlyRate,
        estimatedHours: event.estimatedHours,
        dueDate: event.dueDate,
        isBillable: event.isBillable,
      );
      final tasks = await _repository.getAll(
        status: _currentStatusFilter,
        clientId: _currentClientFilter,
      );
      final counts = await _repository.getStatusCounts();
      emit(TaskOperationSuccess(
        message: 'Task created successfully',
        tasks: tasks,
        statusCounts: counts,
      ));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    try {
      await _repository.update(event.task);
      final tasks = await _repository.getAll(
        status: _currentStatusFilter,
        clientId: _currentClientFilter,
      );
      final counts = await _repository.getStatusCounts();
      emit(TaskOperationSuccess(
        message: 'Task updated successfully',
        tasks: tasks,
        statusCounts: counts,
      ));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onUpdateTaskStatus(UpdateTaskStatus event, Emitter<TaskState> emit) async {
    try {
      await _repository.updateStatus(event.taskId, event.status);
      final tasks = await _repository.getAll(
        status: _currentStatusFilter,
        clientId: _currentClientFilter,
      );
      final counts = await _repository.getStatusCounts();
      emit(TaskLoaded(tasks: tasks, statusCounts: counts));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      await _repository.delete(event.taskId);
      final tasks = await _repository.getAll(
        status: _currentStatusFilter,
        clientId: _currentClientFilter,
      );
      final counts = await _repository.getStatusCounts();
      emit(TaskOperationSuccess(
        message: 'Task deleted',
        tasks: tasks,
        statusCounts: counts,
      ));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }
}
