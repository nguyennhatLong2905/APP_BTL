import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Chỉ giữ chữ số trong lúc người dùng đang nhập.
///
/// Trước đây formatter chèn dấu chấm phân cách ngay khi gõ. Trên Flutter web,
/// việc này làm DOM value / caret / composing range của IME lệch dần so với
/// text của framework, dẫn tới assertion trong text_input.dart:
///   "Range end 8 is out of text of length 7"
/// (TextInputClient.updateEditingState với composingExtent vượt độ dài text).
///
/// Vì vậy: KHÔNG đổi hình thức text khi đang gõ, luôn xoá composing để IME
/// không giữ trạng thái cũ. Dấu phân cách chỉ thêm khi ô mất focus.
class CurrencyInputFormatter extends TextInputFormatter {
  /// Số chữ số tối đa (mặc định 15 để tránh tràn số)
  final int maxDigits;

  const CurrencyInputFormatter({this.maxDigits = 15});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > maxDigits
        ? digits.substring(0, maxDigits)
        : digits;

    // Trả về value luôn hợp lệ: selection nằm trong text, không có composing.
    return TextEditingValue(
      text: limited,
      selection: TextSelection.collapsed(offset: limited.length),
      composing: TextRange.empty,
    );
  }
}

/// Widget TextField nhập số tiền chuẩn cho ứng dụng Quản lý chi tiêu.
///
/// - Đang nhập: controller chứa chuỗi số thuần (an toàn với IME).
/// - Rời ô (blur): hiển thị dạng có dấu phân cách, ví dụ "1.500.000".
/// - Focus lại: trả về chuỗi số thuần để sửa.
class CurrencyTextField extends StatefulWidget {
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
    this.hintText = '0',
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  /// Hàm tiện ích lấy giá trị double nguyên bản từ controller
  static double getRawAmount(TextEditingController controller) {
    final cleanString = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleanString) ?? 0.0;
  }

  /// Định dạng số nguyên thành chuỗi có dấu chấm phân cách (vi_VN).
  static String formatAmount(num amount) {
    return NumberFormat.decimalPattern('vi_VN').format(amount.round());
  }

  @override
  State<CurrencyTextField> createState() => _CurrencyTextFieldState();
}

class _CurrencyTextFieldState extends State<CurrencyTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  /// Gán giá trị mới kèm selection hợp lệ và xoá composing.
  /// Không dùng controller.text = ... vì sẽ giữ selection/composing cũ.
  void _setText(String newText) {
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
      composing: TextRange.empty,
    );
  }

  void _onFocusChanged() {
    if (!mounted) return;

    final raw = CurrencyTextField.getRawAmount(widget.controller);
    final digits = widget.controller.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (_focusNode.hasFocus) {
      // Bắt đầu sửa: bỏ dấu phân cách để con trỏ không nhảy
      if (widget.controller.text != digits) {
        _setText(digits);
      }
    } else {
      // Rời ô: hiển thị có dấu phân cách
      if (raw > 0) {
        _setText(CurrencyTextField.formatAmount(raw));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      inputFormatters: const [CurrencyInputFormatter()],
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (text) {
        widget.onChanged?.call(CurrencyTextField.getRawAmount(widget.controller));
      },
      validator: widget.validator,
    );
  }
}
