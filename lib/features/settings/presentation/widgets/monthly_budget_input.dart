import 'package:flutter/material.dart';
import '../../../../core/widgets/currency_text_field.dart';

class MonthlyBudgetInput extends StatefulWidget {
  final double currentMonthlyBudget;
  final ValueChanged<double> onBudgetChanged;

  const MonthlyBudgetInput({
    super.key,
    required this.currentMonthlyBudget,
    required this.onBudgetChanged,
  });

  @override
  State<MonthlyBudgetInput> createState() => _MonthlyBudgetInputState();
}

class _MonthlyBudgetInputState extends State<MonthlyBudgetInput> {
  late TextEditingController _controller;
  final String _selectedMonth = 'Tháng 10 / 2026';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showEditDialog() {
    _controller.text = widget.currentMonthlyBudget.toInt().toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Thiết Lập Ngân Sách Tháng'),
          content: CurrencyTextField(
            controller: _controller,
            labelText: 'Tổng ngân sách tháng',
            hintText: '0 ₫',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = CurrencyTextField.getRawAmount(_controller);
                if (amount > 0) {
                  widget.onBudgetChanged(amount);
                }
                Navigator.pop(context);
              },
              child: const Text('Cập nhật'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Color(0xFF00A86B), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _selectedMonth,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF00A86B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Text(
                    'Đang áp dụng',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF00A86B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A86B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Color(0xFF00A86B),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng Ngân Sách Tháng',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.currentMonthlyBudget.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00A86B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _showEditDialog,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Chỉnh sửa ngân sách',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
