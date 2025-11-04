import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../db/database_helper.dart';
import '../utils/input_parser.dart';
import '../utils/csv_exporter.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  List<Expense> _todayExpenses = [];
  double _dailyTotal = 0.0;
  double _monthlyTotal = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Expense> get todayExpenses => List.unmodifiable(_todayExpenses);
  double get dailyTotal => _dailyTotal;
  double get monthlyTotal => _monthlyTotal;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize the provider and load today's data
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _databaseHelper.initDatabase();
      await loadTodayExpenses();
      await _calculateTotals();
      _clearError();
    } catch (e) {
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load expenses for today
  Future<void> loadTodayExpenses() async {
    try {
      final today = DateTime.now();
      _todayExpenses = await _databaseHelper.getExpensesForDate(today);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load today\'s expenses: $e');
    }
  }

  /// Calculate daily and monthly totals
  Future<void> _calculateTotals() async {
    try {
      final now = DateTime.now();
      _dailyTotal = await _databaseHelper.getDailyTotal(now);
      _monthlyTotal = await _databaseHelper.getMonthlyTotal(now.year, now.month);
      notifyListeners();
    } catch (e) {
      _setError('Failed to calculate totals: $e');
    }
  }

  /// Add expense from input string
  Future<bool> addExpenseFromInput(String input) async {
    _clearError();
    
    // Parse input
    final parsed = InputParser.parseExpenseInput(input);
    final validationErrors = InputParser.validateParsedInput(parsed);
    
    if (validationErrors.isNotEmpty) {
      _setError(validationErrors.first);
      return false;
    }
    
    // Create expense
    final expense = Expense(
      amount: parsed!['amount'] as double,
      description: parsed['description'] as String,
      timestamp: DateTime.now(),
    );
    
    return await addExpense(expense);
  }

  /// Add expense object
  Future<bool> addExpense(Expense expense) async {
    _setLoading(true);
    try {
      // Validate expense
      final validationErrors = expense.validate();
      if (validationErrors.isNotEmpty) {
        _setError(validationErrors.first);
        return false;
      }
      
      // Insert into database
      final id = await _databaseHelper.insertExpense(expense);
      
      // Add to today's list if it's for today
      final today = DateTime.now();
      if (_isSameDay(expense.timestamp, today)) {
        final expenseWithId = expense.copyWith(id: id);
        _todayExpenses.insert(0, expenseWithId); // Insert at beginning for newest first
      }
      
      // Recalculate totals
      await _calculateTotals();
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to add expense: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete expense by ID
  Future<bool> deleteExpense(int id) async {
    _setLoading(true);
    try {
      await _databaseHelper.deleteExpense(id);
      
      // Remove from today's list
      _todayExpenses.removeWhere((expense) => expense.id == id);
      
      // Recalculate totals
      await _calculateTotals();
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to delete expense: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get expenses for a specific date
  Future<List<Expense>> getExpensesForDate(DateTime date) async {
    try {
      return await _databaseHelper.getExpensesForDate(date);
    } catch (e) {
      _setError('Failed to get expenses for date: $e');
      return [];
    }
  }

  /// Get expenses for a specific month
  Future<List<Expense>> getExpensesForMonth(int year, int month) async {
    try {
      return await _databaseHelper.getExpensesForMonth(year, month);
    } catch (e) {
      _setError('Failed to get expenses for month: $e');
      return [];
    }
  }

  /// Get total for a specific date
  Future<double> getTotalForDate(DateTime date) async {
    try {
      return await _databaseHelper.getDailyTotal(date);
    } catch (e) {
      _setError('Failed to get total for date: $e');
      return 0.0;
    }
  }

  /// Get total for a specific month
  Future<double> getTotalForMonth(int year, int month) async {
    try {
      return await _databaseHelper.getMonthlyTotal(year, month);
    } catch (e) {
      _setError('Failed to get total for month: $e');
      return 0.0;
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadTodayExpenses();
    await _calculateTotals();
  }

  /// Export monthly expenses to CSV
  Future<CsvExportResult> exportMonthlyExpenses() async {
    _setLoading(true);
    try {
      // Check permissions first
      final hasPermission = await CsvExporter.checkAndRequestPermissions();
      if (!hasPermission) {
        _setError('Please grant storage permission in Settings > Apps > DailyTrack > Permissions');
        return CsvExportResult.error('Storage permission denied. Please enable in app settings.');
      }

      // Get current month expenses
      final now = DateTime.now();
      final monthlyExpenses = await _databaseHelper.getExpensesForMonth(now.year, now.month);
      
      if (monthlyExpenses.isEmpty) {
        _setError('No expenses to export for this month');
        return CsvExportResult.error('No expenses to export');
      }

      // Export to CSV
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

  /// Export expenses for a specific date range
  Future<CsvExportResult> exportExpensesForDateRange(DateTime start, DateTime end) async {
    _setLoading(true);
    try {
      final hasPermission = await CsvExporter.checkAndRequestPermissions();
      if (!hasPermission) {
        _setError('Storage permission required for export');
        return CsvExportResult.error('Storage permission denied');
      }

      // Get expenses in date range (simplified - would need more complex query for real date range)
      final expenses = await _databaseHelper.getExpensesForMonth(start.year, start.month);
      
      if (expenses.isEmpty) {
        _setError('No expenses to export for selected period');
        return CsvExportResult.error('No expenses to export');
      }

      final result = await CsvExporter.exportExpenses(expenses);

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

  /// Clear all expenses (for testing/reset)
  Future<void> clearAllExpenses() async {
    _setLoading(true);
    try {
      await _databaseHelper.deleteAllExpenses();
      _todayExpenses.clear();
      _dailyTotal = 0.0;
      _monthlyTotal = 0.0;
      notifyListeners();
      _clearError();
    } catch (e) {
      _setError('Failed to clear expenses: $e');
    } finally {
      _setLoading(false);
    }
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