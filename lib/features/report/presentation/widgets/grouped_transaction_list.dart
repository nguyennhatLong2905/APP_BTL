import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/report_data.dart';
import '../providers/report_provider.dart';

// ════════════════════════════════════════════════════════════════════
// Widget: Period Selector (Tháng 10/2026 | Tuần này | Hôm nay)
// ════════════════════════════════════════════════════════════════════

class PeriodSelectorWidget extends ConsumerWidget {
  const PeriodSelectorWidget({super.key});

  static const _teal = Color(0xFF1A6B5A);
  static const _tealLight = Color(0xFFD1EDE7);
  static const _bg = Color(0xFFF5F5F5);
  static const _textDark = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportProvider);
    final notifier = ref.read(reportProvider.notifier);
    final now = DateTime.now();

    return Row(
      children: [
        // ── Nút tháng (có icon calendar + text dynamic) ─────────────
        _PeriodChip(
          label:
              state.selectedPeriod == PeriodFilter.month
                  ? 'Tháng ${now.month}/${now.year}'
                  : 'Tháng ${now.month}/${now.year}',
          icon: Icons.calendar_month_rounded,
          isActive: state.selectedPeriod == PeriodFilter.month,
          activeColor: _teal,
          activeTextColor: Colors.white,
          inactiveColor: _bg,
          inactiveTextColor: _textDark,
          onTap: () => notifier.setPeriod(PeriodFilter.month),
        ),
        const SizedBox(width: 8),
        _PeriodChip(
          label: 'Tuần này',
          isActive: state.selectedPeriod == PeriodFilter.week,
          activeColor: _teal,
          activeTextColor: Colors.white,
          inactiveColor: _bg,
          inactiveTextColor: _textDark,
          onTap: () => notifier.setPeriod(PeriodFilter.week),
        ),
        const SizedBox(width: 8),
        _PeriodChip(
          label: 'Hôm nay',
          isActive: state.selectedPeriod == PeriodFilter.today,
          activeColor: _teal,
          activeTextColor: Colors.white,
          inactiveColor: _bg,
          inactiveTextColor: _textDark,
          onTap: () => notifier.setPeriod(PeriodFilter.today),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final Color activeColor;
  final Color activeTextColor;
  final Color inactiveColor;
  final Color inactiveTextColor;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    this.icon,
    required this.isActive,
    required this.activeColor,
    required this.activeTextColor,
    required this.inactiveColor,
    required this.inactiveTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isActive ? activeTextColor : inactiveTextColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeTextColor : inactiveTextColor,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Widget: Wallet Filter chips (Tất cả ví | Ví tiền mặt | ...)
// ════════════════════════════════════════════════════════════════════

class WalletFilterWidget extends ConsumerWidget {
  const WalletFilterWidget({super.key});

  static const _teal = Color(0xFF1A6B5A);
  static const _bg = Color(0xFFF5F5F5);
  static const _textDark = Color(0xFF1A1A1A);

  static const _wallets = ['Tất cả ví', 'Ví tiền mặt', 'Tài khoản', 'Ăn uống'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportProvider);
    final notifier = ref.read(reportProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _wallets
            .map((w) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _WalletChip(
                    label: w,
                    isActive: state.selectedWallet == w,
                    activeColor: _teal,
                    inactiveColor: _bg,
                    textColor: state.selectedWallet == w ? Colors.white : _textDark,
                    onTap: () => notifier.setWallet(w),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final Color textColor;
  final VoidCallback onTap;

  const _WalletChip({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFFDDDDDD),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Widget: Grouped Transaction List
// ════════════════════════════════════════════════════════════════════

class GroupedTransactionList extends ConsumerWidget {
  const GroupedTransactionList({super.key});

  static const _teal = Color(0xFF1A6B5A);
  static const _tealBg = Color(0xFFE8F5F1);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF6B7280);
  static const _income = Color(0xFF1A6B5A);
  static const _expense = Color(0xFFD32F2F);
  static const _transfer = Color(0xFF1565C0);
  static const _cardBg = Color(0xFFF8FFFE);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(reportProvider.notifier);
    final groups = notifier.dailyGroups;

    if (groups.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      children: [
        ...groups.map((group) => _buildDayGroup(context, group)),
        const SizedBox(height: 8),
        _buildInsightCard(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFFBDBDBD)),
            SizedBox(height: 12),
            Text(
              'Không có giao dịch nào',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayGroup(BuildContext context, DailyGroup group) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final dateLabel = _formatDateLabel(group.date);

    // Xác định label tổng: nếu có income → "Dòng tiền", nếu chỉ expense → "Tổng chi"
    final hasIncome = group.totalIncome > 0;
    final hasExpense = group.totalExpense > 0;
    final summaryLabel = hasIncome && !hasExpense
        ? 'Dòng tiền:'
        : hasExpense && !hasIncome
            ? 'Tổng chi:'
            : 'Dòng tiền:';
    final summaryAmount = hasIncome && !hasExpense
        ? '+${formatter.format(group.totalIncome.toInt())} đ'
        : hasExpense && !hasIncome
            ? '-${formatter.format(group.totalExpense.toInt())} đ'
            : group.netFlow >= 0
                ? '+${formatter.format(group.netFlow.toInt())} đ'
                : '-${formatter.format(group.netFlow.abs().toInt())} đ';
    final summaryColor =
        group.netFlow >= 0 ? _income : _expense;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _teal,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                // Date
                Expanded(
                  child: Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ),
                // Summary
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      summaryLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                      ),
                    ),
                    Text(
                      summaryAmount,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: summaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Transaction cards ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8F5F1), width: 1),
              ),
              child: Column(
                children: group.transactions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final tx = entry.value;
                  return Column(
                    children: [
                      _TransactionItem(transaction: tx),
                      if (i < group.transactions.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Color(0xFFE8F5F1),
                          indent: 56,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) {
      return 'Hôm nay –\n${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } else if (d == yesterday) {
      return 'Hôm qua –\n${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildInsightCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5F1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1A6B5A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Text
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khoảng lặng tài chính',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Bạn đã kiểm soát tốt các khoản chi lẻ hôm nay. Hãy duy trì thói quen ghi nhận đều đặn nhé!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Widget: Single Transaction Item
// ════════════════════════════════════════════════════════════════════

class _TransactionItem extends StatelessWidget {
  final ReportTransaction transaction;

  const _TransactionItem({required this.transaction});

  static const _teal = Color(0xFF1A6B5A);
  static const _tealBg = Color(0xFFE8F5F1);
  static const _income = Color(0xFF1A6B5A);
  static const _expense = Color(0xFFD32F2F);
  static const _expenseBadgeBg = Color(0xFFFFEBEE);
  static const _incomeBadgeBg = Color(0xFFE8F5F1);
  static const _transferBg = Color(0xFFE3F2FD);
  static const _transferColor = Color(0xFF1565C0);
  static const _textPrimary = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final isExpense = transaction.type == TransactionType.expense;
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;

    // Icon background color
    Color iconBg;
    Color iconColor;
    if (isExpense) {
      iconBg = _tealBg;
      iconColor = _teal;
    } else if (isIncome) {
      iconBg = const Color(0xFFE8F5F1);
      iconColor = _income;
    } else {
      iconBg = _transferBg;
      iconColor = _transferColor;
    }

    // Amount
    final amountStr = isIncome
        ? '+${formatter.format(transaction.amount.toInt())} đ'
        : isTransfer
            ? '↔ ${formatter.format(transaction.amount.abs().toInt())} đ'
            : '-${formatter.format(transaction.amount.abs().toInt())} đ';

    final amountColor = isIncome
        ? _income
        : isTransfer
            ? _transferColor
            : _expense;

    // Badge
    Color badgeBg;
    Color badgeText;
    if (isExpense) {
      badgeBg = _expenseBadgeBg;
      badgeText = _expense;
    } else if (isIncome) {
      badgeBg = _incomeBadgeBg;
      badgeText = _income;
    } else {
      badgeBg = _transferBg;
      badgeText = _transferColor;
    }

    // Wallet sub-label
    final walletShort = isTransfer ? 'Điều chuyển' : transaction.walletLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // ── Icon ──────────────────────────────────────────────────
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                transaction.categoryIcon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── Title + time + badge ───────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        transaction.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        transaction.typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatTime(transaction.dateTime)} • ${transaction.walletLabel}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Amount ────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountStr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                walletShort,
                style: const TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
