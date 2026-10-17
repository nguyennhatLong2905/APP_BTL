import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget skeleton loading dùng chung cho Dashboard
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Row(
              children: [
                _circle(48),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: 80, height: 12),
                    const SizedBox(height: 6),
                    _box(width: 140, height: 16),
                  ],
                ),
                const Spacer(),
                _circle(40),
              ],
            ),
            const SizedBox(height: 24),

            // Balance card skeleton
            _box(width: double.infinity, height: 140),
            const SizedBox(height: 24),

            // Quick actions skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (_) => _actionSkeleton()),
            ),
            const SizedBox(height: 24),

            // Chart skeleton
            _box(width: double.infinity, height: 180),
            const SizedBox(height: 24),

            // Transactions skeleton
            _box(width: 140, height: 16),
            const SizedBox(height: 12),
            ...List.generate(5, (_) => _transactionSkeleton()),
          ],
        ),
      ),
    );
  }

  Widget _box({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _actionSkeleton() {
    return Column(
      children: [
        _circle(56),
        const SizedBox(height: 8),
        _box(width: 48, height: 10),
      ],
    );
  }

  Widget _transactionSkeleton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _circle(44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(width: 150, height: 12),
                const SizedBox(height: 6),
                _box(width: 80, height: 10),
              ],
            ),
          ),
          _box(width: 70, height: 14),
        ],
      ),
    );
  }
}
