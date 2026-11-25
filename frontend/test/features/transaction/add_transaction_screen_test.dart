import 'dart:async';

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
    });
    return pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<(_TransactionSource, ProviderContainer)> _open(
  WidgetTester tester,
  Size size, {
  double scale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final source = _TransactionSource();
  final container = ProviderContainer(
    overrides: [transactionRemoteDataSourceProvider.overrideWithValue(source)],
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
      await tester.drag(find.byType(ListView), const Offset(0, -460));
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
