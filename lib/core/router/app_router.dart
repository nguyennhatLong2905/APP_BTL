import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:flutter_riverpod_clean_architecture/core/providers/localization_providers.dart';
import 'package:flutter_riverpod_clean_architecture/core/router/locale_aware_router.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/presentation/screens/profile_screen.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/presentation/screens/timeline_screen.dart';
import 'package:flutter_riverpod_clean_architecture/features/report/presentation/screens/report_screen.dart';
import 'package:flutter_riverpod_clean_architecture/features/settings/presentation/screens/budget_planning_screen.dart';
import 'package:flutter_riverpod_clean_architecture/features/settings/presentation/screens/language_settings_screen.dart';
import 'package:flutter_riverpod_clean_architecture/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/presentation/screens/add_transaction_screen.dart';
import 'package:flutter_riverpod_clean_architecture/features/wallet/presentation/screens/smart_spending_screen.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  // Watch for locale changes - this rebuilds the router when locale changes
  ref.watch(persistentLocaleProvider);

  return GoRouter(
    initialLocation: AppConstants.splashRoute,
    debugLogDiagnostics: true,
    observers: [ref.read(localizationRouterObserverProvider)],
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final location = state.matchedLocation;

      final isGoingToLogin = location == AppConstants.loginRoute;
      final isGoingToRegister = location == AppConstants.registerRoute;
      final isGoingToSplash = location == AppConstants.splashRoute;

      // Cho phép vào trực tiếp các màn hình tính năng để test/xem UI
      final isFeatureScreen = location == AppConstants.smartSpendingRoute ||
          location == AppConstants.budgetPlanningRoute ||
          location == AppConstants.timelineRoute ||
          location == AppConstants.homeRoute ||
          location == AppConstants.addTransactionRoute ||
          location == AppConstants.reportRoute;

      // Splash & Feature screens luôn được phép vào
      if (isGoingToSplash || isFeatureScreen) return null;

      // Nếu chưa login → về login
      if (!isLoggedIn && !isGoingToLogin && !isGoingToRegister) {
        return AppConstants.loginRoute;
      }

      // Nếu đã login mà vào login/register → về home
      if (isLoggedIn && (isGoingToLogin || isGoingToRegister)) {
        return AppConstants.homeRoute;
      }

      return null;
    },
    routes: [
      // ============================================================
      // App Ví An - 7 màn hình chính
      // ============================================================

      // Long's screens
      GoRoute(
        path: AppConstants.splashRoute,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.homeRoute,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppConstants.addTransactionRoute,
        name: 'add_transaction',
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: AppConstants.reportRoute,
        name: 'report',
        builder: (context, state) => const ReportScreen(),
      ),

      // Dũng's screens
      GoRoute(
        path: AppConstants.smartSpendingRoute,
        name: 'smart_spending',
        builder: (context, state) => const SmartSpendingScreen(),
      ),
      GoRoute(
        path: AppConstants.budgetPlanningRoute,
        name: 'budget_planning',
        builder: (context, state) => const BudgetPlanningScreen(),
      ),
      GoRoute(
        path: AppConstants.timelineRoute,
        name: 'timeline',
        builder: (context, state) => const TimelineScreen(),
      ),

      // ============================================================
      // Auth & Settings routes
      // ============================================================
      GoRoute(
        path: AppConstants.loginRoute,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.registerRoute,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppConstants.settingsRoute,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppConstants.languageSettingsRoute,
        name: 'language_settings',
        builder: (context, state) => const LanguageSettingsScreen(),
      ),
      GoRoute(
        path: AppConstants.profileRoute,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppConstants.notificationsRoute,
        name: 'notifications',
        // Redirect sang timeline (màn của Dũng)
        redirect: (context, state) => AppConstants.timelineRoute,
      ),

      // Initial route
      GoRoute(
        path: '/',
        name: 'initial',
        redirect: (context, state) => AppConstants.splashRoute,
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Không Tìm Thấy Trang')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '404',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Trang ${state.uri.path} không tồn tại'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.homeRoute),
              child: const Text('Về Trang Chủ'),
            ),
          ],
        ),
      ),
    ),
  );
});
