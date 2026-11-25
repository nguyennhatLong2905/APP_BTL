import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/refresh_financial_data.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../providers/data_management_provider.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() =>
      _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  static const Color _teal = Color(0xFF2C7873);

  Future<void> _handleImportCSV() async {
    try {
      final notifier = ref.read(dataManagementProvider.notifier);
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'CSV',
            extensions: ['csv'],
            uniformTypeIdentifiers: ['public.comma-separated-values-text'],
            mimeTypes: ['text/csv'],
          ),
        ],
      );
      if (file == null || !mounted) return;
      final preview = await notifier.previewImport(await file.readAsString());
      if (!mounted) return;
      final rows = (preview['rows'] as List).cast<Map<String, dynamic>>();
      final valid = rows
          .where(
            (row) => row['error'] == null && row['suspectedDuplicate'] != true,
          )
          .toList();
      final skipped = rows.length - valid.length;
      if (valid.isEmpty) {
        AppSnackBar.showWarning(
          context,
          'Không có dòng hợp lệ để nhập. Hãy dùng các cột từ file CSV xuất của Ví An.',
        );
        return;
      }
      if (!await _confirm(
            'Nhập CSV',
            'Nhập ${valid.length} giao dịch hợp lệ. Bỏ qua $skipped dòng lỗi hoặc nghi trùng.',
            'Nhập',
          ) ||
          !mounted) {
        return;
      }
      final result = await notifier.commitImport(
        preview['_id'] as String,
        valid.map((row) => row['index'] as int).toList(),
        false,
      );
      if (!mounted) return;
      invalidateFinancialDataFromWidget(ref);
      AppSnackBar.showSuccess(
        context,
        'Đã nhập ${result['imported']} giao dịch.',
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _handleExportData() async {
    try {
      final now = DateTime.now();
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: now,
        initialDateRange: DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        ),
        helpText: 'Chọn khoảng thời gian xuất',
        cancelText: 'Hủy',
        confirmText: 'Xuất',
        saveText: 'Xuất',
      );
      if (range == null || !mounted) return;
      final end = DateTime(range.end.year, range.end.month, range.end.day + 1);
      final bytes = await ref
          .read(dataManagementProvider.notifier)
          .exportTransactionsCsv(
            startAt: range.start.toUtc().toIso8601String(),
            endAt: end.toUtc().toIso8601String(),
          );
      await _saveFile(bytes, 'giao-dich', 'csv', 'text/csv');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _handleBackup() async {
    try {
      final backup = await ref
          .read(dataManagementProvider.notifier)
          .createBackup();
      await _saveFile(
        utf8.encode(jsonEncode(backup)),
        'sao-luu',
        'json',
        'application/json',
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _handleRestore() async {
    try {
      final notifier = ref.read(dataManagementProvider.notifier);
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'JSON',
            extensions: ['json'],
            uniformTypeIdentifiers: ['public.json'],
            mimeTypes: ['application/json'],
          ),
        ],
      );
      if (file == null || !mounted) return;
      final backup =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final preview = await notifier.previewRestore(backup);
      if (!mounted) return;
      if (!await _confirm(
            'Khôi phục dữ liệu',
            'Bản sao sẽ thay thế dữ liệu tài chính hiện tại. Sau khi khôi phục, bạn cần đăng nhập lại.',
            'Khôi phục',
          ) ||
          !mounted) {
        return;
      }
      await notifier.restoreBackup(
        preview['previewId'] as String,
        preview['confirmationText'] as String,
      );
      if (!mounted) return;
      await ref.read(authProvider.notifier).logout();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _handleWipeData() async {
    try {
      final notifier = ref.read(dataManagementProvider.notifier);
      final preview = await notifier.previewErase();
      if (!mounted) return;
      if (!await _confirm(
            'Xác nhận xóa',
            'Ví, giao dịch, ngân sách, mục tiêu và hóa đơn sẽ bị xóa. Bạn cần đăng nhập lại sau khi xóa.',
            'Xóa dữ liệu',
          ) ||
          !mounted) {
        return;
      }
      await notifier.eraseData(
        preview['previewId'] as String,
        preview['confirmationText'] as String,
      );
      if (!mounted) return;
      await ref.read(authProvider.notifier).logout();
    } catch (error) {
      _showError(error);
    }
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _saveFile(
    List<int> bytes,
    String label,
    String extension,
    String mimeType,
  ) async {
    if (!mounted) return;
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'vi-an-$label-$stamp.$extension';
    final file = XFile.fromData(
      Uint8List.fromList(bytes),
      name: filename,
      mimeType: mimeType,
    );
    if (kIsWeb) {
      await file.saveTo(filename);
    } else {
      final dir = Platform.isAndroid || Platform.isIOS
          ? await getApplicationDocumentsDirectory()
          : await getDownloadsDirectory() ??
                await getApplicationDocumentsDirectory();
      await file.saveTo('${dir.path}/$filename');
    }
    if (mounted) AppSnackBar.showSuccess(context, 'Đã lưu $filename');
  }

  void _showError(Object error) {
    if (mounted) AppSnackBar.showError(context, error.toString());
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
                    subtitle: 'Xem trước và nhập theo cột CSV của Ví An',
                    onTap: _handleImportCSV,
                  ),
                  const Divider(height: 1),
                  _ActionTile(
                    icon: Icons.download_rounded,
                    title: 'Xuất dữ liệu',
                    subtitle: 'Chọn khoảng thời gian và tải CSV',
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
                    subtitle: 'Thay thế dữ liệu từ bản sao lưu của bạn',
                    onTap: _handleRestore,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Bảo mật & Hiển thị',
                children: [
                  SwitchListTile(
                    value: !balanceVisible,
                    onChanged: (_) {
                      ref.read(homeProvider.notifier).toggleBalanceVisibility();
                    },
                    title: const Text(
                      'Ẩn số tiền',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      'Ẩn số dư và giao dịch trên Tổng quan',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    secondary: const Icon(
                      Icons.visibility_off_rounded,
                      color: _teal,
                    ),
                    activeThumbColor: _teal,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: false,
                    onChanged: null,
                    title: const Text(
                      'Khóa app',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: const Text(
                      'Chưa hỗ trợ khóa ứng dụng',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
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

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
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
        Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE3EFEC)),
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
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
