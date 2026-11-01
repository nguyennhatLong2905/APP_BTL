import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/settings/data/datasources/budget_remote_data_source.dart';

class BudgetState {
  final bool isLoading;
  final Map<String, dynamic>? plansData;
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> goals;
  final List<Map<String, dynamic>> upcomingBills;
  final String? errorMessage;

  const BudgetState({
    this.isLoading = false,
    this.plansData,
    this.budgets = const [],
    this.goals = const [],
    this.upcomingBills = const [],
    this.errorMessage,
  });

  BudgetState copyWith({
    bool? isLoading,
    Map<String, dynamic>? plansData,
    List<Map<String, dynamic>>? budgets,
    List<Map<String, dynamic>>? goals,
    List<Map<String, dynamic>>? upcomingBills,
    String? errorMessage,
  }) {
    return BudgetState(
      isLoading: isLoading ?? this.isLoading,
      plansData: plansData ?? this.plansData,
      budgets: budgets ?? this.budgets,
      goals: goals ?? this.goals,
      upcomingBills: upcomingBills ?? this.upcomingBills,
      errorMessage: errorMessage,
    );
  }
}

class BudgetNotifier extends Notifier<BudgetState> {
  @override
  BudgetState build() {
    Future.microtask(() => loadAll());
    return const BudgetState(isLoading: true);
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      final results = await Future.wait([
        ds.getPlansScreen(),
        ds.getBudgets(),
        ds.getGoals(),
        ds.getUpcomingBills(),
      ]);

      state = state.copyWith(
        isLoading: false,
        plansData: results[0] as Map<String, dynamic>,
        budgets: (results[1] as List).cast<Map<String, dynamic>>(),
        goals: (results[2] as List).cast<Map<String, dynamic>>(),
        upcomingBills: (results[3] as List).cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> createBudget({
    required String categoryId,
    required int limitAmount,
    String period = 'monthly',
  }) async {
    try {
      final ds = ref.read(budgetRemoteDataSourceProvider);
      await ds.createBudget(
        categoryId: categoryId,
        limitAmount: limitAmount,
        period: period,
      );
      await loadAll();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final budgetProvider =
    NotifierProvider<BudgetNotifier, BudgetState>(BudgetNotifier.new);
