import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/report_remote_data_source.dart';
import '../../domain/models/report_data.dart';

// ════════════════════════════════════════════════════════════════════
// State – Report Provider (API-backed)
// ════════════════════════════════════════════════════════════════════

class ReportState {
  final PeriodFilter selectedPeriod;
  final String selectedWallet;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  // Dữ liệu từ API
  final List<ReportTransaction> allTransactions;
  final double totalIncome;
  final double totalExpense;
  
  // Cache timestamp để tránh load lại liên tục
  final DateTime? lastLoadedAt;

  const ReportState({
    this.selectedPeriod = PeriodFilter.month,
    this.selectedWallet = 'Tất cả ví',
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.allTransactions = const [],
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.lastLoadedAt,
  });

  ReportState copyWith({
    PeriodFilter? selectedPeriod,
    String? selectedWallet,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    List<ReportTransaction>? allTransactions,
    double? totalIncome,
    double? totalExpense,
    DateTime? lastLoadedAt,
  }) {
    return ReportState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      selectedWallet: selectedWallet ?? this.selectedWallet,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      allTransactions: allTransactions ?? this.allTransactions,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      lastLoadedAt: lastLoadedAt ?? this.lastLoadedAt,
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Notifier (Riverpod 3.x — Notifier)
// ════════════════════════════════════════════════════════════════════

class ReportNotifier extends Notifier<ReportState> {
  @override
  ReportState build() {
    // Load ngay khi provider được tạo
    Future.microtask(() => loadTransactions());
    return const ReportState(isLoading: true);
  }

  Future<void> loadTransactions({bool force = false}) async {
    // Cache trong 30 giây - không load lại nếu dữ liệu còn mới
    if (!force && state.lastLoadedAt != null) {
      final age = DateTime.now().difference(state.lastLoadedAt!);
      if (age.inSeconds < 30 && state.allTransactions.isNotEmpty) {
        return; // Dùng cache
      }
    }
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ds = ref.read(reportRemoteDataSourceProvider);
      final now = DateTime.now();

      // Xác định startDate và endDate theo period
      String startDate, endDate;
      switch (state.selectedPeriod) {
        case PeriodFilter.today:
          startDate = _isoDate(now);
          endDate = _isoDate(now);
          break;
        case PeriodFilter.week:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          startDate = _isoDate(weekStart);
          endDate = _isoDate(now);
          break;
        case PeriodFilter.month:
          startDate = _isoDate(DateTime(now.year, now.month, 1));
          endDate = _isoDate(now);
          break;
      }

      final result = await ds.getTransactionHistory(
        startDate: startDate,
        endDate: endDate,
        limit: 100,
      );

      // Parse items từ backend
      final raw = result['items'] as List<dynamic>? ?? [];
      final txs = raw.map((e) => _parseTransaction(e as Map<String, dynamic>)).toList();

      // Tính tổng
      double income = 0, expense = 0;
      for (final t in txs) {
        if (t.type == TransactionType.income) income += t.amount.abs();
        if (t.type == TransactionType.expense) expense += t.amount.abs();
      }

      state = state.copyWith(
        isLoading: false,
        allTransactions: txs,
        totalIncome: income,
        totalExpense: expense,
        lastLoadedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setPeriod(PeriodFilter period) {
    state = state.copyWith(selectedPeriod: period);
    loadTransactions(force: true); // Force reload khi đổi period
  }

  void setWallet(String wallet) {
    state = state.copyWith(selectedWallet: wallet);
    // Không cần load lại - chỉ filter client-side
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Lấy transactions đã lọc (client-side filter cho wallet/search)
  List<ReportTransaction> filteredTransactions() {
    var list = List<ReportTransaction>.from(state.allTransactions);

    if (state.selectedWallet != 'Tất cả ví') {
      // So sánh chính xác tên ví, không dùng contains
      list = list
          .where((t) => t.walletLabel.trim() == state.selectedWallet.trim())
          .toList();
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
      final key =
          '${tx.dateTime.year}-${tx.dateTime.month}-${tx.dateTime.day}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final groups = grouped.entries
        .map((e) =>
            DailyGroup(date: e.value.first.dateTime, transactions: e.value))
        .toList();

    groups.sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  /// Tổng kết kỳ hiện tại
  ReportSummary summary() {
    return ReportSummary(
      totalIncome: state.totalIncome,
      totalExpense: state.totalExpense,
      balance: state.totalIncome - state.totalExpense,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  ReportTransaction _parseTransaction(Map<String, dynamic> raw) {
    final amountVnd = (raw['amountVnd'] ?? raw['amount'] ?? 0);
    final amount = amountVnd is String
        ? double.tryParse(amountVnd) ?? 0
        : (amountVnd as num).toDouble();
    final typeStr = raw['type'] as String? ?? 'expense';
    final txType = typeStr == 'income'
        ? TransactionType.income
        : typeStr == 'transfer'
            ? TransactionType.transfer
            : TransactionType.expense;

    // Sign convention: expense = negative
    final signedAmount =
        txType == TransactionType.expense ? -amount.abs() : amount.abs();

    final occurredAt = raw['occurredAt'] as String?;
    final dateTime = occurredAt != null
        ? DateTime.tryParse(occurredAt) ?? DateTime.now()
        : DateTime.now();

    final cat = raw['category'] as Map<String, dynamic>?;
    final catName = cat?['name'] as String? ?? 'Khác';
    final catIcon = cat?['icon'] as String? ?? '💰';

    final wallet = raw['wallet'] as Map<String, dynamic>?;
    final walletName = wallet?['name'] as String? ?? 'Ví';

    final typeLabel = txType == TransactionType.income
        ? 'Thu nhập'
        : txType == TransactionType.transfer
            ? 'Chuyển tiền'
            : 'Chi tiêu';

    return ReportTransaction(
      id: raw['_id'] as String? ?? raw['id'] as String? ?? '',
      title: raw['memo'] as String? ?? raw['description'] as String? ?? catName,
      category: catName,
      categoryIcon: catIcon,
      amount: signedAmount,
      dateTime: dateTime,
      type: txType,
      walletLabel: walletName,
      typeLabel: typeLabel,
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Provider
// ════════════════════════════════════════════════════════════════════

final reportProvider = NotifierProvider<ReportNotifier, ReportState>(
  ReportNotifier.new,
);
