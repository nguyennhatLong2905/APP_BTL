import 'package:flutter/material.dart';

enum TransactionType {
  income,
  expense,
}

enum EmotionRating {
  worthIt, // Rất đáng tiền
  normal, // Bình thường
  considerAgain, // Cần cân nhắc
}

class TimelineItem {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final DateTime? dateTime;
  final String? emotionNote;
  final String? note;
  final EmotionRating? rating;
  final String? comment;
  final bool isSaved;
  final String dateText;
  final String paymentType;
  final IconData icon;
  final Color iconBgColor;

  const TimelineItem({
    required this.id,
    required this.title,
    required this.amount,
    this.type = TransactionType.expense,
    this.categoryName = 'Chi Tiêu',
    this.categoryIcon = Icons.category,
    this.categoryColor = Colors.teal,
    this.dateTime,
    this.emotionNote,
    this.note,
    this.rating,
    this.comment,
    this.isSaved = false,
    this.dateText = '',
    this.paymentType = 'Tiền mặt',
    this.icon = Icons.shopping_bag_outlined,
    this.iconBgColor = const Color(0xFFC2F0E6),
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  TimelineItem copyWith({
    EmotionRating? rating,
    String? comment,
    bool? isSaved,
  }) {
    return TimelineItem(
      id: id,
      title: title,
      amount: amount,
      type: type,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColor: categoryColor,
      dateTime: dateTime,
      emotionNote: emotionNote,
      note: note,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      isSaved: isSaved ?? this.isSaved,
      dateText: dateText,
      paymentType: paymentType,
      icon: icon,
      iconBgColor: iconBgColor,
    );
  }
}
