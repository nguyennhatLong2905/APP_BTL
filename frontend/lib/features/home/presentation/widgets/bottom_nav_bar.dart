import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';

/// Bottom Navigation Bar theo thiết kế Ví An
/// 4 tab + nút FAB ở giữa
class ViAnBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const ViAnBottomNavBar({super.key, required this.currentIndex});

  static const Color _teal = Color(0xFF2C7873);
  static const Color _inactive = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Tổng quan',
                isActive: currentIndex == 0,
                onTap: () => context.go(AppConstants.homeRoute),
                activeColor: _teal,
                inactiveColor: _inactive,
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                label: 'Giao dịch',
                isActive: currentIndex == 1,
                onTap: () => context.go(AppConstants.reportRoute),
                activeColor: _teal,
                inactiveColor: _inactive,
              ),
              // ── Nút FAB ở giữa ──────────────────────────────────
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.go(AppConstants.addTransactionRoute),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: _teal,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _teal.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                label: 'Kế hoạch',
                isActive: currentIndex == 2,
                onTap: () => context.go(AppConstants.budgetPlanningRoute),
                activeColor: _teal,
                inactiveColor: _inactive,
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Nhìn lại',
                isActive: currentIndex == 3,
                onTap: () => context.go(AppConstants.timelineRoute),
                activeColor: _teal,
                inactiveColor: _inactive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
