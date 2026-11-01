import 'category_budget.dart';

class Budget {
  final double monthlyBudget;
  final int month;
  final int year;
  final List<CategoryBudget> categories;

  const Budget({
    required this.monthlyBudget,
    required this.month,
    required this.year,
    required this.categories,
  });

  double get totalAllocated =>
      categories.fold(0, (sum, cat) => sum + cat.allocatedAmount);

  double get totalSpent =>
      categories.fold(0, (sum, cat) => sum + cat.spentAmount);

  double get remainingUnallocated => monthlyBudget - totalAllocated;

  bool get isOverAllocated => totalAllocated > monthlyBudget;

  Budget copyWith({
    double? monthlyBudget,
    int? month,
    int? year,
    List<CategoryBudget>? categories,
  }) {
    return Budget(
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      month: month ?? this.month,
      year: year ?? this.year,
      categories: categories ?? this.categories,
    );
  }
}
