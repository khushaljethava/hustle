import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/task_model.dart';
import '../../core/constants/app_constants.dart';

class TaskRepository {
  final DatabaseHelper _dbHelper;
  final _uuid = const Uuid();

  TaskRepository(this._dbHelper);

  Future<Database> get _db async => _dbHelper.database;

  Future<List<TaskModel>> getAll({
    String? status,
    String? clientId,
    String? priority,
  }) async {
    final db = await _db;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (status != null) {
      conditions.add('status = ?');
      args.add(status);
    }
    if (clientId != null) {
      conditions.add('client_id = ?');
      args.add(clientId);
    }
    if (priority != null) {
      conditions.add('priority = ?');
      args.add(priority);
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    final maps = await db.query(
      AppConstants.tasksTable,
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: "CASE priority WHEN 'urgent' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END, created_at DESC",
    );
    return maps.map(TaskModel.fromMap).toList();
  }

  Future<List<TaskModel>> getToday() async {
    final db = await _db;
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

    final maps = await db.query(
      AppConstants.tasksTable,
      where: "status != 'completed' AND (due_date <= ? OR status = 'in_progress')",
      whereArgs: [end],
      orderBy: "CASE priority WHEN 'urgent' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END",
    );
    return maps.map(TaskModel.fromMap).toList();
  }

  Future<TaskModel?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.tasksTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TaskModel.fromMap(maps.first);
  }

  Future<TaskModel> create({
    required String title,
    String? description,
    String? clientId,
    String? clientName,
    required String priority,
    double? hourlyRate,
    double? estimatedHours,
    DateTime? dueDate,
    bool isBillable = true,
  }) async {
    final now = DateTime.now();
    final task = TaskModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      clientId: clientId,
      clientName: clientName,
      status: AppConstants.taskPending,
      priority: priority,
      hourlyRate: hourlyRate,
      estimatedHours: estimatedHours,
      dueDate: dueDate,
      isBillable: isBillable,
      createdAt: now,
      updatedAt: now,
    );
    final db = await _db;
    await db.insert(AppConstants.tasksTable, task.toMap());
    return task;
  }

  Future<TaskModel> update(TaskModel task) async {
    final updated = task.copyWith(updatedAt: DateTime.now());
    final db = await _db;
    await db.update(
      AppConstants.tasksTable,
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    return updated;
  }

  Future<TaskModel> updateStatus(String id, String status) async {
    final task = await getById(id);
    if (task == null) throw Exception('Task not found');
    return update(task.copyWith(status: status));
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(AppConstants.tasksTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getStatusCounts() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM ${AppConstants.tasksTable}
      GROUP BY status
    ''');
    final counts = <String, int>{};
    for (final row in result) {
      counts[row['status'] as String] = row['count'] as int;
    }
    return counts;
  }
}
