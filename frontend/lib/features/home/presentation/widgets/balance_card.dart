import 'package:flutter/material.dart';

import 'home_style.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.amount,
    required this.visible,
    required this.onToggle,
  });

  final double? amount;
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final value = amount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 4, 10, 16),
      decoration: BoxDecoration(
        color: HomeStyle.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Còn để chi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggle,
                tooltip: visible ? 'Ẩn số tiền' : 'Hiện số tiền',
                color: Colors.white,
                style: IconButton.styleFrom(minimumSize: const Size.square(44)),
                icon: Icon(
                  visible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              value == null ? '—' : HomeStyle.money(value, visible: visible),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                height: 1.12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
