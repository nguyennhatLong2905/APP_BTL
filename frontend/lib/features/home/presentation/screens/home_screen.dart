import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:flutter_riverpod_clean_architecture/core/widgets/app_snackbar.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/datasources/profile_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/providers/home_provider.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/widgets/balance_card.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/widgets/calculation_breakdown_sheet.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/widgets/recent_transactions.dart';
import 'package:flutter_riverpod_clean_architecture/features/wallet/presentation/widgets/wallet_reconciliation_sheet.dart';

// ════════════════════════════════════════════════════════════════════
// Màn hình Home – Tổng Quan  (theo thiết kế Figma)
// ════════════════════════════════════════════════════════════════════

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // ── Màu sắc ─────────────────────────────────────────────────────
  static const Color _teal = Color(0xFF2C7873);
  static const Color _tealDark = Color(0xFF1A4F4C);
  static const Color _tealBg = Color(0xFFEBF6F3);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF757575);
  static const Color _textHint = Color(0xFF9E9E9E);
  static const Color _warning = Color(0xFFF57C00);
  static const Color _warningBg = Color(0xFFFFF8F0);
  static const Color _layer2Bg = Color(0xFFFFF0EE);
  static const Color _layer2Amount = Color(0xFFD32F2F);
  static const Color _layer3Bg = Color(0xFFFEFDE8);



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);
    
    // Load dữ liệu nếu chưa có hoặc cũ
    if (homeState.dashboardData == null && !homeState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.loadDashboard();
      });
    }
    
    // Tự động reload khi quay lại màn hình (sau 30s)
    // Kiểm tra xem dữ liệu đã cũ chưa
    if (homeState.lastLoadedAt != null && !homeState.isLoading) {
      final age = DateTime.now().difference(homeState.lastLoadedAt!);
      if (age.inSeconds >= 30) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifier.loadDashboard();
        });
      }
    }

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Loading skeleton khi chờ API
    if (homeState.isLoading && homeState.dashboardData == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2C7873)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom App Bar ──────────────────────────────────────
            _buildAppBar(context),
            // ── Scrollable Content ──────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: ngày + lời chào
                    _buildHeader(context, ref),

                    // Warning banner (nếu còn hiện)
                    if (homeState.showWarningBanner)
                      _buildWarningBanner(context, ref, notifier),

                    const SizedBox(height: 4),

                    // Card "Còn để chi" — số liệu thật từ /dashboard
                    Builder(
                      builder: (context) {
                        final d = homeState.dashboardData;
                        final days = d?.daysRemaining ?? 0;
                        final payday = d?.nextPayday;
                        return BalanceCard(
                          remainingAmount: d?.spendable ?? 0,
                          dailyRate: d?.dailyLimit ?? 0,
                          daysLeft: days < 0 ? 0 : days,
                          nextPaydayLabel: payday == null
                              ? '--'
                              : DateFormat('dd/MM').format(payday),
                          progressPercent: 0,
                          startDateLabel: '--',
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Section "3 Lớp Tiền Minh Bạch"
                    _buildThreeLayerSection(context, ref),

                    const SizedBox(height: 10),

                    // Card "Mua hay chờ?"
                    _buildMuaHayCho(context),

                    const SizedBox(height: 20),

                    // Hóa đơn sắp tới + Giao dịch gần đây
                    const RecentTransactionsSection(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ViAnBottomNavBar(currentIndex: 0),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: Colors.white,
      child: Row(
        children: [
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VÍ AN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _textHint,
                  letterSpacing: 1.5,
                ),
              ),
              const Text(
                'Tong Quan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                  height: 1.1,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Bell icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: _textPrimary,
              size: 22,
            ),
          ),

          const SizedBox(width: 10),

          // Avatar → mở Cài Đặt (có đăng xuất)
          GestureDetector(
            onTap: () => context.push(AppConstants.settingsRoute),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _teal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header: Ngày + lời chào ───────────────────────────────────────
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);
    final user = ref.watch(authProvider).user;
    final firstName = user != null ? user.name.split(' ').last : 'bạn';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ngày + trạng thái tài chính
          Row(
            children: [
              Text(
                _formatDate(DateTime.now()),
                style: const TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'Khoảng lặng tài chính',
                style: TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Lời chào + eye icon
          Row(
            children: [
              Text(
                '${_greeting()}, $firstName',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: notifier.toggleBalanceVisibility,
                child: Icon(
                  homeState.balanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _textSecondary,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
      final isoPayday =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}T00:00:00.000Z';
      await pds.updateProfile(nextPayday: isoPayday);

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

  // ── Warning Banner ────────────────────────────────────────────────
  Widget _buildWarningBanner(
      BuildContext context, WidgetRef ref, HomeNotifier notifier) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: _warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'TRẠNG THÁI DỮ LIỆU CẦN CHÚ Ý',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _warning,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: notifier.dismissWarning,
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Chưa ghi nhận ngày nhận lương chu kỳ tới. Hãy cập nhật để số tiền "Còn để chi" phản ánh chính xác nhất từng ngày.',
            style: TextStyle(
              fontSize: 12,
              color: _textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Nút chính
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickNextPayday(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Bổ sung chu kỳ lương →',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Nút phụ
              GestureDetector(
                onTap: () => showCalculationBreakdownSheet(context, ref),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    'Chi tiết',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textSecondary,
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

  // ── 3 Lớp Tiền Minh Bạch ─────────────────────────────────────────
  Widget _buildThreeLayerSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _tealBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: _teal, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                '3 LỚP TIỀN MINH BẠCH',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => showCalculationBreakdownSheet(context, ref),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Tách bạch an tâm',
                    style: TextStyle(
                      fontSize: 12,
                      color: _teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── LỚP 1: Số tiền hiện có ──────────────────────────────
          _buildLayer1(context, ref),

          const SizedBox(height: 8),

          // ── LỚP 2: Khoản đã bảo vệ ─────────────────────────────
          _buildLayer2(context, ref),

          const SizedBox(height: 8),

          // ── LỚP 3: An tâm chi tiêu ──────────────────────────────
          _buildLayer3(),
        ],
      ),
    );
  }

  Widget _buildLayer1(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => showWalletReconciliationSheet(context, ref),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8F5F2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer(
                builder: (ctx, ref, _) {
                  final d = ref.watch(homeProvider).dashboardData;
                  final bal = d?.totalBalance ?? 0;
                  return Row(
                    children: [
                      const Text(
                        'LỚP 1: SỐ TIỀN HIỆN CÓ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _textHint,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.tune_outlined, size: 13, color: _teal),
                      const Spacer(),
                      Text(
                        _fmtAmount(bal),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _teal,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Consumer(
                builder: (ctx, ref, _) {
                  final d = ref.watch(homeProvider).dashboardData;
                  final wallets = d?.wallets ?? [];

                  if (wallets.isEmpty) {
                    return Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          'Chưa có thông tin ví',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    );
                  }

                  // Tính tổng tiền mặt (cash) và tài khoản (bank + e_wallet)
                  double cashTotal = 0;
                  double bankTotal = 0;

                  for (final w in wallets) {
                    if (w.type == 'cash') {
                      cashTotal += w.balance;
                    } else {
                      bankTotal += w.balance;
                    }
                  }

                  // Nếu chỉ có 1 loại ví, hiển thị chi tiết từng ví
                  if (wallets.length == 1) {
                    final w = wallets[0];
                    return Row(
                      children: [
                        Icon(
                          w.type == 'cash'
                              ? Icons.account_balance_wallet_outlined
                              : Icons.account_balance_outlined,
                          size: 14,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${w.name}: ${_fmtAmount(w.balance)}',
                          style: const TextStyle(fontSize: 12, color: _textSecondary),
                        ),
                        const Spacer(),
                        const Text(
                          'Đối chiếu ví →',
                          style: TextStyle(
                            fontSize: 11,
                            color: _teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }

                  // Hiển thị tổng theo loại
                  return Row(
                    children: [
                      if (cashTotal > 0) ...[
                        const Icon(Icons.account_balance_wallet_outlined,
                            size: 14, color: _textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Tiền mặt: ${_fmtAmount(cashTotal)}',
                          style: const TextStyle(fontSize: 12, color: _textSecondary),
                        ),
                      ],
                      if (cashTotal > 0 && bankTotal > 0) const SizedBox(width: 16),
                      if (bankTotal > 0) ...[
                        const Icon(Icons.account_balance_outlined,
                            size: 14, color: _textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Tài khoản: ${_fmtAmount(bankTotal)}',
                          style: const TextStyle(fontSize: 12, color: _textSecondary),
                        ),
                      ],
                      if (cashTotal == 0 && bankTotal == 0) ...[
                        Icon(Icons.info_outline, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          'Số dư: 0 đ',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                      const Spacer(),
                      const Text(
                        'Đối chiếu ví →',
                        style: TextStyle(
                          fontSize: 11,
                          color: _teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayer2(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (ctx, ref, _) {
        final d = ref.watch(homeProvider).dashboardData;
        final unpaidBills = d?.unpaidBills ?? 0;
        final protectedMoney = d?.protectedMoney ?? 0;
        final layer2Total = unpaidBills + protectedMoney;
        return Material(
          color: _layer2Bg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => showCalculationBreakdownSheet(context, ref),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'LỚP 2: KHOẢN ĐÃ BẢO VỆ & NGHĨA VỤ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _textHint,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _fmtAmount(layer2Total),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _layer2Amount,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hóa đơn cố định:',
                          style: TextStyle(fontSize: 11, color: _textSecondary),
                        ),
                        Text(
                          _fmtAmount(unpaidBills),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quỹ dự phòng:',
                          style: TextStyle(fontSize: 11, color: _textSecondary),
                        ),
                        Text(
                          _fmtAmount(protectedMoney),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 13,
                    color: _layer2Amount.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Text(
                      'Được khóa bảo vệ an toàn, không tính vào tiền tiêu',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  },
);
}

  Widget _buildLayer3() {
    return Consumer(
      builder: (ctx, ref, _) {
        final d = ref.watch(homeProvider).dashboardData;
        final spendable = d?.spendable ?? 0;
        final dailyRate = d?.dailyLimit ?? 0;
        // dailyReference từ backend có thể âm (chi > thu); hiển thị theo đúng dấu
        final rawDaily = d?.dailyReference;
        final dailySign = rawDaily != null && rawDaily < 0 ? '-' : '≈';
        final dailyDisplay = rawDaily != null
            ? '$dailySign ${_fmtAmount(rawDaily.abs())}/ngày'
            : (dailyRate > 0 ? '≈ ${_fmtAmount(dailyRate)}/ngày' : '');

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _layer3Bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LỚP 3: AN TÂM CHI TIÊU',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _textHint,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Số tiền thực còn tự do sử dụng',
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmtAmount(spendable),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _teal,
                        ),
                      ),
                      if (dailyDisplay.isNotEmpty)
                        Text(
                          dailyDisplay,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Mua hay chờ? ─────────────────────────────────────────────────
  Widget _buildMuaHayCho(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _tealBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: _teal,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.balance_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Text
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mua hay chờ?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  'Xem khoản mua ảnh hưởng',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Button
          GestureDetector(
            onTap: () => context.go(AppConstants.smartSpendingRoute),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: _tealDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Thử tính',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────
  String _formatDate(DateTime d) {
    const days = ['Chủ nhật', 'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy'];
    return '${days[d.weekday % 7]}, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Chào buổi sáng';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String _fmtAmount(double v) {
    final str = v.abs().toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return '${buf.toString()} đ';
  }
}
