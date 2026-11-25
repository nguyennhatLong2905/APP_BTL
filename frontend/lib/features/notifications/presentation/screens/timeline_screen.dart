import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/finance_screen_style.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/datasources/timeline_remote_data_source.dart';
import '../../domain/models/review_analytics.dart';
import '../providers/timeline_provider.dart';
import '../widgets/budget_suggestion_section.dart';
import '../widgets/evidence_sheet.dart';
import '../widgets/reflection_bottom_nav.dart';
import '../widgets/self_insight_card.dart';
import '../widgets/review_journal.dart';
import '../widgets/weekly_review_card.dart';

final _money = NumberFormat('#,###', 'vi_VN');

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineProvider);
    final notifier = ref.read(timelineProvider.notifier);

    return Scaffold(
      backgroundColor: FinanceScreenStyle.background,
      appBar: const FinanceScreenHeader(title: 'Nhìn lại tài chính'),
      body: _buildBody(context, ref, state, notifier),
      bottomNavigationBar: const ReflectionBottomNav(),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TimelineState state,
    TimelineNotifier notifier,
  ) {
    if (state.isLoading && state.week.startAt == null) {
      return const Center(
        child: CircularProgressIndicator(color: FinanceScreenStyle.green),
      );
    }
    if (state.errorMessage != null && state.week.startAt == null) {
      return _ErrorState(
        message: state.errorMessage!,
        onRetry: () => notifier.loadAll(),
      );
    }

    return RefreshIndicator(
      color: FinanceScreenStyle.green,
      onRefresh: notifier.loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.errorMessage != null)
              _InlineError(message: state.errorMessage!),
            WeeklyReviewCard(
              state: state,
              onSelectWeek: notifier.selectWeek,
              onTapCategory: (category) =>
                  _openCategoryTransactions(context, ref, category, state),
            ),
            const SizedBox(height: 18),
            ReviewJournal(
              state: state,
              onSave: notifier.rateReflection,
              onSkip: notifier.skipReflection,
              onHistory: () =>
                  context.push(AppConstants.reflectionHistoryRoute),
            ),
            const SizedBox(height: 16),

            // Card 3: Thấu hiểu bản thân (dữ liệu thật)
            SelfInsightCard(
              insight: state.selfInsight,
              onShowEvidence: (s) => _openEvidence(
                context,
                ref,
                title: s.text,
                ids: s.evidenceTransactionIds,
              ),
              onViewHistory: () =>
                  context.push(AppConstants.reflectionHistoryRoute),
            ),
            const SizedBox(height: 20),

            // Card 4: Gợi ý ngân sách (không tự áp dụng)
            BudgetSuggestionSection(
              set: state.budgetSuggestions,
              isBusy: state.isBusy,
              onShowImpact: (s) => _showImpact(context, ref, s, state),
              onConfirm: (s) => _confirmSuggestion(context, ref, s),
              onDismiss: (s) => _dismissSuggestion(context, notifier, s),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Drill-down giao dịch theo danh mục ─────────────────────────────

  Future<void> _openCategoryTransactions(
    BuildContext context,
    WidgetRef ref,
    WeekCategory category,
    TimelineState state,
  ) async {
    final start = state.week.startAt;
    final end = state.week.endAt;
    if (start == null || end == null || category.categoryId == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CategoryTransactionsSheet(
        category: category,
        startAt: start,
        endAt: end,
      ),
    );
  }

  // ── Căn cứ ─────────────────────────────────────────────────────────

  Future<void> _openEvidence(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required List<String> ids,
  }) async {
    try {
      final ds = ref.read(timelineRemoteDataSourceProvider);
      final rows = await ds.getEvidence(ids);
      if (!context.mounted) return;
      await showEvidenceSheet(
        context,
        title: title,
        items: rows.map(EvidenceTransaction.fromJson).toList(),
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.showError(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Gợi ý ngân sách ────────────────────────────────────────────────

  void _showImpact(
    BuildContext context,
    WidgetRef ref,
    BudgetSuggestion s,
    TimelineState state,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tác động: ${s.categoryName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _impactRow('Ngân sách hiện tại', s.currentLimit),
            _impactRow('Đề xuất', s.proposedLimit),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                s.isIncrease
                    ? 'Hạn mức danh mục tăng ${_money.format(s.proposedLimit - s.currentLimit)} ₫. '
                          'Tổng ngân sách kỳ này tăng tương ứng; chỉ áp dụng khi bạn bấm Xác nhận.'
                    : 'Hạn mức danh mục giảm ${_money.format(s.currentLimit - s.proposedLimit)} ₫. '
                          'Khoản chênh lệch trở lại là tiền tự do trong kỳ; chỉ áp dụng khi bạn bấm Xác nhận.',
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _impactRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            '${_money.format(value)} ₫',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSuggestion(
    BuildContext context,
    WidgetRef ref,
    BudgetSuggestion s,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Áp dụng gợi ý?'),
        content: Text(
          '${s.isIncrease ? 'Tăng' : 'Giảm'} hạn mức ${s.categoryName} '
          'từ ${_money.format(s.currentLimit)} ₫ thành '
          '${_money.format(s.proposedLimit)} ₫.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FinanceScreenStyle.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    if (s.budgetId == null) {
      AppSnackBar.showError(context, 'Không xác định được kỳ ngân sách');
      return;
    }
    try {
      await _putBudgetLimit(ref, s.budgetId!, s);
      if (!context.mounted) return;
      AppSnackBar.showSuccess(context, 'Đã cập nhật hạn mức ${s.categoryName}');
      await ref.read(timelineProvider.notifier).loadAll();
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.showError(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Ghi hạn mức mới vào kỳ ngân sách, tái sử dụng repository hiện có.
  Future<void> _putBudgetLimit(
    WidgetRef ref,
    String budgetId,
    BudgetSuggestion s,
  ) async {
    final ds = ref.read(timelineRemoteDataSourceProvider);
    final plan = await ds.getBudgetPlan(budgetId);
    final limits = (plan['limits'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final updated = limits.map((l) {
      if (l['categoryId']?.toString() == s.categoryId) {
        return {
          'categoryId': s.categoryId,
          'limit': s.proposedLimit.toInt().toString(),
        };
      }
      return {
        'categoryId': l['categoryId']?.toString(),
        'limit': l['limit']?.toString(),
      };
    }).toList();
    await ds.updateBudgetPlan(budgetId, {
      'name': plan['name'],
      'periodType': plan['periodType'],
      'startAt': plan['startAt'],
      'endAt': plan['endAt'],
      'warningPercent': plan['warningPercent'],
      'limits': updated,
    });
  }

  Future<void> _dismissSuggestion(
    BuildContext context,
    TimelineNotifier notifier,
    BudgetSuggestion s,
  ) async {
    AppSnackBar.showWarning(
      context,
      'Đã bỏ qua gợi ý ${s.categoryName}. Ngân sách không thay đổi.',
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Trạng thái phụ
// ════════════════════════════════════════════════════════════════════

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: Color(0xFFB91C1C)),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: Color(0xFFB91C1C)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTransactionsSheet extends ConsumerStatefulWidget {
  final WeekCategory category;
  final DateTime startAt;
  final DateTime endAt;

  const _CategoryTransactionsSheet({
    required this.category,
    required this.startAt,
    required this.endAt,
  });

  @override
  ConsumerState<_CategoryTransactionsSheet> createState() =>
      _CategoryTransactionsSheetState();
}

class _CategoryTransactionsSheetState
    extends ConsumerState<_CategoryTransactionsSheet> {
  List<Map<String, dynamic>> _rows = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final client = ref.read(timelineRemoteDataSourceProvider);
      // Tái sử dụng nguồn dữ liệu review: lọc theo giao dịch chi của tuần.
      final rows = await client.getCategoryTransactions(
        categoryId: widget.category.categoryId!,
        startAt: widget.startAt,
        endAt: widget.endAt,
      );
      if (!mounted) return;
      setState(() {
        _rows = rows;
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
              child: Text(
                '${widget.category.name} • ${_money.format(widget.category.amount)} ₫',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: FinanceScreenStyle.green,
                  ),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              )
            else if (_rows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: Text(
                    'Không có giao dịch trong danh mục này.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _rows.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFFEEF2F1)),
                  itemBuilder: (context, i) {
                    final r = _rows[i];
                    final amount = num.tryParse('${r['amount'] ?? 0}') ?? 0;
                    final at = DateTime.tryParse(
                      r['occurredAt']?.toString() ?? '',
                    )?.toLocal();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        r['note']?.toString() ?? 'Chi tiêu',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        at == null
                            ? ''
                            : '${at.day.toString().padLeft(2, '0')}/${at.month.toString().padLeft(2, '0')}/${at.year}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        '-${_money.format(amount)} ₫',
                        style: const TextStyle(
                          fontSize: 12.5,
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
