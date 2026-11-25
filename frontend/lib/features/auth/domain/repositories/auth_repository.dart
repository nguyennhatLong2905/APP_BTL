import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/failures.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/entities/password_reset_otp_info.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Login a user with email and password
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  /// Register a new user
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  });

  /// Demo login qua POST /auth/demo (chỉ bật trên localhost dev)
  Future<Either<Failure, UserEntity>> demoLogin();

  /// Logout the current user
  Future<Either<Failure, void>> logout();

  /// Check if a user is authenticated
  Future<Either<Failure, bool>> isAuthenticated();

  /// Get the current authenticated user
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Update the current user's profile information
  Future<Either<Failure, UserEntity>> updateProfile(UserEntity user);

  /// Đổi mật khẩu — trả về accessToken mới
  Future<Either<Failure, String>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Gửi mã OTP đặt lại mật khẩu qua email
  Future<Either<Failure, PasswordResetOtpInfo>> requestPasswordResetOtp({
    required String email,
  });

  /// Xác minh mã OTP — trả về resetToken dùng để đổi mật khẩu
  Future<Either<Failure, String>> verifyResetOtp({
    required String email,
    required String otp,
  });

  /// Đặt lại mật khẩu sau khi xác minh OTP
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  });
}
