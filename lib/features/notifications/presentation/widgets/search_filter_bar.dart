import 'package:flutter/material.dart';

class SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final List<String> categories;

  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm nhật ký giao dịch...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: selectedCategory == null,
                  onSelected: (_) => onCategoryChanged(null),
                  selectedColor: Colors.green.shade100,
                  checkmarkColor: const Color(0xFF00A86B),
                ),
                const SizedBox(width: 8),
                for (final cat in categories) ...[
                  FilterChip(
                    label: Text(cat),
                    selected: selectedCategory == cat,
                    onSelected: (selected) {
                      onCategoryChanged(selected ? cat : null);
                    },
                    selectedColor: Colors.green.shade100,
                    checkmarkColor: const Color(0xFF00A86B),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
