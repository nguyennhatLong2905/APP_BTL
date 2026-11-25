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
  bool get showsCreditSign => icon != TransactionIcon.transfer;
}

/// Enum icon cho giao dịch
enum TransactionIcon {
  food, // Ăn uống
  transport, // Di chuyển
  shopping, // Mua sắm
  health, // Sức khỏe
  entertainment, // Giải trí
  salary, // Lương
  transfer, // Chuyển khoản
  other, // Khác
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

/// Số dư một ví — dùng hiển thị chi tiết Lớp 1.
class WalletBalance {
  final String id;
  final String name;
  final double balance;

  const WalletBalance({
    required this.id,
    required this.name,
    required this.balance,
  });
}

/// Model tổng hợp cho Dashboard
class DashboardData {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final double protectedMoney;
  final double unpaidBills;
  final double? available; // null khi chưa có ngày lương kế tiếp
  final double? spendableAmount;
  final double? shortfallAmount;
  final int? daysRemaining;
  final DateTime? nextPayday;
  final double? dailyReference;
  final List<Transaction> recentTransactions;
  final List<UpcomingBill> upcomingBills;
  final List<WeeklySpending> weeklyData;

  /// Chi tiết số dư từng ví đang hoạt động (Lớp 1).
  final List<WalletBalance> walletBreakdown;

  const DashboardData({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    this.protectedMoney = 0,
    this.unpaidBills = 0,
    this.available,
    this.spendableAmount,
    this.shortfallAmount,
    this.daysRemaining,
    this.nextPayday,
    this.dailyReference,
    required this.recentTransactions,
    this.upcomingBills = const [],
    required this.weeklyData,
    this.walletBreakdown = const [],
  });

  double get _netAvailable => available ?? (totalBalance - obligations);

  double get spendable =>
      spendableAmount ?? _netAvailable.clamp(0, double.infinity);

  double get shortfall =>
      shortfallAmount ?? (-_netAvailable).clamp(0, double.infinity);

  /// Số ví đang hoạt động.
  int get walletCount => walletBreakdown.length;

  /// Tổng của Lớp 2 = hóa đơn chưa trả + quỹ bảo vệ.
  double get obligations => protectedMoney + unpaidBills;

  /// Hạn mức mỗi ngày
  double get dailyLimit {
    final d = daysRemaining;
    if (d == null || d <= 0) return 0;
    return (dailyReference ?? spendable / d).clamp(0, double.infinity);
  }
}
