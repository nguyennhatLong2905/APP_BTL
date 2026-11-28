/// Nhận ra định dạng ảnh từ vài byte đầu tệp, để báo "ảnh hỏng" rõ ràng thay vì lỗi khó hiểu từ ML Kit.
/// Trả về null nếu không phải định dạng ảnh mà app hỗ trợ.
String? dinhDangAnh(List<int> b) {
  bool bat(int i, List<int> m) =>
      b.length >= i + m.length &&
      [for (var k = 0; k < m.length; k++) b[i + k]].join(',') == m.join(',');
  if (bat(0, const [0xFF, 0xD8, 0xFF])) return 'jpeg';
  if (bat(0, const [0x89, 0x50, 0x4E, 0x47])) return 'png';
  if (bat(0, 'RIFF'.codeUnits) && bat(8, 'WEBP'.codeUnits)) return 'webp';
  if (bat(4, 'ftyp'.codeUnits)) return 'heic';
  if (bat(0, 'GIF8'.codeUnits)) return 'gif';
  if (bat(0, 'BM'.codeUnits)) return 'bmp';
  return null;
}
