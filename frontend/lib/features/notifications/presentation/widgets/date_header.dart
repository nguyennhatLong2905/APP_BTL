import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateHeader extends StatelessWidget {
  final DateTime date;
  final double totalIncome;
  final double totalExpense;

  const DateHeader({
    super.key,
    required this.date,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final dateFormatter = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN');

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: Color(0xFF00A86B)),
              const SizedBox(width: 8),
              Text(
                dateFormatter.format(date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (totalIncome > 0)
                Text(
                  '+${currencyFormatter.format(totalIncome)} ₫  ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              if (totalExpense > 0)
                Text(
                  '-${currencyFormatter.format(totalExpense)} ₫',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
