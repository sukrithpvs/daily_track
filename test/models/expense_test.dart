import 'package:flutter_test/flutter_test.dart';
import 'package:daily_track/models/expense.dart';

void main() {
  group('Expense Model Tests', () {
    late DateTime testTimestamp;
    late Expense testExpense;

    setUp(() {
      testTimestamp = DateTime(2024, 1, 15, 10, 30);
      testExpense = Expense(
        id: 1,
        amount: 120.50,
        description: 'Coffee and snacks',
        timestamp: testTimestamp,
      );
    });

    group('Constructor and Properties', () {
      test('should create expense with all properties', () {
        expect(testExpense.id, equals(1));
        expect(testExpense.amount, equals(120.50));
        expect(testExpense.description, equals('Coffee and snacks'));
        expect(testExpense.timestamp, equals(testTimestamp));
      });

      test('should create expense without id', () {
        final expense = Expense(
          amount: 50.0,
          description: 'Lunch',
          timestamp: testTimestamp,
        );
        
        expect(expense.id, isNull);
        expect(expense.amount, equals(50.0));
        expect(expense.description, equals('Lunch'));
        expect(expense.timestamp, equals(testTimestamp));
      });
    });

    group('Serialization', () {
      test('should convert to map correctly', () {
        final map = testExpense.toMap();
        
        expect(map['id'], equals(1));
        expect(map['amount'], equals(120.50));
        expect(map['description'], equals('Coffee and snacks'));
        expect(map['timestamp'], equals(testTimestamp.millisecondsSinceEpoch));
      });

      test('should create from map correctly', () {
        final map = {
          'id': 1,
          'amount': 120.50,
          'description': 'Coffee and snacks',
          'timestamp': testTimestamp.millisecondsSinceEpoch,
        };
        
        final expense = Expense.fromMap(map);
        
        expect(expense.id, equals(1));
        expect(expense.amount, equals(120.50));
        expect(expense.description, equals('Coffee and snacks'));
        expect(expense.timestamp, equals(testTimestamp));
      });

      test('should handle integer amount in fromMap', () {
        final map = {
          'id': 1,
          'amount': 120, // Integer instead of double
          'description': 'Test',
          'timestamp': testTimestamp.millisecondsSinceEpoch,
        };
        
        final expense = Expense.fromMap(map);
        expect(expense.amount, equals(120.0));
      });
    });

    group('Validation', () {
      test('validateAmount should return null for valid amounts', () {
        expect(Expense.validateAmount(1.0), isNull);
        expect(Expense.validateAmount(100.50), isNull);
        expect(Expense.validateAmount(0.01), isNull);
      });

      test('validateAmount should return error for invalid amounts', () {
        expect(Expense.validateAmount(null), isNotNull);
        expect(Expense.validateAmount(0), isNotNull);
        expect(Expense.validateAmount(-1), isNotNull);
      });

      test('validateDescription should return null for valid descriptions', () {
        expect(Expense.validateDescription('Coffee'), isNull);
        expect(Expense.validateDescription('  Lunch  '), isNull);
        expect(Expense.validateDescription('A' * 100), isNull);
      });

      test('validateDescription should return error for invalid descriptions', () {
        expect(Expense.validateDescription(null), isNotNull);
        expect(Expense.validateDescription(''), isNotNull);
        expect(Expense.validateDescription('   '), isNotNull);
        expect(Expense.validateDescription('A' * 101), isNotNull);
      });

      test('validate should return empty list for valid expense', () {
        expect(testExpense.validate(), isEmpty);
        expect(testExpense.isValid, isTrue);
      });

      test('validate should return errors for invalid expense', () {
        final invalidExpense = Expense(
          amount: -10,
          description: '',
          timestamp: testTimestamp,
        );
        
        final errors = invalidExpense.validate();
        expect(errors, hasLength(2));
        expect(invalidExpense.isValid, isFalse);
      });
    });

    group('CopyWith', () {
      test('should create copy with updated values', () {
        final newTimestamp = DateTime(2024, 1, 16);
        final copied = testExpense.copyWith(
          amount: 200.0,
          timestamp: newTimestamp,
        );
        
        expect(copied.id, equals(testExpense.id));
        expect(copied.amount, equals(200.0));
        expect(copied.description, equals(testExpense.description));
        expect(copied.timestamp, equals(newTimestamp));
      });

      test('should create identical copy when no parameters provided', () {
        final copied = testExpense.copyWith();
        
        expect(copied.id, equals(testExpense.id));
        expect(copied.amount, equals(testExpense.amount));
        expect(copied.description, equals(testExpense.description));
        expect(copied.timestamp, equals(testExpense.timestamp));
      });
    });

    group('Equality and HashCode', () {
      test('should be equal when all properties match', () {
        final expense1 = Expense(
          id: 1,
          amount: 100.0,
          description: 'Test',
          timestamp: testTimestamp,
        );
        
        final expense2 = Expense(
          id: 1,
          amount: 100.0,
          description: 'Test',
          timestamp: testTimestamp,
        );
        
        expect(expense1, equals(expense2));
        expect(expense1.hashCode, equals(expense2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final expense1 = testExpense;
        final expense2 = testExpense.copyWith(amount: 200.0);
        
        expect(expense1, isNot(equals(expense2)));
        expect(expense1.hashCode, isNot(equals(expense2.hashCode)));
      });
    });

    group('ToString', () {
      test('should return formatted string representation', () {
        final string = testExpense.toString();
        
        expect(string, contains('Expense'));
        expect(string, contains('id: 1'));
        expect(string, contains('amount: 120.5'));
        expect(string, contains('description: Coffee and snacks'));
      });
    });
  });
}