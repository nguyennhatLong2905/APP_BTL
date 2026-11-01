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

  const CategoryBudget({
    required this.id,
    required this.name,
    required this.icon,
    this.iconBgColor = const Color(0xFFE2F6F0),
    this.color = const Color(0xFF0F5B47),
    required this.allocatedAmount,
    required this.spentAmount,
    this.warningMessage,
  });

  double get remainingAmount => allocatedAmount - spentAmount;
  double get percentageSpent =>
      allocatedAmount > 0 ? (spentAmount / allocatedAmount) : 0;
  int get percentageInt => (percentageSpent * 100).toInt();

  bool get isOverBudget => spentAmount > allocatedAmount;
  bool get isNearLimit => percentageSpent >= 0.8;

  CategoryBudget copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? iconBgColor,
    Color? color,
    double? allocatedAmount,
    double? spentAmount,
    String? warningMessage,
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
    );
  }
}
