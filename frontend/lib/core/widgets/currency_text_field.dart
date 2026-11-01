import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Format số tiền tự động theo định dạng tiền tệ (Ví dụ: 100.000 ₫)
class CurrencyInputFormatter extends TextInputFormatter {
  final String locale;
  final String symbol;

  CurrencyInputFormatter({
    this.locale = 'vi_VN',
    this.symbol = '₫',
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Loại bỏ tất cả ký tự không phải số
    final cleanString = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanString.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final double value = double.parse(cleanString);
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 0,
    );

    final String newText = formatter.format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

/// Widget TextField nhập số tiền chuẩn cho ứng dụng Quản lý chi tiêu
class CurrencyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final ValueChanged<double>? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  const CurrencyTextField({
    super.key,
    required this.controller,
    this.labelText = 'Số tiền',
    this.hintText = '0 ₫',
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  /// Hàm tiện ích lấy giá trị double nguyên bản từ controller
  static double getRawAmount(TextEditingController controller) {
    final cleanString = controller.text.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleanString) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CurrencyInputFormatter(),
      ],
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (text) {
        if (onChanged != null) {
          onChanged!(getRawAmount(controller));
        }
      },
      validator: validator,
    );
  }
}
