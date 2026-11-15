import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/data/datasources/profile_remote_data_source.dart';
import '../providers/home_provider.dart';

/// Modal chi tiết "Cách tính Còn để chi" theo đúng luồng nghiệp vụ Ví An
Future<void> showCalculationBreakdownSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _CalculationBreakdownModal(),
  );
}

class _CalculationBreakdownModal extends ConsumerWidget {
  const _CalculationBreakdownModal();

  static const Color _teal = Color(0xFF2C7873);
  static const Color _tealBg = Color(0xFFEBF6F3);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF757575);
  static const Color _red = Color(0xFFD32F2F);

  String _fmt(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount.abs().toInt())} ₫';
  }

  Future<void> _pickNextPayday(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'CHỌN NGÀY NHẬN LƯƠNG TIẾP THEO',
      confirmText: 'LƯU NGÀY LƯƠNG',
      cancelText: 'HỦY',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _teal,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null || !context.mounted) return;

    try {
      final pds = ref.read(profileRemoteDataSourceProvider);
      // Format ISO 8601 UTC
      final isoPayday =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}T00:00:00.000Z';
      await pds.updateProfile(nextPayday: isoPayday);

      // Reload dashboard
      await ref.read(homeProvider.notifier).loadDashboard(force: true);

      if (context.mounted) {
        AppSnackBar.showSuccess(context,
            'Đã cập nhật ngày nhận lương: ${DateFormat('dd/MM/yyyy').format(picked)}');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Không thể cập nhật ngày lương: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final d = homeState.dashboardData;

    final totalBalance = d?.totalBalance ?? 0;
    final unpaidBills = d?.unpaidBills ?? 0;
    final protectedMoney = d?.protectedMoney ?? 0;
    final spendable = d?.spendable ?? (totalBalance - unpaidBills - protectedMoney);
    final daysRemaining = d?.daysRemaining ?? 0;
    final nextPayday = d?.nextPayday;
    final dailyReference = d?.dailyReference ?? (daysRemaining > 0 ? spendable / daysRemaining : 0);
    final isNegative = spendable < 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _tealBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calculate_outlined, color: _teal, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cách tính "Còn để chi"',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      'Công thức minh bạch dựa trên dòng tiền thực tế',
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Formula banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FBF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4EDE5)),
            ),
            child: const Text(
              'Còn để chi = Tiền hiện có − Hóa đơn chưa trả − Tiền được bảo vệ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _teal,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Breakdown List
          _buildRow(
            label: '1. Tiền hiện có (tất cả các ví)',
            amountStr: '+${_fmt(totalBalance)}',
            amountColor: _teal,
            icon: Icons.account_balance_wallet_outlined,
            iconBg: _tealBg,
            subtitle: d != null && d.wallets.isNotEmpty
                ? d.wallets.map((w) => '${w.name}: ${_fmt(w.balance)}').join(' • ')
                : 'Chưa có thông tin ví',
          ),
          const SizedBox(height: 10),

          _buildRow(
            label: '2. Hóa đơn chưa trả trước ngày lương',
            amountStr: '-${_fmt(unpaidBills)}',
            amountColor: _red,
            icon: Icons.receipt_long_outlined,
            iconBg: const Color(0xFFFFEBEE),
            subtitle: unpaidBills > 0
                ? 'Đã được giữ riêng an toàn để tránh bị tiêu lạm'
                : 'Không có hóa đơn chưa trả trong kỳ',
          ),
          const SizedBox(height: 10),

          _buildRow(
            label: '3. Khoản tiền được bảo vệ',
            amountStr: '-${_fmt(protectedMoney)}',
            amountColor: const Color(0xFFE65100),
            icon: Icons.shield_outlined,
            iconBg: const Color(0xFFFFF3E0),
            subtitle: protectedMoney > 0
                ? 'Quỹ dự phòng / Mục tiêu tiết kiệm đã bật bảo vệ'
                : 'Chưa khóa khoản tiền bảo vệ nào',
          ),

          const Divider(height: 24, thickness: 1),

          // Result row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CÒN ĐỂ CHI THỰC TẾ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nextPayday != null
                        ? 'Còn $daysRemaining ngày (đến ${DateFormat('dd/MM').format(nextPayday)})'
                        : 'Chưa cài đặt ngày lương chu kỳ tới',
                    style: TextStyle(
                      fontSize: 12,
                      color: isNegative ? _red : _textSecondary,
                      fontWeight: isNegative ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              Text(
                '${isNegative ? '-' : ''}${_fmt(spendable.abs())}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isNegative ? _red : _teal,
                ),
              ),
            ],
          ),

          // Daily reference note
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isNegative ? const Color(0xFFFFEBEE) : const Color(0xFFFEFDE8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isNegative ? Icons.warning_amber_rounded : Icons.info_outline,
                  size: 16,
                  color: isNegative ? _red : const Color(0xFFF57C00),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isNegative
                        ? 'Số tiền hiện đang âm. Bạn đang có nghĩa vụ hóa đơn hoặc quỹ bảo vệ lớn hơn số tiền sẵn có. Hãy xem lại kế hoạch chi tiêu.'
                        : 'Mức chi bình quân: ≈ ${_fmt(dailyReference.abs())}/ngày. Đây là mốc tham khảo tự do, không phải hạn mức bắt buộc.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isNegative ? _red : const Color(0xFF5D4037),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _pickNextPayday(context, ref);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Đổi ngày lương', style: TextStyle(fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _teal,
                    side: const BorderSide(color: _teal),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go(AppConstants.budgetPlanningRoute);
                  },
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Chỉnh kế hoạch', style: TextStyle(fontSize: 12.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String amountStr,
    required Color amountColor,
    required IconData icon,
    required Color iconBg,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: amountColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: _textSecondary),
              ),
            ],
          ),
        ),
        Text(
          amountStr,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: amountColor),
        ),
      ],
    );
  }
}

