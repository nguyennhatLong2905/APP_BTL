import 'package:flutter/material.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';

class ReflectionBottomNav extends StatelessWidget {
  const ReflectionBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            icon: Icons.grid_view_outlined,
            label: 'Tổng quan',
            route: AppConstants.splashRoute,
            isSelected: false,
          ),
          _buildNavItem(
            context,
            icon: Icons.receipt_long_outlined,
            label: 'Giao dịch',
            route: AppConstants.smartSpendingRoute,
            isSelected: false,
          ),
          // Center Floating Plus
          InkWell(
            onTap: () => context.go(AppConstants.smartSpendingRoute),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF0F5B47),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
          _buildNavItem(
            context,
            icon: Icons.calendar_month_outlined,
            label: 'Kế hoạch',
            route: AppConstants.budgetPlanningRoute,
            isSelected: false,
          ),
          _buildNavItem(
            context,
            icon: Icons.analytics_outlined,
            label: 'Nhìn lại',
            route: AppConstants.timelineRoute,
            isSelected: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isSelected,
  }) {
    final color = isSelected ? const Color(0xFF0F5B47) : Colors.grey.shade600;

    return InkWell(
      onTap: () => context.go(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
