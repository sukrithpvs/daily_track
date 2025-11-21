import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  /// Get the database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/daily_track.db';

    return await openDatabase(
      path,
      version: 2, // Incremented version for new schema
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Create new transactions table with type and category
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        type INTEGER NOT NULL,
        category INTEGER NOT NULL
      )
    ''');

    // Create index on timestamp for efficient date-based queries
    await db.execute('''
      CREATE INDEX idx_transactions_timestamp ON transactions(timestamp)
    ''');

    // Create index on type for filtering income/expenses
    await db.execute('''
      CREATE INDEX idx_transactions_type ON transactions(type)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrate from old expenses table to new transactions table
      try {
        // Check if old expenses table exists
        var result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='expenses'",
        );

        if (result.isNotEmpty) {
          // Create new transactions table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              amount REAL NOT NULL,
              description TEXT NOT NULL,
              timestamp INTEGER NOT NULL,
              type INTEGER NOT NULL,
              category INTEGER NOT NULL
            )
          ''');

          // Migrate old expenses to transactions (as expense type, misc category)
          await db.execute('''
            INSERT INTO transactions (amount, description, timestamp, type, category)
            SELECT amount, description, timestamp, 1, 13 FROM expenses
          ''');

          // Create indexes
          await db.execute('''
            CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON transactions(timestamp)
          ''');

          await db.execute('''
            CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type)
          ''');

          // Drop old table
          await db.execute('DROP TABLE IF EXISTS expenses');
          await db.execute('DROP INDEX IF EXISTS idx_expenses_timestamp');
        }
      } catch (e) {
        // If migration fails, just create new table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            description TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            type INTEGER NOT NULL,
            category INTEGER NOT NULL
          )
        ''');
      }
    }
  }

  /// Initialize database (public method for app startup)
  Future<void> initDatabase() async {
    final db = await database;

    // Safety check: Ensure transactions table exists
    var result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='transactions'",
    );

    if (result.isEmpty) {
      // Table doesn't exist, create it
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          description TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          type INTEGER NOT NULL,
          category INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON transactions(timestamp)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type)
      ''');

      // Migrate old expenses if they exist
      var expensesCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='expenses'",
      );

      if (expensesCheck.isNotEmpty) {
        await db.execute('''
          INSERT INTO transactions (amount, description, timestamp, type, category)
          SELECT amount, description, timestamp, 1, 13 FROM expenses
        ''');
      }
    }
  }

  // ========== NEW TRANSACTION METHODS ==========

  /// Insert a new transaction
  Future<int> insertTransaction(MoneyTransaction transaction) async {
    try {
      final db = await database;
      final id = await db.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      throw DatabaseHelperException('Failed to insert transaction: $e');
    }
  }

  /// Get all transactions for a specific date
  Future<List<MoneyTransaction>> getTransactionsForDate(DateTime date) async {
    try {
      final db = await database;

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
        999,
      );

      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [
          startOfDay.millisecondsSinceEpoch,
          endOfDay.millisecondsSinceEpoch,
        ],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => MoneyTransaction.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseHelperException('Failed to get transactions for date: $e');
    }
  }

  /// Get all transactions for a specific month
  Future<List<MoneyTransaction>> getTransactionsForMonth(
    int year,
    int month,
  ) async {
    try {
      final db = await database;

      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59, 999);

      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [
          startOfMonth.millisecondsSinceEpoch,
          endOfMonth.millisecondsSinceEpoch,
        ],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => MoneyTransaction.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseHelperException('Failed to get transactions for month: $e');
    }
  }

  /// Get income for a specific date
  Future<double> getIncomeForDate(DateTime date) async {
    final transactions = await getTransactionsForDate(date);
    return transactions
        .where((t) => t.isIncome)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Get total expense amount for a specific date
  Future<double> getExpensesForDate(DateTime date) async {
    final transactions = await getTransactionsForDate(date);
    return transactions
        .where((t) => t.isExpense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Get income for a specific month
  Future<double> getIncomeForMonth(int year, int month) async {
    final transactions = await getTransactionsForMonth(year, month);
    return transactions
        .where((t) => t.isIncome)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Get total expense amount for a specific month
  Future<double> getExpensesForMonth(int year, int month) async {
    final transactions = await getTransactionsForMonth(year, month);
    return transactions
        .where((t) => t.isExpense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  /// Get balance (income - expenses) for current month
  Future<double> getCurrentBalance() async {
    final now = DateTime.now();
    final income = await getIncomeForMonth(now.year, now.month);
    final expenses = await getExpensesForMonth(now.year, now.month);
    return income - expenses;
  }

  /// Delete a transaction by ID
  Future<void> deleteTransaction(int id) async {
    try {
      final db = await database;
      final deletedRows = await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (deletedRows == 0) {
        throw DatabaseHelperException('Transaction with id $id not found');
      }
    } catch (e) {
      throw DatabaseHelperException('Failed to delete transaction: $e');
    }
  }

  /// Update a transaction
  Future<void> updateTransaction(MoneyTransaction transaction) async {
    try {
      if (transaction.id == null) {
        throw DatabaseHelperException('Cannot update transaction without ID');
      }

      final db = await database;
      final updatedRows = await db.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      if (updatedRows == 0) {
        throw DatabaseHelperException(
          'Transaction with id ${transaction.id} not found',
        );
      }
    } catch (e) {
      throw DatabaseHelperException('Failed to update transaction: $e');
    }
  }

  /// Delete all transactions (for testing or reset)
  Future<void> deleteAllTransactions() async {
    try {
      final db = await database;
      await db.delete('transactions');
    } catch (e) {
      throw DatabaseHelperException('Failed to delete all transactions: $e');
    }
  }

  // ========== LEGACY EXPENSE METHODS (for backward compatibility) ==========

  /// Insert a new expense (converts to transaction)
  Future<int> insertExpense(Expense expense) async {
    final transaction = MoneyTransaction(
      amount: expense.amount,
      description: expense.description,
      timestamp: expense.timestamp,
      type: TransactionType.expense,
      category: TransactionCategory.misc,
    );
    return await insertTransaction(transaction);
  }

  /// Get all expenses for a specific date (returns as Expense objects - legacy support)
  Future<List<Expense>> getExpensesListForDate(DateTime date) async {
    final transactions = await getTransactionsForDate(date);
    return transactions
        .where((t) => t.isExpense)
        .map(
          (t) => Expense(
            id: t.id,
            amount: t.amount,
            description: t.description,
            timestamp: t.timestamp,
          ),
        )
        .toList();
  }

  /// Get all expenses for a specific month (returns as Expense objects - legacy support)
  Future<List<Expense>> getExpensesListForMonth(int year, int month) async {
    final transactions = await getTransactionsForMonth(year, month);
    return transactions
        .where((t) => t.isExpense)
        .map(
          (t) => Expense(
            id: t.id,
            amount: t.amount,
            description: t.description,
            timestamp: t.timestamp,
          ),
        )
        .toList();
  }

  /// Get all expenses (for export or backup)
  Future<List<Expense>> getAllExpenses() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        where: 'type = ?',
        whereArgs: [TransactionType.expense.index],
        orderBy: 'timestamp DESC',
      );

      return maps
          .map(
            (map) => Expense(
              id: map['id'] as int?,
              amount: (map['amount'] as num).toDouble(),
              description: map['description'] as String,
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                map['timestamp'] as int,
              ),
            ),
          )
          .toList();
    } catch (e) {
      throw DatabaseHelperException('Failed to get all expenses: $e');
    }
  }

  /// Delete an expense by ID
  Future<void> deleteExpense(int id) async {
    await deleteTransaction(id);
  }

  /// Update an expense
  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) {
      throw DatabaseHelperException('Cannot update expense without ID');
    }

    final transaction = MoneyTransaction(
      id: expense.id,
      amount: expense.amount,
      description: expense.description,
      timestamp: expense.timestamp,
      type: TransactionType.expense,
      category: TransactionCategory.misc,
    );

    await updateTransaction(transaction);
  }

  /// Get total amount for a specific date (expenses only)
  Future<double> getDailyTotal(DateTime date) async {
    return await getExpensesForDate(date);
  }

  /// Get total amount for a specific month (expenses only)
  Future<double> getMonthlyTotal(int year, int month) async {
    return await getExpensesForMonth(year, month);
  }

  /// Get expense count for a specific date
  Future<int> getExpenseCountForDate(DateTime date) async {
    try {
      final expenses = await getExpensesListForDate(date);
      return expenses.length;
    } catch (e) {
      throw DatabaseHelperException('Failed to get expense count: $e');
    }
  }

  /// Delete all expenses (for testing or reset)
  Future<void> deleteAllExpenses() async {
    await deleteAllTransactions();
  }

  /// Close the database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

/// Custom exception for database operations
class DatabaseHelperException implements Exception {
  final String message;

  const DatabaseHelperException(this.message);

  @override
  String toString() => 'DatabaseHelperException: $message';
}
