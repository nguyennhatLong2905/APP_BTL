import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import 'home_style.dart';

class ViAnBottomNavBar extends StatelessWidget {
  const ViAnBottomNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const Border(top: BorderSide(color: HomeStyle.outline)),
      child: SafeArea(
        top: false,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NavItem(
                icon: Icons.grid_view_outlined,
                label: 'Tổng quan',
                selected: currentIndex == 0,
                onTap: () => context.go(AppConstants.homeRoute),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                label: 'Giao dịch',
                selected: currentIndex == 1,
                onTap: () => context.go(AppConstants.reportRoute),
              ),
              _NavItem(
                icon: Icons.add,
                label: 'Thêm',
                isAdd: true,
                onTap: () => context.go(AppConstants.addTransactionRoute),
              ),
              _NavItem(
                icon: Icons.calendar_today_outlined,
                label: 'Kế hoạch',
                selected: currentIndex == 2,
                onTap: () => context.go(AppConstants.budgetPlanningRoute),
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Nhìn lại',
                selected: currentIndex == 3,
                onTap: () => context.go(AppConstants.timelineRoute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.isAdd = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    final color = selected || isAdd ? HomeStyle.spendable : HomeStyle.muted;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 7, 2, 8),
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: isAdd
                      ? BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(9),
                        )
                      : null,
                  child: Icon(
                    icon,
                    size: 20,
                    color: isAdd ? Colors.white : color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
