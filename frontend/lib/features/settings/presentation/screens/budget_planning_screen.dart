import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/currency_text_field.dart';
import '../../domain/models/category_budget.dart';
import '../providers/budget_provider.dart';
import '../widgets/add_category_button.dart';
import '../widgets/budget_bottom_nav.dart';
import '../widgets/budget_category_card.dart';
import '../widgets/budget_control_tabs.dart';
import '../widgets/budget_summary_overview_card.dart';
import '../widgets/salary_cycle_card.dart';

class BudgetPlanningScreen extends ConsumerWidget {
  const BudgetPlanningScreen({super.key});

  void _showEditCategoryDialog(
      BuildContext context, WidgetRef ref, CategoryBudget cat) {
    final controller = TextEditingController(
        text: cat.allocatedAmount.toInt().toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Điều Chỉnh Ngân Sách "${cat.name}"'),
          content: CurrencyTextField(
            controller: controller,
            labelText: 'Ngân sách phân bổ',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = CurrencyTextField.getRawAmount(controller);
                if (amount > 0) {
                  ref
                      .read(budgetProvider.notifier)
                      .updateCategoryAllocated(cat.id, amount);
                  AppSnackBar.showSuccess(
                      context, 'Đã cập nhật ngân sách cho "${cat.name}"!');
                }
                Navigator.pop(context);
              },
              child: const Text('Cập nhật'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Thêm Danh Mục Ngân Sách Mới'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên danh mục',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              CurrencyTextField(
                controller: amountController,
                labelText: 'Ngân sách dự kiến',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final amount =
                    CurrencyTextField.getRawAmount(amountController);
                if (name.isNotEmpty && amount > 0) {
                  final newCat = CategoryBudget(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    icon: Icons.category_outlined,
                    allocatedAmount: amount,
                    spentAmount: 0,
                  );
                  ref.read(budgetProvider.notifier).addCategory(newCat);
                  AppSnackBar.showSuccess(
                      context, 'Đã thêm danh mục "$name"!');
                }
                Navigator.pop(context);
              },
              child: const Text('Thêm mới'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetProvider);
    final notifier = ref.read(budgetProvider.notifier);

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
              'Ví An Kế Hoạch Chi Tiêu',
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
            // Card 1: Kỳ lương an tâm & Kế hoạch tài chính
            SalaryCycleCard(
              daysLeft: state.daysLeft,
              periodText: state.periodText,
            ),
            const SizedBox(height: 12),

            // Tab Controls & Filter Chips
            BudgetControlTabs(
              activeTab: state.activeTab,
              onTabChanged: (tab) => notifier.setActiveTab(tab),
              filterMode: state.filterMode,
              onFilterModeChanged: (mode) => notifier.setFilterMode(mode),
            ),
            const SizedBox(height: 12),

            // Card 2: Còn để chi thực tế & Tổng ngân sách
            BudgetSummaryOverviewCard(
              freeRemaining: state.freeRemainingBalance,
              totalBudget: state.totalBudget,
              totalSpent: state.totalSpent,
              spentPercentage: state.spentPercentage,
              dailyLimit: state.dailyLimit,
              statusText: state.cycleStatus,
            ),
            const SizedBox(height: 16),

            // Section Header: Danh mục chi tiêu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh mục chi tiêu',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${state.categories.length} danh mục',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Category Cards List
            for (final cat in state.categories)
              BudgetCategoryCard(
                category: cat,
                onEditPressed: () =>
                    _showEditCategoryDialog(context, ref, cat),
              ),

            // Add Category Button
            AddCategoryButton(
              onPressed: () => _showAddCategoryDialog(context, ref),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BudgetBottomNav(),
    );
  }
}
