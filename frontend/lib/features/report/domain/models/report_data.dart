import '../../../transaction/domain/models/receipt.dart';

// ════════════════════════════════════════════════════════════════════
// Domain Models – Lịch Sử Giao Dịch & Báo Cáo
// ════════════════════════════════════════════════════════════════════

enum TransactionType { income, expense, transfer }

enum WalletType { all, cash, bank, category }

enum PeriodFilter { month, week, today }

class ReportTransaction {
  final String id;
  final String title;
  final String category;
  final String categoryIcon; // emoji hoặc icon name
  final double amount;
  final DateTime dateTime;
  final TransactionType type;
  final String walletLabel; // "Ví tiền mặt", "Tài khoản thanh toán"...
  final String typeLabel; // "Chi tiêu", "Thu nhập", "Chuyển tiền"

  // Dữ liệu cần cho sửa / hủy giao dịch
  final String walletId;
  final String categoryId;
  final String note;
  final int version;
  final bool isVoided;
  final List<String> attachmentIds;
  final String merchant;
  final List<ReceiptLine> receiptLines;

  const ReportTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryIcon,
    required this.amount,
    required this.dateTime,
    required this.type,
    required this.walletLabel,
    required this.typeLabel,
    this.walletId = '',
    this.categoryId = '',
    this.note = '',
    this.version = 0,
    this.isVoided = false,
    this.attachmentIds = const [],
    this.merchant = '',
    this.receiptLines = const [],
  });

  /// Có thể sửa/hủy khi là giao dịch thủ công chưa bị hủy
  bool get canModify => !isVoided && id.isNotEmpty;

  ReportTransaction copyWith({
    String? title,
    double? amount,
    DateTime? dateTime,
  }) {
    return ReportTransaction(
      id: id,
      title: title ?? this.title,
      category: category,
      categoryIcon: categoryIcon,
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      type: type,
      walletLabel: walletLabel,
      typeLabel: typeLabel,
      walletId: walletId,
      categoryId: categoryId,
      note: note,
      version: version,
      isVoided: isVoided,
      attachmentIds: attachmentIds,
      merchant: merchant,
      receiptLines: receiptLines,
    );
  }
}

class DailyGroup {
  final DateTime date;
  final List<ReportTransaction> transactions;

  const DailyGroup({required this.date, required this.transactions});

  /// Tổng thu trong ngày
  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount.abs());

  /// Tổng chi trong ngày
  double get totalExpense => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount.abs());

  /// Dòng tiền ròng (thu - chi)
  double get netFlow => totalIncome - totalExpense;
}

class ReportSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;

  const ReportSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });
}
