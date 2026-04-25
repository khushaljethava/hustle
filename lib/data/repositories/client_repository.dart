import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/client_model.dart';
import '../../core/constants/app_constants.dart';

class ClientRepository {
  final DatabaseHelper _dbHelper;
  final _uuid = const Uuid();

  ClientRepository(this._dbHelper);

  Future<Database> get _db async => _dbHelper.database;

  Future<List<ClientModel>> getAll({bool includeArchived = false}) async {
    final db = await _db;
    final where = includeArchived ? null : 'is_archived = 0';
    final maps = await db.query(
      AppConstants.clientsTable,
      where: where,
      orderBy: 'name ASC',
    );
    return maps.map(ClientModel.fromMap).toList();
  }

  Future<ClientModel?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.clientsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ClientModel.fromMap(maps.first);
  }

  Future<ClientModel> create({
    required String name,
    String? email,
    String? phone,
    String? company,
    required double defaultRate,
    required String currency,
    String? notes,
  }) async {
    final now = DateTime.now();
    final client = ClientModel(
      id: _uuid.v4(),
      name: name,
      email: email,
      phone: phone,
      company: company,
      defaultRate: defaultRate,
      currency: currency,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    final db = await _db;
    await db.insert(AppConstants.clientsTable, client.toMap());
    return client;
  }

  Future<ClientModel> update(ClientModel client) async {
    final updated = client.copyWith(updatedAt: DateTime.now());
    final db = await _db;
    await db.update(
      AppConstants.clientsTable,
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
    return updated;
  }

  Future<void> archive(String id) async {
    final db = await _db;
    await db.update(
      AppConstants.clientsTable,
      {'is_archived': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(AppConstants.clientsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getClientEarnings(String clientId) async {
    final db = await _db;

    // Get total from paid invoices
    final invoiceResult = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) as total
      FROM ${AppConstants.invoicesTable}
      WHERE client_id = ? AND status = 'paid'
    ''', [clientId]);
    final earned = (invoiceResult.first['total'] as num).toDouble();

    // Get total from sent invoices (outstanding)
    final outstandingResult = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) as total
      FROM ${AppConstants.invoicesTable}
      WHERE client_id = ? AND status = 'sent'
    ''', [clientId]);
    final outstanding = (outstandingResult.first['total'] as num).toDouble();

    // Get total hours logged
    final hoursResult = await db.rawQuery('''
      SELECT COALESCE(SUM(duration_seconds), 0) as seconds
      FROM ${AppConstants.timeEntriesTable}
      WHERE client_id = ? AND end_time IS NOT NULL
    ''', [clientId]);
    final totalSeconds = (hoursResult.first['seconds'] as num).toDouble();

    return {
      'earned': earned,
      'outstanding': outstanding,
      'hours': totalSeconds / 3600,
    };
  }
}
