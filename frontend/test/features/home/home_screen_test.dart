import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/profile_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/data/datasources/dashboard_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/domain/models/dashboard_data.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/providers/home_provider.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/screens/home_screen.dart';
import 'package:go_router/go_router.dart';

class _DashboardSource implements DashboardRemoteDataSource {
  _DashboardSource(this.data);
  DashboardData data;

  @override
  Future<DashboardData> getDashboard() async => data;
}

class _QueuedDashboardSource implements DashboardRemoteDataSource {
  final requests = <Completer<DashboardData>>[];

  @override
  Future<DashboardData> getDashboard() {
    final request = Completer<DashboardData>();
    requests.add(request);
    return request.future;
  }
}

class _ProfileSource implements ProfileRemoteDataSource {
  _ProfileSource(this.dashboard);

  final _DashboardSource dashboard;
  String? savedDate;

  @override
  Future<Map<String, dynamic>> getProfile() async => {};

  @override
  Future<Map<String, dynamic>> updateProfile({
    String? nextPayday,
    Map<String, dynamic>? settings,
  }) async {
    savedDate = nextPayday;
    dashboard.data = _data(payday: DateTime.parse(nextPayday!).toLocal());
    return {};
  }
}

DashboardData _data({
  double total = 7950000,
  double bills = 3500000,
  double savings = 2400000,
  DateTime? payday,
}) => DashboardData(
  totalBalance: total,
  totalIncome: 0,
  totalExpense: 0,
  protectedMoney: savings,
  unpaidBills: bills,
  nextPayday: payday,
  daysRemaining: payday == null ? null : 10,
  dailyReference: payday == null ? null : 205000,
  walletBreakdown: total == 7950000
      ? const [
          WalletBalance(id: 'cash', name: 'Tiền mặt', balance: 550000),
          WalletBalance(id: 'bank', name: 'Tài khoản', balance: 7400000),
        ]
      : const [],
  upcomingBills: bills == 3500000
      ? [
          UpcomingBill(
            id: 'rent',
            name: 'Tiền nhà',
            amount: 3000000,
            dueAt: DateTime(2026, 12, 5),
          ),
        ]
      : const [],
  recentTransactions: [
    Transaction(
      id: '1',
      title: 'Ăn sáng',
      category: 'Ăn uống',
      amount: -50000,
      date: DateTime(2026, 10, 3),
      icon: TransactionIcon.food,
    ),
    Transaction(
      id: '2',
      title: 'Nhận lương',
      category: 'Lương',
      amount: 1000000,
      date: DateTime(2026, 10, 2),
      icon: TransactionIcon.salary,
    ),
    Transaction(
      id: '3',
      title: 'Giao dịch cũ',
      category: 'Khác',
      amount: -5000,
      date: DateTime(2026, 10, 1),
      icon: TransactionIcon.other,
    ),
  ],
  weeklyData: const [],
);

Future<_ProfileSource> _openHome(
  WidgetTester tester, {
  required DashboardData data,
  double width = 412,
  double height = 1200,
  double scale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final dashboard = _DashboardSource(data);
  final profile = _ProfileSource(dashboard);
  final router = GoRouter(
    initialLocation: AppConstants.homeRoute,
    routes: [
      GoRoute(
        path: AppConstants.homeRoute,
        builder: (_, _) => const HomeScreen(),
      ),
      for (final path in [
        AppConstants.smartSpendingRoute,
        AppConstants.notificationsRoute,
        AppConstants.settingsRoute,
        AppConstants.reportRoute,
      ])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text(path)),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardRemoteDataSourceProvider.overrideWithValue(dashboard),
        profileRemoteDataSourceProvider.overrideWithValue(profile),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en'), Locale('vi')],
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return profile;
}

void main() {
  test('Tổng quan giữ số dư mới nếu yêu cầu cũ trả về sau', () async {
    final source = _QueuedDashboardSource();
    final container = ProviderContainer(
      overrides: [dashboardRemoteDataSourceProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(homeProvider.notifier);

    final before = notifier.loadDashboard();
    final after = notifier.loadDashboard(force: true);
    source.requests.last.complete(_data(total: 17950000));
    await after;
    source.requests.first.complete(_data(total: 7950000));
    await before;

    expect(container.read(homeProvider).dashboardData?.totalBalance, 17950000);
  });

  testWidgets('412 px: cùng số tiền, đúng tỷ trọng và ẩn toàn bộ giá trị', (
    tester,
  ) async {
    await _openHome(tester, data: _data());
    expect(find.text('2.050.000 đ'), findsNWidgets(2));
    expect(find.textContaining('Lớp 2 · 74,2%'), findsOneWidget);
    expect(find.textContaining('Lớp 3 · 25,8%'), findsOneWidget);
    expect(find.text('−50.000 đ'), findsOneWidget);
    expect(find.text('+1.000.000 đ'), findsOneWidget);
    expect(find.text('Giao dịch cũ'), findsNothing);

    await tester.tap(find.byTooltip('Ẩn số tiền'));
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'\d đ|\d%')), findsNothing);
    expect(find.byTooltip('Hiện số tiền'), findsOneWidget);

    await tester.tap(find.byTooltip('Hiện số tiền'));
    await tester.pumpAndSettle();
    expect(find.text('2.050.000 đ'), findsNWidgets(2));
  });

  testWidgets('360 px: chữ lớn, đoạn rất hẹp và cuộn qua thanh điều hướng', (
    tester,
  ) async {
    await _openHome(
      tester,
      data: _data(bills: 5549999),
      width: 360,
      height: 740,
      scale: 2,
    );
    final ratio = find.text('Lớp 3 · 0,0%');
    await tester.scrollUntilVisible(ratio, 150);
    expect(tester.getTopLeft(ratio).dx, lessThan(100));
    await tester.scrollUntilVisible(find.text('Nhận lương'), 200);
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.text('Nhận lương')).dy,
      lessThan(tester.getTopLeft(find.byIcon(Icons.add)).dy),
    );
    expect(find.text('Thêm').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tổng bằng 0 bỏ tỷ trọng', (tester) async {
    await _openHome(tester, data: _data(total: 0, bills: 0, savings: 0));
    expect(find.text('Chưa có số dư để tính tỷ trọng.'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('thiếu tiền hiện 0 đ cho phần có thể chi và báo khoản thiếu', (
    tester,
  ) async {
    await _openHome(tester, data: _data(total: 5000000));
    expect(find.text('0 đ'), findsNWidgets(2));
    expect(find.text('−900.000 đ'), findsNothing);
    expect(
      find.text('Còn thiếu 900.000 đ để đủ khoản đã dành riêng.'),
      findsOneWidget,
    );
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('chọn ngày lương gọi luồng lưu và tải lại hạn mức', (
    tester,
  ) async {
    final profile = await _openHome(tester, data: _data(), width: 360);
    expect(find.text('Thêm ngày nhận lương'), findsOneWidget);
    await tester.tap(find.text('Thêm ngày nhận lương'));
    await tester.pumpAndSettle();
    final dialog = find.byType(DatePickerDialog);
    expect(dialog, findsOneWidget);
    final today = DateTime.now();
    final chosen = DateTime(today.year, today.month, today.day + 10);
    Navigator.of(tester.element(dialog)).pop(chosen);
    await tester.pumpAndSettle();
    expect(
      profile.savedDate,
      DateTime.utc(chosen.year, chosen.month, chosen.day, 12).toIso8601String(),
    );
    expect(find.textContaining('Ngày nhận lương ·'), findsOneWidget);
    expect(find.text('Khoảng 205.000 đ/ngày'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.tap(find.byTooltip('Ẩn số tiền'));
    await tester.pumpAndSettle();
    expect(find.text('Khoảng •••••/ngày'), findsOneWidget);
  });

  for (final (label, path, isTooltip) in [
    ('Thông báo', AppConstants.notificationsRoute, true),
    ('Cài đặt', AppConstants.settingsRoute, true),
    ('Thử tính', AppConstants.smartSpendingRoute, false),
    ('Xem tất cả', AppConstants.reportRoute, false),
  ]) {
    testWidgets('$label mở route hiện có', (tester) async {
      await _openHome(tester, data: _data());
      await tester.tap(isTooltip ? find.byTooltip(label) : find.text(label));
      await tester.pumpAndSettle();
      expect(find.text(path), findsOneWidget);
    });
  }
}
