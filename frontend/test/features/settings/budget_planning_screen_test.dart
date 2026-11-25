import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/settings/data/datasources/budget_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/settings/presentation/screens/budget_planning_screen.dart';
import 'package:flutter_test/flutter_test.dart';

const _longCategory = 'Mua sắm vật dụng cá nhân và đồ dùng trong gia đình';

class _BudgetSource implements BudgetRemoteDataSource {
  @override
  Future<Map<String, dynamic>> getPlansScreen() async => {
    'overview': {
      'total': '7950000',
      'protectedMoney': '2400000',
      'unpaidBills': '10500000',
      'available': null,
    },
    'categories': [
      {'_id': 'category', 'name': _longCategory},
    ],
  };

  @override
  Future<List<Map<String, dynamic>>> getBudgets() async => [
    {
      '_id': 'budget',
      'name': 'Ngân sách theo chu kỳ',
      'periodType': 'pay_cycle',
      'status': 'active',
      'startAt': '2026-09-16T00:00:00',
      'endAt': '2026-10-16T00:00:00',
      'warningPercent': 70,
      'limits': [
        {'categoryId': 'category', 'limit': '1000000', 'spent': '380000'},
      ],
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> getGoals() async => [];

  @override
  Future<List<Map<String, dynamic>>> getBills({String? status}) async => [];

  @override
  Future<Map<String, dynamic>> getBillsScreen() async => {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final width in [360.0, 412.0]) {
    testWidgets('${width.toInt()} px: số âm, tên dài, menu và kỳ trống', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            budgetRemoteDataSourceProvider.overrideWithValue(_BudgetSource()),
          ],
          child: const MaterialApp(home: BudgetPlanningScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('−4.950.000 đ'), findsOneWidget);
      expect(find.text('Cảnh báo 70%'), findsOneWidget);
      expect(find.text(_longCategory), findsOneWidget);
      expect(find.text('620.000 đ'), findsOneWidget);
      final menu = find.byTooltip('Thao tác ngân sách: $_longCategory');
      await tester.ensureVisible(menu);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(find.text('Sửa'), findsOneWidget);
      expect(find.text('Xóa'), findsOneWidget);
      await tester.tap(find.text('Sửa'));
      await tester.pumpAndSettle();
      expect(find.textContaining(_longCategory), findsWidgets);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      final addCategory = find.text('Thêm danh mục');
      await tester.ensureVisible(addCategory);
      await tester.pumpAndSettle();
      await tester.tap(addCategory);
      await tester.pumpAndSettle();
      expect(find.text('Thêm Ngân Sách Danh Mục'), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final period = find.byTooltip('Chọn kỳ ngân sách');
      await tester.ensureVisible(period);
      await tester.pumpAndSettle();
      await tester.tap(period);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Theo tháng'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có kỳ ngân sách'), findsOneWidget);
      expect(find.text('Chưa có danh mục trong kỳ này.'), findsOneWidget);
      expect(find.text(_longCategory), findsNothing);
      expect(find.text('−4.950.000 đ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
