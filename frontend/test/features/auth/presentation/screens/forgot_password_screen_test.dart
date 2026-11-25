import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod_clean_architecture/core/constants/app_constants.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/entities/password_reset_otp_info.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod_clean_architecture/features/auth/presentation/screens/forgot_password_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  Widget buildSubject({String? initialEmail}) {
    final router = GoRouter(
      initialLocation: AppConstants.forgotPasswordRoute,
      routes: [
        GoRoute(
          path: AppConstants.loginRoute,
          builder: (_, _) => const Scaffold(body: Text('Login Placeholder')),
        ),
        GoRoute(
          path: AppConstants.forgotPasswordRoute,
          builder: (_, _) => ForgotPasswordScreen(initialEmail: initialEmail),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('completes 3-step forgot password OTP flow and returns to login',
      (tester) async {
    when(() => mockRepo.requestPasswordResetOtp(email: 'user@gmail.com'))
        .thenAnswer(
      (_) async => const Right(
        PasswordResetOtpInfo(
          email: 'user@gmail.com',
          expiresInSeconds: 600,
          resendAfterSeconds: 60,
          deliveryChannel: 'smtp',
        ),
      ),
    );
    when(() => mockRepo.verifyResetOtp(email: 'user@gmail.com', otp: '123456'))
        .thenAnswer((_) async => const Right('reset-token-xyz'));
    when(
      () => mockRepo.resetPassword(
        email: 'user@gmail.com',
        resetToken: 'reset-token-xyz',
        newPassword: 'newStrongPassword123',
      ),
    ).thenAnswer((_) async => const Right(null));

    await tester.pumpWidget(buildSubject(initialEmail: 'user@gmail.com'));
    await tester.pumpAndSettle();

    // Step 1: Submit email
    expect(find.byKey(const Key('forgot_email_field')), findsOneWidget);
    await tester.tap(find.byKey(const Key('forgot_send_otp_button')));
    await tester.pumpAndSettle();

    // Step 2: Enter OTP (with spaces/extra chars to verify formatter) and wait 2s for countdown ticks
    expect(find.byKey(const Key('forgot_otp_field')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.enterText(
      find.byKey(const Key('forgot_otp_field')),
      ' 12-345678 ',
    );
    await tester.pump();
    final otpField = tester.widget<TextFormField>(
      find.byKey(const Key('forgot_otp_field')),
    );
    expect(otpField.controller?.text, '123456');
    await tester.tap(find.byKey(const Key('forgot_verify_otp_button')));
    await tester.pumpAndSettle();

    // Step 3: Enter new password + confirm
    expect(find.byKey(const Key('forgot_new_password_field')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('forgot_new_password_field')),
      'newStrongPassword123',
    );
    await tester.enterText(
      find.byKey(const Key('forgot_confirm_password_field')),
      'newStrongPassword123',
    );
    await tester.tap(find.byKey(const Key('forgot_reset_password_button')));
    await tester.pumpAndSettle();

    verify(() => mockRepo.requestPasswordResetOtp(email: 'user@gmail.com'))
        .called(1);
    verify(() => mockRepo.verifyResetOtp(email: 'user@gmail.com', otp: '123456'))
        .called(1);
    verify(
      () => mockRepo.resetPassword(
        email: 'user@gmail.com',
        resetToken: 'reset-token-xyz',
        newPassword: 'newStrongPassword123',
      ),
    ).called(1);

    expect(find.text('Login Placeholder'), findsOneWidget);
  });
}
