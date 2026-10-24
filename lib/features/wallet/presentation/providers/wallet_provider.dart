import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  const WalletState({
    this.itemName = 'Tai nghe chống ồn không dây',
    this.itemPrice = 900000,
    this.categoryTag = 'Công nghệ • Làm việc',
    this.daysLeftInPeriod = 14,
    this.salaryDateText = '16/10',
    this.currentFreeBalance = 2100000,
    this.fixedBillsAmount = 3500000,
    this.emergencyFundAmount = 2400000,
    this.savingDaysGoal = 30,
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
    );
  }
}

class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() {
    return const WalletState();
  }

  void updateItemDetails({String? name, double? price, String? category}) {
    state = state.copyWith(
      itemName: name ?? state.itemName,
      itemPrice: price ?? state.itemPrice,
      categoryTag: category ?? state.categoryTag,
    );
  }

  void updateFreeBalance(double newBalance) {
    state = state.copyWith(currentFreeBalance: newBalance);
  }
}

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
);
