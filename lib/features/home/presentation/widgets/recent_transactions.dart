import 'package:flutter/material.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/domain/models/dashboard_data.dart';

/// Widget hiển thị list 5 giao dịch gần nhất
class RecentTransactions extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback? onViewAll;

  const RecentTransactions({
    super.key,
    required this.transactions,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Giao dịch gần đây',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00A86B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Transaction list
        ...transactions.asMap().entries.map(
              (entry) => _TransactionItem(
                transaction: entry.value,
                index: entry.key,
              ),
            ),
      ],
    );
  }
}

class _TransactionItem extends StatefulWidget {
  final Transaction transaction;
  final int index;

  const _TransactionItem({required this.transaction, required this.index});

  @override
  State<_TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<_TransactionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    // Stagger animation dựa vào index
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _iconColor {
    switch (widget.transaction.icon) {
      case TransactionIcon.food:
        return const Color(0xFFFF6B35);
      case TransactionIcon.transport:
        return const Color(0xFF6C63FF);
      case TransactionIcon.shopping:
        return const Color(0xFFFF9F1C);
      case TransactionIcon.health:
        return const Color(0xFFE71D36);
      case TransactionIcon.entertainment:
        return const Color(0xFF8B5CF6);
      case TransactionIcon.salary:
        return const Color(0xFF2EC4B6);
      case TransactionIcon.transfer:
        return const Color(0xFF00A86B);
      case TransactionIcon.other:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData get _iconData {
    switch (widget.transaction.icon) {
      case TransactionIcon.food:
        return Icons.restaurant_rounded;
      case TransactionIcon.transport:
        return Icons.directions_car_rounded;
      case TransactionIcon.shopping:
        return Icons.shopping_bag_rounded;
      case TransactionIcon.health:
        return Icons.local_hospital_rounded;
      case TransactionIcon.entertainment:
        return Icons.movie_rounded;
      case TransactionIcon.salary:
        return Icons.account_balance_wallet_rounded;
      case TransactionIcon.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionIcon.other:
        return Icons.more_horiz_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua';
    return '${date.day}/${date.month}';
  }

  String _formatAmount(double amount) {
    final sign = amount >= 0 ? '+' : '-';
    final abs = amount.abs();
    final formatted = abs
        .toInt()
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.');
    return '$sign$formatted ₫';
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction.isIncome;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconData, color: _iconColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Title + Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.transaction.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          widget.transaction.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '·',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(widget.transaction.date),
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

              // Amount
              Text(
                _formatAmount(widget.transaction.amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isIncome
                      ? const Color(0xFF2EC4B6)
                      : const Color(0xFFE71D36),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
