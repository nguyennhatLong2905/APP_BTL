import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/providers/home_provider.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/widgets/balance_card.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/widgets/dashboard_skeleton.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/widgets/quick_action_buttons.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/widgets/recent_transactions.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/widgets/spending_chart.dart';
import 'package:go_router/go_router.dart';

/// Dashboard (Tổng Quan) - Màn hình chính của app Ví An
///
/// Bao gồm:
/// - Header: Avatar, tên user, notification icon
/// - Balance Card: Tổng số dư + thu/chi tháng
/// - Quick Actions: Thu / Chi / Chuyển / Mục tiêu
/// - Spending Chart: Biểu đồ chi tiêu tuần
/// - Recent Transactions: 5 giao dịch gần nhất
/// - Bottom Navigation Bar: 5 tabs
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    switch (index) {
      case 1:
        context.push(AppConstants.addTransactionRoute);
        break;
      case 3:
        context.push(AppConstants.reportRoute);
        break;
      case 4:
        context.push(AppConstants.settingsRoute);
        break;
      default:
        setState(() => _currentNavIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: homeState.isLoading
          ? const DashboardSkeleton()
          : homeState.error != null
              ? _ErrorView(
                  error: homeState.error!,
                  onRetry: () => ref.read(homeProvider.notifier).refresh(),
                )
              : _DashboardContent(
                  state: homeState,
                  onRefresh: () =>
                      ref.read(homeProvider.notifier).refresh(),
                ),
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

/// Nội dung chính của Dashboard sau khi load xong
class _DashboardContent extends StatelessWidget {
  final HomeState state;
  final Future<void> Function() onRefresh;

  const _DashboardContent({
    required this.state,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final data = state.data!;

    return RefreshIndicator(
      color: const Color(0xFF00A86B),
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Header với SliverAppBar
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            snap: true,
            backgroundColor: const Color(0xFFF8F9FA),
            elevation: 0,
            flexibleSpace: const FlexibleSpaceBar(),
            title: _HomeHeader(),
            centerTitle: false,
            leading: const SizedBox.shrink(),
            leadingWidth: 0,
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Balance Card
                BalanceCard(
                  totalBalance: data.totalBalance,
                  totalIncome: data.totalIncome,
                  totalExpense: data.totalExpense,
                ),
                const SizedBox(height: 24),

                // Quick Actions
                const QuickActionButtons(),
                const SizedBox(height: 28),

                // Spending Chart
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SpendingChart(data: data.weeklyData),
                ),
                const SizedBox(height: 24),

                // Recent Transactions
                RecentTransactions(
                  transactions: data.recentTransactions,
                  onViewAll: () {
                    // TODO: Navigate đến màn lịch sử đầy đủ
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header - Avatar, tên user, notification
class _HomeHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Lấy thông tin user từ auth provider thực tế
    const userName = 'Nguyễn Long';
    final greeting = _getGreeting();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00A86B), Color(0xFF2EC4B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00A86B).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'NL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Greeting + Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Text(
                  userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),

          // Notification bell
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    size: 22,
                    color: Color(0xFF1A1A2E),
                  ),
                  onPressed: () {
                    // TODO: Navigate đến notifications
                  },
                  padding: EdgeInsets.zero,
                ),
              ),
              // Badge
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE71D36),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng ☀️';
    if (hour < 18) return 'Chào buổi chiều 🌤️';
    return 'Chào buổi tối 🌙';
  }
}

/// Widget hiển thị khi có lỗi
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: Color(0xFFE71D36),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không tải được dữ liệu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A86B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Thử lại',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
