import 'package:flutter/material.dart';

class MindfulActionCard extends StatelessWidget {
  final VoidCallback? onAdjustBudget;
  final VoidCallback? onActivateChallenge;

  const MindfulActionCard({
    super.key,
    this.onAdjustBudget,
    this.onActivateChallenge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.eco_outlined, color: Color(0xFF0F5B47), size: 18),
            SizedBox(width: 8),
            Text(
              'Gợi ý hành động chánh niệm',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Action Item 1
        Card(
          elevation: 0,
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC2F0E6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.attach_money,
                          size: 18, color: Color(0xFF0F5B47)),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Tăng ngân sách học tập',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(text: 'Gợi ý bổ sung thêm '),
                      TextSpan(
                        text: '200.000 ₫',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                          text:
                              ' cho chu kỳ tới để tiếp tục nuôi dưỡng thói quen phát triển bản yêu thích.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAdjustBudget,
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text(
                      'Điều chỉnh ngân sách',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5B47),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Action Item 2
        Card(
          elevation: 0,
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.hourglass_bottom,
                          size: 18, color: Colors.orange.shade900),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Thử thách khoảng lặng 48h',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tạm ngừng 48 tiếng trước khi thanh toán các món đồ công nghệ hoặc mua sắm sau 22h để kiểm tra độ thật sự cần thiết.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onActivateChallenge,
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: const Text(
                      'Kích hoạt thử thách',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAF8F5),
                      foregroundColor: const Color(0xFF0F5B47),
                      side: const BorderSide(color: Color(0xFF80D8C3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
