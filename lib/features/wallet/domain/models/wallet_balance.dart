class WalletBalance {
  final double currentBalance;
  final double monthlyBudget;
  final double monthlySpent;

  const WalletBalance({
    required this.currentBalance,
    required this.monthlyBudget,
    required this.monthlySpent,
  });

  double get remainingBudget => monthlyBudget - monthlySpent;
  double get spentPercentage =>
      monthlyBudget > 0 ? (monthlySpent / monthlyBudget) * 100 : 0;

  WalletBalance copyWith({
    double? currentBalance,
    double? monthlyBudget,
    double? monthlySpent,
  }) {
    return WalletBalance(
      currentBalance: currentBalance ?? this.currentBalance,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      monthlySpent: monthlySpent ?? this.monthlySpent,
    );
  }
}
