import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daily_track/widgets/summary_card.dart';
import 'package:daily_track/providers/expense_provider.dart';

void main() {
  group('SummaryCard Widget Tests', () {
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
            body: SummaryCard(),
          ),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('should render summary card with header', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Expense Summary'), findsOneWidget);
        expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
      });

      testWidgets('should show today and monthly sections', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Today'), findsOneWidget);
        expect(find.text('This Month'), findsOneWidget);
        expect(find.byIcon(Icons.today), findsOneWidget);
        expect(find.byIcon(Icons.calendar_month), findsOneWidget);
      });

      testWidgets('should show zero amounts initially', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('₹0'), findsNWidgets(2)); // Both today and monthly should be ₹0
      });
    });

    group('Amount Display', () {
      testWidgets('should display daily total correctly', (tester) async {
        await provider.addExpenseFromInput('120 coffee');
        await provider.addExpenseFromInput('80 snack');

        await tester.pumpWidget(createTestWidget());

        expect(find.text('₹200'), findsAtLeastNWidgets(1)); // Daily total
      });

      testWidgets('should display monthly total correctly', (tester) async {
        await provider.addExpenseFromInput('100 expense1');
        await provider.addExpenseFromInput('200 expense2');
        await provider.addExpenseFromInput('50 expense3');

        await tester.pumpWidget(createTestWidget());

        expect(find.text('₹350'), findsAtLeastNWidgets(1)); // Monthly total
      });

      testWidgets('should format whole numbers without decimals', (tester) async {
        await provider.addExpenseFromInput('100 coffee');

        await tester.pumpWidget(createTestWidget());

        expect(find.text('₹100'), findsAtLeastNWidgets(1));
        expect(find.text('₹100.00'), findsNothing);
      });

      testWidgets('should format decimal numbers with decimals', (tester) async {
        await provider.addExpenseFromInput('120.50 coffee');

        await tester.pumpWidget(createTestWidget());

        expect(find.text('₹120.50'), findsAtLeastNWidgets(1));
      });
    });

    group('Loading State', () {
      testWidgets('should show loading indicators when loading', (tester) async {
        // Create a provider in loading state
        final loadingProvider = ExpenseProvider();
        // Don't initialize to keep it in loading state

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: loadingProvider,
              child: const Scaffold(
                body: SummaryCard(),
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
        
        loadingProvider.dispose();
      });

      testWidgets('should hide loading indicators after loading completes', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('₹0'), findsNWidgets(2));
      });
    });

    group('Additional Info', () {
      testWidgets('should show average expense when expenses exist', (tester) async {
        await provider.addExpenseFromInput('100 coffee');
        await provider.addExpenseFromInput('200 lunch');

        await tester.pumpWidget(createTestWidget());

        expect(find.textContaining('Average per expense today:'), findsOneWidget);
        expect(find.textContaining('₹150'), findsOneWidget); // (100 + 200) / 2
      });

      testWidgets('should not show average when no expenses', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.textContaining('Average per expense today:'), findsNothing);
      });

      testWidgets('should calculate average correctly with different amounts', (tester) async {
        await provider.addExpenseFromInput('50 snack');
        await provider.addExpenseFromInput('100 lunch');
        await provider.addExpenseFromInput('150 dinner');

        await tester.pumpWidget(createTestWidget());

        expect(find.textContaining('₹100'), findsOneWidget); // (50 + 100 + 150) / 3
      });

      testWidgets('should show info icon with average', (tester) async {
        await provider.addExpenseFromInput('100 coffee');

        await tester.pumpWidget(createTestWidget());

        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });
    });

    group('Styling and Layout', () {
      testWidgets('should have proper container styling', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text('Expense Summary'),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.decoration, isA<BoxDecoration>());
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.white));
        expect(decoration.border, isNotNull);
      });

      testWidgets('should have divider between today and monthly', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final dividers = find.byWidgetPredicate((widget) {
          return widget is Container && 
                 widget.decoration is BoxDecoration &&
                 (widget.decoration as BoxDecoration).color == Colors.grey[300];
        });

        expect(dividers, findsOneWidget);
      });

      testWidgets('should have proper text styling', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final titleText = tester.widget<Text>(find.text('Expense Summary'));
        expect(titleText.style?.fontSize, equals(20));
        expect(titleText.style?.fontWeight, equals(FontWeight.bold));
        expect(titleText.style?.color, equals(Colors.black));
      });
    });

    group('Responsive Design', () {
      testWidgets('should layout properly in different screen sizes', (tester) async {
        await provider.addExpenseFromInput('100 coffee');

        // Test with narrow screen
        await tester.binding.setSurfaceSize(const Size(300, 600));
        await tester.pumpWidget(createTestWidget());
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('This Month'), findsOneWidget);

        // Test with wide screen
        await tester.binding.setSurfaceSize(const Size(800, 600));
        await tester.pumpWidget(createTestWidget());
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('This Month'), findsOneWidget);
      });
    });

    group('Real-time Updates', () {
      testWidgets('should update when expenses are added', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Initially zero
        expect(find.text('₹0'), findsNWidgets(2));

        // Add expense
        await provider.addExpenseFromInput('150 lunch');
        await tester.pumpAndSettle();

        // Should update to show new total
        expect(find.text('₹150'), findsAtLeastNWidgets(1));
      });

      testWidgets('should update when expenses are deleted', (tester) async {
        // Add expense first
        await provider.addExpenseFromInput('100 coffee');
        await tester.pumpWidget(createTestWidget());

        expect(find.text('₹100'), findsAtLeastNWidgets(1));

        // Delete expense
        final expenseId = provider.todayExpenses.first.id!;
        await provider.deleteExpense(expenseId);
        await tester.pumpAndSettle();

        // Should update to show zero
        expect(find.text('₹0'), findsNWidgets(2));
      });

      testWidgets('should handle multiple rapid updates', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Add multiple expenses rapidly
        await provider.addExpenseFromInput('50 coffee');
        await provider.addExpenseFromInput('100 lunch');
        await provider.addExpenseFromInput('75 snack');
        await tester.pumpAndSettle();

        expect(find.text('₹225'), findsAtLeastNWidgets(1)); // Total
        expect(find.textContaining('₹75'), findsOneWidget); // Average
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle very large amounts', (tester) async {
        await provider.addExpenseFromInput('999999 expensive');

        await tester.pumpWidget(createTestWidget());

        expect(find.text('₹999999'), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle very small amounts', (tester) async {
        await provider.addExpenseFromInput('0.01 penny');

        await tester.pumpWidget(createTestWidget());

        expect(find.text('₹0.01'), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle single expense average', (tester) async {
        await provider.addExpenseFromInput('100 single');

        await tester.pumpWidget(createTestWidget());

        expect(find.textContaining('₹100'), findsAtLeastNWidgets(2)); // Total and average
      });
    });

    group('Integration', () {
      testWidgets('should work correctly with provider state changes', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Test complete workflow
        await provider.addExpenseFromInput('100 breakfast');
        await tester.pumpAndSettle();
        expect(find.text('₹100'), findsAtLeastNWidgets(1));

        await provider.addExpenseFromInput('150 lunch');
        await tester.pumpAndSettle();
        expect(find.text('₹250'), findsAtLeastNWidgets(1));

        // Delete one expense
        final expenseId = provider.todayExpenses.first.id!;
        await provider.deleteExpense(expenseId);
        await tester.pumpAndSettle();
        expect(find.text('₹100'), findsAtLeastNWidgets(1));
      });
    });
  });
}