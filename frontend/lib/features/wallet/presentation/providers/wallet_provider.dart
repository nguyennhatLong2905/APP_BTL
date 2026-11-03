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
    this.itemName = '',
    this.itemPrice = 0,
    this.categoryTag = '',
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

      final freeBalance = _toDouble(data['freeBalance'] ?? data['totalBalance'] ?? 0);
      final fixedBills = _toDouble(data['fixedBills'] ?? data['totalFixedExpense'] ?? 0);
      final daysLeft = (data['daysLeft'] ?? data['daysLeftInPeriod'] ?? 14) as int;
      final salaryDate = data['salaryDate'] as String? ?? '--';

      state = state.copyWith(
        currentFreeBalance: freeBalance,
        fixedBillsAmount: fixedBills,
        daysLeftInPeriod: daysLeft,
        salaryDateText: salaryDate,
      );
    } catch (_) {
      // Nếu API lỗi, giữ default values – không hiển thị lỗi trên màn hình này
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
