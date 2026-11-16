import 'package:flutter/material.dart';

import '../../domain/models/review_analytics.dart';

/// Card "Chiêm nghiệm tuần": chọn tuần + nhận xét auto từ số liệu thật.
///
/// Nhận xét lấy từ `WeekStats.narrative` (backend chỉ trả khi đủ dữ liệu).
/// Khi tuần không có giao dịch, hiển thị trạng thái "chưa đủ thông tin"
/// thay vì bịa nội dung.
class WeekReflectionHeader extends StatelessWidget {
  final String dateRange;
  final WeekStats week;
  final List<ReviewWeek> weeks;
  final String? selectedWeekStartIso;
  final ValueChanged<ReviewWeek>? onSelectWeek;
  final VoidCallback? onClearSelection;
  final bool isBusy;

  const WeekReflectionHeader({
    super.key,
    required this.dateRange,
    required this.week,
    this.weeks = const [],
    this.selectedWeekStartIso,
    this.onSelectWeek,
    this.onClearSelection,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2F6F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.anchor_outlined,
                    color: Color(0xFF0F5B47),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHIÊM NGHIỆM TUẦN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateRange,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (weeks.isNotEmpty)
                  PopupMenuButton<ReviewWeek>(
                    tooltip: 'Chọn tuần',
                    enabled: !isBusy,
                    onSelected: onSelectWeek,
                    itemBuilder: (context) => [
                      for (final w in weeks)
                        PopupMenuItem(
                          value: w,
                          child: Row(
                            children: [
                              Icon(
                                selectedWeekStartIso == w.isoStart
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 16,
                                color: const Color(0xFF0F5B47),
                              ),
                              const SizedBox(width: 8),
                              Text(w.label,
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC2F0E6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              size: 13, color: Color(0xFF0F5B47)),
                          SizedBox(width: 4),
                          Text(
                            'Đổi tuần',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F5B47),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (selectedWeekStartIso != null && onClearSelection != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: isBusy ? null : onClearSelection,
                  icon: const Icon(Icons.restart_alt, size: 14),
                  label: const Text('Về tuần hiện tại',
                      style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0F5B47),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),

            if (!week.hasData)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chưa đủ dữ liệu để chiêm nghiệm tuần này. '
                        'Thêm giao dịch chi tiêu để Ví An tổng hợp cùng bạn.',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              for (final note in week.narrative)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F5B47),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: Colors.black87,
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
