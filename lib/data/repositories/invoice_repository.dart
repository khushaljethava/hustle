import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/invoice_model.dart';
import '../../core/constants/app_constants.dart';

class InvoiceRepository {
  final DatabaseHelper _dbHelper;
  final _uuid = const Uuid();

  InvoiceRepository(this._dbHelper);

  Future<Database> get _db async => _dbHelper.database;

  Future<List<InvoiceModel>> getAll({String? status, String? clientId}) async {
    final db = await _db;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (status != null) {
      conditions.add('i.status = ?');
      args.add(status);
    }
    if (clientId != null) {
      conditions.add('i.client_id = ?');
      args.add(clientId);
    }

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final invoiceMaps = await db.rawQuery('''
      SELECT i.* FROM ${AppConstants.invoicesTable} i
      $where
      ORDER BY i.created_at DESC
    ''', args.isEmpty ? null : args);

    final invoices = <InvoiceModel>[];
    for (final map in invoiceMaps) {
      final items = await _getItems(db, map['id'] as String);
      invoices.add(InvoiceModel.fromMap(map, items));
    }
    return invoices;
  }

  Future<InvoiceModel?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.invoicesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final items = await _getItems(db, id);
    return InvoiceModel.fromMap(maps.first, items);
  }

  Future<List<InvoiceItemModel>> _getItems(Database db, String invoiceId) async {
    final maps = await db.query(
      AppConstants.invoiceItemsTable,
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return maps.map(InvoiceItemModel.fromMap).toList();
  }

  Future<int> _getNextInvoiceNumber() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT MAX(invoice_number) as max FROM ${AppConstants.invoicesTable}',
    );
    final max = result.first['max'] as int?;
    return (max ?? 0) + 1;
  }

  Future<List<InvoiceModel>> getRecurringDue() async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      AppConstants.invoicesTable,
      where: 'is_recurring = 1 AND recurring_next_date <= ? AND status != ?',
      whereArgs: [now, 'paid'],
    );
    final invoices = <InvoiceModel>[];
    for (final map in maps) {
      final items = await _getItems(db, map['id'] as String);
      invoices.add(InvoiceModel.fromMap(map, items));
    }
    return invoices;
  }

  Future<void> updateRecurringNextDate(String id, DateTime nextDate) async {
    final db = await _db;
    await db.update(
      AppConstants.invoicesTable,
      {
        'recurring_next_date': nextDate.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<InvoiceModel> create({
    required String clientId,
    required String clientName,
    String? clientEmail,
    required List<InvoiceItemModel> items,
    required double taxRate,
    required String currency,
    required DateTime issueDate,
    required DateTime dueDate,
    String? notes,
    String status = 'draft',
    bool isRecurring = false,
    String? recurringInterval,
    DateTime? recurringNextDate,
    String template = 'classic',
  }) async {
    final invoiceNumber = await _getNextInvoiceNumber();
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.amount);
    final taxAmount = subtotal * (taxRate / 100);
    final total = subtotal + taxAmount;
    final now = DateTime.now();
    final invoiceId = _uuid.v4();

    final invoice = InvoiceModel(
      id: invoiceId,
      invoiceNumber: invoiceNumber,
      clientId: clientId,
      clientName: clientName,
      clientEmail: clientEmail,
      items: items.map((item) => item.copyWith(invoiceId: invoiceId, id: _uuid.v4())).toList(),
      subtotal: subtotal,
      taxRate: taxRate,
      taxAmount: taxAmount,
      total: total,
      currency: currency,
      status: status,
      issueDate: issueDate,
      dueDate: dueDate,
      notes: notes,
      isRecurring: isRecurring,
      recurringInterval: recurringInterval,
      recurringNextDate: recurringNextDate,
      template: template,
      createdAt: now,
      updatedAt: now,
    );

    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert(AppConstants.invoicesTable, invoice.toMap());
      for (final item in invoice.items) {
        await txn.insert(AppConstants.invoiceItemsTable, item.toMap());
      }
    });

    return invoice;
  }

  Future<InvoiceModel> updateStatus(String id, String status) async {
    final invoice = await getById(id);
    if (invoice == null) throw Exception('Invoice not found');

    final updated = invoice.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    final db = await _db;
    await db.update(
      AppConstants.invoicesTable,
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    return updated;
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete(AppConstants.invoicesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await _db;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();

    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN status = 'paid' AND issue_date >= ? THEN total ELSE 0 END), 0) as monthly_earned,
        COALESCE(SUM(CASE WHEN status = 'sent' THEN total ELSE 0 END), 0) as outstanding,
        COALESCE(SUM(CASE WHEN status = 'paid' THEN total ELSE 0 END), 0) as total_earned,
        COUNT(CASE WHEN status = 'sent' THEN 1 END) as unpaid_count,
        COUNT(CASE WHEN status = 'sent' AND due_date < ? THEN 1 END) as overdue_count
      FROM ${AppConstants.invoicesTable}
    ''', [monthStart, now.toIso8601String()]);

    final row = result.first;
    return {
      'monthlyEarned': (row['monthly_earned'] as num).toDouble(),
      'outstanding': (row['outstanding'] as num).toDouble(),
      'totalEarned': (row['total_earned'] as num).toDouble(),
      'unpaidCount': row['unpaid_count'] as int,
      'overdueCount': row['overdue_count'] as int,
    };
  }

  Future<List<Map<String, dynamic>>> getMonthlyEarnings(int months) async {
    final db = await _db;
    final startDate = DateTime.now().subtract(Duration(days: months * 30));

    return db.rawQuery('''
      SELECT
        strftime('%Y-%m', issue_date) as month,
        COALESCE(SUM(CASE WHEN status = 'paid' THEN total ELSE 0 END), 0) as earned,
        COALESCE(SUM(total), 0) as invoiced
      FROM ${AppConstants.invoicesTable}
      WHERE issue_date >= ?
      GROUP BY month
      ORDER BY month ASC
    ''', [startDate.toIso8601String()]);
  }
}
