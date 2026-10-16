import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:flutter_riverpod_clean_architecture/core/utils/app_utils.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

/// TODO (Long): Implement Home/Dashboard Screen
/// - Header: Avatar, tên user, notification icon
/// - Balance Card: Hiển thị tổng số dư (số lớn, highlight)
/// - Quick Actions: 4 nút (Thu/Chi/Chuyển/Mục tiêu)
/// - Transaction List: List 5 giao dịch gần nhất
/// - Chart: Biểu đồ chi tiêu tuần (line chart hoặc bar chart)
/// - Bottom Navigation Bar: 5 tabs (Home/Transaction/Report/Wallet/Settings)
/// - Pull-to-refresh
/// - Skeleton loading khi fetch data
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state to get current user
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng Quan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push(AppConstants.settingsRoute);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Huỷ'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await ref.read(authProvider.notifier).logout();

                if (ref.read(authProvider).errorMessage != null) {
                  if (context.mounted) {
                    AppUtils.showSnackBar(
                      context,
                      message: ref.read(authProvider).errorMessage!,
                      backgroundColor: Theme.of(context).colorScheme.error,
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                // TODO (Long): Thêm refresh logic
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // TODO (Long): Thay bằng BalanceCard widget
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name.substring(0, 1).toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              context.push(AppConstants.profileRoute);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // TODO (Long): Implement dashboard widgets
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard - Đang phát triển',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Long sẽ implement: Balance Card, Quick Actions, Transaction List, Spending Chart...',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
