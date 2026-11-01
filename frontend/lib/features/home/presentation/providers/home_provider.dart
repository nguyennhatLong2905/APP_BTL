import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/data/datasources/dashboard_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/domain/models/dashboard_data.dart';

/// State đầy đủ của màn hình Home
class HomeState {
  final bool showWarningBanner;
  final bool balanceVisible;
  final bool isLoading;
  final DashboardData? dashboardData;
  final String? errorMessage;

  const HomeState({
    this.showWarningBanner = true,
    this.balanceVisible = true,
    this.isLoading = false,
    this.dashboardData,
    this.errorMessage,
  });

  HomeState copyWith({
    bool? showWarningBanner,
    bool? balanceVisible,
    bool? isLoading,
    DashboardData? dashboardData,
    String? errorMessage,
  }) {
    return HomeState(
      showWarningBanner: showWarningBanner ?? this.showWarningBanner,
      balanceVisible: balanceVisible ?? this.balanceVisible,
      isLoading: isLoading ?? this.isLoading,
      dashboardData: dashboardData ?? this.dashboardData,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier cho màn hình Home — kết nối API thật
class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    // Tự động load dashboard khi provider được tạo
    Future.microtask(() => loadDashboard());
    return const HomeState(isLoading: true);
  }

  /// Load dữ liệu dashboard từ API
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dataSource = ref.read(dashboardRemoteDataSourceProvider);
      final data = await dataSource.getDashboard();
      state = state.copyWith(isLoading: false, dashboardData: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Đóng banner cảnh báo
  void dismissWarning() =>
      state = state.copyWith(showWarningBanner: false);

  /// Ẩn/hiện số tiền
  void toggleBalanceVisibility() =>
      state = state.copyWith(balanceVisible: !state.balanceVisible);
}

final homeProvider =
    NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
