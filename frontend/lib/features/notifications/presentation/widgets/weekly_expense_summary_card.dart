import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/review_analytics.dart';

final _money = NumberFormat('#,###', 'vi_VN');

/// Card "Tổng chi tuần qua".
///
/// Số liệu 100% từ `WeekStats` (backend tính từ giao dịch thật). Biểu đồ là
/// thanh phân đoạn theo tỷ lệ thật; nhấn một nhóm để mở danh sách giao dịch
/// của danh mục đó (drill-down).
class WeeklyExpenseSummaryCard extends StatelessWidget {
  final WeekStats week;
  final void Function(WeekCategory category)? onTapCategory;

  const WeeklyExpenseSummaryCard({
    super.key,
    required this.week,
    this.onTapCategory,
  });

  static const _palette = [
    Color(0xFF0F5B47),
    Color(0xFF43B096),
    Color(0xFF7CCDB9),
    Color(0xFFA0E0D2),
    Color(0xFFC2F0E6),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentWeek = week.startAt != null &&
        week.endAt != null &&
        !now.isBefore(week.startAt!) &&
        now.isBefore(week.endAt!);

    final isUp = week.trend == 'up';
    final changeColor = isUp ? const Color(0xFFB91C1C) : const Color(0xFF0F5B47);
    final changeBg =
        isUp ? const Color(0xFFFEE2E2) : const Color(0xFFC2F0E6);

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
                Text(
                  isCurrentWeek ? 'TỔNG CHI TUẦN NÀY' : 'TỔNG CHI TRONG TUẦN',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.black54,
                  ),
                ),
                if (week.expenseChangePercent != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: changeBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUp ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: changeColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          week.changeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: changeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${_money.format(week.expense)} ₫',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),

            if (!week.hasData)
              Text(
                isCurrentWeek
                    ? 'Chưa có giao dịch chi trong tuần này. Chọn "Đổi tuần" ở trên để xem các tuần trước.'
                    : 'Chưa có giao dịch chi trong tuần được chọn.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
              )
            else ...[
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                  children: [
                    TextSpan(
                      text: isCurrentWeek ? 'Tuần trước đã chi ' : 'Tuần trước đó đã chi ',
                    ),
                    TextSpan(
                      text: '${_money.format(week.previousExpense)} ₫',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: week.expenseChangePercent == null
                          ? '.'
                          : isUp
                              ? '. Chú ý nhịp chi tiêu tăng nhé.'
                              : '. Bạn đang giữ nhịp chi tiêu dịu êm.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Biểu đồ cơ cấu thật theo % từng danh mục.
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      for (var i = 0; i < week.categories.length; i++) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Expanded(
                          flex: (week.categories[i].percent ?? 0) < 1
                              ? 1
                              : week.categories[i].percent!,
                          child: Container(
                            color: _palette[i % _palette.length],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              for (var i = 0; i < week.categories.length; i++)
                _CategoryRow(
                  category: week.categories[i],
                  color: _palette[i % _palette.length],
                  onTap: onTapCategory == null
                      ? null
                      : () => onTapCategory!(week.categories[i]),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final WeekCategory category;
  final Color color;
  final VoidCallback? onTap;

  const _CategoryRow({
    required this.category,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      category.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F6F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${category.count} GD',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F5B47),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${_money.format(category.amount)} ₫ ',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '(${category.percent ?? 0}%)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade500),
            ],
          ],
        ),
      ),
    );
  }
}
