import 'package:flutter/material.dart';

import '../../domain/models/review_analytics.dart';

/// Card "Thấu hiểu bản thân".
///
/// Mọi nhận xét đến từ `SelfInsight.statements`, mỗi câu kèm tỷ lệ + số mẫu
/// và nút xem căn cứ (các giao dịch thật). Nếu chưa đủ mẫu, hiển thị tiến độ
/// thay vì kết luận.
class SelfInsightCard extends StatelessWidget {
  final SelfInsight insight;
  final void Function(InsightStatement statement)? onShowEvidence;
  final VoidCallback? onViewHistory;

  const SelfInsightCard({
    super.key,
    required this.insight,
    this.onShowEvidence,
    this.onViewHistory,
  });

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
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF0D5B47),
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Thấu hiểu bản thân',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F6F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Dựa trên ${insight.sampleCount} đánh giá',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F5B47),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!insight.hasEnoughData)
              _NotEnoughData(insight: insight)
            else
              for (final s in insight.statements) ...[
                _StatementBox(
                  statement: s,
                  onShowEvidence: onShowEvidence == null
                      ? null
                      : () => onShowEvidence!(s),
                ),
                const SizedBox(height: 10),
              ],

            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: onViewHistory,
                icon: const Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: Color(0xFF0F5B47),
                ),
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

class _NotEnoughData extends StatelessWidget {
  final SelfInsight insight;

  const _NotEnoughData({required this.insight});

  @override
  Widget build(BuildContext context) {
    final remaining = (insight.minimumSamples - insight.sampleCount).clamp(
      0,
      insight.minimumSamples,
    );
    final progress = insight.minimumSamples == 0
        ? 0.0
        : (insight.sampleCount / insight.minimumSamples).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.sampleCount == 0
                ? 'Chưa có đánh giá nào. Hãy theo dõi vài khoản chi rồi đánh giá sau 7 ngày để Ví An hiểu bạn hơn.'
                : 'Cần thêm $remaining đánh giá nữa để có nhận xét đáng tin cậy.',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFD3EFE8),
              color: const Color(0xFF0F5B47),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${insight.sampleCount}/${insight.minimumSamples} đánh giá tối thiểu',
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _StatementBox extends StatelessWidget {
  final InsightStatement statement;
  final VoidCallback? onShowEvidence;

  const _StatementBox({required this.statement, this.onShowEvidence});

  @override
  Widget build(BuildContext context) {
    final positive = statement.isPositive;
    final accent = positive ? const Color(0xFF0F5B47) : Colors.orange.shade900;
    final bg = positive ? const Color(0xFFEAF8F5) : Colors.orange.shade50;

    // Câu nhận xét đã có sẵn nội dung; chèn tỷ lệ + số mẫu làm căn cứ.
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: positive
                      ? const Color(0xFFC2F0E6)
                      : Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  positive ? Icons.favorite_border : Icons.nightlight_round,
                  size: 14,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(text: statement.text),
                      TextSpan(
                        text:
                            ' ${statement.count}/${statement.sampleCount} mẫu (${statement.percent}%).',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (onShowEvidence != null &&
              statement.evidenceTransactionIds.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onShowEvidence,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 26),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Xem ${statement.evidenceTransactionIds.length} giao dịch căn cứ',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
