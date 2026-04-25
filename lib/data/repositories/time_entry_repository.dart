import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/time_entry_model.dart';
import '../../core/constants/app_constants.dart';

class TimeEntryRepository {
  final DatabaseHelper _dbHelper;
  final _uuid = const Uuid();

  TimeEntryRepository(this._dbHelper);

  Future<Database> get _db async => _dbHelper.database;

  Future<List<TimeEntryModel>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.timeEntriesTable,
      where: 'end_time IS NOT NULL',
      orderBy: 'start_time DESC',
    );
    return maps.map(TimeEntryModel.fromMap).toList();
  }

  Future<TimeEntryModel?> getRunningEntry() async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.timeEntriesTable,
      where: 'end_time IS NULL',
      orderBy: 'start_time DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TimeEntryModel.fromMap(maps.first);
  }

  Future<List<TimeEntryModel>> getForDate(DateTime date) async {
    final db = await _db;
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final maps = await db.query(
      AppConstants.timeEntriesTable,
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [start, end],
      orderBy: 'start_time ASC',
    );
    return maps.map(TimeEntryModel.fromMap).toList();
  }

  Future<List<TimeEntryModel>> getForTask(String taskId) async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.timeEntriesTable,
      where: 'task_id = ? AND end_time IS NOT NULL',
      whereArgs: [taskId],
      orderBy: 'start_time DESC',
    );
    return maps.map(TimeEntryModel.fromMap).toList();
  }

  Future<List<TimeEntryModel>> getForDateRange(DateTime start, DateTime end) async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.timeEntriesTable,
      where: 'start_time >= ? AND start_time <= ? AND end_time IS NOT NULL',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'start_time DESC',
    );
    return maps.map(TimeEntryModel.fromMap).toList();
  }

  Future<TimeEntryModel> startTimer({
    String? taskId,
    String? taskTitle,
    String? clientId,
    String? clientName,
    double? hourlyRate,
    bool isBillable = true,
  }) async {
    // Stop any running timer first
    await stopRunningTimer();

    final now = DateTime.now();
    final entry = TimeEntryModel(
      id: _uuid.v4(),
      taskId: taskId,
      taskTitle: taskTitle,
      clientId: clientId,
      clientName: clientName,
      startTime: now,
      isBillable: isBillable,
      hourlyRate: hourlyRate,
      createdAt: now,
    );
    final db = await _db;
    await db.insert(AppConstants.timeEntriesTable, entry.toMap());
    return entry;
  }

  Future<TimeEntryModel?> stopRunningTimer() async {
    final running = await getRunningEntry();
    if (running == null) return null;

    final now = DateTime.now();
    final duration = now.difference(running.startTime);
    final stopped = running.copyWith(
      endTime: now,
      duration: duration,
    );
    final db = await _db;
    await db.update(
      AppConstants.timeEntriesTable,
      stopped.toMap(),
      where: 'id = ?',
      whereArgs: [running.id],
    );
    return stopped;
  }

  Future<TimeEntryModel> addManualEntry({
    required DateTime startTime,
    required DateTime endTime,
    String? taskId,
    String? taskTitle,
    String? clientId,
    String? clientName,
    String? notes,
    double? hourlyRate,
    bool isBillable = true,
  }) async {
    final duration = endTime.difference(startTime);
    final entry = TimeEntryModel(
      id: _uuid.v4(),
      taskId: taskId,
      taskTitle: taskTitle,
      clientId: clientId,
      clientName: clientName,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      notes: notes,
      isBillable: isBillable,
      hourlyRate: hourlyRate,
      createdAt: DateTime.now(),
    );
    final db = await _db;
    await db.insert(AppConstants.timeEntriesTable, entry.toMap());
    return entry;
  }

  Future<TimeEntryModel> update(TimeEntryModel entry) async {
    final db = await _db;
    await db.update(
      AppConstants.timeEntriesTable,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    return entry;
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(AppConstants.timeEntriesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getDashboardStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN is_billable = 1 AND end_time IS NOT NULL THEN duration_seconds ELSE 0 END), 0) as billable_seconds,
        COALESCE(SUM(CASE WHEN is_billable = 0 AND end_time IS NOT NULL THEN duration_seconds ELSE 0 END), 0) as non_billable_seconds,
        COALESCE(SUM(CASE WHEN is_billable = 1 AND end_time IS NOT NULL THEN (duration_seconds / 3600.0 * hourly_rate) ELSE 0 END), 0) as potential_earnings
      FROM ${AppConstants.timeEntriesTable}
      WHERE start_time >= ? AND start_time <= ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final row = result.first;
    return {
      'billableSeconds': row['billable_seconds'] as int,
      'nonBillableSeconds': row['non_billable_seconds'] as int,
      'potentialEarnings': (row['potential_earnings'] as num).toDouble(),
    };
  }

  Future<Duration> getTotalDurationForTask(String taskId) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(duration_seconds), 0) as total
      FROM ${AppConstants.timeEntriesTable}
      WHERE task_id = ? AND end_time IS NOT NULL
    ''', [taskId]);
    final seconds = result.first['total'] as int;
    return Duration(seconds: seconds);
  }
}
