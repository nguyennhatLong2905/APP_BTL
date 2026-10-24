import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  const TimelineState({
    this.dateRangeText = '25/09 – 01/10/2026',
    this.totalWeeklySpent = 1150000,
    this.lastWeekSpent = 1400000,
    this.percentDecrease = 18,
    this.categoryExpenses = const [
      CategoryExpense(
        name: 'Ăn uống thường nhật',
        amount: 620000,
        percentage: 54,
        tag: 'Cố định',
      ),
      CategoryExpense(
        name: 'Mua sắm cá nhân',
        amount: 310000,
        percentage: 27,
        tag: 'Giảm 120k',
      ),
      CategoryExpense(
        name: 'Đi lại & dịch vụ',
        amount: 220000,
        percentage: 19,
      ),
    ],
    this.reflectionItems = const [
      TimelineItem(
        id: '1',
        title: 'Khóa học tiếng Anh giao tiếp',
        amount: 450000,
        dateTime: null, // Will use DateTime.now() if null or custom date
        dateText: '28/09/2026 • 1/1 kỳ khoản',
        paymentType: 'Chuyển khoản',
        icon: Icons.videocam_outlined,
        iconBgColor: Color(0xFFC2F0E6),
        rating: EmotionRating.worthIt,
      ),
      TimelineItem(
        id: '2',
        title: 'Áo khoác gió thu đông',
        amount: 380000,
        dateTime: null,
        dateText: '24/09/2026 • Thẻ ghi nợ',
        paymentType: 'Thẻ ghi nợ',
        icon: Icons.dry_cleaning_outlined,
        iconBgColor: Color(0xFFFFEAD5),
      ),
    ],
  });

  TimelineState copyWith({
    List<TimelineItem>? reflectionItems,
  }) {
    return TimelineState(
      dateRangeText: dateRangeText,
      totalWeeklySpent: totalWeeklySpent,
      lastWeekSpent: lastWeekSpent,
      percentDecrease: percentDecrease,
      categoryExpenses: categoryExpenses,
      reflectionItems: reflectionItems ?? this.reflectionItems,
    );
  }
}

class TimelineNotifier extends Notifier<TimelineState> {
  @override
  TimelineState build() {
    return const TimelineState();
  }

  void updateItemRating(String id, EmotionRating rating) {
    final updated = state.reflectionItems.map((item) {
      if (item.id == id) {
        return item.copyWith(rating: rating);
      }
      return item;
    }).toList();

    state = state.copyWith(reflectionItems: updated);
  }

  void saveComment(String id, String comment) {
    final updated = state.reflectionItems.map((item) {
      if (item.id == id) {
        return item.copyWith(comment: comment, isSaved: true);
      }
      return item;
    }).toList();

    state = state.copyWith(reflectionItems: updated);
  }
}

final timelineProvider = NotifierProvider<TimelineNotifier, TimelineState>(
  TimelineNotifier.new,
);
