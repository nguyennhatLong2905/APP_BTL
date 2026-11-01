import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/transaction_provider.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/transaction_category.dart';

// ─── Màu chủ đạo ───────────────────────────────────────────────────────────
const _kBackground = Color(0xFFE0F5F0);
const _kPrimary = Color(0xFF1A6B5A);
const _kPrimaryLight = Color(0xFFD1EDE7);
const _kCardBg = Color(0xFFF0FAF8);
const _kNumpadKey = Color(0xFFD9F0EC);
const _kNumpadSpecial = Color(0xFFC5E8E2);
const _kTextDark = Color(0xFF1A1A1A);
const _kTextGrey = Color(0xFF6B7280);
const _kBorderColor = Color(0xFFBBDED6);

/// Màn hình Thêm Giao Dịch — theo thiết kế Figma
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  bool _noteExpanded = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ── Format số tiền ──────────────────────────────────────────────────────
  String _formatAmount(double? amount) {
    if (amount == null || amount == 0) return '0';
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(amount.toInt()).replaceAll(',', '.');
  }

  // ── Xử lý numpad ────────────────────────────────────────────────────────
  void _onNumpadPressed(String key, TransactionFormNotifier notifier,
      TransactionFormState state) {
    final current =
        (state.amount == null || state.amount == 0) ? '' : state.amount!.toInt().toString();

    if (key == '⌫') {
      if (current.isEmpty) return;
      final next = current.length == 1 ? '' : current.substring(0, current.length - 1);
      notifier.setAmount(next.isEmpty ? null : double.parse(next));
    } else if (key == '000') {
      if (current.isEmpty) return;
      final next = current + '000';
      notifier.setAmount(double.parse(next));
    } else {
      final next = current + key;
      notifier.setAmount(double.parse(next));
    }
  }

  // ── Chọn ngày ────────────────────────────────────────────────────────────
  Future<void> _pickDate(BuildContext context, TransactionFormNotifier notifier,
      DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kPrimary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) notifier.setDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionFormProvider);
    final notifier = ref.read(transactionFormProvider.notifier);

    // Success snackbar
    ref.listen<TransactionFormState>(transactionFormProvider, (prev, next) {
      if (next.isSuccess && !(prev?.isSuccess ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Đã lưu giao dịch thành công!'),
              ],
            ),
            backgroundColor: _kPrimary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        notifier.reset();
      }
    });

    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ────────────────────────────────────────────────────
            _buildAppBar(context),

            // ── Scrollable content ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card "Ghi nhận giao dịch"
                    _buildMainCard(state, notifier, context),
                    const SizedBox(height: 12),

                    // Numpad
                    _buildNumpad(state, notifier),
                    const SizedBox(height: 16),

                    // Nút Lưu giao dịch
                    _buildSaveButton(state, notifier),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // AppBar
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Nút back
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: _kTextDark, size: 24),
            ),
          ),
          const SizedBox(width: 8),

          // Title
          const Expanded(
            child: Text(
              'Thêm Giao Dịch',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
          ),

          // Bell icon
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.notifications_none_rounded,
                color: _kTextDark, size: 26),
          ),
          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: _kPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Main Card
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMainCard(TransactionFormState state,
      TransactionFormNotifier notifier, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorderColor, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ghi nhận giao dịch',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => notifier.reset(),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: _kPrimaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: _kPrimary, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Tab Selector ─────────────────────────────────────────────────
          _buildTabSelector(state, notifier),
          const SizedBox(height: 14),

          // ── Amount Box ───────────────────────────────────────────────────
          _buildAmountBox(state),
          const SizedBox(height: 12),

          // ── Quick Amount Chips ────────────────────────────────────────────
          _buildQuickAmountChips(state, notifier),
          const SizedBox(height: 12),

          // ── Date & Source Row ─────────────────────────────────────────────
          _buildDateSourceRow(state, notifier, context),
          const SizedBox(height: 14),

          // ── Category ─────────────────────────────────────────────────────
          _buildCategorySection(state, notifier),
          const SizedBox(height: 12),

          // ── Note & Photo ──────────────────────────────────────────────────
          _buildNotePhotoSection(state, notifier),

          // ── Error ────────────────────────────────────────────────────────
          if (state.error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab Selector ─────────────────────────────────────────────────────────
  Widget _buildTabSelector(
      TransactionFormState state, TransactionFormNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: _kPrimaryLight,
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTab('↓ Chi tiêu', TransactionType.expense, state, notifier),
          _buildTab('↑ Thu nhập', TransactionType.income, state, notifier),
          _buildTab('⇄ Chuyển ví', null, state, notifier),
        ],
      ),
    );
  }

  Widget _buildTab(String label, TransactionType? type,
      TransactionFormState state, TransactionFormNotifier notifier) {
    final bool isActive =
        type != null && state.type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (type != null) notifier.setType(type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? _kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : _kTextGrey,
            ),
          ),
        ),
      ),
    );
  }

  // ── Amount Box ───────────────────────────────────────────────────────────
  Widget _buildAmountBox(TransactionFormState state) {
    final amountStr = _formatAmount(state.amount);
    final influence = state.amount != null && state.amount! > 0
        ? '~${_formatAmount(state.amount! / 14)} đ/ngày trong 14 ngày tới'
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kPrimaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderColor, width: 1),
      ),
      child: Column(
        children: [
          // Label
          const Text(
            'SỐ TIỀN GIAO DỊCH',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: _kTextGrey,
            ),
          ),
          const SizedBox(height: 6),

          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                amountStr,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: _kTextDark,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'đ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),

          // Influence hint
          if (influence != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.eco_outlined, color: _kPrimary, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Ảnh hưởng: $influence',
                    style: const TextStyle(fontSize: 12, color: _kTextGrey),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Quick Amount Chips ────────────────────────────────────────────────────
  Widget _buildQuickAmountChips(
      TransactionFormState state, TransactionFormNotifier notifier) {
    const chips = [10000.0, 50000.0, 100000.0];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((amount) {
          final label = '+${_formatAmount(amount)} đ';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                final current = state.amount ?? 0;
                notifier.setAmount(current + amount);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: _kBorderColor, width: 1),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kTextDark,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Date & Source Row ─────────────────────────────────────────────────────
  Widget _buildDateSourceRow(TransactionFormState state,
      TransactionFormNotifier notifier, BuildContext context) {
    final dateStr =
        DateFormat('HH:mm, dd/MM', 'vi_VN').format(state.selectedDate);
    return Row(
      children: [
        // Date
        Expanded(
          child: GestureDetector(
            onTap: () => _pickDate(context, notifier, state.selectedDate),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _kPrimaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorderColor, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: _kPrimary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày ghi nhận',
                          style: TextStyle(fontSize: 10, color: _kTextGrey),
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Nguồn tiền
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _kPrimaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorderColor, width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded,
                    color: _kPrimary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nguồn tiền',
                        style: TextStyle(fontSize: 10, color: _kTextGrey),
                      ),
                      Text(
                        'Ví tiền mặt',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kTextDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: _kTextGrey, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Category Section ──────────────────────────────────────────────────────
  Widget _buildCategorySection(
      TransactionFormState state, TransactionFormNotifier notifier) {
    final categories = state.type == TransactionType.expense
        ? DefaultCategories.expenseCategories
        : DefaultCategories.incomeCategories;

    // Chỉ hiện 5 categories đầu (theo Figma)
    final displayCategories = categories.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Danh mục phổ biến',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kTextDark,
              ),
            ),
            const Text(
              'Chạm 1 lần để chọn',
              style: TextStyle(fontSize: 12, color: _kPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Category items
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: displayCategories.map((cat) {
            final isSelected = state.selectedCategory?.id == cat.id;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  notifier.selectCategory(cat);
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected ? _kPrimary : _kPrimaryLight,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? null
                            : Border.all(color: _kBorderColor, width: 1),
                      ),
                      child: Icon(
                        cat.icon,
                        color: isSelected ? Colors.white : _kPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected ? _kPrimary : _kTextGrey,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Note & Photo Section ──────────────────────────────────────────────────
  Widget _buildNotePhotoSection(
      TransactionFormState state, TransactionFormNotifier notifier) {
    return Column(
      children: [
        // Header toggle
        GestureDetector(
          onTap: () => setState(() => _noteExpanded = !_noteExpanded),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _kPrimaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorderColor, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.note_add_outlined,
                    color: _kPrimary, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ghi chú & Ảnh hóa đơn',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kTextDark,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _noteExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: _kTextGrey),
                ),
              ],
            ),
          ),
        ),

        // Expanded content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kPrimaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Note field
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  onChanged: notifier.setNote,
                  style: const TextStyle(fontSize: 14, color: _kTextDark),
                  decoration: InputDecoration(
                    hintText: 'Nhập ghi chú...',
                    hintStyle:
                        const TextStyle(color: _kTextGrey, fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: _kPrimary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                // Photo button
                GestureDetector(
                  onTap: () {
                    // TODO: image picker
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kBorderColor, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_outlined,
                            color: _kPrimary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Thêm ảnh hóa đơn',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Preview photo if selected
                if (state.photoPath != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.image_rounded,
                          color: _kPrimary, size: 16),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Đã chọn ảnh',
                          style: TextStyle(fontSize: 12, color: _kPrimary),
                        ),
                      ),
                      GestureDetector(
                        onTap: notifier.removePhoto,
                        child: const Icon(Icons.close_rounded,
                            color: Colors.red, size: 16),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          crossFadeState: _noteExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Numpad
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildNumpad(
      TransactionFormState state, TransactionFormNotifier notifier) {
    const keys = [
      ['1', '2', '3', '000'],
      ['4', '5', '6', '0'],
      ['7', '8', '9', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: row.map((key) {
              final isSpecial = key == '000' || key == '⌫';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _NumpadKey(
                    label: key,
                    isSpecial: isSpecial,
                    onTap: () => _onNumpadPressed(key, notifier, state),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Save Button
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildSaveButton(
      TransactionFormState state, TransactionFormNotifier notifier) {
    return GestureDetector(
      onTap: state.isLoading ? null : () => notifier.saveTransaction(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: state.isValid ? _kPrimary : _kPrimary.withAlpha(153),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: state.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Lưu giao dịch',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Numpad Key Widget
// ════════════════════════════════════════════════════════════════════════════
class _NumpadKey extends StatefulWidget {
  final String label;
  final bool isSpecial;
  final VoidCallback onTap;

  const _NumpadKey({
    required this.label,
    required this.isSpecial,
    required this.onTap,
  });

  @override
  State<_NumpadKey> createState() => _NumpadKeyState();
}

class _NumpadKeyState extends State<_NumpadKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 60,
        decoration: BoxDecoration(
          color: _pressed
              ? _kPrimary.withAlpha(51)
              : (widget.isSpecial ? _kNumpadSpecial : _kNumpadKey),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: widget.label == '⌫'
              ? const Icon(Icons.backspace_outlined, color: _kPrimary, size: 22)
              : Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: widget.label == '000' ? 16 : 22,
                    fontWeight: FontWeight.w600,
                    color: widget.isSpecial ? _kPrimary : _kTextDark,
                  ),
                ),
        ),
      ),
    );
  }
}
