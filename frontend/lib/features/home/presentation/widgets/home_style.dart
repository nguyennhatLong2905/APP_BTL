import 'package:flutter/material.dart';
import 'package:flutter_riverpod_clean_architecture/core/widgets/currency_text_field.dart';

abstract final class HomeStyle {
  static const primary = Color(0xFF115F52);
  static const ink = Color(0xFF173730);
  static const muted = Color(0xFF50665E);
  static const outline = Color(0xFFD2E1DA);
  static const iconBackground = Color(0xFFEDF3EF);
  static const reserved = Color(0xFFD8E8E0);
  static const spendable = Color(0xFF136F60);

  static const heading = TextStyle(
    color: ink,
    fontSize: 19,
    fontWeight: FontWeight.w700,
  );
  static const label = TextStyle(
    color: ink,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const detail = TextStyle(color: muted, fontSize: 12);

  static String money(
    double amount, {
    required bool visible,
    bool credit = false,
  }) {
    if (!visible) return '•••••';
    final sign = amount < 0 ? '−' : (credit && amount > 0 ? '+' : '');
    return '$sign${CurrencyTextField.formatAmount(amount.abs())} đ';
  }
}

/// Keeps the trailing value aligned while allowing both columns to wrap.
class HomeLabelRow extends StatelessWidget {
  const HomeLabelRow({
    super.key,
    required this.leading,
    required this.title,
    this.detail,
    this.trailing,
  });

  final Widget leading;
  final Widget title;
  final Widget? detail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                if (detail != null) ...[const SizedBox(height: 3), detail!],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * .45),
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}

class HomeIcon extends StatelessWidget {
  const HomeIcon(this.icon, {super.key, this.size = 34});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: HomeStyle.iconBackground,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, size: 20, color: HomeStyle.primary),
  );
}
