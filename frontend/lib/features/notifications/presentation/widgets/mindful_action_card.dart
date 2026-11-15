import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timeline_provider.dart';

class MindfulActionCard extends ConsumerWidget {
  final VoidCallback? onAdjustBudget;
  final VoidCallback? onActivateChallenge;

  const MindfulActionCard({
    super.key,
    this.onAdjustBudget,
    this.onActivateChallenge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineProvider);
    final hasActiveCooldown = state.hasActiveCooldown;

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

        // Action Item 1: Điều chỉnh ngân sách
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
                      child: const Icon(Icons.tune,
                          size: 18, color: Color(0xFF0F5B47)),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Tối ưu hạn mức ngân sách',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cân đối lại hạn mức giữa các danh mục dựa trên báo cáo tuần qua để chi tiêu thảnh thơi hơn.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.35,
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
                        fontSize: 12.5,
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

        // Action Item 2: Thử thách khoảng lặng 48h
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
                        color: hasActiveCooldown
                            ? const Color(0xFFE8F5E9)
                            : Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasActiveCooldown
                            ? Icons.check_circle_outline
                            : Icons.hourglass_bottom,
                        size: 18,
                        color: hasActiveCooldown
                            ? const Color(0xFF2E7D32)
                            : Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      hasActiveCooldown
                          ? 'Đang bật Khoảng Lặng 48h'
                          : 'Thử thách khoảng lặng 48h',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  hasActiveCooldown
                      ? 'Bạn đang trong khoảng lặng 48 giờ! Hãy cho bản thân thời gian lắng đọng trước khi quyết định mua các món đồ không thật sự cần thiết.'
                      : 'Tạm ngừng 48 tiếng trước khi thanh toán các món đồ công nghệ hoặc mua sắm sau 22h để kiểm tra độ thật sự cần thiết.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: hasActiveCooldown ? null : onActivateChallenge,
                    icon: Icon(
                      hasActiveCooldown
                          ? Icons.check
                          : Icons.flag_outlined,
                      size: 16,
                    ),
                    label: Text(
                      hasActiveCooldown
                          ? 'Thử thách đang kích hoạt'
                          : 'Kích hoạt thử thách 48h',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: hasActiveCooldown
                          ? const Color(0xFFF1F8E9)
                          : const Color(0xFFEAF8F5),
                      foregroundColor: hasActiveCooldown
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF0F5B47),
                      side: BorderSide(
                        color: hasActiveCooldown
                            ? const Color(0xFFA5D6A7)
                            : const Color(0xFF80D8C3),
                      ),
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
