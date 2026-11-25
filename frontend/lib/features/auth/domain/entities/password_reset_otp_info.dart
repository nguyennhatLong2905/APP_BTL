import 'package:equatable/equatable.dart';

class PasswordResetOtpInfo extends Equatable {
  final String email;
  final int expiresInSeconds;
  final int resendAfterSeconds;
  final String deliveryChannel;

  const PasswordResetOtpInfo({
    required this.email,
    required this.expiresInSeconds,
    required this.resendAfterSeconds,
    required this.deliveryChannel,
  });

  @override
  List<Object?> get props => [
        email,
        expiresInSeconds,
        resendAfterSeconds,
        deliveryChannel,
      ];
}

