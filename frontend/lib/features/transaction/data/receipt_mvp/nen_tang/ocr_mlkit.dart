import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../mo_hinh/hoa_don.dart';
import '../mo_hinh/xu_ly_van_ban.dart';
import '../ocr/bo_nhan_dang.dart';
import '../ocr/dinh_dang_anh.dart';
import '../ocr/ghep_dong.dart';

/// Nhận dạng chữ NGAY TRÊN ĐIỆN THOẠI bằng Google ML Kit (mô hình chữ Latinh, có tiếng Việt).
/// Không gửi ảnh lên mạng, không cần API key, chạy được khi không có Internet.
class NhanDangMlKit implements BoNhanDang {
  /// Chép ảnh mẫu (asset) ra tệp tạm vì ML Kit chỉ đọc tệp trên máy.
  final Future<String> Function(String asset) tepTuAsset;
  TextRecognizer? _bo;

  NhanDangMlKit({required this.tepTuAsset});

  @override
  bool get laDemo => false;

  @override
  Future<KetQuaNhanDang> nhanDang(AnhHoaDon anh) async {
    final dongHo = Stopwatch()..start();
    final duongDan = anh.laAsset
        ? await tepTuAsset(anh.duongDan)
        : anh.duongDan;
    final tep = File(duongDan);
    if (!await tep.exists()) {
      throw const LoiNhanDang(
        LoaiLoiNhanDang.khongDocDuocAnh,
        'không thấy tệp ảnh',
      );
    }
    final dau = await tep
        .openRead(0, 16)
        .fold<List<int>>([], (a, b) => a..addAll(b));
    if (dinhDangAnh(dau) == null) {
      throw const LoiNhanDang(
        LoaiLoiNhanDang.khongDocDuocAnh,
        'không phải tệp ảnh hợp lệ',
      );
    }

    final bo = _bo ??= TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText kq;
    try {
      kq = await bo.processImage(InputImage.fromFilePath(duongDan));
    } on PlatformException catch (e) {
      throw LoiNhanDang(LoaiLoiNhanDang.thatBai, '${e.code}: ${e.message}');
    } on MissingPluginException {
      throw const LoiNhanDang(LoaiLoiNhanDang.khongHoTro);
    }

    final dong = [
      for (final khoi in kq.blocks)
        for (final d in khoi.lines)
          DongChu(
            d.text,
            trai: d.boundingBox.left,
            tren: d.boundingBox.top,
            phai: d.boundingBox.right,
            duoi: d.boundingBox.bottom,
          ),
    ];
    // Ghép theo hàng để hóa đơn không bị "đọc theo cột"; không có toạ độ thì dùng văn bản gốc của ML Kit.
    final vanBan = chuanHoaVanBan(dong.isEmpty ? kq.text : ghepThanhHang(dong));
    return KetQuaNhanDang(
      vanBan: vanBan,
      soDong: demDong(vanBan),
      thoiGian: dongHo.elapsed,
    );
  }

  @override
  Future<void> dong() async {
    await _bo?.close();
    _bo = null;
  }
}
