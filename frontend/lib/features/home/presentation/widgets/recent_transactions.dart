import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/models/dashboard_data.dart';
import '../providers/home_provider.dart';

/// Section "Hóa đơn sắp tới" + "Giao dịch gần đây" — lấy dữ liệu thật
/// từ homeProvider (/dashboard).
class RecentTransactionsSection extends ConsumerWidget {
  const RecentTransactionsSection({super.key});

  static const Color _teal = Color(0xFF2C7873);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    final data = state.dashboardData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUpcomingBills(data?.upcomingBills ?? const []),
        const SizedBox(height: 16),
        _buildRecentTransactions(context, data, state.isLoading),
      ],
    );
  }

  // ── Hóa đơn sắp tới ────────────────────────────────────────────────
  Widget _buildUpcomingBills(List<UpcomingBill> bills) {
    if (bills.isEmpty) return const SizedBox.shrink();

    final nextDue = bills.first.dueAt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hóa đơn sắp tới',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              if (nextDue != null)
                Text(
                  'Trước ngày ${DateFormat('dd/MM').format(nextDue)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < bills.length; i++) ...[
            _BillItem(bill: bills[i]),
            if (i < bills.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  // ── Giao dịch gần đây ──────────────────────────────────────────────
  Widget _buildRecentTransactions(
    BuildContext context,
    DashboardData? data,
    bool isLoading,
  ) {
    final txns = data?.recentTransactions ?? const <Transaction>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Giao dịch gần đây',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppConstants.reportRoute),
                child: const Row(
                  children: [
                    Text(
                      'Xem tất cả',
                      style: TextStyle(
                        color: _teal,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: _teal, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (txns.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 32, color: Color(0xFFBDBDBD)),
                  const SizedBox(height: 8),
                  Text(
                    isLoading
                        ? 'Đang tải giao dịch...'
                        : 'Chưa có giao dịch nào',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            for (int i = 0; i < txns.length; i++) ...[
              _TransactionItem(transaction: txns[i]),
              if (i < txns.length - 1)
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
            ],
        ],
      ),
    );
  }

  /// Format số tiền: 1.234.567 đ
  static String formatAmount(double v) {
    final str = v.abs().toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return '${buf.toString()} đ';
  }
}

/// Item hóa đơn sắp tới
class _BillItem extends StatelessWidget {
  final UpcomingBill bill;

  const _BillItem({required this.bill});

  static const Color _expense = Color(0xFFD32F2F);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    final days = bill.daysLeft;
    final showBadge = days != null && days <= 3;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.home_outlined,
            color: Color(0xFFFF8F00),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      bill.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  if (showBadge) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8F00).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        days == 0 ? 'Hôm nay' : 'Còn $days ngày',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF8F00),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                bill.dueAt == null
                    ? 'Chưa rõ hạn'
                    : 'Hạn ${DateFormat('dd/MM/yyyy').format(bill.dueAt!)}',
                style: const TextStyle(fontSize: 12, color: _textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '-${RecentTransactionsSection.formatAmount(bill.amount)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _expense,
          ),
        ),
      ],
    );
  }
}

/// Item giao dịch đơn lẻ — dựng từ model thật
class _TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const _TransactionItem({required this.transaction});

  static const Color _teal = Color(0xFF2C7873);
  static const Color _expense = Color(0xFFD32F2F);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF9E9E9E);

  IconData get _icon {
    switch (transaction.icon) {
      case TransactionIcon.food:
        return Icons.restaurant_outlined;
      case TransactionIcon.transport:
        return Icons.local_gas_station_outlined;
      case TransactionIcon.shopping:
        return Icons.shopping_bag_outlined;
      case TransactionIcon.health:
        return Icons.favorite_outline;
      case TransactionIcon.entertainment:
        return Icons.movie_outlined;
      case TransactionIcon.salary:
        return Icons.attach_money;
      case TransactionIcon.transfer:
        return Icons.swap_horiz;
      case TransactionIcon.other:
        return Icons.receipt_long_outlined;
    }
  }

  /// "Hôm nay 08:15" | "Hôm qua" | "12/11"
  String get _timeLabel {
    final d = transaction.date;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final hm =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (day == today) return 'Hôm nay $hm';
    if (day == today.subtract(const Duration(days: 1))) return 'Hôm qua';
    return DateFormat('dd/MM').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.amount < 0;
    final sign = isExpense ? '-' : '+';
    final amountText =
        '$sign${RecentTransactionsSection.formatAmount(transaction.amount)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF6F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _teal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${transaction.category} • $_timeLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isExpense ? _expense : _teal,
            ),
          ),
        ],
      ),
    );
  }
}
