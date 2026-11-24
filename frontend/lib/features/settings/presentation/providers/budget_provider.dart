import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../report/presentation/providers/report_provider.dart';
import '../../../transaction/providers/transaction_provider.dart';
import '../../data/datasources/budget_remote_data_source.dart';
import '../../domain/models/category_budget.dart';
import '../../domain/models/recurring_bill.dart';
import '../../domain/models/savings_goal.dart';

// ════════════════════════════════════════════════════════════════════
// State – Budget Provider (API-backed, persist qua /budgets)
// ════════════════════════════════════════════════════════════════════

class BudgetState {
  final double totalBudget;
  final double totalSpent;
  final int daysLeft;
  final String periodText;
  final String cycleStatus;
  final String activeTab; // 'Ngân sách', 'Mục tiêu', 'Hóa đơn'
  final String filterMode; // 'Chu kỳ lương', 'Theo tháng'
  final List<CategoryBudget> categories;
  final bool isLoading;
  final String? errorMessage;

  // Raw data from API
  final List<Map<String, dynamic>> goals;
  final List<Map<String, dynamic>> upcomingBills;

  // Tổng quan tài chính (từ /screens/plans → overview)
  final double walletTotal;
  final double protectedMoney;
  final double unpaidBills;
  final double? availableToSpend;

  /// Mục tiêu tiết kiệm đã parse + ví để chọn khi phân bổ
  final List<SavingsGoal> savingsGoals;
  final List<GoalWalletOption> walletOptions;

  /// id bản ghi budget_plan đang dùng (null = chưa có kỳ ngân sách nào)
  final String? planId;
  final String? planName;
  final String? planPeriodType;
  final DateTime? planStartAt;
  final DateTime? planEndAt;

  /// Ngưỡng cảnh báo (%) của kỳ ngân sách, người dùng chọn (mặc định 80).
  final int planWarningPercent;

  /// Hóa đơn định kỳ
  final List<RecurringBill> bills;
  final BillsSummary billsSummary;
  final String billFilter; // 'Tất cả' | 'Chưa trả' | 'Đến hạn' | 'Quá hạn' | 'Đã trả'

  const BudgetState({
    this.totalBudget = 0,
    this.totalSpent = 0,
    this.daysLeft = 0,
    this.periodText = '--',
    this.cycleStatus = '--',
    this.activeTab = 'Ngân sách',
    this.filterMode = 'Chu kỳ lương',
    this.categories = const [],
    this.isLoading = false,
    this.errorMessage,
    this.goals = const [],
    this.upcomingBills = const [],
    this.walletTotal = 0,
    this.protectedMoney = 0,
    this.unpaidBills = 0,
    this.availableToSpend,
    this.savingsGoals = const [],
    this.walletOptions = const [],
    this.planId,
    this.planName,
    this.planPeriodType,
    this.planStartAt,
    this.planEndAt,
    this.planWarningPercent = 80,
    this.bills = const [],
    this.billsSummary = const BillsSummary(),
    this.billFilter = 'Tất cả',
  });

  double get freeRemainingBalance => totalBudget - totalSpent;
  double get dailyLimit => daysLeft > 0 ? freeRemainingBalance / daysLeft : 0;
  int get spentPercentage =>
      totalBudget > 0 ? ((totalSpent / totalBudget) * 100).toInt() : 0;

  /// "Còn để chi" thực tế = available từ backend
  /// (= tổng tiền ví − tiền bảo vệ − hóa đơn chưa trả)
  double get spendableNow => availableToSpend ?? freeRemainingBalance;

  BudgetState copyWith({
    double? totalBudget,
    double? totalSpent,
    int? daysLeft,
    String? periodText,
    String? cycleStatus,
    String? activeTab,
    String? filterMode,
    List<CategoryBudget>? categories,
    bool? isLoading,
    String? errorMessage,
    List<Map<String, dynamic>>? goals,
    List<Map<String, dynamic>>? upcomingBills,
    double? walletTotal,
    double? protectedMoney,
    double? unpaidBills,
    double? availableToSpend,
    List<SavingsGoal>? savingsGoals,
    List<GoalWalletOption>? walletOptions,
    String? planId,
    String? planName,
    String? planPeriodType,
    DateTime? planStartAt,
    DateTime? planEndAt,
    int? planWarningPercent,
    List<RecurringBill>? bills,
    BillsSummary? billsSummary,
    String? billFilter,
  }) {
    return BudgetState(
      totalBudget: totalBudget ?? this.totalBudget,
      totalSpent: totalSpent ?? this.totalSpent,
      daysLeft: daysLeft ?? this.daysLeft,
      periodText: periodText ?? this.periodText,
      cycleStatus: cycleStatus ?? this.cycleStatus,
      activeTab: activeTab ?? this.activeTab,
      filterMode: filterMode ?? this.filterMode,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      goals: goals ?? this.goals,
      upcomingBills: upcomingBills ?? this.upcomingBills,
      walletTotal: walletTotal ?? this.walletTotal,
      protectedMoney: protectedMoney ?? this.protectedMoney,
      unpaidBills: unpaidBills ?? this.unpaidBills,
      availableToSpend: availableToSpend ?? this.availableToSpend,
      savingsGoals: savingsGoals ?? this.savingsGoals,
      walletOptions: walletOptions ?? this.walletOptions,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      planPeriodType: planPeriodType ?? this.planPeriodType,
      planStartAt: planStartAt ?? this.planStartAt,
      planEndAt: planEndAt ?? this.planEndAt,
      planWarningPercent: planWarningPercent ?? this.planWarningPercent,
      bills: bills ?? this.bills,
      billsSummary: billsSummary ?? this.billsSummary,
      billFilter: billFilter ?? this.billFilter,
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Notifier
// ════════════════════════════════════════════════════════════════════

class BudgetNotifier extends Notifier<BudgetState> {
  @override
  BudgetState build() {
    Future.microtask(loadAll);
    return const BudgetState(isLoading: true);
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      final results = await Future.wait([
        ds.getPlansScreen(),
        ds.getBudgets(),
        ds.getGoals(),
        ds.getBills(),
        ds.getBillsScreen(),
      ]);

      final plans = results[0] as Map<String, dynamic>;
      final budgets = (results[1] as List).cast<Map<String, dynamic>>();
      // 1 kỳ ngân sách active duy nhất (backend chặn chồng lấn)
      final activeBudgets = budgets.where((b) => b['status'] == 'active').toList();
      final plan = activeBudgets.isNotEmpty ? activeBudgets.first : (budgets.isNotEmpty ? budgets.first : null);

      final goals = (results[2] as List).cast<Map<String, dynamic>>();
      final bills = (results[3] as List).cast<Map<String, dynamic>>();
      final billsScreen = results[4] as Map<String, dynamic>;

      // Parse overview
      final overview = plans['overview'] as Map<String, dynamic>? ?? {};
      final daysLeft =
          ((overview['daysRemaining'] ?? overview['daysLeft'] ?? 0) as num)
              .toInt();

      // Tính periodText từ kỳ ngân sách (plan) hoặc mặc định theo tháng
      String periodText;
      if (plan != null) {
        final startAt = DateTime.tryParse(plan['startAt'] as String? ?? '');
        final endAt = DateTime.tryParse(plan['endAt'] as String? ?? '');
        final periodType = plan['periodType'] as String? ?? 'month';
        if (startAt != null && endAt != null) {
          final startLabel = '${startAt.toLocal().day.toString().padLeft(2, '0')}/${startAt.toLocal().month.toString().padLeft(2, '0')}';
          final endLabel = '${endAt.toLocal().day.toString().padLeft(2, '0')}/${endAt.toLocal().month.toString().padLeft(2, '0')}/${endAt.toLocal().year}';
          periodText = periodType == 'pay_cycle'
              ? 'Chu kỳ lương: $startLabel – $endLabel'
              : 'Tháng ${startAt.toLocal().month}/${startAt.toLocal().year}';
        } else {
          final now = DateTime.now();
          periodText = 'Tháng ${now.month}/${now.year}';
        }
      } else {
        // Chưa có kỳ ngân sách — hiển thị "Chưa thiết lập"
        final now = DateTime.now();
        periodText = 'Tháng ${now.month}/${now.year} (Chưa có ngân sách)';
      }

      // Ví từ overview để map tên + tính khả dụng khi phân bổ
      final rawWallets =
          (overview['wallets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final walletNames = {
        for (final w in rawWallets)
          w['_id'] as String: (w['name'] as String? ?? 'Ví'),
      };

      // Parse mục tiêu tiết kiệm
      final parsedGoals = goals.map((g) => _parseGoal(g, walletNames)).toList();

      // Ví khả dụng: trừ phần đã bị mục tiêu khác giữ
      final walletOptions = rawWallets.map((w) {
        final id = w['_id'] as String? ?? '';
        final reserved = parsedGoals.fold<double>(
          0,
          (s, g) => s + (g.allocationIn(id) ?? 0),
        );
        return GoalWalletOption(
          id: id,
          name: w['name'] as String? ?? 'Ví',
          type: w['type'] as String? ?? 'cash',
          balance: _toDouble(w['balance']),
          reservedByOthers: reserved,
        );
      }).toList();

      // Parse limits của kỳ ngân sách + map tên danh mục
      final categoriesApi =
          (plans['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final nameById = {
        for (final c in categoriesApi)
          c['_id'] as String: (c['name'] as String? ?? 'Khác'),
      };

      final limits =
          (plan?['limits'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final warningPercent =
          ((plan?['warningPercent'] as num?) ?? 80).toInt();
      final cats = limits
          .map((l) => _parseLimit(l, nameById, daysLeft, warningPercent))
          .toList();

      final totalBudget = cats.fold<double>(0, (s, c) => s + c.allocatedAmount);
      final totalSpent = cats.fold<double>(0, (s, c) => s + c.spentAmount);

      final pct = totalBudget > 0 ? totalSpent / totalBudget : 0.0;
      final cycleStatus = pct < 0.6
          ? 'Rất an tâm'
          : pct < 0.8
              ? 'Cần chú ý'
              : 'Gần hết ngân sách';

      state = state.copyWith(
        isLoading: false,
        totalBudget: totalBudget,
        totalSpent: totalSpent,
        daysLeft: daysLeft,
        periodText: periodText,
        categories: cats,
        cycleStatus: cycleStatus,
        goals: goals,
        upcomingBills: bills,
        savingsGoals: parsedGoals.where((g) => g.isActive).toList(),
        walletOptions: walletOptions,
        walletTotal: _toDouble(overview['total']),
        protectedMoney: _toDouble(overview['protectedMoney']),
        unpaidBills: _toDouble(overview['unpaidBills']),
        availableToSpend: overview['available'] == null
            ? null
            : _toDouble(overview['available']),
        planId: plan?['_id'] as String?,
        planName: plan?['name'] as String?,
        planPeriodType: plan?['periodType'] as String?,
        planStartAt: DateTime.tryParse(plan?['startAt'] as String? ?? ''),
        planEndAt: DateTime.tryParse(plan?['endAt'] as String? ?? ''),
        planWarningPercent: warningPercent,
        bills: ((billsScreen['bills'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(RecurringBill.fromJson)
            .toList(),
        billsSummary: BillsSummary.fromJson(
          billsScreen['summary'] as Map<String, dynamic>?,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Chỉ tải lại ngân sách & số đã chi — không reload mục tiêu hay hóa đơn
  Future<void> loadBudgetsOnly() async {
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      final budgets = await ds.getBudgets();
      final activeBudgets = budgets.where((b) => b['status'] == 'active').toList();
      final plan = activeBudgets.isNotEmpty ? activeBudgets.first : (budgets.isNotEmpty ? budgets.first : null);
      if (plan == null) {
        state = state.copyWith(
          categories: const [],
          totalBudget: 0,
          totalSpent: 0,
          cycleStatus: '--',
          planId: null,
        );
        return;
      }
      final limits =
          (plan['limits'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final nameById = {
        for (final c in state.categories) c.id: c.name,
      };
      final warningPercent =
          ((plan['warningPercent'] as num?) ?? state.planWarningPercent).toInt();
      final cats = limits
          .map((l) => _parseLimit(l, nameById, state.daysLeft, warningPercent))
          .toList();

      final totalBudget = cats.fold<double>(0, (s, c) => s + c.allocatedAmount);
      final totalSpent = cats.fold<double>(0, (s, c) => s + c.spentAmount);

      final pct = totalBudget > 0 ? totalSpent / totalBudget : 0.0;
      final cycleStatus = pct < 0.6
          ? 'Rất an tâm'
          : pct < 0.8
              ? 'Cần chú ý'
              : 'Gần hết ngân sách';

      state = state.copyWith(
        categories: cats,
        totalBudget: totalBudget,
        totalSpent: totalSpent,
        cycleStatus: cycleStatus,
        planId: plan['_id'] as String?,
        planName: plan['name'] as String?,
        planPeriodType: plan['periodType'] as String?,
        planStartAt: DateTime.tryParse(plan['startAt'] as String? ?? ''),
        planEndAt: DateTime.tryParse(plan['endAt'] as String? ?? ''),
        planWarningPercent: warningPercent,
      );
    } catch (_) {}
  }

  /// Chỉ tải lại mục tiêu tiết kiệm — không reload ngân sách hay hóa đơn
  Future<void> loadGoalsOnly() async {
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      final goals = await ds.getGoals();
      final walletNames = {
        for (final w in state.walletOptions) w.id: w.name,
      };
      final parsedGoals = goals.map((g) => _parseGoal(g, walletNames)).toList();
      final activeGoals = parsedGoals.where((g) => g.isActive).toList();

      final updatedWalletOptions = state.walletOptions.map((w) {
        final reserved = activeGoals.fold<double>(
          0,
          (s, g) => s + (g.allocationIn(w.id) ?? 0),
        );
        return GoalWalletOption(
          id: w.id,
          name: w.name,
          type: w.type,
          balance: w.balance,
          reservedByOthers: reserved,
        );
      }).toList();

      final protectedMoney = activeGoals
          .where((g) => g.protect)
          .fold<double>(0, (s, g) => s + g.allocated);

      final available = state.walletTotal > 0
          ? state.walletTotal - protectedMoney - state.unpaidBills
          : state.availableToSpend;

      state = state.copyWith(
        goals: goals,
        savingsGoals: activeGoals,
        walletOptions: updatedWalletOptions,
        protectedMoney: protectedMoney,
        availableToSpend: available,
      );
    } catch (_) {}
  }

  /// Chỉ tải lại danh sách hóa đơn — không reload ngân sách hay mục tiêu
  Future<void> loadBillsOnly() async {
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      final results = await Future.wait([
        ds.getBills(),
        ds.getBillsScreen(),
      ]);
      final upcomingBills = (results[0] as List).cast<Map<String, dynamic>>();
      final billsScreen = results[1] as Map<String, dynamic>;

      final bills = ((billsScreen['bills'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(RecurringBill.fromJson)
          .toList();
      final summary = BillsSummary.fromJson(
        billsScreen['summary'] as Map<String, dynamic>?,
      );

      final unpaid = bills
          .where((b) => b.status.isUnpaid)
          .fold<double>(0, (s, b) => s + b.amount);

      final available = state.walletTotal > 0
          ? state.walletTotal - state.protectedMoney - unpaid
          : state.availableToSpend;

      state = state.copyWith(
        upcomingBills: upcomingBills,
        bills: bills,
        billsSummary: summary,
        unpaidBills: unpaid,
        availableToSpend: available,
      );
    } catch (_) {}
  }

  void setActiveTab(String tab) => state = state.copyWith(activeTab: tab);
  void setFilterMode(String mode) => state = state.copyWith(filterMode: mode);

  /// Ngưỡng cảnh báo của kỳ ngân sách (%), lưu ngay lên backend.
  Future<String?> setWarningPercent(int percent) async {
    final clamped = percent.clamp(1, 100).toInt();
    state = state.copyWith(planWarningPercent: clamped);
    if (state.planId == null) return null; // sẽ dùng khi tạo kỳ đầu tiên
    return _saveToServer(state.categories);
  }

  /// Xóa một dòng ngân sách danh mục (đặt hạn mức về 0).
  Future<String?> removeCategory(String id) async {
    final updated =
        state.categories.where((c) => c.id != id).toList(growable: false);
    if (updated.isEmpty) {
      // Không còn danh mục nào: xóa hẳn kỳ ngân sách.
      return deleteBudget();
    }
    state = state.copyWith(
      categories: updated,
      totalBudget: updated.fold<double>(0, (s, c) => s + c.allocatedAmount),
    );
    return _saveToServer(updated);
  }

  /// Xóa kỳ ngân sách hiện tại. Chỉ xóa kế hoạch chi tiêu — không đụng số dư
  /// ví, quỹ bảo vệ, hóa đơn hay giao dịch.
  Future<String?> deleteBudget() async {
    final id = state.planId;
    if (id == null) return null;
    try {
      await ref.read(budgetRemoteDataSourceProvider).deleteBudget(id);
      await loadBudgetsOnly();
      return null;
    } catch (e) {
      await loadBudgetsOnly();
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Đổi hạn mức của 1 danh mục và lưu ngay lên backend
  Future<String?> updateCategoryAllocated(String id, double newAmount) async {
    final updated = state.categories.map((cat) {
      if (cat.id == id) {
        return cat.copyWith(
          allocatedAmount: newAmount,
          warningMessage: _buildWarning(newAmount, cat.spentAmount),
        );
      }
      return cat;
    }).toList();

    // Optimistic UI, sẽ được đồng bộ lại từ server sau khi lưu
    state = state.copyWith(
      categories: updated,
      totalBudget: updated.fold<double>(0, (s, c) => s + c.allocatedAmount),
    );

    return _saveToServer(updated);
  }

  /// Thêm danh mục ngân sách mới (tạo category + thêm limit nếu cần)
  Future<String?> addCategory({
    required String name,
    required double amount,
  }) async {
    final ds = ref.read(budgetRemoteDataSourceProvider);
    try {
      // 1. Tìm danh mục chi có sẵn trùng tên → dùng lại, tránh trùng lặp
      final existing = await ds.getCategories();
      final matched = existing.firstWhere(
        (c) =>
            (c['name'] as String?)?.toLowerCase().trim() ==
                name.toLowerCase().trim() &&
            c['kind'] == 'expense',
        orElse: () => <String, dynamic>{},
      );

      String categoryId;
      if (matched.isNotEmpty) {
        categoryId = matched['_id'] as String;
      } else {
        // 2. Tạo danh mục chi mới trên server
        final created = await ds.createCategory(name: name, kind: 'expense');
        categoryId = created['_id'] as String;
      }

      // 3. Thêm limit vào kỳ ngân sách và lưu
      final updated = [
        ...state.categories,
        CategoryBudget(
          id: categoryId,
          name: name,
          icon: _iconForCategory(name),
          iconBgColor: _colorForCategory(name),
          allocatedAmount: amount,
          spentAmount: 0,
          warningMessage: _buildWarning(amount, 0),
        ),
      ];
      state = state.copyWith(
        categories: updated,
        totalBudget: updated.fold<double>(0, (s, c) => s + c.allocatedAmount),
      );

      final err = await _saveToServer(updated);
      if (err != null) return err;
      await loadBudgetsOnly(); // đồng bộ id/version mới từ server
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  // ── Mục tiêu tiết kiệm ─────────────────────────────────────────────

  /// Tạo mục tiêu mới. targetAt: null = không đặt hạn.
  Future<String?> createGoal({
    required String name,
    required double targetAmount,
    DateTime? targetAt,
    bool protect = true,
  }) async {
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      final data = <String, dynamic>{
        'name': name,
        'targetAmount': targetAmount.toInt().toString(),
        'protect': protect,
      };
      if (targetAt != null) data['targetAt'] = _iso(targetAt);
      await ds.createGoalRaw(data);
      await _reloadAfterGoalChange();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Sửa mục tiêu (tên, số tiền đích, hạn, bảo vệ)
  Future<String?> updateGoal(
    String goalId, {
    String? name,
    double? targetAmount,
    DateTime? targetAt,
    bool? protect,
  }) async {
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (targetAmount != null) {
        data['targetAmount'] = targetAmount.toInt().toString();
      }
      if (targetAt != null) data['targetAt'] = _iso(targetAt);
      if (protect != null) data['protect'] = protect;
      if (data.isEmpty) return null;
      await ds.updateGoalPatch(goalId, data);
      await _reloadAfterGoalChange();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Bật/tắt bảo vệ cho mục tiêu
  Future<String?> setGoalProtection(String goalId, bool protect) =>
      updateGoal(goalId, protect: protect);

  /// Gán tiền trong ví cho mục tiêu (KHÔNG đổi tổng tiền, chỉ đổi tiền bảo vệ)
  Future<String?> setGoalAllocation({
    required String goalId,
    required String walletId,
    required double amount,
  }) async {
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      await ds.setGoalAllocation(
        goalId: goalId,
        walletId: walletId,
        amount: amount.toInt().toString(),
      );
      await _reloadAfterGoalChange();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Preview tác động lên "Còn để chi" nếu đổi phân bổ / bảo vệ.
  /// Dương = Còn để chi tăng, âm = giảm.
  ///
  /// Chỉ tính phần chênh lệch tiền bảo vệ; một khoản tiền chỉ được bảo vệ
  /// một lần vì protectedMoney của backend cộng allocation của goal protect=true.
  GoalImpactPreview previewGoalImpact({
    required SavingsGoal goal,
    required double newAllocatedTotal,
    required bool newProtect,
  }) {
    final oldProtected = goal.protect ? goal.allocated : 0.0;
    final newProtected = newProtect ? newAllocatedTotal : 0.0;
    final deltaProtected = newProtected - oldProtected;

    final before = state.spendableNow;
    final after = before - deltaProtected;

    return GoalImpactPreview(
      before: before,
      after: after,
      change: -deltaProtected,
      protectedBefore: state.protectedMoney,
      protectedAfter: state.protectedMoney + deltaProtected,
    );
  }

  /// Ví có thể phân bổ cho mục tiêu (trừ phần các mục tiêu khác đã giữ)
  List<GoalWalletOption> walletsForGoal(String goalId) {
    return state.walletOptions.map((w) {
      final goal = state.savingsGoals.firstWhere(
        (g) => g.id == goalId,
        orElse: () => SavingsGoal(
            id: '', name: '', targetAmount: 0, allocations: const []),
      );
      // Phần ví này đã bị mục tiêu này giữ (được phép sửa)
      final own = goal.allocationIn(w.id) ?? 0;
      return GoalWalletOption(
        id: w.id,
        name: w.name,
        type: w.type,
        balance: w.balance,
        // reservedByOthers gồm cả chính goal này → bỏ ra để không chặn sửa
        reservedByOthers: (w.reservedByOthers - own).clamp(0, double.infinity),
      );
    }).toList();
  }

  // ── Hóa đơn định kỳ ────────────────────────────────────────────────

  void setBillFilter(String filter) => state = state.copyWith(billFilter: filter);

  /// Danh sách hóa đơn theo bộ lọc trạng thái đang chọn.
  List<RecurringBill> get filteredBills {
    switch (state.billFilter) {
      case 'Chưa trả':
        return state.bills.where((b) => b.status.isUnpaid).toList();
      case 'Đến hạn':
        return state.bills.where((b) => b.status == BillStatus.due).toList();
      case 'Quá hạn':
        return state.bills.where((b) => b.status == BillStatus.overdue).toList();
      case 'Đã trả':
        return state.bills.where((b) => b.status == BillStatus.paid).toList();
      default:
        return state.bills;
    }
  }

  /// Tìm danh mục chi phù hợp từ tên gợi ý (tái sử dụng logic addCategory).
  Future<String> _resolveExpenseCategoryId(String name) async {
    final ds = ref.read(budgetRemoteDataSourceProvider);
    final existing = await ds.getCategories();
    final matched = existing.firstWhere(
      (c) =>
          (c['name'] as String?)?.toLowerCase().trim() ==
              name.toLowerCase().trim() &&
          c['kind'] == 'expense',
      orElse: () => <String, dynamic>{},
    );
    if (matched.isNotEmpty) return matched['_id'] as String;
    final created = await ds.createCategory(name: name, kind: 'expense');
    return created['_id'] as String;
  }

  /// Tạo hóa đơn định kỳ. Trả về thông báo lỗi hoặc null nếu thành công.
  Future<String?> createBill({
    required String name,
    required double amount,
    required DateTime dueDate,
    required BillFrequency frequency,
    DateTime? startAt,
    DateTime? endAt,
    String? note,
    int reminderDaysBefore = 3,
    String? categoryName,
  }) async {
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      final categoryId = await _resolveExpenseCategoryId(
        (categoryName == null || categoryName.trim().isEmpty)
            ? name
            : categoryName,
      );
      final start = startAt ?? dueDate;
      final data = <String, dynamic>{
        'name': name.trim(),
        'estimatedAmount': amount.toInt().toString(),
        'categoryId': categoryId,
        'frequency': frequency.apiValue,
        'startAt': _iso(start),
        'reminderDaysBefore': reminderDaysBefore,
      };
      if (endAt != null) data['endAt'] = _iso(endAt);
      if (note != null && note.trim().isNotEmpty) data['note'] = note.trim();
      if (state.walletOptions.isNotEmpty) {
        data['preferredWalletId'] = state.walletOptions.first.id;
      }
      await ds.createRecurringBill(data);
      await loadBillsOnly();
      ref.read(homeProvider.notifier).loadDashboard(force: true);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Cập nhật hóa đơn định kỳ.
  Future<String?> updateBill({
    required String id,
    String? name,
    double? amount,
    DateTime? dueDate,
    BillFrequency? frequency,
    DateTime? startAt,
    DateTime? endAt,
    bool clearEndAt = false,
    String? note,
    int? reminderDaysBefore,
    String? categoryName,
  }) async {
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name.trim();
      if (amount != null) data['estimatedAmount'] = amount.toInt().toString();
      if (frequency != null) data['frequency'] = frequency.apiValue;
      if (categoryName != null && categoryName.trim().isNotEmpty) {
        data['categoryId'] = await _resolveExpenseCategoryId(categoryName);
      }
      if (startAt != null || dueDate != null) {
        data['startAt'] = _iso(startAt ?? dueDate!);
      }
      if (clearEndAt) {
        // Backend dùng $set với endAt; gửi null để bỏ hạn.
        data['endAt'] = null;
      } else if (endAt != null) {
        data['endAt'] = _iso(endAt);
      }
      if (note != null) data['note'] = note.trim();
      if (reminderDaysBefore != null) {
        data['reminderDaysBefore'] = reminderDaysBefore;
      }
      if (data.isEmpty) return null;
      await ds.updateRecurringBill(id, data);
      await loadBillsOnly();
      ref.read(homeProvider.notifier).loadDashboard(force: true);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Xóa một kỳ hóa đơn chưa thanh toán.
  Future<String?> deleteBill(String billId) async {
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      await ds.deleteBill(billId);
      await loadBillsOnly();
      ref.read(homeProvider.notifier).loadDashboard(force: true);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Ngừng hóa đơn định kỳ (hủy các kỳ tương lai chưa trả).
  Future<String?> stopBillTemplate(String templateId) async {
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      await ds.stopRecurringBill(templateId);
      await loadBillsOnly();
      ref.read(homeProvider.notifier).loadDashboard(force: true);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Xem trước tác động thanh toán lên 3 lớp.
  Future<BillPayPreview?> previewBillPayment(
    String billId, {
    String? amount,
  }) async {
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      final data = await ds.previewBillPayment(billId, amount: amount);
      return BillPayPreview.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Lấy giao dịch chi có thể liên kết.
  Future<List<BillCandidateTransaction>> billCandidates(
    String billId, {
    String? search,
  }) async {
    final ds = ref.read(budgetRemoteDataSourceProvider);
    final rows = await ds.getBillCandidateTransactions(billId, search: search);
    return rows.map(BillCandidateTransaction.fromJson).toList();
  }

  /// Thanh toán hóa đơn bằng một giao dịch chi mới.
  Future<String?> settleBill({
    required String billId,
    required String walletId,
    required String occurredAt,
    String? amount,
    String? note,
    bool allowNegativeAvailable = false,
  }) async {
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      await ds.settleBill(
        id: billId,
        walletId: walletId,
        occurredAt: occurredAt,
        amount: amount,
        note: note,
        allowNegativeAvailable: allowNegativeAvailable,
      );
      await loadBillsOnly();
      await loadBudgetsOnly();
      ref.read(homeProvider.notifier).loadDashboard(force: true);
      ref.read(transactionProvider.notifier).loadTransactions();
      ref.read(reportProvider.notifier).loadTransactions(force: true);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Liên kết hóa đơn với giao dịch chi đã có (không tạo giao dịch mới).
  Future<String?> linkBillToTransaction({
    required String billId,
    required String transactionId,
    required int expectedVersion,
  }) async {
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      await ds.linkBill(billId: billId, transactionId: transactionId, expectedVersion: expectedVersion);
      await loadBillsOnly();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Mọi thay đổi mục tiêu (tạo/sửa/bảo vệ/phân bổ) chỉ ảnh hưởng quỹ bảo vệ,
  /// chỉ cần tải lại mục tiêu và cập nhật số dư khả dụng ở Dashboard.
  Future<void> _reloadAfterGoalChange() async {
    await loadGoalsOnly();
    ref.read(homeProvider.notifier).loadDashboard(force: true);
  }

  // ── Persist ────────────────────────────────────────────────────────

  /// Ghi toàn bộ danh mục ngân sách lên backend.
  /// Nếu chưa có kỳ ngân sách → tạo mới kỳ tháng hiện tại.
  Future<String?> _saveToServer(List<CategoryBudget> cats) async {
    final ds = ref.read(budgetRemoteDataSourceProvider);
    try {
      final limits = cats
          .where((c) => c.allocatedAmount > 0 && _looksLikeObjectId(c.id))
          .map((c) => {
                'categoryId': c.id,
                'limit': c.allocatedAmount.toInt().toString(),
              })
          .toList();

      if (limits.isEmpty) {
        return 'Cần ít nhất một danh mục có hạn mức lớn hơn 0';
      }

      if (state.planId == null) {
        final range = _currentMonthRange(state.filterMode);
        await ds.createBudget(
          name: 'Ngân sách tháng ${DateFormat('MM/yyyy').format(DateTime.now())}',
          periodType: state.filterMode == 'Chu kỳ lương' ? 'pay_cycle' : 'month',
          startAt: range.$1,
          endAt: range.$2,
          limits: limits,
          warningPercent: state.planWarningPercent,
        );
      } else {
        final start =
            state.planStartAt ?? DateTime.parse(_currentMonthRange('Theo tháng').$1);
        final end =
            state.planEndAt ?? DateTime.parse(_currentMonthRange('Theo tháng').$2);
        await ds.updateBudget(
          id: state.planId!,
          name: state.planName ??
              'Ngân sách tháng ${DateFormat('MM/yyyy').format(DateTime.now())}',
          periodType: state.planPeriodType ?? 'month',
          startAt: _iso(start),
          endAt: _iso(end),
          limits: limits,
          warningPercent: state.planWarningPercent,
        );
      }

      await loadBudgetsOnly();
      return null;
    } catch (e) {
      // Hoàn tác UI nếu lưu thất bại
      await loadBudgetsOnly();
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  (String, String) _currentMonthRange(String filterMode) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = start.month == 12
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);
    return (_iso(start), _iso(end));
  }

  String _iso(DateTime d) {
    final u = d.toUtc();
    String p(int v, int n) => v.toString().padLeft(n, '0');
    return '${p(u.year, 4)}-${p(u.month, 2)}-${p(u.day, 2)}'
        'T${p(u.hour, 2)}:${p(u.minute, 2)}:${p(u.second, 2)}.000Z';
  }

  bool _looksLikeObjectId(String v) => RegExp(r'^[0-9a-f]{24}$').hasMatch(v);

  // ── Helpers ────────────────────────────────────────────────────────

  double _toDouble(dynamic v) {
    if (v is String) return double.tryParse(v) ?? 0;
    if (v is num) return v.toDouble();
    return 0;
  }

  SavingsGoal _parseGoal(
    Map<String, dynamic> raw,
    Map<String, String> walletNames,
  ) {
    final allocations =
        (raw['allocations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return SavingsGoal(
      id: raw['_id'] as String? ?? '',
      name: raw['name'] as String? ?? 'Mục tiêu',
      targetAmount: _toDouble(raw['targetAmount']),
      targetAt: DateTime.tryParse(raw['targetAt'] as String? ?? ''),
      protect: raw['protect'] as bool? ?? false,
      status: raw['status'] as String? ?? 'active',
      allocations: allocations
          .map((a) => GoalAllocation(
                walletId: a['walletId'] as String? ?? '',
                walletName:
                    walletNames[a['walletId'] as String? ?? ''] ?? 'Ví',
                amount: _toDouble(a['amount']),
              ))
          .toList(),
    );
  }

  String? _buildWarning(double limit, double spent) {
    if (limit <= 0) return null;
    final pct = spent / limit;
    if (pct < 0.8) return null;
    final remaining = limit - spent;
    return 'Gần chạm mức: còn ${_fmt(remaining)}';
  }

  /// Parse một phần tử trong plan.limits: { categoryId, limit, spent, ... }
  CategoryBudget _parseLimit(
    Map<String, dynamic> raw,
    Map<String, String> nameById,
    int daysLeft,
    int warningPercent,
  ) {
    final categoryId =
        raw['categoryId'] as String? ?? raw['_id'] as String? ?? '';
    final name = nameById[categoryId] ?? (raw['name'] as String? ?? 'Khác');
    // Số đã chi lấy trực tiếp từ backend (tổng giao dịch chi thật trong kỳ).
    final limitAmount = _toDouble(raw['limit'] ?? raw['limitAmount'] ?? 0);
    final spentAmount = _toDouble(raw['spent'] ?? raw['spentAmount'] ?? 0);
    final percentRaw = raw['percent'];
    final percent = percentRaw is num
        ? percentRaw.round()
        : (limitAmount > 0
            ? ((spentAmount / limitAmount) * 100).round()
            : 0);
    final locked = raw['locked'] as bool? ?? spentAmount >= limitAmount;
    final remaining = limitAmount - spentAmount;

    String? warning;
    if (spentAmount > limitAmount) {
      warning = 'Đã vượt hạn mức ${_fmt(spentAmount - limitAmount)}';
    } else if (spentAmount >= limitAmount) {
      warning = 'Đã dùng hết hạn mức danh mục này';
    } else if (percent >= warningPercent) {
      warning = daysLeft > 0
          ? 'Sắp chạm ngưỡng $warningPercent%: còn ${_fmt(remaining)} cho $daysLeft ngày'
          : 'Sắp chạm ngưỡng $warningPercent%: còn ${_fmt(remaining)}';
    }

    return CategoryBudget(
      id: categoryId,
      name: name,
      icon: _iconForCategory(name),
      iconBgColor: _colorForCategory(name),
      allocatedAmount: limitAmount,
      spentAmount: spentAmount,
      warningMessage: warning,
      warningPercent: warningPercent,
      locked: locked,
      percent: percent,
    );
  }

  IconData _iconForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('ăn') || n.contains('food')) return Icons.restaurant;
    if (n.contains('đi') || n.contains('transport')) return Icons.directions_car;
    if (n.contains('mua') || n.contains('shop')) return Icons.shopping_bag_outlined;
    if (n.contains('học') || n.contains('edu')) return Icons.school_outlined;
    if (n.contains('giải') || n.contains('enter')) return Icons.movie_outlined;
    if (n.contains('sức') || n.contains('health')) return Icons.favorite_outline;
    return Icons.tune;
  }

  Color _colorForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('ăn') || n.contains('food')) return const Color(0xFFE2F6F0);
    if (n.contains('mua') || n.contains('shop')) return const Color(0xFFFFEAD5);
    if (n.contains('giải') || n.contains('enter')) return const Color(0xFFEAE5FF);
    return const Color(0xFFE2F6F0);
  }

  String _fmt(double v) {
    final i = v.abs().toInt().toString();
    final buf = StringBuffer();
    for (int j = 0; j < i.length; j++) {
      if (j > 0 && (i.length - j) % 3 == 0) buf.write('.');
      buf.write(i[j]);
    }
    return '${buf.toString()} ₫';
  }
}

// ════════════════════════════════════════════════════════════════════
// Preview tác động lên "Còn để chi"
// ════════════════════════════════════════════════════════════════════

class GoalImpactPreview {
  final double before;
  final double after;
  final double change; // > 0: Còn để chi tăng
  final double protectedBefore;
  final double protectedAfter;

  const GoalImpactPreview({
    required this.before,
    required this.after,
    required this.change,
    required this.protectedBefore,
    required this.protectedAfter,
  });

  bool get isIncrease => change > 0.5;
  bool get isDecrease => change < -0.5;
}

// ════════════════════════════════════════════════════════════════════
// Provider
// ════════════════════════════════════════════════════════════════════

final budgetProvider = NotifierProvider<BudgetNotifier, BudgetState>(
  BudgetNotifier.new,
);
