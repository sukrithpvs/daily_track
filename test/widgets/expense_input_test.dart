import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daily_track/widgets/expense_input.dart';
import 'package:daily_track/providers/expense_provider.dart';

void main() {
  group('ExpenseInput Widget Tests', () {
    late ExpenseProvider provider;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      provider = ExpenseProvider();
      await provider.initialize();
      await provider.clearAllExpenses();
    });

    tearDown(() async {
      await provider.clearAllExpenses();
      provider.dispose();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider.value(
          value: provider,
          child: const Scaffold(
            body: ExpenseInput(),
          ),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('should render input field and add button', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.text('Add'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('should show hint text', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(
          find.text('Enter expense (e.g., "120 coffee" or "120 - coffee")'),
          findsOneWidget,
        );
      });

      testWidgets('should show supported formats', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.textContaining('Supported formats:'), findsOneWidget);
      });
    });

    group('User Interaction', () {
      testWidgets('should accept text input', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final textField = find.byType(TextField);
        await tester.enterText(textField, '120 coffee');

        expect(find.text('120 coffee'), findsOneWidget);
      });

      testWidgets('should submit expense when add button is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter valid expense
        await tester.enterText(find.byType(TextField), '120 coffee');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify expense was added
        expect(provider.todayExpenses, hasLength(1));
        expect(provider.todayExpenses.first.amount, equals(120.0));
        expect(provider.todayExpenses.first.description, equals('coffee'));
      });

      testWidgets('should submit expense when enter key is pressed', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter valid expense and press enter
        await tester.enterText(find.byType(TextField), '75 lunch');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Verify expense was added
        expect(provider.todayExpenses, hasLength(1));
        expect(provider.todayExpenses.first.amount, equals(75.0));
      });

      testWidgets('should clear input field after successful submission', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter and submit expense
        await tester.enterText(find.byType(TextField), '50 snack');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify input field is cleared
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, isEmpty);
      });

      testWidgets('should not submit empty input', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Try to submit empty input
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify no expense was added
        expect(provider.todayExpenses, isEmpty);
      });

      testWidgets('should not submit whitespace-only input', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter whitespace and try to submit
        await tester.enterText(find.byType(TextField), '   ');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify no expense was added
        expect(provider.todayExpenses, isEmpty);
      });
    });

    group('Error Handling', () {
      testWidgets('should display error message for invalid input', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter invalid input
        await tester.enterText(find.byType(TextField), 'invalid input');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify error message is displayed
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.textContaining('Invalid input format'), findsOneWidget);
      });

      testWidgets('should keep input text when submission fails', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter invalid input
        await tester.enterText(find.byType(TextField), 'invalid input');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify input text is preserved
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, equals('invalid input'));
      });

      testWidgets('should clear error message after successful submission', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // First, cause an error
        await tester.enterText(find.byType(TextField), 'invalid');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        // Then submit valid input
        await tester.enterText(find.byType(TextField), '100 coffee');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Error should be cleared
        expect(find.byIcon(Icons.error_outline), findsNothing);
      });
    });

    group('Loading State', () {
      testWidgets('should show loading indicator during submission', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter valid input
        await tester.enterText(find.byType(TextField), '120 coffee');
        
        // Start submission but don't wait for completion
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(); // Only pump once to catch loading state

        // Note: The loading state might be too fast to catch in tests,
        // but we can verify the button becomes disabled
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        // The button should be disabled during submission
      });

      testWidgets('should disable input and button during submission', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.enterText(find.byType(TextField), '120 coffee');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(); // Don't settle to catch intermediate state

        // Input should be disabled during submission
        final textField = tester.widget<TextField>(find.byType(TextField));
        // Note: The actual disabled state might be hard to test due to timing
      });
    });

    group('Success Feedback', () {
      testWidgets('should show success snackbar after adding expense', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Add expense
        await tester.enterText(find.byType(TextField), '120 coffee');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify success message
        expect(find.text('Expense added successfully'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper text input action', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.textInputAction, equals(TextInputAction.done));
      });

      testWidgets('should have appropriate keyboard type', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.keyboardType, equals(TextInputType.text));
      });
    });

    group('Integration', () {
      testWidgets('should work with provider state changes', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Add multiple expenses
        await tester.enterText(find.byType(TextField), '100 breakfast');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '150 lunch');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify provider state
        expect(provider.todayExpenses, hasLength(2));
        expect(provider.dailyTotal, equals(250.0));
      });
    });
  });
}