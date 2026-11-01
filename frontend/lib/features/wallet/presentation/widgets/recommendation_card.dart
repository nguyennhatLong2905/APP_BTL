import 'package:flutter/material.dart';
import '../../domain/models/spending_decision.dart';

class RecommendationCard extends StatelessWidget {
  final SpendingDecision decision;

  const RecommendationCard({
    super.key,
    required this.decision,
  });

  @override
  Widget build(BuildContext context) {
    final isBuy = decision.isBuy;
    final cardColor = isBuy ? Colors.green.shade50 : Colors.red.shade50;
    final borderColor = isBuy ? Colors.green : Colors.red;
    final titleColor = isBuy ? Colors.green.shade800 : Colors.red.shade800;
    final icon = isBuy ? Icons.check_circle_rounded : Icons.pause_circle_rounded;
    final statusText = isBuy ? 'NÊN MUA NGAY' : 'NÊN CHỜ THÊM';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    Text(
                      'Sản phẩm: ${decision.itemName}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    decision.reason,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.3,
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
