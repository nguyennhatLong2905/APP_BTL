import 'package:flutter/material.dart';

import '../../../../core/ui/finance_screen_style.dart';
import '../../domain/models/review_analytics.dart';
import '../providers/timeline_provider.dart';

class WeeklyReviewCard extends StatelessWidget {
  const WeeklyReviewCard({
    super.key,
    required this.state,
    required this.onSelectWeek,
    required this.onTapCategory,
  });

  final TimelineState state;
  final ValueChanged<ReviewWeek> onSelectWeek;
  final ValueChanged<WeekCategory> onTapCategory;

  static const _palette = [
    FinanceScreenStyle.green,
    Color(0xFF94D9C8),
    Color(0xFF2D8E79),
    Color(0xFFC6E8C4),
    Color(0xFF578F55),
    Color(0xFFE0C788),
  ];

  @override
  Widget build(BuildContext context) {
    final week = state.week;
    final categories = week.categories
        .where((category) => category.amount > 0)
        .toList();
    final categoryTotal = categories.fold<double>(
      0,
      (sum, category) => sum + category.amount,
    );
    final change = week.expenseChangePercent;
    final isIncrease = week.trend == 'up';
    return FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.weekLabel,
                  style: FinanceScreenStyle.strong.copyWith(fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<ReviewWeek>(
                enabled: !state.isLoading && state.weeks.isNotEmpty,
                tooltip: 'Đổi tuần',
                onSelected: onSelectWeek,
                itemBuilder: (_) => [
                  for (final choice in state.weeks)
                    CheckedPopupMenuItem(
                      value: choice,
                      checked: choice.startAt.isAtSameMomentAs(
                        week.startAt ?? choice.endAt,
                      ),
                      child: Text(choice.label),
                    ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: FinanceScreenStyle.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 17,
                        color: FinanceScreenStyle.green,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Đổi tuần',
                        style: FinanceScreenStyle.strong.copyWith(
                          color: FinanceScreenStyle.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (state.isLoading) ...[
            const SizedBox(height: 6),
            const LinearProgressIndicator(color: FinanceScreenStyle.green),
          ],
          const SizedBox(height: 10),
          const Text(
            'Tổng chi trong tuần',
            style: TextStyle(color: FinanceScreenStyle.ink, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  FinanceScreenStyle.money(week.expense),
                  style: FinanceScreenStyle.amount,
                ),
              ),
              if (change != null) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 128),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isIncrease
                          ? const Color(0xFFFCEAEC)
                          : FinanceScreenStyle.mint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isIncrease
                              ? Icons.arrow_upward
                              : week.trend == 'down'
                              ? Icons.arrow_downward
                              : Icons.remove,
                          color: isIncrease
                              ? FinanceScreenStyle.danger
                              : FinanceScreenStyle.green,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            week.changeLabel,
                            textAlign: TextAlign.center,
                            style: FinanceScreenStyle.strong.copyWith(
                              color: isIncrease
                                  ? FinanceScreenStyle.danger
                                  : FinanceScreenStyle.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Text.rich(
            TextSpan(
              text: 'Tuần trước ',
              children: [
                TextSpan(
                  text: FinanceScreenStyle.money(week.previousExpense),
                  style: FinanceScreenStyle.strong.copyWith(
                    color: FinanceScreenStyle.green,
                  ),
                ),
              ],
            ),
            style: const TextStyle(color: FinanceScreenStyle.ink),
          ),
          const SizedBox(height: 14),
          if (week.expense <= 0)
            const Text(
              'Tuần này chưa có giao dịch chi tiêu.',
              style: FinanceScreenStyle.detail,
            )
          else if (categories.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < categories.length; i++)
                      Expanded(
                        flex: (categories[i].amount / categoryTotal * 100000)
                            .round()
                            .clamp(1, 100000),
                        child: ColoredBox(color: _palette[i % _palette.length]),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < categories.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: FinanceScreenStyle.border),
              _CategoryLegend(
                category: categories[i],
                color: _palette[i % _palette.length],
                percent:
                    categories[i].percent ??
                    (categories[i].amount / categoryTotal * 100).round(),
                onTap: () => onTapCategory(categories[i]),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({
    required this.category,
    required this.color,
    required this.percent,
    required this.onTap,
  });

  final WeekCategory category;
  final Color color;
  final int percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
            flex: 5,
            child: Text(category.name, style: FinanceScreenStyle.strong),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 5,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${FinanceScreenStyle.money(category.amount)} · $percent%',
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: FinanceScreenStyle.ink,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
