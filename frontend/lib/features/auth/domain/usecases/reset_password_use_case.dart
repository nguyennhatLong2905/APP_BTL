import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/failures.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository _repository;

  ResetPasswordUseCase(this._repository);

  Future<Either<Failure, void>> execute({
    required String email,
    required String resetToken,
    required String newPassword,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || resetToken.isEmpty) {
      return Future.value(
        const Left(
          InputFailure(
            message: 'Phiên xác minh không hợp lệ. Vui lòng thử lại.',
          ),
        ),
      );
    }
    if (newPassword.length < 10) {
      return Future.value(
        const Left(
          InputFailure(message: 'Mật khẩu mới phải có ít nhất 10 ký tự.'),
        ),
      );
    }
    if (newPassword.length > 128) {
      return Future.value(
        const Left(
          InputFailure(message: 'Mật khẩu mới tối đa 128 ký tự.'),
        ),
      );
    }
    return _repository.resetPassword(
      email: normalizedEmail,
      resetToken: resetToken,
      newPassword: newPassword,
    );
  }
}

