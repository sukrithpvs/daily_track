import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daily_track/providers/expense_provider.dart';
import 'package:daily_track/models/expense.dart';

void main() {
  group('ExpenseProvider Tests', () {
    late ExpenseProvider provider;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      provider = ExpenseProvider();
      await provider.initialize();
      await provider.clearAllExpenses(); // Start with clean state
    });

    tearDown(() async {
      await provider.clearAllExpenses();
      provider.dispose();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        final newProvider = ExpenseProvider();
        await newProvider.initialize();
        
        expect(newProvider.isLoading, isFalse);
        expect(newProvider.errorMessage, isNull);
        expect(newProvider.todayExpenses, isEmpty);
        expect(newProvider.dailyTotal, equals(0.0));
        expect(newProvider.monthlyTotal, equals(0.0));
        
        newProvider.dispose();
      });
    });

    group('Adding Expenses', () {
      test('should add expense from valid input string', () async {
        final result = await provider.addExpenseFromInput('120 coffee');
        
        expect(result, isTrue);
        expect(provider.errorMessage, isNull);
        expect(provider.todayExpenses, hasLength(1));
        expect(provider.todayExpenses.first.amount, equals(120.0));
        expect(provider.todayExpenses.first.description, equals('coffee'));
        expect(provider.dailyTotal, equals(120.0));
      });

      test('should add expense from dash-separated input', () async {
        final result = await provider.addExpenseFromInput('75.50 - lunch');
        
        expect(result, isTrue);
        expect(provider.todayExpenses, hasLength(1));
        expect(provider.todayExpenses.first.amount, equals(75.50));
        expect(provider.todayExpenses.first.description, equals('lunch'));
      });

      test('should add expense object directly', () async {
        final expense = Expense(
          amount: 50.0,
          description: 'snack',
          timestamp: DateTime.now(),
        );
        
        final result = await provider.addExpense(expense);
        
        expect(result, isTrue);
        expect(provider.todayExpenses, hasLength(1));
        expect(provider.dailyTotal, equals(50.0));
      });

      test('should add multiple expenses and calculate totals correctly', () async {
        await provider.addExpenseFromInput('100 breakfast');
        await provider.addExpenseFromInput('150 lunch');
        await provider.addExpenseFromInput('75 dinner');
        
        expect(provider.todayExpenses, hasLength(3));
        expect(provider.dailyTotal, equals(325.0));
        expect(provider.monthlyTotal, equals(325.0));
      });

      test('should maintain chronological order (newest first)', () async {
        await provider.addExpenseFromInput('100 first');
        await Future.delayed(const Duration(milliseconds: 10));
        await provider.addExpenseFromInput('200 second');
        await Future.delayed(const Duration(milliseconds: 10));
        await provider.addExpenseFromInput('300 third');
        
        expect(provider.todayExpenses, hasLength(3));
        expect(provider.todayExpenses[0].description, equals('third'));
        expect(provider.todayExpenses[1].description, equals('second'));
        expect(provider.todayExpenses[2].description, equals('first'));
      });

      test('should reject invalid input formats', () async {
        final result = await provider.addExpenseFromInput('invalid input');
        
        expect(result, isFalse);
        expect(provider.errorMessage, isNotNull);
        expect(provider.todayExpenses, isEmpty);
        expect(provider.dailyTotal, equals(0.0));
      });

      test('should reject negative amounts', () async {
        final result = await provider.addExpenseFromInput('-50 invalid');
        
        expect(result, isFalse);
        expect(provider.errorMessage, isNotNull);
        expect(provider.todayExpenses, isEmpty);
      });

      test('should reject empty descriptions', () async {
        final expense = Expense(
          amount: 100.0,
          description: '',
          timestamp: DateTime.now(),
        );
        
        final result = await provider.addExpense(expense);
        
        expect(result, isFalse);
        expect(provider.errorMessage, isNotNull);
        expect(provider.todayExpenses, isEmpty);
      });
    });

    group('Deleting Expenses', () {
      test('should delete expense successfully', () async {
        // Add an expense first
        await provider.addExpenseFromInput('100 coffee');
        expect(provider.todayExpenses, hasLength(1));
        
        final expenseId = provider.todayExpenses.first.id!;
        final result = await provider.deleteExpense(expenseId);
        
        expect(result, isTrue);
        expect(provider.todayExpenses, isEmpty);
        expect(provider.dailyTotal, equals(0.0));
        expect(provider.errorMessage, isNull);
      });

      test('should update totals after deletion', () async {
        await provider.addExpenseFromInput('100 coffee');
        await provider.addExpenseFromInput('200 lunch');
        expect(provider.dailyTotal, equals(300.0));
        
        final expenseId = provider.todayExpenses.first.id!;
        await provider.deleteExpense(expenseId);
        
        expect(provider.todayExpenses, hasLength(1));
        expect(provider.dailyTotal, equals(100.0)); // Should be updated
      });

      test('should handle deletion of non-existent expense', () async {
        final result = await provider.deleteExpense(999);
        
        expect(result, isFalse);
        expect(provider.errorMessage, isNotNull);
      });
    });

    group('Data Retrieval', () {
      test('should get expenses for specific date', () async {
        final testDate = DateTime(2024, 1, 15);
        
        // Add expense for test date
        final expense = Expense(
          amount: 100.0,
          description: 'test expense',
          timestamp: testDate,
        );
        await provider.addExpense(expense);
        
        final expenses = await provider.getExpensesForDate(testDate);
        expect(expenses, hasLength(1));
        expect(expenses.first.description, equals('test expense'));
      });

      test('should get expenses for specific month', () async {
        final testDate1 = DateTime(2024, 1, 15);
        final testDate2 = DateTime(2024, 1, 20);
        final testDate3 = DateTime(2024, 2, 5);
        
        await provider.addExpense(Expense(
          amount: 100.0,
          description: 'january 1',
          timestamp: testDate1,
        ));
        await provider.addExpense(Expense(
          amount: 200.0,
          description: 'january 2',
          timestamp: testDate2,
        ));
        await provider.addExpense(Expense(
          amount: 300.0,
          description: 'february',
          timestamp: testDate3,
        ));
        
        final januaryExpenses = await provider.getExpensesForMonth(2024, 1);
        expect(januaryExpenses, hasLength(2));
        
        final februaryExpenses = await provider.getExpensesForMonth(2024, 2);
        expect(februaryExpenses, hasLength(1));
      });

      test('should get total for specific date', () async {
        final testDate = DateTime(2024, 1, 15);
        
        await provider.addExpense(Expense(
          amount: 100.0,
          description: 'expense 1',
          timestamp: testDate,
        ));
        await provider.addExpense(Expense(
          amount: 200.0,
          description: 'expense 2',
          timestamp: testDate,
        ));
        
        final total = await provider.getTotalForDate(testDate);
        expect(total, equals(300.0));
      });

      test('should get total for specific month', () async {
        final testDate1 = DateTime(2024, 1, 15);
        final testDate2 = DateTime(2024, 1, 20);
        
        await provider.addExpense(Expense(
          amount: 100.0,
          description: 'expense 1',
          timestamp: testDate1,
        ));
        await provider.addExpense(Expense(
          amount: 200.0,
          description: 'expense 2',
          timestamp: testDate2,
        ));
        
        final total = await provider.getTotalForMonth(2024, 1);
        expect(total, equals(300.0));
      });
    });

    group('State Management', () {
      test('should notify listeners when expenses change', () async {
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        await provider.addExpenseFromInput('100 coffee');
        expect(notificationCount, greaterThan(0));
      });

      test('should clear error message after successful operation', () async {
        // Cause an error first
        await provider.addExpenseFromInput('invalid');
        expect(provider.errorMessage, isNotNull);
        
        // Perform successful operation
        await provider.addExpenseFromInput('100 coffee');
        expect(provider.errorMessage, isNull);
      });

      test('should handle loading state correctly', () async {
        expect(provider.isLoading, isFalse);
        
        // The loading state changes happen very quickly in tests,
        // so we just verify the final state
        await provider.addExpenseFromInput('100 coffee');
        expect(provider.isLoading, isFalse);
      });
    });

    group('Refresh Functionality', () {
      test('should refresh data correctly', () async {
        await provider.addExpenseFromInput('100 coffee');
        expect(provider.todayExpenses, hasLength(1));
        
        await provider.refresh();
        expect(provider.todayExpenses, hasLength(1));
        expect(provider.dailyTotal, equals(100.0));
      });
    });

    group('Clear All Expenses', () {
      test('should clear all expenses and reset totals', () async {
        await provider.addExpenseFromInput('100 coffee');
        await provider.addExpenseFromInput('200 lunch');
        expect(provider.todayExpenses, hasLength(2));
        expect(provider.dailyTotal, equals(300.0));
        
        await provider.clearAllExpenses();
        expect(provider.todayExpenses, isEmpty);
        expect(provider.dailyTotal, equals(0.0));
        expect(provider.monthlyTotal, equals(0.0));
      });
    });

    group('Error Handling', () {
      test('should handle invalid input gracefully', () async {
        final result = await provider.addExpenseFromInput('invalid input');
        expect(result, isFalse);
        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains('Invalid input format'));
      });
    });

    group('Edge Cases', () {
      test('should handle very small amounts', () async {
        final result = await provider.addExpenseFromInput('0.01 penny');
        
        expect(result, isTrue);
        expect(provider.todayExpenses.first.amount, equals(0.01));
      });

      test('should handle large amounts', () async {
        final result = await provider.addExpenseFromInput('999999 expensive');
        
        expect(result, isTrue);
        expect(provider.todayExpenses.first.amount, equals(999999.0));
      });

      test('should handle long descriptions', () async {
        final longDescription = 'A' * 99; // Just under the limit
        final result = await provider.addExpenseFromInput('100 $longDescription');
        
        expect(result, isTrue);
        expect(provider.todayExpenses.first.description, equals(longDescription));
      });

      test('should reject too long descriptions', () async {
        final tooLongDescription = 'A' * 101; // Over the limit
        final result = await provider.addExpenseFromInput('100 $tooLongDescription');
        
        expect(result, isFalse);
        expect(provider.errorMessage, isNotNull);
      });
    });
  });
}