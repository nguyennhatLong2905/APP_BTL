import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/data/datasources/attachment_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/data/receipt_mvp/du_lieu/bo_chon_anh.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/data/receipt_mvp/mo_hinh/hoa_don.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/data/receipt_mvp/ocr/bo_nhan_dang.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/data/receipt_scanner.dart';

import 'package:flutter_riverpod_clean_architecture/features/transaction/domain/models/receipt.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/data/datasources/transaction_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/presentation/screens/add_transaction_screen.dart';
import 'package:flutter_riverpod_clean_architecture/features/transaction/presentation/widgets/transaction_keypad.dart';

class _TransactionSource implements TransactionRemoteDataSource {
  final requests = <Map<String, Object?>>[];
  final pending = Completer<Map<String, dynamic>>();

  @override
  Future<List<Map<String, dynamic>>> getWallets() async => [
    {
      '_id': 'cash',
      'name': 'Tiền mặt',
      'balance': '850000',
      'status': 'active',
    },
    {
      '_id': 'bank',
      'name': 'Tài khoản',
      'balance': '7400000',
      'status': 'active',
    },
    {'_id': 'old', 'name': 'Ví cũ', 'balance': '0', 'status': 'archived'},
  ];

  @override
  Future<List<Map<String, dynamic>>> getCategories() async => [
    {'_id': 'food-id', 'name': 'Ăn uống', 'kind': 'expense'},
    {'_id': 'salary-id', 'name': 'Lương', 'kind': 'income'},
    {'_id': 'project-id', 'name': 'Dự án', 'kind': 'income'},
  ];

  @override
  Future<Map<String, dynamic>> getTransactions({
    String? cursor,
    int limit = 20,
    String? walletId,
    String? categoryId,
  }) async => {'items': []};

  @override
  Future<List<Map<String, dynamic>>> getBudgets() async => [];

  @override
  Future<Map<String, dynamic>> createTransaction({
    required String type,
    required String amount,
    required String occurredAt,
    String? categoryId,
    String? walletId,
    String? fromWalletId,
    String? toWalletId,
    String? memo,
    String? note,
    List<String>? attachmentIds,
    String? merchant,
    List<ReceiptLine>? receiptLines,
    String? idempotencyKey,
  }) {
    requests.add({
      'type': type,
      'amount': amount,
      'date': occurredAt,
      'category': categoryId,
      'wallet': walletId,
      'from': fromWalletId,
      'to': toWalletId,
      'note': note,
      'merchant': merchant,
      'receiptLines': receiptLines?.map((item) => item.toJson()).toList(),
      'attachmentIds': attachmentIds,
      'key': idempotencyKey,
    });
    return pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReceiptPicker implements BoChonAnh {
  AnhHoaDon? next;

  @override
  Future<AnhHoaDon?> chon(NguonAnh nguon) async => next;

  @override
  Future<AnhHoaDon?> layAnhBiGianDoan() async => null;
}

class _ReceiptRecognition implements BoNhanDang {
  @override
  bool get laDemo => false;

  @override
  Future<void> dong() async {}

  @override
  Future<KetQuaNhanDang> nhanDang(AnhHoaDon anh) async => const KetQuaNhanDang(
    vanBan: 'Cửa hàng thử\nCà phê   35.000 đ\nTạm tính 35.000 đ',
    soDong: 3,
    thoiGian: Duration.zero,
  );
}

class _ReceiptAttachments implements AttachmentRemoteDataSource {
  int uploads = 0;

  @override
  Future<String> uploadAttachment(XFile file) async {
    uploads++;
    return 'receipt-photo';
  }

  @override
  Future<List<int>> downloadAttachment(String id) async => [];
}

Future<(_TransactionSource, ProviderContainer)> _open(
  WidgetTester tester,
  Size size, {
  double scale = 1,
  _ReceiptPicker? receiptPicker,
  _ReceiptAttachments? receiptAttachments,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final source = _TransactionSource();
  final container = ProviderContainer(
    overrides: [
      transactionRemoteDataSourceProvider.overrideWithValue(source),
      if (receiptPicker != null) ...[
        receiptImagePickerProvider.overrideWithValue(receiptPicker),
        receiptRecognitionProvider.overrideWithValue(_ReceiptRecognition.new),
      ],
      if (receiptAttachments != null)
        attachmentRemoteDataSourceProvider.overrideWithValue(
          receiptAttachments,
        ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('vi'), Locale('en')],
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: child!,
        ),
        home: const AddTransactionScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (source, container);
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Finder _key(String label) => find.descendant(
  of: find.byType(TransactionKeypad),
  matching: find.text(label),
);

bool _saveEnabled(WidgetTester tester) => tester
    .widget<FilledButton>(find.widgetWithText(FilledButton, 'Lưu giao dịch'))
    .enabled;

void main() {
  testWidgets('OCR chỉ ở khoản chi, giữ chỉnh sửa và gửi một giao dịch', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('vian-receipt-test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final photo = File('${dir.path}/receipt.png')
      ..writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jHZkAAAAASUVORK5CYII=',
        ),
      );
    final picker = _ReceiptPicker();
    final attachments = _ReceiptAttachments();
    final (source, container) = await _open(
      tester,
      const Size(390, 750),
      receiptPicker: picker,
      receiptAttachments: attachments,
    );
    await _tap(tester, 'Thu nhập');
    expect(find.text('Quét OCR'), findsNothing);
    await _tap(tester, 'Chuyển ví');
    expect(find.text('Quét OCR'), findsNothing);
    await _tap(tester, 'Chi tiêu');
    expect(find.byType(TransactionKeypad), findsOneWidget);
    await _tap(tester, 'Quét OCR');
    await _tap(tester, 'Chọn ảnh có sẵn');
    expect(find.text('Quét hóa đơn'), findsOneWidget);
    expect(find.text('Đang đọc hóa đơn…'), findsNothing);

    picker.next = AnhHoaDon.tep(photo.path);
    await tester.runAsync(() async {
      await tester.tap(find.text('Chọn ảnh có sẵn'));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await tester.pumpAndSettle();
    expect(find.text('Kết quả quét'), findsOneWidget);
    expect(find.text('0 đ'), findsOneWidget);
    await tester.tap(find.byTooltip('Sửa số tiền'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '65000');
    await _tap(tester, 'Xác nhận');
    await _tap(tester, 'Xem ảnh gốc');
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await _tap(tester, 'Đóng ảnh');
    expect(find.text('65.000 đ'), findsOneWidget);

    await _tap(tester, 'Thêm dòng');
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Bánh');
    await tester.enterText(fields.at(1), '10000');
    await _tap(tester, 'Xác nhận');
    expect(container.read(receiptTransactionFormProvider).amount, 65000);
    await _tap(tester, 'Ví chi tiền');
    await _tap(tester, 'Tiền mặt');
    await _tap(tester, 'Ăn uống');

    final note = find.byType(TextField);
    await tester.ensureVisible(note);
    await tester.enterText(note, 'Ghi chú OCR');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Lưu giao dịch');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.tap(save);
    await tester.pump();
    expect(source.requests, hasLength(1));
    expect(attachments.uploads, 1);
    expect(source.requests.single, containsPair('amount', '65000'));
    expect(source.requests.single, containsPair('merchant', 'Cửa hàng thử'));
    expect(source.requests.single, containsPair('wallet', 'cash'));
    expect(source.requests.single, containsPair('category', 'food-id'));
    expect(source.requests.single, containsPair('note', 'Ghi chú OCR'));
    expect(source.requests.single['key'], isNotEmpty);
    expect(source.requests.single['attachmentIds'], ['receipt-photo']);
    expect(source.requests.single['receiptLines'], [
      {'name': 'Cà phê', 'amount': '35000'},
      {'name': 'Bánh', 'amount': '10000'},
    ]);
    source.pending.complete({});
    await tester.pumpAndSettle();
    expect(find.text('Quét hóa đơn'), findsOneWidget);
  });

  testWidgets(
    '360 px: bàn phím ghim đáy, đúng vị trí và nhập không cần focus',
    (tester) async {
      await _open(tester, const Size(360, 520));
      expect(find.byType(TextField), findsNothing);
      expect(find.text('0 đ'), findsOneWidget);
      final layout = [
        [_key('1'), _key('2'), _key('3'), _key('000')],
        [_key('4'), _key('5'), _key('6'), _key('0')],
        [_key('7'), _key('8'), _key('9'), find.byTooltip('Xóa')],
      ];
      for (final row in layout) {
        final points = row.map(tester.getCenter).toList();
        expect(points.map((p) => p.dy).toSet(), hasLength(1));
        expect(
          points.map((p) => p.dx),
          orderedEquals([...points.map((p) => p.dx)]..sort()),
        );
      }
      expect(
        tester.getCenter(layout[0][0]).dy,
        lessThan(tester.getCenter(layout[1][0]).dy),
      );
      expect(
        tester.getCenter(layout[1][0]).dy,
        lessThan(tester.getCenter(layout[2][0]).dy),
      );
      expect(_saveEnabled(tester), isFalse);

      for (final digit in ['1', '2', '5', '000']) {
        await tester.tap(_key(digit));
        await tester.pump();
      }
      expect(find.text('125.000 đ'), findsOneWidget);
      await tester.tap(find.byTooltip('Xóa'));
      await tester.pump();
      expect(find.text('12.500 đ'), findsOneWidget);
      for (var count = 0; count < 5; count++) {
        await tester.tap(find.byTooltip('Xóa'));
        await tester.pump();
      }
      expect(find.text('0 đ'), findsOneWidget);

      final keyPosition = tester.getCenter(_key('1'));
      await tester.scrollUntilVisible(
        find.text('Ghi chú & ảnh hóa đơn'),
        60,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ghi chú & ảnh hóa đơn').hitTestable(), findsOneWidget);
      expect(tester.getCenter(_key('1')), keyPosition);
      expect(find.text('Lưu giao dịch').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('412 px: cộng dồn, danh mục theo tab và yêu cầu chọn ví', (
    tester,
  ) async {
    final (source, _) = await _open(tester, const Size(412, 860));
    for (final key in ['2', '5', '000']) {
      await tester.tap(_key(key));
      await tester.pump();
    }
    await _tap(tester, '+50.000 đ');
    expect(find.text('75.000 đ'), findsOneWidget);
    expect(find.text('Ví chi tiền'), findsOneWidget);
    await _tap(tester, 'Ăn uống');
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(_saveEnabled(tester), isFalse);

    await _tap(tester, 'Thu nhập');
    expect(find.text('Ví nhận tiền'), findsOneWidget);
    expect(find.text('Chọn ví nhận tiền và danh mục để lưu.'), findsOneWidget);
    expect(find.text('Ăn uống'), findsNothing);
    for (final name in ['Lương', 'Thưởng', 'Đầu tư', 'Tự do', 'Quà tặng']) {
      expect(find.text(name), findsOneWidget);
    }
    await _tap(tester, 'Lương');
    expect(find.text('Chọn ví nhận tiền để lưu.'), findsOneWidget);
    await _tap(tester, 'Ví nhận tiền');
    expect(find.text('Ví cũ'), findsNothing);
    await _tap(tester, 'Tiền mặt');
    expect(_saveEnabled(tester), isTrue);

    final notes = find.text('Ghi chú & ảnh hóa đơn');
    await tester.ensureVisible(notes);
    await tester.pumpAndSettle();
    await _tap(tester, 'Ghi chú & ảnh hóa đơn');
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Ghi chú thử');
    await tester.ensureVisible(notes);
    await tester.pumpAndSettle();
    await tester.tap(notes);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Lưu giao dịch'));
    await tester.pump();
    expect(source.requests.single, containsPair('type', 'income'));
    expect(source.requests.single, containsPair('amount', '75000'));
    expect(source.requests.single, containsPair('wallet', 'cash'));
    expect(source.requests.single, containsPair('category', 'salary-id'));
    expect(source.requests.single, containsPair('note', 'Ghi chú thử'));
    source.pending.complete({'_id': 'income-saved'});
    await tester.pumpAndSettle();
    expect(find.text('Đã lưu giao dịch thành công!'), findsOneWidget);
  });

  testWidgets('chuyển ví chặn ví trùng và chỉ gửi một yêu cầu khi lưu', (
    tester,
  ) async {
    final (source, container) = await _open(tester, const Size(412, 860));
    await _tap(tester, 'Chuyển ví');
    expect(find.text('Danh mục phổ biến'), findsNothing);
    await _tap(tester, '+10.000 đ');
    await _tap(tester, 'Từ ví');
    await _tap(tester, 'Tiền mặt');
    await _tap(tester, 'Đến ví');
    final blocked = find.widgetWithText(ListTile, 'Trùng với ví đã chọn');
    expect(tester.widget<ListTile>(blocked).enabled, isFalse);
    await tester.tap(blocked);
    await tester.pumpAndSettle();
    expect(find.text('Trùng với ví đã chọn'), findsOneWidget);
    expect(_saveEnabled(tester), isFalse);
    await _tap(tester, 'Tài khoản');

    final notifier = container.read(transactionFormProvider.notifier);
    await tester.tap(find.text('Lưu giao dịch'));
    await tester.pump();
    expect(find.text('Đang lưu…'), findsOneWidget);
    await notifier
        .saveTransaction(); // Người dùng bấm thêm khi yêu cầu đầu chưa xong.
    expect(source.requests, hasLength(1));
    expect(source.requests.single, containsPair('type', 'transfer'));
    expect(source.requests.single, containsPair('amount', '10000'));
    expect(source.requests.single, containsPair('from', 'cash'));
    expect(source.requests.single, containsPair('to', 'bank'));
    expect(source.requests.single, containsPair('category', null));
    expect(source.requests.single, containsPair('wallet', null));
    expect(
      DateTime.parse(source.requests.single['date']! as String).isUtc,
      isTrue,
    );

    source.pending.complete({'_id': 'saved'});
    await tester.pumpAndSettle();
    expect(find.text('Đã lưu giao dịch thành công!'), findsOneWidget);
    expect(find.text('0 đ'), findsOneWidget);
    expect(_saveEnabled(tester), isFalse);
  });
}
