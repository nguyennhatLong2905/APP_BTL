import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/failures.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/repositories/auth_repository.dart';

class VerifyResetOtpUseCase {
  final AuthRepository _repository;

  VerifyResetOtpUseCase(this._repository);

  Future<Either<Failure, String>> execute({
    required String email,
    required String otp,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedOtp = otp.trim();
    if (normalizedEmail.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'Thiếu địa chỉ email.')),
      );
    }
    if (!RegExp(r'^\d{6}$').hasMatch(normalizedOtp)) {
      return Future.value(
        const Left(InputFailure(message: 'Mã OTP phải gồm đúng 6 chữ số.')),
      );
    }
    return _repository.verifyResetOtp(
      email: normalizedEmail,
      otp: normalizedOtp,
    );
  }
}

