import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/models/savings_goal.dart';
import '../providers/budget_provider.dart';

const _teal = Color(0xFF0F5B47);
const _tealSoft = Color(0xFFE2F6F0);
const _textPrimary = Color(0xFF1A1A1A);
const _textSecondary = Color(0xFF6B7280);
final _money = NumberFormat('#,###', 'vi_VN');

String _fmt(num v) => '${_money.format(v.round())} ₫';

/// Tab "Mục tiêu" trong trang Kế hoạch.
/// - Danh sách mục tiêu với tiến độ, tiền đã phân bổ, tiền bảo vệ
/// - Tạo mục tiêu mới (tên, số tiền đích, thời hạn)
/// - Phân bổ tiền trong ví cho mục tiêu
/// - Bật/tắt bảo vệ, có preview "Còn để chi" thay đổi bao nhiêu
class GoalsTabView extends ConsumerWidget {
  const GoalsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetProvider);
    final goals = state.savingsGoals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProtectedSummaryCard(
          protectedMoney: state.protectedMoney,
          spendable: state.spendableNow,
          walletTotal: state.walletTotal,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mục tiêu tiết kiệm',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              '${goals.length} mục tiêu',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (state.isLoading && goals.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator(color: _teal)),
          )
        else if (goals.isEmpty)
          _EmptyGoals()
        else
          for (final goal in goals)
            _GoalCard(
              goal: goal,
              wallets:
                  ref.read(budgetProvider.notifier).walletsForGoal(goal.id),
              onAllocate: () => _showAllocateDialog(context, ref, goal),
              onToggleProtect: () => _toggleProtect(context, ref, goal),
              onEdit: () => _showEditGoalDialog(context, ref, goal),
            ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showCreateGoalDialog(context, ref),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text(
              'Tạo mục tiêu mới',
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

  // ── Bật/tắt bảo vệ (có preview) ──────────────────────────────────
  Future<void> _toggleProtect(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
  ) async {
    final newProtect = !goal.protect;
    final preview = ref.read(budgetProvider.notifier).previewGoalImpact(
          goal: goal,
          newAllocatedTotal: goal.allocated,
          newProtect: newProtect,
        );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(newProtect ? 'Bật bảo vệ khoản này?' : 'Bỏ bảo vệ?'),
        content: _ImpactPreviewBody(
          preview: preview,
          description: newProtect
              ? '${_fmt(goal.allocated)} trong ví sẽ được giữ riêng cho '
                  '"${goal.name}" và bị loại khỏi "Còn để chi".'
              : '${_fmt(goal.allocated)} sẽ được trả lại vào "Còn để chi" '
                  'và có thể chi tiêu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newProtect ? _teal : const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(newProtect ? 'Bật bảo vệ' : 'Bỏ bảo vệ'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final err = await ref
        .read(budgetProvider.notifier)
        .setGoalProtection(goal.id, newProtect);
    if (!context.mounted) return;
    if (err != null) {
      AppSnackBar.showError(context, err);
      return;
    }
    AppSnackBar.showSuccess(
      context,
      newProtect ? 'Đã bật bảo vệ cho "${goal.name}"' : 'Đã bỏ bảo vệ',
    );
  }

  // ── Phân bổ tiền ──────────────────────────────────────────────────
  Future<void> _showAllocateDialog(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
  ) async {
    final wallets =
        ref.read(budgetProvider.notifier).walletsForGoal(goal.id);
    if (wallets.isEmpty) {
      AppSnackBar.showError(context, 'Chưa có ví nào để phân bổ');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => _AllocateDialog(goal: goal, wallets: wallets),
    );
  }

  // ── Tạo mục tiêu ──────────────────────────────────────────────────
  Future<void> _showCreateGoalDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _GoalFormDialog(),
    );
  }

  // ── Sửa mục tiêu ──────────────────────────────────────────────────
  Future<void> _showEditGoalDialog(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _GoalFormDialog(goal: goal),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Tổng quan quỹ bảo vệ
// ════════════════════════════════════════════════════════════════════

class _ProtectedSummaryCard extends StatelessWidget {
  final double protectedMoney;
  final double spendable;
  final double walletTotal;

  const _ProtectedSummaryCard({
    required this.protectedMoney,
    required this.spendable,
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: _tealSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, size: 18, color: _teal),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Quỹ bảo vệ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ),
              Text(
                _fmt(protectedMoney),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE8F5F1)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryCell(
                  label: 'Tổng tiền trong ví',
                  value: _fmt(walletTotal),
                  color: _textPrimary,
                ),
              ),
              Container(width: 1, height: 28, color: const Color(0xFFE8F5F1)),
              Expanded(
                child: _SummaryCell(
                  label: 'Còn để chi',
                  value: _fmt(spendable),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 13, color: _textSecondary),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Một khoản tiền chỉ được bảo vệ một lần. Tiền trong ví '
                    'tiết kiệm không bị trừ thêm nếu đã nằm trong mục tiêu.',
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

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCell({
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
          style: const TextStyle(fontSize: 10.5, color: _textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
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

class _EmptyGoals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.savings_outlined, size: 40, color: Color(0xFFBDBDBD)),
          SizedBox(height: 10),
          Text(
            'Chưa có mục tiêu tiết kiệm',
            style: TextStyle(fontSize: 13.5, color: _textSecondary),
          ),
          SizedBox(height: 4),
          Text(
            'Tạo mục tiêu để giữ riêng tiền cho quỹ dự phòng.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Card mục tiêu
// ════════════════════════════════════════════════════════════════════

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final List<GoalWalletOption> wallets;
  final VoidCallback onAllocate;
  final VoidCallback onToggleProtect;
  final VoidCallback onEdit;

  const _GoalCard({
    required this.goal,
    required this.wallets,
    required this.onAllocate,
    required this.onToggleProtect,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final pct = goal.percentInt;
    final targetLabel = goal.targetAt == null
        ? 'Không đặt hạn'
        : 'Hạn ${DateFormat('dd/MM/yyyy').format(goal.targetAt!.toLocal())}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: goal.protect ? _tealSoft : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  goal.protect ? Icons.shield : Icons.savings_outlined,
                  size: 18,
                  color: goal.protect ? _teal : _textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      targetLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: _textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Tiến độ ────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.percent,
              minHeight: 8,
              backgroundColor: const Color(0xFFEAF8F5),
              color: goal.isCompleted
                  ? const Color(0xFF16A34A)
                  : goal.protect
                      ? _teal
                      : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${_fmt(goal.allocated)} / ${_fmt(goal.targetAmount)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: goal.protect ? _teal : _textSecondary,
                ),
              ),
            ],
          ),

          if (goal.daysLeft != null && !goal.isCompleted) ...[
            const SizedBox(height: 4),
            Text(
              goal.requiredPerDay != null
                  ? 'Còn ${goal.daysLeft} ngày • cần ~${_fmt(goal.requiredPerDay!)}/ngày'
                  : 'Còn ${goal.daysLeft} ngày',
              style: const TextStyle(fontSize: 10.5, color: _textSecondary),
            ),
          ],

          // ── Phân bổ theo ví ────────────────────────────────────
          if (goal.allocations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: goal.allocations
                  .where((a) => a.amount > 0)
                  .map((a) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${a.walletName}: ${_fmt(a.amount)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: _textSecondary,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAllocate,
                  icon: const Icon(Icons.account_balance_wallet_outlined,
                      size: 15),
                  label: const Text('Phân bổ', style: TextStyle(fontSize: 12)),
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
                child: OutlinedButton.icon(
                  onPressed: onToggleProtect,
                  icon: Icon(
                    goal.protect
                        ? Icons.lock_open_outlined
                        : Icons.lock_outline,
                    size: 15,
                  ),
                  label: Text(
                    goal.protect ? 'Bỏ bảo vệ' : 'Bảo vệ',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        goal.protect ? const Color(0xFFD97706) : _teal,
                    side: BorderSide(
                      color: goal.protect
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFB7E4D8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Preview tác động
// ════════════════════════════════════════════════════════════════════

class _ImpactPreviewBody extends StatelessWidget {
  final GoalImpactPreview preview;
  final String description;

  const _ImpactPreviewBody({
    required this.preview,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final change = preview.change;
    final increased = preview.isIncrease;
    final color = increased ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final sign = change >= 0 ? '+' : '−';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Còn để chi hiện tại',
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                  Text(
                    _fmt(preview.before),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    increased ? 'Sẽ tăng' : 'Sẽ giảm',
                    style: const TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                  Text(
                    '$sign${_fmt(change.abs())}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFE5E7EB)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Còn để chi sau khi đổi',
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                  Text(
                    _fmt(preview.after),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Dialog phân bổ
// ════════════════════════════════════════════════════════════════════

class _AllocateDialog extends ConsumerStatefulWidget {
  final SavingsGoal goal;
  final List<GoalWalletOption> wallets;

  const _AllocateDialog({required this.goal, required this.wallets});

  @override
  ConsumerState<_AllocateDialog> createState() => _AllocateDialogState();
}

class _AllocateDialogState extends ConsumerState<_AllocateDialog> {
  late GoalWalletOption _wallet;
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Ưu tiên ví đang có phân bổ cho mục tiêu này
    _wallet = widget.wallets.firstWhere(
      (w) => (widget.goal.allocationIn(w.id) ?? 0) > 0,
      orElse: () => widget.wallets.first,
    );
    final initial =
        (widget.goal.allocationIn(_wallet.id) ?? 0).toInt().toString();
    _controller = TextEditingController(text: initial);
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _amount {
    final raw = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(raw) ?? 0;
  }

  /// Tổng phân bổ mới nếu lưu (gồm phần ví khác của mục tiêu này)
  double get _newTotal {
    final otherWallets = widget.goal.allocations
        .where((a) => a.walletId != _wallet.id)
        .fold<double>(0, (s, a) => s + a.amount);
    return otherWallets + _amount;
  }

  GoalImpactPreview get _preview =>
      ref.read(budgetProvider.notifier).previewGoalImpact(
            goal: widget.goal,
            newAllocatedTotal: _newTotal,
            newProtect: widget.goal.protect,
          );

  Future<void> _save() async {
    final max = _wallet.allocatable;
    if (_amount > max + 0.5) {
      AppSnackBar.showError(
        context,
        'Vượt số tiền khả dụng trong "${_wallet.name}" '
        '(tối đa ${_fmt(max)})',
      );
      return;
    }
    if (widget.goal.protect && _newTotal > widget.goal.targetAmount) {
      AppSnackBar.showError(
        context,
        'Tổng phân bổ vượt số tiền đích (${_fmt(widget.goal.targetAmount)})',
      );
      return;
    }

    setState(() => _saving = true);
    final err = await ref.read(budgetProvider.notifier).setGoalAllocation(
          goalId: widget.goal.id,
          walletId: _wallet.id,
          amount: _amount,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      AppSnackBar.showError(context, err);
      return;
    }
    Navigator.of(context).pop();
    AppSnackBar.showSuccess(context, 'Đã cập nhật phân bổ cho "${widget.goal.name}"');
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final max = _wallet.allocatable;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Phân bổ cho "${widget.goal.name}"'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chọn ví
            DropdownButtonFormField<String>(
              initialValue: _wallet.id,
              decoration: InputDecoration(
                labelText: 'Ví nguồn',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Khả dụng: ${_fmt(max)}',
              ),
              items: widget.wallets
                  .map((w) => DropdownMenuItem(
                        value: w.id,
                        child: Text(
                          '${w.name} (${_fmt(w.allocatable)})',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _wallet = widget.wallets.firstWhere((w) => w.id == v);
                  final cur =
                      (widget.goal.allocationIn(v) ?? 0).toInt().toString();
                  _controller.value = TextEditingValue(
                    text: cur,
                    selection:
                        TextSelection.collapsed(offset: cur.length),
                  );
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Số tiền gán cho mục tiêu',
                suffixText: '₫',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ImpactPreviewBody(
              preview: preview,
              description:
                  'Tổng phân bổ sau khi lưu: ${_fmt(_newTotal)} / '
                  '${_fmt(widget.goal.targetAmount)}. '
                  'Tiền chỉ được đánh dấu giữ riêng, không chuyển khỏi ví.',
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
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Lưu phân bổ'),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Dialog tạo / sửa mục tiêu
// ════════════════════════════════════════════════════════════════════

class _GoalFormDialog extends ConsumerStatefulWidget {
  final SavingsGoal? goal;

  const _GoalFormDialog({this.goal});

  @override
  ConsumerState<_GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends ConsumerState<_GoalFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  DateTime? _targetAt;
  late bool _protect;
  bool _saving = false;

  bool get _isEdit => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameController = TextEditingController(text: g?.name ?? '');
    final amount = g == null ? '' : g.targetAmount.toInt().toString();
    _amountController = TextEditingController(text: amount);
    _amountController.selection =
        TextSelection.collapsed(offset: amount.length);
    _targetAt = g?.targetAt?.toLocal();
    _protect = g?.protect ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetAt ?? now.add(const Duration(days: 90)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) setState(() => _targetAt = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final raw = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(raw) ?? 0;

    if (name.isEmpty) {
      AppSnackBar.showError(context, 'Nhập tên mục tiêu');
      return;
    }
    if (amount <= 0) {
      AppSnackBar.showError(context, 'Số tiền đích phải lớn hơn 0');
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(budgetProvider.notifier);
    final err = _isEdit
        ? await notifier.updateGoal(
            widget.goal!.id,
            name: name,
            targetAmount: amount,
            targetAt: _targetAt,
            protect: _protect,
          )
        : await notifier.createGoal(
            name: name,
            targetAmount: amount,
            targetAt: _targetAt,
            protect: _protect,
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
      _isEdit ? 'Đã cập nhật mục tiêu' : 'Đã tạo mục tiêu "$name"',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_isEdit ? 'Sửa mục tiêu' : 'Tạo mục tiêu tiết kiệm'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên mục tiêu',
                hintText: 'VD: Quỹ dự phòng',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền đích',
                suffixText: '₫',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Thời hạn (không bắt buộc)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today_outlined,
                      size: 18),
                ),
                child: Text(
                  _targetAt == null
                      ? 'Không đặt hạn'
                      : DateFormat('dd/MM/yyyy').format(_targetAt!),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _protect,
              onChanged: (v) => setState(() => _protect = v),
              title: const Text(
                'Bảo vệ khoản tiền',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Loại tiền đã phân bổ khỏi "Còn để chi"',
                style: TextStyle(fontSize: 11.5),
              ),
              activeTrackColor: _teal,
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
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(_isEdit ? 'Lưu' : 'Tạo mục tiêu'),
        ),
      ],
    );
  }
}
