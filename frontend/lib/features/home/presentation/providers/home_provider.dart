import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/data/datasources/dashboard_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/domain/models/dashboard_data.dart';

/// State đầy đủ của màn hình Home
class HomeState {
  final bool balanceVisible;
  final bool isLoading;
  final DashboardData? dashboardData;
  final String? errorMessage;
  final DateTime? lastLoadedAt;

  const HomeState({
    this.balanceVisible = true,
    this.isLoading = false,
    this.dashboardData,
    this.errorMessage,
    this.lastLoadedAt,
  });

  HomeState copyWith({
    bool? balanceVisible,
    bool? isLoading,
    DashboardData? dashboardData,
    String? errorMessage,
    DateTime? lastLoadedAt,
  }) {
    return HomeState(
      balanceVisible: balanceVisible ?? this.balanceVisible,
      isLoading: isLoading ?? this.isLoading,
      dashboardData: dashboardData ?? this.dashboardData,
      errorMessage: errorMessage,
      lastLoadedAt: lastLoadedAt ?? this.lastLoadedAt,
    );
  }
}

/// Notifier cho màn hình Home — kết nối API thật
class HomeNotifier extends Notifier<HomeState> {
  int _dashboardRequestId = 0;

  @override
  HomeState build() {
    // Không load tự động nữa
    return const HomeState();
  }

  /// Load dữ liệu dashboard từ API với cache 30s
  Future<void> loadDashboard({bool force = false}) async {
    // Cache 30 giây
    if (!force && state.lastLoadedAt != null && state.dashboardData != null) {
      final age = DateTime.now().difference(state.lastLoadedAt!);
      if (age.inSeconds < 30) {
        return; // Dùng cache
      }
    }

    final requestId = ++_dashboardRequestId;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dataSource = ref.read(dashboardRemoteDataSourceProvider);
      final data = await dataSource.getDashboard();
      if (!ref.mounted || requestId != _dashboardRequestId) return;
      state = state.copyWith(
        isLoading: false,
        dashboardData: data,
        lastLoadedAt: DateTime.now(),
      );
    } catch (e) {
      if (!ref.mounted || requestId != _dashboardRequestId) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Ẩn/hiện số tiền
  void toggleBalanceVisibility() =>
      state = state.copyWith(balanceVisible: !state.balanceVisible);
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
