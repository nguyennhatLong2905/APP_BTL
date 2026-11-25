import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../data/datasources/smart_spending_remote_data_source.dart';

class WalletState {
  final String itemName;
  final double itemPrice;
  final String categoryTag;
  final int daysLeftInPeriod;
  final DateTime? nextPayday;
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
    this.daysLeftInPeriod = 0,
    this.nextPayday,
    this.currentFreeBalance = 0,
    this.fixedBillsAmount = 0,
    this.emergencyFundAmount = 0,
    this.savingDaysGoal = 30,
    this.isSimulating = false,
    this.simulationResult,
    this.errorMessage,
  });

  String get salaryDateText => nextPayday == null
      ? '--'
      : DateFormat('dd/MM').format(nextPayday!.toLocal());

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
    DateTime? nextPayday,
    bool clearNextPayday = false,
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
      nextPayday: clearNextPayday ? null : nextPayday ?? this.nextPayday,
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
    final dashboard = ref.read(homeProvider).dashboardData;
    ref.listen(homeProvider.select((home) => home.dashboardData), (_, data) {
      if (data == null) return;
      state = state.copyWith(
        currentFreeBalance: data.spendable,
        fixedBillsAmount: data.unpaidBills,
        emergencyFundAmount: data.protectedMoney,
        daysLeftInPeriod: math.max(0, data.daysRemaining ?? 0),
        nextPayday: data.nextPayday,
        clearNextPayday: data.nextPayday == null,
      );
    });
    Future.microtask(() async {
      if (ref.mounted) await ref.read(homeProvider.notifier).loadDashboard();
    });
    return WalletState(
      currentFreeBalance: dashboard?.spendable ?? 0,
      fixedBillsAmount: dashboard?.unpaidBills ?? 0,
      emergencyFundAmount: dashboard?.protectedMoney ?? 0,
      daysLeftInPeriod: math.max(0, dashboard?.daysRemaining ?? 0),
      nextPayday: dashboard?.nextPayday,
    );
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
    state = state.copyWith(
      isSimulating: true,
      errorMessage: null,
      simulationResult: null,
    );
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
}

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
);
