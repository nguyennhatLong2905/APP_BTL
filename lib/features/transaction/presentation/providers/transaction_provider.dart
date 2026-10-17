import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/domain/models/transaction.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/domain/models/transaction_category.dart';

/// State cho Add Transaction Screen
class TransactionFormState {
  final TransactionType type;
  final double? amount;
  final TransactionCategory? selectedCategory;
  final DateTime selectedDate;
  final String? note;
  final String? photoPath;
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  TransactionFormState({
    this.type = TransactionType.expense,
    this.amount,
    this.selectedCategory,
    DateTime? selectedDate,
    this.note,
    this.photoPath,
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  }) : selectedDate = selectedDate ?? DateTime.now();

  TransactionFormState copyWith({
    TransactionType? type,
    double? amount,
    TransactionCategory? selectedCategory,
    DateTime? selectedDate,
    String? note,
    String? photoPath,
    bool? isLoading,
    String? error,
    bool? isSuccess,
    bool clearCategory = false,
    bool clearPhoto = false,
  }) {
    return TransactionFormState(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedDate: selectedDate ?? this.selectedDate,
      note: note ?? this.note,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  bool get isValid {
    return amount != null && 
           amount! > 0 && 
           selectedCategory != null;
  }
}

/// Notifier quản lý state Add Transaction Form
class TransactionFormNotifier extends Notifier<TransactionFormState> {
  @override
  TransactionFormState build() {
    return TransactionFormState(
      selectedDate: DateTime.now(),
    );
  }

  /// Chuyển đổi giữa Thu/Chi
  void setType(TransactionType type) {
    state = state.copyWith(
      type: type,
      clearCategory: true, // Reset category khi đổi type
    );
  }

  /// Cập nhật số tiền
  void setAmount(double? amount) {
    state = state.copyWith(amount: amount);
  }

  /// Chọn category
  void selectCategory(TransactionCategory category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Chọn ngày
  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  /// Cập nhật ghi chú
  void setNote(String? note) {
    state = state.copyWith(note: note);
  }

  /// Cập nhật ảnh
  void setPhoto(String? path) {
    state = state.copyWith(photoPath: path);
  }

  /// Xóa ảnh
  void removePhoto() {
    state = state.copyWith(clearPhoto: true);
  }

  /// Lưu giao dịch
  Future<void> saveTransaction() async {
    if (!state.isValid) {
      state = state.copyWith(
        error: 'Vui lòng nhập đủ thông tin',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Giả lập network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // TODO: Gọi API hoặc lưu vào local database
      // final transaction = Transaction(
      //   id: uuid.v4(),
      //   title: state.selectedCategory!.name,
      //   category: state.selectedCategory!.name,
      //   amount: state.type == TransactionType.expense 
      //       ? -state.amount! 
      //       : state.amount!,
      //   date: state.selectedDate,
      //   note: state.note,
      //   photoPath: state.photoPath,
      //   type: state.type,
      // );

      // Giả lập thành công
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể lưu giao dịch: ${e.toString()}',
      );
    }
  }

  /// Reset form
  void reset() {
    state = TransactionFormState(selectedDate: DateTime.now());
  }
}

/// Provider cho Transaction Form
final transactionFormProvider =
    NotifierProvider<TransactionFormNotifier, TransactionFormState>(
  TransactionFormNotifier.new,
);

/// Provider cho danh sách categories (dựa vào type hiện tại)
final currentCategoriesProvider = Provider<List<TransactionCategory>>((ref) {
  final type = ref.watch(transactionFormProvider).type;
  return type == TransactionType.expense
      ? DefaultCategories.expenseCategories
      : DefaultCategories.incomeCategories;
});
