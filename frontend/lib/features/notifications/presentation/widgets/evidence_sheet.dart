import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/review_analytics.dart';
import '../providers/timeline_provider.dart';

final _money = NumberFormat('#,###', 'vi_VN');

/// Bottom sheet hiển thị các giao dịch làm căn cứ cho một nhận xét / gợi ý.
Future<void> showEvidenceSheet(
  BuildContext context, {
  required String title,
  required List<EvidenceTransaction> items,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _EvidenceSheet(title: title, items: items),
  );
}

class _EvidenceSheet extends StatelessWidget {
  final String title;
  final List<EvidenceTransaction> items;

  const _EvidenceSheet({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giao dịch làm căn cứ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Không tìm thấy giao dịch căn cứ.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFFEEF2F1)),
                  itemBuilder: (context, i) {
                    final e = items[i];
                    final d = e.occurredAt;
                    final dateText = d == null
                        ? ''
                        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFE2F6F0),
                        child: Icon(
                          billCategoryIcon(e.categoryName ?? ''),
                          size: 16,
                          color: const Color(0xFF0F5B47),
                        ),
                      ),
                      title: Text(
                        (e.note?.isNotEmpty ?? false)
                            ? e.note!
                            : (e.categoryName ?? 'Chi tiêu'),
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        [if (e.categoryName != null) e.categoryName!, dateText]
                            .where((s) => s.isNotEmpty)
                            .join(' • '),
                        style: const TextStyle(fontSize: 10.5),
                      ),
                      trailing: Text(
                        '-${_money.format(e.amount)} ₫',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
