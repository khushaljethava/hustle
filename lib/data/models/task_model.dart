import 'package:equatable/equatable.dart';

class TaskModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? clientId;
  final String? clientName;
  final String status;
  final String priority;
  final double? hourlyRate;
  final double? estimatedHours;
  final DateTime? dueDate;
  final bool isBillable;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.clientId,
    this.clientName,
    required this.status,
    required this.priority,
    this.hourlyRate,
    this.estimatedHours,
    this.dueDate,
    this.isBillable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? clientId,
    String? clientName,
    String? status,
    String? priority,
    double? hourlyRate,
    double? estimatedHours,
    DateTime? dueDate,
    bool? isBillable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      dueDate: dueDate ?? this.dueDate,
      isBillable: isBillable ?? this.isBillable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'client_id': clientId,
      'client_name': clientName,
      'status': status,
      'priority': priority,
      'hourly_rate': hourlyRate,
      'estimated_hours': estimatedHours,
      'due_date': dueDate?.toIso8601String(),
      'is_billable': isBillable ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      clientId: map['client_id'],
      clientName: map['client_name'],
      status: map['status'] ?? 'pending',
      priority: map['priority'] ?? 'medium',
      hourlyRate: map['hourly_rate'] != null ? (map['hourly_rate'] as num).toDouble() : null,
      estimatedHours: map['estimated_hours'] != null ? (map['estimated_hours'] as num).toDouble() : null,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      isBillable: map['is_billable'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, title, status, priority, clientId, dueDate, isBillable];
}
