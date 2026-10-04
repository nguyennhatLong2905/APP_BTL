import 'package:dio/dio.dart';

/// Interceptor bắt và format chuẩn lỗi trả về từ NestJS Backend
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

      // Trích xuất message từ response NestJS
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        final messageData = data['message'];
        if (messageData is List) {
          // NestJS ValidationPipe thường trả về mảng các câu báo lỗi
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
            errorMessage = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
            break;
          case 403:
            errorMessage = 'Bạn không có quyền thực hiện thao tác này (Forbidden)';
            break;
          case 404:
            errorMessage = 'Không tìm thấy dữ liệu yêu cầu (Not Found)';
            break;
          case 500:
          case 502:
          case 503:
            errorMessage = 'Lỗi máy chủ (Server Error). Vui lòng thử lại sau.';
            break;
        }
      }
    } else if (err.type == DioExceptionType.unknown && err.error.toString().contains('SocketException')) {
      errorMessage = 'Không thể kết nối đến Server NestJS. Vui lòng kiểm tra Wi-Fi/IP Backend.';
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
