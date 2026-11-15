import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/island_bubble_dialog.dart';
import '../../../auth/data/datasources/profile_remote_data_source.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../data/datasources/data_management_remote_data_source.dart';

/// Màn hình Cài Đặt — Hồ sơ, Quyền riêng tư, Xuất/Sao lưu và Xóa dữ liệu (Luồng 13)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const Color _teal = Color(0xFF2C7873);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF757575);
  static const Color _danger = Color(0xFFD32F2F);

  bool _hideAmounts = false;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final pds = ref.read(profileRemoteDataSourceProvider);
      final profile = await pds.getProfile();
      final settings = profile['settings'] as Map<String, dynamic>? ?? {};
      if (mounted) {
        setState(() {
          _hideAmounts = settings['hideAmounts'] == true;
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _toggleHideAmounts(bool val) async {
    setState(() => _hideAmounts = val);
    try {
      final pds = ref.read(profileRemoteDataSourceProvider);
      await pds.updateProfile(settings: {'hideAmounts': val});
      await ref.read(homeProvider.notifier).loadDashboard(force: true);
      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          val
              ? 'Đã bật chế độ ẩn số tiền riêng tư'
              : 'Đã hiển thị lại số tiền trên màn hình',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hideAmounts = !val);
        AppSnackBar.showError(context, 'Không thể cập nhật thiết lập: $e');
      }
    }
  }

  Future<void> _exportCsv() async {
    try {
      final ds = ref.read(dataManagementRemoteDataSourceProvider);
      final csv = await ds.exportTransactionsCsv();

      if (!mounted) return;
      final lines = csv.split('\n').where((l) => l.trim().isNotEmpty).length;
      final rowCount = lines > 1 ? lines - 1 : 0;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.table_chart_outlined, color: _teal),
              SizedBox(width: 8),
              Text('Xuất CSV thành công'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đã xuất thành công $rowCount giao dịch tài chính.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  csv.length > 200 ? '${csv.substring(0, 200)}...' : csv,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csv));
                Navigator.of(ctx).pop();
                AppSnackBar.showSuccess(context, 'Đã sao chép toàn bộ CSV vào bộ nhớ tạm!');
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Sao chép CSV'),
              style: ElevatedButton.styleFrom(backgroundColor: _teal),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Lỗi xuất CSV: $e');
      }
    }
  }

  Future<void> _createBackup() async {
    try {
      final ds = ref.read(dataManagementRemoteDataSourceProvider);
      final backup = await ds.createBackup();

      if (!mounted) return;
      final checksum = backup['checksum'] as String? ?? 'N/A';
      final generatedAt = backup['generatedAt'] as String? ?? '';

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cloud_download_outlined, color: _teal),
              SizedBox(width: 8),
              Text('Tạo bản sao lưu'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bản sao lưu dữ liệu toàn diện đã được tạo và ký điện tử an toàn.',
                style: TextStyle(fontSize: 13.5),
              ),
              const SizedBox(height: 10),
              Text(
                'Thời gian: $generatedAt',
                style: const TextStyle(fontSize: 12, color: _textSecondary),
              ),
              Text(
                'Chữ ký xác thực: ${checksum.length > 16 ? "${checksum.substring(0, 16)}..." : checksum}',
                style: const TextStyle(fontSize: 12, color: _textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: backup.toString()));
                Navigator.of(ctx).pop();
                AppSnackBar.showSuccess(
                    context, 'Đã sao chép bản sao lưu snapshot!');
              },
              style: ElevatedButton.styleFrom(backgroundColor: _teal),
              child: const Text('Sao chép dữ liệu'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Lỗi tạo sao lưu: $e');
      }
    }
  }

  Future<void> _startEraseDataFlow() async {
    try {
      final ds = ref.read(dataManagementRemoteDataSourceProvider);
      final preview = await ds.previewErase();
      final previewId = preview['previewId'] as String? ?? '';
      final counts = preview['counts'] as Map<String, dynamic>? ?? {};
      final requiredConfirm = preview['confirmationText'] as String? ?? 'XOA DU LIEU VI AN';

      if (!mounted) return;

      final confirmCtrl = TextEditingController();
      bool isErasing = false;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: _danger, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Xóa dữ liệu tài chính (Bắt đầu lại)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hành động này sẽ xóa vĩnh viễn các mục sau và không thể hoàn tác:',
                    style: TextStyle(fontSize: 13, color: _textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _danger.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '• Giao dịch: ${counts['transactions'] ?? 0} bản ghi'),
                        Text('• Ví tiền: ${counts['wallets'] ?? 0} ví'),
                        Text(
                            '• Ngân sách & Hạn mức: ${counts['budgets'] ?? 0} kỳ'),
                        Text(
                            '• Mục tiêu tiết kiệm: ${counts['savings_goals'] ?? 0} mục tiêu'),
                        Text(
                            '• Hóa đơn định kỳ: ${counts['bill_occurrences'] ?? 0} hóa đơn'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Để xác nhận, vui lòng nhập chính xác cụm từ "$requiredConfirm":',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: confirmCtrl,
                    decoration: InputDecoration(
                      hintText: requiredConfirm,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (confirmCtrl.text.trim() != requiredConfirm ||
                              isErasing)
                          ? null
                          : () async {
                              setModalState(() => isErasing = true);
                              try {
                                await ds.eraseData(
                                  previewId: previewId,
                                  confirmation: requiredConfirm,
                                );
                                if (context.mounted) {
                                  Navigator.of(ctx).pop();
                                  AppSnackBar.showSuccess(
                                    context,
                                    'Đã xóa sạch dữ liệu tài chính. Vui lòng đăng nhập lại để bắt đầu lại.',
                                  );
                                  await ref.read(authProvider.notifier).logout();
                                  ref.invalidate(homeProvider);
                                  context.go(AppConstants.loginRoute);
                                }
                              } catch (e) {
                                setModalState(() => isErasing = false);
                                if (context.mounted) {
                                  AppSnackBar.showError(
                                      context, 'Lỗi xóa dữ liệu: $e');
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _danger,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isErasing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Xác nhận xóa vĩnh viễn',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Lỗi tải thông tin xóa dữ liệu: $e');
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
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
    ref.invalidate(homeProvider);

    if (!context.mounted) return;
    AppSnackBar.showSuccess(context, 'Đã đăng xuất tài khoản');
    context.go(AppConstants.loginRoute);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final displayName =
        (user?.name.trim().isNotEmpty ?? false) ? user!.name : 'Người dùng';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Quay lại',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppConstants.homeRoute);
            }
          },
        ),
        title: const Text('Cài Đặt & Dữ Liệu'),
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Về trang chủ',
            onPressed: () => context.go(AppConstants.homeRoute),
          ),
          const SizedBox(width: 8),
        ],
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

          // ── Section 1: Quyền riêng tư & Hiển thị ──────────────
          const Text(
            'QUYỀN RIÊNG TƯ & HIỂN THỊ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3EFEC)),
            ),
            child: SwitchListTile(
              value: _hideAmounts,
              onChanged: _isLoadingProfile ? null : _toggleHideAmounts,
              activeColor: _teal,
              title: const Text(
                'Ẩn số tiền trên trang chủ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Bảo vệ riêng tư khi mở Ví An ở nơi đông người',
                style: TextStyle(fontSize: 12, color: _textSecondary),
              ),
              secondary: const Icon(Icons.visibility_off_outlined, color: _teal),
            ),
          ),

          const SizedBox(height: 20),

          // ── Section 2: Quản lý dữ liệu (Luồng 13) ──────────────
          const Text(
            'QUẢN LÝ DỮ LIỆU & SAO LƯU',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3EFEC)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.table_chart_outlined, color: _teal),
                  title: const Text(
                    'Xuất giao dịch ra file CSV',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Tải về danh sách thu chi để mở bằng Excel hoặc Google Sheets',
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: _exportCsv,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: _teal),
                  title: const Text(
                    'Tạo bản sao lưu dữ liệu (Snapshot)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Sao lưu toàn diện có chữ ký bảo mật chống giả mạo',
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: _createBackup,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: _danger),
                  title: const Text(
                    'Xóa dữ liệu tài chính (Bắt đầu lại)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _danger,
                    ),
                  ),
                  subtitle: const Text(
                    'Reset toàn bộ ví, giao dịch, ngân sách nhưng giữ lại tài khoản',
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: _danger),
                  onTap: _startEraseDataFlow,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Section 3: Tài khoản & Đăng xuất ───────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3EFEC)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: authState.isLoading ? null : () => _confirmLogout(context),
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
                            : 'Đăng xuất tài khoản',
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
          const SizedBox(height: 16),
          // Nút về trang chủ nổi bật
          OutlinedButton.icon(
            onPressed: () => context.go(AppConstants.homeRoute),
            icon: const Icon(Icons.home_outlined, color: _teal),
            label: const Text(
              'Về trang chủ',
              style: TextStyle(
                color: _teal,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: _teal, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
