import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod_clean_architecture/core/utils/refresh_financial_data.dart';
import 'package:flutter_riverpod_clean_architecture/features/settings/data/datasources/category_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/data/datasources/transaction_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/domain/models/transaction.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/domain/models/transaction_category.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/providers/transaction_provider.dart';

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
      // Đọc wallets/categories từ transactionProvider đã cache — không gọi API thêm
      final txState = ref.read(transactionProvider);
      final wallets = txState.wallets.map((w) => <String, dynamic>{
        '_id': w.id,
        'name': w.name,
        'openingAt': null, // openingAt không có trong WalletItem; giữ null, backend kiểm tra
      }).toList();
      final categories = txState.categories.map((c) => <String, dynamic>{
        '_id': c.id,
        'name': c.name,
        'kind': c.type,
      }).toList();

      // Nếu chưa có dữ liệu trong cache, fallback gọi API một lần
      final ds = ref.read(transactionRemoteDataSourceProvider);
      final List<Map<String, dynamic>> resolvedWallets;
      final List<Map<String, dynamic>> resolvedCategories;
      if (wallets.isEmpty) {
        resolvedWallets = await ds.getWallets();
        resolvedCategories = await ds.getCategories();
      } else {
        resolvedWallets = wallets;
        resolvedCategories = categories;
      }

      if (resolvedWallets.isEmpty) {
        throw WalletNotFoundException('Bạn chưa có ví nào. Vui lòng tạo ví trước để ghi nhận giao dịch.');
      }

      // Dùng ví đã chọn, hoặc ví đầu tiên nếu chưa chọn
      final walletId = state.selectedWalletId ?? resolvedWallets.first['_id'] as String;

      // Chặn sớm trên client: ngày giao dịch phải >= openingAt của mọi ví liên quan
      List<Map<String, dynamic>> involvedWallets(List<String> ids) =>
          resolvedWallets.where((w) => ids.contains(w['_id'] as String)).toList();
      final involved = state.type == TransactionType.transfer
          ? involvedWallets([
              state.selectedWalletId ?? resolvedWallets[0]['_id'] as String,
              state.selectedToWalletId ?? resolvedWallets[1]['_id'] as String,
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
        if (resolvedWallets.length < 2) {
          throw Exception('Cần ít nhất 2 ví để thực hiện chuyển ví');
        }

        final fromWalletId = state.selectedWalletId ?? resolvedWallets[0]['_id'] as String;
        final toWalletId = state.selectedToWalletId ?? resolvedWallets[1]['_id'] as String;

        final occurredAtUtc = state.selectedDate.toUtc();
        final occurredAt = '${occurredAtUtc.year.toString().padLeft(4, '0')}-${occurredAtUtc.month.toString().padLeft(2, '0')}-${occurredAtUtc.day.toString().padLeft(2, '0')}T${occurredAtUtc.hour.toString().padLeft(2, '0')}:${occurredAtUtc.minute.toString().padLeft(2, '0')}:${occurredAtUtc.second.toString().padLeft(2, '0')}.${occurredAtUtc.millisecond.toString().padLeft(3, '0')}Z';

        await ds.createTransaction(
          type: 'transfer',
          amount: state.amount!.toInt().toString(),
          occurredAt: occurredAt,
          fromWalletId: fromWalletId,
          toWalletId: toWalletId,
          note: state.note,
        );
      } else {
        String categoryId = '';
        final kind = state.type.name; // 'expense' | 'income'
        final catDs = ref.read(categoryRemoteDataSourceProvider);

        if (state.selectedCategory != null) {
          final selName = state.selectedCategory!.name.toLowerCase().trim();
          // 1. Khớp chính xác tên và loại thu/chi
          final exactMatch = resolvedCategories.firstWhere(
            (c) =>
                c['name']?.toString().toLowerCase().trim() == selName &&
                c['kind']?.toString() == kind,
            orElse: () => <String, dynamic>{},
          );
          if (exactMatch.isNotEmpty && exactMatch['_id'] != null) {
            categoryId = exactMatch['_id'].toString();
          } else {
            // 2. Khớp gần đúng theo tên (ví dụ: "Mua sắm" khớp "Mua sắm cá nhân")
            final partialMatch = resolvedCategories.firstWhere(
              (c) {
                if (c['kind']?.toString() != kind) return false;
                final cName = c['name']?.toString().toLowerCase().trim() ?? '';
                return cName.contains(selName) || selName.contains(cName);
              },
              orElse: () => <String, dynamic>{},
            );
            if (partialMatch.isNotEmpty && partialMatch['_id'] != null) {
              categoryId = partialMatch['_id'].toString();
            } else {
              // 3. Tự động tạo danh mục trên DB nếu chưa có
              try {
                final newCat = await catDs.createCategory(
                  name: state.selectedCategory!.name,
                  kind: kind,
                );
                categoryId = newCat['_id']?.toString() ?? '';
                // Làm mới danh sách danh mục trong cache ngầm
                ref.read(transactionProvider.notifier).loadCategories();
              } catch (_) {}
            }
          }
        }

        // Nếu chưa tìm thấy categoryId, fallback tìm bất kỳ danh mục nào cùng kind
        if (categoryId.isEmpty) {
          final matchingCats = resolvedCategories
              .where((c) => c['kind']?.toString() == kind)
              .toList();
          if (matchingCats.isNotEmpty) {
            categoryId = matchingCats.first['_id']?.toString() ?? '';
          } else {
            // Tự tạo danh mục mặc định cho kind này nếu DB chưa có
            try {
              final defaultName =
                  state.type == TransactionType.income ? 'Thu nhập' : 'Khác';
              final newCat = await catDs.createCategory(
                name: defaultName,
                kind: kind,
              );
              categoryId = newCat['_id']?.toString() ?? '';
              ref.read(transactionProvider.notifier).loadCategories();
            } catch (_) {}
          }
        }

        if (categoryId.isEmpty) {
          throw Exception('Không tìm thấy danh mục phù hợp cho loại giao dịch này');
        }

        final occurredAtUtc = state.selectedDate.toUtc();
        final occurredAt = '${occurredAtUtc.year.toString().padLeft(4, '0')}-${occurredAtUtc.month.toString().padLeft(2, '0')}-${occurredAtUtc.day.toString().padLeft(2, '0')}T${occurredAtUtc.hour.toString().padLeft(2, '0')}:${occurredAtUtc.minute.toString().padLeft(2, '0')}:${occurredAtUtc.second.toString().padLeft(2, '0')}.${occurredAtUtc.millisecond.toString().padLeft(3, '0')}Z';

        // Chỉ kiểm tra hạn mức ngân sách đối với giao dịch Chi tiêu (Expense)
        if (state.type == TransactionType.expense) {
          await _assertBudgetAllowance(
            categoryId: categoryId,
            amount: state.amount!,
            occurredAt: state.selectedDate,
          );
        }

        await ds.createTransaction(
          type: state.type.name,
          amount: state.amount!.toInt().toString(),
          occurredAt: occurredAt,
          categoryId: categoryId,
          walletId: walletId,
          note: state.note,
        );
      }

      // Thành công
      state = state.copyWith(isLoading: false, isSuccess: true);

      // Làm mới chính xác: chỉ những provider bị ảnh hưởng bởi giao dịch này.
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
