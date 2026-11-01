/// Model cho một giao dịch
class Transaction {
  final String id;
  final String title;
  final String category;
  final double amount; // Âm = chi tiêu, Dương = thu nhập
  final DateTime date;
  final String? note;
  final TransactionIcon icon;

  const Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    required this.icon,
  });

  bool get isExpense => amount < 0;
  bool get isIncome => amount > 0;
}

/// Enum icon cho giao dịch
enum TransactionIcon {
  food,       // Ăn uống
  transport,  // Di chuyển
  shopping,   // Mua sắm
  health,     // Sức khỏe
  entertainment, // Giải trí
  salary,     // Lương
  transfer,   // Chuyển khoản
  other,      // Khác
}

/// Model cho dữ liệu chi tiêu theo tuần (dùng cho chart)
class WeeklySpending {
  final String dayLabel; // VD: "T2", "T3"...
  final double income;
  final double expense;

  const WeeklySpending({
    required this.dayLabel,
    required this.income,
    required this.expense,
  });
}

/// Model tổng hợp cho Dashboard
class DashboardData {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final List<Transaction> recentTransactions;
  final List<WeeklySpending> weeklyData;

  const DashboardData({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.recentTransactions,
    required this.weeklyData,
  });
}
