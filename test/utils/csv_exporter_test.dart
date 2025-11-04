import 'package:flutter_test/flutter_test.dart';
import 'package:daily_track/utils/csv_exporter.dart';
import 'package:daily_track/models/expense.dart';

void main() {
  group('CsvExporter Tests', () {
    late List<Expense> testExpenses;

    setUp(() {
      testExpenses = [
        Expense(
          id: 1,
          amount: 120.50,
          description: 'Coffee and pastry',
          timestamp: DateTime(2024, 1, 15, 8, 30),
        ),
        Expense(
          id: 2,
          amount: 75.00,
          description: 'Lunch',
          timestamp: DateTime(2024, 1, 15, 12, 45),
        ),
        Expense(
          id: 3,
          amount: 25.25,
          description: 'Bus fare',
          timestamp: DateTime(2024, 1, 15, 18, 15),
        ),
      ];
    });

    group('Export Validation', () {
      test('should return no errors for valid expenses', () {
        final errors = CsvExporter.validateExpensesForExport(testExpenses);
        expect(errors, isEmpty);
      });

      test('should return error for empty expense list', () {
        final errors = CsvExporter.validateExpensesForExport([]);
        expect(errors, hasLength(1));
        expect(errors.first, equals('No expenses to export'));
      });

      test('should return errors for invalid expenses', () {
        final invalidExpenses = [
          Expense(
            amount: -10.0, // Invalid amount
            description: '', // Invalid description
            timestamp: DateTime.now(),
          ),
        ];
        
        final errors = CsvExporter.validateExpensesForExport(invalidExpenses);
        expect(errors, isNotEmpty);
        expect(errors.first, contains('Expense 1:'));
      });
    });

    group('Export Statistics', () {
      test('should calculate correct statistics', () {
        final stats = CsvExporter.getExportStatistics(testExpenses);
        
        expect(stats.totalExpenses, equals(3));
        expect(stats.totalAmount, equals(220.75)); // 120.50 + 75.00 + 25.25
        expect(stats.averageAmount, closeTo(73.58, 0.01)); // 220.75 / 3
        expect(stats.dateRange, isNotNull);
        expect(stats.dateRange!.start, equals(DateTime(2024, 1, 15, 8, 30)));
        expect(stats.dateRange!.end, equals(DateTime(2024, 1, 15, 18, 15)));
      });

      test('should handle empty expense list for statistics', () {
        final stats = CsvExporter.getExportStatistics([]);
        
        expect(stats.totalExpenses, equals(0));
        expect(stats.totalAmount, equals(0.0));
        expect(stats.averageAmount, equals(0.0));
        expect(stats.dateRange, isNull);
      });

      test('should handle single expense for statistics', () {
        final singleExpense = [testExpenses.first];
        final stats = CsvExporter.getExportStatistics(singleExpense);
        
        expect(stats.totalExpenses, equals(1));
        expect(stats.totalAmount, equals(120.50));
        expect(stats.averageAmount, equals(120.50));
        expect(stats.dateRange, isNotNull);
      });
    });

    group('Date Range', () {
      test('should identify same day correctly', () {
        final dateRange = DateRange(
          start: DateTime(2024, 1, 15, 8, 0),
          end: DateTime(2024, 1, 15, 18, 0),
        );
        
        expect(dateRange.isSameDay, isTrue);
        expect(dateRange.isSameMonth, isTrue);
      });

      test('should identify same month correctly', () {
        final dateRange = DateRange(
          start: DateTime(2024, 1, 15),
          end: DateTime(2024, 1, 25),
        );
        
        expect(dateRange.isSameDay, isFalse);
        expect(dateRange.isSameMonth, isTrue);
      });

      test('should identify different months correctly', () {
        final dateRange = DateRange(
          start: DateTime(2024, 1, 15),
          end: DateTime(2024, 2, 15),
        );
        
        expect(dateRange.isSameDay, isFalse);
        expect(dateRange.isSameMonth, isFalse);
      });

      test('should calculate duration correctly', () {
        final dateRange = DateRange(
          start: DateTime(2024, 1, 15, 8, 0),
          end: DateTime(2024, 1, 15, 18, 0),
        );
        
        expect(dateRange.duration.inHours, equals(10));
      });
    });

    group('Export Result', () {
      test('should create success result correctly', () {
        final result = CsvExportResult.success(
          filePath: '/path/to/file.csv',
          fileName: 'test.csv',
          recordCount: 5,
        );
        
        expect(result.success, isTrue);
        expect(result.filePath, equals('/path/to/file.csv'));
        expect(result.fileName, equals('test.csv'));
        expect(result.recordCount, equals(5));
        expect(result.errorMessage, isNull);
      });

      test('should create error result correctly', () {
        final result = CsvExportResult.error('Test error message');
        
        expect(result.success, isFalse);
        expect(result.filePath, isNull);
        expect(result.fileName, isNull);
        expect(result.recordCount, isNull);
        expect(result.errorMessage, equals('Test error message'));
      });
    });

    group('Supported Formats', () {
      test('should return CSV as supported format', () {
        final formats = CsvExporter.getSupportedFormats();
        expect(formats, contains('CSV'));
        expect(formats, hasLength(1));
      });
    });
  });
}