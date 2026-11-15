import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/presentation/providers/home_provider.dart';
import '../../features/notifications/presentation/providers/timeline_provider.dart';
import '../../features/report/presentation/providers/report_provider.dart';
import '../../features/settings/presentation/providers/budget_provider.dart';

/// Làm mới toàn bộ dữ liệu phụ thuộc vào giao dịch.
///
/// Dùng `ref.container.read` để không bị ràng buộc dependency với origin provider,
/// tránh lỗi assertion: "A provider cannot depend on itself" khi hàm được gọi
/// từ bên trong Notifier (như BudgetNotifier hay ReportNotifier).
void invalidateFinancialData(Ref ref) {
  final container = ref.container;
  try {
    container.read(homeProvider.notifier).loadDashboard(force: true);
  } catch (_) {}
  try {
    container.read(budgetProvider.notifier).loadAll();
  } catch (_) {}
  try {
    container.read(reportProvider.notifier).loadTransactions(force: true);
  } catch (_) {}
  try {
    container.read(timelineProvider.notifier).loadAll();
  } catch (_) {}
}

/// Bản dùng được từ Widget/WidgetRef (Widget không có origin Provider nên luôn an toàn)
void invalidateFinancialDataFromWidget(WidgetRef ref) {
  try {
    ref.read(homeProvider.notifier).loadDashboard(force: true);
  } catch (_) {}
  try {
    ref.read(budgetProvider.notifier).loadAll();
  } catch (_) {}
  try {
    ref.read(reportProvider.notifier).loadTransactions(force: true);
  } catch (_) {}
  try {
    ref.read(timelineProvider.notifier).loadAll();
  } catch (_) {}
}
