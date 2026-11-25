import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/data/datasources/profile_remote_data_source.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/home_style.dart';
import '../widgets/money_layers.dart';
import '../widgets/recent_transactions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _editingPayday = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(homeProvider.notifier).loadDashboard(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);
    final name = ref.watch(authProvider.select((auth) => auth.user?.name));
    final names = name?.trim().split(RegExp(r'\s+'));
    final firstName = names == null || names.last.isEmpty ? 'bạn' : names.last;
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final data = state.dashboardData;
    final nextPayday = data?.nextPayday;
    final days = data?.daysRemaining;
    final payday =
        nextPayday != null &&
            (days == null
                ? DateUtils.dateOnly(nextPayday).isAfter(today)
                : days > 0)
        ? nextPayday
        : null;
    final visible = state.balanceVisible;
    final formattedDate = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(now);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: HomeStyle.primary,
            onRefresh: () => notifier.loadDashboard(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              children: [
                _HomeHeader(initial: firstName.characters.first.toUpperCase()),
                const SizedBox(height: 10),
                Text(
                  '${_greeting(now)}, $firstName',
                  style: HomeStyle.heading.copyWith(fontSize: 26, height: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formattedDate[0].toUpperCase()}${formattedDate.substring(1)}',
                  style: HomeStyle.detail.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 14),
                BalanceCard(
                  amount: data?.spendable,
                  visible: visible,
                  onToggle: notifier.toggleBalanceVisibility,
                ),
                const SizedBox(height: 24),
                if (data != null) ...[
                  MoneyLayers(data: data, visible: visible),
                  const SizedBox(height: 8),
                  _HomeAction(
                    icon: Icons.calendar_today_outlined,
                    title: payday == null
                        ? 'Thêm ngày nhận lương'
                        : 'Ngày nhận lương · ${DateFormat('dd/MM').format(payday)}',
                    detail: payday == null
                        ? 'Để biết mỗi ngày có thể chi bao nhiêu'
                        : days == null
                        ? null
                        : 'Khoảng ${HomeStyle.money(data.dailyLimit, visible: visible)}/ngày',
                    onTap: _editingPayday ? null : () => _pickPayday(payday),
                  ),
                  const Divider(height: 1, color: HomeStyle.outline),
                ] else if (state.errorMessage != null) ...[
                  const Text(
                    'Không tải được dữ liệu tổng quan.',
                    style: HomeStyle.detail,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => notifier.loadDashboard(force: true),
                      child: const Text('Thử lại'),
                    ),
                  ),
                ] else
                  const Center(
                    child: CircularProgressIndicator(color: HomeStyle.primary),
                  ),
                _HomeAction(
                  icon: Icons.calculate_outlined,
                  title: 'Mua hay chờ?',
                  action: 'Thử tính',
                  onTap: () => context.go(AppConstants.smartSpendingRoute),
                ),
                if (data != null) ...[
                  const SizedBox(height: 16),
                  RecentTransactionsSection(data: data, visible: visible),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: const ViAnBottomNavBar(currentIndex: 0),
      ),
    );
  }

  Future<void> _pickPayday(DateTime? payday) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = DateTime(today.year, today.month, today.day + 1);
    final defaultLastDate = DateTime(today.year, today.month, today.day + 90);
    final lastDate = payday != null && payday.isAfter(defaultLastDate)
        ? payday
        : defaultLastDate;
    setState(() => _editingPayday = true);
    try {
      final picked = await showDatePicker(
        context: context,
        locale: const Locale('vi'),
        initialDate:
            payday ?? DateTime(today.year, today.month, today.day + 15),
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: 'Chọn ngày nhận lương',
        confirmText: 'Lưu',
        cancelText: 'Hủy',
      );
      if (picked == null || !mounted) return;

      final isoPayday = DateTime.utc(
        picked.year,
        picked.month,
        picked.day,
        12,
      ).toIso8601String();
      await ref
          .read(profileRemoteDataSourceProvider)
          .updateProfile(nextPayday: isoPayday);
      if (!mounted) return;

      await ref.read(homeProvider.notifier).loadDashboard(force: true);
      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        'Đã cập nhật ngày nhận lương: ${DateFormat('dd/MM/yyyy').format(picked)}',
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        'Không thể cập nhật ngày lương: ${error.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _editingPayday = false);
    }
  }

  String _greeting(DateTime now) {
    if (now.hour < 12) return 'Chào buổi sáng';
    if (now.hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.account_balance_wallet_outlined,
          size: 24,
          color: HomeStyle.primary,
        ),
        const SizedBox(width: 8),
        const Expanded(child: Text('Ví An', style: HomeStyle.heading)),
        IconButton(
          onPressed: () => context.go(AppConstants.notificationsRoute),
          tooltip: 'Thông báo',
          style: IconButton.styleFrom(
            minimumSize: const Size.square(44),
            backgroundColor: HomeStyle.iconBackground,
            foregroundColor: HomeStyle.primary,
          ),
          icon: const Icon(Icons.notifications_none_rounded, size: 21),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => context.go(AppConstants.settingsRoute),
          tooltip: 'Cài đặt',
          style: IconButton.styleFrom(
            minimumSize: const Size.square(44),
            backgroundColor: HomeStyle.primary,
            foregroundColor: Colors.white,
          ),
          icon: ExcludeSemantics(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: HomeLabelRow(
          leading: HomeIcon(icon),
          title: Text(title, style: HomeStyle.label),
          detail: detail == null
              ? null
              : Text(detail!, style: HomeStyle.detail),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (action != null)
                Flexible(
                  child: Text(
                    action!,
                    textAlign: TextAlign.end,
                    style: HomeStyle.label.copyWith(color: HomeStyle.primary),
                  ),
                ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: HomeStyle.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
