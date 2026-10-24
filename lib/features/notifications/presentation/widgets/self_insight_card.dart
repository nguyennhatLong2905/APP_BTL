import 'package:flutter/material.dart';

class SelfInsightCard extends StatelessWidget {
  const SelfInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: Color(0xFF0F5B47), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Thấu hiểu bản thân',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F6F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Dựa trên 12 đánh giá',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F5B47),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Box 1
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFC2F0E6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on,
                        size: 14, color: Color(0xFF0F5B47)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(text: 'Bạn thường đánh giá rất cao ('),
                          TextSpan(
                            text: '90% Đáng tiền',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F5B47),
                            ),
                          ),
                          TextSpan(text: ') cho các khoản chi về '),
                          TextSpan(
                            text: 'Học tập & Sức khỏe',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                              text:
                                  '. Đây là vùng đầu tư mang lại bình an lớn nhất.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Box 2
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.nightlight_round,
                        size: 14, color: Colors.orange.shade900),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(text: 'Khoản mua sắm ngẫu hứng sau 22h đêm có '),
                          TextSpan(
                            text: '66%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          TextSpan(text: ' rơi vào nhóm '),
                          TextSpan(
                            text: 'Muốn cân nhắc lại',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' sau 7 ngày.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Link action
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility_outlined,
                    size: 16, color: Color(0xFF0F5B47)),
                label: const Text(
                  'Xem chi tiết các nhật ký giao dịch đã đánh giá',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F5B47),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
