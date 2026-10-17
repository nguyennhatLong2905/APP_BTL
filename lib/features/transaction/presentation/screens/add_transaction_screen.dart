import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/domain/models/transaction.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/presentation/widgets/amount_input.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/presentation/widgets/category_grid.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/presentation/widgets/date_picker_field.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/presentation/widgets/photo_picker.dart';
import 'package:go_router/go_router.dart';

/// Màn hình Thêm Giao Dịch
/// 
/// Features:
/// - Tab selector: Thu / Chi
/// - Amount input với format VND
/// - Category picker (grid)
/// - Date picker
/// - Note input (optional)
/// - Photo attachment (optional)
/// - Form validation
/// - Save button
class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? initialType; // 'income' hoặc 'expense'

  const AddTransactionScreen({
    super.key,
    this.initialType,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _noteController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Set initial type nếu được truyền từ navigation
    if (widget.initialType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final type = widget.initialType == 'income'
            ? TransactionType.income
            : TransactionType.expense;
        ref.read(transactionFormProvider.notifier).setType(type);
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final notifier = ref.read(transactionFormProvider.notifier);
    await notifier.saveTransaction();

    final state = ref.read(transactionFormProvider);
    if (!mounted) return;

    if (state.isSuccess) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Đã lưu giao dịch thành công'),
            ],
          ),
          backgroundColor: Color(0xFF00A86B),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back
      context.pop();
    } else if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(state.error!)),
            ],
          ),
          backgroundColor: const Color(0xFFE71D36),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionFormProvider);
    final categories = ref.watch(currentCategoriesProvider);
    final notifier = ref.read(transactionFormProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Thêm giao dịch',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Tab Selector: Thu / Chi
                    _TypeSelector(
                      selectedType: state.type,
                      onTypeChanged: notifier.setType,
                    ),
                    const SizedBox(height: 20),

                    // Amount Input
                    AmountInput(
                      initialAmount: state.amount,
                      onChanged: notifier.setAmount,
                      accentColor: state.type == TransactionType.expense
                          ? const Color(0xFFE71D36)
                          : const Color(0xFF2EC4B6),
                    ),
                    const SizedBox(height: 16),

                    // Category Grid
                    CategoryGrid(
                      categories: categories,
                      selectedCategory: state.selectedCategory,
                      onCategorySelected: notifier.selectCategory,
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    DatePickerField(
                      selectedDate: state.selectedDate,
                      onDateChanged: notifier.setDate,
                    ),
                    const SizedBox(height: 16),

                    // Note Input
                    _NoteInput(
                      controller: _noteController,
                      onChanged: notifier.setNote,
                    ),
                    const SizedBox(height: 16),

                    // Photo Picker
                    PhotoPicker(
                      photoPath: state.photoPath,
                      onPhotoChanged: notifier.setPhoto,
                      onRemovePhoto: notifier.removePhoto,
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // Save Button (Fixed at bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: _SaveButton(
                  isValid: state.isValid,
                  isLoading: state.isLoading,
                  onPressed: _handleSave,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab selector để chọn Thu hoặc Chi
class _TypeSelector extends StatelessWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onTypeChanged;

  const _TypeSelector({
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeTab(
              label: 'Thu nhập',
              icon: Icons.add_circle_outline_rounded,
              isSelected: selectedType == TransactionType.income,
              color: const Color(0xFF2EC4B6),
              onTap: () => onTypeChanged(TransactionType.income),
            ),
          ),
          Expanded(
            child: _TypeTab(
              label: 'Chi tiêu',
              icon: Icons.remove_circle_outline_rounded,
              isSelected: selectedType == TransactionType.expense,
              color: const Color(0xFFE71D36),
              onTap: () => onTypeChanged(TransactionType.expense),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Note input field
class _NoteInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _NoteInput({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9F1C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.note_outlined,
                  color: Color(0xFFFF9F1C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ghi chú',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Text(
                'Tùy chọn',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú về giao dịch...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00A86B)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Save button
class _SaveButton extends StatelessWidget {
  final bool isValid;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.isValid,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isValid && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A86B),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Lưu giao dịch',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
