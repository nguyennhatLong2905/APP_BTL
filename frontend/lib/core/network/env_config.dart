
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

enum Environment { dev, prod }

class EnvConfig {
  static Environment currentEnvironment = Environment.dev;

  static String? realDeviceIp;

  static String get baseUrl {
    if (currentEnvironment == Environment.prod) {
      return AppConstants.prodBaseUrl;
    }

    if (realDeviceIp != null && realDeviceIp!.isNotEmpty) {
      return 'http://$realDeviceIp:3000/api/v1';
    }

    if (!kIsWeb && Platform.isAndroid) {
      return AppConstants.devBaseUrlAndroid;
    } else if (!kIsWeb && Platform.isIOS) {
      return AppConstants.devBaseUrlIOS;
    }

    return 'http://localhost:3000/api/v1';
  }
}
