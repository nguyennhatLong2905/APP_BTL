import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/timeline_item.dart';

class TimelineItemCard extends StatelessWidget {
  final TimelineItem item;

  const TimelineItemCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final timeFormatter = DateFormat('HH:mm');
    final isIncome = item.isIncome;
    final amountColor = isIncome ? Colors.green.shade700 : Colors.red.shade700;
    final amountPrefix = isIncome ? '+' : '-';
    final itemDate = item.dateTime ?? DateTime.now();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: item.categoryColor.withValues(alpha: 0.15),
                  radius: 20,
                  child: Icon(item.categoryIcon, color: item.categoryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            item.categoryName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${timeFormatter.format(itemDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '$amountPrefix${currencyFormatter.format(item.amount)} ₫',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                  ),
                ),
              ],
            ),
            if (item.emotionNote != null || item.note != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (item.emotionNote != null)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.pink.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite, size: 12, color: Colors.pink),
                          const SizedBox(width: 4),
                          Text(
                            item.emotionNote!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.pink.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (item.note != null)
                    Expanded(
                      child: Text(
                        item.note!,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
