import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';

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
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Create index on timestamp for efficient date-based queries
    await db.execute('''
      CREATE INDEX idx_expenses_timestamp ON expenses(timestamp)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future database schema changes
  }

  /// Initialize database (public method for app startup)
  Future<void> initDatabase() async {
    await database;
  }

  /// Insert a new expense
  Future<int> insertExpense(Expense expense) async {
    try {
      final db = await database;
      final id = await db.insert(
        'expenses',
        expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      throw DatabaseHelperException('Failed to insert expense: $e');
    }
  }

  /// Get all expenses for a specific date
  Future<List<Expense>> getExpensesForDate(DateTime date) async {
    try {
      final db = await database;
      
      // Get start and end of the day in milliseconds
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
      
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [
          startOfDay.millisecondsSinceEpoch,
          endOfDay.millisecondsSinceEpoch,
        ],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => Expense.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseHelperException('Failed to get expenses for date: $e');
    }
  }

  /// Get all expenses for a specific month
  Future<List<Expense>> getExpensesForMonth(int year, int month) async {
    try {
      final db = await database;
      
      // Get start and end of the month in milliseconds
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59, 999);
      
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [
          startOfMonth.millisecondsSinceEpoch,
          endOfMonth.millisecondsSinceEpoch,
        ],
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => Expense.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseHelperException('Failed to get expenses for month: $e');
    }
  }

  /// Get all expenses (for export or backup)
  Future<List<Expense>> getAllExpenses() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'expenses',
        orderBy: 'timestamp DESC',
      );

      return maps.map((map) => Expense.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseHelperException('Failed to get all expenses: $e');
    }
  }

  /// Delete an expense by ID
  Future<void> deleteExpense(int id) async {
    try {
      final db = await database;
      final deletedRows = await db.delete(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (deletedRows == 0) {
        throw DatabaseHelperException('Expense with id $id not found');
      }
    } catch (e) {
      throw DatabaseHelperException('Failed to delete expense: $e');
    }
  }

  /// Update an expense
  Future<void> updateExpense(Expense expense) async {
    try {
      if (expense.id == null) {
        throw DatabaseHelperException('Cannot update expense without ID');
      }
      
      final db = await database;
      final updatedRows = await db.update(
        'expenses',
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
      
      if (updatedRows == 0) {
        throw DatabaseHelperException('Expense with id ${expense.id} not found');
      }
    } catch (e) {
      throw DatabaseHelperException('Failed to update expense: $e');
    }
  }

  /// Get total amount for a specific date
  Future<double> getDailyTotal(DateTime date) async {
    try {
      final expenses = await getExpensesForDate(date);
      return expenses.fold<double>(0.0, (double sum, Expense expense) => sum + expense.amount);
    } catch (e) {
      throw DatabaseHelperException('Failed to calculate daily total: $e');
    }
  }

  /// Get total amount for a specific month
  Future<double> getMonthlyTotal(int year, int month) async {
    try {
      final expenses = await getExpensesForMonth(year, month);
      return expenses.fold<double>(0.0, (double sum, Expense expense) => sum + expense.amount);
    } catch (e) {
      throw DatabaseHelperException('Failed to calculate monthly total: $e');
    }
  }

  /// Get expense count for a specific date
  Future<int> getExpenseCountForDate(DateTime date) async {
    try {
      final expenses = await getExpensesForDate(date);
      return expenses.length;
    } catch (e) {
      throw DatabaseHelperException('Failed to get expense count: $e');
    }
  }

  /// Close the database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete all expenses (for testing or reset)
  Future<void> deleteAllExpenses() async {
    try {
      final db = await database;
      await db.delete('expenses');
    } catch (e) {
      throw DatabaseHelperException('Failed to delete all expenses: $e');
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