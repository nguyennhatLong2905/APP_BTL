import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/currency_text_field.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/transaction_category.dart';
import '../../providers/transaction_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_keypad.dart';
import '../widgets/receipt_scan_widgets.dart';
import '../../data/receipt_mvp/du_lieu/bo_chon_anh.dart';
import '../../data/receipt_mvp/mo_hinh/hoa_don.dart';
import '../../data/receipt_mvp/nen_tang/chon_anh.dart';
import '../../data/receipt_mvp/ocr/bo_nhan_dang.dart';
import '../../data/receipt_scanner.dart';
import '../../domain/models/receipt.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();
  bool _noteExpanded = false;
  bool _pickingPhoto = false;
  bool _openingWalletPicker = false;
  final _receiptNoteController = TextEditingController();
  bool _ocrTab = false;
  bool _pickingReceipt = false;
  bool _readingReceipt = false;
  String? _receiptError;
  ScannedReceipt? _receipt;

  bool get _scanBusy => _pickingReceipt || _readingReceipt;

  static const _tabs = [
    (TransactionType.expense, 'Chi tiêu', Icons.arrow_downward_rounded),
    (TransactionType.income, 'Thu nhập', Icons.arrow_upward_rounded),
    (TransactionType.transfer, 'Chuyển ví', Icons.swap_horiz_rounded),
  ];

  @override
  void initState() {
    super.initState();
    final draft = ref.read(transactionFormProvider);
    if (draft.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(transactionFormProvider).isSuccess) {
          ref.read(transactionFormProvider.notifier).reset();
        }
      });
    } else {
      _noteController.text = draft.note;
    }
    _noteFocus.addListener(_updateNoteFocus);
  }

  void _updateNoteFocus() => setState(() {});

  @override
  void dispose() {
    _noteFocus.removeListener(_updateNoteFocus);
    _noteFocus.dispose();
    _noteController.dispose();
    _receiptNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionFormProvider);
    final notifier = ref.read(transactionFormProvider.notifier);
    final categories = ref.watch(currentCategoriesProvider);
    final receiptForm = ref.watch(receiptTransactionFormProvider);
    final receiptNotifier = ref.read(receiptTransactionFormProvider.notifier);
    final showOcr = state.type == TransactionType.expense && _ocrTab;
    ref.listen(receiptTransactionFormProvider, (previous, next) {
      if (!next.isSuccess || (previous?.isSuccess ?? false)) return;
      receiptNotifier.reset();
      _receiptNoteController.clear();
      setState(() => _receipt = null);
      _showSaved();
    });
    final editingNote =
        _noteFocus.hasFocus && MediaQuery.viewInsetsOf(context).bottom > 0;
    final busy = state.isLoading || _pickingPhoto;
    final saveBlockReason = state.saveBlockReason;

    ref.listen(transactionFormProvider, (previous, next) {
      if ((previous?.isLoading ?? false) && next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
      if (!next.isSuccess || (previous?.isSuccess ?? false)) return;
      _noteController.clear();
      _noteFocus.unfocus();
      setState(() => _noteExpanded = false);
      notifier.reset();
      _showSaved();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              context,
              saving: state.isLoading || receiptForm.isLoading,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: AbsorbPointer(
                absorbing: busy || _scanBusy || receiptForm.isLoading,
                child: Column(
                  children: [
                    _buildTabs(state, notifier),
                    if (state.type == TransactionType.expense)
                      _buildEntryTabs(),
                  ],
                ),
              ),
            ),
            if (showOcr)
              Expanded(
                child: _buildReceipt(receiptForm, receiptNotifier, categories),
              )
            else
              Expanded(
                child: AbsorbPointer(
                  absorbing: busy,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    children: [
                      const SizedBox(height: 8),
                      _buildAmount(state.amount),
                      const SizedBox(height: 12),
                      _buildQuickAmounts(notifier),
                      const SizedBox(height: 10),
                      _buildDateAndWallet(state, notifier),
                      const SizedBox(height: 12),
                      if (state.isTransfer)
                        _buildDestination(state)
                      else
                        _buildCategories(state, notifier, categories),
                      const SizedBox(height: 12),
                      _buildNotes(state, notifier),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              state.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (!showOcr && !editingNote)
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: transactionBorder)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TransactionKeypad(
                        enabled: !busy,
                        onKey: (key) {
                          switch (key) {
                            case 'Xóa':
                              notifier.deleteDigit();
                            case '000':
                              notifier.appendDigits(0, placeValue: 1000);
                            default:
                              notifier.appendDigits(int.parse(key));
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (!busy && saveBlockReason != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            saveBlockReason,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: transactionMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      _buildSave(state, notifier, busy),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryTabs() {
    return Row(
      children: [
        for (final (isOcr, label) in [(false, 'Nhập tay'), (true, 'Quét OCR')])
          Expanded(
            child: Semantics(
              selected: _ocrTab == isOcr,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _ocrTab == isOcr
                          ? transactionPrimary
                          : transactionBorder,
                      width: _ocrTab == isOcr ? 2 : 1,
                    ),
                  ),
                ),
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _ocrTab == isOcr
                        ? transactionPrimary
                        : transactionMuted,
                    textStyle: TextStyle(
                      fontWeight: _ocrTab == isOcr
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _ocrTab = isOcr);
                  },
                  child: Text(label),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _scan(NguonAnh source) async {
    if (_scanBusy) return;
    setState(() => _pickingReceipt = true);
    try {
      final photo = await ref.read(receiptImagePickerProvider).chon(source);
      if (photo == null || !mounted) return;
      setState(() {
        _readingReceipt = true;
        _receiptError = null;
      });
      final result = await scanReceipt(
        photo,
        ref.read(receiptRecognitionProvider)(),
      );
      if (!mounted) return;
      if (result == null) {
        setState(
          () => _receiptError =
              'Không tìm thấy chữ. Thử chụp rõ hơn hoặc chọn ảnh khác.',
        );
        return;
      }
      ref
          .read(receiptTransactionFormProvider.notifier)
          .loadReceipt(result.draft, result.attachment);
      _receiptNoteController.clear();
      setState(() => _receipt = result);
    } on LoiChonAnh catch (error) {
      if (!mounted) return;
      setState(
        () => _receiptError = switch (error.loai) {
          LoaiLoiChonAnh.khongCoQuyen =>
            'Hãy cho phép truy cập trong cài đặt thiết bị rồi thử lại.',
          LoaiLoiChonAnh.khongCoCamera =>
            'Không mở được camera. Bạn có thể chọn ảnh có sẵn.',
          LoaiLoiChonAnh.khac =>
            'Không thể mở camera hoặc thư viện. Hãy thử lại.',
        },
      );
    } on LoiNhanDang catch (error) {
      if (!mounted) return;
      setState(
        () => _receiptError = switch (error.loai) {
          LoaiLoiNhanDang.khongDocDuocAnh =>
            'Không đọc được tệp ảnh. Hãy chụp lại hoặc chọn ảnh khác.',
          LoaiLoiNhanDang.khongHoTro => 'Thiết bị này không hỗ trợ quét OCR.',
          LoaiLoiNhanDang.thatBai =>
            'Không đọc được hóa đơn. Hãy chụp lại hoặc chọn ảnh khác.',
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _receiptError =
            'Không đọc được hóa đơn. Hãy chụp lại hoặc chọn ảnh khác.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _pickingReceipt = false;
          _readingReceipt = false;
        });
      }
    }
  }

  Widget _buildReceipt(
    TransactionFormState state,
    TransactionFormNotifier notifier,
    List<TransactionCategory> categories,
  ) {
    final result = _receipt;
    if (result == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          ReceiptScanPrompt(
            supported: coOcrThietBi,
            busy: _scanBusy,
            reading: _readingReceipt,
            error: _receiptError,
            onCamera: () => _scan(NguonAnh.mayAnh),
            onGallery: () => _scan(NguonAnh.thuVien),
            onManual: () => setState(() => _ocrTab = false),
          ),
        ],
      );
    }
    final activeIds = ref
        .watch(transactionProvider.select((data) => data.categories))
        .where((category) => category.isActive && category.type == 'expense')
        .map((category) => category.id)
        .toSet();
    final activeCategories = categories
        .where((item) => activeIds.contains(item.id))
        .toList();
    final blockReason = state.error ?? state.saveBlockReason;
    return AbsorbPointer(
      absorbing: state.isLoading,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          const Text(
            'Kết quả quét',
            style: TextStyle(
              color: transactionInk,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ReceiptPhotoPreview(bytes: result.original),
          const SizedBox(height: 10),
          _buildAmount(
            state.amount,
            onEdit: () async {
              final edited = await editReceiptField(
                context,
                field: ReceiptEdit.total,
                initial: state.amount == 0
                    ? null
                    : ReceiptLine('', state.amount),
              );
              if (mounted && edited != null) {
                notifier.setReceiptAmount(edited.amount);
              }
            },
          ),
          const SizedBox(height: 10),
          _buildDateAndWallet(state, notifier, receipt: true),
          const SizedBox(height: 10),
          _FormFieldTile(
            label: 'Tên cửa hàng',
            value: state.merchant.isEmpty
                ? 'Nhập tên cửa hàng'
                : state.merchant,
            icon: Icons.storefront_outlined,
            trailing: const Icon(
              Icons.edit_outlined,
              color: transactionPrimary,
              size: 19,
            ),
            onTap: () async {
              final edited = await editReceiptField(
                context,
                field: ReceiptEdit.merchant,
                initial: ReceiptLine(state.merchant, 0),
              );
              if (mounted && edited != null) notifier.setMerchant(edited.name);
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Chi tiết hóa đơn',
            style: TextStyle(
              color: transactionInk,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final (index, line) in state.receiptLines.indexed)
            ReceiptLineTile(
              line: line,
              onEdit: () =>
                  _editReceiptLine(notifier, state.receiptLines, index),
              onDelete: () => notifier.setReceiptLines(
                [...state.receiptLines]..removeAt(index),
              ),
            ),
          FilledButton.tonalIcon(
            onPressed: state.receiptLines.length >= ReceiptLine.maxCount
                ? null
                : () => _editReceiptLine(notifier, state.receiptLines),
            style: FilledButton.styleFrom(
              backgroundColor: transactionMint,
              foregroundColor: transactionPrimary,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm dòng'),
          ),
          const SizedBox(height: 10),
          _buildCategories(state, notifier, activeCategories, receipt: true),
          if (activeCategories.isEmpty)
            TextButton(
              onPressed: ref.read(transactionProvider.notifier).loadCategories,
              child: const Text('Tải lại danh mục chi tiêu'),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _receiptNoteController,
            readOnly: state.isLoading,
            onChanged: notifier.setNote,
            maxLength: 2000,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
              prefixIcon: Icon(
                Icons.note_alt_outlined,
                color: transactionPrimary,
              ),
              counterText: '',
            ),
          ),
          if (blockReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  blockReason,
                  style: TextStyle(
                    color: state.error == null
                        ? transactionMuted
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          _buildSave(state, notifier, state.isLoading),
        ],
      ),
    );
  }

  Future<void> _editReceiptLine(
    TransactionFormNotifier notifier,
    List<ReceiptLine> lines, [
    int? index,
  ]) async {
    final edited = await editReceiptField(
      context,
      field: ReceiptEdit.line,
      initial: index == null ? null : lines[index],
    );
    if (!mounted || edited == null) return;
    final updated = [...lines];
    if (index == null) {
      updated.add(edited);
    } else {
      updated[index] = edited;
    }
    notifier.setReceiptLines(updated);
  }

  void _showSaved() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu giao dịch thành công!'),
        backgroundColor: transactionPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool saving}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          IconButton(
            onPressed: saving
                ? null
                : () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppConstants.homeRoute);
                    }
                  },
            tooltip: 'Quay lại',
            color: transactionPrimary,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const Expanded(
            child: Text(
              'Thêm giao dịch',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: transactionInk,
              ),
            ),
          ),
          IconButton(
            onPressed: saving
                ? null
                : () => context.go(AppConstants.notificationsRoute),
            tooltip: 'Thông báo',
            color: transactionPrimary,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            onPressed: saving
                ? null
                : () => context.go(AppConstants.settingsRoute),
            tooltip: 'Tài khoản',
            style: IconButton.styleFrom(
              backgroundColor: transactionPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size.square(44),
            ),
            icon: const Icon(Icons.person_rounded, size: 21),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(
    TransactionFormState state,
    TransactionFormNotifier notifier,
  ) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: transactionMint,
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (type, label, icon) in _tabs)
                Expanded(
                  child: Semantics(
                    selected: state.type == type,
                    child: TextButton(
                      onPressed: () => notifier.setType(type),
                      style: TextButton.styleFrom(
                        shape: const StadiumBorder(),
                        foregroundColor: state.type == type
                            ? Colors.white
                            : transactionInk,
                        backgroundColor: state.type == type
                            ? transactionPrimary
                            : Colors.transparent,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 14),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(label, textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmount(int amount, {VoidCallback? onEdit}) {
    final card = Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: transactionMint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            children: [
              const Text(
                'Số tiền giao dịch',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: transactionInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  text: CurrencyTextField.formatAmount(amount),
                  children: const [
                    TextSpan(
                      text: ' đ',
                      style: TextStyle(fontSize: 25, color: transactionPrimary),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 42,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: transactionInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (onEdit == null) return card;
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: transactionMint,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Row(
          children: [
            const SizedBox(width: 48),
            Expanded(child: card),
            IconButton(
              tooltip: 'Sửa số tiền',
              onPressed: onEdit,
              color: transactionPrimary,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAmounts(TransactionFormNotifier notifier) {
    const amounts = [10000, 50000, 100000];
    return Row(
      children: [
        for (final amount in amounts) ...[
          if (amount != amounts.first) const SizedBox(width: 6),
          Expanded(
            child: OutlinedButton(
              onPressed: () => notifier.addAmount(amount),
              style: OutlinedButton.styleFrom(
                foregroundColor: transactionInk,
                side: const BorderSide(color: transactionBorder),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '+${CurrencyTextField.formatAmount(amount)} đ',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateAndWallet(
    TransactionFormState state,
    TransactionFormNotifier notifier, {
    bool receipt = false,
  }) {
    final walletLabel = switch (state.type) {
      TransactionType.expense => 'Ví chi tiền',
      TransactionType.income => 'Ví nhận tiền',
      TransactionType.transfer => 'Từ ví',
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _FormFieldTile(
              label: 'Ngày ghi nhận',
              value: DateFormat('HH:mm, dd/MM').format(state.selectedDate),
              icon: Icons.calendar_today_outlined,
              onTap: () =>
                  _pickDate(state.selectedDate, notifier, withTime: receipt),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FormFieldTile(
              label: walletLabel,
              value: state.wallet?.name ?? 'Chọn ví',
              icon: Icons.account_balance_wallet_outlined,
              dropdown: true,
              onTap: () =>
                  _showWalletPicker(destination: false, receipt: receipt),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestination(TransactionFormState state) {
    final sameWallet =
        state.wallet != null && state.wallet?.id == state.toWallet?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FormFieldTile(
          label: 'Đến ví',
          value: state.toWallet?.name ?? 'Chọn ví nhận',
          icon: Icons.account_balance_wallet_outlined,
          dropdown: true,
          onTap: () => _showWalletPicker(destination: true),
        ),
        if (sameWallet)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Ví gửi và ví nhận phải khác nhau.',
              style: TextStyle(color: transactionMuted),
            ),
          ),
      ],
    );
  }

  Widget _buildCategories(
    TransactionFormState state,
    TransactionFormNotifier notifier,
    List<TransactionCategory> categories, {
    bool receipt = false,
  }) {
    final heading = Text(
      receipt ? 'Danh mục chi tiêu' : 'Danh mục phổ biến',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: transactionInk,
      ),
    );
    final popular = categories.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categories.length > 5)
          Row(
            children: [
              Expanded(child: heading),
              TextButton(
                onPressed: () => _showCategoryPicker(
                  categories,
                  state.selectedCategory,
                  notifier,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: transactionPrimary,
                ),
                child: const Text('Xem thêm'),
              ),
            ],
          )
        else ...[
          heading,
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final category in popular)
              Expanded(
                child: _CategoryTile(
                  category: category,
                  selected: category.id == state.selectedCategory?.id,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    notifier.selectCategory(category);
                  },
                ),
              ),
          ],
        ),
        if (state.selectedCategory case final selection?
            when !popular.any((category) => category.id == selection.id))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '✓ ${selection.name}',
              style: const TextStyle(
                color: transactionPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotes(
    TransactionFormState state,
    TransactionFormNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: _noteExpanded,
          child: _FormFieldTile(
            value: 'Ghi chú & ảnh hóa đơn',
            valueWeight: FontWeight.w700,
            icon: Icons.note_add_outlined,
            dropdown: true,
            expanded: _noteExpanded,
            onTap: () {
              if (_noteExpanded) _noteFocus.unfocus();
              setState(() => _noteExpanded = !_noteExpanded);
            },
          ),
        ),
        if (_noteExpanded) ...[
          const SizedBox(height: 8),
          TextField(
            focusNode: _noteFocus,
            controller: _noteController,
            maxLines: 2,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: transactionInk),
            onChanged: notifier.setNote,
            readOnly: state.isLoading,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
              labelStyle: TextStyle(color: transactionMuted),
              hintText: 'Nhập ghi chú',
              hintStyle: TextStyle(color: transactionMuted),
              counterText: '',
            ),
          ),
          if (state.photo case final photo?)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.image_outlined,
                color: transactionPrimary,
              ),
              title: Text(
                photo.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  child: InteractiveViewer(child: Image.file(File(photo.path))),
                ),
              ),
              trailing: IconButton(
                onPressed: () => notifier.setPhoto(null),
                tooltip: 'Gỡ ảnh',
                icon: const Icon(Icons.close_rounded),
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pickingPhoto ? null : () => _pickPhoto(notifier),
                label: const Text('Thêm ảnh hóa đơn'),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                style: TextButton.styleFrom(
                  foregroundColor: transactionPrimary,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSave(
    TransactionFormState state,
    TransactionFormNotifier notifier,
    bool busy,
  ) {
    return FilledButton.icon(
      onPressed: state.isValid && !state.isSuccess && !busy
          ? () {
              if (_ocrTab && state.type == TransactionType.expense) {
                FocusManager.instance.primaryFocus?.unfocus();
              }
              notifier.saveTransaction();
            }
          : null,
      style: FilledButton.styleFrom(
        backgroundColor: transactionPrimary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFCDE3D9),
        disabledForegroundColor: const Color(0xFF4B665C),
        minimumSize: const Size(0, 52),
        visualDensity: VisualDensity.standard,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      icon: state.isLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: transactionPrimary,
              ),
            )
          : const Icon(Icons.check_circle_outline_rounded),
      label: Text(
        state.isLoading ? 'Đang lưu…' : 'Lưu giao dịch',
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _pickDate(
    DateTime current,
    TransactionFormNotifier notifier, {
    bool withTime = false,
  }) async {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('vi'),
      initialDate: current.isAfter(now) ? today : current,
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Chọn ngày ghi nhận',
    );
    if (picked == null || !mounted) return;
    if (!withTime) {
      final time = DateTime.now();
      notifier.setDate(
        DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
          time.second,
        ),
      );
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: 'Chọn giờ ghi nhận',
    );
    if (time == null || !mounted) return;
    final date = DateTime(
      picked.year,
      picked.month,
      picked.day,
      time.hour,
      time.minute,
    );
    if (date.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày giờ ghi nhận không được ở tương lai.'),
        ),
      );
      return;
    }
    notifier.setDate(date);
  }

  Future<void> _showWalletPicker({
    required bool destination,
    bool receipt = false,
  }) async {
    final provider = receipt
        ? receiptTransactionFormProvider
        : transactionFormProvider;
    if (_openingWalletPicker) return;
    _noteFocus.unfocus();
    _openingWalletPicker = true;
    try {
      final walletNotifier = ref.read(transactionProvider.notifier);
      if (ref.read(transactionProvider).wallets.isEmpty) {
        await walletNotifier.loadWallets();
      }
      if (!mounted) return;

      final state = ref.read(provider);
      final selectedId = destination ? state.toWallet?.id : state.wallet?.id;
      final blockedId = state.isTransfer
          ? (destination ? state.wallet?.id : state.toWallet?.id)
          : null;
      final wallets = ref
          .read(transactionProvider)
          .wallets
          .where((wallet) => wallet.isActive);
      final picked = await showModalBottomSheet<WalletItem>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => _PickerSheet(
          title: destination ? 'Chọn ví nhận' : 'Chọn ví',
          children: [
            if (wallets.isEmpty)
              const ListTile(title: Text('Chưa có ví khả dụng.')),
            for (final wallet in wallets)
              ListTile(
                leading: Icon(
                  _walletIcon(wallet.type),
                  color: transactionPrimary,
                ),
                title: Text(wallet.name),
                subtitle: Text(
                  wallet.id == blockedId
                      ? 'Trùng với ví đã chọn'
                      : '${CurrencyTextField.formatAmount(wallet.balance)} đ',
                ),
                selected: wallet.id == selectedId,
                selectedColor: transactionPrimary,
                enabled: wallet.id != blockedId,
                trailing: wallet.id == selectedId
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: wallet.id == blockedId
                    ? null
                    : () => Navigator.pop(sheetContext, wallet),
              ),
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline_rounded,
                color: transactionPrimary,
              ),
              title: const Text('Tạo ví mới'),
              onTap: () {
                Navigator.pop(sheetContext);
                _createWallet();
              },
            ),
          ],
        ),
      );
      if (mounted && picked != null) {
        ref
            .read(provider.notifier)
            .selectWallet(picked, destination: destination);
      }
    } finally {
      _openingWalletPicker = false;
    }
  }

  Future<void> _createWallet() async {
    final created = await context.push<bool>('/create-wallet');
    if (!mounted || created != true) return;
    await ref.read(transactionProvider.notifier).loadWallets();
  }

  IconData _walletIcon(String? type) => switch (type) {
    'cash' => Icons.payments_outlined,
    'bank' => Icons.account_balance_outlined,
    'ewallet' => Icons.credit_card_rounded,
    'savings' => Icons.savings_outlined,
    _ => Icons.account_balance_wallet_outlined,
  };

  Future<void> _showCategoryPicker(
    List<TransactionCategory> categories,
    TransactionCategory? selected,
    TransactionFormNotifier notifier,
  ) async {
    final picked = await showModalBottomSheet<TransactionCategory>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _PickerSheet(
        title: 'Chọn danh mục',
        children: [
          for (final category in categories)
            ListTile(
              leading: Icon(category.icon, color: transactionPrimary),
              title: Text(category.name),
              selected: category.id == selected?.id,
              selectedColor: transactionPrimary,
              onTap: () => Navigator.pop(sheetContext, category),
            ),
        ],
      ),
    );
    if (picked != null && mounted) notifier.selectCategory(picked);
  }

  Future<void> _pickPhoto(TransactionFormNotifier notifier) async {
    _noteFocus.unfocus();
    setState(() => _pickingPhoto = true);
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (mounted && photo != null) notifier.setPhoto(photo);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở thư viện ảnh.')),
      );
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }
}

class _FormFieldTile extends StatelessWidget {
  const _FormFieldTile({
    this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.dropdown = false,
    this.trailing,
    this.expanded = false,
    this.valueWeight,
  });

  final String? label;
  final String value;
  final FontWeight? valueWeight;
  final IconData icon;
  final VoidCallback onTap;
  final bool dropdown;
  final Widget? trailing;
  final bool expanded;

  @override
  Widget build(BuildContext context) => Material(
    color: transactionMint,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: transactionBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: transactionPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null)
                    Text(
                      label!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: transactionMuted,
                      ),
                    ),
                  Text(
                    value,
                    style: TextStyle(
                      color: transactionInk,
                      fontSize: 14,
                      fontWeight:
                          valueWeight ??
                          (label == null ? FontWeight.w500 : FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
            if (dropdown)
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: transactionPrimary,
              ),
          ],
        ),
      ),
    ),
  );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final TransactionCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 49,
              decoration: BoxDecoration(
                color: transactionMint,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: selected ? transactionPrimary : transactionBorder,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(category.icon, size: 21, color: transactionPrimary),
                  if (selected)
                    const Positioned(
                      top: 2,
                      right: 2,
                      child: Icon(
                        Icons.check_circle,
                        size: 13,
                        color: transactionPrimary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: transactionInk,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .65,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: transactionInk,
              ),
            ),
          ),
          ...children,
        ],
      ),
    ),
  );
}
