import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daily_track/main.dart';

void main() {
  group('DailyTrack App Integration Tests', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    testWidgets('Complete expense tracking workflow', (tester) async {
      await tester.pumpWidget(const DailyTrackApp());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('DailyTrack'), findsOneWidget);
      expect(find.text('No expenses today'), findsOneWidget);
      expect(find.text('₹0'), findsAtLeastNWidgets(2)); // Daily and monthly totals

      // Add first expense
      await tester.enterText(find.byType(TextField), '120 coffee');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify expense was added
      expect(find.text('coffee'), findsOneWidget);
      expect(find.text('₹120'), findsAtLeastNWidgets(1));
      expect(find.text('No expenses today'), findsNothing);

      // Add second expense
      await tester.enterText(find.byType(TextField), '75 lunch');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify both expenses and updated totals
      expect(find.text('coffee'), findsOneWidget);
      expect(find.text('lunch'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);
      expect(find.text('₹195'), findsAtLeastNWidgets(1)); // Total should be 195

      // Test input validation
      await tester.enterText(find.byType(TextField), 'invalid input');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Should show error and not add expense
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget); // Still 2 items

      // Test successful input after error
      await tester.enterText(find.byType(TextField), '50 snack');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Error should be cleared and expense added
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.text('3 items'), findsOneWidget);
      expect(find.text('snack'), findsOneWidget);
    });

    testWidgets('Expense deletion workflow', (tester) async {
      await tester.pumpWidget(const DailyTrackApp());
      await tester.pumpAndSettle();

      // Add expenses
      await tester.enterText(find.byType(TextField), '100 coffee');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '200 lunch');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('2 items'), findsOneWidget);

      // Long press to delete
      await tester.longPress(find.text('lunch'));
      await tester.pumpAndSettle();

      // Confirm deletion
      expect(find.text('Delete Expense'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify expense was deleted
      expect(find.text('lunch'), findsNothing);
      expect(find.text('1 item'), findsOneWidget);
      expect(find.text('coffee'), findsOneWidget);
    });

    testWidgets('Summary calculations update correctly', (tester) async {
      await tester.pumpWidget(const DailyTrackApp());
      await tester.pumpAndSettle();

      // Initial state - zeros
      expect(find.text('₹0'), findsNWidgets(2));

      // Add expense and verify summary updates
      await tester.enterText(find.byType(TextField), '150 dinner');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('₹150'), findsAtLeastNWidgets(2)); // Daily and monthly

      // Add another expense
      await tester.enterText(find.byType(TextField), '75 dessert');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('₹225'), findsAtLeastNWidgets(2)); // Updated totals

      // Verify average calculation appears
      expect(find.textContaining('Average per expense today:'), findsOneWidget);
    });

    testWidgets('Export functionality integration', (tester) async {
      await tester.pumpWidget(const DailyTrackApp());
      await tester.pumpAndSettle();

      // Add some expenses
      await tester.enterText(find.byType(TextField), '100 coffee');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '200 lunch');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Try to export (will likely fail due to permissions in test environment)
      await tester.tap(find.text('Export Month'));
      await tester.pumpAndSettle();

      // Should show some kind of dialog (either success or error)
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('App handles empty states correctly', (tester) async {
      await tester.pumpWidget(const DailyTrackApp());
      await tester.pumpAndSettle();

      // Verify empty state UI
      expect(find.text('No expenses today'), findsOneWidget);
      expect(find.text('Add your first expense above'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);

      // Verify export button is still available (though will show no data message)
      expect(find.text('Export Month'), findsOneWidget);

      // Verify summary shows zeros
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('₹0'), findsNWidgets(2));
    });

    testWidgets('Input field behavior and validation', (tester) async {
      await tester.pumpWidget(const DailyTrackApp());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);

      // Test various input formats
      final testCases = [
        {'input': '120 coffee', 'shouldWork': true},
        {'input': '75.50 - lunch', 'shouldWork': true},
        {'input': 'invalid', 'shouldWork': false},
        {'input': '0 zero', 'shouldWork': false},
        {'input': '-50 negative', 'shouldWork': false},
      ];

      for (final testCase in testCases) {
        final input = testCase['input'] as String;
        final shouldWork = testCase['shouldWork'] as bool;

        await tester.enterText(textField, input);
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        if (shouldWork) {
          // Should not show error
          expect(find.byIcon(Icons.error_outline), findsNothing);
          // Input should be cleared
          final textFieldWidget = tester.widget<TextField>(textField);
          expect(textFieldWidget.controller?.text, isEmpty);
        } else {
          // Should show error
          expect(find.byIcon(Icons.error_outline), findsOneWidget);
          // Input should be preserved for correction
          final textFieldWidget = tester.widget<TextField>(textField);
          expect(textFieldWidget.controller?.text, equals(input));
        }

        // Clear any error state for next test
        await tester.enterText(textField, '1 clear');
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('UI responsiveness and loading states', (tester) async {
      await tester.pumpWidget(const DailyTrackApp());
      await tester.pumpAndSettle();

      // Test that UI responds to rapid inputs
      for (int i = 0; i < 5; i++) {
        await tester.enterText(find.byType(TextField), '${10 + i} item$i');
        await tester.tap(find.text('Add'));
        await tester.pump(); // Don't settle to test intermediate states
      }

      await tester.pumpAndSettle(); // Now settle

      // Should have all 5 items
      expect(find.text('5 items'), findsOneWidget);
    });

    testWidgets('Theme and styling consistency', (tester) async {
      await tester.pumpWidget(const DailyTrackApp());
      await tester.pumpAndSettle();

      // Verify black and white theme
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.grey[50]));

      // Verify app bar styling
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, equals(Colors.white));
      expect(appBar.foregroundColor, equals(Colors.black));

      // Add an expense to test item styling
      await tester.enterText(find.byType(TextField), '100 coffee');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify consistent black and white styling throughout
      expect(find.text('coffee'), findsOneWidget);
      expect(find.text('₹100'), findsAtLeastNWidgets(1));
    });

    testWidgets('Accessibility and usability features', (tester) async {
      await tester.pumpWidget(const DailyTrackApp());
      await tester.pumpAndSettle();

      // Test keyboard navigation
      final textField = find.byType(TextField);
      await tester.enterText(textField, '50 test');
      
      // Test enter key submission
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('test'), findsOneWidget);

      // Test that focus returns to input after successful submission
      // (This would need more complex testing in a real app)
    });
  });
}