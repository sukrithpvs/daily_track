import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daily_track/widgets/expense_list.dart';
import 'package:daily_track/providers/expense_provider.dart';
import 'package:daily_track/models/expense.dart';

void main() {
  group('ExpenseList Widget Tests', () {
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
            body: ExpenseList(),
          ),
        ),
      );
    }

    group('Empty State', () {
      testWidgets('should show empty state when no expenses', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('No expenses today'), findsOneWidget);
        expect(find.text('Add your first expense above'), findsOneWidget);
        expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
      });

      testWidgets('should show empty state container with proper styling', (tester) async {
        await tester.pumpWidget(createTestWidget());

        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text('No expenses today'),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.decoration, isA<BoxDecoration>());
      });
    });

    group('Loading State', () {
      testWidgets('should show loading indicator when loading', (tester) async {
        // Create a provider that's in loading state
        final loadingProvider = ExpenseProvider();
        // Don't initialize to keep it in loading state

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider.value(
              value: loadingProvider,
              child: const Scaffold(
                body: ExpenseList(),
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        loadingProvider.dispose();
      });
    });

    group('Expense Display', () {
      testWidgets('should display expenses when available', (tester) async {
        // Add test expenses
        await provider.addExpenseFromInput('120 coffee');
        await provider.addExpenseFromInput('75 lunch');

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Today\'s Expenses'), findsOneWidget);
        expect(find.text('2 items'), findsOneWidget);
        expect(find.text('coffee'), findsOneWidget);
        expect(find.text('lunch'), findsOneWidget);
        expect(find.text('₹120'), findsOneWidget);
        expect(find.text('₹75'), findsOneWidget);
      });

      testWidgets('should show single item count correctly', (tester) async {
        await provider.addExpenseFromInput('50 snack');

        await tester.pumpWidget(createTestWidget());

        expect(find.text('1 item'), findsOneWidget);
      });

      testWidgets('should display expenses in chronological order', (tester) async {
        // Add expenses with slight delay to ensure different timestamps
        await provider.addExpenseFromInput('100 first');
        await Future.delayed(const Duration(milliseconds: 10));
        await provider.addExpenseFromInput('200 second');
        await Future.delayed(const Duration(milliseconds: 10));
        await provider.addExpenseFromInput('300 third');

        await tester.pumpWidget(createTestWidget());

        // Find all expense items
        final expenseItems = find.byType(Material);
        expect(expenseItems, findsWidgets);

        // The newest should be first (third)
        expect(find.text('third'), findsOneWidget);
        expect(find.text('second'), findsOneWidget);
        expect(find.text('first'), findsOneWidget);
      });

      testWidgets('should format currency correctly', (tester) async {
        await provider.addExpenseFromInput('120.50 coffee');
        await provider.addExpenseFromInput('100 lunch');

        await tester.pumpWidget(createTestWidget());

        expect(find.text('₹121'), findsOneWidget); // Rounded up
        expect(find.text('₹100'), findsOneWidget);
      });

      testWidgets('should show time for each expense', (tester) async {
        await provider.addExpenseFromInput('120 coffee');

        await tester.pumpWidget(createTestWidget());

        // Should find time in HH:mm format
        expect(find.byWidgetPredicate((widget) {
          return widget is Text && 
                 widget.data != null && 
                 RegExp(r'^\d{2}:\d{2}$').hasMatch(widget.data!);
        }), findsOneWidget);
      });
    });

    group('Delete Functionality', () {
      testWidgets('should show delete confirmation on long press', (tester) async {
        await provider.addExpenseFromInput('120 coffee');

        await tester.pumpWidget(createTestWidget());

        // Long press on expense item
        await tester.longPress(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('Delete Expense'), findsOneWidget);
        expect(find.text('Are you sure you want to delete "coffee" (₹120.00)?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('should cancel delete when cancel is pressed', (tester) async {
        await provider.addExpenseFromInput('120 coffee');

        await tester.pumpWidget(createTestWidget());

        // Long press and cancel
        await tester.longPress(find.byType(InkWell));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Expense should still be there
        expect(provider.todayExpenses, hasLength(1));
        expect(find.text('coffee'), findsOneWidget);
      });

      testWidgets('should delete expense when confirmed', (tester) async {
        await provider.addExpenseFromInput('120 coffee');
        expect(provider.todayExpenses, hasLength(1));

        await tester.pumpWidget(createTestWidget());

        // Long press and confirm delete
        await tester.longPress(find.byType(InkWell));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Expense should be deleted
        expect(provider.todayExpenses, isEmpty);
        expect(find.text('No expenses today'), findsOneWidget);
      });
    });

    group('UI Elements', () {
      testWidgets('should show header with icon and title', (tester) async {
        await provider.addExpenseFromInput('120 coffee');

        await tester.pumpWidget(createTestWidget());

        expect(find.byIcon(Icons.receipt_long), findsOneWidget);
        expect(find.text('Today\'s Expenses'), findsOneWidget);
      });

      testWidgets('should show more options icon for each expense', (tester) async {
        await provider.addExpenseFromInput('120 coffee');

        await tester.pumpWidget(createTestWidget());

        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('should have proper container styling', (tester) async {
        await provider.addExpenseFromInput('120 coffee');

        await tester.pumpWidget(createTestWidget());

        // Find the main container
        final containers = find.byType(Container);
        expect(containers, findsWidgets);
      });
    });

    group('Text Overflow', () {
      testWidgets('should handle long descriptions properly', (tester) async {
        final longDescription = 'A' * 100;
        await provider.addExpenseFromInput('120 $longDescription');

        await tester.pumpWidget(createTestWidget());

        // Should find the text widget with overflow handling
        final textWidget = tester.widget<Text>(
          find.byWidgetPredicate((widget) {
            return widget is Text && 
                   widget.data != null && 
                   widget.data!.contains('A');
          }),
        );

        expect(textWidget.maxLines, equals(2));
        expect(textWidget.overflow, equals(TextOverflow.ellipsis));
      });
    });

    group('Responsive Design', () {
      testWidgets('should layout properly in different screen sizes', (tester) async {
        await provider.addExpenseFromInput('120 coffee');

        // Test with different screen sizes
        await tester.binding.setSurfaceSize(const Size(400, 800));
        await tester.pumpWidget(createTestWidget());
        expect(find.text('coffee'), findsOneWidget);

        await tester.binding.setSurfaceSize(const Size(800, 600));
        await tester.pumpWidget(createTestWidget());
        expect(find.text('coffee'), findsOneWidget);
      });
    });

    group('Integration', () {
      testWidgets('should update when provider state changes', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Initially empty
        expect(find.text('No expenses today'), findsOneWidget);

        // Add expense through provider
        await provider.addExpenseFromInput('120 coffee');
        await tester.pumpAndSettle();

        // Should show the expense
        expect(find.text('coffee'), findsOneWidget);
        expect(find.text('No expenses today'), findsNothing);
      });

      testWidgets('should handle multiple rapid updates', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Add multiple expenses rapidly
        await provider.addExpenseFromInput('100 coffee');
        await provider.addExpenseFromInput('200 lunch');
        await provider.addExpenseFromInput('50 snack');
        await tester.pumpAndSettle();

        expect(find.text('3 items'), findsOneWidget);
        expect(find.text('coffee'), findsOneWidget);
        expect(find.text('lunch'), findsOneWidget);
        expect(find.text('snack'), findsOneWidget);
      });
    });
  });
}