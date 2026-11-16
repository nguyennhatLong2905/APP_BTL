import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/data_management_provider.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  static const Color _teal = Color(0xFF2C7873);

  bool _hideAmount = false;
  bool _appLock = false;

  Future<void> _handleImportCSV() async {
    AppSnackBar.showWarning(context, 'Chức năng chọn file CSV đang được phát triển...');
  }

  Future<void> _handleExportData() async {
    try {
      final bytes = await ref.read(dataManagementProvider.notifier).exportTransactionsCsv();
      // In a real app, save bytes to a file. For now, show success.
      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Xuất dữ liệu thành công (${bytes.length} bytes)');
    } catch (e) {
      AppSnackBar.showError(context, e.toString());
    }
  }

  Future<void> _handleBackup() async {
    try {
      final backup = await ref.read(dataManagementProvider.notifier).createBackup();
      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Đã tạo bản sao lưu thành công');
    } catch (e) {
      AppSnackBar.showError(context, e.toString());
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
        )
      );

      if (confirm == true) {
        await ref.read(dataManagementProvider.notifier).eraseData(preview['previewId'] ?? '', 'CONFIRM');
        if (!mounted) return;
        AppSnackBar.showSuccess(context, 'Đã xóa dữ liệu');
      }
    } catch (e) {
      AppSnackBar.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dataManagementProvider);

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
                  SwitchListTile(
                    value: _hideAmount,
                    onChanged: (v) => setState(() => _hideAmount = v),
                    title: const Text('Ẩn số tiền', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    subtitle: const Text('không thay đổi dữ liệu nghiệp vụ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    secondary: const Icon(Icons.visibility_off_rounded, color: _teal),
                    activeColor: _teal,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _appLock,
                    onChanged: (v) => setState(() => _appLock = v),
                    title: const Text('Khóa app', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    subtitle: const Text('thay đổi cách truy cập', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    secondary: const Icon(Icons.lock_rounded, color: _teal),
                    activeColor: _teal,
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
