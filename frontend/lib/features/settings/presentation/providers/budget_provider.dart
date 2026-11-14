import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/datasources/budget_remote_data_source.dart';
import '../../domain/models/category_budget.dart';
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
      ]);

      final plans = results[0] as Map<String, dynamic>;
      final budgets = (results[1] as List).cast<Map<String, dynamic>>();
      // 1 kỳ ngân sách active duy nhất (backend chặn chồng lấn)
      final plan = budgets.isNotEmpty ? budgets.first : null;

      final goals = (results[2] as List).cast<Map<String, dynamic>>();
      final bills = (results[3] as List).cast<Map<String, dynamic>>();

      // Parse overview
      final overview = plans['overview'] as Map<String, dynamic>? ?? {};
      final daysLeft =
          ((overview['daysRemaining'] ?? overview['daysLeft'] ?? 0) as num)
              .toInt();

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
      final cats = limits
          .map((l) => _parseLimit(l, nameById, daysLeft))
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
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setActiveTab(String tab) => state = state.copyWith(activeTab: tab);
  void setFilterMode(String mode) => state = state.copyWith(filterMode: mode);

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
      await loadAll(); // đồng bộ id/version mới từ server
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
      await loadAll();
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
      await loadAll();
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
      await loadAll();
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
        );
      }

      await loadAll();
      return null;
    } catch (e) {
      // Hoàn tác UI nếu lưu thất bại
      await loadAll();
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
  ) {
    final categoryId =
        raw['categoryId'] as String? ?? raw['_id'] as String? ?? '';
    final name = nameById[categoryId] ?? (raw['name'] as String? ?? 'Khác');
    final limitAmount = _toDouble(raw['limit'] ?? raw['limitAmount'] ?? 0);
    final spentAmount =
        _toDouble(raw['spent'] ?? raw['spentAmount'] ?? 0);

    final isNear = limitAmount > 0 && (spentAmount / limitAmount) >= 0.8;
    final remaining = limitAmount - spentAmount;
    final warning = isNear && daysLeft > 0
        ? 'Gần chạm mức: còn ${_fmt(remaining)} cho $daysLeft ngày'
        : isNear
            ? 'Gần chạm mức: còn ${_fmt(remaining)}'
            : null;

    return CategoryBudget(
      id: categoryId,
      name: name,
      icon: _iconForCategory(name),
      iconBgColor: _colorForCategory(name),
      allocatedAmount: limitAmount,
      spentAmount: spentAmount,
      warningMessage: warning,
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
