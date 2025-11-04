import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final currencyFormat = NumberFormat.currency(
          symbol: '₹',
          decimalDigits: 0,
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    color: Colors.black,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Expense Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Summary items
              Row(
                children: [
                  Expanded(
                    child: _SummaryItem(
                      title: 'Today',
                      amount: provider.dailyTotal,
                      icon: Icons.today,
                      isLoading: provider.isLoading,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Divider
                  Container(
                    height: 60,
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: _SummaryItem(
                      title: 'This Month',
                      amount: provider.monthlyTotal,
                      icon: Icons.calendar_month,
                      isLoading: provider.isLoading,
                    ),
                  ),
                ],
              ),
              
              // Additional info
              if (provider.todayExpenses.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Average per expense today: ${currencyFormat.format(provider.dailyTotal / provider.todayExpenses.length)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final bool isLoading;

  const _SummaryItem({
    required this.title,
    required this.amount,
    required this.icon,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with icon
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Amount
        if (isLoading)
          const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.black,
            ),
          )
        else
          Text(
            currencyFormat.format(amount),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
      ],
    );
  }
}