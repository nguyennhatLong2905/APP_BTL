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
  final String lastWeekRangeText; // Thêm text cho tuần trước
  final double totalWeeklySpent;
  final double lastWeekSpent;
  final int percentDecrease;
  final List<CategoryExpense> categoryExpenses;
  final List<TimelineItem> reflectionItems;
  final bool isLoading;
  final String? errorMessage;

  const TimelineState({
    this.dateRangeText = '--',
    this.lastWeekRangeText = '--', // Mặc định
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
    String? lastWeekRangeText,
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
      lastWeekRangeText: lastWeekRangeText ?? this.lastWeekRangeText,
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

      // Parse report data từ backend (/screens/review trả về report, categories, reflections, ...)
      final report = review['report'] as Map<String, dynamic>?;
      final weekStats = review['weekStats'] as Map<String, dynamic>? 
          ?? review['data'] as Map<String, dynamic>?
          ?? review;
      
      final totalSpent = _toDouble(
        report?['expense'] ??
        weekStats['totalSpent'] ?? 
        weekStats['totalWeeklySpent'] ?? 
        weekStats['thisWeekSpent'] ??
        weekStats['currentWeekSpent'] ?? 
        0
      );
      
      final lastSpent = _toDouble(
        report?['previousExpense'] ??
        weekStats['lastWeekSpent'] ?? 
        weekStats['previousWeekSpent'] ?? 
        weekStats['prevWeekSpent'] ??
        0
      );
      
      final pctDecrease = lastSpent > 0
          ? (((lastSpent - totalSpent) / lastSpent) * 100).round()
          : (report?['expenseChangePercent'] != null
              ? -(_toDouble(report!['expenseChangePercent'])).round()
              : 0);

      // Date range text cho tuần hiện tại
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final dateRangeText =
          '${_fmtDay(weekStart)}/${weekStart.month.toString().padLeft(2, '0')} – ${_fmtDay(weekEnd)}/${weekEnd.month.toString().padLeft(2, '0')}';

      // Date range text cho tuần trước
      final lastWeekStart = weekStart.subtract(const Duration(days: 7));
      final lastWeekEnd = lastWeekStart.add(const Duration(days: 6));
      final lastWeekRangeText =
          '${_fmtDay(lastWeekStart)}/${lastWeekStart.month.toString().padLeft(2, '0')} – ${_fmtDay(lastWeekEnd)}/${lastWeekEnd.month.toString().padLeft(2, '0')}';

      // Map danh mục để tra cứu tên/thông tin
      final catList = (review['categories'] as List<dynamic>?) ?? [];
      final catMap = <String, Map<String, dynamic>>{};
      for (final c in catList) {
        if (c is Map<String, dynamic>) {
          final id = c['_id']?.toString() ?? c['id']?.toString();
          if (id != null) catMap[id] = c;
        }
      }

      // Parse categories từ report['byCategory'] hoặc fallback weekStats
      final byCat = report?['byCategory'] as List<dynamic>?;
      List<CategoryExpense> categories = [];
      final totalForPct = totalSpent > 0 ? totalSpent : 1;

      if (byCat != null && byCat.isNotEmpty) {
        categories = byCat
            .where((c) => c is Map<String, dynamic> && c['type'] == 'expense')
            .map((c) {
              final m = c as Map<String, dynamic>;
              final catId = m['categoryId']?.toString();
              final catInfo = catId != null ? catMap[catId] : null;
              final name = catInfo?['name'] as String? ?? 'Chi tiêu khác';
              final amt = _toDouble(m['amount']);
              return CategoryExpense(
                name: name,
                amount: amt,
                percentage: totalSpent > 0 ? ((amt / totalForPct) * 100).round() : 0,
                tag: catInfo?['tag'] as String?,
              );
            }).toList();
      } else {
        final catRaw = (weekStats['categories'] as List<dynamic>?) 
            ?? (weekStats['categoryBreakdown'] as List<dynamic>?)
            ?? (weekStats['expensesByCategory'] as List<dynamic>?)
            ?? [];
        categories = catRaw.map((c) {
          final m = c as Map<String, dynamic>;
          final amt = _toDouble(
            m['amount'] ?? 
            m['totalSpent'] ?? 
            m['total'] ?? 
            m['spent'] ?? 
            0
          );
          final name = m['name'] as String? 
              ?? m['categoryName'] as String? 
              ?? m['category'] as String? 
              ?? 'Khác';
          return CategoryExpense(
            name: name,
            amount: amt,
            percentage: totalSpent > 0 ? ((amt / totalForPct) * 100).round() : 0,
            tag: m['tag'] as String?,
          );
        }).toList();
      }

      // Parse reflections: kết hợp từ review['reflections'] hoặc API /reflections
      final reflectionsList = (review['reflections'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          reflections;
      final items = reflectionsList.map((r) => _parseReflection(r, catMap)).toList();

      state = state.copyWith(
        isLoading: false,
        dateRangeText: dateRangeText,
        lastWeekRangeText: lastWeekRangeText,
        totalWeeklySpent: totalSpent,
        lastWeekSpent: lastSpent,
        percentDecrease: pctDecrease.abs(), // Luôn dương
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

    // Call API cập nhật rating
    String apiRating = 'worth_it';
    if (rating == EmotionRating.normal) apiRating = 'neutral';
    if (rating == EmotionRating.considerAgain) apiRating = 'reconsider';

    try {
      final ds = ref.read(timelineRemoteDataSourceProvider);
      ds.rateReflection(id: id, rating: apiRating);
    } catch (_) {}
  }

  void saveComment(String id, String comment) {
    final updated = state.reflectionItems.map((item) {
      if (item.id == id) return item.copyWith(comment: comment, isSaved: true);
      return item;
    }).toList();
    state = state.copyWith(reflectionItems: updated);

    // Call API lưu cảm nhận
    try {
      final item = state.reflectionItems.firstWhere((i) => i.id == id);
      String apiRating = 'worth_it';
      if (item.rating == EmotionRating.normal) apiRating = 'neutral';
      if (item.rating == EmotionRating.considerAgain) apiRating = 'reconsider';

      final ds = ref.read(timelineRemoteDataSourceProvider);
      ds.rateReflection(id: id, rating: apiRating, note: comment);
    } catch (_) {}
  }

  // ── Helpers ────────────────────────────────────────────────────────

  double _toDouble(dynamic v) {
    if (v is String) return double.tryParse(v) ?? 0;
    if (v is num) return v.toDouble();
    return 0;
  }

  String _fmtDay(DateTime d) => d.day.toString().padLeft(2, '0');

  TimelineItem _parseReflection(
    Map<String, dynamic> raw, [
    Map<String, Map<String, dynamic>>? catMap,
  ]) {
    final tx = raw['transaction'] as Map<String, dynamic>? ?? raw;
    final catObj = tx['category'];
    String catName = 'Chi Tiêu';
    if (catObj is Map<String, dynamic>) {
      catName = catObj['name'] as String? ?? 'Chi Tiêu';
    } else if (tx['categoryId'] != null && catMap != null) {
      final c = catMap[tx['categoryId'].toString()];
      if (c != null && c['name'] != null) {
        catName = c['name'] as String;
      }
    }

    final amount = _toDouble(tx['amountVnd'] ?? tx['amount'] ?? raw['amount'] ?? 0);
    final occurredAt = tx['occurredAt'] as String? ?? raw['periodStart'] as String?;
    final dateTime = occurredAt != null
        ? DateTime.tryParse(occurredAt)
        : null;
    final fmtDate = dateTime != null
        ? '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}'
        : '';

    final title = tx['note'] as String? ?? tx['memo'] as String? ?? catName;

    EmotionRating? rating;
    final rawRating = raw['rating'] as String?;
    if (rawRating == 'worth_it') {
      rating = EmotionRating.worthIt;
    } else if (rawRating == 'neutral') {
      rating = EmotionRating.normal;
    } else if (rawRating == 'reconsider') {
      rating = EmotionRating.considerAgain;
    }

    return TimelineItem(
      id: raw['_id'] as String? ?? raw['id'] as String? ?? '',
      title: title.isEmpty ? catName : title,
      amount: amount,
      type: TransactionType.expense,
      categoryName: catName,
      dateTime: dateTime,
      dateText: fmtDate,
      rating: rating,
      comment: raw['note'] as String?,
      paymentType: 'Chuyển khoản',
      icon: Icons.shopping_bag_outlined,
      iconBgColor: const Color(0xFFC2F0E6),
    );
  }
}

final timelineProvider = NotifierProvider<TimelineNotifier, TimelineState>(
  TimelineNotifier.new,
);
