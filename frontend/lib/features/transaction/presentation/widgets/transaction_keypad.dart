import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const transactionPrimary = Color(0xFF116452);
const transactionMint = Color(0xFFE8F4EE);
const transactionInk = Color(0xFF17372E);
const transactionMuted = Color(0xFF50635A);
const transactionBorder = Color(0xFFD5E2DB);

class TransactionKeypad extends StatelessWidget {
  const TransactionKeypad({
    super.key,
    required this.onKey,
    required this.enabled,
  });

  final ValueChanged<String> onKey;
  final bool enabled;

  static const keys = [
    ['1', '2', '3', '000'],
    ['4', '5', '6', '0'],
    ['7', '8', '9', 'Xóa'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in keys) ...[
          if (!identical(row, keys.first)) const SizedBox(height: 7),
          Row(
            children: [
              for (var index = 0; index < row.length; index++) ...[
                if (index > 0) const SizedBox(width: 6),
                Expanded(child: _buildKey(row[index])),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildKey(String label) {
    final isDelete = label == 'Xóa';
    final isFunction = label == '000' || isDelete;
    final foreground = isFunction ? transactionPrimary : transactionInk;
    final button = OutlinedButton(
      onPressed: enabled
          ? () {
              HapticFeedback.selectionClick();
              onKey(label);
            }
          : null,
      style: OutlinedButton.styleFrom(
        backgroundColor: isFunction ? transactionMint : Colors.white,
        foregroundColor: foreground,
        minimumSize: const Size(0, 54),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: const BorderSide(color: transactionBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        textStyle: TextStyle(
          fontSize: isFunction ? 20 : 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: isDelete
          ? const Icon(Icons.backspace_outlined, size: 22)
          : Text(label),
    );
    return isDelete
        ? Semantics(
            label: label,
            button: true,
            child: Tooltip(
              message: label,
              excludeFromSemantics: true,
              child: button,
            ),
          )
        : button;
  }
}
