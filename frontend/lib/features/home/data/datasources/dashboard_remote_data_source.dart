import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/exceptions.dart';
import 'package:flutter_riverpod_clean_architecture/core/network/api_client.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/domain/models/dashboard_data.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardData> getDashboard();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient _apiClient;

  DashboardRemoteDataSourceImpl(this._apiClient);

  @override
  Future<DashboardData> getDashboard() async {
    final result = await _apiClient.get('/dashboard');
    return result.fold(
      (failure) => throw ServerException(message: failure.message),
      (data) {
        final body = data as Map<String, dynamic>;
        // Backend trả phẳng: { data: { total, available, wallets,
        // recentTransactions, ... } }. Giữ fallback cho shape lồng cũ.
        final d = body['data'] as Map<String, dynamic>? ?? body;
        return _parseDashboard(d);
      },
    );
  }

  DashboardData _parseDashboard(Map<String, dynamic> d) {
    // Trường hợp backend bọc trong 'overview' (shape cũ)
    final overview = (d['overview'] as Map<String, dynamic>?) ?? d;

    // Tổng số dư: ưu tiên field 'total' của backend,
    // fallback cộng balance các ví.
    final wallets = overview['wallets'] as List<dynamic>? ?? [];
    double walletSum = 0;
    for (final w in wallets) {
      final bal = _toDouble((w as Map<String, dynamic>)['balance']);
      if (bal >= 0) walletSum += bal;
    }
    final totalFromApi = overview['total'];
    final totalBalance = totalFromApi != null
        ? _toDouble(totalFromApi)
        : walletSum;

    // Thu/chi trong kỳ: backend dashboard không trả period summary,
    // nên tính từ recentTransactions nếu có, ngược lại 0.
    final rawEntries =
        (d['recentTransactions'] as List<dynamic>?) ??
        (d['recentEntries'] as List<dynamic>?) ??
        const [];

    double totalIncome = 0;
    double totalExpense = 0;
    final parsed = <Transaction>[];
    for (final e in rawEntries) {
      final map = e as Map<String, dynamic>;
      final type = map['type'] as String?;
      final amount = _toDouble(map['amount'] ?? map['netAmount']);
      if (type == 'income') {
        totalIncome += amount;
        parsed.add(_parseTransaction(map, signed: amount));
      } else if (type == 'expense') {
        totalExpense += amount;
        parsed.add(_parseTransaction(map, signed: -amount));
      } else if (type == 'adjustment' &&
          map['adjustmentDirection'] == 'decrease') {
        parsed.add(_parseTransaction(map, signed: -amount));
      } else {
        parsed.add(_parseTransaction(map, signed: amount));
      }
    }

    final period = d['period'] as Map<String, dynamic>? ?? {};
    if (period.isNotEmpty) {
      totalIncome = _toDouble(period['totalIncome'] ?? period['income']);
      totalExpense = _toDouble(period['totalExpense'] ?? period['expense']);
    }

    final recentTransactions = parsed.take(10).toList();

    // Hóa đơn sắp tới (chưa trả) — nằm ở d['bills'] top-level
    final rawBills =
        (d['bills'] as List<dynamic>?) ??
        (overview['bills'] as List<dynamic>?) ??
        const [];
    final upcomingBills = rawBills.map((b) {
      final map = b as Map<String, dynamic>;
      return UpcomingBill(
        id: map['_id']?.toString() ?? '',
        name:
            map['name']?.toString() ??
            map['nameTemplate']?.toString() ??
            'Hóa đơn',
        amount: _toDouble(map['amount']),
        dueAt: DateTime.tryParse(map['dueAt']?.toString() ?? '')?.toLocal(),
      );
    }).toList();

    // Weekly data (fallback: tạo 7 cột trống)
    final weeklyData = <WeeklySpending>[
      const WeeklySpending(dayLabel: 'T2', income: 0, expense: 0),
      const WeeklySpending(dayLabel: 'T3', income: 0, expense: 0),
      const WeeklySpending(dayLabel: 'T4', income: 0, expense: 0),
      const WeeklySpending(dayLabel: 'T5', income: 0, expense: 0),
      const WeeklySpending(dayLabel: 'T6', income: 0, expense: 0),
      const WeeklySpending(dayLabel: 'T7', income: 0, expense: 0),
      const WeeklySpending(dayLabel: 'CN', income: 0, expense: 0),
    ];

    // Lớp 1 hiển thị chi tiết từng ví đang hoạt động (balance thật).
    final walletBreakdown = wallets.map((w) {
      final map = w as Map<String, dynamic>;
      return WalletBalance(
        id: map['_id']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Ví',
        balance: _toDouble(map['balance']),
      );
    }).toList();

    return DashboardData(
      totalBalance: totalBalance,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      protectedMoney: _toDouble(overview['protectedMoney']),
      unpaidBills: _toDouble(overview['unpaidBills']),
      available: overview['available'] == null
          ? null
          : _toDouble(overview['available']),
      spendableAmount: overview['spendableAmount'] == null
          ? null
          : _toDouble(overview['spendableAmount']),
      shortfallAmount: overview['shortfallAmount'] == null
          ? null
          : _toDouble(overview['shortfallAmount']),
      daysRemaining: (overview['daysRemaining'] as num?)?.toInt(),
      dailyReference: overview['dailyReference'] == null
          ? null
          : _toDouble(overview['dailyReference']),
      nextPayday: DateTime.tryParse(
        overview['nextPayday']?.toString() ?? '',
      )?.toLocal(),
      recentTransactions: recentTransactions,
      upcomingBills: upcomingBills,
      weeklyData: weeklyData,
      walletBreakdown: walletBreakdown,
    );
  }

  Transaction _parseTransaction(Map<String, dynamic> e, {double? signed}) {
    final raw = _toDouble(e['amount'] ?? e['netAmount']);
    final amount = signed ?? raw;
    final catName = _categoryName(e);
    final note = e['note']?.toString();
    return Transaction(
      id: e['_id']?.toString() ?? '',
      title: (note != null && note.trim().isNotEmpty)
          ? note
          : e['memo']?.toString() ?? catName,
      category: catName,
      amount: amount,
      date: _parseDate(e['occurredAt'] ?? e['createdAt']),
      note: note,
      icon: e['type'] == 'transfer'
          ? TransactionIcon.transfer
          : _iconFor(catName, amount),
    );
  }

  String _categoryName(Map<String, dynamic> e) {
    final cat = e['category'];
    if (cat is Map) return cat['name']?.toString() ?? 'Khác';
    if (cat is String) return cat;
    final impacts = e['impacts'] as List<dynamic>?;
    if (impacts != null && impacts.isNotEmpty) {
      final first = impacts.first as Map<String, dynamic>? ?? {};
      final wallet = first['wallet'];
      if (wallet is Map) return wallet['name']?.toString() ?? 'Khác';
    }
    return 'Khác';
  }

  TransactionIcon _iconFor(String category, double amount) {
    final cat = category.toLowerCase();
    if (cat.contains('ăn') ||
        cat.contains('food') ||
        cat.contains('cà phê') ||
        cat.contains('quán')) {
      return TransactionIcon.food;
    }
    if (cat.contains('xe') ||
        cat.contains('grab') ||
        cat.contains('đi lại') ||
        cat.contains('di chuyển') ||
        cat.contains('xăng')) {
      return TransactionIcon.transport;
    }
    if (cat.contains('mua') || cat.contains('shop') || cat.contains('shopee')) {
      return TransactionIcon.shopping;
    }
    if (cat.contains('y tế') ||
        cat.contains('sức khoẻ') ||
        cat.contains('bệnh')) {
      return TransactionIcon.health;
    }
    if (cat.contains('lương') || cat.contains('salary') || amount > 0) {
      return TransactionIcon.salary;
    }
    if (cat.contains('chuyển') || cat.contains('transfer')) {
      return TransactionIcon.transfer;
    }
    return TransactionIcon.other;
  }

  DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    try {
      return DateTime.parse(val.toString()).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    // Backend có thể trả về { '$numberLong': '...' }
    if (val is Map) {
      final raw = val['\$numberLong'] ?? val['low'];
      if (raw != null) return double.tryParse(raw.toString()) ?? 0.0;
    }
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRemoteDataSourceImpl(apiClient);
});
