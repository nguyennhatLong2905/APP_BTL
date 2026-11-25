import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/providers/auth_providers.dart';

enum ForgotPasswordStep { email, otp, newPassword }

class ForgotPasswordState {
  final ForgotPasswordStep step;
  final String email;
  final String resetToken;
  final String deliveryChannel;
  final int resendSecondsLeft;
  final int otpExpiresInSeconds;
  final bool isLoading;
  final String? errorMessage;

  const ForgotPasswordState({
    this.step = ForgotPasswordStep.email,
    this.email = '',
    this.resetToken = '',
    this.deliveryChannel = 'smtp',
    this.resendSecondsLeft = 0,
    this.otpExpiresInSeconds = 600,
    this.isLoading = false,
    this.errorMessage,
  });

  ForgotPasswordState copyWith({
    ForgotPasswordStep? step,
    String? email,
    String? resetToken,
    String? deliveryChannel,
    int? resendSecondsLeft,
    int? otpExpiresInSeconds,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      step: step ?? this.step,
      email: email ?? this.email,
      resetToken: resetToken ?? this.resetToken,
      deliveryChannel: deliveryChannel ?? this.deliveryChannel,
      resendSecondsLeft: resendSecondsLeft ?? this.resendSecondsLeft,
      otpExpiresInSeconds: otpExpiresInSeconds ?? this.otpExpiresInSeconds,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ForgotPasswordNotifier extends Notifier<ForgotPasswordState> {
  Timer? _resendTimer;

  @override
  ForgotPasswordState build() {
    ref.onDispose(() {
      _resendTimer?.cancel();
    });
    return const ForgotPasswordState();
  }

  void _startResendCountdown(int seconds) {
    _resendTimer?.cancel();
    if (seconds <= 0) {
      state = state.copyWith(resendSecondsLeft: 0);
      return;
    }
    state = state.copyWith(resendSecondsLeft: seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.resendSecondsLeft - 1;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(resendSecondsLeft: 0);
      } else {
        state = state.copyWith(resendSecondsLeft: remaining);
      }
    });
  }

  void goBackToEmail() {
    state = state.copyWith(
      step: ForgotPasswordStep.email,
      resetToken: '',
      clearError: true,
    );
  }

  Future<bool> sendOtp(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final useCase = ref.read(requestPasswordResetOtpUseCaseProvider);
    final result = await useCase.execute(email: email);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (info) {
        state = state.copyWith(
          step: ForgotPasswordStep.otp,
          email: info.email,
          resetToken: '',
          deliveryChannel: info.deliveryChannel,
          otpExpiresInSeconds: info.expiresInSeconds,
          isLoading: false,
          clearError: true,
        );
        _startResendCountdown(info.resendAfterSeconds);
        return true;
      },
    );
  }

  Future<bool> resendOtp() async {
    if (state.isLoading || state.resendSecondsLeft > 0 || state.email.isEmpty) {
      return false;
    }
    return sendOtp(state.email);
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final useCase = ref.read(verifyResetOtpUseCaseProvider);
    final result = await useCase.execute(email: state.email, otp: otp);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (resetToken) {
        state = state.copyWith(
          step: ForgotPasswordStep.newPassword,
          resetToken: resetToken,
          isLoading: false,
          clearError: true,
        );
        return true;
      },
    );
  }

  Future<bool> resetPassword(String newPassword) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final useCase = ref.read(resetPasswordUseCaseProvider);
    final result = await useCase.execute(
      email: state.email,
      resetToken: state.resetToken,
      newPassword: newPassword,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (_) {
        _resendTimer?.cancel();
        state = state.copyWith(isLoading: false, clearError: true);
        return true;
      },
    );
  }
}

final forgotPasswordProvider =
    NotifierProvider.autoDispose<ForgotPasswordNotifier, ForgotPasswordState>(
  ForgotPasswordNotifier.new,
);

