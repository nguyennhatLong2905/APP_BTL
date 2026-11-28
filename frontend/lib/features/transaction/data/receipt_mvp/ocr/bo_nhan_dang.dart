import '../mo_hinh/hoa_don.dart';

/// Một dòng chữ máy nhận dạng được, kèm khung bao (toạ độ điểm ảnh trong ảnh gốc).
class DongChu {
  final String chu;
  final double trai, tren, phai, duoi;

  const DongChu(
    this.chu, {
    required this.trai,
    required this.tren,
    required this.phai,
    required this.duoi,
  });

  double get giuaY => (tren + duoi) / 2;
  double get cao => (duoi - tren).abs();
}

class KetQuaNhanDang {
  final String vanBan;
  final int soDong;
  final Duration thoiGian;

  const KetQuaNhanDang({
    required this.vanBan,
    required this.soDong,
    required this.thoiGian,
  });

  bool get trong => vanBan.trim().isEmpty;
}

enum LoaiLoiNhanDang {
  /// Tệp ảnh không mở được (hỏng, đã bị xoá, định dạng lạ).
  khongDocDuocAnh,

  /// Nền tảng không có bộ nhận dạng trên thiết bị (web, máy tính).
  khongHoTro,

  /// Lỗi khác trong lúc nhận dạng.
  thatBai,
}

class LoiNhanDang implements Exception {
  final LoaiLoiNhanDang loai;
  final String? chiTiet;

  const LoiNhanDang(this.loai, [this.chiTiet]);

  @override
  String toString() =>
      'LoiNhanDang(${loai.name}${chiTiet == null ? '' : ': $chiTiet'})';
}

/// Bộ nhận dạng chữ. Có hai bản: ML Kit trên thiết bị (`nen_tang/ocr_mlkit.dart`) và demo (`nhan_dang_demo.dart`).
/// Màn hình chỉ biết giao diện này nên đổi sang dịch vụ khác không phải sửa giao diện.
abstract interface class BoNhanDang {
  /// true: văn bản là dữ liệu mẫu, không đọc từ ảnh thật.
  bool get laDemo;

  /// Ném [LoiNhanDang] khi thất bại. Ảnh không có chữ KHÔNG phải lỗi: trả về kết quả rỗng.
  Future<KetQuaNhanDang> nhanDang(AnhHoaDon anh);

  Future<void> dong();
}
