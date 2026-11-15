import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/timeline_provider.dart';

class WeeklyExpenseSummaryCard extends StatelessWidget {
  final double totalSpent;
  final double lastWeekSpent;
  final int percentDecrease;
  final List<CategoryExpense> categories;
  final String lastWeekRangeText; // Thêm tham số này

  const WeeklyExpenseSummaryCard({
    super.key,
    required this.totalSpent,
    required this.lastWeekSpent,
    required this.percentDecrease,
    required this.categories,
    this.lastWeekRangeText = '--', // Mặc định
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    
    // Tính toán dữ liệu hiển thị
    final hasData = totalSpent > 0 || lastWeekSpent > 0 || categories.isNotEmpty;
    final displayTotal = totalSpent > 0 ? totalSpent : 0;
    final displayLastWeek = lastWeekSpent > 0 ? lastWeekSpent : 0;
    final displayPercent = percentDecrease.abs();
    final isDecrease = percentDecrease >= 0; // true = giảm, false = tăng

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
                if (hasData && displayPercent > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDecrease ? const Color(0xFFC2F0E6) : const Color(0xFFFFE5E5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDecrease ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 12,
                          color: isDecrease ? const Color(0xFF0F5B47) : const Color(0xFFD32F2F),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${isDecrease ? "Giảm" : "Tăng"} $displayPercent%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDecrease ? const Color(0xFF0F5B47) : const Color(0xFFD32F2F),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${currencyFormatter.format(displayTotal)} ₫',
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
                  TextSpan(
                    text: hasData && displayLastWeek > 0
                        ? 'Tuần trước ($lastWeekRangeText) đã chi '
                        : 'Chưa có dữ liệu tuần trước. ',
                  ),
                  if (hasData && displayLastWeek > 0) ...[
                    TextSpan(
                      text: '${currencyFormatter.format(displayLastWeek)} ₫',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: isDecrease 
                          ? '. Bạn đang giữ nhịp chi tiêu rất dịu êm.'
                          : '. Hãy cẩn thận với chi tiêu tuần này.',
                    ),
                  ],
                  if (!hasData)
                    const TextSpan(
                      text: 'Hãy thêm giao dịch để xem phân tích.',
                    ),
                ],
              ),
            ),
            
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 14),

              // Segmented Progress Bar - tính % dựa trên categories
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      for (int i = 0; i < categories.length && i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Expanded(
                          flex: categories[i].percentage > 0 ? categories[i].percentage : 1,
                          child: Container(
                            color: i == 0
                                ? const Color(0xFF0F5B47)
                                : i == 1
                                    ? const Color(0xFF43B096)
                                    : const Color(0xFFA0E0D2),
                          ),
                        ),
                      ],
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
            ] else if (hasData) ...[
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Chưa có phân loại chi tiêu',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
