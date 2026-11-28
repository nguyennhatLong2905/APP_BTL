/// Ảnh của một hóa đơn: tệp trên máy hoặc ảnh mẫu đóng gói trong app (asset).
class AnhHoaDon {
  final String duongDan;
  final bool laAsset;

  const AnhHoaDon.tep(this.duongDan) : laAsset = false;
  const AnhHoaDon.asset(this.duongDan) : laAsset = true;

  static const _tienToAsset = 'asset:';

  /// Chuỗi để lưu vào lịch sử.
  String maHoa() => laAsset ? '$_tienToAsset$duongDan' : duongDan;

  static AnhHoaDon? giaiMa(Object? s) {
    if (s is! String || s.isEmpty) return null;
    return s.startsWith(_tienToAsset)
        ? AnhHoaDon.asset(s.substring(_tienToAsset.length))
        : AnhHoaDon.tep(s);
  }

  @override
  bool operator ==(Object other) =>
      other is AnhHoaDon &&
      other.duongDan == duongDan &&
      other.laAsset == laAsset;

  @override
  int get hashCode => Object.hash(duongDan, laAsset);

  @override
  String toString() => maHoa();
}

/// Ảnh lấy từ đâu.
enum NguonAnh { mayAnh, thuVien, mau }
