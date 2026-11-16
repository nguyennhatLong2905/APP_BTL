import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod_clean_architecture/core/utils/refresh_financial_data.dart';
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

      // Chặn sớm trên client: ngày giao dịch phải >= openingAt của mọi ví liên quan
      // (backend trả 422 BEFORE_OPENING nếu vi phạm)
      List<Map<String, dynamic>> involvedWallets(List<String> ids) =>
          wallets.where((w) => ids.contains(w['_id'] as String)).toList();
      final involved = state.type == TransactionType.transfer
          ? involvedWallets([
              state.selectedWalletId ?? wallets[0]['_id'] as String,
              state.selectedToWalletId ?? wallets[1]['_id'] as String,
            ])
          : involvedWallets([walletId]);
      for (final w in involved) {
        final openingAtRaw = w['openingAt'];
        if (openingAtRaw != null) {
          final openingAt = DateTime.tryParse(openingAtRaw as String)?.toLocal();
          if (openingAt != null && state.selectedDate.isBefore(openingAt)) {
            throw Exception(
                'Ngày giao dịch (${DateFormat('dd/MM/yyyy').format(state.selectedDate)}) '
                'trước ngày bắt đầu theo dõi ví "${w['name']}" '
                '(${DateFormat('dd/MM/yyyy').format(openingAt)}). '
                'Hãy chọn ngày sau đó, hoặc tạo ví mới với ngày bắt đầu sớm hơn.');
          }
        }
      }

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
        
        // Chặn sớm trên client khi danh mục đã hết hạn mức ngân sách trong kỳ
        // bao phủ ngày giao dịch. Backend vẫn là nơi chặn cuối cùng và an toàn
        // khi có nhiều request đồng thời.
        await _assertBudgetAllowance(
          categoryId: categoryId,
          amount: state.amount!,
          occurredAt: state.selectedDate,
        );

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

      // Làm mới dữ liệu các màn hình khác: giao dịch vừa tạo phải xuất hiện
      // ngay ở Tổng quan, Giao dịch và Kế hoạch (số dư ví, tiến độ ngân sách).
      invalidateFinancialData(ref);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể lưu giao dịch: '
            '${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  /// Kiểm tra hạn mức ngân sách trên client (backend vẫn kiểm tra lại).
  ///
  /// Chỉ áp dụng cho danh mục có hạn mức trong kỳ đang mở chứa ngày giao dịch;
  /// danh mục khác hoặc giao dịch thu nhập/chuyển ví không bị ảnh hưởng.
  Future<void> _assertBudgetAllowance({
    required String categoryId,
    required double amount,
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
              : 'Khoản chi vượt hạn mức còn lại ${_vnd(remaining)} ₫ của danh mục '
                  '"$name" (vượt ${_vnd(over)} ₫). Tăng hạn mức hoặc chọn danh mục khác.',
        );
      }
    }
  }

  static String _vnd(double v) {
    final s = v.abs().toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
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
