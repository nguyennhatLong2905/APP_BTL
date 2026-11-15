import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/currency_text_field.dart';
import '../../../transaction/data/datasources/transaction_remote_data_source.dart';
import '../../domain/models/category_budget.dart';
import '../providers/budget_provider.dart';

/// Tab hiển thị và quản lý Hóa đơn định kỳ (Luồng 8)
class BillsTabView extends ConsumerStatefulWidget {
  const BillsTabView({super.key});

  @override
  ConsumerState<BillsTabView> createState() => _BillsTabViewState();
}

class _BillsTabViewState extends ConsumerState<BillsTabView> {
  static const Color _teal = Color(0xFF2C7873);
  static const Color _tealBg = Color(0xFFEBF6F3);
  static const Color _warningBg = Color(0xFFFFF3E0);
  static const Color _danger = Color(0xFFD32F2F);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF757575);

  final _money = NumberFormat('#,###', 'vi_VN');
  bool _showPaidOnly = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetProvider);
    final allBills = state.upcomingBills;

    final unpaidBills = allBills.where((b) {
      final s = b['status'] as String? ?? 'unpaid';
      return s == 'unpaid';
    }).toList();

    final paidBills = allBills.where((b) {
      final s = b['status'] as String? ?? 'unpaid';
      return s == 'paid';
    }).toList();

    final displayedBills = _showPaidOnly ? paidBills : unpaidBills;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thanh giải thích nghiệp vụ
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F7F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD5E8E4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: _teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hóa đơn chưa trả trước ngày lương (${state.unpaidBills > 0 ? _money.format(state.unpaidBills) : "0"} ₫) được giữ ở Lớp 2 để bảo vệ số tiền chi tiêu. Khi bạn thanh toán hoặc liên kết giao dịch, tiền sẽ tự động giải phóng sang Còn để chi.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Tabs phân loại Chưa trả / Đã trả
        Row(
          children: [
            _buildFilterChip(
              label: 'Chưa trả (${unpaidBills.length})',
              isSelected: !_showPaidOnly,
              onTap: () => setState(() => _showPaidOnly = false),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Đã thanh toán (${paidBills.length})',
              isSelected: _showPaidOnly,
              onTap: () => setState(() => _showPaidOnly = true),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Danh sách hóa đơn
        if (displayedBills.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    _showPaidOnly
                        ? Icons.check_circle_outline
                        : Icons.receipt_long_outlined,
                    size: 44,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _showPaidOnly
                        ? 'Chưa có hóa đơn nào đã thanh toán'
                        : 'Không có hóa đơn chưa trả nào',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          for (final b in displayedBills) _buildBillCard(b, state),

        const SizedBox(height: 16),

        // Nút thêm hóa đơn định kỳ
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _showAddBillTemplateDialog(context),
            icon: const Icon(Icons.add_circle_outline, size: 20, color: _teal),
            label: const Text(
              'Thêm lịch hóa đơn định kỳ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _teal,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _teal, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _teal : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : _textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBillCard(Map<String, dynamic> b, BudgetState state) {
    final name = b['name'] as String? ??
        b['nameTemplate'] as String? ??
        'Hóa đơn';
    final amountNum = num.tryParse('${b['amount'] ?? 0}') ?? 0;
    final isPaid = (b['status'] as String? ?? '') == 'paid';
    final isOverdue = b['overdue'] == true && !isPaid;

    DateTime? dueAt;
    if (b['dueAt'] != null) {
      dueAt = DateTime.tryParse(b['dueAt'].toString());
    }
    DateTime? paidAt;
    if (b['paidAt'] != null) {
      paidAt = DateTime.tryParse(b['paidAt'].toString());
    }
    final periodStr = dueAt != null ? 'Kỳ ${DateFormat('MM/yyyy').format(dueAt)}' : '';

    final catId = b['categoryId'] as String? ?? '';
    final category = state.categories.firstWhere(
      (c) => c.id == catId,
      orElse: () => CategoryBudget(
        id: '',
        name: 'Chi tiêu',
        icon: Icons.receipt_long,
        iconBgColor: _tealBg,
        allocatedAmount: 0,
        spentAmount: 0,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue ? _danger.withValues(alpha: 0.3) : const Color(0xFFE8F5F2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon tròn
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isPaid
                        ? const Color(0xFFE8F5E9)
                        : (isOverdue ? _warningBg : _tealBg),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPaid
                        ? Icons.check_circle_outline
                        : (isOverdue
                            ? Icons.warning_amber_rounded
                            : Icons.receipt_outlined),
                    color: isPaid
                        ? const Color(0xFF2E7D32)
                        : (isOverdue ? _danger : _teal),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Tên hóa đơn + Ngày đến hạn + Badge kỳ tháng
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (periodStr.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? const Color(0xFFE8F5E9)
                                    : _teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                periodStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isPaid
                                      ? const Color(0xFF2E7D32)
                                      : _teal,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            isPaid
                                ? Icons.event_available_outlined
                                : Icons.calendar_today_outlined,
                            size: 12,
                            color: isOverdue ? _danger : _textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dueAt != null
                                ? 'Hạn: ${DateFormat('dd/MM/yyyy').format(dueAt)}'
                                : 'Chưa định hạn',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isOverdue
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isOverdue ? _danger : _textSecondary,
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: _danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Quá hạn',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _danger,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Số tiền
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_money.format(amountNum)} ₫',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isPaid ? _textSecondary : _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Banner trạng thái dành cho hóa đơn đã thanh toán
          if (isPaid) ...[
            const Divider(height: 1, thickness: 0.8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              color: const Color(0xFFF9FDF9),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 6),
                  Text(
                    paidAt != null
                        ? 'Đã thanh toán ngày ${DateFormat('dd/MM/yyyy').format(paidAt.toLocal())}'
                        : 'Đã hoàn tất thanh toán',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action row dành cho hóa đơn chưa trả
          if (!isPaid) ...[
            const Divider(height: 1, thickness: 0.8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  // Nút Thanh toán ngay
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _showPayBillSheet(context, b),
                      icon: const Icon(Icons.payment_outlined,
                          size: 15, color: _teal),
                      label: const Text(
                        'Thanh toán',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _teal,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        backgroundColor: _tealBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Nút Gắn giao dịch có sẵn
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showLinkTransactionSheet(context, b),
                      icon: const Icon(Icons.link, size: 15, color: _teal),
                      label: const Text(
                        'Gắn giao dịch',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _teal,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        side: const BorderSide(color: _teal, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Nút Hủy kỳ
                  IconButton(
                    onPressed: () => _confirmCancelBill(context, b),
                    icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                    tooltip: 'Hủy kỳ hóa đơn này',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Dialog / BottomSheet: Thanh toán hóa đơn (POST /bills/:id/pay) ───
  Future<void> _showPayBillSheet(
    BuildContext context,
    Map<String, dynamic> bill,
  ) async {
    final state = ref.read(budgetProvider);
    final wallets = state.walletOptions;
    final billId = bill['_id'] as String? ?? '';
    final defaultAmount = num.tryParse('${bill['amount'] ?? 0}') ?? 0;
    final billName = bill['name'] as String? ?? bill['nameTemplate'] as String? ?? 'Hóa đơn';

    DateTime? dueAt;
    if (bill['dueAt'] != null) {
      dueAt = DateTime.tryParse(bill['dueAt'].toString());
    }
    final periodStr = dueAt != null ? 'Kỳ ${DateFormat('MM/yyyy').format(dueAt)}' : '';

    String selectedWalletId = bill['preferredWalletId'] as String? ??
        (wallets.isNotEmpty ? wallets.first.id : '');
    final amountCtrl = TextEditingController(text: defaultAmount.toInt().toString());
    DateTime selectedDate = DateTime.now();
    bool isSubmitting = false;

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
              Row(
                children: [
                  const Icon(Icons.payment_outlined, color: _teal, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thanh toán: $billName ${periodStr.isNotEmpty ? "($periodStr)" : ""}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Thanh toán sẽ tạo 1 giao dịch chi tiêu, tự động giải phóng tiền bảo vệ ở Lớp 2 và chuyển hóa đơn sang mục "Đã thanh toán".',
                style: const TextStyle(fontSize: 12, color: _textSecondary),
              ),
              if (dueAt != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: _teal),
                      const SizedBox(width: 6),
                      Text(
                        'Hạn thanh toán gốc: ${DateFormat('dd/MM/yyyy').format(dueAt)}',
                        style: const TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Chọn ví thanh toán
              const Text(
                'Ví thanh toán',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedWalletId.isNotEmpty ? selectedWalletId : null,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                hint: const Text('Chọn ví chi trả'),
                items: wallets
                  .map((w) => DropdownMenuItem(
                        value: w.id,
                        child: Text(
                          '${w.name} (Số dư: ${_money.format(w.balance)} ₫)',
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ))
                  .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selectedWalletId = val);
                  }
                },
              ),
              const SizedBox(height: 14),

              // Số tiền thanh toán
              CurrencyTextField(
                controller: amountCtrl,
                labelText: 'Số tiền thanh toán',
              ),
              const SizedBox(height: 14),

              // Ngày thanh toán
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thời gian: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                    style: const TextStyle(fontSize: 13, color: _textSecondary),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.edit_calendar, size: 16, color: _teal),
                    label: const Text('Đổi ngày', style: TextStyle(color: _teal)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nút xác nhận
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (selectedWalletId.isEmpty) {
                            AppSnackBar.showError(
                                context, 'Vui lòng chọn ví thanh toán.');
                            return;
                          }
                          final rawAmount =
                              amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                          if (rawAmount.isEmpty || rawAmount == '0') {
                            AppSnackBar.showError(
                                context, 'Vui lòng nhập số tiền hợp lệ.');
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          final err = await ref
                              .read(budgetProvider.notifier)
                              .payBill(
                                billId: billId,
                                walletId: selectedWalletId,
                                occurredAt: selectedDate,
                                amount: rawAmount,
                              );

                          if (context.mounted) {
                            if (err != null) {
                              setModalState(() => isSubmitting = false);
                              AppSnackBar.showError(context, err);
                            } else {
                              Navigator.of(ctx).pop();
                              setState(() {
                                _showPaidOnly = true;
                              });
                              AppSnackBar.showSuccess(
                                context,
                                'Đã thanh toán thành công $billName ($periodStr)! Hóa đơn đã được chuyển sang mục "Đã thanh toán".',
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Xác nhận thanh toán',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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

  // ── Dialog / BottomSheet: Gắn giao dịch có sẵn (POST /bills/:id/link-transaction)
  Future<void> _showLinkTransactionSheet(
    BuildContext context,
    Map<String, dynamic> bill,
  ) async {
    final billId = bill['_id'] as String? ?? '';
    final billCatId = bill['categoryId'] as String? ?? '';
    final billAmount = num.tryParse('${bill['amount'] ?? 0}') ?? 0;
    final billName = bill['name'] as String? ?? 'Hóa đơn';
    DateTime? dueAt;
    if (bill['dueAt'] != null) {
      dueAt = DateTime.tryParse(bill['dueAt'].toString());
    }
    final periodStr = dueAt != null ? 'Kỳ ${DateFormat('MM/yyyy').format(dueAt)}' : '';

    final linked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LinkTransactionModal(
        billId: billId,
        billCategoryId: billCatId,
        billAmount: billAmount,
      ),
    );

    if (linked == true && mounted) {
      setState(() {
        _showPaidOnly = true;
      });
      AppSnackBar.showSuccess(
        context,
        'Đã gắn giao dịch cho $billName ($periodStr)! Hóa đơn đã được chuyển sang mục "Đã thanh toán".',
      );
    }
  }

  // ── Hủy kỳ hóa đơn (PATCH /bills/:id với status: 'cancelled') ────────
  Future<void> _confirmCancelBill(
    BuildContext context,
    Map<String, dynamic> bill,
  ) async {
    final billId = bill['_id'] as String? ?? '';
    final name = bill['name'] ?? bill['nameTemplate'] ?? 'Hóa đơn này';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy kỳ hóa đơn?'),
        content: Text(
          'Bạn có chắc muốn hủy kỳ "$name"? Kỳ này sẽ không còn trừ vào tiền dự trù Lớp 2.',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Bỏ qua'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: _danger),
            child: const Text('Hủy kỳ này', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final err = await ref.read(budgetProvider.notifier).cancelBill(
            billId: billId,
            expectedVersion: bill['version'] as int?,
          );
      if (context.mounted) {
        if (err != null) {
          AppSnackBar.showError(context, err);
        } else {
          AppSnackBar.showSuccess(context, 'Đã hủy kỳ hóa đơn thành công.');
        }
      }
    }
  }

  // ── Dialog Thêm lịch hóa đơn định kỳ (POST /bill-templates) ─────────
  Future<void> _showAddBillTemplateDialog(BuildContext context) async {
    final state = ref.read(budgetProvider);
    final categories = state.categories;
    final wallets = state.walletOptions;

    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String? selectedCategoryId =
        categories.isNotEmpty ? categories.first.id : null;
    String? selectedWalletId =
        wallets.isNotEmpty ? wallets.first.id : null;
    String frequency = 'monthly'; // 'monthly' | 'yearly' | 'once'
    DateTime firstDueAt = DateTime.now().add(const Duration(days: 7));
    int reminderDays = 3;
    bool isSubmitting = false;

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
                    Icon(Icons.receipt_long, color: _teal, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Thêm lịch hóa đơn định kỳ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hệ thống sẽ tự động tạo các kỳ hóa đơn sắp tới và dự trù vào Lớp 2 trước mỗi ngày lương.',
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
                const SizedBox(height: 16),

                // Tên hóa đơn
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tên hóa đơn *',
                    hintText: 'VD: Tiền điện, Internet FPT, Tiền nhà...',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Số tiền ước tính
                CurrencyTextField(
                  controller: amountCtrl,
                  labelText: 'Số tiền ước tính mỗi kỳ *',
                ),
                const SizedBox(height: 14),

                // Danh mục
                const Text(
                  'Danh mục chi tiêu *',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  hint: const Text('Chọn danh mục'),
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name,
                                style: const TextStyle(fontSize: 13.5)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedCategoryId = val);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // Chu kỳ lặp
                const Text(
                  'Chu kỳ lặp',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'monthly', child: Text('Hàng tháng')),
                    DropdownMenuItem(
                        value: 'yearly', child: Text('Hàng năm')),
                    DropdownMenuItem(
                        value: 'once', child: Text('Một lần duy nhất')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => frequency = val);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // Ngày đến hạn đầu tiên
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày đến hạn đầu tiên',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(firstDueAt),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _teal,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: firstDueAt,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() => firstDueAt = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today,
                          size: 16, color: _teal),
                      label: const Text('Chọn ngày',
                          style: TextStyle(color: _teal)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Ví dự kiến chi trả (tuỳ chọn)
                const Text(
                  'Ví dự kiến chi trả (không bắt buộc)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedWalletId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  hint: const Text('Chọn ví dự kiến'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Không chọn trước',
                          style: TextStyle(fontSize: 13.5)),
                    ),
                    ...wallets.map((w) => DropdownMenuItem(
                          value: w.id,
                          child: Text(w.name,
                              style: const TextStyle(fontSize: 13.5)),
                        )),
                  ],
                  onChanged: (val) {
                    setModalState(() => selectedWalletId = val);
                  },
                ),
                const SizedBox(height: 20),

                // Nút tạo lịch
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) {
                              AppSnackBar.showError(
                                  context, 'Vui lòng nhập tên hóa đơn.');
                              return;
                            }
                            final rawAmount = amountCtrl.text
                                .replaceAll(RegExp(r'[^0-9]'), '');
                            if (rawAmount.isEmpty || rawAmount == '0') {
                              AppSnackBar.showError(
                                  context, 'Vui lòng nhập số tiền ước tính.');
                              return;
                            }
                            if (selectedCategoryId == null ||
                                selectedCategoryId!.isEmpty) {
                              AppSnackBar.showError(
                                  context, 'Vui lòng chọn danh mục chi tiêu.');
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            final err = await ref
                                .read(budgetProvider.notifier)
                                .createBillTemplate(
                                  name: name,
                                  estimatedAmount: rawAmount,
                                  categoryId: selectedCategoryId!,
                                  frequency: frequency,
                                  startAt: firstDueAt,
                                  preferredWalletId: selectedWalletId,
                                  reminderDaysBefore: reminderDays,
                                );

                            if (context.mounted) {
                              Navigator.of(ctx).pop();
                              if (err != null) {
                                AppSnackBar.showError(context, err);
                              } else {
                                AppSnackBar.showSuccess(
                                  context,
                                  'Đã tạo lịch hóa đơn định kỳ thành công! Các kỳ tương lai đã được sinh.',
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Tạo lịch hóa đơn',
                            style: TextStyle(
                              fontSize: 15,
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
  }
}

// ── Modal Chọn giao dịch để liên kết (POST /bills/:id/link-transaction)
class _LinkTransactionModal extends ConsumerStatefulWidget {
  final String billId;
  final String billCategoryId;
  final num billAmount;

  const _LinkTransactionModal({
    required this.billId,
    required this.billCategoryId,
    required this.billAmount,
  });

  @override
  ConsumerState<_LinkTransactionModal> createState() =>
      _LinkTransactionModalState();
}

class _LinkTransactionModalState extends ConsumerState<_LinkTransactionModal> {
  static const Color _teal = Color(0xFF2C7873);
  final _money = NumberFormat('#,###', 'vi_VN');

  List<Map<String, dynamic>> _candidates = [];
  bool _isLoading = true;
  String? _selectedTransactionId;
  int _selectedVersion = 1;
  bool _isLinking = false;

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
  }

  Future<void> _fetchCandidates() async {
    setState(() => _isLoading = true);
    try {
      final ds = ref.read(transactionRemoteDataSourceProvider);
      // Ưu tiên tải giao dịch đúng categoryId của bill
      final res = await ds.getTransactions(
        limit: 50,
        categoryId: widget.billCategoryId.isNotEmpty ? widget.billCategoryId : null,
      );

      final items = (res['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      // Lọc giao dịch expense, đã ghi nhận, chưa gắn hóa đơn
      final filtered = items.where((t) {
        final type = t['type'] as String? ?? '';
        final status = t['status'] as String? ?? '';
        final billOccId = t['billOccurrenceId'];
        return type == 'expense' &&
            status == 'posted' &&
            (billOccId == null || billOccId.toString().isEmpty);
      }).toList();

      if (mounted) {
        setState(() {
          _candidates = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              Icon(Icons.link, color: _teal, size: 22),
              SizedBox(width: 8),
              Text(
                'Gắn với giao dịch đã ghi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Nếu bạn đã tự ghi khoản chi này trước đó, hãy liên kết để hệ thống đánh dấu hóa đơn đã trả mà KHÔNG trừ tiền ví lần nữa.',
            style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
          ),
          const SizedBox(height: 14),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_candidates.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Không tìm thấy giao dịch chi tiêu phù hợp trong cùng danh mục để liên kết.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _candidates.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final t = _candidates[i];
                  final tid = t['_id'] as String? ?? '';
                  final version = (t['version'] as num?)?.toInt() ?? 1;
                  final amount = num.tryParse('${t['amount'] ?? 0}') ?? 0;
                  final note = t['note'] as String? ?? t['memo'] as String? ?? 'Khoản chi';
                  final isSelected = _selectedTransactionId == tid;

                  DateTime? occ;
                  if (t['occurredAt'] != null) {
                    occ = DateTime.tryParse(t['occurredAt'].toString());
                  }

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: Radio<String>(
                      value: tid,
                      groupValue: _selectedTransactionId,
                      activeColor: _teal,
                      onChanged: (val) {
                        setState(() {
                          _selectedTransactionId = val;
                          _selectedVersion = version;
                        });
                      },
                    ),
                    title: Text(
                      note,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      occ != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(occ)
                          : '',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    trailing: Text(
                      '-${_money.format(amount)} ₫',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedTransactionId = tid;
                        _selectedVersion = version;
                      });
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_selectedTransactionId == null || _isLinking)
                  ? null
                  : () async {
                      setState(() => _isLinking = true);
                      final err = await ref
                          .read(budgetProvider.notifier)
                          .linkBillTransaction(
                            billId: widget.billId,
                            transactionId: _selectedTransactionId!,
                            expectedVersion: _selectedVersion,
                          );

                      if (context.mounted) {
                        if (err != null) {
                          setState(() => _isLinking = false);
                          AppSnackBar.showError(context, err);
                        } else {
                          Navigator.of(context).pop(true);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLinking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Xác nhận liên kết',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

