import 'package:flutter_riverpod_clean_architecture/features/home/domain/models/dashboard_data.dart';

/// Mock data cho Dashboard - dùng tạm trong khi chưa có API
class MockHomeData {
  // Số dư tổng
  static const double mockBalance = 12_850_000;
  static const double mockTotalIncome = 18_000_000;
  static const double mockTotalExpense = 5_150_000;

  // 5 giao dịch gần nhất
  static final List<Transaction> mockTransactions = [
    Transaction(
      id: '1',
      title: 'Cà phê Highlands',
      category: 'Ăn uống',
      amount: -65000,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      note: 'Với nhóm bạn',
      icon: TransactionIcon.food,
    ),
    Transaction(
      id: '2',
      title: 'Lương tháng 10',
      category: 'Thu nhập',
      amount: 18000000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      icon: TransactionIcon.salary,
    ),
    Transaction(
      id: '3',
      title: 'Grab đi làm',
      category: 'Di chuyển',
      amount: -45000,
      date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      icon: TransactionIcon.transport,
    ),
    Transaction(
      id: '4',
      title: 'Shopee - Áo thun',
      category: 'Mua sắm',
      amount: -250000,
      date: DateTime.now().subtract(const Duration(days: 2)),
      note: 'Sale 11.11',
      icon: TransactionIcon.shopping,
    ),
    Transaction(
      id: '5',
      title: 'Khám bệnh định kỳ',
      category: 'Sức khỏe',
      amount: -150000,
      date: DateTime.now().subtract(const Duration(days: 3)),
      icon: TransactionIcon.health,
    ),
  ];

  // Dữ liệu chi tiêu theo tuần (cho biểu đồ)
  static const List<WeeklySpending> mockWeeklyData = [
    WeeklySpending(dayLabel: 'T2', income: 0, expense: 120000),
    WeeklySpending(dayLabel: 'T3', income: 0, expense: 85000),
    WeeklySpending(dayLabel: 'T4', income: 18000000, expense: 250000),
    WeeklySpending(dayLabel: 'T5', income: 0, expense: 65000),
    WeeklySpending(dayLabel: 'T6', income: 0, expense: 195000),
    WeeklySpending(dayLabel: 'T7', income: 0, expense: 380000),
    WeeklySpending(dayLabel: 'CN', income: 0, expense: 420000),
  ];

  static DashboardData get dashboardData => DashboardData(
        totalBalance: mockBalance,
        totalIncome: mockTotalIncome,
        totalExpense: mockTotalExpense,
        recentTransactions: mockTransactions,
        weeklyData: mockWeeklyData,
      );
}
