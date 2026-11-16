import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/currency_text_field.dart';
import '../../../transaction/domain/models/transaction_category.dart';
import '../../domain/models/category_budget.dart';
import '../providers/budget_provider.dart';
import '../widgets/add_category_button.dart';
import '../widgets/budget_bottom_nav.dart';
import '../widgets/budget_category_card.dart';
import '../widgets/budget_control_tabs.dart';
import '../widgets/budget_summary_overview_card.dart';
import '../widgets/bills_tab_view.dart';
import '../widgets/goals_tab_view.dart';
import '../widgets/salary_cycle_card.dart';

class BudgetPlanningScreen extends ConsumerWidget {
  const BudgetPlanningScreen({super.key});

  Future<void> _showEditCategoryDialog(
      BuildContext context, WidgetRef ref, CategoryBudget cat) async {
    final controller = TextEditingController(
        text: cat.allocatedAmount.toInt().toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Điều Chỉnh Ngân Sách "${cat.name}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CurrencyTextField(
                controller: controller,
                labelText: 'Hạn mức ngân sách',
              ),
              const SizedBox(height: 8),
              Text(
                'Đã chi ${_money(cat.spentAmount)} ₫ • '
                'Còn lại ${_money(cat.remainingAmount)} ₫',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = CurrencyTextField.getRawAmount(controller);
                Navigator.pop(context, amount > 0);
              },
              child: const Text('Cập nhật'),
            ),
          ],
        );
      },
    );

    final amount = CurrencyTextField.getRawAmount(controller);
    controller.dispose();
    if (confirmed != true || !context.mounted) return;

    final error = await ref
        .read(budgetProvider.notifier)
        .updateCategoryAllocated(cat.id, amount);

    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.showError(context, error);
      return;
    }
    AppSnackBar.showSuccess(
        context, 'Đã cập nhật ngân sách cho "${cat.name}"!');
  }

  /// Xác nhận xóa một dòng ngân sách danh mục.
  Future<void> _confirmDeleteCategory(
      BuildContext context, WidgetRef ref, CategoryBudget cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa ngân sách?'),
        content: Text(
          'Xóa ngân sách "${cat.name}" khỏi kế hoạch chi tiêu?\n\n'
          'Số dư ví và các giao dịch đã ghi không bị ảnh hưởng.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await ref.read(budgetProvider.notifier).removeCategory(cat.id);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.showError(context, error);
      return;
    }
    AppSnackBar.showSuccess(context, 'Đã xóa ngân sách "${cat.name}"');
  }

  /// Quy trình tạo ngân sách: chọn danh mục → nhập hạn mức → lưu.
  ///
  /// Danh mục dùng lại đúng danh sách + icon của màn Thêm Giao Dịch
  /// (`DefaultCategories.expenseCategories`); backend tự map sang danh mục
  /// expense tương ứng nên không sinh danh mục mới.
  Future<void> _showAddCategoryDialog(
      BuildContext context, WidgetRef ref) async {
    final existingNames =
        ref.read(budgetProvider).categories.map((c) => c.name).toSet();
    final available = DefaultCategories.expenseCategories
        .where((c) => !existingNames.contains(c.name))
        .toList();

    if (available.isEmpty) {
      AppSnackBar.showWarning(
        context,
        'Mọi danh mục chi tiêu đã có ngân sách. Chỉnh hạn mức ở từng thẻ.',
      );
      return;
    }

    final nameController = TextEditingController();
    final amountController = TextEditingController();
    var selected = available.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Thêm Ngân Sách Danh Mục'),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              content: SizedBox(
                width: 340,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn danh mục',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final cat in available)
                            InkWell(
                              onTap: () => setLocal(() => selected = cat),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected.id == cat.id
                                      ? const Color(0xFF0F5B47)
                                      : const Color(0xFFEAF8F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      cat.icon,
                                      size: 16,
                                      color: selected.id == cat.id
                                          ? Colors.white
                                          : cat.color,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: selected.id == cat.id
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CurrencyTextField(
                        controller: amountController,
                        labelText: 'Hạn mức cho ${selected.name}',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5B47),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final amount =
                        CurrencyTextField.getRawAmount(amountController);
                    Navigator.pop(ctx, amount > 0);
                  },
                  child: const Text('Lưu ngân sách'),
                ),
              ],
            );
          },
        );
      },
    );

    final name = selected.name;
    final amount = CurrencyTextField.getRawAmount(amountController);
    nameController.dispose();
    amountController.dispose();
    if (confirmed != true || !context.mounted) return;

    final error = await ref
        .read(budgetProvider.notifier)
        .addCategory(name: name, amount: amount);

    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.showError(context, error);
      return;
    }
    AppSnackBar.showSuccess(context, 'Đã thêm ngân sách cho "$name"!');
  }

  /// Chọn ngưỡng cảnh báo cho cả kỳ ngân sách.
  Future<void> _showWarningThresholdDialog(
      BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(budgetProvider.notifier);
    final current = ref.read(budgetProvider).planWarningPercent;
    var selected = current;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Ngưỡng cảnh báo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ví An cảnh báo khi chi tiêu chạm ngưỡng này của hạn mức.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in [50, 70, 80, 90, 100])
                    InkWell(
                      onTap: () => setLocal(() => selected = p),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: selected == p
                              ? const Color(0xFF0F5B47)
                              : const Color(0xFFEAF8F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$p%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: selected == p
                                ? Colors.white
                                : const Color(0xFF0F5B47),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await notifier.setWarningPercent(selected);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.showError(context, error);
      return;
    }
    AppSnackBar.showSuccess(context, 'Đã đặt ngưỡng cảnh báo $selected%');
  }

  static String _money(double v) {
    final s = v.abs().toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
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
            // "Còn để chi" ưu tiên available từ backend (đã trừ quỹ bảo vệ
            // và hóa đơn chưa trả); tạo ngân sách KHÔNG trừ vào con số này.
            BudgetSummaryOverviewCard(
              freeRemaining: state.spendableNow,
              totalBudget: state.totalBudget,
              totalSpent: state.totalSpent,
              spentPercentage: state.spentPercentage,
              dailyLimit: state.dailyLimit,
              statusText: state.cycleStatus,
            ),
            const SizedBox(height: 16),

            // ── Nội dung theo tab ────────────────────────────────
            if (state.activeTab == 'Mục tiêu')
              const GoalsTabView()
            else if (state.activeTab == 'Hóa đơn')
              const BillsTabView()
            else ...[
              // Section Header: Danh mục chi tiêu + ngưỡng cảnh báo
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
                  InkWell(
                    onTap: () => _showWarningThresholdDialog(context, ref),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_active_outlined,
                              size: 12, color: Color(0xFF0F5B47)),
                          const SizedBox(width: 4),
                          Text(
                            'Cảnh báo ${state.planWarningPercent}%',
                            style: const TextStyle(
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
              const SizedBox(height: 10),

              if (state.categories.isEmpty)
                _EmptyBudgetHint(
                  onCreate: () => _showAddCategoryDialog(context, ref),
                )
              else ...[
                for (final cat in state.categories)
                  BudgetCategoryCard(
                    category: cat,
                    onEditPressed: () =>
                        _showEditCategoryDialog(context, ref, cat),
                    onDeletePressed: () =>
                        _confirmDeleteCategory(context, ref, cat),
                  ),
                // Add Category Button
                AddCategoryButton(
                  onPressed: () => _showAddCategoryDialog(context, ref),
                ),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: const BudgetBottomNav(),
    );
  }
}

/// Trạng thái rỗng: hướng dẫn tạo ngân sách đầu tiên.
class _EmptyBudgetHint extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyBudgetHint({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.savings_outlined,
              size: 34, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 8),
          const Text(
            'Chưa có ngân sách nào',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Đặt hạn mức theo danh mục để Ví An theo dõi chi tiêu và cảnh báo '
            'khi sắp chạm ngưỡng. Tạo ngân sách không trừ tiền trong ví.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Tạo ngân sách đầu tiên'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F5B47),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
