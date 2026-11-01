import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/wallet/data/datasources/smart_spending_remote_data_source.dart';

class SmartSpendingState {
  final bool isLoading;
  final bool isSimulating;
  final Map<String, dynamic>? simulationResult;
  final Map<String, dynamic>? recommendations;
  final Map<String, dynamic>? dashboardOverview;
  final String? errorMessage;

  // Form inputs
  final String itemName;
  final int itemAmount;

  const SmartSpendingState({
    this.isLoading = false,
    this.isSimulating = false,
    this.simulationResult,
    this.recommendations,
    this.dashboardOverview,
    this.errorMessage,
    this.itemName = '',
    this.itemAmount = 0,
  });

  SmartSpendingState copyWith({
    bool? isLoading,
    bool? isSimulating,
    Map<String, dynamic>? simulationResult,
    Map<String, dynamic>? recommendations,
    Map<String, dynamic>? dashboardOverview,
    String? errorMessage,
    String? itemName,
    int? itemAmount,
  }) {
    return SmartSpendingState(
      isLoading: isLoading ?? this.isLoading,
      isSimulating: isSimulating ?? this.isSimulating,
      simulationResult: simulationResult ?? this.simulationResult,
      recommendations: recommendations ?? this.recommendations,
      dashboardOverview: dashboardOverview ?? this.dashboardOverview,
      errorMessage: errorMessage,
      itemName: itemName ?? this.itemName,
      itemAmount: itemAmount ?? this.itemAmount,
    );
  }
}

class SmartSpendingNotifier extends Notifier<SmartSpendingState> {
  @override
  SmartSpendingState build() {
    Future.microtask(() => loadOverview());
    return const SmartSpendingState(isLoading: true);
  }

  Future<void> loadOverview() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ds = ref.read(smartSpendingRemoteDataSourceProvider);
      final data = await ds.getDashboardOverview();
      state = state.copyWith(isLoading: false, dashboardOverview: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void updateItemName(String name) =>
      state = state.copyWith(itemName: name);

  void updateItemAmount(int amount) =>
      state = state.copyWith(itemAmount: amount);

  Future<void> simulate() async {
    if (state.itemAmount <= 0) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập số tiền hợp lệ');
      return;
    }
    state = state.copyWith(isSimulating: true, errorMessage: null);
    try {
      final ds = ref.read(smartSpendingRemoteDataSourceProvider);
      final result = await ds.simulatePurchase(
        amount: state.itemAmount,
        itemName: state.itemName.isEmpty ? 'Sản phẩm' : state.itemName,
      );
      state = state.copyWith(isSimulating: false, simulationResult: result);
    } catch (e) {
      state = state.copyWith(
        isSimulating: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> getRecommendations() async {
    state = state.copyWith(isSimulating: true, errorMessage: null);
    try {
      final ds = ref.read(smartSpendingRemoteDataSourceProvider);
      final result = await ds.getRecommendations(
        budget: state.itemAmount,
        itemName: state.itemName.isEmpty ? 'Sản phẩm' : state.itemName,
      );
      state = state.copyWith(isSimulating: false, recommendations: result);
    } catch (e) {
      state = state.copyWith(
        isSimulating: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearResult() {
    state = state.copyWith(
      simulationResult: null,
      recommendations: null,
      errorMessage: null,
    );
  }
}

final smartSpendingProvider =
    NotifierProvider<SmartSpendingNotifier, SmartSpendingState>(
        SmartSpendingNotifier.new);
