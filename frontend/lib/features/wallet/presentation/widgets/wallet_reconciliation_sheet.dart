import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/refresh_financial_data.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/currency_text_field.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../data/datasources/wallet_remote_data_source.dart';

/// Modal quản lý danh sách ví và Đối chiếu số dư thực tế
Future<void> showWalletReconciliationSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _WalletReconciliationModal(),
  );
}

class _WalletReconciliationModal extends ConsumerStatefulWidget {
  const _WalletReconciliationModal();

  @override
  ConsumerState<_WalletReconciliationModal> createState() =>
      _WalletReconciliationModalState();
}

class _WalletReconciliationModalState
    extends ConsumerState<_WalletReconciliationModal> {
  static const Color _teal = Color(0xFF2C7873);
  static const Color _tealBg = Color(0xFFEBF6F3);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF757575);

  final _money = NumberFormat('#,###', 'vi_VN');
  List<Map<String, dynamic>> _wallets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWallets();
  }

  Future<void> _fetchWallets() async {
    setState(() => _isLoading = true);
    try {
      final ds = ref.read(walletRemoteDataSourceProvider);
      final list = await ds.getWallets();
      if (mounted) {
        setState(() {
          _wallets = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showReconcileDialog(Map<String, dynamic> wallet) async {
    final currentBal = num.tryParse('${wallet['balance'] ?? 0}')?.toDouble() ?? 0.0;
    final balanceController =
        TextEditingController(text: currentBal.toInt().toString());
    final noteController = TextEditingController();
    double actualBal = currentBal;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final diff = actualBal - currentBal;
            final isZero = diff == 0;
            final isPositive = diff > 0;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: _tealBg, shape: BoxShape.circle),
                    child: const Icon(Icons.sync_alt, color: _teal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đối Chiếu Ví "${wallet['name']}"',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nhập số tiền thực tế bạn đang có trong ví này. Hệ thống sẽ phát hiện chênh lệch và tạo một bản ghi điều chỉnh riêng biệt.',
                      style: TextStyle(fontSize: 12, color: _textSecondary, height: 1.35),
                    ),
                    const SizedBox(height: 14),

                    // Số dư trên app
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Số dư trên ứng dụng:',
                              style: TextStyle(fontSize: 12, color: _textSecondary)),
                          Text(
                            '${_money.format(currentBal.toInt())} ₫',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold, color: _textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nhập số dư thực tế
                    CurrencyTextField(
                      controller: balanceController,
                      labelText: 'Số tiền thực tế đếm được',
                      onChanged: (val) {
                        setDialogState(() {
                          actualBal = val;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    // Chênh lệch
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isZero
                            ? Colors.green.shade50
                            : (isPositive ? Colors.blue.shade50 : Colors.red.shade50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isZero
                                ? Icons.check_circle_outline
                                : (isPositive ? Icons.arrow_upward : Icons.arrow_downward),
                            size: 16,
                            color: isZero
                                ? Colors.green.shade700
                                : (isPositive ? Colors.blue.shade700 : Colors.red.shade700),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isZero
                                  ? 'Khớp hoàn toàn, không có chênh lệch.'
                                  : 'Chênh lệch: ${isPositive ? '+' : ''}${_money.format(diff.toInt())} ₫ (${isPositive ? 'thừa' : 'thiếu'})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isZero
                                    ? Colors.green.shade800
                                    : (isPositive ? Colors.blue.shade800 : Colors.red.shade800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ghi chú lý do
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú lý do điều chỉnh (tùy chọn)',
                        hintText: 'VD: Quên ghi khoản trà đá, phí ngân hàng...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Xác nhận điều chỉnh'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) {
      balanceController.dispose();
      noteController.dispose();
      return;
    }

    final note = noteController.text.trim();
    balanceController.dispose();
    noteController.dispose();

    try {
      final ds = ref.read(walletRemoteDataSourceProvider);
      final walletId = wallet['_id'] as String? ?? wallet['id'] as String;
      final version = (wallet['version'] as num?)?.toInt() ?? 0;

      await ds.reconcileWallet(
        id: walletId,
        actualBalance: actualBal.toInt().toString(),
        expectedVersion: version,
        note: note.isNotEmpty ? note : 'Điều chỉnh đối chiếu số dư',
      );

      // Làm mới toàn bộ dashboard và sổ giao dịch
      invalidateFinancialDataFromWidget(ref);
      await ref.read(homeProvider.notifier).loadDashboard(force: true);
      await _fetchWallets();

      if (mounted) {
        AppSnackBar.showSuccess(
            context, 'Đã đối chiếu và cập nhật số dư ví "${wallet['name']}"!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Không thể đối chiếu ví: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Handle
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
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: _teal, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý ví & Đối chiếu số dư',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      'Đối chiếu số tiền thực tế để dòng tiền luôn minh bạch',
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

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(color: _teal)),
            )
          else if (_wallets.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    const Text('Chưa có ví nào được tạo',
                        style: TextStyle(fontSize: 14, color: _textSecondary)),
                  ],
                ),
              ),
            )
          else
            for (final w in _wallets)
              _buildWalletTile(w),

          const SizedBox(height: 14),

          // Add Wallet Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final res = await context.push('/create-wallet');
                if (res == true) {
                  ref.read(homeProvider.notifier).loadDashboard(force: true);
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm ví mới', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _teal,
                side: const BorderSide(color: _teal),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletTile(Map<String, dynamic> w) {
    final name = w['name'] as String? ?? 'Ví';
    final type = w['type'] as String? ?? 'cash';
    final bal = num.tryParse('${w['balance'] ?? 0}')?.toDouble() ?? 0.0;
    final isCash = type == 'cash';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8F5F1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCash ? const Color(0xFFD4EDE5) : const Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCash ? Icons.money : Icons.account_balance,
              size: 18,
              color: isCash ? _teal : const Color(0xFF1565C0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: _textPrimary),
                ),
                Text(
                  isCash ? 'Tiền mặt' : 'Tài khoản thanh toán',
                  style: const TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_money.format(bal.toInt())} ₫',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: _teal),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showReconcileDialog(w),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _tealBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _teal.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync, size: 11, color: _teal),
                      SizedBox(width: 3),
                      Text(
                        'Đối chiếu',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: _teal),
                      ),
                    ],
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

