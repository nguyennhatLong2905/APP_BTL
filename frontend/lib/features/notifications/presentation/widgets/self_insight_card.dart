import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timeline_provider.dart';

class SelfInsightCard extends ConsumerWidget {
  const SelfInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineProvider);
    final patterns = state.patterns;
    final sampleCount = (patterns?['sampleCount'] as num?)?.toInt() ?? state.totalRated;
    final hasEnoughData = (patterns?['hasEnoughData'] as bool?) ?? (sampleCount >= 5);

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
                  child: Text(
                    hasEnoughData
                        ? 'Dựa trên $sampleCount đánh giá'
                        : '$sampleCount/5 đánh giá',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F5B47),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (sampleCount == 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Color(0xFF757575)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Đánh giá cảm xúc cho các khoản chi tuần này (Đáng tiền, Bình thường, Cân nhắc) để Ví An giúp bạn khám phá thói quen chi tiêu thực tế.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF616161)),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Box 1: Khoản chi tích cực
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
                      child: const Icon(Icons.favorite,
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
                              text: 'Đáng tiền',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F5B47),
                              ),
                            ),
                            TextSpan(text: ') cho các khoản chi thiết yếu & học tập. Đây là vùng đầu tư mang lại bình an lớn nhất.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Box 2: Nhận diện mua ngẫu hứng
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
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
                            TextSpan(text: 'Các khoản mua sắm ngẫu hứng sau 22h đêm thường rơi vào nhóm '),
                            TextSpan(
                              text: 'Muốn cân nhắc lại',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            TextSpan(text: ' sau 7 ngày.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
