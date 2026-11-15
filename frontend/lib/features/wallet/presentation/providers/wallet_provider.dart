import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/smart_spending_remote_data_source.dart';

class WalletState {
  final String itemName;
  final double itemPrice;
  final String categoryTag;
  final int daysLeftInPeriod;
  final String salaryDateText;
  final double currentFreeBalance;
  final double fixedBillsAmount;
  final double emergencyFundAmount;
  final int savingDaysGoal;

  // Kết quả mô phỏng từ API
  final bool isSimulating;
  final Map<String, dynamic>? simulationResult;
  final String? errorMessage;

  const WalletState({
    this.itemName = 'Tai nghe không dây',
    this.itemPrice = 900000,
    this.categoryTag = 'Mua sắm',
    this.daysLeftInPeriod = 14,
    this.salaryDateText = '--',
    this.currentFreeBalance = 0,
    this.fixedBillsAmount = 0,
    this.emergencyFundAmount = 0,
    this.savingDaysGoal = 30,
    this.isSimulating = false,
    this.simulationResult,
    this.errorMessage,
  });

  double get freeBalanceAfterPurchase => currentFreeBalance - itemPrice;
  double get dailyAvgCurrent =>
      daysLeftInPeriod > 0 ? currentFreeBalance / daysLeftInPeriod : 0;
  double get dailyAvgAfterPurchase =>
      daysLeftInPeriod > 0 ? freeBalanceAfterPurchase / daysLeftInPeriod : 0;
  double get dailySavingGoal =>
      savingDaysGoal > 0 ? itemPrice / savingDaysGoal : 0;

  WalletState copyWith({
    String? itemName,
    double? itemPrice,
    String? categoryTag,
    int? daysLeftInPeriod,
    String? salaryDateText,
    double? currentFreeBalance,
    double? fixedBillsAmount,
    double? emergencyFundAmount,
    int? savingDaysGoal,
    bool? isSimulating,
    Map<String, dynamic>? simulationResult,
    String? errorMessage,
  }) {
    return WalletState(
      itemName: itemName ?? this.itemName,
      itemPrice: itemPrice ?? this.itemPrice,
      categoryTag: categoryTag ?? this.categoryTag,
      daysLeftInPeriod: daysLeftInPeriod ?? this.daysLeftInPeriod,
      salaryDateText: salaryDateText ?? this.salaryDateText,
      currentFreeBalance: currentFreeBalance ?? this.currentFreeBalance,
      fixedBillsAmount: fixedBillsAmount ?? this.fixedBillsAmount,
      emergencyFundAmount: emergencyFundAmount ?? this.emergencyFundAmount,
      savingDaysGoal: savingDaysGoal ?? this.savingDaysGoal,
      isSimulating: isSimulating ?? this.isSimulating,
      simulationResult: simulationResult ?? this.simulationResult,
      errorMessage: errorMessage,
    );
  }
}

class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() {
    Future.microtask(_loadDashboardOverview);
    return const WalletState();
  }

  Future<void> _loadDashboardOverview() async {
    try {
      final ds = ref.read(smartSpendingRemoteDataSourceProvider);
      final data = await ds.getDashboardOverview();

      // Backend trả về: available, total, unpaidBills, protectedMoney, daysRemaining, nextPayday
      final freeBalance = _toDouble(data['available'] ?? data['freeBalance'] ?? data['total'] ?? 0);
      final fixedBills = _toDouble(data['unpaidBills'] ?? data['fixedBills'] ?? 0);
      final protectedMoney = _toDouble(data['protectedMoney'] ?? 0);
      final daysLeft = (data['daysRemaining'] ?? data['daysLeft'] ?? 14) as int;
      final paydayRaw = data['nextPayday'] as String?;
      String salaryDate = '--';
      if (paydayRaw != null) {
        final parsed = DateTime.tryParse(paydayRaw)?.toLocal();
        if (parsed != null) {
          salaryDate = '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}';
        }
      }

      state = state.copyWith(
        currentFreeBalance: freeBalance,
        fixedBillsAmount: fixedBills,
        emergencyFundAmount: protectedMoney,
        daysLeftInPeriod: daysLeft,
        salaryDateText: salaryDate,
      );
    } catch (_) {
      // Nếu API lỗi, giữ default values
    }
  }

  /// Lưu món đồ vào danh sách cân nhắc mua sau (Wishlist)
  Future<String?> savePurchaseWishlist() async {
    try {
      final ds = ref.read(smartSpendingRemoteDataSourceProvider);
      final remindAt = DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String();
      await ds.createPurchase(
        name: state.itemName,
        price: state.itemPrice.toInt().toString(),
        remindAt: remindAt,
      );
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  void updateItemDetails({String? name, double? price, String? category}) {
    state = state.copyWith(
      itemName: name ?? state.itemName,
      itemPrice: price ?? state.itemPrice,
      categoryTag: category ?? state.categoryTag,
      simulationResult: null, // reset kết quả cũ
    );
  }

  void updateFreeBalance(double newBalance) {
    state = state.copyWith(currentFreeBalance: newBalance);
  }

  /// Gọi API mô phỏng mua hàng
  Future<void> simulatePurchase() async {
    if (state.itemPrice <= 0) return;
    state = state.copyWith(isSimulating: true, errorMessage: null, simulationResult: null);
    try {
      final ds = ref.read(smartSpendingRemoteDataSourceProvider);
      final result = await ds.simulatePurchase(
        price: state.itemPrice.toInt().toString(),
      );
      state = state.copyWith(isSimulating: false, simulationResult: result);
    } catch (e) {
      state = state.copyWith(
        isSimulating: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearSimulation() {
    state = state.copyWith(simulationResult: null, errorMessage: null);
  }

  double _toDouble(dynamic v) {
    if (v is String) return double.tryParse(v) ?? 0;
    if (v is num) return v.toDouble();
    return 0;
  }
}

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
);
