import 'package:flutter/material.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/presentation/widgets/reflection_bottom_nav.dart';
import 'package:flutter_riverpod_clean_architecture/features/settings/presentation/widgets/budget_bottom_nav.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Builds a router whose pages render a stub body plus the bottom nav under
/// test, so every nav tap runs inside a valid GoRouter context.
///
/// Trang TIMELINE có thêm nút "Mở lịch sử" gọi `context.push` — đúng cách màn
/// Nhìn lại mở `/timeline/history` trong ứng dụng thật.
GoRouter _buildRouter(String initialLocation, Widget nav) {
  Widget page(String label) => Scaffold(
        body: Center(
          child: label == 'TIMELINE'
              ? Builder(
                  builder: (context) => TextButton(
                    onPressed: () =>
                        context.push(AppConstants.reflectionHistoryRoute),
                    child: Text(label),
                  ),
                )
              : Text(label),
        ),
        bottomNavigationBar: nav,
      );

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppConstants.homeRoute,
        builder: (_, __) => page('HOME'),
      ),
      GoRoute(
        path: AppConstants.reportRoute,
        builder: (_, __) => page('REPORTS'),
      ),
      GoRoute(
        path: AppConstants.addTransactionRoute,
        builder: (_, __) => page('ADD_TRANSACTION'),
      ),
      GoRoute(
        path: AppConstants.budgetPlanningRoute,
        builder: (_, __) => page('BUDGET_PLANNING'),
      ),
      GoRoute(
        path: AppConstants.timelineRoute,
        builder: (_, __) => page('TIMELINE'),
      ),
      GoRoute(
        path: AppConstants.reflectionHistoryRoute,
        builder: (_, __) => page('REFLECTION_HISTORY'),
      ),
      GoRoute(
        path: AppConstants.smartSpendingRoute,
        builder: (_, __) => page('SMART_SPENDING'),
      ),
    ],
  );
}

Future<GoRouter> _pumpNav(
  WidgetTester tester, {
  required Widget nav,
  String initialLocation = AppConstants.budgetPlanningRoute,
}) async {
  final router = _buildRouter(initialLocation, nav);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

String _currentPath(GoRouter router) =>
    router.routeInformationProvider.value.uri.path;

void main() {
  group('BudgetBottomNav (màn Kế hoạch)', () {
    testWidgets('Giao dịch mở danh sách Giao dịch, không mở Mua Hay Chờ',
        (tester) async {
      final router = await _pumpNav(tester, nav: const BudgetBottomNav());
      await tester.tap(find.text('Giao dịch'));
      await tester.pumpAndSettle();

      expect(_currentPath(router), AppConstants.reportRoute);
      expect(find.text('REPORTS'), findsOneWidget);
      expect(find.text('SMART_SPENDING'), findsNothing);
    });

    testWidgets('Nút + mở luồng thêm giao dịch', (tester) async {
      final router = await _pumpNav(tester, nav: const BudgetBottomNav());
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(_currentPath(router), AppConstants.addTransactionRoute);
      expect(find.text('ADD_TRANSACTION'), findsOneWidget);
      expect(find.text('SMART_SPENDING'), findsNothing);
    });

    testWidgets('Tổng quan điều hướng đúng', (tester) async {
      final router = await _pumpNav(tester, nav: const BudgetBottomNav());
      await tester.tap(find.text('Tổng quan'));
      await tester.pumpAndSettle();

      expect(_currentPath(router), AppConstants.homeRoute);
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('Nhìn lại điều hướng đúng', (tester) async {
      final router = await _pumpNav(tester, nav: const BudgetBottomNav());
      await tester.tap(find.text('Nhìn lại'));
      await tester.pumpAndSettle();

      expect(_currentPath(router), AppConstants.timelineRoute);
      expect(find.text('TIMELINE'), findsOneWidget);
    });

    testWidgets('Kế hoạch vẫn điều hướng đúng', (tester) async {
      final router = await _pumpNav(
        tester,
        nav: const BudgetBottomNav(),
        initialLocation: AppConstants.homeRoute,
      );
      await tester.tap(find.text('Kế hoạch'));
      await tester.pumpAndSettle();

      expect(_currentPath(router), AppConstants.budgetPlanningRoute);
      expect(find.text('BUDGET_PLANNING'), findsOneWidget);
    });
  });

  group('ReflectionBottomNav (màn Nhìn lại)', () {
    testWidgets('Giao dịch mở danh sách Giao dịch, không mở Mua Hay Chờ',
        (tester) async {
      final router = await _pumpNav(
        tester,
        nav: const ReflectionBottomNav(),
        initialLocation: AppConstants.timelineRoute,
      );
      await tester.tap(find.text('Giao dịch'));
      await tester.pumpAndSettle();

      expect(_currentPath(router), AppConstants.reportRoute);
      expect(find.text('REPORTS'), findsOneWidget);
      expect(find.text('SMART_SPENDING'), findsNothing);
    });

    testWidgets('Nút + mở luồng thêm giao dịch', (tester) async {
      final router = await _pumpNav(
        tester,
        nav: const ReflectionBottomNav(),
        initialLocation: AppConstants.timelineRoute,
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(_currentPath(router), AppConstants.addTransactionRoute);
      expect(find.text('ADD_TRANSACTION'), findsOneWidget);
      expect(find.text('SMART_SPENDING'), findsNothing);
    });

    testWidgets('Tổng quan điều hướng đúng', (tester) async {
      final router = await _pumpNav(
        tester,
        nav: const ReflectionBottomNav(),
        initialLocation: AppConstants.timelineRoute,
      );
      await tester.tap(find.text('Tổng quan'));
      await tester.pumpAndSettle();

      expect(_currentPath(router), AppConstants.homeRoute);
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('Kế hoạch điều hướng đúng', (tester) async {
      final router = await _pumpNav(
        tester,
        nav: const ReflectionBottomNav(),
        initialLocation: AppConstants.timelineRoute,
      );
      await tester.tap(find.text('Kế hoạch'));
      await tester.pumpAndSettle();

      expect(_currentPath(router), AppConstants.budgetPlanningRoute);
      expect(find.text('BUDGET_PLANNING'), findsOneWidget);
    });
  });

  group('ViAnBottomNavBar (màn Tổng quan)', () {
    testWidgets('Giao dịch mở danh sách Giao dịch', (tester) async {
      final router = await _pumpNav(
        tester,
        nav: const ViAnBottomNavBar(currentIndex: 0),
        initialLocation: AppConstants.homeRoute,
      );
      await tester.tap(find.text('Giao dịch'));
      await tester.pumpAndSettle();

      expect(_currentPath(router), AppConstants.reportRoute);
      expect(find.text('REPORTS'), findsOneWidget);
    });

    testWidgets('Nút + mở luồng thêm giao dịch', (tester) async {
      final router = await _pumpNav(
        tester,
        nav: const ViAnBottomNavBar(currentIndex: 0),
        initialLocation: AppConstants.homeRoute,
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(_currentPath(router), AppConstants.addTransactionRoute);
      expect(find.text('ADD_TRANSACTION'), findsOneWidget);
    });

    testWidgets('Kế hoạch và Nhìn lại điều hướng đúng', (tester) async {
      var router = await _pumpNav(
        tester,
        nav: const ViAnBottomNavBar(currentIndex: 0),
        initialLocation: AppConstants.homeRoute,
      );
      await tester.tap(find.text('Kế hoạch'));
      await tester.pumpAndSettle();
      expect(_currentPath(router), AppConstants.budgetPlanningRoute);

      router = await _pumpNav(
        tester,
        nav: const ViAnBottomNavBar(currentIndex: 0),
        initialLocation: AppConstants.homeRoute,
      );
      await tester.tap(find.text('Nhìn lại'));
      await tester.pumpAndSettle();
      expect(_currentPath(router), AppConstants.timelineRoute);
      expect(find.text('TIMELINE'), findsOneWidget);
    });
  });

  group('Mua Hay Chờ vẫn truy cập được từ đúng vị trí chức năng', () {
    testWidgets('route smart-spending tồn tại và render đúng màn',
        (tester) async {
      final router = await _pumpNav(
        tester,
        nav: const BudgetBottomNav(),
        initialLocation: AppConstants.smartSpendingRoute,
      );
      expect(_currentPath(router), AppConstants.smartSpendingRoute);
      expect(find.text('SMART_SPENDING'), findsOneWidget);
    });
  });

  group('Nhật ký đã đánh giá (route riêng)', () {
    testWidgets('route /timeline/history render đúng màn', (tester) async {
      final router = await _pumpNav(
        tester,
        nav: const ReflectionBottomNav(),
        initialLocation: AppConstants.reflectionHistoryRoute,
      );
      expect(_currentPath(router), AppConstants.reflectionHistoryRoute);
      expect(find.text('REFLECTION_HISTORY'), findsOneWidget);
    });

    testWidgets('từ Nhìn lại có thể push sang /timeline/history',
        (tester) async {
      final router = await _pumpNav(
        tester,
        nav: const ReflectionBottomNav(),
        initialLocation: AppConstants.timelineRoute,
      );
      // Push từ bên trong màn (context.push), giống nút "Xem chi tiết" ở
      // card Thấu hiểu bản thân. GoRouter giữ URI gốc cho page dưới cùng,
      // nên kiểm tra route trên cùng của stack là /timeline/history.
      await tester.tap(find.text('TIMELINE'));
      await tester.pumpAndSettle();
      final matches =
          router.routerDelegate.currentConfiguration.matches;
      expect(
        matches.last.matchedLocation,
        AppConstants.reflectionHistoryRoute,
      );
      expect(router.canPop(), isTrue);
      expect(find.text('REFLECTION_HISTORY'), findsOneWidget);
    });
  });
}
