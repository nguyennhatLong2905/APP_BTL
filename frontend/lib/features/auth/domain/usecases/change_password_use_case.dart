import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/failures.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/repositories/auth_repository.dart';

class ChangePasswordUseCase {
  final AuthRepository _repository;

  ChangePasswordUseCase(this._repository);

  Future<Either<Failure, String>> execute({
    required String currentPassword,
    required String newPassword,
  }) {
    if (currentPassword.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'Vui lòng nhập mật khẩu hiện tại.')),
      );
    }
    if (newPassword.length < 10) {
      return Future.value(
        const Left(InputFailure(message: 'Mật khẩu mới phải có ít nhất 10 ký tự.')),
      );
    }
    if (currentPassword == newPassword) {
      return Future.value(
        const Left(InputFailure(message: 'Mật khẩu mới phải khác mật khẩu hiện tại.')),
      );
    }
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

