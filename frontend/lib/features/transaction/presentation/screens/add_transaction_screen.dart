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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionFormProvider);
    final notifier = ref.read(transactionFormProvider.notifier);
    final categories = ref.watch(currentCategoriesProvider);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu giao dịch thành công!'),
          backgroundColor: transactionPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: AbsorbPointer(
                absorbing: busy,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  children: [
                    _buildTabs(state, notifier),
                    const SizedBox(height: 12),
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
            if (!editingNote)
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
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
            onPressed: () => context.go(AppConstants.notificationsRoute),
            tooltip: 'Thông báo',
            color: transactionPrimary,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            onPressed: () => context.go(AppConstants.settingsRoute),
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

  Widget _buildAmount(int amount) {
    return Semantics(
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
    TransactionFormNotifier notifier,
  ) {
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
              onTap: () => _pickDate(state.selectedDate, notifier),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FormFieldTile(
              label: walletLabel,
              value: state.wallet?.name ?? 'Chọn ví',
              icon: Icons.account_balance_wallet_outlined,
              dropdown: true,
              onTap: () => _showWalletPicker(destination: false),
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
    List<TransactionCategory> categories,
  ) {
    const heading = Text(
      'Danh mục phổ biến',
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
              const Expanded(child: heading),
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
          ? notifier.saveTransaction
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
    TransactionFormNotifier notifier,
  ) async {
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
  }

  Future<void> _showWalletPicker({required bool destination}) async {
    if (_openingWalletPicker) return;
    _noteFocus.unfocus();
    _openingWalletPicker = true;
    try {
      final walletNotifier = ref.read(transactionProvider.notifier);
      if (ref.read(transactionProvider).wallets.isEmpty) {
        await walletNotifier.loadWallets();
      }
      if (!mounted) return;

      final state = ref.read(transactionFormProvider);
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
            .read(transactionFormProvider.notifier)
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
    this.expanded = false,
    this.valueWeight,
  });

  final String? label;
  final String value;
  final FontWeight? valueWeight;
  final IconData icon;
  final VoidCallback onTap;
  final bool dropdown;
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
