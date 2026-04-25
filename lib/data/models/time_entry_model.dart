import 'package:equatable/equatable.dart';

class TimeEntryModel extends Equatable {
  final String id;
  final String? taskId;
  final String? taskTitle;
  final String? clientId;
  final String? clientName;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final String? notes;
  final bool isBillable;
  final double? hourlyRate;
  final DateTime createdAt;

  const TimeEntryModel({
    required this.id,
    this.taskId,
    this.taskTitle,
    this.clientId,
    this.clientName,
    required this.startTime,
    this.endTime,
    this.duration,
    this.notes,
    this.isBillable = true,
    this.hourlyRate,
    required this.createdAt,
  });

  bool get isRunning => endTime == null;

  Duration get actualDuration {
    if (duration != null) return duration!;
    if (endTime != null) return endTime!.difference(startTime);
    return DateTime.now().difference(startTime);
  }

  double get earnings {
    if (!isBillable || hourlyRate == null) return 0;
    return (actualDuration.inMinutes / 60) * hourlyRate!;
  }

  TimeEntryModel copyWith({
    String? id,
    String? taskId,
    String? taskTitle,
    String? clientId,
    String? clientName,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    String? notes,
    bool? isBillable,
    double? hourlyRate,
    DateTime? createdAt,
  }) {
    return TimeEntryModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      isBillable: isBillable ?? this.isBillable,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'task_title': taskTitle,
      'client_id': clientId,
      'client_name': clientName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': duration?.inSeconds,
      'notes': notes,
      'is_billable': isBillable ? 1 : 0,
      'hourly_rate': hourlyRate,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TimeEntryModel.fromMap(Map<String, dynamic> map) {
    return TimeEntryModel(
      id: map['id'],
      taskId: map['task_id'],
      taskTitle: map['task_title'],
      clientId: map['client_id'],
      clientName: map['client_name'],
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      duration: map['duration_seconds'] != null
          ? Duration(seconds: map['duration_seconds'])
          : null,
      notes: map['notes'],
      isBillable: map['is_billable'] == 1,
      hourlyRate: map['hourly_rate'] != null ? (map['hourly_rate'] as num).toDouble() : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, taskId, startTime, endTime, isBillable];
}
