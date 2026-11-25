import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/timeline_remote_data_source.dart';
import '../../domain/models/review_analytics.dart';
import '../../domain/models/timeline_item.dart';

String emotionRatingApiValue(EmotionRating rating) {
  switch (rating) {
    case EmotionRating.worthIt:
      return 'worth_it';
    case EmotionRating.normal:
      return 'neutral';
    case EmotionRating.considerAgain:
      return 'reconsider';
  }
}

String emotionRatingLabel(EmotionRating? rating) {
  switch (rating) {
    case EmotionRating.worthIt:
      return 'Đáng tiền';
    case EmotionRating.normal:
      return 'Bình thường';
    case EmotionRating.considerAgain:
      return 'Muốn cân nhắc lại';
    default:
      return 'Chưa đánh giá';
  }
}

class TimelineState {
  // Tuần đang xem
  final DateTime? weekStart;
  final DateTime? weekEnd;
  final String weekLabel;
  final List<ReviewWeek> weeks;
  final String? selectedWeekStartIso;

  // Số liệu thật
  final WeekStats week;
  final SelfInsight selfInsight;
  final BudgetSuggestionSet budgetSuggestions;

  // Nhật ký tự động
  final List<JournalEntry> journal;
  final JournalSummary summary;

  final bool isLoading;
  final bool isBusy;
  final String? errorMessage;

  const TimelineState({
    this.weekStart,
    this.weekEnd,
    this.weekLabel = '--',
    this.weeks = const [],
    this.selectedWeekStartIso,
    this.week = const WeekStats(),
    this.selfInsight = const SelfInsight(),
    this.budgetSuggestions = const BudgetSuggestionSet(),
    this.journal = const [],
    this.summary = const JournalSummary(),
    this.isLoading = false,
    this.isBusy = false,
    this.errorMessage,
  });

  /// Khoản đã đủ ngày chờ, cần người dùng đánh giá hoặc bỏ qua.
  List<JournalEntry> get awaitingReview =>
      journal.where((e) => e.isAwaitingReview).toList();

  /// Khoản mới ghi nhận, còn đếm ngược tới hạn đánh giá.
  List<JournalEntry> get tracking =>
      journal.where((e) => e.isTracking).toList();

  int get ratedCount => journal.where((e) => e.isRated).length;
  int get skippedCount => journal.where((e) => e.isSkipped).length;

  /// Không còn khoản nào chưa xử lý (đã đánh giá/bỏ qua hết).
  bool get allJournalHandled => !summary.hasUnresolved;

  TimelineState copyWith({
    DateTime? weekStart,
    DateTime? weekEnd,
    String? weekLabel,
    List<ReviewWeek>? weeks,
    String? selectedWeekStartIso,
    WeekStats? week,
    SelfInsight? selfInsight,
    BudgetSuggestionSet? budgetSuggestions,
    List<JournalEntry>? journal,
    JournalSummary? summary,
    bool? isLoading,
    bool? isBusy,
    String? errorMessage,
  }) {
    return TimelineState(
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      weekLabel: weekLabel ?? this.weekLabel,
      weeks: weeks ?? this.weeks,
      selectedWeekStartIso: selectedWeekStartIso ?? this.selectedWeekStartIso,
      week: week ?? this.week,
      selfInsight: selfInsight ?? this.selfInsight,
      budgetSuggestions: budgetSuggestions ?? this.budgetSuggestions,
      journal: journal ?? this.journal,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: errorMessage,
    );
  }
}

class TimelineNotifier extends Notifier<TimelineState> {
  int _requestId = 0;
  (String?, String?) _requestedWeek = (null, null);

  @override
  TimelineState build() {
    Future.microtask(loadAll);
    return const TimelineState(isLoading: true);
  }

  Future<void> loadAll({
    String? weekStartIso,
    String? weekEndIso,
    bool resetWeek = false,
  }) async {
    if (resetWeek || weekStartIso != null) {
      _requestedWeek = (weekStartIso, weekEndIso);
    }
    final (startAt, endAt) = _requestedWeek;
    final request = ++_requestId;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ds = ref.read(timelineRemoteDataSourceProvider);
      final review = await ds.getReviewScreen(startAt: startAt, endAt: endAt);
      final journalRows =
          (review['journal'] as List?)?.cast<Map<String, dynamic>>() ??
          await ds.getJournal();
      if (!ref.mounted || request != _requestId) return;

      final week = WeekStats.fromJson(review['week'] as Map<String, dynamic>?);
      final weeksRaw = (review['weeks'] as List?) ?? const [];
      final weeks = weeksRaw
          .whereType<Map<String, dynamic>>()
          .map(ReviewWeek.fromJson)
          .toList();
      final journal = journalRows.map(JournalEntry.fromJson).toList();
      final summary = review['journalSummary'] as Map<String, dynamic>?;

      state = state.copyWith(
        isLoading: false,
        weekStart: week.startAt,
        weekEnd: week.endAt,
        weekLabel: _weekLabel(week),
        week: week,
        selfInsight: SelfInsight.fromJson(
          review['selfInsight'] as Map<String, dynamic>?,
        ),
        budgetSuggestions: BudgetSuggestionSet.fromJson(
          review['budgetSuggestions'] as Map<String, dynamic>?,
        ),
        weeks: weeks,
        selectedWeekStartIso: week.startAt?.toUtc().toIso8601String(),
        journal: journal,
        summary: summary == null
            ? JournalSummary(
                total: journal.length,
                tracking: journal.where((entry) => entry.isTracking).length,
                awaitingReview: journal
                    .where((entry) => entry.isAwaitingReview)
                    .length,
                rated: journal.where((entry) => entry.isRated).length,
                skipped: journal.where((entry) => entry.isSkipped).length,
              )
            : JournalSummary.fromJson(summary),
      );
    } catch (e) {
      if (!ref.mounted || request != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Chọn tuần khác để xem báo cáo.
  Future<void> selectWeek(ReviewWeek week) =>
      loadAll(weekStartIso: week.isoStart, weekEndIso: week.isoEnd);

  /// Bỏ chọn tuần (về tuần hiện tại).
  Future<void> clearWeekSelection() => loadAll(resetWeek: true);

  /// Lưu đánh giá (kèm ghi chú) rồi đồng bộ lại toàn bộ dữ liệu phân tích.
  Future<String?> rateReflection(
    String entryId,
    EmotionRating rating, {
    String? note,
  }) async {
    try {
      final ds = ref.read(timelineRemoteDataSourceProvider);
      await ds.rateReflection(
        id: entryId,
        rating: emotionRatingApiValue(rating),
        note: note,
      );
      await loadAll();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Bỏ qua không đánh giá — không tự gán mức đánh giá nào.
  Future<String?> skipReflection(String entryId) async {
    try {
      final ds = ref.read(timelineRemoteDataSourceProvider);
      await ds.skipReflection(entryId);
      await loadAll();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────

  String _weekLabel(WeekStats w) {
    final a = w.startAt;
    final b = w.endAt;
    if (a == null || b == null) return '--';
    final last = b.subtract(const Duration(days: 1));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(a.day)}/${two(a.month)} – ${two(last.day)}/${two(last.month)}/${last.year}';
  }
}

final timelineProvider = NotifierProvider<TimelineNotifier, TimelineState>(
  TimelineNotifier.new,
);

// ── dùng chung ───────────────────────────────────────────────────────

/// Icon/màu theo tên danh mục — chỉ dùng để hiển thị, không phải dữ liệu.
IconData billCategoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('ăn') || n.contains('cà phê')) {
    return Icons.restaurant_outlined;
  }
  if (n.contains('học')) return Icons.school_outlined;
  if (n.contains('mua')) return Icons.shopping_bag_outlined;
  if (n.contains('đi lại') || n.contains('xe')) {
    return Icons.directions_car_outlined;
  }
  if (n.contains('hóa đơn')) return Icons.receipt_long_outlined;
  return Icons.category_outlined;
}
