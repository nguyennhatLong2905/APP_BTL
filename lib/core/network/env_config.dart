import 'dart:io';
import 'package:flutter/foundation.dart';

enum Environment { dev, prod }

/// Class quản lý cấu hình Base URL linh hoạt cho NestJS Backend
class EnvConfig {
  static Environment currentEnvironment = Environment.dev;

  /// Đổi IP này nếu test trên Thiết bị thật (Real Device) qua cùng mạng Wi-Fi
  /// Ví dụ: '192.168.1.15'
  static String? realDeviceIp;

  static String get baseUrl {
    if (currentEnvironment == Environment.prod) {
      return 'https://api.expensetracker.com/api/v1';
    }

    // Môi trường Dev
    if (realDeviceIp != null && realDeviceIp!.isNotEmpty) {
      return 'http://$realDeviceIp:3000/api/v1';
    }

    if (!kIsWeb && Platform.isAndroid) {
      // Android Emulator dùng IP 10.0.2.2 để gọi localhost của máy tính
      return 'http://10.0.2.2:3000/api/v1';
    } else if (!kIsWeb && Platform.isIOS) {
      // iOS Simulator dùng 127.0.0.1
      return 'http://127.0.0.1:3000/api/v1';
    }

    return 'http://localhost:3000/api/v1';
  }
}
