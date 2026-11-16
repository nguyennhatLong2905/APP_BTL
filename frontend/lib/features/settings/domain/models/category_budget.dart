import 'package:flutter/material.dart';

class CategoryBudget {
  final String id;
  final String name;
  final IconData icon;
  final Color iconBgColor;
  final Color color;
  final double allocatedAmount;
  final double spentAmount;
  final String? warningMessage;

  /// Ngưỡng cảnh báo (%) của kỳ ngân sách — người dùng chọn, mặc định 80.
  final int warningPercent;

  /// Trạng thái khóa chi tiêu do backend tính: còn lại <= 0.
  final bool locked;
  final int? percent;

  const CategoryBudget({
    required this.id,
    required this.name,
    required this.icon,
    this.iconBgColor = const Color(0xFFE2F6F0),
    this.color = const Color(0xFF0F5B47),
    required this.allocatedAmount,
    required this.spentAmount,
    this.warningMessage,
    this.warningPercent = 80,
    this.locked = false,
    this.percent,
  });

  double get remainingAmount {
    final r = allocatedAmount - spentAmount;
    return r > 0 ? r : 0;
  }

  /// Số tiền đã vượt hạn mức (0 nếu chưa vượt).
  double get overAmount {
    final o = spentAmount - allocatedAmount;
    return o > 0 ? o : 0;
  }

  bool get isOverBudget => spentAmount > allocatedAmount;
  bool get isExhausted => allocatedAmount > 0 && spentAmount >= allocatedAmount;

  double get percentageSpent =>
      allocatedAmount > 0 ? (spentAmount / allocatedAmount) : 0;
  int get percentageInt =>
      percent ?? (percentageSpent * 100).toInt();

  /// Sắp chạm ngưỡng cảnh báo người dùng chọn.
  bool get isNearLimit =>
      allocatedAmount > 0 && percentageInt >= warningPercent && !isExhausted;

  /// Nhãn trạng thái hiển thị.
  String get statusLabel {
    if (isOverBudget) return 'Vượt hạn mức';
    if (isExhausted) return 'Hết hạn mức';
    if (isNearLimit) return 'Sắp hết';
    return 'Bình thường';
  }

  CategoryBudget copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? iconBgColor,
    Color? color,
    double? allocatedAmount,
    double? spentAmount,
    String? warningMessage,
    int? warningPercent,
    bool? locked,
    int? percent,
  }) {
    return CategoryBudget(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      iconBgColor: iconBgColor ?? this.iconBgColor,
      color: color ?? this.color,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      warningMessage: warningMessage ?? this.warningMessage,
      warningPercent: warningPercent ?? this.warningPercent,
      locked: locked ?? this.locked,
      percent: percent ?? this.percent,
    );
  }
}
