import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';

import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/currency_text_field.dart';
import '../../domain/models/report_data.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../transaction/data/datasources/attachment_remote_data_source.dart';
import '../providers/report_provider.dart';

const _teal = Color(0xFF1A6B5A);
const _danger = Color(0xFFD32F2F);

final _moneyFormat = NumberFormat('#,###', 'vi_VN');

/// Mở sheet thao tác cho một giao dịch (Sửa / Hủy).
Future<void> showTransactionActions(
  BuildContext context,
  WidgetRef ref,
  ReportTransaction tx,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _TransactionActionSheet(tx: tx),
  );
  if (action == null || !context.mounted) return;

  if (action == 'edit') {
    await showDialog<void>(
      context: context,
      builder: (_) => _EditTransactionDialog(tx: tx),
    );
  } else if (action == 'delete') {
    final ok = await _confirmDelete(context, ref, tx);
    if (ok && context.mounted) {
      AppSnackBar.showSuccess(context, 'Đã hủy giao dịch');
    }
  } else if (action == 'attachment') {
    await _showAttachment(context, ref, tx.attachmentIds.first);
  } else if (action == 'review') {
    context.push(AppConstants.timelineRoute);
  }
}

Future<void> _showAttachment(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  await showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      child: FutureBuilder<List<int>>(
        future: ref
            .read(attachmentRemoteDataSourceProvider)
            .downloadAttachment(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(color: _teal)),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Không thể tải ảnh hóa đơn.'),
            );
          }
          return InteractiveViewer(
            child: Image.memory(
              Uint8List.fromList(snapshot.data!),
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    ),
  );
}

class _TransactionActionSheet extends StatelessWidget {
  final ReportTransaction tx;
  const _TransactionActionSheet({required this.tx});

  @override
  Widget build(BuildContext context) {
    final amount = _moneyFormat.format(tx.amount.abs().toInt());
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$amount đ • ${tx.walletLabel}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: _teal),
              title: const Text('Sửa giao dịch'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined, color: _teal),
              title: const Text('Xem ảnh hóa đơn'),
              onTap: tx.attachmentIds.isEmpty
                  ? null
                  : () => Navigator.of(context).pop('attachment'),
            ),
            if (tx.type == TransactionType.expense && !tx.isVoided)
              ListTile(
                leading: const Icon(Icons.rate_review_outlined, color: _teal),
                title: const Text('Đánh giá giao dịch'),
                onTap: () => Navigator.of(context).pop('review'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: _danger),
              title: const Text(
                'Hủy giao dịch',
                style: TextStyle(color: _danger),
              ),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Color(0xFF6B7280)),
              title: const Text('Đóng'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Xác nhận hủy giao dịch và gọi API
Future<bool> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  ReportTransaction tx,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Hủy giao dịch?'),
      content: Text(
        '"${tx.title}" sẽ bị hủy và số tiền được hoàn lại vào ví. '
        'Giao dịch vẫn được lưu trong lịch sử ở trạng thái đã hủy.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Không'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _danger,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Hủy giao dịch'),
        ),
      ],
    ),
  );
  if (confirm != true) return false;

  final error = await ref.read(reportProvider.notifier).voidTransaction(tx);
  if (error != null) {
    if (context.mounted) AppSnackBar.showError(context, error);
    return false;
  }
  return true;
}

/// Dialog sửa số tiền / ngày / ghi chú
class _EditTransactionDialog extends ConsumerStatefulWidget {
  final ReportTransaction tx;
  const _EditTransactionDialog({required this.tx});

  @override
  ConsumerState<_EditTransactionDialog> createState() =>
      _EditTransactionDialogState();
}

class _EditTransactionDialogState
    extends ConsumerState<_EditTransactionDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.tx.amount.abs().toInt().toString();
    _amountController = TextEditingController(text: initial)
      ..selection = TextSelection.collapsed(offset: initial.length);
    _noteController = TextEditingController(text: widget.tx.note);
    _noteController.selection = TextSelection.collapsed(
      offset: _noteController.text.length,
    );
    _date = widget.tx.dateTime.toLocal();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null) return;
    // Giữ giờ/phút hiện có của giao dịch, chỉ đổi ngày
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
        _date.second,
      );
    });
  }

  Future<void> _save() async {
    final amount = CurrencyTextField.getRawAmount(_amountController);
    if (amount <= 0) {
      AppSnackBar.showError(context, 'Số tiền phải lớn hơn 0');
      return;
    }

    setState(() => _saving = true);
    final error = await ref
        .read(reportProvider.notifier)
        .editTransaction(
          tx: widget.tx,
          amount: amount,
          occurredAt: _date,
          note: _noteController.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      AppSnackBar.showError(context, error);
      return;
    }
    Navigator.of(context).pop();
    AppSnackBar.showSuccess(context, 'Đã cập nhật giao dịch');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Sửa giao dịch'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurrencyTextField(
            controller: _amountController,
            labelText: 'Số tiền',
            hintText: '0',
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Ngày giao dịch',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              ),
              child: Text(
                DateFormat('dd/MM/yyyy').format(_date),
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Ghi chú',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
