import 'package:flutter/material.dart';
import '../../../../core/widgets/currency_text_field.dart';
import '../../../../core/widgets/primary_button.dart';

class ItemInputForm extends StatefulWidget {
  final Function(String name, double price) onSubmit;

  const ItemInputForm({
    super.key,
    required this.onSubmit,
  });

  @override
  State<ItemInputForm> createState() => _ItemInputFormState();
}

class _ItemInputFormState extends State<ItemInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedCategory = 'Mua Sắm';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Mua Sắm', 'icon': Icons.shopping_bag, 'color': Colors.pink},
    {'name': 'Đồ Điện Tử', 'icon': Icons.devices, 'color': Colors.blue},
    {'name': 'Thời Trang', 'icon': Icons.checkroom, 'color': Colors.purple},
    {'name': 'Giải Trí', 'icon': Icons.sports_esports, 'color': Colors.orange},
    {'name': 'Khác', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _handleAnalyze() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final price = CurrencyTextField.getRawAmount(_priceController);
      widget.onSubmit(name, price);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shopping_cart_outlined, color: Color(0xFF00A86B)),
                  SizedBox(width: 8),
                  Text(
                    'Món Đồ Muốn Mua Sắm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên sản phẩm / Món đồ',
                  hintText: 'Ví dụ: Tai nghe bluetooth, Giày thể thao...',
                  prefixIcon: const Icon(Icons.edit_note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên món đồ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CurrencyTextField(
                controller: _priceController,
                labelText: 'Giá tiền dự kiến',
                hintText: '0 ₫',
                validator: (value) {
                  final amount =
                      CurrencyTextField.getRawAmount(_priceController);
                  if (amount <= 0) {
                    return 'Số tiền phải lớn hơn 0 ₫';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'Danh mục sản phẩm:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat['name'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        avatar: Icon(
                          cat['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : cat['color'] as Color,
                        ),
                        label: Text(cat['name'] as String),
                        selected: isSelected,
                        selectedColor: const Color(0xFF00A86B),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat['name'] as String;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Phân Tích Ngay',
                icon: Icons.analytics_outlined,
                backgroundColor: const Color(0xFF00A86B),
                onPressed: _handleAnalyze,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
