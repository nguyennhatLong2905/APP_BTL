import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/category_budget.dart';

class BudgetState {
  final double totalBudget;
  final double totalSpent;
  final int daysLeft;
  final String periodText;
  final String cycleStatus;
  final String activeTab; // 'Ngân sách', 'Mục tiêu', 'Hóa đơn'
  final String filterMode; // 'Chu kỳ lương', 'Theo tháng'
  final List<CategoryBudget> categories;

  const BudgetState({
    this.totalBudget = 5500000,
    this.totalSpent = 3400000,
    this.daysLeft = 14,
    this.periodText = '16/09 – 16/10/2026 (còn nửa chặng đường)',
    this.cycleStatus = 'Rất an tâm',
    this.activeTab = 'Ngân sách',
    this.filterMode = 'Chu kỳ lương',
    this.categories = const [
      CategoryBudget(
        id: 'food',
        name: 'Ăn uống',
        icon: Icons.restaurant,
        iconBgColor: Color(0xFFE2F6F0),
        allocatedAmount: 2500000,
        spentAmount: 1850000,
      ),
      CategoryBudget(
        id: 'transport',
        name: 'Đi lại',
        icon: Icons.directions_car,
        iconBgColor: Color(0xFFE2F6F0),
        allocatedAmount: 600000,
        spentAmount: 420000,
      ),
      CategoryBudget(
        id: 'shopping',
        name: 'Mua sắm cá nhân',
        icon: Icons.shopping_bag_outlined,
        iconBgColor: Color(0xFFFFEAD5),
        allocatedAmount: 1000000,
        spentAmount: 880000,
        warningMessage: 'Gần chạm mức: còn 120.000 ₫ cho 14 ngày',
      ),
      CategoryBudget(
        id: 'others',
        name: 'Sinh hoạt & Khác',
        icon: Icons.tune,
        iconBgColor: Color(0xFFE2F6F0),
        allocatedAmount: 1400000,
        spentAmount: 250000,
      ),
    ],
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
    );
  }
}

class BudgetNotifier extends Notifier<BudgetState> {
  @override
  BudgetState build() {
    return const BudgetState();
  }

  void setActiveTab(String tab) {
    state = state.copyWith(activeTab: tab);
  }

  void setFilterMode(String mode) {
    state = state.copyWith(filterMode: mode);
  }

  void updateCategoryAllocated(String id, double newAmount) {
    final updated = state.categories.map((cat) {
      if (cat.id == id) {
        return cat.copyWith(allocatedAmount: newAmount);
      }
      return cat;
    }).toList();

    double newTotalBudget = 0;
    for (final c in updated) {
      newTotalBudget += c.allocatedAmount;
    }

    state = state.copyWith(
      categories: updated,
      totalBudget: newTotalBudget,
    );
  }

  void addCategory(CategoryBudget category) {
    final updated = [...state.categories, category];
    state = state.copyWith(categories: updated);
  }
}

final budgetProvider = NotifierProvider<BudgetNotifier, BudgetState>(
  BudgetNotifier.new,
);
