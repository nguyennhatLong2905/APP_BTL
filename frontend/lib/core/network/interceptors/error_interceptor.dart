import 'package:dio/dio.dart';

/// Interceptor bắt và format chuẩn lỗi trả về từ Backend (Fastify / NestJS)
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String errorMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại sau.';

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      errorMessage = 'Kết nối quá thời gian quy định (Timeout). Vui lòng kiểm tra lại mạng.';
    } else if (err.type == DioExceptionType.badResponse && err.response != null) {
      final statusCode = err.response?.statusCode;
      final data = err.response?.data;

      // Trích xuất message từ response Fastify hoặc NestJS
      if (data is Map<String, dynamic>) {
        if (data['error'] is Map<String, dynamic> && data['error']['message'] != null) {
          final errorObj = data['error'] as Map<String, dynamic>;
          final msg = errorObj['message'].toString();
          if (errorObj['details'] is List && (errorObj['details'] as List).isNotEmpty) {
            final details = (errorObj['details'] as List)
                .map((d) => d is Map ? (d['message'] ?? d.toString()) : d.toString())
                .join(', ');
            errorMessage = '$msg: $details';
          } else {
            errorMessage = msg;
          }
        } else if (data.containsKey('message')) {
          final messageData = data['message'];
          if (messageData is List) {
            errorMessage = messageData.join('\n');
          } else if (messageData is String) {
            errorMessage = messageData;
          }
        } else {
          switch (statusCode) {
            case 400:
              errorMessage = 'Yêu cầu không hợp lệ (Bad Request)';
              break;
            case 401:
              errorMessage = 'Email hoặc mật khẩu không đúng, hoặc phiên đăng nhập đã hết hạn.';
              break;
            case 403:
              errorMessage = 'Bạn không có quyền thực hiện thao tác này (Forbidden)';
              break;
            case 404:
              errorMessage = 'Không tìm thấy dữ liệu yêu cầu (Not Found)';
              break;
            case 409:
              errorMessage = 'Dữ liệu đã tồn tại hoặc xảy ra xung đột.';
              break;
            case 422:
              errorMessage = 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại thông tin nhập.';
              break;
            case 500:
            case 502:
            case 503:
              errorMessage = 'Lỗi máy chủ (Server Error). Vui lòng thử lại sau.';
              break;
          }
        }
      } else {
        switch (statusCode) {
          case 400:
            errorMessage = 'Yêu cầu không hợp lệ (Bad Request)';
            break;
          case 401:
            errorMessage = 'Email hoặc mật khẩu không đúng, hoặc phiên đăng nhập đã hết hạn.';
            break;
          case 403:
            errorMessage = 'Bạn không có quyền thực hiện thao tác này (Forbidden)';
            break;
          case 404:
            errorMessage = 'Không tìm thấy dữ liệu yêu cầu (Not Found)';
            break;
          case 409:
            errorMessage = 'Dữ liệu đã tồn tại hoặc xảy ra xung đột.';
            break;
          case 422:
            errorMessage = 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại thông tin nhập.';
            break;
          case 500:
          case 502:
          case 503:
            errorMessage = 'Lỗi máy chủ (Server Error). Vui lòng thử lại sau.';
            break;
        }
      }
    } else if (err.type == DioExceptionType.unknown && err.error.toString().contains('SocketException')) {
      errorMessage = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra Wi-Fi/IP Backend.';
    }

    // Gắn thông điệp lỗi rõ ràng vào DioException
    final customException = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: errorMessage,
    );

    return handler.next(customException);
  }
}
