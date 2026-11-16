import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/datasources/timeline_remote_data_source.dart';
import '../../domain/models/review_analytics.dart';

final _money = NumberFormat('#,###', 'vi_VN');

/// Màn "Nhật ký đã đánh giá" — lịch sử đánh giá với bộ lọc trạng thái.
///
/// Dữ liệu lấy từ `/reflections/history` (đúng nguồn backend), không dựng lại
/// từ cache màn Nhìn lại, nên luôn phản ánh đánh giá mới nhất.
class ReflectionHistoryScreen extends ConsumerStatefulWidget {
  const ReflectionHistoryScreen({super.key});

  @override
  ConsumerState<ReflectionHistoryScreen> createState() =>
      _ReflectionHistoryScreenState();
}

class _ReflectionHistoryScreenState
    extends ConsumerState<ReflectionHistoryScreen> {
  String _status = 'rated';
  List<ReflectionRecord> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ds = ref.read(timelineRemoteDataSourceProvider);
      final rows = await ds.getReflectionHistory(status: _status);
      if (!mounted) return;
      setState(() {
        _items = rows.map(ReflectionRecord.fromJson).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F5F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VÍ AN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.black54,
              ),
            ),
            Text(
              'Nhật ký đã đánh giá',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F5B47),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            status: _status,
            onChanged: (s) {
              setState(() => _status = s);
              _load();
            },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F5B47)),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40, color: Color(0xFFB91C1C)),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_stories_outlined,
                  size: 44, color: Color(0xFFBDBDBD)),
              const SizedBox(height: 12),
              Text(
                _status == 'rated'
                    ? 'Chưa có nhật ký nào được đánh giá.'
                    : _status == 'skipped'
                        ? 'Chưa có nhật ký nào bị bỏ qua.'
                        : _status == 'tracking'
                            ? 'Không có khoản chi nào đang theo dõi.'
                            : _status == 'awaiting_review'
                                ? 'Không có khoản chi nào tới hạn đánh giá.'
                                : 'Nhật ký đang trống.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mọi khoản chi bạn tạo sẽ tự động vào nhật ký và được nhắc đánh giá sau 7 ngày.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF0F5B47),
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, i) => _HistoryCard(record: _items[i]),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String status;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.status, required this.onChanged});

  static const _options = {
    'rated': 'Đã đánh giá',
    'awaiting_review': 'Chờ đánh giá',
    'tracking': 'Đang theo dõi',
    'skipped': 'Đã bỏ qua',
    'all': 'Tất cả',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (final entry in _options.entries) ...[
            InkWell(
              onTap: () => onChanged(entry.key),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status == entry.key
                      ? const Color(0xFF0F5B47)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: status == entry.key
                        ? const Color(0xFF0F5B47)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: status == entry.key
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: status == entry.key ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ReflectionRecord record;

  const _HistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (record.status) {
      'rated' when record.rating == 'worth_it' => (
          const Color(0xFF15803D),
          const Color(0xFFDCFCE7),
        ),
      'rated' when record.rating == 'reconsider' => (
          const Color(0xFFB45309),
          const Color(0xFFFEF3C7),
        ),
      'rated' => (const Color(0xFF0F5B47), const Color(0xFFE2F6F0)),
      'skipped' => (const Color(0xFF6B7280), const Color(0xFFF3F4F6)),
      _ => (const Color(0xFF0F5B47), const Color(0xFFEAF8F5)),
    };
    final date = record.occurredAt;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (record.transactionNote?.isNotEmpty ?? false)
                            ? record.transactionNote!
                            : (record.categoryName ?? 'Chi tiêu'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (record.categoryName != null) record.categoryName!,
                          if (date != null)
                            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                        ].join(' • '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '-${_money.format(record.amount)} ₫',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record.ratingLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                if (record.ratedAt != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Đánh giá ${DateFormat('dd/MM/yyyy').format(record.ratedAt!)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
            if (record.note != null && record.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  record.note!,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
