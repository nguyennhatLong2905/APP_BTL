import 'package:flutter_riverpod_clean_architecture/features/transaction/data/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ưu tiên số phải trả và lấy thành tiền cuối mỗi dòng', () {
    final receipt = parseReceipt('''
ĐẠI LÝ NƯỚC GIẢI KHÁT MINH TÂM
12 Ngõ 34 Đường Mẫu, Hà Nội
HÓA ĐƠN BÁN LẺ
Số: 000127   Ngày: 03/11/2026   10:24
Tên hàng   SL   Đơn giá   Thành tiền
Nước suối 500ml (thùng 24)   5   96.000   480.000
Trà xanh 455ml (thùng 24)   3   180.000   540.000
Cộng tiền hàng:   1.020.000
Chiết khấu:   -20.000
Tổng thanh toán:   1.000.000 đ
Tổng tiền   1.020.000
Tiền khách đưa:   1.100.000
Tiền thừa:   100.000
''');

    expect(receipt.merchant, 'ĐẠI LÝ NƯỚC GIẢI KHÁT MINH TÂM');
    expect(receipt.date, DateTime(2026, 11, 3, 10, 24));
    expect(receipt.total, 1000000);
    expect(receipt.lines.map((row) => row.name), [
      'Nước suối 500ml (thùng 24)',
      'Trà xanh 455ml (thùng 24)',
    ]);
    expect(receipt.lines.map((row) => row.amount), [480000, 540000]);
  });

  test('thiếu tổng thì giữ nguyên tên và món, không đoán từ tạm tính', () {
    final receipt = parseReceipt('''
Cà phê Mộc
Cà phê sữa    35.000 đ
Bánh chuối    30.000 đ
Tạm tính      65.000 đ
Khách đưa     100.000 đ
Trả lại       35.000 đ
''');
    expect(receipt.total, isNull);
    expect(receipt.date, isNull);
    expect(receipt.merchant, 'Cà phê Mộc');
    expect(receipt.lines.map((row) => row.amount), [35000, 30000]);
  });

  test('bỏ cột mã hàng và các dòng công nợ', () {
    final receipt = parseReceipt('''
CÔNG TY PHÂN PHỐI AN PHÁT
Mã   Tên hàng   ĐVT   SL   Thành tiền
MI01   Mì gói tôm chua cay   Thùng   10   1.150.000
Tổng cộng: 1.150.000
Đã thanh toán: 1.000.000
Còn nợ: 150.000
''');
    expect(receipt.lines.single.name, 'Mì gói tôm chua cay');
    expect(receipt.total, 1150000);
  });

  test('đọc dòng chỉ có tiền ngay sau nhãn phải trả', () {
    final receipt = parseReceipt('Ngày 2026-11-03\nPhải trả\n65 000 ₫');
    expect(receipt.total, 65000);
    expect(receipt.date, DateTime(2026, 11, 3));
  });
}
