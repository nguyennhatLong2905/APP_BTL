import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/currency_text_field.dart';
import '../../domain/models/receipt.dart';
import 'transaction_keypad.dart';

class ReceiptScanPrompt extends StatelessWidget {
  const ReceiptScanPrompt({
    super.key,
    required this.supported,
    required this.busy,
    required this.reading,
    required this.onCamera,
    required this.onGallery,
    required this.onManual,
    this.error,
  });

  final bool supported;
  final bool busy;
  final bool reading;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onManual;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        const Text(
          'Quét hóa đơn',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: transactionInk,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Chụp hoặc chọn ảnh để điền thông tin giao dịch.',
          textAlign: TextAlign.center,
          style: TextStyle(color: transactionMuted),
        ),
        const SizedBox(height: 24),
        Container(
          height: 205,
          decoration: BoxDecoration(
            color: transactionMint,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: reading
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: transactionPrimary),
                    const SizedBox(height: 14),
                    Semantics(
                      liveRegion: true,
                      child: const Text('Đang đọc hóa đơn…'),
                    ),
                  ],
                )
              : const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.crop_free_rounded,
                      color: transactionPrimary,
                      size: 126,
                    ),
                    Icon(
                      Icons.receipt_long_outlined,
                      color: transactionPrimary,
                      size: 70,
                    ),
                  ],
                ),
        ),
        if (error != null || !supported) ...[
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: Text(
              error ?? 'Quét OCR trên thiết bị khả dụng trên Android và iOS.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: error == null
                    ? transactionMuted
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: supported && !busy ? onCamera : null,
          style: FilledButton.styleFrom(
            backgroundColor: transactionPrimary,
            minimumSize: const Size(0, 52),
          ),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Chụp hóa đơn'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: supported && !busy ? onGallery : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: transactionPrimary,
            minimumSize: const Size(0, 52),
            side: const BorderSide(color: transactionPrimary),
          ),
          icon: const Icon(Icons.image_outlined),
          label: const Text('Chọn ảnh có sẵn'),
        ),
        if (error != null || !supported)
          TextButton(
            onPressed: onManual,
            child: const Text('Chuyển sang nhập tay'),
          ),
      ],
    );
  }
}

class ReceiptPhotoPreview extends StatelessWidget {
  const ReceiptPhotoPreview({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    void open() => showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: InteractiveViewer(
                maxScale: 6,
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng ảnh'),
            ),
          ],
        ),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: open,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.memory(
              bytes,
              width: 64,
              height: 58,
              fit: BoxFit.cover,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: open,
          style: TextButton.styleFrom(foregroundColor: transactionPrimary),
          icon: const Icon(Icons.image_outlined),
          label: const Text('Xem ảnh gốc'),
        ),
      ],
    );
  }
}

class ReceiptLineTile extends StatelessWidget {
  const ReceiptLineTile({
    super.key,
    required this.line,
    required this.onEdit,
    required this.onDelete,
  });

  final ReceiptLine line;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: transactionBorder),
    ),
    child: Row(
      children: [
        const SizedBox(width: 10),
        const Icon(Icons.receipt_outlined, color: transactionPrimary, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(line.name)),
        const SizedBox(width: 6),
        Flexible(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: transactionMint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              child: Text(
                '${CurrencyTextField.formatAmount(line.amount)} đ',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Sửa dòng',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          color: transactionPrimary,
        ),
        IconButton(
          tooltip: 'Xóa dòng',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          color: transactionMuted,
        ),
      ],
    ),
  );
}

enum ReceiptEdit { total, merchant, line }

Future<ReceiptLine?> editReceiptField(
  BuildContext context, {
  required ReceiptEdit field,
  ReceiptLine? initial,
}) => showDialog<ReceiptLine>(
  context: context,
  builder: (_) => _ReceiptFieldDialog(field: field, initial: initial),
);

class _ReceiptFieldDialog extends StatefulWidget {
  const _ReceiptFieldDialog({required this.field, this.initial});

  final ReceiptEdit field;
  final ReceiptLine? initial;

  @override
  State<_ReceiptFieldDialog> createState() => _ReceiptFieldDialogState();
}

class _ReceiptFieldDialogState extends State<_ReceiptFieldDialog> {
  final _form = GlobalKey<FormState>();
  String _name = '';
  int _amount = 0;

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    return AlertDialog(
      title: Text(switch (field) {
        ReceiptEdit.total => 'Số tiền giao dịch',
        ReceiptEdit.merchant => 'Tên cửa hàng',
        ReceiptEdit.line => widget.initial == null ? 'Thêm dòng' : 'Sửa dòng',
      }),
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (field != ReceiptEdit.total)
              TextFormField(
                initialValue: widget.initial?.name,
                autofocus: true,
                maxLength: 160,
                decoration: InputDecoration(
                  labelText: field == ReceiptEdit.merchant
                      ? 'Tên cửa hàng'
                      : 'Tên món',
                ),
                validator: (value) =>
                    field == ReceiptEdit.line && value!.trim().isEmpty
                    ? 'Nhập tên món.'
                    : null,
                onSaved: (value) => _name = value!.trim(),
              ),
            if (field != ReceiptEdit.merchant)
              TextFormField(
                initialValue: widget.initial?.amount.toString(),
                autofocus: field == ReceiptEdit.total,
                keyboardType: TextInputType.number,
                inputFormatters: const [CurrencyInputFormatter()],
                decoration: InputDecoration(
                  labelText: field == ReceiptEdit.total
                      ? 'Số tiền'
                      : 'Thành tiền',
                  suffixText: 'đ',
                ),
                validator: (value) {
                  final amount = int.tryParse(value ?? '');
                  if (amount == null ||
                      (field == ReceiptEdit.total && amount <= 0)) {
                    return field == ReceiptEdit.total
                        ? 'Nhập số tiền lớn hơn 0.'
                        : 'Nhập thành tiền.';
                  }
                  return null;
                },
                onSaved: (value) => _amount = int.parse(value!),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            _form.currentState!.save();
            Navigator.pop(context, ReceiptLine(_name, _amount));
          },
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
