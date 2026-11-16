import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:go_router/go_router.dart';

class CreateWalletScreen extends ConsumerStatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  ConsumerState<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends ConsumerState<CreateWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Tiền mặt');
  final _balanceController = TextEditingController(text: '0');
  
  String _selectedType = 'cash';
  bool _isLoading = false;
  String? _errorMessage;

  /// Tên các ví đang hoạt động (chữ thường) để kiểm tra trùng ngay trên form.
  Set<String> _existingNames = {};

  final Map<String, String> _walletTypes = {
    'cash': '💵 Tiền mặt',
    'bank': '🏦 Ngân hàng',
    'ewallet': '💳 Ví điện tử',
    'savings': '🏛️ Tiết kiệm',
  };

  @override
  void initState() {
    super.initState();
    _loadExistingNames();
  }

  Future<void> _loadExistingNames() async {
    try {
      final wallets = await ref.read(walletRemoteDataSourceProvider).getWallets();
      if (!mounted) return;
      setState(() {
        _existingNames = wallets
            .where((w) => (w['status']?.toString() ?? 'active') == 'active')
            .map((w) => w['name']?.toString().trim().toLowerCase() ?? '')
            .where((n) => n.isNotEmpty)
            .toSet();
      });
    } catch (_) {
      // Không chặn màn tạo ví nếu tải danh sách lỗi; backend vẫn kiểm tra.
    }
  }

  /// Kiểm tra trùng tên (không phân biệt hoa/thường, bỏ khoảng trắng thừa).
  String? _validateName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Vui lòng nhập tên ví';
    if (_existingNames.contains(name.toLowerCase())) {
      return 'Bạn đã có ví tên "$name". Vui lòng chọn tên khác.';
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _createWallet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ds = ref.read(walletRemoteDataSourceProvider);

      // Kiểm tra trùng tên trước để báo ngay cho người dùng; backend vẫn là
      // nơi chặn cuối cùng (kể cả khi tạo từ màn khác).
      final existing = await ds.getWallets();
      final name = _nameController.text.trim();
      final duplicated = existing.any(
        (w) =>
            (w['status']?.toString() ?? 'active') == 'active' &&
            w['name']?.toString().trim().toLowerCase() == name.toLowerCase(),
      );
      if (duplicated) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Bạn đã có ví tên "$name". Vui lòng chọn tên khác.';
        });
        return;
      }

      // Format datetime cho backend
      final now = DateTime.now().toUtc();
      final openingAt = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}Z';
      
      await ds.createWallet(
        name: name,
        type: _selectedType,
        openingBalance: _balanceController.text.replaceAll('.', '').replaceAll(',', ''),
        openingAt: openingAt,
        // Không gửi color vì schema không cho phép additionalProperties
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Tạo ví "${_nameController.text}" thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return true để reload data
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Ví Mới'),
        backgroundColor: const Color(0xFF2D5F5D),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Intro
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tạo ví đầu tiên để bắt đầu ghi nhận giao dịch',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Tên ví
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên ví *',
                hintText: 'Ví dụ: Tiền mặt, Techcombank, MoMo',
                prefixIcon: const Icon(Icons.wallet),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: _validateName,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            
            const SizedBox(height: 16),
            
            // Loại ví
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: 'Loại ví *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _walletTypes.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Số dư ban đầu
            TextFormField(
              controller: _balanceController,
              decoration: InputDecoration(
                labelText: 'Số dư ban đầu (VND) *',
                hintText: '0',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: 'đ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Nhập số dư hiện tại của ví này',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số dư';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_errorMessage != null) const SizedBox(height: 16),
            
            // Nút tạo
            ElevatedButton(
              onPressed: _isLoading ? null : _createWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5F5D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Tạo Ví',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            
            const SizedBox(height: 12),
            
            // Nút bỏ qua (nếu cần)
            TextButton(
              onPressed: _isLoading ? null : () => context.pop(),
              child: const Text('Bỏ qua, tạo sau'),
            ),
          ],
        ),
      ),
    );
  }
}
