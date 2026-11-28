import '../mo_hinh/hoa_don.dart';

enum LoaiLoiChonAnh { khongCoQuyen, khongCoCamera, khac }

class LoiChonAnh implements Exception {
  final LoaiLoiChonAnh loai;
  final String? chiTiet;

  const LoiChonAnh(this.loai, [this.chiTiet]);

  @override
  String toString() => 'LoiChonAnh(${loai.name}: $chiTiet)';
}

/// Lấy ảnh hóa đơn từ camera hoặc thư viện. Bản thật: `ChonAnh` (image_picker) trong nen_tang/nen_tang.dart.
abstract interface class BoChonAnh {
  /// null = người dùng bấm huỷ. Ném [LoiChonAnh] khi không mở được camera/thư viện.
  Future<AnhHoaDon?> chon(NguonAnh nguon);

  /// Android có thể huỷ màn hình của app khi mở camera (máy ít RAM). Gọi lúc mở app để lấy lại ảnh vừa chụp.
  Future<AnhHoaDon?> layAnhBiGianDoan();
}
