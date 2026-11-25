import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/models/dashboard_data.dart';
import 'home_style.dart';

class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({
    super.key,
    required this.data,
    required this.visible,
  });

  final DashboardData data;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final bills = data.upcomingBills;
    // The dashboard already sorts transactions by occurrence date, newest first.
    final transactions = data.recentTransactions.take(2).toList();
    final dateFormat = DateFormat('dd/MM');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hóa đơn sắp tới', style: HomeStyle.heading),
        const SizedBox(height: 4),
        if (bills.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Chưa có hóa đơn sắp tới', style: HomeStyle.detail),
          ),
        for (var i = 0; i < bills.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: HomeStyle.outline),
          _ActivityRow(
            icon: _billIcon(bills[i].name),
            title: bills[i].name,
            detail: bills[i].dueAt == null
                ? 'Chưa rõ hạn'
                : 'Hạn ${dateFormat.format(bills[i].dueAt!)}',
            amount: HomeStyle.money(bills[i].amount, visible: visible),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text('Giao dịch gần đây', style: HomeStyle.heading),
            ),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go(AppConstants.reportRoute),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.only(left: 8),
                    foregroundColor: HomeStyle.primary,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text('Xem tất cả', textAlign: TextAlign.end),
                      ),
                      Icon(Icons.chevron_right, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('Chưa có giao dịch nào', style: HomeStyle.detail),
          ),
        for (var i = 0; i < transactions.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: HomeStyle.outline),
          _ActivityRow(
            icon: _transactionIcon(transactions[i].icon),
            title: transactions[i].title,
            detail:
                '${transactions[i].category} · ${dateFormat.format(transactions[i].date)}',
            amount: HomeStyle.money(
              transactions[i].amount,
              visible: visible,
              credit: transactions[i].showsCreditSign,
            ),
          ),
        ],
      ],
    );
  }

  IconData _billIcon(String name) {
    final label = name.toLowerCase();
    if (label.contains('nước')) return Icons.water_drop_outlined;
    if (label.contains('điện')) return Icons.bolt_outlined;
    if (label.contains('nhà')) return Icons.home_outlined;
    return Icons.receipt_long_outlined;
  }

  IconData _transactionIcon(TransactionIcon icon) => switch (icon) {
    TransactionIcon.food => Icons.restaurant_outlined,
    TransactionIcon.transport => Icons.local_gas_station_outlined,
    TransactionIcon.shopping => Icons.shopping_bag_outlined,
    TransactionIcon.health => Icons.favorite_outline,
    TransactionIcon.entertainment => Icons.movie_outlined,
    TransactionIcon.salary => Icons.attach_money,
    TransactionIcon.transfer => Icons.swap_horiz,
    TransactionIcon.other => Icons.receipt_long_outlined,
  };
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.amount,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String amount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: HomeLabelRow(
      leading: HomeIcon(icon),
      title: Text(title, style: HomeStyle.label),
      detail: Text(detail, style: HomeStyle.detail),
      trailing: Text(amount, textAlign: TextAlign.end, style: HomeStyle.label),
    ),
  );
}
