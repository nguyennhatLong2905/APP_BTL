import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/category_budget.dart';

class BudgetCategoryCard extends StatelessWidget {
  final CategoryBudget category;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;

  const BudgetCategoryCard({
    super.key,
    required this.category,
    this.onEditPressed,
    this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final isNearLimit = category.isNearLimit;
    final isOver = category.isOverBudget;
    final isExhausted = category.isExhausted;
    final percentageInt = category.percentageInt;

    // Màu theo trạng thái: bình thường → sắp hết → hết/vượt hạn mức.
    final progressColor = isOver
        ? const Color(0xFFDC2626)
        : isExhausted || isNearLimit
            ? Colors.brown.shade700
            : const Color(0xFF0F5B47);
    final percentTextColor = isOver
        ? const Color(0xFFDC2626)
        : isNearLimit || isExhausted
            ? Colors.brown.shade800
            : Colors.black87;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOver
                        ? const Color(0xFFFEE2E2)
                        : isNearLimit || isExhausted
                            ? Colors.orange.shade100
                            : category.iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    color: isOver
                        ? const Color(0xFFDC2626)
                        : isNearLimit || isExhausted
                            ? Colors.brown.shade800
                            : const Color(0xFF0F5B47),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hạn mức ${currencyFormatter.format(category.allocatedAmount)} ₫ • '
                        'Đã chi ${currencyFormatter.format(category.spentAmount)} ₫',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isOver
                              ? '-${currencyFormatter.format(category.overAmount)} ₫'
                              : '${currencyFormatter.format(category.remainingAmount)} ₫',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: percentTextColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onEditPressed,
                          color: Colors.grey.shade600,
                          tooltip: 'Sửa hạn mức',
                        ),
                        if (onDeletePressed != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: onDeletePressed,
                            color: Colors.red.shade400,
                            tooltip: 'Xóa ngân sách',
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '$percentageInt%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: percentTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar: đầy 100% khi vượt hạn mức, đổi màu theo trạng thái.
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (category.percentageSpent).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFFEAF8F5),
                color: progressColor,
              ),
            ),
            const SizedBox(height: 8),

            // Dòng còn lại / vượt hạn mức + trạng thái.
            Row(
              children: [
                Expanded(
                  child: Text(
                    isOver
                        ? 'Vượt hạn mức ${currencyFormatter.format(category.overAmount)} ₫'
                        : isExhausted
                            ? 'Đã dùng hết hạn mức'
                            : 'Còn lại ${currencyFormatter.format(category.remainingAmount)} ₫',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: percentTextColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOver
                        ? const Color(0xFFFEE2E2)
                        : isExhausted || isNearLimit
                            ? Colors.orange.shade50
                            : const Color(0xFFEAF8F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: percentTextColor,
                    ),
                  ),
                ),
              ],
            ),

            // Warning Box if any
            if (category.warningMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isOver ? const Color(0xFFFEF2F2) : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isOver
                        ? const Color(0xFFFECACA)
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOver ? Icons.error_outline : Icons.info_outline,
                      size: 14,
                      color: isOver
                          ? const Color(0xFFDC2626)
                          : Colors.brown.shade800,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        category.warningMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isOver
                              ? const Color(0xFF991B1B)
                              : Colors.brown.shade900,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onEditPressed,
                      child: Text(
                        'Điều chỉnh...',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                          decoration: TextDecoration.underline,
                        ),
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
