import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/failures.dart';
import 'package:flutter_riverpod_clean_architecture/core/utils/app_utils.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/entities/password_reset_otp_info.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/repositories/auth_repository.dart';

class RequestPasswordResetOtpUseCase {
  final AuthRepository _repository;

  RequestPasswordResetOtpUseCase(this._repository);

  Future<Either<Failure, PasswordResetOtpInfo>> execute({
    required String email,
  }) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'Vui lòng nhập email.')),
      );
    }
    if (!AppUtils.isValidEmail(normalized)) {
      return Future.value(
        const Left(InputFailure(message: 'Email không hợp lệ.')),
      );
    }
    return _repository.requestPasswordResetOtp(email: normalized);
  }
}

