import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/presentation/widgets/logo_widget.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  static const _primaryColor = Color(0xFF0F5B47);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showError('Vui lòng đồng ý với Điều khoản sử dụng');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    // Mock register: tạo account ngay lập tức thành công
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    ref.read(authProvider.notifier).loginWithMock(_usernameController.text.trim());
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated && mounted) {
        context.go(AppConstants.homeRoute);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // ── Header: Back + Logo ───────────────────────────────
                  _buildHeader(context),

                  const SizedBox(height: 32),

                  // ── Tiêu đề ──────────────────────────────────────────
                  const Text(
                    'Tạo tài khoản mới',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _primaryColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bắt đầu hành trình tiêu dùng thông minh',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Form ─────────────────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          id: 'register_name_field',
                          controller: _nameController,
                          label: 'Họ và tên',
                          hint: 'Nhập họ và tên của bạn',
                          icon: Icons.badge_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Vui lòng nhập họ tên'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          id: 'register_username_field',
                          controller: _usernameController,
                          label: 'Tên đăng nhập',
                          hint: 'Chọn tên đăng nhập',
                          icon: Icons.person_outline_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Vui lòng nhập tên đăng nhập';
                            }
                            if (v.trim().length < 3) {
                              return 'Tên đăng nhập tối thiểu 3 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildPasswordField(
                          id: 'register_password_field',
                          controller: _passwordController,
                          label: 'Mật khẩu',
                          hint: 'Tạo mật khẩu',
                          obscure: _obscurePassword,
                          onToggle: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            if (v.length < 3) {
                              return 'Mật khẩu tối thiểu 3 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildPasswordField(
                          id: 'register_confirm_field',
                          controller: _confirmController,
                          label: 'Xác nhận mật khẩu',
                          hint: 'Nhập lại mật khẩu',
                          obscure: _obscureConfirm,
                          onToggle: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return 'Mật khẩu xác nhận không khớp';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Checkbox điều khoản ───────────────────────────────
                  _buildTermsCheckbox(),

                  const SizedBox(height: 24),

                  // ── Nút đăng ký ──────────────────────────────────────
                  _buildRegisterButton(),

                  const SizedBox(height: 28),

                  // ── Link đăng nhập ───────────────────────────────────
                  _buildLoginLink(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Back button
        InkWell(
          onTap: () => context.go(AppConstants.loginRoute),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: _primaryColor),
          ),
        ),
        const SizedBox(width: 14),
        // Mini logo
        const ViAnLogoIcon(size: 36),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ví An',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _primaryColor,
              ),
            ),
            Text(
              'Tiêu dùng thông minh',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String id,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: Key(id),
          controller: controller,
          validator: validator,
          style: const TextStyle(fontSize: 15),
          decoration: _inputDecoration(hint: hint, prefixIcon: icon),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String id,
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: Key(id),
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: const TextStyle(fontSize: 15),
          decoration: _inputDecoration(
            hint: hint,
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey.shade500,
                size: 20,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: Colors.grey.shade500, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7FAF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryColor, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD32F2F)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.8),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            key: const Key('register_terms_checkbox'),
            value: _agreedToTerms,
            activeColor: _primaryColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5)),
            side: BorderSide(color: Colors.grey.shade400),
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade700, height: 1.4),
              children: const [
                TextSpan(text: 'Tôi đồng ý với '),
                TextSpan(
                  text: 'Điều khoản sử dụng',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' và '),
                TextSpan(
                  text: 'Chính sách bảo mật',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' của Ví An'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        key: const Key('register_submit_button'),
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryColor.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Tạo tài khoản',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        GestureDetector(
          onTap: () => context.go(AppConstants.loginRoute),
          child: const Text(
            'Đăng nhập',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
