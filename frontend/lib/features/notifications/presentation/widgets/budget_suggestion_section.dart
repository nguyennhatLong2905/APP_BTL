import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/review_analytics.dart';

final _money = NumberFormat('#,###', 'vi_VN');

/// Khu vực "Gợi ý ngân sách".
///
/// Mỗi gợi ý có lý do, căn cứ (số giao dịch), hạn mức hiện tại & đề xuất,
/// nút "Xem tác động" và "Xác nhận"/"Bỏ qua". KHÔNG tự áp dụng: xác nhận sẽ
/// gọi API riêng (do màn hình quyết định) sau khi người dùng đồng ý.
class BudgetSuggestionSection extends StatelessWidget {
  final BudgetSuggestionSet set;
  final void Function(BudgetSuggestion suggestion)? onShowImpact;
  final void Function(BudgetSuggestion suggestion)? onConfirm;
  final void Function(BudgetSuggestion suggestion)? onDismiss;
  final bool isBusy;

  const BudgetSuggestionSection({
    super.key,
    required this.set,
    this.onShowImpact,
    this.onConfirm,
    this.onDismiss,
    this.isBusy = false,
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
              'Gợi ý ngân sách',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (!set.hasBudget)
          _Info(
            text: set.emptyReason?.reason ??
                'Chưa có kỳ ngân sách đang mở. Tạo ngân sách ở tab Kế hoạch để nhận gợi ý điều chỉnh dựa trên đánh giá của bạn.',
            nextStep: set.emptyReason?.nextStep,
          )
        else if (set.suggestions.isEmpty) ...[
          _Info(
            text: set.emptyReason?.reason ??
                'Chưa có gợi ý phù hợp. Gợi ý chỉ xuất hiện khi có đủ đánh giá và mức chi thực tế đáng để điều chỉnh.',
            nextStep: set.emptyReason?.nextStep,
          ),
          if (set.usage.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Vẫn cho thấy mức dùng hạn mức thật để màn không "trống".
            _UsageList(usage: set.usage),
          ],
        ] else
          for (final s in set.suggestions)
            _SuggestionCard(
              suggestion: s,
              isBusy: isBusy,
              onShowImpact:
                  onShowImpact == null ? null : () => onShowImpact!(s),
              onConfirm: onConfirm == null ? null : () => onConfirm!(s),
              onDismiss: onDismiss == null ? null : () => onDismiss!(s),
            ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  final String text;
  final String? nextStep;

  const _Info({required this.text, this.nextStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 14, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: Color(0xFF6B7280),
                  ),
                ),
                if (nextStep != null && nextStep!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    nextStep!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F5B47),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mức dùng hạn mức thật theo danh mục (thanh tiến độ).
class _UsageList extends StatelessWidget {
  final List<BudgetUsage> usage;

  const _UsageList({required this.usage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mức dùng hạn mức kỳ này',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          for (final u in usage) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    u.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ),
                Text(
                  '${_money.format(u.spent)} / ${_money.format(u.limit)} ₫',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 34,
                  child: Text(
                    '${u.percent ?? 0}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: (u.percent ?? 0) >= 80
                          ? const Color(0xFFB45309)
                          : const Color(0xFF0F5B47),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ((u.percent ?? 0) / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: const Color(0xFFEAF8F5),
                color: (u.percent ?? 0) >= 80
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF0F5B47),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final BudgetSuggestion suggestion;
  final VoidCallback? onShowImpact;
  final VoidCallback? onConfirm;
  final VoidCallback? onDismiss;
  final bool isBusy;

  const _SuggestionCard({
    required this.suggestion,
    this.onShowImpact,
    this.onConfirm,
    this.onDismiss,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final increase = suggestion.isIncrease;
    final accent =
        increase ? const Color(0xFF0F5B47) : const Color(0xFFB45309);
    final accentBg =
        increase ? const Color(0xFFC2F0E6) : const Color(0xFFFEF3C7);

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration:
                      BoxDecoration(color: accentBg, shape: BoxShape.circle),
                  child: Icon(
                    increase ? Icons.trending_up : Icons.trending_down,
                    size: 18,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${increase ? 'Tăng' : 'Giảm'} ngân sách ${suggestion.categoryName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Lý do
            Text(
              suggestion.reason,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),

            // Hiện tại → đề xuất
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _LimitCell(
                      label: 'Ngân sách hiện tại',
                      value: _money.format(suggestion.currentLimit),
                      color: Colors.black87,
                    ),
                  ),
                  const Icon(Icons.arrow_forward,
                      size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _LimitCell(
                      label: 'Đề xuất',
                      value: _money.format(suggestion.proposedLimit),
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Căn cứ
            Row(
              children: [
                const Icon(Icons.link, size: 12, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    suggestion.usedPercent == null
                        ? 'Căn cứ: ${suggestion.evidenceTransactionIds.length} giao dịch đã đánh giá'
                        : 'Đã dùng ${suggestion.usedPercent}% hạn mức • ${suggestion.evidenceTransactionIds.length} giao dịch căn cứ',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onShowImpact,
                    icon: const Icon(Icons.query_stats, size: 15),
                    label: const Text('Xem tác động',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: isBusy ? null : onDismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('Bỏ qua',
                      style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: isBusy ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5B47),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Xác nhận',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LimitCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 2),
        Text(
          '$value ₫',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
