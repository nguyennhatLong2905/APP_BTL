/// Các hàm xử lý văn bản thuần Dart — kiểm thử không cần điện thoại.
library;

final _chu = RegExp(r'\p{L}', unicode: true);
final _nhieuDongTrong = RegExp(r'\n{3,}');
final _khoangTrangCuoiDong = RegExp(r'[ \t]+$', multiLine: true);

/// Gom xuống dòng về `\n`, bỏ khoảng trắng cuối dòng, tối đa một dòng trống liên tiếp, cắt đầu/cuối.
String chuanHoaVanBan(String s) => s
    .replaceAll('\r\n', '\n')
    .replaceAll('\r', '\n')
    .replaceAll(_khoangTrangCuoiDong, '')
    .replaceAll(_nhieuDongTrong, '\n\n')
    .trim();

/// Đoán tiêu đề: dòng đầu tiên có ít nhất 3 chữ cái (thường là tên nhà cung cấp in đầu hóa đơn).
/// Trả về chuỗi rỗng nếu không có dòng nào phù hợp.
String doanTieuDe(String vanBan, {int toiDa = 60}) {
  for (final dong in vanBan.split('\n')) {
    final d = dong.trim().replaceAll(RegExp(r'\s{2,}'), ' ');
    if (_chu.allMatches(d).length >= 3) {
      return d.length <= toiDa
          ? d
          : '${d.substring(0, toiDa - 1).trimRight()}…';
    }
  }
  return '';
}

/// Vài dòng đầu (không rỗng) nối bằng " · " — để xem nhanh trong danh sách lịch sử.
String tomTat(String vanBan, {int soDong = 2, int toiDa = 120}) {
  final s = vanBan
      .split('\n')
      .map((d) => d.trim().replaceAll(RegExp(r'\s{2,}'), ' '))
      .where((d) => d.isNotEmpty)
      .take(soDong)
      .join(' · ');
  return s.length <= toiDa ? s : '${s.substring(0, toiDa - 1).trimRight()}…';
}

String _hai(int n) => n.toString().padLeft(2, '0');

/// 03/11/2026 14:05 — cách viết ngày quen thuộc ở Việt Nam, dùng chung cho cả hai ngôn ngữ.
String dinhDangThoiGian(DateTime t) =>
    '${_hai(t.day)}/${_hai(t.month)}/${t.year} ${_hai(t.hour)}:${_hai(t.minute)}';

/// Mã hóa đơn: thời điểm (cơ số 36) + số ngẫu nhiên — đủ để không trùng trên một máy.
String taoMa(DateTime t, int ngauNhien) =>
    '${t.microsecondsSinceEpoch.toRadixString(36)}${(ngauNhien & 0xffff).toRadixString(36).padLeft(4, '0')}';

/// Số dòng có chữ.
int demDong(String vanBan) =>
    vanBan.split('\n').where((d) => d.trim().isNotEmpty).length;
