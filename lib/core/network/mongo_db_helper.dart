/// Helper xử lý chuẩn hóa dữ liệu từ MongoDB & NestJS
class MongoDbHelper {
  /// Chuyển đổi trường `_id` của MongoDB thành `id` cho Dart Model
  static Map<String, dynamic> normalizeJson(Map<String, dynamic> json) {
    final Map<String, dynamic> copy = Map<String, dynamic>.from(json);

    // Nếu MongoDB trả về `_id` nhưng trong JSON chưa có `id`
    if (copy.containsKey('_id') && !copy.containsKey('id')) {
      copy['id'] = copy['_id']?.toString() ?? '';
    }

    return copy;
  }

  /// Parse chuỗi thời gian ISO 8601 từ NestJS/MongoDB (`createdAt`, `updatedAt`) thành DateTime
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  /// Format DateTime thành chuỗi ISO 8601 để gửi lên NestJS API
  static String? toIso8601String(DateTime? dateTime) {
    return dateTime?.toUtc().toIso8601String();
  }
}

/// Extension tiện ích mở rộng cho Map<String, dynamic>
extension MongoJsonExtension on Map<String, dynamic> {
  /// Tự động mapper `_id` sang `id`
  Map<String, dynamic> toMongoNormalized() {
    return MongoDbHelper.normalizeJson(this);
  }
}
