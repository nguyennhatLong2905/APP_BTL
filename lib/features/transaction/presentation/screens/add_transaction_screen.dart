import 'package:flutter/material.dart';

/// TODO (Long): Implement Add Transaction Screen
/// - Tab Selector: Thu / Chi
/// - Amount Input: TextField số tiền (format tiền VND)
/// - Category Picker: Grid các category
/// - Date Picker: Chọn ngày giao dịch
/// - Note Input: TextField ghi chú (optional)
/// - Photo Attachment: Button chụp/chọn ảnh hóa đơn (optional)
/// - Save Button: Lưu giao dịch
class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm Giao Dịch')),
      body: const Center(
        child: Text('Add Transaction - TODO (Long)'),
      ),
    );
  }
}
