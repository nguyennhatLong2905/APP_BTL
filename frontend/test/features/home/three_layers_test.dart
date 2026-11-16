import 'package:flutter_riverpod_clean_architecture/features/home/domain/models/dashboard_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ba lớp tiền minh bạch phải suy ra từ dữ liệu dashboard thật, không hardcode.
void main() {
  DashboardData data({
    double total = 8000000,
    double protectedMoney = 2400000,
    double unpaidBills = 3500000,
    double? available,
    int? daysRemaining = 20,
  }) => DashboardData(
    totalBalance: total,
    totalIncome: 0,
    totalExpense: 0,
    protectedMoney: protectedMoney,
    unpaidBills: unpaidBills,
    available: available,
    daysRemaining: daysRemaining,
    recentTransactions: const [],
    weeklyData: const [],
    walletBreakdown: const [
      WalletBalance(id: 'w1', name: 'Ví tiền mặt', balance: 1200000),
      WalletBalance(id: 'w2', name: 'Tài khoản thanh toán', balance: 6800000),
    ],
  );

  group('3 lớp tiền – công thức', () {
    test('Lớp 3 = Lớp 1 − Lớp 2 khi backend trả available', () {
      final d = data(available: 2100000);
      expect(d.totalBalance, 8000000, reason: 'Lớp 1');
      expect(d.obligations, 5900000, reason: 'Lớp 2 = bảo vệ + hóa đơn');
      expect(d.spendable, 2100000, reason: 'Lớp 3');
      expect(d.dailyLimit, 105000);
    });

    test('fallback tự tính cùng công thức khi thiếu available', () {
      final d = data(available: null);
      expect(d.spendable, 8000000 - 2400000 - 3500000);
      expect(d.spendable, 2100000);
    });

    test('Lớp 1 lấy tổng số dư thật của từng ví', () {
      final d = data();
      final sum = d.walletBreakdown.fold<double>(0, (s, w) => s + w.balance);
      expect(sum, d.totalBalance);
      expect(d.walletCount, 2);
    });

    test('Lớp 2 phản ánh đúng hóa đơn và quỹ bảo vệ riêng biệt', () {
      final d = data(protectedMoney: 2400000, unpaidBills: 3500000);
      expect(d.protectedMoney, 2400000);
      expect(d.unpaidBills, 3500000);
      expect(d.obligations, 5900000);
    });

    test('không có ngày lương: dailyLimit = 0, không bịa số', () {
      final d = data(available: 2100000, daysRemaining: null);
      expect(d.dailyLimit, 0);
      expect(d.spendable, 2100000, reason: 'Lớp 3 vẫn tính được');
    });

    test('chi vượt khả năng: Lớp 3 âm được giữ nguyên', () {
      final d = data(
        total: 1000000,
        protectedMoney: 800000,
        unpaidBills: 500000,
        available: -300000,
      );
      expect(d.spendable, -300000);
    });

    test('số liệu thay đổi khi dữ liệu thật thay đổi (không hardcode)', () {
      final before = data(available: 2100000);
      final after = data(total: 7800000, available: 1900000);
      expect(before.spendable, isNot(after.spendable));
      expect(after.spendable, 1900000);
    });
  });
}
