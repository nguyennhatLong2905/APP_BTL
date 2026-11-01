import 'package:flutter/material.dart';

class AddCategoryButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AddCategoryButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_circle_outline, size: 18),
        label: const Text(
          'Thêm danh mục ngân sách',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFE2F6F0),
          foregroundColor: const Color(0xFF0F5B47),
          side: const BorderSide(color: Color(0xFF80D8C3)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
