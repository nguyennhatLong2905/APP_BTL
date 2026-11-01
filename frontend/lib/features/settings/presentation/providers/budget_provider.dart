import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/budget_remote_data_source.dart';
import '../../domain/models/category_budget.dart';

// ════════════════════════════════════════════════════════════════════
// State – Budget Provider (API-backed)
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
  });

  double get freeRemainingBalance => totalBudget - totalSpent;
  double get dailyLimit => daysLeft > 0 ? freeRemainingBalance / daysLeft : 0;
  int get spentPercentage =>
      totalBudget > 0 ? ((totalSpent / totalBudget) * 100).toInt() : 0;

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
        ds.getUpcomingBills(),
      ]);

      final plans = results[0] as Map<String, dynamic>;
      final budgets = (results[1] as List).cast<Map<String, dynamic>>();
      final goals = (results[2] as List).cast<Map<String, dynamic>>();
      final bills = (results[3] as List).cast<Map<String, dynamic>>();

      // Parse overview từ plans screen
      final overview = plans['overview'] as Map<String, dynamic>? ?? {};
      final totalBudget = _toDouble(overview['totalBudget'] ?? plans['totalBudget'] ?? 0);
      final totalSpent = _toDouble(overview['totalSpent'] ?? plans['totalSpent'] ?? 0);
      final daysLeft = (overview['daysLeft'] ?? plans['daysLeft'] ?? 0) as int;

      // Parse categories từ budgets list
      final cats = budgets.map(_parseCategoryBudget).toList();

      // Compute status
      final remaining = totalBudget - totalSpent;
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

  void updateCategoryAllocated(String id, double newAmount) {
    final updated = state.categories.map((cat) {
      if (cat.id == id) return cat.copyWith(allocatedAmount: newAmount);
      return cat;
    }).toList();

    final newTotal =
        updated.fold<double>(0, (sum, c) => sum + c.allocatedAmount);
    state = state.copyWith(categories: updated, totalBudget: newTotal);
  }

  void addCategory(CategoryBudget category) {
    state = state.copyWith(categories: [...state.categories, category]);
  }

  // ── Helpers ────────────────────────────────────────────────────────

  double _toDouble(dynamic v) {
    if (v is String) return double.tryParse(v) ?? 0;
    if (v is num) return v.toDouble();
    return 0;
  }

  CategoryBudget _parseCategoryBudget(Map<String, dynamic> raw) {
    final cat = raw['category'] as Map<String, dynamic>?;
    final name = cat?['name'] as String? ?? raw['name'] as String? ?? 'Khác';
    final limitAmount = _toDouble(raw['limitAmount'] ?? 0);
    final spentAmount = _toDouble(raw['spentAmount'] ?? 0);

    final isNear = limitAmount > 0 && (spentAmount / limitAmount) >= 0.8;
    final remaining = limitAmount - spentAmount;
    final daysLeft = state.daysLeft;
    final warning = isNear && daysLeft > 0
        ? 'Gần chạm mức: còn ${_fmt(remaining)} cho $daysLeft ngày'
        : null;

    return CategoryBudget(
      id: raw['_id'] as String? ?? raw['id'] as String? ?? name,
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
// Provider
// ════════════════════════════════════════════════════════════════════

final budgetProvider = NotifierProvider<BudgetNotifier, BudgetState>(
  BudgetNotifier.new,
);
