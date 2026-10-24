import 'package:flutter/material.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A86B).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: Color(0xFF00A86B),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ứng Dụng Ví An',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A86B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Màn hình khởi động (Splash Screen)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                ' BẢNG ĐIỀU HƯỚNG MÀN HÌNH CỦA DŨNG ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              _buildNavCard(
                context,
                title: '1. Mua Hay Chờ (Smart Spending)',
                subtitle: 'Phân tích & đề xuất quyết định mua sắm',
                icon: Icons.shopping_bag_outlined,
                color: Colors.orange,
                route: AppConstants.smartSpendingRoute,
              ),
              const SizedBox(height: 12),
              _buildNavCard(
                context,
                title: '2. Kế Hoạch Chi Tiêu (Budget Planning)',
                subtitle: 'Lập ngân sách & phân bổ danh mục',
                icon: Icons.pie_chart_outline,
                color: Colors.blue,
                route: AppConstants.budgetPlanningRoute,
              ),
              const SizedBox(height: 12),
              _buildNavCard(
                context,
                title: '3. Nhìn Lại Nhật Ký (Transaction Timeline)',
                subtitle: 'Xem nhật ký giao dịch theo dòng thời gian & lịch',
                icon: Icons.timeline,
                color: Colors.purple,
                route: AppConstants.timelineRoute,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.go(route),
      ),
    );
  }
}
