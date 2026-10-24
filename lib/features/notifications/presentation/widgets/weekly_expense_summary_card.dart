import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/timeline_provider.dart';

class WeeklyExpenseSummaryCard extends StatelessWidget {
  final double totalSpent;
  final double lastWeekSpent;
  final int percentDecrease;
  final List<CategoryExpense> categories;

  const WeeklyExpenseSummaryCard({
    super.key,
    required this.totalSpent,
    required this.lastWeekSpent,
    required this.percentDecrease,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TỔNG CHI TUẦN QUA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.black54,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC2F0E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_downward,
                          size: 12, color: Color(0xFF0F5B47)),
                      const SizedBox(width: 2),
                      Text(
                        'Giảm $percentDecrease%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F5B47),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${currencyFormatter.format(totalSpent)} ₫',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
                children: [
                  const TextSpan(text: 'Tuần trước (18/09 – 24/09) đã chi '),
                  TextSpan(
                    text: '${currencyFormatter.format(lastWeekSpent)} ₫',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                      text: '. Bạn đang giữ nhịp chi tiêu rất dịu êm.'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Segmented Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    Expanded(
                      flex: 54,
                      child: Container(color: const Color(0xFF0F5B47)),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: 27,
                      child: Container(color: const Color(0xFF43B096)),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: 19,
                      child: Container(color: const Color(0xFFA0E0D2)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Category breakdown items
            for (final cat in categories) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F5B47),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            cat.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (cat.tag != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2F6F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                cat.tag!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F5B47),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      '${currencyFormatter.format(cat.amount)} ₫ ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '(${cat.percentage}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
