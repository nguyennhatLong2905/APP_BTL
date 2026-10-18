import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/report_data.dart';

// ════════════════════════════════════════════════════════════════════
// State – Report Provider
// ════════════════════════════════════════════════════════════════════

class ReportState {
  final PeriodFilter selectedPeriod;
  final String selectedWallet;
  final String searchQuery;

  const ReportState({
    this.selectedPeriod = PeriodFilter.month,
    this.selectedWallet = 'Tất cả ví',
    this.searchQuery = '',
  });

  ReportState copyWith({
    PeriodFilter? selectedPeriod,
    String? selectedWallet,
    String? searchQuery,
  }) {
    return ReportState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      selectedWallet: selectedWallet ?? this.selectedWallet,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Mock Data
// ════════════════════════════════════════════════════════════════════

final _mockTransactions = <ReportTransaction>[
  // Hôm nay 02/10
  ReportTransaction(
    id: '1',
    title: 'Cà phê sáng',
    category: 'Ăn uống',
    categoryIcon: '☕',
    amount: -45000,
    dateTime: DateTime(2026, 10, 2, 8, 30),
    type: TransactionType.expense,
    walletLabel: 'Ví tiền mặt',
    typeLabel: 'Chi tiêu',
  ),
  ReportTransaction(
    id: '2',
    title: 'Cơm trưa văn phòng',
    category: 'Ăn uống',
    categoryIcon: '🍱',
    amount: -60000,
    dateTime: DateTime(2026, 10, 2, 12, 15),
    type: TransactionType.expense,
    walletLabel: 'Tài khoản thanh toán',
    typeLabel: 'Chi tiêu',
  ),
  ReportTransaction(
    id: '3',
    title: 'Đổ xăng xe máy',
    category: 'Di chuyển',
    categoryIcon: '⛽',
    amount: -70000,
    dateTime: DateTime(2026, 10, 2, 17, 45),
    type: TransactionType.expense,
    walletLabel: 'Ví tiền mặt',
    typeLabel: 'Chi tiêu',
  ),
  // Hôm qua 01/10
  ReportTransaction(
    id: '4',
    title: 'Tiền hoàn cashback',
    category: 'Thu nhập',
    categoryIcon: '💳',
    amount: 25000,
    dateTime: DateTime(2026, 10, 1, 10, 0),
    type: TransactionType.income,
    walletLabel: 'Tài khoản thanh toán',
    typeLabel: 'Thu nhập',
  ),
  ReportTransaction(
    id: '5',
    title: 'Chuyển tiền tiết kiệm',
    category: 'Chuyển tiền',
    categoryIcon: '↔',
    amount: -500000,
    dateTime: DateTime(2026, 10, 1, 15, 0),
    type: TransactionType.transfer,
    walletLabel: 'Ví liên kết',
    typeLabel: 'Chuyển tiền',
  ),
  // 30/09
  ReportTransaction(
    id: '6',
    title: 'Siêu thị VinMart',
    category: 'Mua sắm',
    categoryIcon: '🛒',
    amount: -250000,
    dateTime: DateTime(2026, 9, 30, 19, 0),
    type: TransactionType.expense,
    walletLabel: 'Tài khoản thanh toán',
    typeLabel: 'Chi tiêu',
  ),
  ReportTransaction(
    id: '7',
    title: 'Lương tháng 9',
    category: 'Thu nhập',
    categoryIcon: '💰',
    amount: 12000000,
    dateTime: DateTime(2026, 9, 30, 9, 0),
    type: TransactionType.income,
    walletLabel: 'Tài khoản thanh toán',
    typeLabel: 'Thu nhập',
  ),
];

// ════════════════════════════════════════════════════════════════════
// Notifier (Riverpod 3.x — dùng Notifier thay StateNotifier)
// ════════════════════════════════════════════════════════════════════

class ReportNotifier extends Notifier<ReportState> {
  @override
  ReportState build() => const ReportState();

  void setPeriod(PeriodFilter period) {
    state = state.copyWith(selectedPeriod: period);
  }

  void setWallet(String wallet) {
    state = state.copyWith(selectedWallet: wallet);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Lấy transactions đã lọc
  List<ReportTransaction> filteredTransactions() {
    var list = List<ReportTransaction>.from(_mockTransactions);
    final now = DateTime.now();

    switch (state.selectedPeriod) {
      case PeriodFilter.today:
        list = list
            .where((t) =>
                t.dateTime.year == now.year &&
                t.dateTime.month == now.month &&
                t.dateTime.day == now.day)
            .toList();
        break;
      case PeriodFilter.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        list = list.where((t) => t.dateTime.isAfter(weekStart)).toList();
        break;
      case PeriodFilter.month:
        list = list
            .where((t) =>
                t.dateTime.year == now.year &&
                t.dateTime.month == now.month)
            .toList();
        break;
    }

    if (state.selectedWallet != 'Tất cả ví') {
      if (state.selectedWallet == 'Ví tiền mặt') {
        list = list.where((t) => t.walletLabel == 'Ví tiền mặt').toList();
      } else if (state.selectedWallet == 'Tài khoản') {
        list = list.where((t) => t.walletLabel.startsWith('Tài khoản')).toList();
      } else if (state.selectedWallet == 'Ăn uống') {
        list = list.where((t) => t.category == 'Ăn uống').toList();
      }
    }

    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q))
          .toList();
    }

    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  /// Group theo ngày
  List<DailyGroup> dailyGroups() {
    final txList = filteredTransactions();
    final Map<String, List<ReportTransaction>> grouped = {};

    for (final tx in txList) {
      final key = '${tx.dateTime.year}-${tx.dateTime.month}-${tx.dateTime.day}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final groups = grouped.entries
        .map((e) => DailyGroup(date: e.value.first.dateTime, transactions: e.value))
        .toList();

    groups.sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  /// Tổng kết kỳ hiện tại
  ReportSummary summary() {
    final txList = filteredTransactions();
    double income = 0, expense = 0;
    for (final t in txList) {
      if (t.type == TransactionType.income) income += t.amount;
      if (t.type == TransactionType.expense) expense += t.amount.abs();
    }
    return ReportSummary(
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Provider (Riverpod 3.x — NotifierProvider)
// ════════════════════════════════════════════════════════════════════

final reportProvider = NotifierProvider<ReportNotifier, ReportState>(
  ReportNotifier.new,
);
