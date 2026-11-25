import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod_clean_architecture/core/error/failures.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/entities/password_reset_otp_info.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/usecases/request_password_reset_otp_use_case.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/usecases/verify_reset_otp_use_case.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late RequestPasswordResetOtpUseCase requestOtpUseCase;
  late VerifyResetOtpUseCase verifyOtpUseCase;
  late ResetPasswordUseCase resetPasswordUseCase;

  setUp(() {
    mockRepo = MockAuthRepository();
    requestOtpUseCase = RequestPasswordResetOtpUseCase(mockRepo);
    verifyOtpUseCase = VerifyResetOtpUseCase(mockRepo);
    resetPasswordUseCase = ResetPasswordUseCase(mockRepo);
  });

  group('RequestPasswordResetOtpUseCase', () {
    test('rejects empty email without calling repository', () async {
      final result = await requestOtpUseCase.execute(email: '   ');
      result.fold(
        (failure) => expect(failure, isA<InputFailure>()),
        (_) => fail('Expected InputFailure'),
      );
      verifyZeroInteractions(mockRepo);
    });

    test('rejects invalid email format', () async {
      final result = await requestOtpUseCase.execute(email: 'invalid-email');
      result.fold(
        (failure) => expect(failure, isA<InputFailure>()),
        (_) => fail('Expected InputFailure'),
      );
      verifyZeroInteractions(mockRepo);
    });

    test('normalizes email and forwards to repository', () async {
      const info = PasswordResetOtpInfo(
        email: 'user@gmail.com',
        expiresInSeconds: 600,
        resendAfterSeconds: 60,
        deliveryChannel: 'smtp',
      );
      when(() => mockRepo.requestPasswordResetOtp(email: 'user@gmail.com'))
          .thenAnswer((_) async => const Right(info));

      final result = await requestOtpUseCase.execute(email: '  USER@gmail.com ');

      expect(result, const Right(info));
      verify(() => mockRepo.requestPasswordResetOtp(email: 'user@gmail.com'))
          .called(1);
    });
  });

  group('VerifyResetOtpUseCase', () {
    test('rejects non-6-digit OTP', () async {
      final result = await verifyOtpUseCase.execute(
        email: 'user@gmail.com',
        otp: '12345',
      );
      result.fold(
        (failure) => expect(failure, isA<InputFailure>()),
        (_) => fail('Expected InputFailure'),
      );
      verifyZeroInteractions(mockRepo);
    });

    test('returns resetToken on valid 6-digit OTP', () async {
      when(() => mockRepo.verifyResetOtp(email: 'user@gmail.com', otp: '654321'))
          .thenAnswer((_) async => const Right('reset-token-abc'));

      final result = await verifyOtpUseCase.execute(
        email: 'User@gmail.com',
        otp: ' 654321 ',
      );

      expect(result, const Right('reset-token-abc'));
      verify(
        () => mockRepo.verifyResetOtp(email: 'user@gmail.com', otp: '654321'),
      ).called(1);
    });
  });

  group('ResetPasswordUseCase', () {
    test('rejects password shorter than 10 characters', () async {
      final result = await resetPasswordUseCase.execute(
        email: 'user@gmail.com',
        resetToken: 'token123',
        newPassword: 'short',
      );
      result.fold(
        (failure) => expect(failure, isA<InputFailure>()),
        (_) => fail('Expected InputFailure'),
      );
      verifyZeroInteractions(mockRepo);
    });

    test('calls repository when valid', () async {
      when(
        () => mockRepo.resetPassword(
          email: 'user@gmail.com',
          resetToken: 'token123',
          newPassword: 'newStrongPassword123',
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await resetPasswordUseCase.execute(
        email: 'user@gmail.com',
        resetToken: 'token123',
        newPassword: 'newStrongPassword123',
      );

      expect(result, const Right(null));
      verify(
        () => mockRepo.resetPassword(
          email: 'user@gmail.com',
          resetToken: 'token123',
          newPassword: 'newStrongPassword123',
        ),
      ).called(1);
    });
  });
}

