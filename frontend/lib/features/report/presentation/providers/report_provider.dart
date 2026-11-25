import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/refresh_financial_data.dart';
import '../../../transaction/data/datasources/transaction_remote_data_source.dart';
import '../../data/datasources/report_remote_data_source.dart';
import '../../domain/models/report_data.dart';

// ════════════════════════════════════════════════════════════════════
// State – Report Provider (API-backed)
// ════════════════════════════════════════════════════════════════════

class ReportState {
  final PeriodFilter selectedPeriod;
  final DateTime? selectedMonth;
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
    this.selectedMonth,
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
    DateTime? selectedMonth,
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
      selectedMonth: selectedMonth ?? this.selectedMonth,
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
  int _loadRequestId = 0;

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

    final requestId = ++_loadRequestId;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ds = ref.read(reportRemoteDataSourceProvider);
      final now = DateTime.now();
      final month = state.selectedMonth ?? now;
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final (startAt, endAt) = switch (state.selectedPeriod) {
        PeriodFilter.today => (
          DateTime(now.year, now.month, now.day),
          tomorrow,
        ),
        PeriodFilter.week => (
          DateTime(now.year, now.month, now.day - now.weekday + 1),
          tomorrow,
        ),
        PeriodFilter.month => (
          DateTime(month.year, month.month),
          DateTime(month.year, month.month + 1),
        ),
      };

      final result = await ds.getTransactionHistory(
        startAt: startAt,
        endAt: endAt,
        limit: 100,
      );
      if (!ref.mounted || requestId != _loadRequestId) return;

      // Parse items từ backend
      final raw = result['items'] as List<dynamic>? ?? [];
      final txs = raw
          .map((e) => _parseTransaction(e as Map<String, dynamic>))
          .toList();

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
      if (!ref.mounted || requestId != _loadRequestId) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setPeriod(PeriodFilter period) {
    _selectPeriod(period);
  }

  void setMonth(DateTime month) {
    _selectPeriod(PeriodFilter.month, month: DateTime(month.year, month.month));
  }

  void _selectPeriod(PeriodFilter period, {DateTime? month}) {
    final changed =
        period != state.selectedPeriod ||
        (month != null && month != state.selectedMonth);
    state = state.copyWith(
      selectedPeriod: period,
      selectedMonth: month,
      allTransactions: changed ? const [] : null,
      totalIncome: changed ? 0 : null,
      totalExpense: changed ? 0 : null,
    );
    loadTransactions(force: true);
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
        ? (DateTime.tryParse(occurredAt) ?? DateTime.now()).toLocal()
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
      walletId: raw['walletId'] as String? ?? wallet?['_id'] as String? ?? '',
      categoryId:
          raw['categoryId'] as String? ?? cat?['_id'] as String? ?? '',
      note: raw['note'] as String? ?? raw['memo'] as String? ?? '',
      version: (raw['version'] as num?)?.toInt() ?? 0,
      isVoided: (raw['status'] as String?) == 'voided',
    );
  }

  /// Sửa giao dịch: PUT /transactions/:id (backend cần expectedVersion)
  Future<String?> editTransaction({
    required ReportTransaction tx,
    required double amount,
    required DateTime occurredAt,
    String? note,
  }) async {
    // Giữ nguyên loại + ví/danh mục để backend không yêu cầu chọn lại
    final data = <String, dynamic>{
      'type': tx.type.name,
      'amount': amount.abs().toInt().toString(),
      'occurredAt': _isoTimestamp(occurredAt),
      'expectedVersion': tx.version,
    };
    if (tx.type == TransactionType.transfer) return 'Chưa hỗ trợ sửa giao dịch chuyển ví';
    data['walletId'] = tx.walletId;
    data['categoryId'] = tx.categoryId;
    if (note != null && note.trim().isNotEmpty) data['note'] = note.trim();

    try {
      final ds = ref.read(transactionRemoteDataSourceProvider);
      await ds.updateTransaction(id: tx.id, data: data);
      // Làm mới các màn hình bị ảnh hưởng (Report, Dashboard, Transaction, Budget)
      invalidateFinancialData(ref);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Hủy (xóa) giao dịch: POST /transactions/:id/void
  Future<String?> voidTransaction(ReportTransaction tx) async {
    try {
      final ds = ref.read(transactionRemoteDataSourceProvider);
      await ds.voidTransaction(tx.id, expectedVersion: tx.version);
      invalidateFinancialData(ref);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Format datetime theo regex backend: YYYY-MM-DDTHH:mm:ss.sssZ (UTC)
  String _isoTimestamp(DateTime d) {
    final u = d.toUtc();
    String p(int v, int n) => v.toString().padLeft(n, '0');
    return '${p(u.year, 4)}-${p(u.month, 2)}-${p(u.day, 2)}'
        'T${p(u.hour, 2)}:${p(u.minute, 2)}:${p(u.second, 2)}'
        '.${p(u.millisecond, 3)}Z';
  }
}

// ════════════════════════════════════════════════════════════════════
// Provider
// ════════════════════════════════════════════════════════════════════

final reportProvider = NotifierProvider<ReportNotifier, ReportState>(
  ReportNotifier.new,
);
