import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../du_lieu/bo_chon_anh.dart';
import '../mo_hinh/hoa_don.dart';

/// Máy có ML Kit (nhận dạng trên thiết bị) hay không.
bool get coOcrThietBi =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Chụp ảnh / chọn ảnh bằng image_picker.
///
/// Android: dùng ứng dụng camera của máy và trình chọn ảnh hệ thống (Android Photo Picker) nên app KHÔNG
/// khai báo quyền CAMERA hay quyền đọc ảnh. Ảnh được thu nhỏ còn cạnh dài ≤ 2400 px: đủ nét cho OCR,
/// nhẹ bộ nhớ.
class ChonAnh implements BoChonAnh {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<AnhHoaDon?> chon(NguonAnh nguon) async {
    try {
      final x = await _picker.pickImage(
        source: nguon == NguonAnh.mayAnh
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 90,
        requestFullMetadata: false,
      );
      return x == null ? null : AnhHoaDon.tep(x.path);
    } on PlatformException catch (e) {
      final ma = e.code.toLowerCase();
      if (ma.contains('access_denied') || ma.contains('permission')) {
        throw LoiChonAnh(LoaiLoiChonAnh.khongCoQuyen, e.code);
      }
      if (ma.contains('no_available_camera') ||
          ma.contains('camera_unavailable')) {
        throw LoiChonAnh(LoaiLoiChonAnh.khongCoCamera, e.code);
      }
      throw LoiChonAnh(LoaiLoiChonAnh.khac, '${e.code}: ${e.message}');
    }
  }

  @override
  Future<AnhHoaDon?> layAnhBiGianDoan() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final r = await _picker.retrieveLostData();
      if (r.isEmpty) return null;
      final f = (r.files != null && r.files!.isNotEmpty)
          ? r.files!.first
          : r.file;
      return f == null ? null : AnhHoaDon.tep(f.path);
    } catch (_) {
      return null;
    }
  }
}
