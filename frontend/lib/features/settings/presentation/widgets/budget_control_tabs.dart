import 'package:flutter/material.dart';

class BudgetControlTabs extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChanged;
  final String filterMode;
  final ValueChanged<String> onFilterModeChanged;

  const BudgetControlTabs({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.filterMode,
    required this.onFilterModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Row (Ngân sách, Mục tiêu, Hóa đơn)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFD3EFE8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _buildMainTab('Ngân sách', Icons.compass_calibration_outlined),
              _buildMainTab('Mục tiêu', Icons.savings_outlined),
              _buildMainTab('Hóa đơn', Icons.receipt_long_outlined),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Filter Mode Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildFilterChip('Chu kỳ lương'),
                const SizedBox(width: 8),
                _buildFilterChip('Theo tháng'),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.sync_alt, size: 14, color: Color(0xFF0F5B47)),
                const SizedBox(width: 4),
                Text(
                  'Thử xem bản trống',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainTab(String label, IconData icon) {
    final isSelected = activeTab == label;

    return Expanded(
      child: InkWell(
        onTap: () => onTabChanged(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: const Color(0xFF0F5B47), width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF0F5B47) : Colors.black87,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF0F5B47) : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = filterMode == label;

    return InkWell(
      onTap: () => onFilterModeChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F5B47) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
