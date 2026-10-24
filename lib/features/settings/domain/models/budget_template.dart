class BudgetTemplate {
  final String id;
  final String name;
  final String description;

  /// Tỷ lệ phân bổ theo phần trăm cho từng danh mục
  /// key: id danh mục, value: tỷ lệ (VD: 0.35 cho 35%)
  final Map<String, double> categoryRatios;

  const BudgetTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryRatios,
  });

  static const List<BudgetTemplate> defaultTemplates = [
    BudgetTemplate(
      id: 'savings',
      name: 'Tiết Kiệm (50/30/20)',
      description: 'Dành 50% nhu cầu thiết yếu, 30% sở thích, 20% tiết kiệm.',
      categoryRatios: {
        'food': 0.30,
        'transport': 0.15,
        'bills': 0.20,
        'entertainment': 0.15,
        'shopping': 0.10,
        'others': 0.10,
      },
    ),
    BudgetTemplate(
      id: 'balanced',
      name: 'Trung Bình Cân Bằng',
      description: 'Phân bổ đồng đều giữa ăn uống, sinh hoạt và giải trí.',
      categoryRatios: {
        'food': 0.35,
        'transport': 0.15,
        'bills': 0.25,
        'entertainment': 0.10,
        'shopping': 0.10,
        'others': 0.05,
      },
    ),
    BudgetTemplate(
      id: 'flexible',
      name: 'Thoải Mái Sinh Hoạt',
      description: 'Tập trung nhiều hơn cho giải trí và trải nghiệm cá nhân.',
      categoryRatios: {
        'food': 0.35,
        'transport': 0.15,
        'bills': 0.15,
        'entertainment': 0.20,
        'shopping': 0.10,
        'others': 0.05,
      },
    ),
  ];
}
