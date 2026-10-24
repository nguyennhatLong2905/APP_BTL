import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/timeline_provider.dart';
import '../widgets/mindful_action_card.dart';
import '../widgets/reflection_bottom_nav.dart';
import '../widgets/reflection_transaction_card.dart';
import '../widgets/self_insight_card.dart';
import '../widgets/week_reflection_header.dart';
import '../widgets/weekly_expense_summary_card.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timelineProvider);
    final notifier = ref.read(timelineProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFE3F5F1), // Pastel Mint Background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go(AppConstants.splashRoute),
          tooltip: 'Quay lại',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VÍ AN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.grey.shade600,
              ),
            ),
            const Text(
              'Ví An Nhìn Lại Tài Chính',
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
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
            tooltip: 'Thông báo',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF0F5B47),
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Chiêm nghiệm tuần
            WeekReflectionHeader(dateRange: state.dateRangeText),
            const SizedBox(height: 12),

            // Card 2: Tổng chi tuần qua
            WeeklyExpenseSummaryCard(
              totalSpent: state.totalWeeklySpent,
              lastWeekSpent: state.lastWeekSpent,
              percentDecrease: state.percentDecrease,
              categories: state.categoryExpenses,
            ),
            const SizedBox(height: 20),

            // Section Header: Nhật ký dùng tiền
            const Row(
              children: [
                Icon(Icons.favorite_outline, color: Color(0xFF0F5B47), size: 18),
                SizedBox(width: 8),
                Text(
                  'Nhật ký Dùng tiền',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Cùng nhìn lại những khoản chi sau 7 ngày để lắng nghe cảm xúc thật sự nào còn lại khi niềm phấn khích mua sắm ban đầu đã lắng xuống.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),

            // Reflection Transaction Cards List
            for (final item in state.reflectionItems)
              ReflectionTransactionCard(
                item: item,
                onRatingSelected: (rating) {
                  notifier.updateItemRating(item.id, rating);
                },
                onSaveComment: (comment) {
                  notifier.saveComment(item.id, comment);
                  AppSnackBar.showSuccess(
                      context, 'Đã lưu cảm nhận cho "${item.title}"!');
                },
              ),
            const SizedBox(height: 16),

            // Card 3: Thấu hiểu bản thân
            const SelfInsightCard(),
            const SizedBox(height: 20),

            // Card 4: Gợi ý hành động chánh niệm
            MindfulActionCard(
              onAdjustBudget: () {
                context.go(AppConstants.budgetPlanningRoute);
              },
              onActivateChallenge: () {
                AppSnackBar.showSuccess(
                    context, 'Đã kích hoạt thử thách khoảng lặng 48h!');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const ReflectionBottomNav(),
    );
  }
}
