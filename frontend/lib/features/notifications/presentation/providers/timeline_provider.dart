import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/timeline_remote_data_source.dart';
import '../../domain/models/timeline_item.dart';

class CategoryExpense {
  final String name;
  final double amount;
  final int percentage;
  final String? tag;

  const CategoryExpense({
    required this.name,
    required this.amount,
    required this.percentage,
    this.tag,
  });
}

class TimelineState {
  final String dateRangeText;
  final double totalWeeklySpent;
  final double lastWeekSpent;
  final int percentDecrease;
  final List<CategoryExpense> categoryExpenses;
  final List<TimelineItem> reflectionItems;
  final bool isLoading;
  final String? errorMessage;

  const TimelineState({
    this.dateRangeText = '--',
    this.totalWeeklySpent = 0,
    this.lastWeekSpent = 0,
    this.percentDecrease = 0,
    this.categoryExpenses = const [],
    this.reflectionItems = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Số lượng giao dịch đã được đánh giá cảm xúc
  int get totalRated => reflectionItems.where((i) => i.rating != null).length;

  TimelineState copyWith({
    String? dateRangeText,
    double? totalWeeklySpent,
    double? lastWeekSpent,
    int? percentDecrease,
    List<CategoryExpense>? categoryExpenses,
    List<TimelineItem>? reflectionItems,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TimelineState(
      dateRangeText: dateRangeText ?? this.dateRangeText,
      totalWeeklySpent: totalWeeklySpent ?? this.totalWeeklySpent,
      lastWeekSpent: lastWeekSpent ?? this.lastWeekSpent,
      percentDecrease: percentDecrease ?? this.percentDecrease,
      categoryExpenses: categoryExpenses ?? this.categoryExpenses,
      reflectionItems: reflectionItems ?? this.reflectionItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class TimelineNotifier extends Notifier<TimelineState> {
  @override
  TimelineState build() {
    Future.microtask(loadAll);
    return const TimelineState(isLoading: true);
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ds = ref.read(timelineRemoteDataSourceProvider);
      final results = await Future.wait([
        ds.getReviewScreen(),
        ds.getReflections(limit: 20),
      ]);

      final review = results[0] as Map<String, dynamic>;
      final reflections = (results[1] as List).cast<Map<String, dynamic>>();

      // Parse review screen data
      final weekStats = review['weekStats'] as Map<String, dynamic>? ?? review;
      final totalSpent = _toDouble(weekStats['totalSpent'] ?? weekStats['totalWeeklySpent'] ?? 0);
      final lastSpent = _toDouble(weekStats['lastWeekSpent'] ?? weekStats['previousWeekSpent'] ?? 0);
      final pctDecrease = lastSpent > 0
          ? (((lastSpent - totalSpent) / lastSpent) * 100).round()
          : 0;

      // Date range text
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final dateRangeText =
          '${_fmtDay(weekStart)} – ${_fmtDay(now)}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      // Parse categories
      final catRaw = weekStats['categories'] as List<dynamic>? ?? [];
      final totalForPct = totalSpent > 0 ? totalSpent : 1;
      final categories = catRaw.map((c) {
        final m = c as Map<String, dynamic>;
        final amt = _toDouble(m['amount'] ?? m['totalSpent'] ?? 0);
        return CategoryExpense(
          name: m['name'] as String? ?? 'Khác',
          amount: amt,
          percentage: ((amt / totalForPct) * 100).round(),
          tag: m['tag'] as String?,
        );
      }).toList();

      // Parse reflections → TimelineItems
      final items = reflections.map(_parseReflection).toList();

      state = state.copyWith(
        isLoading: false,
        dateRangeText: dateRangeText,
        totalWeeklySpent: totalSpent,
        lastWeekSpent: lastSpent,
        percentDecrease: pctDecrease,
        categoryExpenses: categories,
        reflectionItems: items,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void updateItemRating(String id, EmotionRating rating) {
    final updated = state.reflectionItems.map((item) {
      if (item.id == id) return item.copyWith(rating: rating);
      return item;
    }).toList();
    state = state.copyWith(reflectionItems: updated);
  }

  void saveComment(String id, String comment) {
    final updated = state.reflectionItems.map((item) {
      if (item.id == id) return item.copyWith(comment: comment, isSaved: true);
      return item;
    }).toList();
    state = state.copyWith(reflectionItems: updated);
  }

  // ── Helpers ────────────────────────────────────────────────────────

  double _toDouble(dynamic v) {
    if (v is String) return double.tryParse(v) ?? 0;
    if (v is num) return v.toDouble();
    return 0;
  }

  String _fmtDay(DateTime d) => d.day.toString().padLeft(2, '0');

  TimelineItem _parseReflection(Map<String, dynamic> raw) {
    final tx = raw['transaction'] as Map<String, dynamic>? ?? raw;
    final cat = tx['category'] as Map<String, dynamic>? ?? {};
    final catName = cat['name'] as String? ?? 'Chi Tiêu';
    final amount = _toDouble(tx['amountVnd'] ?? tx['amount'] ?? raw['amount'] ?? 0);
    final occurredAt = tx['occurredAt'] as String? ?? raw['periodStart'] as String?;
    final dateTime = occurredAt != null
        ? DateTime.tryParse(occurredAt)
        : null;
    final fmtDate = dateTime != null
        ? '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}'
        : '';

    return TimelineItem(
      id: raw['_id'] as String? ?? raw['id'] as String? ?? '',
      title: tx['memo'] as String? ?? catName,
      amount: amount,
      type: TransactionType.expense,
      categoryName: catName,
      dateTime: dateTime,
      dateText: fmtDate,
      paymentType: 'Chuyển khoản',
      icon: Icons.shopping_bag_outlined,
      iconBgColor: const Color(0xFFC2F0E6),
    );
  }
}

final timelineProvider = NotifierProvider<TimelineNotifier, TimelineState>(
  TimelineNotifier.new,
);
