import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../models/transaction.dart';
import '../db/database_helper.dart';
import '../utils/input_parser.dart';
import '../utils/csv_exporter.dart';

class MoneyProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<MoneyTransaction> _todayTransactions = [];
  double _dailyIncome = 0.0;
  double _dailyExpenses = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpenses = 0.0;
  double _currentBalance = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<MoneyTransaction> get todayTransactions =>
      List.unmodifiable(_todayTransactions);
  List<MoneyTransaction> get todayIncome =>
      _todayTransactions.where((t) => t.isIncome).toList();
  List<MoneyTransaction> get todayExpenses =>
      _todayTransactions.where((t) => t.isExpense).toList();

  double get dailyIncome => _dailyIncome;
  double get dailyExpenses => _dailyExpenses;
  double get dailyNet => _dailyIncome - _dailyExpenses;

  double get monthlyIncome => _monthlyIncome;
  double get monthlyExpenses => _monthlyExpenses;
  double get monthlyNet => _monthlyIncome - _monthlyExpenses;

  double get currentBalance => _currentBalance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Legacy getters for backward compatibility
  double get dailyTotal => _dailyExpenses;
  double get monthlyTotal => _monthlyExpenses;

  /// Initialize the provider and load today's data
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _databaseHelper.initDatabase();
      await loadTodayTransactions();
      await _calculateTotals();
      _clearError();
    } catch (e) {
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load transactions for today
  Future<void> loadTodayTransactions() async {
    try {
      final today = DateTime.now();
      _todayTransactions = await _databaseHelper.getTransactionsForDate(today);
      notifyListeners();
    } catch (e) {
      _setError("Failed to load today's transactions: $e");
    }
  }

  /// Calculate daily and monthly totals
  Future<void> _calculateTotals() async {
    try {
      final now = DateTime.now();

      // Daily totals
      _dailyIncome = await _databaseHelper.getIncomeForDate(now);
      _dailyExpenses = await _databaseHelper.getExpensesForDate(now);

      // Monthly totals
      _monthlyIncome = await _databaseHelper.getIncomeForMonth(
        now.year,
        now.month,
      );
      _monthlyExpenses = await _databaseHelper.getExpensesForMonth(
        now.year,
        now.month,
      );

      // Current balance
      _currentBalance = await _databaseHelper.getCurrentBalance();

      notifyListeners();
    } catch (e) {
      _setError('Failed to calculate totals: $e');
    }
  }

  /// Add transaction (income or expense)
  Future<bool> addTransaction({
    required double amount,
    required String description,
    required TransactionType type,
    required TransactionCategory category,
  }) async {
    _setLoading(true);
    try {
      final transaction = MoneyTransaction(
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
        type: type,
        category: category,
      );

      final validationErrors = transaction.validate();
      if (validationErrors.isNotEmpty) {
        _setError(validationErrors.first);
        return false;
      }

      final id = await _databaseHelper.insertTransaction(transaction);

      final today = DateTime.now();
      if (_isSameDay(transaction.timestamp, today)) {
        final transactionWithId = transaction.copyWith(id: id);
        _todayTransactions.insert(0, transactionWithId);
      }

      await _calculateTotals();
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to add transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Add expense from input string (legacy support)
  Future<bool> addExpenseFromInput(String input) async {
    _clearError();

    final parsed = InputParser.parseExpenseInput(input);
    final validationErrors = InputParser.validateParsedInput(parsed);

    if (validationErrors.isNotEmpty) {
      _setError(validationErrors.first);
      return false;
    }

    return await addTransaction(
      amount: parsed!['amount'] as double,
      description: parsed['description'] as String,
      type: TransactionType.expense,
      category: TransactionCategory.misc,
    );
  }

  /// Add expense object (legacy support)
  Future<bool> addExpense(Expense expense) async {
    return await addTransaction(
      amount: expense.amount,
      description: expense.description,
      type: TransactionType.expense,
      category: TransactionCategory.misc,
    );
  }

  /// Delete transaction by ID
  Future<bool> deleteTransaction(int id) async {
    _setLoading(true);
    try {
      await _databaseHelper.deleteTransaction(id);
      _todayTransactions.removeWhere((transaction) => transaction.id == id);
      await _calculateTotals();
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to delete transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete expense by ID (legacy support)
  Future<bool> deleteExpense(int id) async {
    return await deleteTransaction(id);
  }

  /// Get transactions for a specific date
  Future<List<MoneyTransaction>> getTransactionsForDate(DateTime date) async {
    try {
      return await _databaseHelper.getTransactionsForDate(date);
    } catch (e) {
      _setError('Failed to get transactions for date: $e');
      return [];
    }
  }

  /// Get transactions for a specific month
  Future<List<MoneyTransaction>> getTransactionsForMonth(
    int year,
    int month,
  ) async {
    try {
      return await _databaseHelper.getTransactionsForMonth(year, month);
    } catch (e) {
      _setError('Failed to get transactions for month: $e');
      return [];
    }
  }

  /// Get expenses for date (legacy support)
  Future<List<Expense>> getExpensesForDate(DateTime date) async {
    try {
      return await _databaseHelper.getExpensesListForDate(date);
    } catch (e) {
      _setError('Failed to get expenses for date: $e');
      return [];
    }
  }

  /// Get expenses for month (legacy support)
  Future<List<Expense>> getExpensesForMonth(int year, int month) async {
    try {
      return await _databaseHelper.getExpensesListForMonth(year, month);
    } catch (e) {
      _setError('Failed to get expenses for month: $e');
      return [];
    }
  }

  /// Get total expense amount for a specific date
  Future<double> getTotalForDate(DateTime date) async {
    try {
      return await _databaseHelper.getExpensesForDate(date);
    } catch (e) {
      _setError('Failed to get total for date: $e');
      return 0.0;
    }
  }

  /// Get total expense amount for a specific month
  Future<double> getTotalForMonth(int year, int month) async {
    try {
      return await _databaseHelper.getExpensesForMonth(year, month);
    } catch (e) {
      _setError('Failed to get total for month: $e');
      return 0.0;
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadTodayTransactions();
    await _calculateTotals();
  }

  /// Export monthly expenses to CSV
  Future<CsvExportResult> exportMonthlyExpenses() async {
    _setLoading(true);
    try {
      final hasPermission = await CsvExporter.checkAndRequestPermissions();
      if (!hasPermission) {
        _setError(
          'Please grant storage permission in Settings > Apps > DailyTrack > Permissions',
        );
        return CsvExportResult.error(
          'Storage permission denied. Please enable in app settings.',
        );
      }

      final now = DateTime.now();
      final monthlyExpenses = await _databaseHelper.getExpensesListForMonth(
        now.year,
        now.month,
      );

      if (monthlyExpenses.isEmpty) {
        _setError('No expenses to export for this month');
        return CsvExportResult.error('No expenses to export');
      }

      final result = await CsvExporter.exportMonthlyExpenses(
        monthlyExpenses,
        now.year,
        now.month,
      );

      if (result.success) {
        _clearError();
      } else {
        _setError(result.errorMessage ?? 'Export failed');
      }

      return result;
    } catch (e) {
      final errorMsg = 'Export failed: $e';
      _setError(errorMsg);
      return CsvExportResult.error(errorMsg);
    } finally {
      _setLoading(false);
    }
  }

  /// Clear all transactions (for testing/reset)
  Future<void> clearAllTransactions() async {
    _setLoading(true);
    try {
      await _databaseHelper.deleteAllTransactions();
      _todayTransactions.clear();
      _dailyIncome = 0.0;
      _dailyExpenses = 0.0;
      _monthlyIncome = 0.0;
      _monthlyExpenses = 0.0;
      _currentBalance = 0.0;
      notifyListeners();
      _clearError();
    } catch (e) {
      _setError('Failed to clear transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear all expenses (legacy support)
  Future<void> clearAllExpenses() async {
    await clearAllTransactions();
  }

  // Helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  void dispose() {
    _databaseHelper.close();
    super.dispose();
  }
}

// Create an alias for backward compatibility
typedef ExpenseProvider = MoneyProvider;
