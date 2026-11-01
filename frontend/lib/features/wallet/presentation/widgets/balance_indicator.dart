import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/wallet_balance.dart';

class BalanceIndicator extends StatelessWidget {
  final WalletBalance balance;

  const BalanceIndicator({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A86B), Color(0xFF028A58)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A86B).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Số Dư Ví Hiện Tại',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Ví An',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${currencyFormatter.format(balance.currentBalance)} ₫',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSubStat(
                  'Ngân sách tháng',
                  '${currencyFormatter.format(balance.monthlyBudget)} ₫',
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.white24,
                ),
                _buildSubStat(
                  'Đã chi tiêu',
                  '${currencyFormatter.format(balance.monthlySpent)} ₫',
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.white24,
                ),
                _buildSubStat(
                  'Còn lại',
                  '${currencyFormatter.format(balance.remainingBudget)} ₫',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
