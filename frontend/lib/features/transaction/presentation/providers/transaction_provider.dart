import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/data/datasources/transaction_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/domain/models/transaction.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/domain/models/transaction_category.dart';

/// Exception khi chưa có ví
class WalletNotFoundException implements Exception {
  final String message;
  WalletNotFoundException(this.message);
  @override
  String toString() => message;
}

/// State cho Add Transaction Screen
class TransactionFormState {
  final TransactionType type;
  final double? amount;
  final TransactionCategory? selectedCategory;
  final String? selectedWalletId; // ID của ví được chọn
  final String? selectedWalletName; // Tên ví để hiển thị
  final String? selectedToWalletId; // Cho chuyển ví
  final String? selectedToWalletName; // Cho chuyển ví
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
    this.selectedWalletId,
    this.selectedWalletName,
    this.selectedToWalletId,
    this.selectedToWalletName,
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
    String? selectedWalletId,
    String? selectedWalletName,
    String? selectedToWalletId,
    String? selectedToWalletName,
    DateTime? selectedDate,
    String? note,
    String? photoPath,
    bool? isLoading,
    String? error,
    bool? isSuccess,
    bool clearCategory = false,
    bool clearPhoto = false,
    bool clearWallet = false,
    bool clearToWallet = false,
  }) {
    return TransactionFormState(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedWalletId: clearWallet ? null : (selectedWalletId ?? this.selectedWalletId),
      selectedWalletName: clearWallet ? null : (selectedWalletName ?? this.selectedWalletName),
      selectedToWalletId: clearToWallet ? null : (selectedToWalletId ?? this.selectedToWalletId),
      selectedToWalletName: clearToWallet ? null : (selectedToWalletName ?? this.selectedToWalletName),
      selectedDate: selectedDate ?? this.selectedDate,
      note: note ?? this.note,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  bool get isValid {
    if (type == TransactionType.transfer) {
      return amount != null && 
             amount! > 0 && 
             selectedWalletId != null &&
             selectedToWalletId != null;
    }
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
      clearWallet: false, // Giữ ví đã chọn
    );
  }

  /// Chọn ví nguồn
  void selectWallet(String walletId, String walletName) {
    state = state.copyWith(
      selectedWalletId: walletId,
      selectedWalletName: walletName,
    );
  }

  /// Chọn ví đích (cho chuyển ví)
  void selectToWallet(String walletId, String walletName) {
    state = state.copyWith(
      selectedToWalletId: walletId,
      selectedToWalletName: walletName,
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
      // 1. Khởi tạo datasource
      final ds = ref.read(transactionRemoteDataSourceProvider);
      
      // 2. Lấy danh sách ví và danh mục thực tế từ backend
      final wallets = await ds.getWallets();
      final categories = await ds.getCategories();
      
      if (wallets.isEmpty) {
        throw WalletNotFoundException('Bạn chưa có ví nào. Vui lòng tạo ví trước để ghi nhận giao dịch.');
      }
      
      // Dùng ví đã chọn, hoặc ví đầu tiên nếu chưa chọn
      final walletId = state.selectedWalletId ?? wallets.first['_id'] as String;

      if (state.type == TransactionType.transfer) {
        if (wallets.length < 2) {
          throw Exception('Cần ít nhất 2 ví để thực hiện chuyển ví');
        }
        
        // Dùng ví đã chọn cho chuyển tiền
        final fromWalletId = state.selectedWalletId ?? wallets[0]['_id'] as String;
        final toWalletId = state.selectedToWalletId ?? wallets[1]['_id'] as String;
        
        // Format datetime đúng theo backend regex: YYYY-MM-DDTHH:mm:ss.sssZ
        final occurredAtUtc = state.selectedDate.toUtc();
        final occurredAt = '${occurredAtUtc.year.toString().padLeft(4, '0')}-${occurredAtUtc.month.toString().padLeft(2, '0')}-${occurredAtUtc.day.toString().padLeft(2, '0')}T${occurredAtUtc.hour.toString().padLeft(2, '0')}:${occurredAtUtc.minute.toString().padLeft(2, '0')}:${occurredAtUtc.second.toString().padLeft(2, '0')}.${occurredAtUtc.millisecond.toString().padLeft(3, '0')}Z';
        
        await ds.createTransaction(
          type: 'transfer',
          amount: state.amount!.toInt().toString(), // Convert to string
          occurredAt: occurredAt,
          fromWalletId: fromWalletId,
          toWalletId: toWalletId,
          note: state.note,
        );
      } else {
        String categoryId = '';
        if (state.selectedCategory != null) {
          final matched = categories.firstWhere(
            (c) => c['name'] == state.selectedCategory!.name && c['kind'] == state.type.name,
            orElse: () => <String, dynamic>{},
          );
          if (matched.isNotEmpty && matched['_id'] != null) {
            categoryId = matched['_id'] as String;
          }
        }
        if (categoryId.isEmpty) {
          final matchingCats = categories.where((c) => c['kind'] == state.type.name).toList();
          if (matchingCats.isNotEmpty) {
            categoryId = matchingCats.first['_id'] as String;
          } else {
            throw Exception('Không tìm thấy danh mục phù hợp cho loại giao dịch này');
          }
        }

        // 3. Gửi request tạo giao dịch lên backend
        // Format datetime đúng theo backend regex: YYYY-MM-DDTHH:mm:ss.sssZ
        final occurredAtUtc = state.selectedDate.toUtc();
        final occurredAt = '${occurredAtUtc.year.toString().padLeft(4, '0')}-${occurredAtUtc.month.toString().padLeft(2, '0')}-${occurredAtUtc.day.toString().padLeft(2, '0')}T${occurredAtUtc.hour.toString().padLeft(2, '0')}:${occurredAtUtc.minute.toString().padLeft(2, '0')}:${occurredAtUtc.second.toString().padLeft(2, '0')}.${occurredAtUtc.millisecond.toString().padLeft(3, '0')}Z';
        
        await ds.createTransaction(
          type: state.type.name,
          amount: state.amount!.toInt().toString(), // Convert to string
          occurredAt: occurredAt,
          categoryId: categoryId,
          walletId: walletId,
          note: state.note,
        );
      }

      // Thành công
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
