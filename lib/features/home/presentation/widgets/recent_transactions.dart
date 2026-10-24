import 'package:flutter/material.dart';

/// Section "Giao dịch gần đây" + "Hóa đơn sắp tới"
/// Hiển thị ở phần dưới màn hình Home
class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({super.key});

  static const Color _teal = Color(0xFF2C7873);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUpcomingBills(),
        const SizedBox(height: 8),
        _buildRecentTransactions(context),
      ],
    );
  }

  /// ── Hóa đơn sắp tới ─────────────────────────────────────────────
  Widget _buildUpcomingBills() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
              Text(
                'Trước ngày 16/10',
                style: TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tiền nhà
          _BillItem(
            iconBg: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFFF8F00),
            icon: Icons.home_outlined,
            title: 'Tiền nhà',
            subtitle: 'Hạn 05/10/2026',
            amount: -3000000,
            urgencyBadge: 'Còn 3 ngày',
            badgeColor: const Color(0xFFFF8F00),
          ),

          const SizedBox(height: 10),

          // Điện nước sinh hoạt
          _BillItem(
            iconBg: const Color(0xFFFFFDE7),
            iconColor: const Color(0xFFF9A825),
            icon: Icons.flash_on_outlined,
            title: 'Điện nước sinh hoạt',
            subtitle: 'Hạn 10/10/2026',
            amount: -500000,
          ),
        ],
      ),
    );
  }

  /// ── Giao dịch gần đây ────────────────────────────────────────────
  Widget _buildRecentTransactions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
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
                  color: _textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {},
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

          // Cà phê sáng
          _TransactionItem(
            iconBg: const Color(0xFFEBF6F3),
            icon: Icons.coffee_outlined,
            title: 'Cà phê sáng',
            subtitle: 'Ví tiền mặt • Hôm nay 08:15',
            amount: -45000,
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // Ăn trưa cơm văn phòng
          _TransactionItem(
            iconBg: const Color(0xFFEBF6F3),
            icon: Icons.restaurant_outlined,
            title: 'Ăn trưa cơm văn phòng',
            subtitle: 'Tài khoản • Hôm qua',
            amount: -60000,
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // Đổ xăng
          _TransactionItem(
            iconBg: const Color(0xFFEBF6F3),
            icon: Icons.local_gas_station_outlined,
            title: 'Đổ xăng',
            subtitle: 'Ví tiền mặt • Hôm qua',
            amount: -70000,
          ),
        ],
      ),
    );
  }
}

/// Item hóa đơn đơn lẻ
class _BillItem extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final double amount;
  final String? urgencyBadge;
  final Color? badgeColor;

  const _BillItem({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.urgencyBadge,
    this.badgeColor,
  });

  String _fmt(double v) {
    final str = v.abs().toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return '-${buf.toString()} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),

        // Title + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (urgencyBadge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? Colors.orange)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        urgencyBadge!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: badgeColor ?? Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),

        // Amount
        Text(
          _fmt(amount),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD32F2F),
          ),
        ),
      ],
    );
  }
}

/// Item giao dịch đơn lẻ
class _TransactionItem extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final String title;
  final String subtitle;
  final double amount;

  const _TransactionItem({
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  String _fmt(double v) {
    final str = v.abs().toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    final prefix = v < 0 ? '-' : '+';
    return '$prefix${buf.toString()} đ';
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = amount < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2C7873), size: 20),
          ),
          const SizedBox(width: 12),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            _fmt(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isExpense
                  ? const Color(0xFFD32F2F)
                  : const Color(0xFF2C7873),
            ),
          ),
        ],
      ),
    );
  }
}
