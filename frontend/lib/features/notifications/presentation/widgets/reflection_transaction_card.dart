import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/timeline_item.dart';

class ReflectionTransactionCard extends StatefulWidget {
  final TimelineItem item;
  final ValueChanged<EmotionRating> onRatingSelected;
  final ValueChanged<String> onSaveComment;

  const ReflectionTransactionCard({
    super.key,
    required this.item,
    required this.onRatingSelected,
    required this.onSaveComment,
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
    _commentController = TextEditingController(text: widget.item.comment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    final selectedRating = widget.item.rating ?? EmotionRating.worthIt;

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
                  decoration: BoxDecoration(
                    color: widget.item.iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.item.icon,
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
                        widget.item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.item.dateText,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '-${currencyFormatter.format(widget.item.amount)} ₫',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3 Rating Buttons
            Row(
              children: [
                Expanded(
                  child: _buildRatingButton(
                    rating: EmotionRating.worthIt,
                    selectedRating: selectedRating,
                    label: 'Rất đáng tiền',
                    icon: '❤',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildRatingButton(
                    rating: EmotionRating.normal,
                    selectedRating: selectedRating,
                    label: 'Bình thường',
                    icon: '🙂',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildRatingButton(
                    rating: EmotionRating.considerAgain,
                    selectedRating: selectedRating,
                    label: 'Cần cân nhắc',
                    icon: '🔴',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Comment textfield
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Chia sẻ ngắn lý do bạn thấy đáng...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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

            // Bottom actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Bỏ qua không đánh giá',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onSaveComment(_commentController.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5B47),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.item.isSaved ? 'Đã lưu' : 'Lưu cảm nhận',
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

  Widget _buildRatingButton({
    required EmotionRating rating,
    required EmotionRating selectedRating,
    required String label,
    required String icon,
  }) {
    final isSelected = selectedRating == rating;

    return InkWell(
      onTap: () => widget.onRatingSelected(rating),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F5B47) : const Color(0xFFEAF8F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              label,
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
