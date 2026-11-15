/// Ví (wallet) trong hệ thống
class Wallet {
  final String id;
  final String name;
  final String type; // 'cash', 'bank', 'e_wallet'
  final double balance;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });
}

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

/// Hóa đơn sắp tới (chưa trả)
class UpcomingBill {
  final String id;
  final String name;
  final double amount;
  final DateTime? dueAt;

  const UpcomingBill({
    required this.id,
    required this.name,
    required this.amount,
    this.dueAt,
  });

  /// Số ngày còn lại tới hạn
  int? get daysLeft {
    if (dueAt == null) return null;
    final d = dueAt!.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }
}

/// Model tổng hợp cho Dashboard
class DashboardData {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final double protectedMoney;
  final double unpaidBills;
  final double? available; // null khi chưa có ngày lương kế tiếp
  final double? dailyReference; // mức chi tham khảo mỗi ngày từ backend
  final int? daysRemaining;
  final DateTime? nextPayday;
  final List<Transaction> recentTransactions;
  final List<UpcomingBill> upcomingBills;
  final List<WeeklySpending> weeklyData;
  final List<Wallet> wallets; // Thêm danh sách ví

  const DashboardData({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    this.protectedMoney = 0,
    this.unpaidBills = 0,
    this.available,
    this.dailyReference,
    this.daysRemaining,
    this.nextPayday,
    required this.recentTransactions,
    this.upcomingBills = const [],
    required this.weeklyData,
    this.wallets = const [], // Mặc định empty list
  });

  /// Số tiền còn được chi = available (đã trừ bảo vệ + hóa đơn),
  /// fallback tự tính nếu backend không trả.
  double get spendable =>
      available ?? (totalBalance - protectedMoney - unpaidBills);

  /// Hạn mức mỗi ngày: ưu tiên dailyReference từ backend,
  /// fallback tự tính từ spendable / daysRemaining.
  double get dailyLimit {
    if (dailyReference != null) return dailyReference!.abs();
    final d = daysRemaining;
    if (d == null || d <= 0) return 0;
    return (spendable / d).clamp(0, double.infinity);
  }
}
