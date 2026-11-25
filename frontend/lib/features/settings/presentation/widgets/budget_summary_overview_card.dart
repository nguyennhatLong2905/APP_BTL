import 'package:flutter/material.dart';

import '../../../../core/ui/finance_screen_style.dart';
import '../providers/budget_provider.dart';

class BudgetSummaryOverviewCard extends StatelessWidget {
  const BudgetSummaryOverviewCard({
    super.key,
    required this.state,
    required this.onPeriodChanged,
  });

  final BudgetState state;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final remaining = state.spendableNow;
    return FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PopupMenuButton<String>(
                enabled: !state.isLoading,
                tooltip: 'Chọn kỳ ngân sách',
                initialValue: state.filterMode,
                onSelected: onPeriodChanged,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'Chu kỳ lương',
                    child: Text('Chu kỳ lương'),
                  ),
                  PopupMenuItem(value: 'Theo tháng', child: Text('Theo tháng')),
                ],
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: FinanceScreenStyle.mint,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.filterMode,
                          style: FinanceScreenStyle.strong,
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state.periodText,
                  style: FinanceScreenStyle.detail,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Còn để chi thực tế',
            style: TextStyle(color: FinanceScreenStyle.ink, fontSize: 15),
          ),
          const SizedBox(height: 3),
          Text(
            FinanceScreenStyle.money(remaining),
            style: FinanceScreenStyle.amount.copyWith(
              color: remaining < 0
                  ? FinanceScreenStyle.danger
                  : FinanceScreenStyle.green,
            ),
          ),
          const SizedBox(height: 6),
          const Divider(color: FinanceScreenStyle.border),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Đã dùng ${FinanceScreenStyle.money(state.totalSpent)} / ${FinanceScreenStyle.money(state.totalBudget)}',
                  style: const TextStyle(
                    color: FinanceScreenStyle.ink,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${state.spentPercentage}%',
                style: FinanceScreenStyle.strong,
              ),
            ],
          ),
          const SizedBox(height: 9),
          FinanceProgress(
            value: state.totalBudget > 0
                ? state.totalSpent / state.totalBudget
                : 0,
            height: 10,
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Hạn mức / ngày',
                  style: TextStyle(color: FinanceScreenStyle.ink),
                ),
              ),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    state.daysLeft > 0
                        ? FinanceScreenStyle.money(state.dailyLimit)
                        : '—',
                    textAlign: TextAlign.end,
                    style: FinanceScreenStyle.strong.copyWith(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
