import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/currency_text_field.dart';
import '../../domain/models/recurring_bill.dart';
import '../providers/budget_provider.dart';

const _teal = Color(0xFF0F5B47);
const _tealSoft = Color(0xFFE2F6F0);
const _textPrimary = Color(0xFF1A1A1A);
const _textSecondary = Color(0xFF6B7280);
final _money = NumberFormat('#,###', 'vi_VN');

String _fmt(num v) => '${_money.format(v.round())} ₫';
String _fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

const _filters = ['Tất cả', 'Chưa trả', 'Đến hạn', 'Quá hạn', 'Đã trả'];

/// Tab "Hóa đơn" trong màn Kế hoạch — Hóa đơn định kỳ.
///
/// Dữ liệu lấy từ /screens/bills (backend đã tính trạng thái theo ngày hiện
/// tại và tổng quan 3 lớp). Thanh toán dùng /bills/:id/settle để đảm bảo
/// idempotency + không trừ 2 lần vào "Còn để chi".
class BillsTabView extends ConsumerWidget {
  const BillsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetProvider);
    final notifier = ref.read(budgetProvider.notifier);
    final bills = notifier.filteredBills;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BillsOverviewCard(
          summary: state.billsSummary,
          available: state.spendableNow,
          protectedMoney: state.protectedMoney,
          walletTotal: state.walletTotal,
        ),
        const SizedBox(height: 14),
        _FilterRow(active: state.billFilter, onChanged: notifier.setBillFilter),
        const SizedBox(height: 12),
        if (state.isLoading && state.bills.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator(color: _teal)),
          )
        else if (bills.isEmpty)
          _EmptyBills(filter: state.billFilter)
        else
          for (final group in _groupBills(bills))
            _BillGroupCard(
              bills: group,
              onDetail: (bill) => _showBillDetail(context, ref, bill),
              onPay: (bill) => _startPayment(context, ref, bill),
              onEdit: (bill) =>
                  _showCreateOrEditBill(context, ref, existing: bill),
            ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showCreateOrEditBill(context, ref),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text(
              'Thêm hóa đơn',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: _tealSoft,
              foregroundColor: _teal,
              side: const BorderSide(color: Color(0xFF80D8C3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<List<RecurringBill>> _groupBills(List<RecurringBill> bills) {
    final groups = <String, List<RecurringBill>>{};
    for (final bill in bills) {
      final key = bill.templateId != null && bill.templateId!.isNotEmpty
          ? 'template:${bill.templateId}'
          : bill.frequency != 'once'
              ? 'recurring:${bill.name.trim().toLowerCase()}|${bill.amount}|${bill.frequency}'
              : 'single:${bill.id}';
      groups.putIfAbsent(key, () => <RecurringBill>[]).add(bill);
    }
    for (final group in groups.values) {
      group.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    }
    return groups.values.toList();
  }

  // ── Chi tiết hóa đơn ───────────────────────────────────────────────
  Future<void> _showBillDetail(
    BuildContext context,
    WidgetRef ref,
    RecurringBill bill,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _BillDetailDialog(bill: bill),
    );
  }

  // ── Tạo / sửa ──────────────────────────────────────────────────────
  Future<void> _showCreateOrEditBill(
    BuildContext context,
    WidgetRef ref, {
    RecurringBill? existing,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _BillFormDialog(existing: existing),
    );
  }

  // ── Thanh toán ─────────────────────────────────────────────────────
  Future<void> _startPayment(
    BuildContext context,
    WidgetRef ref,
    RecurringBill bill,
  ) async {
    if (bill.status == BillStatus.paid) {
      AppSnackBar.showWarning(context, 'Hóa đơn này đã được thanh toán.');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _PayBillDialog(bill: bill),
    );
  }
}

class _BillGroupCard extends StatefulWidget {
  final List<RecurringBill> bills;
  final ValueChanged<RecurringBill> onDetail;
  final ValueChanged<RecurringBill> onPay;
  final ValueChanged<RecurringBill> onEdit;

  const _BillGroupCard({
    required this.bills,
    required this.onDetail,
    required this.onPay,
    required this.onEdit,
  });

  @override
  State<_BillGroupCard> createState() => _BillGroupCardState();
}

class _BillGroupCardState extends State<_BillGroupCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final bill = widget.bills.first;
    final isGroup = widget.bills.length > 1 || bill.templateId != null;
    final unpaid = widget.bills.where((b) => b.status.isUnpaid).length;
    return Column(
      children: [
        Stack(
          children: [
            _BillCard(
              bill: bill,
              onTap: isGroup
                  ? () => setState(() => expanded = !expanded)
                  : () => widget.onDetail(bill),
              onPay: () => widget.onPay(bill),
              onEdit: () => widget.onEdit(bill),
            ),
            if (isGroup)
              Positioned(
                right: 18,
                top: 12,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _tealSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      child: Text(
                        '${widget.bills.length} kỳ · $unpaid chưa trả',
                        style: const TextStyle(
                          color: _teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (expanded)
          Container(
            margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5FBF9),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              border: Border.all(color: const Color(0xFFD8EEE8)),
            ),
            child: Column(
              children: [
                for (final occurrence in widget.bills.skip(1))
                  _BillCard(
                    bill: occurrence,
                    onTap: () => widget.onDetail(occurrence),
                    onPay: () => widget.onPay(occurrence),
                    onEdit: () => widget.onEdit(occurrence),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Tổng quan
// ════════════════════════════════════════════════════════════════════

class _BillsOverviewCard extends StatelessWidget {
  final BillsSummary summary;
  final double available;
  final double protectedMoney;
  final double walletTotal;

  const _BillsOverviewCard({
    required this.summary,
    required this.available,
    required this.protectedMoney,
    required this.walletTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F5F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: _tealSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long, size: 18, color: _teal),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Hóa đơn chưa thanh toán',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ),
              Text(
                _fmt(summary.unpaidTotal),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  label: 'Tổng hóa đơn',
                  value: '${summary.total}',
                  color: _textPrimary,
                ),
              ),
              Container(width: 1, height: 30, color: const Color(0xFFE8F5F1)),
              Expanded(
                child: _StatCell(
                  label: 'Sắp đến hạn',
                  value: '${summary.upcomingCount}',
                  color: const Color(0xFFB45309),
                ),
              ),
              Container(width: 1, height: 30, color: const Color(0xFFE8F5F1)),
              Expanded(
                child: _StatCell(
                  label: 'Quá hạn',
                  value: '${summary.overdueCount}',
                  color: const Color(0xFFB91C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE8F5F1)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  label: 'Tổng tiền trong ví',
                  value: _fmt(walletTotal),
                  color: _textPrimary,
                ),
              ),
              Expanded(
                child: _StatCell(
                  label: 'Quỹ bảo vệ',
                  value: _fmt(protectedMoney),
                  color: _textPrimary,
                ),
              ),
              Expanded(
                child: _StatCell(
                  label: 'Còn để chi',
                  value: _fmt(available),
                  color: _teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 13, color: _textSecondary),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Hóa đơn chưa trả đã được giữ riêng trong Lớp 2. Khi thanh '
                    'toán, số tiền lấy từ khoản giữ riêng nên "Còn để chi" '
                    'không bị trừ thêm lần nữa.',
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.35,
                      color: _textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10.5, color: _textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String active;
  final ValueChanged<String> onChanged;

  const _FilterRow({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in _filters) ...[
            InkWell(
              onTap: () => onChanged(f),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: active == f ? _teal : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active == f ? _teal : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: active == f ? FontWeight.bold : FontWeight.w500,
                    color: active == f ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _EmptyBills extends StatelessWidget {
  final String filter;

  const _EmptyBills({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: Color(0xFFBDBDBD),
          ),
          const SizedBox(height: 10),
          Text(
            filter == 'Tất cả'
                ? 'Chưa có hóa đơn nào'
                : 'Không có hóa đơn ở nhóm "$filter"',
            style: const TextStyle(fontSize: 13.5, color: _textSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Thêm hóa đơn định kỳ để Ví An giữ riêng tiền và nhắc bạn đúng hạn.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Card hóa đơn
// ════════════════════════════════════════════════════════════════════

class _BillCard extends StatelessWidget {
  final RecurringBill bill;
  final VoidCallback onTap;
  final VoidCallback onPay;
  final VoidCallback onEdit;

  const _BillCard({
    required this.bill,
    required this.onTap,
    required this.onPay,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final status = bill.status;
    final dueLabel = switch (status) {
      BillStatus.paid =>
        bill.paidAt == null ? 'Đã trả' : 'Đã trả ${_fmtDate(bill.paidAt!)}',
      BillStatus.overdue => 'Quá hạn ${-bill.daysUntilDue} ngày',
      BillStatus.due => 'Đến hạn hôm nay',
      BillStatus.cancelled => 'Đã hủy',
      BillStatus.upcoming => 'Còn ${bill.daysUntilDue} ngày',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == BillStatus.overdue
              ? const Color(0xFFFECACA)
              : const Color(0xFFE8F5F1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: status.bg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      status == BillStatus.paid
                          ? Icons.check_circle_outline
                          : status == BillStatus.overdue
                          ? Icons.error_outline
                          : Icons.receipt_long,
                      size: 18,
                      color: status.fg,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${bill.frequencyEnum.label} • Hạn ${_fmtDate(bill.dueAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmt(bill.paidAmount ?? bill.amount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _StatusBadge(status: status, label: dueLabel),
                    ],
                  ),
                ],
              ),
              if (bill.status.isUnpaid) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text(
                          'Sửa',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _teal,
                          side: const BorderSide(color: Color(0xFFB7E4D8)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onPay,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text(
                          'Đánh dấu đã trả',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BillStatus status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: status.fg,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Dialog chi tiết
// ════════════════════════════════════════════════════════════════════

class _BillDetailDialog extends ConsumerWidget {
  final RecurringBill bill;

  const _BillDetailDialog({required this.bill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(bill.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Trạng thái', bill.status.label, color: bill.status.fg),
            _row('Số tiền dự kiến', _fmt(bill.amount)),
            if (bill.paidAmount != null)
              _row('Số tiền thực trả', _fmt(bill.paidAmount!)),
            _row('Ngày đến hạn', _fmtDate(bill.dueAt)),
            _row('Chu kỳ', bill.frequencyEnum.label),
            if (bill.templateStartAt != null)
              _row('Bắt đầu', _fmtDate(bill.templateStartAt!)),
            if (bill.templateEndAt != null)
              _row('Kết thúc', _fmtDate(bill.templateEndAt!)),
            if (bill.reminderDaysBefore > 0)
              _row('Nhắc trước', '${bill.reminderDaysBefore} ngày'),
            if (bill.paidAt != null)
              _row('Ngày thanh toán', _fmtDate(bill.paidAt!)),
            _row(
              'Phương thức',
              bill.paymentMethod == 'linked_transaction'
                  ? 'Liên kết giao dịch có sẵn'
                  : bill.paymentMethod == 'new_transaction'
                  ? 'Tạo giao dịch chi mới'
                  : 'Chưa thanh toán',
            ),
            if (bill.transactionId != null)
              _row('Mã giao dịch', bill.transactionId!.substring(0, 8)),
            if (bill.note != null && bill.note!.isNotEmpty)
              _row('Ghi chú', bill.note!),
          ],
        ),
      ),
      actions: [
        if (bill.status.isUnpaid)
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmDelete(context, ref);
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Color(0xFFB91C1C)),
            ),
          ),
        if (bill.status.isUnpaid &&
            bill.frequencyEnum.isRecurring &&
            bill.templateId != null)
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmStop(context, ref);
            },
            child: const Text('Ngừng định kỳ'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa hóa đơn này?'),
        content: Text(
          'Kỳ hóa đơn "${bill.name}" (${_fmt(bill.amount)}) sẽ bị xóa. '
          'Nếu cần giữ lịch định kỳ, hãy dùng "Ngừng định kỳ".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final err = await ref.read(budgetProvider.notifier).deleteBill(bill.id);
    if (!context.mounted) return;
    if (err != null) {
      AppSnackBar.showError(context, err);
      return;
    }
    AppSnackBar.showSuccess(context, 'Đã xóa hóa đơn');
  }

  Future<void> _confirmStop(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ngừng hóa đơn định kỳ?'),
        content: const Text(
          'Các kỳ tương lai chưa thanh toán sẽ bị hủy. Lịch sử đã trả được '
          'giữ nguyên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ngừng định kỳ'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final err = await ref
        .read(budgetProvider.notifier)
        .stopBillTemplate(bill.templateId!);
    if (!context.mounted) return;
    if (err != null) {
      AppSnackBar.showError(context, err);
      return;
    }
    AppSnackBar.showSuccess(context, 'Đã ngừng hóa đơn định kỳ');
  }

  Widget _row(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: _textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color ?? _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Dialog tạo / sửa
// ════════════════════════════════════════════════════════════════════

class _BillFormDialog extends ConsumerStatefulWidget {
  final RecurringBill? existing;

  const _BillFormDialog({this.existing});

  @override
  ConsumerState<_BillFormDialog> createState() => _BillFormDialogState();
}

class _BillFormDialogState extends ConsumerState<_BillFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _dueDate;
  late BillFrequency _frequency;
  DateTime? _startAt;
  DateTime? _endAt;
  late int _reminderDays;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _nameController = TextEditingController(text: b?.name ?? '');
    final amount = b == null ? '' : b.amount.toInt().toString();
    _amountController = TextEditingController(text: amount);
    _amountController.selection = TextSelection.collapsed(
      offset: amount.length,
    );
    _noteController = TextEditingController(text: b?.note ?? '');
    _dueDate = b?.dueAt ?? DateTime.now().add(const Duration(days: 7));
    _frequency = b?.frequencyEnum ?? BillFrequency.monthly;
    _startAt = b?.templateStartAt;
    _endAt = b?.templateEndAt;
    _reminderDays = b?.reminderDaysBefore ?? 3;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 20),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final raw = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(raw) ?? 0;

    if (name.isEmpty) {
      AppSnackBar.showError(context, 'Nhập tên hóa đơn');
      return;
    }
    if (amount <= 0) {
      AppSnackBar.showError(context, 'Số tiền dự kiến phải lớn hơn 0');
      return;
    }
    if (_endAt != null && _endAt!.isBefore(_startAt ?? _dueDate)) {
      AppSnackBar.showError(
        context,
        'Ngày kết thúc phải sau ngày bắt đầu / đến hạn',
      );
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(budgetProvider.notifier);
    final err = _isEdit
        ? await notifier.updateBill(
            id: widget.existing!.id,
            name: name,
            amount: amount,
            dueDate: _dueDate,
            frequency: _frequency,
            startAt: _startAt,
            endAt: _endAt,
            clearEndAt: _endAt == null,
            note: _noteController.text,
            reminderDaysBefore: _reminderDays,
            categoryName: widget.existing!.name,
          )
        : await notifier.createBill(
            name: name,
            amount: amount,
            dueDate: _dueDate,
            frequency: _frequency,
            startAt: _startAt,
            endAt: _endAt,
            note: _noteController.text,
            reminderDaysBefore: _reminderDays,
            categoryName: name,
          );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      AppSnackBar.showError(context, err);
      return;
    }
    Navigator.of(context).pop();
    AppSnackBar.showSuccess(
      context,
      _isEdit ? 'Đã cập nhật hóa đơn' : 'Đã thêm hóa đơn "$name"',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_isEdit ? 'Sửa hóa đơn' : 'Thêm hóa đơn định kỳ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên hóa đơn',
                hintText: 'VD: Tiền nhà, tiền điện…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CurrencyTextField(
              controller: _amountController,
              labelText: 'Số tiền dự kiến',
            ),
            const SizedBox(height: 12),
            _dateField(
              label: 'Ngày đến hạn',
              value: _fmtDate(_dueDate),
              onTap: () =>
                  _pickDate(initial: _dueDate, onPicked: (d) => _dueDate = d),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BillFrequency>(
              initialValue: _frequency,
              decoration: InputDecoration(
                labelText: 'Chu kỳ lặp',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: BillFrequency.values
                  .map(
                    (f) => DropdownMenuItem(
                      value: f,
                      child: Text(
                        f.label,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _frequency = v);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _dateField(
                    label: 'Bắt đầu',
                    value: _startAt == null
                        ? 'Theo ngày đến hạn'
                        : _fmtDate(_startAt!),
                    onTap: () => _pickDate(
                      initial: _startAt ?? _dueDate,
                      onPicked: (d) => _startAt = d,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _dateField(
                    label: 'Kết thúc',
                    value: _endAt == null ? 'Không đặt' : _fmtDate(_endAt!),
                    onTap: () => _pickDate(
                      initial:
                          _endAt ?? _dueDate.add(const Duration(days: 365)),
                      onPicked: (d) => _endAt = d,
                    ),
                    onClear: _endAt == null
                        ? null
                        : () => setState(() => _endAt = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _reminderDays,
              decoration: InputDecoration(
                labelText: 'Nhắc trước',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [0, 1, 2, 3, 5, 7, 10, 14]
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text(
                        d == 0 ? 'Không nhắc' : '$d ngày',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _reminderDays = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Ghi chú (không bắt buộc)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal,
            foregroundColor: Colors.white,
          ),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isEdit ? 'Lưu' : 'Thêm hóa đơn'),
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required String value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: onClear != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today_outlined, size: 16),
        ),
        child: Text(value, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Dialog thanh toán
// ════════════════════════════════════════════════════════════════════

class _PayBillDialog extends ConsumerStatefulWidget {
  final RecurringBill bill;

  const _PayBillDialog({required this.bill});

  @override
  ConsumerState<_PayBillDialog> createState() => _PayBillDialogState();
}

enum _PayMethod { newTransaction, linkExisting }

class _PayBillDialogState extends ConsumerState<_PayBillDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _searchController;
  _PayMethod _method = _PayMethod.newTransaction;
  String? _walletId;
  BillPayPreview? _preview;
  List<BillCandidateTransaction> _candidates = const [];
  BillCandidateTransaction? _selectedTxn;
  bool _loadingPreview = false;
  bool _loadingCandidates = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final amount = widget.bill.amount.toInt().toString();
    _amountController = TextEditingController(text: amount);
    _amountController.selection = TextSelection.collapsed(
      offset: amount.length,
    );
    _searchController = TextEditingController();
    _searchController.addListener(_filterCandidates);
    _loadPreview();
    _loadCandidates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  double get _plannedAmount {
    if (_method == _PayMethod.linkExisting && _selectedTxn != null) {
      return _selectedTxn!.amount;
    }
    final raw = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(raw) ?? 0;
  }

  String get _amountParam => _plannedAmount.toInt().toString();

  Future<void> _loadPreview() async {
    setState(() => _loadingPreview = true);
    final p = await ref
        .read(budgetProvider.notifier)
        .previewBillPayment(widget.bill.id, amount: _amountParam);
    if (!mounted) return;
    setState(() {
      _preview = p;
      _loadingPreview = false;
    });
  }

  Future<void> _loadCandidates() async {
    setState(() => _loadingCandidates = true);
    try {
      final rows = await ref
          .read(budgetProvider.notifier)
          .billCandidates(widget.bill.id);
      if (!mounted) return;
      setState(() {
        _candidates = rows;
        _loadingCandidates = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCandidates = false);
    }
  }

  void _filterCandidates() {
    setState(() {});
  }

  List<BillCandidateTransaction> get _visibleCandidates {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _candidates;
    return _candidates
        .where(
          (c) =>
              (c.note ?? '').toLowerCase().contains(q) ||
              c.amount.toString().contains(q),
        )
        .toList();
  }

  Future<void> _submit() async {
    final notifier = ref.read(budgetProvider.notifier);
    if (_method == _PayMethod.linkExisting) {
      final txn = _selectedTxn;
      if (txn == null) {
        AppSnackBar.showError(context, 'Chọn một giao dịch để liên kết');
        return;
      }
      setState(() => _submitting = true);
      final err = await notifier.linkBillToTransaction(
        billId: widget.bill.id,
        transactionId: txn.id,
        expectedVersion: txn.version,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      if (err != null) {
        AppSnackBar.showError(context, err);
        return;
      }
      Navigator.pop(context);
      AppSnackBar.showSuccess(
        context,
        'Đã liên kết giao dịch và đánh dấu đã trả',
      );
      return;
    }

    final walletId = _walletId;
    if (walletId == null || walletId.isEmpty) {
      AppSnackBar.showError(context, 'Chọn ví thanh toán');
      return;
    }
    if (_plannedAmount <= 0) {
      AppSnackBar.showError(context, 'Số tiền thanh toán phải lớn hơn 0');
      return;
    }

    // Nếu thanh toán làm "Còn để chi" âm → yêu cầu xác nhận rõ ràng.
    final preview = _preview;
    if (preview != null &&
        preview.requiresConfirmation &&
        !await _confirmNegative(preview)) {
      return;
    }

    setState(() => _submitting = true);
    final now = DateTime.now();
    final occurredAt = '${now.toUtc().toIso8601String().split('.').first}.000Z';
    final err = await notifier.settleBill(
      billId: widget.bill.id,
      walletId: walletId,
      occurredAt: occurredAt,
      amount: _amountParam,
      note: widget.bill.name,
      allowNegativeAvailable: preview?.requiresConfirmation ?? false,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (err != null) {
      AppSnackBar.showError(context, err);
      return;
    }
    Navigator.pop(context);
    AppSnackBar.showSuccess(context, 'Đã thanh toán "${widget.bill.name}"');
  }

  Future<bool> _confirmNegative(BillPayPreview preview) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Còn để chi sẽ âm'),
        content: Text(
          'Sau khi thanh toán, tiền còn để chi là '
          '${_fmt(preview.afterAvailable)}. Bạn vẫn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Vẫn thanh toán'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetProvider);
    final wallets = state.walletOptions;
    _walletId ??= wallets.isNotEmpty ? wallets.first.id : null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Đánh dấu đã trả'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bill.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Dự kiến ${_fmt(widget.bill.amount)} • Hạn ${_fmtDate(widget.bill.dueAt)}',
              style: const TextStyle(fontSize: 11.5, color: _textSecondary),
            ),
            const SizedBox(height: 14),

            // Chọn phương thức
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFD3EFE8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _methodTab('Tạo giao dịch chi', _PayMethod.newTransaction),
                  _methodTab('Liên kết giao dịch', _PayMethod.linkExisting),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (_method == _PayMethod.newTransaction) ...[
              CurrencyTextField(
                controller: _amountController,
                labelText: 'Số tiền thực tế',
                onChanged: (_) => _loadPreview(),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _walletId,
                decoration: InputDecoration(
                  labelText: 'Ví thanh toán',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: wallets
                    .map(
                      (w) => DropdownMenuItem(
                        value: w.id,
                        child: Text(
                          '${w.name} (${_fmt(w.balance)})',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _walletId = v),
              ),
            ] else ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Tìm giao dịch',
                  hintText: 'Nội dung hoặc số tiền',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_loadingCandidates)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_visibleCandidates.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  child: const Text(
                    'Không có giao dịch chi phù hợp để liên kết',
                    style: TextStyle(fontSize: 11.5, color: _textSecondary),
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final c in _visibleCandidates)
                        InkWell(
                          onTap: () {
                            setState(() => _selectedTxn = c);
                            _loadPreview();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            color: _selectedTxn?.id == c.id
                                ? _tealSoft
                                : Colors.transparent,
                            child: Row(
                              children: [
                                Icon(
                                  _selectedTxn?.id == c.id
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: _selectedTxn?.id == c.id
                                      ? _teal
                                      : _textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.note?.isNotEmpty == true
                                            ? c.note!
                                            : 'Giao dịch chi',
                                        style: const TextStyle(fontSize: 12.5),
                                      ),
                                      Text(
                                        '${_fmt(c.amount)} • ${_fmtDate(c.occurredAt)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 14),
            _previewBody(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal,
            foregroundColor: Colors.white,
          ),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Xác nhận đã trả'),
        ),
      ],
    );
  }

  Widget _methodTab(String label, _PayMethod method) {
    final selected = _method == method;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _method = method),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? _teal : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewBody() {
    if (_loadingPreview && _preview == null) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final p = _preview;
    if (p == null) {
      return const Text(
        'Không tải được tác động thanh toán.',
        style: TextStyle(fontSize: 11.5, color: _textSecondary),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tác động lên 3 lớp tiền',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _previewRow('Tổng tiền hiện có', p.beforeTotal, p.afterTotal),
          _previewRow(
            'Hóa đơn chưa trả',
            p.beforeUnpaidBills,
            p.afterUnpaidBills,
          ),
          _previewRow(
            'Quỹ bảo vệ',
            p.beforeProtected,
            p.afterProtected,
            unchanged: true,
          ),
          _previewRow(
            'Còn để chi',
            p.beforeAvailable,
            p.afterAvailable,
            highlight: true,
          ),
          if (p.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final w in p.warnings)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_outlined,
                      size: 12,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        w,
                        style: const TextStyle(
                          fontSize: 10.5,
                          height: 1.3,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _previewRow(
    String label,
    double before,
    double after, {
    bool highlight = false,
    bool unchanged = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: highlight ? _textPrimary : _textSecondary,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            _fmt(before),
            style: const TextStyle(fontSize: 11, color: _textSecondary),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward, size: 11, color: _textSecondary),
          ),
          Text(
            _fmt(after),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: unchanged
                  ? _textSecondary
                  : (after < before
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF15803D)),
            ),
          ),
        ],
      ),
    );
  }
}
