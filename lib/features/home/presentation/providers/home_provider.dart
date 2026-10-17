import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State của màn hình Home
class HomeState {
  final bool showWarningBanner;
  final bool balanceVisible;

  const HomeState({
    this.showWarningBanner = true,
    this.balanceVisible = true,
  });

  HomeState copyWith({
    bool? showWarningBanner,
    bool? balanceVisible,
  }) {
    return HomeState(
      showWarningBanner: showWarningBanner ?? this.showWarningBanner,
      balanceVisible: balanceVisible ?? this.balanceVisible,
    );
  }
}

/// Notifier cho màn hình Home — dùng API Notifier mới của Riverpod 3.x
class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();

  /// Đóng banner cảnh báo dữ liệu
  void dismissWarning() =>
      state = state.copyWith(showWarningBanner: false);

  /// Ẩn/hiện số tiền còn lại
  void toggleBalanceVisibility() =>
      state = state.copyWith(balanceVisible: !state.balanceVisible);
}

final homeProvider =
    NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
