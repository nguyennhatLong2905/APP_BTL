import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/refresh_financial_data.dart';
import '../../../../core/widgets/currency_text_field.dart';
import '../../../settings/data/datasources/category_remote_data_source.dart';
import '../../data/datasources/attachment_remote_data_source.dart';
import '../../data/datasources/transaction_remote_data_source.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/receipt.dart';
import '../../data/receipt_parser.dart';
import '../../domain/models/transaction_category.dart';
import '../../providers/transaction_provider.dart';

class TransactionFormState {
  final TransactionType type;
  final int amount;
  final TransactionCategory? selectedCategory;
  final WalletItem? wallet;
  final WalletItem? toWallet;
  final DateTime selectedDate;
  final String note;
  final XFile? photo;
  final String merchant;
  final List<ReceiptLine> receiptLines;
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  TransactionFormState({
    this.type = TransactionType.expense,
    this.amount = 0,
    this.selectedCategory,
    this.wallet,
    this.toWallet,
    DateTime? selectedDate,
    this.note = '',
    this.photo,
    this.merchant = '',
    this.receiptLines = const [],
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  }) : selectedDate = selectedDate ?? DateTime.now();

  bool get isTransfer => type == TransactionType.transfer;

  bool get isValid => saveBlockReason == null;

  String? get saveBlockReason {
    if (amount <= 0) return 'Nhập số tiền lớn hơn 0 để lưu.';
    if (isTransfer) {
      if (wallet == null && toWallet == null)
        return 'Chọn ví gửi và ví nhận để lưu.';
      if (wallet == null) return 'Chọn ví gửi để lưu.';
      if (toWallet == null) return 'Chọn ví nhận để lưu.';
      if (wallet!.id == toWallet!.id)
        return 'Ví gửi và ví nhận phải khác nhau.';
      return null;
    }
    final walletLabel = type == TransactionType.income
        ? 'ví nhận tiền'
        : 'ví chi tiền';
    if (wallet == null && selectedCategory == null) {
      return 'Chọn $walletLabel và danh mục để lưu.';
    }
    if (wallet == null) return 'Chọn $walletLabel để lưu.';
    if (selectedCategory == null) return 'Chọn danh mục để lưu.';
    return null;
  }

  TransactionFormState copyWith({
    TransactionType? type,
    int? amount,
    TransactionCategory? selectedCategory,
    WalletItem? wallet,
    WalletItem? toWallet,
    DateTime? selectedDate,
    String? note,
    XFile? photo,
    String? merchant,
    List<ReceiptLine>? receiptLines,
    bool? isLoading,
    String? error,
    bool? isSuccess,
    bool clearCategory = false,
    bool clearPhoto = false,
  }) => TransactionFormState(
    type: type ?? this.type,
    amount: amount ?? this.amount,
    selectedCategory: clearCategory
        ? null
        : selectedCategory ?? this.selectedCategory,
    wallet: wallet ?? this.wallet,
    toWallet: toWallet ?? this.toWallet,
    selectedDate: selectedDate ?? this.selectedDate,
    note: note ?? this.note,
    photo: clearPhoto ? null : photo ?? this.photo,
    merchant: merchant ?? this.merchant,
    receiptLines: receiptLines ?? this.receiptLines,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    isSuccess: isSuccess ?? this.isSuccess,
  );
}

class TransactionFormNotifier extends Notifier<TransactionFormState> {
  // Khoảng số nguyên chính xác trên Flutter Web.
  static const _maxAmount = 9007199254740991;
  String? _uploadedPhotoId;
  String? _receiptKey;
  TransactionFormState? _sentReceipt;

  @override
  TransactionFormState build() => TransactionFormState();

  void setType(TransactionType type) {
    if (state.type == type) return;
    state = state.copyWith(type: type, clearCategory: true);
  }

  void selectWallet(WalletItem wallet, {bool destination = false}) {
    final other = destination ? state.wallet : state.toWallet;
    if (state.isTransfer && wallet.id == other?.id) {
      state = state.copyWith(error: 'Ví gửi và ví nhận phải khác nhau.');
      return;
    }
    state = destination
        ? state.copyWith(toWallet: wallet)
        : state.copyWith(wallet: wallet);
  }

  void appendDigits(int digits, {int placeValue = 10}) {
    if (state.amount > (_maxAmount - digits) ~/ placeValue) return;
    state = state.copyWith(amount: state.amount * placeValue + digits);
  }

  void deleteDigit() => state = state.copyWith(amount: state.amount ~/ 10);

  void addAmount(int amount) {
    if (amount > _maxAmount - state.amount) return;
    state = state.copyWith(amount: state.amount + amount);
  }

  void selectCategory(TransactionCategory category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setDate(DateTime date) => state = state.copyWith(selectedDate: date);
  void setNote(String note) => state = state.copyWith(note: note);

  void setPhoto(XFile? photo) {
    _uploadedPhotoId = null;
    state = state.copyWith(photo: photo, clearPhoto: photo == null);
  }

  void loadReceipt(ParsedReceipt receipt, XFile photo) {
    _uploadedPhotoId = null;
    // A retry keeps the same key even if the first response never arrived.
    _receiptKey = const Uuid().v4();
    _sentReceipt = null;
    state = TransactionFormState(
      amount: receipt.total ?? 0,
      selectedDate: receipt.date,
      merchant: receipt.merchant,
      receiptLines: List.unmodifiable(receipt.lines),
      photo: photo,
    );
  }

  void setReceiptAmount(int amount) => state = state.copyWith(amount: amount);
  void setMerchant(String merchant) =>
      state = state.copyWith(merchant: merchant);

  void setReceiptLines(List<ReceiptLine> lines) =>
      state = state.copyWith(receiptLines: List.unmodifiable(lines));

  bool _matchesSentReceipt(TransactionFormState draft) {
    final sent = _sentReceipt;
    return sent != null &&
        sent.amount == draft.amount &&
        sent.selectedDate == draft.selectedDate &&
        sent.wallet?.id == draft.wallet?.id &&
        sent.selectedCategory?.id == draft.selectedCategory?.id &&
        sent.note.trim() == draft.note.trim() &&
        sent.merchant == draft.merchant &&
        identical(sent.receiptLines, draft.receiptLines);
  }

  Future<void> saveTransaction() async {
    if (state.isLoading || state.isSuccess || !state.isValid) return;

    final draft = state;
    final keepAlive = ref.keepAlive();
    state = draft.copyWith(isLoading: true);
    try {
      final from = draft.wallet!;
      final to = draft.isTransfer ? draft.toWallet : null;
      for (final wallet in [from, ?to]) {
        final openingAt = wallet.openingAt;
        if (openingAt != null && draft.selectedDate.isBefore(openingAt)) {
          throw Exception(
            'Ngày giao dịch phải từ ${DateFormat('dd/MM/yyyy').format(openingAt)} '
            'trở đi đối với ví "${wallet.name}".',
          );
        }
      }

      final ds = ref.read(transactionRemoteDataSourceProvider);
      final categoryId = draft.isTransfer
          ? null
          : await _resolveCategory(draft);
      // A replay may already have reduced the remaining budget.
      if (draft.type == TransactionType.expense &&
          !_matchesSentReceipt(draft)) {
        await _assertBudgetAllowance(
          categoryId: categoryId!,
          amount: draft.amount,
          occurredAt: draft.selectedDate,
        );
      }

      final photo = draft.photo;
      if (photo != null && _uploadedPhotoId == null) {
        _uploadedPhotoId = await ref
            .read(attachmentRemoteDataSourceProvider)
            .uploadAttachment(photo);
      }
      final attachmentId = _uploadedPhotoId;
      if (_receiptKey != null) _sentReceipt = draft;
      await ds.createTransaction(
        type: draft.type.name,
        amount: draft.amount.toString(),
        occurredAt: draft.selectedDate.toUtc().toIso8601String(),
        walletId: draft.isTransfer ? null : from.id,
        fromWalletId: draft.isTransfer ? from.id : null,
        toWalletId: to?.id,
        categoryId: categoryId,
        note: draft.note.trim(),
        attachmentIds: attachmentId == null ? null : [attachmentId],
        merchant: draft.merchant.trim(),
        receiptLines: draft.receiptLines,
        idempotencyKey: _receiptKey,
      );
    } catch (e) {
      state = draft.copyWith(
        isLoading: false,
        error:
            'Không thể lưu giao dịch. ${e.toString().replaceFirst('Exception: ', '')}',
      );
      return;
    } finally {
      keepAlive.close();
    }

    state = draft.copyWith(isLoading: false, isSuccess: true);
    ref.read(transactionProvider.notifier).loadWallets();
    invalidateFinancialData(ref);
  }

  Future<String> _resolveCategory(TransactionFormState draft) async {
    final category = draft.selectedCategory!;
    final kind = draft.type.name;
    final name = category.name.trim().toLowerCase();
    final cached = ref
        .read(transactionProvider)
        .categories
        .where((item) => item.isActive && item.type == kind);
    final selected = cached.where((item) => item.id == category.id).firstOrNull;
    if (selected != null) return selected.id;

    // Danh mục gợi ý có thể chưa tồn tại trong tài khoản cũ.
    // Đọc lại danh sách trước khi tạo để dùng đúng ID hiện có.
    final ds = ref.read(categoryRemoteDataSourceProvider);
    final categories = await ds.getCategories();
    for (final item in categories.map(CategoryItem.fromJson)) {
      if (!item.isActive || item.type != kind) continue;
      if (item.id == category.id || item.name.trim().toLowerCase() == name) {
        return item.id;
      }
    }
    final suggestions = draft.type == TransactionType.expense
        ? DefaultCategories.expenseCategories
        : DefaultCategories.incomeCategories;
    if (!suggestions.any((item) => item.id == category.id)) {
      throw Exception('Danh mục đã chọn không còn khả dụng. Hãy chọn lại.');
    }
    final created = await ds.createCategory(name: category.name, kind: kind);
    final id = created['_id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Không tìm thấy danh mục vừa tạo.');
    }
    ref.read(transactionProvider.notifier).loadCategories();
    return id;
  }

  /// Kiểm tra hạn mức ngân sách trên client (backend vẫn kiểm tra lại).
  ///
  /// Chỉ áp dụng cho danh mục có hạn mức trong kỳ đang mở chứa ngày giao dịch;
  /// danh mục khác hoặc giao dịch thu nhập/chuyển ví không bị ảnh hưởng.
  Future<void> _assertBudgetAllowance({
    required String categoryId,
    required int amount,
    required DateTime occurredAt,
  }) async {
    final budgets = await ref
        .read(transactionRemoteDataSourceProvider)
        .getBudgets()
        .catchError((_) => <Map<String, dynamic>>[]);
    for (final plan in budgets) {
      final start = DateTime.tryParse(plan['startAt'] as String? ?? '');
      final end = DateTime.tryParse(plan['endAt'] as String? ?? '');
      if (start == null || end == null) continue;
      if (occurredAt.isBefore(start) || !occurredAt.isBefore(end)) continue;
      final limits = (plan['limits'] as List?) ?? const [];
      final line = limits.cast<Map<String, dynamic>>().firstWhere(
        (l) => l['categoryId']?.toString() == categoryId,
        orElse: () => <String, dynamic>{},
      );
      if (line.isEmpty) continue;
      final limit = double.tryParse(line['limit']?.toString() ?? '') ?? 0;
      final spent = double.tryParse(line['spent']?.toString() ?? '') ?? 0;
      final remaining = limit - spent;
      if (amount > remaining) {
        final name = line['categoryName']?.toString() ?? 'danh mục này';
        final over = amount - (remaining > 0 ? remaining : 0);
        throw Exception(
          remaining <= 0
              ? 'Danh mục "$name" đã hết hạn mức ngân sách trong kỳ này. '
                    'Tăng hạn mức trong Kế hoạch hoặc chọn danh mục khác.'
              : 'Khoản chi vượt hạn mức còn lại ${CurrencyTextField.formatAmount(remaining)} ₫ của danh mục '
                    '"$name" (vượt ${CurrencyTextField.formatAmount(over)} ₫). Tăng hạn mức hoặc chọn danh mục khác.',
        );
      }
    }
  }

  void reset() {
    _uploadedPhotoId = null;
    _receiptKey = null;
    _sentReceipt = null;
    state = TransactionFormState();
  }
}

final transactionFormProvider =
    NotifierProvider<TransactionFormNotifier, TransactionFormState>(
      TransactionFormNotifier.new,
    );

final receiptTransactionFormProvider =
    NotifierProvider.autoDispose<TransactionFormNotifier, TransactionFormState>(
      TransactionFormNotifier.new,
    );

final currentCategoriesProvider = Provider<List<TransactionCategory>>((ref) {
  final type = ref.watch(transactionFormProvider.select((form) => form.type));
  if (type == TransactionType.transfer) return const [];

  final isExpense = type == TransactionType.expense;
  final categories = ref
      .watch(transactionProvider.select((state) => state.categories))
      .where((item) => item.isActive && item.type == type.name)
      .toList();
  final defaults = isExpense
      ? DefaultCategories.expenseCategories
      : DefaultCategories.incomeCategories;
  final popular = defaults.take(5).toList();
  final usedIds = <String>{};
  final choices = [
    for (final suggestion in popular)
      _matchSuggestion(suggestion, categories, usedIds),
  ];
  return [
    ...choices,
    for (final item in categories)
      if (!usedIds.contains(item.id))
        TransactionCategory(
          id: item.id,
          name: item.name,
          icon: Icons.label_outline_rounded,
          color: Colors.transparent,
          type: isExpense
              ? TransactionCategoryType.expense
              : TransactionCategoryType.income,
        ),
  ];
});

TransactionCategory _matchSuggestion(
  TransactionCategory suggestion,
  List<CategoryItem> categories,
  Set<String> usedIds,
) {
  final match = categories
      .where(
        (item) =>
            item.name.trim().toLowerCase() == suggestion.name.toLowerCase(),
      )
      .firstOrNull;
  if (match == null) return suggestion;
  usedIds.add(match.id);
  return TransactionCategory(
    id: match.id,
    name: match.name,
    icon: suggestion.icon,
    color: suggestion.color,
    type: suggestion.type,
  );
}
