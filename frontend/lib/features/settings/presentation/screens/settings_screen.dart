import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/island_bubble_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';

/// Màn hình Cài Đặt — hiện có thông tin tài khoản + Đăng xuất
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const Color _teal = Color(0xFF2C7873);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF757575);

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showIslandConfirm(
      context,
      title: 'Đăng xuất tài khoản?',
      message: 'Bạn sẽ cần đăng nhập lại để tiếp tục.',
      cancelLabel: 'Hủy',
      confirmLabel: 'Đăng xuất',
      icon: Icons.logout_rounded,
    );

    if (confirmed != true) return;

    await ref.read(authProvider.notifier).logout();

    // Xóa dữ liệu dashboard của phiên trước để không lộ dữ liệu người cũ
    ref.invalidate(homeProvider);

    if (!context.mounted) return;
    AppSnackBar.showSuccess(context, 'Đã đăng xuất tài khoản');
    // Router tự chuyển về /login khi isAuthenticated = false;
    // gọi go() để chắc chắn không kẹt ở trang cần đăng nhập.
    context.go(AppConstants.loginRoute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final displayName =
        (user?.name.trim().isNotEmpty ?? false) ? user!.name : 'Người dùng';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF9),
      appBar: AppBar(
        title: const Text('Cài Đặt'),
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Thẻ tài khoản ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3EFEC)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: _teal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Đăng xuất ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3EFEC)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: authState.isLoading
                  ? null
                  : () => _confirmLogout(context, ref),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: Colors.red.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        authState.isLoading
                            ? 'Đang đăng xuất...'
                            : 'Đăng xuất',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                    if (authState.isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red.shade600,
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Colors.red.shade300,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
