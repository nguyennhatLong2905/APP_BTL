/// Model cho một giao dịch (transaction)
class Transaction {
  final String id;
  final String title;
  final String category;
  final double amount; // Âm = chi tiêu, Dương = thu nhập
  final DateTime date;
  final String? note;
  final String? photoPath; // Đường dẫn ảnh hóa đơn (optional)
  final TransactionType type;

  const Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    this.photoPath,
    required this.type,
  });

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  Transaction copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    String? note,
    String? photoPath,
    TransactionType? type,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      photoPath: photoPath ?? this.photoPath,
      type: type ?? this.type,
    );
  }
}

/// Enum loại giao dịch
enum TransactionType {
  income,  // Thu nhập
  expense, // Chi tiêu
}
