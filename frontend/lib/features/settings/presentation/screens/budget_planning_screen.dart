import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ui/finance_screen_style.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/currency_text_field.dart';
import '../../../transaction/domain/models/transaction_category.dart';
import '../../domain/models/category_budget.dart';
import '../providers/budget_provider.dart';
import '../widgets/budget_bottom_nav.dart';
import '../widgets/budget_category_card.dart';
import '../widgets/budget_control_tabs.dart';
import '../widgets/budget_summary_overview_card.dart';
import '../widgets/bills_tab_view.dart';
import '../widgets/goals_tab_view.dart';

class BudgetPlanningScreen extends ConsumerWidget {
  const BudgetPlanningScreen({super.key});

  Future<void> _showEditCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryBudget cat,
  ) async {
    final controller = TextEditingController(
      text: cat.allocatedAmount.toInt().toString(),
    );

    final route = DialogRoute<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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

    final confirmed = await Navigator.of(
      context,
      rootNavigator: true,
    ).push(route);
    final amount = CurrencyTextField.getRawAmount(controller);
    route.completed.whenComplete(controller.dispose);
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
      context,
      'Đã cập nhật ngân sách cho "${cat.name}"!',
    );
  }

  /// Xác nhận xóa một dòng ngân sách danh mục.
  Future<void> _confirmDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    CategoryBudget cat,
  ) async {
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

    final error = await ref
        .read(budgetProvider.notifier)
        .removeCategory(cat.id);
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
    BuildContext context,
    WidgetRef ref,
  ) async {
    final existingNames = ref
        .read(budgetProvider)
        .categories
        .map((c) => c.name)
        .toSet();
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

    final amountController = TextEditingController();
    var selected = available.first;

    final route = DialogRoute<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Thêm Ngân Sách Danh Mục'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
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
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected.id == cat.id
                                      ? FinanceScreenStyle.green
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
                    backgroundColor: FinanceScreenStyle.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final amount = CurrencyTextField.getRawAmount(
                      amountController,
                    );
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

    final confirmed = await Navigator.of(
      context,
      rootNavigator: true,
    ).push(route);
    final name = selected.name;
    final amount = CurrencyTextField.getRawAmount(amountController);
    route.completed.whenComplete(amountController.dispose);
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
    BuildContext context,
    WidgetRef ref,
  ) async {
    final notifier = ref.read(budgetProvider.notifier);
    final current = ref.read(budgetProvider).planWarningPercent;
    var selected = current;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: selected == p
                              ? FinanceScreenStyle.green
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
                                : FinanceScreenStyle.green,
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
      backgroundColor: FinanceScreenStyle.background,
      appBar: const FinanceScreenHeader(title: 'Kế hoạch chi tiêu'),
      body: Column(
        children: [
          BudgetControlTabs(
            activeTab: state.activeTab,
            onTabChanged: notifier.setActiveTab,
          ),
          Expanded(
            child: RefreshIndicator(
              color: FinanceScreenStyle.green,
              onRefresh: notifier.loadAll,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(13, 13, 13, 24),
                children: [
                  if (state.activeTab == 'Mục tiêu')
                    const GoalsTabView()
                  else if (state.activeTab == 'Hóa đơn')
                    const BillsTabView()
                  else ...[
                    BudgetSummaryOverviewCard(
                      state: state,
                      onPeriodChanged: notifier.setFilterMode,
                    ),
                    if (state.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: FinanceScreenStyle.green,
                          ),
                        ),
                      )
                    else if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Không tải được ngân sách. ${state.errorMessage}',
                        style: const TextStyle(
                          color: FinanceScreenStyle.danger,
                        ),
                      ),
                      TextButton(
                        onPressed: notifier.loadAll,
                        child: const Text('Thử lại'),
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Danh mục chi tiêu',
                              style: FinanceScreenStyle.heading,
                            ),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showWarningThresholdDialog(context, ref),
                            icon: const Icon(
                              Icons.notifications_outlined,
                              size: 17,
                            ),
                            label: Text(
                              'Cảnh báo ${state.planWarningPercent}%',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: FinanceScreenStyle.green,
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: FinanceScreenStyle.border,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FinanceCard(
                        padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (state.categories.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'Chưa có danh mục trong kỳ này.',
                                  style: FinanceScreenStyle.detail,
                                ),
                              )
                            else ...[
                              const Padding(
                                padding: EdgeInsets.only(right: 42),
                                child: Text(
                                  'Còn lại',
                                  textAlign: TextAlign.end,
                                  style: FinanceScreenStyle.strong,
                                ),
                              ),
                              for (final category in state.categories) ...[
                                BudgetCategoryCard(
                                  key: ValueKey(category.id),
                                  category: category,
                                  onEditPressed: () => _showEditCategoryDialog(
                                    context,
                                    ref,
                                    category,
                                  ),
                                  onDeletePressed: () => _confirmDeleteCategory(
                                    context,
                                    ref,
                                    category,
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  color: FinanceScreenStyle.border,
                                ),
                              ],
                            ],
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _showAddCategoryDialog(context, ref),
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Thêm danh mục'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: FinanceScreenStyle.green,
                                side: const BorderSide(
                                  color: FinanceScreenStyle.green,
                                ),
                                minimumSize: const Size.fromHeight(46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BudgetBottomNav(),
    );
  }
}
