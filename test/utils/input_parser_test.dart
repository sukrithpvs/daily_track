import 'package:flutter_test/flutter_test.dart';
import 'package:daily_track/utils/input_parser.dart';

void main() {
  group('InputParser Tests', () {
    group('parseExpenseInput', () {
      test('should parse dash-separated format correctly', () {
        final result = InputParser.parseExpenseInput('120 - coffee');
        
        expect(result, isNotNull);
        expect(result!['amount'], equals(120.0));
        expect(result['description'], equals('coffee'));
      });

      test('should parse space-separated format correctly', () {
        final result = InputParser.parseExpenseInput('120 coffee');
        
        expect(result, isNotNull);
        expect(result!['amount'], equals(120.0));
        expect(result['description'], equals('coffee'));
      });

      test('should parse decimal amounts correctly', () {
        final result1 = InputParser.parseExpenseInput('120.50 - lunch');
        final result2 = InputParser.parseExpenseInput('25.75 snack');
        
        expect(result1, isNotNull);
        expect(result1!['amount'], equals(120.50));
        expect(result1['description'], equals('lunch'));
        
        expect(result2, isNotNull);
        expect(result2!['amount'], equals(25.75));
        expect(result2['description'], equals('snack'));
      });

      test('should handle extra whitespace correctly', () {
        final result1 = InputParser.parseExpenseInput('  120  -  coffee  ');
        final result2 = InputParser.parseExpenseInput('  120   coffee  ');
        
        expect(result1, isNotNull);
        expect(result1!['amount'], equals(120.0));
        expect(result1['description'], equals('coffee'));
        
        expect(result2, isNotNull);
        expect(result2!['amount'], equals(120.0));
        expect(result2['description'], equals('coffee'));
      });

      test('should handle multi-word descriptions', () {
        final result1 = InputParser.parseExpenseInput('50 - coffee and snacks');
        final result2 = InputParser.parseExpenseInput('75 grocery shopping');
        
        expect(result1, isNotNull);
        expect(result1!['description'], equals('coffee and snacks'));
        
        expect(result2, isNotNull);
        expect(result2!['description'], equals('grocery shopping'));
      });

      test('should return null for invalid formats', () {
        expect(InputParser.parseExpenseInput(''), isNull);
        expect(InputParser.parseExpenseInput('   '), isNull);
        expect(InputParser.parseExpenseInput('coffee'), isNull);
        expect(InputParser.parseExpenseInput('120'), isNull);
        expect(InputParser.parseExpenseInput('abc coffee'), isNull);
        expect(InputParser.parseExpenseInput('120 -'), isNull);
        expect(InputParser.parseExpenseInput('- coffee'), isNull);
      });

      test('should return null for zero or negative amounts', () {
        expect(InputParser.parseExpenseInput('0 coffee'), isNull);
        expect(InputParser.parseExpenseInput('-10 coffee'), isNull);
        expect(InputParser.parseExpenseInput('0.0 - lunch'), isNull);
      });

      test('should handle edge cases', () {
        expect(InputParser.parseExpenseInput('0.01 coffee'), isNotNull);
        expect(InputParser.parseExpenseInput('999999 expensive'), isNotNull);
        expect(InputParser.parseExpenseInput('1 a'), isNotNull);
      });
    });

    group('isValidFormat', () {
      test('should return true for valid formats', () {
        expect(InputParser.isValidFormat('120 coffee'), isTrue);
        expect(InputParser.isValidFormat('120 - coffee'), isTrue);
        expect(InputParser.isValidFormat('25.50 lunch'), isTrue);
        expect(InputParser.isValidFormat('100 grocery shopping'), isTrue);
      });

      test('should return false for invalid formats', () {
        expect(InputParser.isValidFormat(''), isFalse);
        expect(InputParser.isValidFormat('coffee'), isFalse);
        expect(InputParser.isValidFormat('120'), isFalse);
        expect(InputParser.isValidFormat('abc coffee'), isFalse);
      });
    });

    group('extractAmount', () {
      test('should extract amount correctly', () {
        expect(InputParser.extractAmount('120 coffee'), equals(120.0));
        expect(InputParser.extractAmount('25.50 - lunch'), equals(25.50));
        expect(InputParser.extractAmount('invalid'), isNull);
      });
    });

    group('extractDescription', () {
      test('should extract description correctly', () {
        expect(InputParser.extractDescription('120 coffee'), equals('coffee'));
        expect(InputParser.extractDescription('25.50 - lunch'), equals('lunch'));
        expect(InputParser.extractDescription('100 grocery shopping'), equals('grocery shopping'));
        expect(InputParser.extractDescription('invalid'), isNull);
      });
    });

    group('validateAmount', () {
      test('should return null for valid amounts', () {
        expect(InputParser.validateAmount(1.0), isNull);
        expect(InputParser.validateAmount(100.50), isNull);
        expect(InputParser.validateAmount(999999.0), isNull);
      });

      test('should return error for invalid amounts', () {
        expect(InputParser.validateAmount(null), isNotNull);
        expect(InputParser.validateAmount(0.0), isNotNull);
        expect(InputParser.validateAmount(-1.0), isNotNull);
        expect(InputParser.validateAmount(1000000.0), isNotNull);
      });
    });

    group('validateDescription', () {
      test('should return null for valid descriptions', () {
        expect(InputParser.validateDescription('coffee'), isNull);
        expect(InputParser.validateDescription('grocery shopping'), isNull);
        expect(InputParser.validateDescription('a'), isNull);
        expect(InputParser.validateDescription('A' * 100), isNull);
      });

      test('should return error for invalid descriptions', () {
        expect(InputParser.validateDescription(null), isNotNull);
        expect(InputParser.validateDescription(''), isNotNull);
        expect(InputParser.validateDescription('   '), isNotNull);
        expect(InputParser.validateDescription('A' * 101), isNotNull);
      });
    });

    group('validateParsedInput', () {
      test('should return empty list for valid parsed input', () {
        final parsed = {'amount': 120.0, 'description': 'coffee'};
        final errors = InputParser.validateParsedInput(parsed);
        expect(errors, isEmpty);
      });

      test('should return errors for invalid parsed input', () {
        final parsed1 = {'amount': -10.0, 'description': 'coffee'};
        final errors1 = InputParser.validateParsedInput(parsed1);
        expect(errors1, isNotEmpty);
        
        final parsed2 = {'amount': 120.0, 'description': ''};
        final errors2 = InputParser.validateParsedInput(parsed2);
        expect(errors2, isNotEmpty);
        
        final errors3 = InputParser.validateParsedInput(null);
        expect(errors3, isNotEmpty);
        expect(errors3.first, contains('Invalid input format'));
      });

      test('should return multiple errors for multiple issues', () {
        final parsed = {'amount': -10.0, 'description': ''};
        final errors = InputParser.validateParsedInput(parsed);
        expect(errors, hasLength(2));
      });
    });

    group('formatAmount', () {
      test('should format whole numbers without decimals', () {
        expect(InputParser.formatAmount(120.0), equals('120'));
        expect(InputParser.formatAmount(1.0), equals('1'));
      });

      test('should format decimal numbers with two decimal places', () {
        expect(InputParser.formatAmount(120.50), equals('120.50'));
        expect(InputParser.formatAmount(25.75), equals('25.75'));
        expect(InputParser.formatAmount(1.01), equals('1.01'));
      });
    });

    group('normalizeInput', () {
      test('should trim and normalize whitespace', () {
        expect(InputParser.normalizeInput('  120   coffee  '), equals('120 coffee'));
        expect(InputParser.normalizeInput('120\t-\tcoffee'), equals('120 - coffee'));
        expect(InputParser.normalizeInput('120\n\ncoffee'), equals('120 coffee'));
      });

      test('should handle empty and whitespace-only input', () {
        expect(InputParser.normalizeInput(''), equals(''));
        expect(InputParser.normalizeInput('   '), equals(''));
      });
    });

    group('getSupportedFormats', () {
      test('should return list of example formats', () {
        final formats = InputParser.getSupportedFormats();
        expect(formats, isNotEmpty);
        expect(formats, contains('120 - coffee'));
        expect(formats, contains('120 coffee'));
      });
    });

    group('Integration Tests', () {
      test('should handle complete parsing workflow', () {
        const input = '  120.50  -  coffee and pastry  ';
        
        // Normalize input
        final normalized = InputParser.normalizeInput(input);
        expect(normalized, equals('120.50 - coffee and pastry'));
        
        // Parse input
        final parsed = InputParser.parseExpenseInput(normalized);
        expect(parsed, isNotNull);
        
        // Validate parsed input
        final errors = InputParser.validateParsedInput(parsed);
        expect(errors, isEmpty);
        
        // Extract values
        final amount = InputParser.extractAmount(normalized);
        final description = InputParser.extractDescription(normalized);
        
        expect(amount, equals(120.50));
        expect(description, equals('coffee and pastry'));
        
        // Format amount
        final formattedAmount = InputParser.formatAmount(amount!);
        expect(formattedAmount, equals('120.50'));
      });

      test('should handle various real-world inputs', () {
        final testCases = [
          {'input': '50 lunch', 'amount': 50.0, 'description': 'lunch'},
          {'input': '25.75 - coffee', 'amount': 25.75, 'description': 'coffee'},
          {'input': '100 grocery shopping', 'amount': 100.0, 'description': 'grocery shopping'},
          {'input': '15.50 - bus fare', 'amount': 15.50, 'description': 'bus fare'},
          {'input': '200 dinner with friends', 'amount': 200.0, 'description': 'dinner with friends'},
        ];
        
        for (final testCase in testCases) {
          final input = testCase['input'] as String;
          final expectedAmount = testCase['amount'] as double;
          final expectedDescription = testCase['description'] as String;
          
          final parsed = InputParser.parseExpenseInput(input);
          expect(parsed, isNotNull, reason: 'Failed to parse: $input');
          expect(parsed!['amount'], equals(expectedAmount));
          expect(parsed['description'], equals(expectedDescription));
          
          final errors = InputParser.validateParsedInput(parsed);
          expect(errors, isEmpty, reason: 'Validation failed for: $input');
        }
      });
    });
  });
}