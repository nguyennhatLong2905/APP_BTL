import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CashFlowImpactCard extends StatelessWidget {
  final double currentFreeBalance;
  final double freeBalanceAfter;
  final double itemPrice;
  final double dailyAvgCurrent;
  final double dailyAvgAfter;
  final int daysLeft;

  const CashFlowImpactCard({
    super.key,
    required this.currentFreeBalance,
    required this.freeBalanceAfter,
    required this.itemPrice,
    required this.dailyAvgCurrent,
    required this.dailyAvgAfter,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final itemPriceK = (itemPrice / 1000).toStringAsFixed(0);
    final dailyAvgAfterK = (dailyAvgAfter / 1000).toStringAsFixed(1);
    final dailyAvgCurrentK = (dailyAvgCurrent / 1000).toStringAsFixed(0);

    final flexLeft = (dailyAvgAfter / (dailyAvgCurrent > 0 ? dailyAvgCurrent : 1) * 100).toInt().clamp(1, 99);
    final flexRight = (100 - flexLeft).clamp(1, 99);

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
                  'Tác động dòng tiền',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$daysLeft ngày kế tiếp',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Col 1: Hiện tại
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hiện tại',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tiền còn để chi',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${currencyFormatter.format(currentFreeBalance)} ₫',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bình quân / ngày',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${currencyFormatter.format(dailyAvgCurrent)} ₫',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F5B47),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Col 2: Sau khi mua
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F3EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sau khi mua',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F5B47),
                              ),
                            ),
                            Text(
                              '-${itemPriceK}k',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tiền còn để chi',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${currencyFormatter.format(freeBalanceAfter)} ₫',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bình quân / ngày',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '~${currencyFormatter.format(dailyAvgAfter)} ₫',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.balance, size: 14, color: Colors.brown.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Cần thắt chặt hơn (~${dailyAvgAfterK}k/ngày)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Thoải mái (${dailyAvgCurrentK}k/ngày)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F5B47),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle_outline,
                        size: 14, color: Color(0xFF0F5B47)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    Expanded(
                      flex: flexLeft,
                      child: Container(color: Colors.brown.shade700),
                    ),
                    Expanded(
                      flex: flexRight,
                      child: Container(color: const Color(0xFF80D8C3)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '0 ₫',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  'Hạn mức tự do: ${currencyFormatter.format(currentFreeBalance)} ₫',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
