import 'package:flutter/material.dart';

/// Model cho danh mục giao dịch
class TransactionCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionCategoryType type; // Thu hay chi

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });
}

/// Enum loại danh mục
enum TransactionCategoryType {
  income,  // Thu nhập
  expense, // Chi tiêu
  both,    // Cả hai
}

/// Danh sách categories mặc định
class DefaultCategories {
  // Categories cho Chi tiêu
  static const List<TransactionCategory> expenseCategories = [
    TransactionCategory(
      id: 'food',
      name: 'Ăn uống',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFF6B35),
      type: TransactionCategoryType.expense,
    ),
    TransactionCategory(
      id: 'transport',
      name: 'Di chuyển',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF6C63FF),
      type: TransactionCategoryType.expense,
    ),
    TransactionCategory(
      id: 'shopping',
      name: 'Mua sắm',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFFF9F1C),
      type: TransactionCategoryType.expense,
    ),
    TransactionCategory(
      id: 'health',
      name: 'Sức khỏe',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFFE71D36),
      type: TransactionCategoryType.expense,
    ),
    TransactionCategory(
      id: 'entertainment',
      name: 'Giải trí',
      icon: Icons.movie_rounded,
      color: Color(0xFF8B5CF6),
      type: TransactionCategoryType.expense,
    ),
    TransactionCategory(
      id: 'education',
      name: 'Giáo dục',
      icon: Icons.school_rounded,
      color: Color(0xFF3B82F6),
      type: TransactionCategoryType.expense,
    ),
    TransactionCategory(
      id: 'bills',
      name: 'Hóa đơn',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFEF4444),
      type: TransactionCategoryType.expense,
    ),
    TransactionCategory(
      id: 'other_expense',
      name: 'Khác',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF9CA3AF),
      type: TransactionCategoryType.expense,
    ),
  ];

  // Categories cho Thu nhập
  static const List<TransactionCategory> incomeCategories = [
    TransactionCategory(
      id: 'salary',
      name: 'Lương',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF2EC4B6),
      type: TransactionCategoryType.income,
    ),
    TransactionCategory(
      id: 'bonus',
      name: 'Thưởng',
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFF10B981),
      type: TransactionCategoryType.income,
    ),
    TransactionCategory(
      id: 'investment',
      name: 'Đầu tư',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF06B6D4),
      type: TransactionCategoryType.income,
    ),
    TransactionCategory(
      id: 'freelance',
      name: 'Tự do',
      icon: Icons.work_outline_rounded,
      color: Color(0xFF8B5CF6),
      type: TransactionCategoryType.income,
    ),
    TransactionCategory(
      id: 'gift',
      name: 'Quà tặng',
      icon: Icons.redeem_rounded,
      color: Color(0xFFF59E0B),
      type: TransactionCategoryType.income,
    ),
    TransactionCategory(
      id: 'other_income',
      name: 'Khác',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF9CA3AF),
      type: TransactionCategoryType.income,
    ),
  ];

  /// Lấy category theo type
  static List<TransactionCategory> getByType(TransactionCategoryType type) {
    switch (type) {
      case TransactionCategoryType.income:
        return incomeCategories;
      case TransactionCategoryType.expense:
        return expenseCategories;
      case TransactionCategoryType.both:
        return [...incomeCategories, ...expenseCategories];
    }
  }
}
