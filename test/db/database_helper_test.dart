import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daily_track/db/database_helper.dart';
import 'package:daily_track/models/expense.dart';

void main() {
  group('DatabaseHelper Tests', () {
    late DatabaseHelper dbHelper;
    late DateTime testDate;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      dbHelper = DatabaseHelper();
      testDate = DateTime(2024, 1, 15, 10, 30);
      
      // Clean up any existing data
      await dbHelper.deleteAllExpenses();
    });

    tearDown(() async {
      await dbHelper.deleteAllExpenses();
    });

    group('Database Initialization', () {
      test('should initialize database successfully', () async {
        await dbHelper.initDatabase();
        final db = await dbHelper.database;
        expect(db.isOpen, isTrue);
      });
    });

    group('Insert Operations', () {
      test('should insert expense successfully', () async {
        final expense = Expense(
          amount: 120.50,
          description: 'Coffee',
          timestamp: testDate,
        );

        final id = await dbHelper.insertExpense(expense);
        expect(id, isPositive);
      });

      test('should insert multiple expenses', () async {
        final expenses = [
          Expense(amount: 50.0, description: 'Lunch', timestamp: testDate),
          Expense(amount: 25.0, description: 'Snack', timestamp: testDate),
        ];

        for (final expense in expenses) {
          final id = await dbHelper.insertExpense(expense);
          expect(id, isPositive);
        }

        final allExpenses = await dbHelper.getAllExpenses();
        expect(allExpenses, hasLength(2));
      });
    });

    group('Query Operations', () {
      setUp(() async {
        // Insert test data
        final testExpenses = [
          Expense(
            amount: 100.0,
            description: 'Morning coffee',
            timestamp: DateTime(2024, 1, 15, 8, 0),
          ),
          Expense(
            amount: 200.0,
            description: 'Lunch',
            timestamp: DateTime(2024, 1, 15, 12, 0),
          ),
          Expense(
            amount: 50.0,
            description: 'Evening snack',
            timestamp: DateTime(2024, 1, 16, 18, 0),
          ),
        ];

        for (final expense in testExpenses) {
          await dbHelper.insertExpense(expense);
        }
      });

      test('should get expenses for specific date', () async {
        final expenses = await dbHelper.getExpensesForDate(DateTime(2024, 1, 15));
        
        expect(expenses, hasLength(2));
        expect(expenses[0].description, equals('Lunch')); // Should be ordered by timestamp DESC
        expect(expenses[1].description, equals('Morning coffee'));
      });

      test('should get expenses for specific month', () async {
        final expenses = await dbHelper.getExpensesForMonth(2024, 1);
        
        expect(expenses, hasLength(3));
        expect(expenses.first.timestamp.month, equals(1));
      });

      test('should return empty list for date with no expenses', () async {
        final expenses = await dbHelper.getExpensesForDate(DateTime(2024, 2, 1));
        expect(expenses, isEmpty);
      });

      test('should get all expenses', () async {
        final expenses = await dbHelper.getAllExpenses();
        expect(expenses, hasLength(3));
      });
    });

    group('Delete Operations', () {
      test('should delete expense by id', () async {
        final expense = Expense(
          amount: 100.0,
          description: 'Test expense',
          timestamp: testDate,
        );

        final id = await dbHelper.insertExpense(expense);
        await dbHelper.deleteExpense(id);

        final allExpenses = await dbHelper.getAllExpenses();
        expect(allExpenses, isEmpty);
      });

      test('should throw exception when deleting non-existent expense', () async {
        expect(
          () => dbHelper.deleteExpense(999),
          throwsA(isA<DatabaseHelperException>()),
        );
      });

      test('should delete all expenses', () async {
        // Insert some test data
        await dbHelper.insertExpense(Expense(
          amount: 100.0,
          description: 'Test 1',
          timestamp: testDate,
        ));
        await dbHelper.insertExpense(Expense(
          amount: 200.0,
          description: 'Test 2',
          timestamp: testDate,
        ));

        await dbHelper.deleteAllExpenses();
        final expenses = await dbHelper.getAllExpenses();
        expect(expenses, isEmpty);
      });
    });

    group('Update Operations', () {
      test('should update expense successfully', () async {
        final expense = Expense(
          amount: 100.0,
          description: 'Original',
          timestamp: testDate,
        );

        final id = await dbHelper.insertExpense(expense);
        final updatedExpense = expense.copyWith(
          id: id,
          description: 'Updated',
          amount: 150.0,
        );

        await dbHelper.updateExpense(updatedExpense);

        final expenses = await dbHelper.getAllExpenses();
        expect(expenses, hasLength(1));
        expect(expenses.first.description, equals('Updated'));
        expect(expenses.first.amount, equals(150.0));
      });

      test('should throw exception when updating expense without id', () async {
        final expense = Expense(
          amount: 100.0,
          description: 'Test',
          timestamp: testDate,
        );

        expect(
          () => dbHelper.updateExpense(expense),
          throwsA(isA<DatabaseHelperException>()),
        );
      });
    });

    group('Calculation Operations', () {
      setUp(() async {
        // Insert test data for calculations
        final testExpenses = [
          Expense(
            amount: 100.0,
            description: 'Expense 1',
            timestamp: DateTime(2024, 1, 15, 8, 0),
          ),
          Expense(
            amount: 200.0,
            description: 'Expense 2',
            timestamp: DateTime(2024, 1, 15, 12, 0),
          ),
          Expense(
            amount: 50.0,
            description: 'Expense 3',
            timestamp: DateTime(2024, 1, 16, 18, 0),
          ),
        ];

        for (final expense in testExpenses) {
          await dbHelper.insertExpense(expense);
        }
      });

      test('should calculate daily total correctly', () async {
        final total = await dbHelper.getDailyTotal(DateTime(2024, 1, 15));
        expect(total, equals(300.0));
      });

      test('should calculate monthly total correctly', () async {
        final total = await dbHelper.getMonthlyTotal(2024, 1);
        expect(total, equals(350.0));
      });

      test('should return zero for date with no expenses', () async {
        final total = await dbHelper.getDailyTotal(DateTime(2024, 2, 1));
        expect(total, equals(0.0));
      });

      test('should get expense count for date', () async {
        final count = await dbHelper.getExpenseCountForDate(DateTime(2024, 1, 15));
        expect(count, equals(2));
      });
    });

    group('Error Handling', () {
      test('should handle database exceptions gracefully', () async {
        // Close the database to simulate error
        await dbHelper.close();
        
        // This should handle the error gracefully
        expect(
          () => dbHelper.deleteExpense(1),
          throwsA(isA<DatabaseHelperException>()),
        );
      });
    });
  });
}