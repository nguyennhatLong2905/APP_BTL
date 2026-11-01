import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/providers/home_provider.dart';

/// Card hiển thị "Còn để chi đến ngày lương"
/// Khớp hoàn toàn với thiết kế Figma
class BalanceCard extends ConsumerWidget {
  /// Số tiền còn lại để chi (VD: 2.100.000)
  final double remainingAmount;

  /// Số tiền chi trung bình mỗi ngày (VD: 150.000)
  final double dailyRate;

  /// Số ngày còn lại đến ngày lương (VD: 14)
  final int daysLeft;

  /// Ngày nhận lương (VD: 16/10)
  final String nextPaydayLabel;

  /// Tỷ lệ tiến độ chu kỳ lương (0–100)
  final double progressPercent;

  /// Ngày bắt đầu chu kỳ (VD: 16/09)
  final String startDateLabel;

  const BalanceCard({
    super.key,
    required this.remainingAmount,
    required this.dailyRate,
    required this.daysLeft,
    required this.nextPaydayLabel,
    required this.progressPercent,
    required this.startDateLabel,
  });

  static const Color _teal = Color(0xFF2C7873);
  static const Color _tealBg = Color(0xFFEBF6F3);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF757575);

  String _fmt(double amount) {
    final str = amount.abs().toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return '${buf.toString()} đ';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _tealBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: label + Cách tính ─────────────────────────
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _teal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'CÒN ĐỂ CHI ĐẾN NGÀY LƯƠNG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  children: [
                    Icon(Icons.format_list_bulleted,
                        size: 13, color: _teal),
                    SizedBox(width: 3),
                    Text(
                      'Cách tính',
                      style: TextStyle(
                        color: _teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Số tiền còn lại ──────────────────────────────────
          Text(
            homeState.balanceVisible ? _fmt(remainingAmount) : '••••••• đ',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: _teal,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 10),

          // ── Thông tin trung bình/ngày ────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textSecondary,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'Khoảng '),
                      TextSpan(
                        text: _fmt(dailyRate),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      TextSpan(
                        text:
                            '/ngày đến $nextPaydayLabel (còn $daysLeft ngày)',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Tiến độ chu kỳ lương ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tiến độ chu kỳ lương',
                style: TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
              Text(
                '${progressPercent.toInt()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _teal,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              valueColor: const AlwaysStoppedAnimation<Color>(_teal),
            ),
          ),

          const SizedBox(height: 6),

          // ── Ngày bắt đầu / Ngày lương ───────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bắt đầu: $startDateLabel',
                style: const TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
              Text(
                'Ngày lương: $nextPaydayLabel',
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
}
