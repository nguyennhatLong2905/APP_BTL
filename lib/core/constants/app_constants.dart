class AppConstants {
  // API constants (will be configured per environment in Stage 3)
  static const String devBaseUrlAndroid = 'http://10.0.2.2:3000/api/v1';
  static const String devBaseUrlIOS = 'http://127.0.0.1:3000/api/v1';
  static const String prodBaseUrl = 'https://api.expensetracker.com/api/v1';

  // Storage constants
  static const String tokenKey = 'authToken';
  static const String userDataKey = 'userData';
  static const String refreshTokenKey = 'refreshToken';

  // App constants
  static const String appName = 'Expense Tracker';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.mycompany.expensetracker';

  // Timeout durations
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Route constants
  static const String initialRoute = '/';
  static const String homeRoute = '/home';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  static const String languageSettingsRoute = '/settings/language';
  static const String notificationsRoute = '/notifications';

  // Hive box names
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';
  static const String offlineSyncBox = 'offline_sync';
  static const String notificationsStorageKey = 'notifications_key';

  // Accessibility & UX constants
  static const double accessibilityTouchTargetMinSize = 48.0;
  static const Duration accessibilityTooltipDuration = Duration(seconds: 3);

  // App Review & Update constants
  static const String iOSAppId = 'id1234567890';
  static const int minSessionsBeforeReview = 3;
  static const int minDaysBeforeReview = 7;
  static const int minActionsBeforeReview = 10;

  // Extra Routes
  static const String localizationAssetsDemoRoute = '/settings/localization-demo';

  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
