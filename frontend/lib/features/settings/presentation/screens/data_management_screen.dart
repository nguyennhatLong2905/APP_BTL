import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../providers/data_management_provider.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  static const Color _teal = Color(0xFF2C7873);

  bool _appLock = false;

  Future<void> _handleImportCSV() async {
    AppSnackBar.showWarning(context, 'Chức năng chọn file CSV đang được phát triển...');
  }

  /// Xuất dữ liệu: gọi API, lưu file CSV vào thư mục Downloads, thông báo đường dẫn.
  Future<void> _handleExportData() async {
    try {
      // Hiển thị dialog chọn thời gian
      final dateRange = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        ),
        helpText: 'Chọn khoảng thời gian xuất',
        cancelText: 'Hủy',
        confirmText: 'Xuất',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: _teal),
            ),
            child: child!,
          );
        },
      );

      if (dateRange == null) return;
      if (!mounted) return;

      AppSnackBar.showWarning(context, 'Đang xuất dữ liệu...');

      final startAt = DateFormat("yyyy-MM-dd'T'00:00:00.000'Z'").format(dateRange.start.toUtc());
      final endAt = DateFormat("yyyy-MM-dd'T'23:59:59.999'Z'").format(dateRange.end.toUtc());

      final bytes = await ref.read(dataManagementProvider.notifier).exportTransactionsCsv(
        startAt: startAt,
        endAt: endAt,
      );

      if (!mounted) return;

      // Lưu file vào thư mục Downloads của thiết bị
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) dir = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }

      if (!mounted) return;
      if (dir == null) {
        AppSnackBar.showError(context, 'Không thể lưu file trên thiết bị này');
        return;
      }

      final fileName = 'vi_an_transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        'Đã xuất ${bytes.length} bytes → ${file.path}',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Lỗi xuất dữ liệu: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  Future<void> _handleBackup() async {
    try {
      await ref.read(dataManagementProvider.notifier).createBackup();
      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Đã tạo bản sao lưu thành công');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _handleWipeData() async {
    try {
      final preview = await ref.read(dataManagementProvider.notifier).previewErase();
      if (!mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Sẽ xóa: ${preview.toString()}. Bạn chắc chứ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await ref.read(dataManagementProvider.notifier).eraseData(preview['previewId'] ?? '', 'CONFIRM');
        if (!mounted) return;
        AppSnackBar.showSuccess(context, 'Đã xóa dữ liệu');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dataManagementProvider);
    // Lấy trạng thái ẩn số tiền từ homeProvider (nguồn duy nhất của sự thật)
    final balanceVisible = ref.watch(homeProvider).balanceVisible;

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF9),
      appBar: AppBar(
        title: const Text('Nhập, xuất và kiểm soát dữ liệu'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                title: 'Nhập & Xuất',
                children: [
                  _ActionTile(
                    icon: Icons.upload_file_rounded,
                    title: 'Nhập CSV',
                    subtitle: 'chọn file → ghép cột → xem trước → ...',
                    onTap: _handleImportCSV,
                  ),
                  const Divider(height: 1),
                  _ActionTile(
                    icon: Icons.download_rounded,
                    title: 'Xuất dữ liệu',
                    subtitle: 'chọn thời gian, ví và định dạng → tạo file',
                    onTap: _handleExportData,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Sao lưu & Khôi phục',
                children: [
                  _ActionTile(
                    icon: Icons.backup_rounded,
                    title: 'Sao lưu',
                    subtitle: 'tạo bản sao dữ liệu an toàn',
                    onTap: _handleBackup,
                  ),
                  const Divider(height: 1),
                  _ActionTile(
                    icon: Icons.restore_rounded,
                    title: 'Khôi phục',
                    subtitle: 'xem dữ liệu sẽ thay thế hoặc bổ sung',
                    onTap: () {
                      AppSnackBar.showWarning(context, 'Chức năng chọn file để khôi phục đang được phát triển.');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Bảo mật & Hiển thị',
                children: [
                  // Ẩn số tiền — kết nối với homeProvider để đồng bộ toàn app
                  SwitchListTile(
                    value: !balanceVisible,
                    onChanged: (v) {
                      // Toggle qua homeProvider → cập nhật balance_card & các nơi dùng balanceVisible
                      ref.read(homeProvider.notifier).toggleBalanceVisibility();
                    },
                    title: const Text('Ẩn số tiền', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    subtitle: const Text('ẩn số dư & giao dịch trong toàn bộ app', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    secondary: const Icon(Icons.visibility_off_rounded, color: _teal),
                    activeThumbColor: _teal,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _appLock,
                    onChanged: (v) => setState(() => _appLock = v),
                    title: const Text('Khóa app', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    subtitle: const Text('thay đổi cách truy cập', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    secondary: const Icon(Icons.lock_rounded, color: _teal),
                    activeThumbColor: _teal,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Vùng nguy hiểm',
                children: [
                  _ActionTile(
                    icon: Icons.delete_forever_rounded,
                    iconColor: Colors.red,
                    title: 'Xóa dữ liệu',
                    titleColor: Colors.red,
                    subtitle: 'hiển thị tác động → xác nhận trước khi xóa',
                    onTap: _handleWipeData,
                  ),
                ],
              ),
            ],
          ),
          if (state.isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(color: _teal),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3EFEC)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF2C7873)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: titleColor ?? Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
