import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/presentation/widgets/bottom_nav_bar.dart';
import 'package:go_router/go_router.dart';

import '../providers/report_provider.dart';
import '../widgets/grouped_transaction_list.dart';

// ════════════════════════════════════════════════════════════════════
// Màn hình Lịch Sử Giao Dịch – "Sổ giao dịch" (theo thiết kế Figma)
// ════════════════════════════════════════════════════════════════════

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final TextEditingController _searchController = TextEditingController();

  // ── Màu sắc ─────────────────────────────────────────────────────
  static const Color _teal = Color(0xFF1A6B5A);
  static const Color _bg = Color(0xFFEFF9F6);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(reportProvider.notifier).setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ────────────────────────────────────────────
            _buildAppBar(context),

            // ── Scrollable Content ─────────────────────────────────
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: _buildPeriodRow()),
                  SliverToBoxAdapter(child: _buildWalletRow()),
                  SliverToBoxAdapter(child: _buildDivider()),
                  const SliverToBoxAdapter(child: GroupedTransactionList()),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ViAnBottomNavBar(currentIndex: 1),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // Brand
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VÍ AN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _teal,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Giao Dịch',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Notification icon
          GestureDetector(
            onTap: () => context.go(AppConstants.notificationsRoute),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 22,
                color: _textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Avatar
          GestureDetector(
            onTap: () => context.go(AppConstants.settingsRoute),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header "Sổ giao dịch" ────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + subtitle
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sổ giao dịch',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Quản lý dòng tiền an tâm & minh bạch',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Mẫu trống button
          GestureDetector(
            onTap: () {
              // TODO: Show mẫu trống
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD1EDE7)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_outlined, size: 14, color: _teal),
                  SizedBox(width: 4),
                  Text(
                    'Mẫu trống',
                    style: TextStyle(
                      fontSize: 12,
                      color: _teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ───────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.search_rounded,
                size: 20,
                color: _textSecondary,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14, color: _textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Tìm nội dung, số tiền...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFBDBDBD),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            // Clear button
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (_, value, child) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    ref.read(reportProvider.notifier).setSearchQuery('');
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: _textSecondary,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Period Row ───────────────────────────────────────────────────
  Widget _buildPeriodRow() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: const PeriodSelectorWidget(),
    );
  }

  // ── Wallet Row ───────────────────────────────────────────────────
  Widget _buildWalletRow() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: const WalletFilterWidget(),
    );
  }

  // ── Divider ──────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Container(
      height: 8,
      color: const Color(0xFFF5F5F5),
    );
  }
}
