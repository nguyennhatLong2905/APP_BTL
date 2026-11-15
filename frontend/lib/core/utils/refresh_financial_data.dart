import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/presentation/providers/home_provider.dart';
import '../../features/notifications/presentation/providers/timeline_provider.dart';
import '../../features/report/presentation/providers/report_provider.dart';
import '../../features/settings/presentation/providers/budget_provider.dart';

/// Làm mới toàn bộ dữ liệu phụ thuộc vào giao dịch.
///
/// Mỗi provider tự có cache riêng (home 30s, report 30s, budget theo API),
/// nên chỉ gọi load lại ở một màn hình sẽ khiến các màn khác hiển thị số cũ.
/// Gọi hàm này sau mọi thao tác ghi giao dịch: tạo, sửa, hủy.
void invalidateFinancialData(Ref ref) {
  // Dùng read().load...(force: true) thay vì invalidate
  // để reload ngay lập tức, không đợi màn hình rebuild
  ref.read(homeProvider.notifier).loadDashboard(force: true);
  ref.read(budgetProvider.notifier).loadAll();
  ref.read(reportProvider.notifier).loadTransactions(force: true);
  ref.read(timelineProvider.notifier).loadAll(); // Thêm timeline
}

/// Bản dùng được từ Widget/WidgetRef
void invalidateFinancialDataFromWidget(WidgetRef ref) {
  // Dùng read().load...(force: true) thay vì invalidate
  // để reload ngay lập tức, không đợi màn hình rebuild
  ref.read(homeProvider.notifier).loadDashboard(force: true);
  ref.read(budgetProvider.notifier).loadAll();
  ref.read(reportProvider.notifier).loadTransactions(force: true);
  ref.read(timelineProvider.notifier).loadAll(); // Thêm timeline
}
