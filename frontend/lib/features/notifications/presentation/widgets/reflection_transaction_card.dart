import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/review_analytics.dart';
import '../../domain/models/timeline_item.dart';
import '../providers/timeline_provider.dart';

final _money = NumberFormat('#,###', 'vi_VN');

/// Card một khoản chi trong "Nhật ký Đáng tiền".
///
/// Nhật ký được ghi nhận tự động từ giao dịch thật, nên card không có thao tác
/// thêm/xác nhận theo dõi. Người dùng chỉ chọn một trong bốn lựa chọn: Đáng
/// tiền / Bình thường / Muốn cân nhắc lại / Bỏ qua. Khi chưa đủ 7 ngày, card
/// hiển thị đếm ngược và vẫn cho phép đánh giá sớm.
class ReflectionTransactionCard extends StatefulWidget {
  final JournalEntry entry;
  final ValueChanged<EmotionRating> onRatingSelected;
  final void Function(EmotionRating? rating, String note) onSave;
  final VoidCallback? onSkip;
  final bool isSaving;

  const ReflectionTransactionCard({
    super.key,
    required this.entry,
    required this.onRatingSelected,
    required this.onSave,
    this.onSkip,
    this.isSaving = false,
  });

  @override
  State<ReflectionTransactionCard> createState() =>
      _ReflectionTransactionCardState();
}

class _ReflectionTransactionCardState
    extends State<ReflectionTransactionCard> {
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.entry.note ?? '');
  }

  @override
  void didUpdateWidget(covariant ReflectionTransactionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Đồng bộ khi provider nạp lại dữ liệu từ server.
    final incoming = widget.entry.note ?? '';
    if (incoming != _commentController.text &&
        !_commentController.selection.isValid) {
      _commentController.text = incoming;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final selectedRating = _ratingFromApi(entry.rating);
    final isAwaiting = entry.isAwaitingReview;

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
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFC2F0E6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    billCategoryIcon(entry.categoryLabel),
                    color: const Color(0xFF0F5B47),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.categoryLabel} • ${entry.dateText}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '-${_money.format(entry.amount)} ₫',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAwaiting
                    ? const Color(0xFFE2F6F0)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isAwaiting
                    ? 'Đã đủ 7 ngày — mời bạn đánh giá trải nghiệm mua sắm.'
                    : '${entry.countdownLabel}; bạn vẫn có thể ghi cảm nhận sớm.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: isAwaiting
                      ? const Color(0xFF0F5B47)
                      : const Color(0xFFB45309),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _RatingButton(
                    selected: selectedRating,
                    label: 'Đáng tiền',
                    icon: '❤',
                    onTap: widget.isSaving
                        ? null
                        : () => widget.onRatingSelected(EmotionRating.worthIt),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _RatingButton(
                    selected: selectedRating,
                    label: 'Bình thường',
                    icon: '🙂',
                    onTap: widget.isSaving
                        ? null
                        : () => widget.onRatingSelected(EmotionRating.normal),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _RatingButton(
                    selected: selectedRating,
                    label: 'Muốn cân nhắc lại',
                    icon: '🔴',
                    onTap: widget.isSaving
                        ? null
                        : () => widget.onRatingSelected(
                            EmotionRating.considerAgain),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _commentController,
              enabled: !widget.isSaving,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Chia sẻ ngắn lý do bạn thấy đáng...',
                hintStyle:
                    TextStyle(fontSize: 12, color: Colors.grey.shade500),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFEAF8F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: widget.isSaving ? null : widget.onSkip,
                  child: Text(
                    'Bỏ qua không đánh giá',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: widget.isSaving
                      ? null
                      : () => widget.onSave(
                            selectedRating,
                            _commentController.text.trim(),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5B47),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: widget.isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          selectedRating == null ? 'Lưu cảm nhận' : 'Lưu đánh giá',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static EmotionRating? _ratingFromApi(String? raw) {
    switch (raw) {
      case 'worth_it':
        return EmotionRating.worthIt;
      case 'neutral':
        return EmotionRating.normal;
      case 'reconsider':
        return EmotionRating.considerAgain;
      default:
        return null;
    }
  }
}

class _RatingButton extends StatelessWidget {
  final EmotionRating? selected;
  final String label;
  final String icon;
  final VoidCallback? onTap;

  const _RatingButton({
    required this.selected,
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F5B47) : const Color(0xFFEAF8F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : const Color(0xFF0F5B47),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
