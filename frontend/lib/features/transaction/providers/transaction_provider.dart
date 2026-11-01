import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/data/datasources/transaction_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/domain/models/dashboard_data.dart';

// ── Models ──────────────────────────────────────────────────────────

class WalletItem {
  final String id;
  final String name;
  final double balance;
  final String? currency;

  const WalletItem({
    required this.id,
    required this.name,
    required this.balance,
    this.currency,
  });

  factory WalletItem.fromJson(Map<String, dynamic> j) => WalletItem(
        id: j['_id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        balance: _toDouble(j['balance']),
        currency: j['currency']?.toString(),
      );

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is Map) {
      final raw = v['\$numberLong'] ?? v['low'];
      if (raw != null) return double.tryParse(raw.toString()) ?? 0.0;
    }
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class CategoryItem {
  final String id;
  final String name;
  final String type; // 'income' | 'expense'
  final String? icon;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> j) => CategoryItem(
        id: j['_id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        type: j['type']?.toString() ?? 'expense',
        icon: j['icon']?.toString(),
      );
}

// ── State ────────────────────────────────────────────────────────────

class TransactionState {
  final bool isLoading;
  final bool isSubmitting;
  final List<Transaction> transactions;
  final List<WalletItem> wallets;
  final List<CategoryItem> categories;
  final String? nextCursor;
  final bool hasMore;
  final String? errorMessage;
  final String? successMessage;

  const TransactionState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.transactions = const [],
    this.wallets = const [],
    this.categories = const [],
    this.nextCursor,
    this.hasMore = true,
    this.errorMessage,
    this.successMessage,
  });

  TransactionState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<Transaction>? transactions,
    List<WalletItem>? wallets,
    List<CategoryItem>? categories,
    String? nextCursor,
    bool? hasMore,
    String? errorMessage,
    String? successMessage,
  }) {
    return TransactionState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      transactions: transactions ?? this.transactions,
      wallets: wallets ?? this.wallets,
      categories: categories ?? this.categories,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────

class TransactionNotifier extends Notifier<TransactionState> {
  @override
  TransactionState build() {
    Future.microtask(() => initialize());
    return const TransactionState(isLoading: true);
  }

  Future<void> initialize() async {
    await Future.wait([loadWallets(), loadCategories()]);
    await loadTransactions();
  }

  Future<void> loadWallets() async {
    try {
      final ds = ref.read(transactionRemoteDataSourceProvider);
      final raw = await ds.getWallets();
      final wallets = raw.map(WalletItem.fromJson).toList();
      state = state.copyWith(wallets: wallets);
    } catch (_) {}
  }

  Future<void> loadCategories() async {
    try {
      final ds = ref.read(transactionRemoteDataSourceProvider);
      final raw = await ds.getCategories();
      final cats = raw.map(CategoryItem.fromJson).toList();
      state = state.copyWith(categories: cats);
    } catch (_) {}
  }

  Future<void> loadTransactions({bool refresh = true}) async {
    if (!refresh && !state.hasMore) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ds = ref.read(transactionRemoteDataSourceProvider);
      final resp = await ds.getTransactions(
        cursor: refresh ? null : state.nextCursor,
        limit: 20,
      );

      final items = _parseTransactionList(resp);
      final cursor = resp['nextCursor']?.toString();
      final hasMore = cursor != null && cursor.isNotEmpty;

      state = state.copyWith(
        isLoading: false,
        transactions: refresh ? items : [...state.transactions, ...items],
        nextCursor: cursor,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> createTransaction({
    required String type,
    required int amountVnd,
    required DateTime occurredAt,
    String? categoryId,
    String? walletId,
    String? toWalletId,
    String? memo,
    String? note,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final ds = ref.read(transactionRemoteDataSourceProvider);
      await ds.createTransaction(
        type: type,
        amount: amountVnd,
        occurredAt: occurredAt.toIso8601String(),
        categoryId: categoryId,
        walletId: walletId,
        toWalletId: toWalletId,
        memo: memo,
        note: note,
      );
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Giao dịch đã được lưu!',
      );
      // Refresh danh sách
      await loadTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> voidTransaction(String id) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final ds = ref.read(transactionRemoteDataSourceProvider);
      await ds.voidTransaction(id);
      state = state.copyWith(isSubmitting: false);
      await loadTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  // ── Parser ─────────────────────────────────────────────────────────

  List<Transaction> _parseTransactionList(Map<String, dynamic> resp) {
    final raw = resp['items'] as List<dynamic>? ??
        resp['entries'] as List<dynamic>? ??
        [];
    return raw.map((e) => _parseOne(e as Map<String, dynamic>)).toList();
  }

  Transaction _parseOne(Map<String, dynamic> e) {
    final amount = _toDouble(e['amount'] ?? e['netAmount']);
    final catName = _catName(e);
    return Transaction(
      id: e['_id']?.toString() ?? '',
      title: e['memo']?.toString() ?? catName,
      category: catName,
      amount: amount,
      date: _parseDate(e['occurredAt'] ?? e['createdAt']),
      note: e['note']?.toString(),
      icon: _icon(catName, amount),
    );
  }

  String _catName(Map<String, dynamic> e) {
    final cat = e['category'];
    if (cat is Map) return cat['name']?.toString() ?? 'Khác';
    if (cat is String) return cat;
    return 'Khác';
  }

  TransactionIcon _icon(String cat, double amount) {
    final c = cat.toLowerCase();
    if (c.contains('ăn') || c.contains('food') || c.contains('quán')) return TransactionIcon.food;
    if (c.contains('xe') || c.contains('grab') || c.contains('di chuyển')) return TransactionIcon.transport;
    if (c.contains('mua') || c.contains('shop')) return TransactionIcon.shopping;
    if (c.contains('y tế') || c.contains('sức khoẻ')) return TransactionIcon.health;
    if (c.contains('lương') || amount > 0) return TransactionIcon.salary;
    if (c.contains('chuyển')) return TransactionIcon.transfer;
    return TransactionIcon.other;
  }

  DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    try { return DateTime.parse(v.toString()).toLocal(); } catch (_) { return DateTime.now(); }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is Map) {
      final raw = v['\$numberLong'] ?? v['low'];
      if (raw != null) return double.tryParse(raw.toString()) ?? 0.0;
    }
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

final transactionProvider =
    NotifierProvider<TransactionNotifier, TransactionState>(
        TransactionNotifier.new);
