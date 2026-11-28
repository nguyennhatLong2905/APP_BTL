import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';

import 'receipt_mvp/du_lieu/bo_chon_anh.dart';
import 'receipt_mvp/mo_hinh/hoa_don.dart';
import 'receipt_mvp/nen_tang/chon_anh.dart';
import 'receipt_mvp/nen_tang/ocr_mlkit.dart';
import 'receipt_mvp/ocr/bo_nhan_dang.dart';
import 'receipt_mvp/ocr/dinh_dang_anh.dart';
import 'receipt_parser.dart';

typedef ScannedReceipt = ({
  ParsedReceipt draft,
  Uint8List original,
  XFile attachment,
});

final receiptImagePickerProvider = Provider<BoChonAnh>((ref) => ChonAnh());

final receiptRecognitionProvider = Provider<BoNhanDang Function()>((ref) {
  return () => NhanDangMlKit(
    tepTuAsset: (_) => throw UnsupportedError('Chọn ảnh từ thiết bị.'),
  );
});

Future<ScannedReceipt?> scanReceipt(
  AnhHoaDon photo,
  BoNhanDang recognition,
) async {
  final KetQuaNhanDang result;
  try {
    result = await recognition.nhanDang(photo);
  } finally {
    await recognition.dong();
  }
  if (result.trong) return null;

  final source = XFile(photo.duongDan);
  final original = await source.readAsBytes();
  final format = dinhDangAnh(original);
  final keepOriginal =
      const {'jpeg', 'png', 'webp'}.contains(format) &&
      original.length <= 2000000;
  final bytes = keepOriginal
      ? original
      : await compute(_attachmentJpeg, original);
  if (bytes == null) {
    throw const LoiNhanDang(LoaiLoiNhanDang.khongDocDuocAnh);
  }
  final extension = keepOriginal && format != 'jpeg' ? format : 'jpg';
  return (
    draft: parseReceipt(result.vanBan),
    original: original,
    attachment: XFile.fromData(
      bytes,
      path: 'hoa-don.$extension',
      name: 'hoa-don.$extension',
    ),
  );
}

Uint8List? _attachmentJpeg(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) return null;
  var resized = image.bakeOrientation(decoded);
  final longest = math.max(resized.width, resized.height);
  for (final limit in [2000, 1400, 1000]) {
    if (longest > limit) {
      final landscape = resized.width >= resized.height;
      resized = image.copyResize(
        resized,
        width: landscape ? limit : null,
        height: landscape ? null : limit,
      );
    }
    final output = image.encodeJpg(resized, quality: 84);
    if (output.length <= 2000000) return output;
  }
  return null;
}
