import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/forgot_password_provider.dart';
import '../widgets/logo_widget.dart';

class _OtpDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    final digitsBuffer = StringBuffer();
    int targetSelection = 0;
    final selectionEnd = newValue.selection.extentOffset;

    for (var i = 0; i < raw.length; i++) {
      final code = raw.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        if (digitsBuffer.length < 6) {
          digitsBuffer.writeCharCode(code);
          if (i < selectionEnd) {
            targetSelection = digitsBuffer.length;
          }
        }
      }
    }

    final formatted = digitsBuffer.toString();
    final clampedOffset =
        targetSelection.clamp(0, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: clampedOffset),
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  static const _primaryColor = Color(0xFF0F5B47);

  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpFocusNode = FocusNode();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.initialEmail?.trim() ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _navigateBackToLogin([String? updatedEmail]) {
    if (context.canPop()) {
      context.pop(updatedEmail);
    } else {
      context.go(AppConstants.loginRoute);
    }
  }

  void _focusOtpField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _otpFocusNode.canRequestFocus) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  Future<void> _submitEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await ref
        .read(forgotPasswordProvider.notifier)
        .sendOtp(_emailController.text.trim());
    if (!mounted) return;

    final state = ref.read(forgotPasswordProvider);
    if (ok) {
      _otpController.clear();
      _focusOtpField();
      final msg = state.deliveryChannel == 'console'
          ? 'Đã tạo mã OTP (chế độ dev: xem mã tại console backend).'
          : 'Mã OTP đã được gửi đến ${state.email}.';
      AppSnackBar.showSuccess(context, msg);
    } else if (state.errorMessage != null) {
      AppSnackBar.showError(context, state.errorMessage!);
    }
  }

  Future<void> _resendOtp() async {
    FocusScope.of(context).unfocus();
    final ok = await ref.read(forgotPasswordProvider.notifier).resendOtp();
    if (!mounted) return;

    final state = ref.read(forgotPasswordProvider);
    if (ok) {
      _otpController.clear();
      _focusOtpField();
      final msg = state.deliveryChannel == 'console'
          ? 'Đã tạo lại mã OTP (chế độ dev: xem mã tại console backend).'
          : 'Đã gửi lại mã OTP đến ${state.email}.';
      AppSnackBar.showSuccess(context, msg);
    } else if (state.errorMessage != null) {
      AppSnackBar.showError(context, state.errorMessage!);
    }
  }

  Future<void> _submitOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await ref
        .read(forgotPasswordProvider.notifier)
        .verifyOtp(_otpController.text.trim());
    if (!mounted) return;

    if (ok) {
      AppSnackBar.showSuccess(
        context,
        'Xác minh OTP thành công. Hãy nhập mật khẩu mới.',
      );
    } else {
      final error = ref.read(forgotPasswordProvider).errorMessage;
      if (error != null) {
        AppSnackBar.showError(context, error);
      }
    }
  }

  Future<void> _submitNewPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final state = ref.read(forgotPasswordProvider);
    final ok = await ref
        .read(forgotPasswordProvider.notifier)
        .resetPassword(_newPasswordController.text);
    if (!mounted) return;

    if (ok) {
      AppSnackBar.showSuccess(
        context,
        'Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.',
      );
      _navigateBackToLogin(state.email);
    } else {
      final error = ref.read(forgotPasswordProvider).errorMessage;
      if (error != null) {
        AppSnackBar.showError(context, error);
      }
    }
  }

  void _handleBack(ForgotPasswordStep step, bool isLoading) {
    if (isLoading) return;
    if (step == ForgotPasswordStep.otp) {
      _otpController.clear();
      ref.read(forgotPasswordProvider.notifier).goBackToEmail();
      return;
    }
    _navigateBackToLogin();
  }

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(
      forgotPasswordProvider.select(
        (s) => (
          step: s.step,
          isLoading: s.isLoading,
          email: s.email,
          deliveryChannel: s.deliveryChannel,
          otpExpiresInSeconds: s.otpExpiresInSeconds,
        ),
      ),
    );

    return PopScope(
      canPop:
          viewState.step != ForgotPasswordStep.otp && !viewState.isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop &&
            viewState.step == ForgotPasswordStep.otp &&
            !viewState.isLoading) {
          _otpController.clear();
          ref.read(forgotPasswordProvider.notifier).goBackToEmail();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildHeader(viewState.step, viewState.isLoading),
                const SizedBox(height: 28),
                _buildStepIndicator(viewState.step),
                const SizedBox(height: 28),
                if (viewState.step == ForgotPasswordStep.email)
                  _buildEmailStep(isLoading: viewState.isLoading)
                else if (viewState.step == ForgotPasswordStep.otp)
                  _buildOtpStep(
                    email: viewState.email,
                    deliveryChannel: viewState.deliveryChannel,
                    otpExpiresInSeconds: viewState.otpExpiresInSeconds,
                    isLoading: viewState.isLoading,
                  )
                else
                  _buildNewPasswordStep(
                    email: viewState.email,
                    isLoading: viewState.isLoading,
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ForgotPasswordStep step, bool isLoading) {
    return Row(
      children: [
        InkWell(
          onTap: () => _handleBack(step, isLoading),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: _primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 14),
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
              'Khôi phục mật khẩu',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIndicator(ForgotPasswordStep currentStep) {
    final currentIdx = currentStep.index;
    const labels = ['1. Email', '2. Mã OTP', '3. Mật khẩu mới'];

    return Row(
      children: List.generate(labels.length, (i) {
        final isDone = i < currentIdx;
        final isActive = i == currentIdx;
        final bgColor = isActive
            ? _primaryColor
            : isDone
                ? const Color(0xFFEAF8F5)
                : const Color(0xFFF3F4F6);
        final textColor = isActive
            ? Colors.white
            : isDone
                ? _primaryColor
                : Colors.grey.shade500;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: isDone
                  ? Border.all(color: const Color(0xFFC2E8DF))
                  : null,
            ),
            child: Text(
              labels[i],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmailStep({required bool isLoading}) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quên mật khẩu?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _primaryColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập địa chỉ email đã đăng ký tài khoản Ví An. Chúng tôi sẽ gửi mã OTP gồm 6 chữ số qua email để xác minh.',
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('forgot_email_field'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => isLoading ? null : _submitEmail(),
            enabled: !isLoading,
            validator: (v) {
              final email = v?.trim() ?? '';
              if (email.isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!AppUtils.isValidEmail(email)) {
                return 'Email không hợp lệ (vd: ten@gmail.com)';
              }
              return null;
            },
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecoration(
              hint: 'Nhập địa chỉ email',
              prefixIcon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: 28),
          _buildPrimaryButton(
            key: const Key('forgot_send_otp_button'),
            label: 'Gửi mã OTP',
            isLoading: isLoading,
            onPressed: _submitEmail,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep({
    required String email,
    required String deliveryChannel,
    required int otpExpiresInSeconds,
    required bool isLoading,
  }) {
    final validMinutes = (otpExpiresInSeconds / 60).ceil();

    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xác minh mã OTP',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _primaryColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'Nhập mã 6 chữ số đã được gửi tới '),
                TextSpan(
                  text: email,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                TextSpan(text: '. Mã có hiệu lực trong $validMinutes phút.'),
              ],
            ),
          ),
          if (deliveryChannel == 'console') ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC2E8DF)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.terminal_rounded, color: _primaryColor, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Chế độ dev (chưa cấu hình SMTP): vui lòng xem mã OTP trên terminal của backend.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF1E4D40),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Mã OTP (6 chữ số)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('forgot_otp_field'),
            controller: _otpController,
            focusNode: _otpFocusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => isLoading ? null : _submitOtp(),
            enabled: !isLoading,
            inputFormatters: [_OtpDigitsFormatter()],
            validator: (v) {
              final otp = v?.trim() ?? '';
              if (otp.length != 6) {
                return 'Vui lòng nhập đủ 6 chữ số OTP';
              }
              return null;
            },
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: _primaryColor,
            ),
            decoration: _inputDecoration(
              hint: 'Nhập mã 6 chữ số (vd: 123456)',
              prefixIcon: Icons.pin_outlined,
            ),
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
            key: const Key('forgot_verify_otp_button'),
            label: 'Xác minh OTP',
            isLoading: isLoading,
            onPressed: _submitOtp,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        _otpController.clear();
                        ref
                            .read(forgotPasswordProvider.notifier)
                            .goBackToEmail();
                      },
                child: const Text(
                  'Đổi email',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _ResendOtpButton(
                isLoading: isLoading,
                onResend: _resendOtp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordStep({
    required String email,
    required bool isLoading,
  }) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đặt mật khẩu mới',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _primaryColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo mật khẩu mới cho $email. Mật khẩu phải có ít nhất 10 ký tự và khác mật khẩu cũ.',
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Mật khẩu mới',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('forgot_new_password_field'),
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Vui lòng nhập mật khẩu mới';
              }
              if (v.length < 10) {
                return 'Mật khẩu mới tối thiểu 10 ký tự';
              }
              if (v.length > 128) {
                return 'Mật khẩu mới tối đa 128 ký tự';
              }
              return null;
            },
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecoration(
              hint: 'Tối thiểu 10 ký tự',
              prefixIcon: Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: () => setState(
                  () => _obscureNewPassword = !_obscureNewPassword,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Xác nhận mật khẩu mới',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('forgot_confirm_password_field'),
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => isLoading ? null : _submitNewPassword(),
            enabled: !isLoading,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Vui lòng xác nhận mật khẩu mới';
              }
              if (v != _newPasswordController.text) {
                return 'Mật khẩu xác nhận không khớp';
              }
              return null;
            },
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecoration(
              hint: 'Nhập lại mật khẩu mới',
              prefixIcon: Icons.lock_reset_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildPrimaryButton(
            key: const Key('forgot_reset_password_button'),
            label: 'Đổi mật khẩu',
            isLoading: isLoading,
            onPressed: _submitNewPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required Key key,
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        key: key,
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryColor.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, letterSpacing: 0),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: Colors.grey.shade500, size: 20),
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
}

class _ResendOtpButton extends ConsumerWidget {
  final bool isLoading;
  final VoidCallback onResend;

  const _ResendOtpButton({
    required this.isLoading,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resendSecondsLeft = ref.watch(
      forgotPasswordProvider.select((s) => s.resendSecondsLeft),
    );

    return TextButton(
      onPressed: isLoading || resendSecondsLeft > 0 ? null : onResend,
      child: Text(
        resendSecondsLeft > 0
            ? 'Gửi lại sau ${resendSecondsLeft}s'
            : 'Gửi lại mã OTP',
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: resendSecondsLeft > 0
              ? Colors.grey.shade400
              : const Color(0xFF0F5B47),
        ),
      ),
    );
  }
}
