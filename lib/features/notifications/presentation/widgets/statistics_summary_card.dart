import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/timeline_item.dart';

class StatisticsSummaryCard extends StatelessWidget {
  final List<TimelineItem> items;

  const StatisticsSummaryCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');

    final double totalIncome = items
        .where((item) => item.isIncome)
        .fold(0.0, (sum, item) => sum + item.amount);

    final double totalExpense = items
        .where((item) => item.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);

    final double netBalance = totalIncome - totalExpense;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatCol(
              title: 'Tổng Thu',
              amount: '+${currencyFormatter.format(totalIncome)} ₫',
              color: Colors.green.shade700,
              icon: Icons.arrow_downward,
            ),
            Container(height: 30, width: 1, color: Colors.grey.shade300),
            _buildStatCol(
              title: 'Tổng Chi',
              amount: '-${currencyFormatter.format(totalExpense)} ₫',
              color: Colors.red.shade700,
              icon: Icons.arrow_upward,
            ),
            Container(height: 30, width: 1, color: Colors.grey.shade300),
            _buildStatCol(
              title: 'Thặng Dư',
              amount: '${currencyFormatter.format(netBalance)} ₫',
              color: netBalance >= 0
                  ? const Color(0xFF00A86B)
                  : Colors.red.shade900,
              icon: Icons.account_balance_wallet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
