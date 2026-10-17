import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/data/mock_data.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/domain/models/dashboard_data.dart';

/// State cho Home Screen
class HomeState {
  final bool isLoading;
  final DashboardData? data;
  final String? error;

  const HomeState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  HomeState copyWith({
    bool? isLoading,
    DashboardData? data,
    String? error,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

/// Notifier quản lý state Dashboard
class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    // Tự động load data khi khởi tạo
    Future.microtask(() => loadDashboardData());
    return const HomeState(isLoading: true);
  }

  /// Load dữ liệu dashboard (hiện tại dùng mock data)
  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);

    // Giả lập network delay để thấy skeleton loading
    await Future.delayed(const Duration(milliseconds: 1200));

    try {
      // TODO: Thay thế bằng API call thực tế
      final data = MockHomeData.dashboardData;
      state = HomeState(isLoading: false, data: data);
    } catch (e) {
      state = HomeState(isLoading: false, error: e.toString());
    }
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    await loadDashboardData();
  }
}

/// Provider cho Home Screen
final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
