import 'bo_nhan_dang.dart';

/// Ghép các dòng chữ OCR thành từng HÀNG theo vị trí trên ảnh.
///
/// ML Kit trả chữ theo khối (block): tên hàng một khối, cột số lượng một khối, cột tiền một khối… nên nếu
/// lấy thẳng `RecognizedText.text`, hóa đơn bị "đọc theo cột". Hàm này đặt các dòng có cùng độ cao vào một
/// hàng (sắp trái → phải), để "Nước suối 500ml   5   96.000   480.000" nằm trên cùng một dòng như trên giấy.
///
/// Hai dòng cùng hàng khi tâm theo chiều dọc lệch nhau không quá [nguong] × chiều cao dòng thấp hơn.
String ghepThanhHang(
  List<DongChu> dong, {
  String phanCach = '   ',
  double nguong = 0.5,
}) {
  final ds = dong.where((d) => d.chu.trim().isNotEmpty).toList()
    ..sort((a, b) => a.giuaY.compareTo(b.giuaY));
  final hang = <List<DongChu>>[];
  for (final d in ds) {
    final cuoi = hang.isEmpty ? null : hang.last;
    if (cuoi != null) {
      final tamHang =
          cuoi.map((x) => x.giuaY).reduce((a, b) => a + b) / cuoi.length;
      final caoHang =
          cuoi.map((x) => x.cao).reduce((a, b) => a + b) / cuoi.length;
      final cao = d.cao < caoHang ? d.cao : caoHang;
      if ((d.giuaY - tamHang).abs() <= nguong * cao) {
        cuoi.add(d);
        continue;
      }
    }
    hang.add([d]);
  }
  return hang
      .map((h) {
        h.sort((a, b) => a.trai.compareTo(b.trai));
        return h.map((d) => d.chu.trim()).join(phanCach);
      })
      .join('\n');
}
