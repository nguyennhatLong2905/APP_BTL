import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../widgets/currency_text_field.dart';

abstract final class FinanceScreenStyle {
  static const green = Color(0xFF0D5B47);
  static const background = Color(0xFFE3F5F1);
  static const mint = Color(0xFFD8F2EB);
  static const border = Color(0xFFC7E0DB);
  static const ink = Color(0xFF192725);
  static const muted = Color(0xFF50635C);
  static const danger = Color(0xFFB3261E);

  static const heading = TextStyle(
    color: green,
    fontSize: 19,
    fontWeight: FontWeight.w800,
  );

  static const amount = TextStyle(
    color: green,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.12,
  );

  static const strong = TextStyle(color: ink, fontWeight: FontWeight.w700);
  static const detail = TextStyle(color: muted, fontSize: 12);

  static String money(num value) =>
      '${value < 0 ? '−' : ''}${CurrencyTextField.formatAmount(value.abs())} đ';
}

class FinanceScreenHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const FinanceScreenHeader({
    super.key,
    required this.title,
    this.onNotifications,
  });

  final String title;
  final VoidCallback? onNotifications;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: preferredSize.height,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    foregroundColor: FinanceScreenStyle.ink,
    centerTitle: false,
    titleSpacing: 8,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Quay lại',
      onPressed: () =>
          context.canPop() ? context.pop() : context.go(AppConstants.homeRoute),
    ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('VÍ AN', style: TextStyle(fontSize: 11)),
        Text(title, style: FinanceScreenStyle.heading),
      ],
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        tooltip: 'Thông báo',
        onPressed:
            onNotifications ??
            () => context.go(AppConstants.notificationsRoute),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 10),
        child: IconButton(
          icon: const Icon(Icons.person_rounded, size: 20),
          tooltip: 'Tài khoản',
          onPressed: () => context.go(AppConstants.settingsRoute),
          style: IconButton.styleFrom(
            backgroundColor: FinanceScreenStyle.green,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    ],
  );
}

class FinanceCard extends StatelessWidget {
  const FinanceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: FinanceScreenStyle.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

class FinanceProgress extends StatelessWidget {
  const FinanceProgress({super.key, required this.value, this.height = 8});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: LinearProgressIndicator(
      value: value.clamp(0.0, 1.0),
      minHeight: height,
      color: FinanceScreenStyle.green,
      backgroundColor: FinanceScreenStyle.mint,
    ),
  );
}

class FinanceCategoryIcon extends StatelessWidget {
  const FinanceCategoryIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: FinanceScreenStyle.mint,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Icon(icon, color: FinanceScreenStyle.green, size: 21),
  );
}

class FinanceBottomNav extends StatelessWidget {
  const FinanceBottomNav({super.key, required this.selectedRoute});

  final String selectedRoute;

  static const _routes = [
    (AppConstants.homeRoute, 'Tổng quan', Icons.grid_view_outlined),
    (AppConstants.reportRoute, 'Giao dịch', Icons.swap_horiz_outlined),
    (AppConstants.addTransactionRoute, 'Thêm giao dịch', Icons.add),
    (
      AppConstants.budgetPlanningRoute,
      'Kế hoạch',
      Icons.calendar_month_outlined,
    ),
    (AppConstants.timelineRoute, 'Nhìn lại', Icons.analytics_outlined),
  ];

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const Border(top: BorderSide(color: FinanceScreenStyle.border)),
    child: SafeArea(
      top: false,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (route, title, icon) in _routes)
              Expanded(
                child: route == AppConstants.addTransactionRoute
                    ? Center(
                        child: IconButton(
                          onPressed: () => context.go(route),
                          tooltip: title,
                          style: IconButton.styleFrom(
                            minimumSize: const Size.square(46),
                            backgroundColor: FinanceScreenStyle.green,
                            foregroundColor: Colors.white,
                          ),
                          icon: Icon(icon, size: 25),
                        ),
                      )
                    : _FinanceNavItem(
                        route: route,
                        title: title,
                        icon: icon,
                        selected: selectedRoute == route,
                      ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _FinanceNavItem extends StatelessWidget {
  const _FinanceNavItem({
    required this.route,
    required this.title,
    required this.icon,
    required this.selected,
  });

  final String route;
  final String title;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? FinanceScreenStyle.green
        : FinanceScreenStyle.muted;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
