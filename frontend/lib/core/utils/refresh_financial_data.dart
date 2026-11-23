import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/presentation/providers/home_provider.dart';
import '../../features/notifications/presentation/providers/timeline_provider.dart';
import '../../features/report/presentation/providers/report_provider.dart';
import '../../features/settings/presentation/providers/budget_provider.dart';
import '../../features/transaction/providers/transaction_provider.dart';

// ═══════════════════════════════════════════════════════════════════
// Targeted Refresh — chỉ reload đúng những gì thay đổi
// ═══════════════════════════════════════════════════════════════════

/// Giao dịch mới (tạo/sửa/hủy): ảnh hưởng số dư ví, danh sách giao dịch,
/// báo cáo thu chi, kỳ ngân sách và chiêm nghiệm tuần. KHÔNG reload goals, bills.
void invalidateFinancialData(Ref ref) {
  // Chỉ force-reload những provider thực sự thay đổi:
  ref.read(homeProvider.notifier).loadDashboard(force: true);      // số dư, hóa đơn ở dashboard
  ref.read(reportProvider.notifier).loadTransactions(force: true); // danh sách giao dịch báo cáo
  ref.read(transactionProvider.notifier).loadTransactions();       // danh sách giao dịch chính
  ref.read(budgetProvider.notifier).loadBudgetsOnly();             // chỉ cập nhật số đã chi của ngân sách
  ref.read(timelineProvider.notifier).loadAll();                   // cập nhật tổng chi và chiêm nghiệm tuần
}

/// Bản dùng được từ Widget/WidgetRef (gọi từ UI layer)
void invalidateFinancialDataFromWidget(WidgetRef ref) {
  ref.read(homeProvider.notifier).loadDashboard(force: true);
  ref.read(reportProvider.notifier).loadTransactions(force: true);
  ref.read(transactionProvider.notifier).loadTransactions();
  ref.read(budgetProvider.notifier).loadBudgetsOnly();
  ref.read(timelineProvider.notifier).loadAll();
}

/// Chỉ cập nhật số dư ví — không cần reload giao dịch hay báo cáo.
/// Dùng sau: đổi ngày lương, cài đặt ví, phân bổ mục tiêu.
void invalidateBalanceOnly(Ref ref) {
  ref.read(homeProvider.notifier).loadDashboard(force: true);
  ref.invalidate(budgetProvider);
}

/// Cập nhật số dư ví (WidgetRef)
void invalidateBalanceOnlyFromWidget(WidgetRef ref) {
  ref.read(homeProvider.notifier).loadDashboard(force: true);
  ref.invalidate(budgetProvider);
}
