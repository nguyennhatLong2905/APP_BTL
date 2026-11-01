import 'package:flutter/material.dart';
import '../../domain/models/budget_template.dart';

class TemplateSelector extends StatelessWidget {
  final ValueChanged<BudgetTemplate> onSelectTemplate;

  const TemplateSelector({
    super.key,
    required this.onSelectTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mẫu Phân Bổ Ngân Sách Nhanh',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: BudgetTemplate.defaultTemplates.length,
            itemBuilder: (context, index) {
              final template = BudgetTemplate.defaultTemplates[index];
              return InkWell(
                onTap: () => onSelectTemplate(template),
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.style_outlined,
                              size: 16, color: Color(0xFF00A86B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              template.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF00A86B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        template.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
