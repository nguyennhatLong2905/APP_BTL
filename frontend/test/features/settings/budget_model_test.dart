import 'package:flutter/material.dart';
import 'package:flutter_riverpod_clean_architecture/features/settings/domain/models/category_budget.dart';
import 'package:flutter_riverpod_clean_architecture/features/settings/presentation/widgets/budget_category_card.dart';
import 'package:flutter_test/flutter_test.dart';

CategoryBudget _budget({
  double limit = 2000000,
  double spent = 0,
  int warningPercent = 80,
  bool locked = false,
  int? percent,
}) =>
    CategoryBudget(
      id: 'c1',
      name: 'Ăn uống',
      icon: Icons.restaurant_rounded,
      allocatedAmount: limit,
      spentAmount: spent,
      warningPercent: warningPercent,
      locked: locked,
      percent: percent,
    );

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('CategoryBudget – công thức và trạng thái', () {
    test('còn lại = hạn mức − đã chi', () {
      final b = _budget(limit: 2000000, spent: 1600000);
      expect(b.remainingAmount, 400000);
      expect(b.overAmount, 0);
      expect(b.isOverBudget, isFalse);
      expect(b.isExhausted, isFalse);
      expect(b.percentageInt, 80);
    });

    test('hết hạn mức khi đã chi bằng hạn mức', () {
      final b = _budget(limit: 2000000, spent: 2000000);
      expect(b.remainingAmount, 0);
      expect(b.isExhausted, isTrue);
      expect(b.isOverBudget, isFalse);
      expect(b.statusLabel, 'Hết hạn mức');
    });

    test('vượt hạn mức: báo đúng số tiền vượt', () {
      final b = _budget(limit: 2000000, spent: 2300000);
      expect(b.remainingAmount, 0);
      expect(b.overAmount, 300000);
      expect(b.isOverBudget, isTrue);
      expect(b.statusLabel, 'Vượt hạn mức');
    });

    test('ngưỡng cảnh báo do người dùng chọn (50%)', () {
      final b = _budget(limit: 1000000, spent: 550000, warningPercent: 50);
      expect(b.isNearLimit, isTrue);
      expect(b.statusLabel, 'Sắp hết');

      // Cùng 55% nhưng ngưỡng 80% thì chưa cảnh báo.
      final relaxed = _budget(
        limit: 1000000,
        spent: 550000,
        warningPercent: 80,
      );
      expect(relaxed.isNearLimit, isFalse);
      expect(relaxed.statusLabel, 'Bình thường');
    });

    test('percent ưu tiên giá trị backend trả về', () {
      final b = _budget(limit: 1000000, spent: 999999, percent: 100);
      expect(b.percentageInt, 100);
    });
  });

  group('BudgetCategoryCard – hiển thị', () {
    testWidgets('bình thường: hiện hạn mức, đã chi, còn lại, %', (tester) async {
      await tester.pumpWidget(_wrap(
        BudgetCategoryCard(
          category: _budget(limit: 2000000, spent: 1600000),
        ),
      ));
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(
        find.textContaining('Hạn mức 2.000.000 ₫'),
        findsOneWidget,
      );
      expect(find.textContaining('Đã chi 1.600.000 ₫'), findsOneWidget);
      expect(find.text('400.000 ₫'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('Sắp hết'), findsOneWidget);
    });

    testWidgets('vượt hạn mức: hiện số tiền vượt và trạng thái', (tester) async {
      await tester.pumpWidget(_wrap(
        BudgetCategoryCard(
          category: _budget(limit: 2000000, spent: 2300000),
        ),
      ));
      expect(find.textContaining('Vượt hạn mức 300.000 ₫'), findsWidgets);
      expect(find.text('Vượt hạn mức'), findsWidgets);
    });

    testWidgets('có nút xóa khi được cấp callback', (tester) async {
      var deleted = false;
      await tester.pumpWidget(_wrap(
        BudgetCategoryCard(
          category: _budget(limit: 2000000, spent: 100000),
          onDeletePressed: () => deleted = true,
        ),
      ));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });
  });
}
