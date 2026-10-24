import 'timeline_item.dart';

class TransactionGroup {
  final DateTime date;
  final List<TimelineItem> items;

  const TransactionGroup({
    required this.date,
    required this.items,
  });

  double get totalIncome => items
      .where((item) => item.isIncome)
      .fold(0, (sum, item) => sum + item.amount);

  double get totalExpense => items
      .where((item) => item.isExpense)
      .fold(0, (sum, item) => sum + item.amount);
}
