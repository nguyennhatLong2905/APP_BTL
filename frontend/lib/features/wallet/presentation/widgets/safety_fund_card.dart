import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SafetyFundCard extends StatelessWidget {
  final double fixedBills;
  final double emergencyFund;

  const SafetyFundCard({
    super.key,
    required this.fixedBills,
    required this.emergencyFund,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F6F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F5B47),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Túi an toàn được bảo toàn',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F5B47),
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                    children: [
                      const TextSpan(text: 'Hóa đơn cố định ('),
                      TextSpan(
                        text: '${currencyFormatter.format(fixedBills)} ₫',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ') và Quỹ dự phòng ('),
                      TextSpan(
                        text: '${currencyFormatter.format(emergencyFund)} ₫',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                          text:
                              ') vẫn được giữ riêng an toàn tuyệt đối. Khoản mua này chỉ lấy từ số tiền chi tiêu tự do chu kỳ này của bạn.'),
                    ],
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
