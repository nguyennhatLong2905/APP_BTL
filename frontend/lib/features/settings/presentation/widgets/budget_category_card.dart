import 'package:flutter/material.dart';

import '../../../../core/ui/finance_screen_style.dart';
import '../../domain/models/category_budget.dart';

/// A single category row inside the period's budget card.
class BudgetCategoryCard extends StatelessWidget {
  const BudgetCategoryCard({
    super.key,
    required this.category,
    this.onEditPressed,
    this.onDeletePressed,
  });

  final CategoryBudget category;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final remaining = category.allocatedAmount - category.spentAmount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FinanceCategoryIcon(category.icon),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: Text(
                  category.name,
                  style: FinanceScreenStyle.strong.copyWith(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    FinanceScreenStyle.money(remaining),
                    textAlign: TextAlign.end,
                    style: FinanceScreenStyle.strong.copyWith(
                      fontSize: 15,
                      color: remaining < 0
                          ? FinanceScreenStyle.danger
                          : FinanceScreenStyle.ink,
                    ),
                  ),
                ),
              ),
              if (onEditPressed != null || onDeletePressed != null)
                PopupMenuButton<String>(
                  tooltip: 'Thao tác ngân sách: ${category.name}',
                  icon: const Icon(Icons.more_vert, size: 20),
                  padding: EdgeInsets.zero,
                  onSelected: (action) => action == 'edit'
                      ? onEditPressed?.call()
                      : onDeletePressed?.call(),
                  itemBuilder: (_) => [
                    if (onEditPressed != null)
                      const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                    if (onDeletePressed != null)
                      const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                  ],
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hạn mức ${FinanceScreenStyle.money(category.allocatedAmount)} · Đã chi ${FinanceScreenStyle.money(category.spentAmount)}',
                  style: FinanceScreenStyle.detail,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: FinanceProgress(
                        value: category.percentageSpent,
                        height: 7,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${category.percentageInt}%',
                      style: FinanceScreenStyle.detail,
                    ),
                  ],
                ),
                if (category.isNearLimit || category.isExhausted)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      category.statusLabel,
                      style: FinanceScreenStyle.detail.copyWith(
                        color: FinanceScreenStyle.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
