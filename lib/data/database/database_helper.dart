import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.clientsTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        company TEXT,
        default_rate REAL NOT NULL DEFAULT 50.0,
        currency TEXT NOT NULL DEFAULT 'USD',
        notes TEXT,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tasksTable} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        client_id TEXT,
        client_name TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        priority TEXT NOT NULL DEFAULT 'medium',
        hourly_rate REAL,
        estimated_hours REAL,
        due_date TEXT,
        is_billable INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (client_id) REFERENCES ${AppConstants.clientsTable}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.timeEntriesTable} (
        id TEXT PRIMARY KEY,
        task_id TEXT,
        task_title TEXT,
        client_id TEXT,
        client_name TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration_seconds INTEGER,
        notes TEXT,
        is_billable INTEGER NOT NULL DEFAULT 1,
        hourly_rate REAL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (task_id) REFERENCES ${AppConstants.tasksTable}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.invoicesTable} (
        id TEXT PRIMARY KEY,
        invoice_number INTEGER NOT NULL,
        client_id TEXT NOT NULL,
        client_name TEXT NOT NULL,
        client_email TEXT,
        subtotal REAL NOT NULL,
        tax_rate REAL NOT NULL DEFAULT 0,
        tax_amount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'USD',
        status TEXT NOT NULL DEFAULT 'draft',
        issue_date TEXT NOT NULL,
        due_date TEXT NOT NULL,
        notes TEXT,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurring_interval TEXT,
        recurring_next_date TEXT,
        template TEXT NOT NULL DEFAULT 'classic',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (client_id) REFERENCES ${AppConstants.clientsTable}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.invoiceItemsTable} (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        description TEXT NOT NULL,
        quantity REAL NOT NULL,
        rate REAL NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES ${AppConstants.invoicesTable}(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_tasks_client ON ${AppConstants.tasksTable}(client_id)');
    await db.execute('CREATE INDEX idx_tasks_status ON ${AppConstants.tasksTable}(status)');
    await db.execute('CREATE INDEX idx_time_entries_task ON ${AppConstants.timeEntriesTable}(task_id)');
    await db.execute('CREATE INDEX idx_time_entries_client ON ${AppConstants.timeEntriesTable}(client_id)');
    await db.execute('CREATE INDEX idx_invoices_client ON ${AppConstants.invoicesTable}(client_id)');
    await db.execute('CREATE INDEX idx_invoices_status ON ${AppConstants.invoicesTable}(status)');
    await db.execute('CREATE INDEX idx_invoices_recurring ON ${AppConstants.invoicesTable}(is_recurring)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${AppConstants.invoicesTable} ADD COLUMN is_recurring INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE ${AppConstants.invoicesTable} ADD COLUMN recurring_interval TEXT',
      );
      await db.execute(
        'ALTER TABLE ${AppConstants.invoicesTable} ADD COLUMN recurring_next_date TEXT',
      );
      await db.execute(
        "ALTER TABLE ${AppConstants.invoicesTable} ADD COLUMN template TEXT NOT NULL DEFAULT 'classic'",
      );
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
