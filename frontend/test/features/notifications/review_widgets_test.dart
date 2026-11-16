import 'package:flutter/material.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/domain/models/review_analytics.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/domain/models/timeline_item.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/presentation/widgets/budget_suggestion_section.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/presentation/widgets/reflection_transaction_card.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/presentation/widgets/self_insight_card.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/presentation/widgets/week_reflection_header.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/presentation/widgets/weekly_expense_summary_card.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );

void main() {
  group('ReflectionTransactionCard (nhật ký tự động)', () {
    JournalEntry entry(JournalState state, {int days = 0, String? rating}) =>
        JournalEntry(
          id: 'r1',
          transactionId: 't1',
          state: state,
          rating: rating,
          daysRemaining: days,
          amount: 120000,
          occurredAt: DateTime(2026, 11, 10),
          categoryName: 'Học tập',
          transactionNote: 'Sách kỹ năng',
        );

    testWidgets('chưa đủ 7 ngày: hiển thị đếm ngược, không có nút thêm nhật ký',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ReflectionTransactionCard(
          entry: entry(JournalState.tracking, days: 4),
          onRatingSelected: (_) {},
          onSave: (_, _) {},
        ),
      ));
      expect(find.text('Sách kỹ năng'), findsOneWidget);
      expect(find.text('120.000 ₫'), findsNothing); // có dấu trừ ở trước
      expect(find.textContaining('-120.000 ₫'), findsOneWidget);
      expect(
        find.textContaining('Còn 4 ngày trước khi đánh giá'),
        findsOneWidget,
      );
      expect(find.textContaining('Thêm khoản chi vào nhật ký'), findsNothing);
      // Vẫn cho phép đánh giá sớm với đủ 4 lựa chọn (3 mức + bỏ qua).
      expect(find.text('Đáng tiền'), findsOneWidget);
      expect(find.text('Bình thường'), findsOneWidget);
      expect(find.text('Muốn cân nhắc lại'), findsOneWidget);
      expect(find.text('Bỏ qua không đánh giá'), findsOneWidget);
    });

    testWidgets('đủ 7 ngày: hiển thị lời mời đánh giá', (tester) async {
      await tester.pumpWidget(_wrap(
        ReflectionTransactionCard(
          entry: entry(JournalState.awaitingReview),
          onRatingSelected: (_) {},
          onSave: (_, _) {},
        ),
      ));
      expect(
        find.textContaining('Đã đủ 7 ngày — mời bạn đánh giá'),
        findsOneWidget,
      );
    });

    testWidgets('bấm đánh giá gọi callback đúng mức', (tester) async {
      EmotionRating? picked;
      await tester.pumpWidget(_wrap(
        ReflectionTransactionCard(
          entry: entry(JournalState.awaitingReview),
          onRatingSelected: (r) => picked = r,
          onSave: (_, _) {},
        ),
      ));
      await tester.tap(find.text('Muốn cân nhắc lại'));
      await tester.pumpAndSettle();
      expect(picked, EmotionRating.considerAgain);
    });
  });

  group('WeekReflectionHeader', () {
    testWidgets('tuần không đủ dữ liệu hiển thị trạng thái, không bịa nhận xét',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const WeekReflectionHeader(
          dateRange: '09/11 – 15/11/2026',
          week: WeekStats(hasData: false),
        ),
      ));
      expect(find.text('09/11 – 15/11/2026'), findsOneWidget);
      expect(find.textContaining('Chưa đủ dữ liệu'), findsOneWidget);
    });

    testWidgets('hiển thị nhận xét thật khi có dữ liệu', (tester) async {
      await tester.pumpWidget(_wrap(
        WeekReflectionHeader(
          dateRange: '09/11 – 15/11/2026',
          week: WeekStats.fromJson({
            'hasData': true,
            'trend': 'down',
            'expenseChangePercent': -12.0,
            'narrative': [
              'Chi tiêu tuần này giảm 12% so với tuần trước.',
              'Học tập chiếm 100% tổng chi (3 giao dịch).',
            ],
          }),
        ),
      ));
      expect(find.textContaining('giảm 12%'), findsOneWidget);
      expect(find.textContaining('Học tập chiếm'), findsOneWidget);
    });
  });

  group('WeeklyExpenseSummaryCard', () {
    testWidgets('hiển thị số tiền thật và empty state', (tester) async {
      await tester.pumpWidget(
        _wrap(WeeklyExpenseSummaryCard(week: const WeekStats())),
      );
      expect(find.textContaining('Chưa có giao dịch chi'), findsOneWidget);
    });

    testWidgets('hiển thị danh mục và bấm để drill-down', (tester) async {
      WeekCategory? tapped;
      await tester.pumpWidget(_wrap(
        WeeklyExpenseSummaryCard(
          week: WeekStats.fromJson({
            'expense': '330000',
            'previousExpense': '900000',
            'expenseChangePercent': -63.0,
            'trend': 'down',
            'hasData': true,
            'categories': [
              {
                'name': 'Học tập',
                'amount': '330000',
                'count': 3,
                'percent': 100,
              },
            ],
          }),
          onTapCategory: (c) => tapped = c,
        ),
      ));
      expect(find.text('Học tập'), findsOneWidget);
      expect(find.text('(100%)'), findsOneWidget);
      await tester.tap(find.text('Học tập'));
      await tester.pumpAndSettle();
      expect(tapped?.name, 'Học tập');
    });
  });

  group('SelfInsightCard', () {
    testWidgets('chưa đủ mẫu hiển thị tiến độ, không kết luận', (tester) async {
      await tester.pumpWidget(_wrap(
        const SelfInsightCard(
          insight: SelfInsight(sampleCount: 1, minimumSamples: 3),
        ),
      ));
      expect(find.textContaining('Cần thêm'), findsOneWidget);
      expect(find.textContaining('1/3'), findsOneWidget);
    });

    testWidgets('đủ mẫu hiển thị luận điểm kèm tỷ lệ', (tester) async {
      await tester.pumpWidget(_wrap(
        SelfInsightCard(
          insight: SelfInsight.fromJson({
            'sampleCount': 6,
            'hasEnoughData': true,
            'minimumSamples': 3,
            'statements': [
              {
                'kind': 'negative',
                'text': 'Các khoản Mua sắm cá nhân thường được đánh giá Muốn cân nhắc lại.',
                'percent': 100,
                'sampleCount': 3,
                'count': 3,
                'evidenceTransactionIds': ['a', 'b', 'c'],
              },
            ],
          }),
          onShowEvidence: (_) {},
          onViewHistory: () {},
        ),
      ));
      expect(
        find.textContaining('Mua sắm cá nhân', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('3/3 mẫu (100%)', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('3 giao dịch căn cứ'), findsOneWidget);
    });
  });

  group('BudgetSuggestionSection', () {
    testWidgets('chưa có ngân sách hiển thị hướng dẫn, không gợi ý',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const BudgetSuggestionSection(set: BudgetSuggestionSet()),
      ));
      expect(find.textContaining('Chưa có kỳ ngân sách'), findsOneWidget);
    });

    testWidgets('không có gợi ý: nêu đúng lý do và việc cần làm', (tester) async {
      await tester.pumpWidget(_wrap(
        BudgetSuggestionSection(
          set: BudgetSuggestionSet.fromJson({
            'hasBudget': true,
            'suggestions': [],
            'usage': [
              {
                'categoryName': 'Học tập',
                'limit': '600000',
                'spent': '1230000',
                'percent': 205,
                'transactions': 2,
              },
            ],
            'emptyReason': {
              'code': 'no_ratings',
              'reason':
                  'Mức chi hiện tại đang nằm trong khoảng hợp lý so với hạn mức.',
              'nextStep':
                  'Đánh giá các khoản chi sau 7 ngày để Ví An hiểu bạn thấy khoản nào đáng tiền.',
            },
          }),
        ),
      ));
      // Không còn câu chung chung "Chưa có gợi ý phù hợp".
      expect(find.textContaining('Chưa có gợi ý phù hợp'), findsNothing);
      expect(
        find.textContaining('nằm trong khoảng hợp lý'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Đánh giá các khoản chi sau 7 ngày'),
        findsOneWidget,
      );
      // Vẫn hiển thị mức dùng hạn mức thật.
      expect(find.text('Mức dùng hạn mức kỳ này'), findsOneWidget);
      expect(find.text('Học tập'), findsOneWidget);
      expect(find.text('205%'), findsOneWidget);
      expect(find.text('1.230.000 / 600.000 ₫'), findsOneWidget);
    });

    testWidgets('gợi ý có lý do, hạn mức, nút xem tác động/xác nhận/bỏ qua',
        (tester) async {
      await tester.pumpWidget(_wrap(
        BudgetSuggestionSection(
          set: BudgetSuggestionSet.fromJson({
            'hasBudget': true,
            'suggestions': [
              {
                'kind': 'decrease_limit',
                'categoryName': 'Mua sắm cá nhân',
                'currentLimit': '400000',
                'proposedLimit': '320000',
                'usedPercent': 52,
                'reason': '100% trong 3 đánh giá là Muốn cân nhắc lại.',
                'evidenceTransactionIds': ['x', 'y'],
              },
            ],
          }),
        ),
      ));
      expect(find.textContaining('Giảm ngân sách Mua sắm cá nhân'),
          findsOneWidget);
      expect(find.textContaining('100% trong 3 đánh giá'), findsOneWidget);
      expect(find.text('Xem tác động'), findsOneWidget);
      expect(find.text('Xác nhận'), findsOneWidget);
      expect(find.text('Bỏ qua'), findsOneWidget);
      // Không tự áp dụng: chỉ hiển thị, không có hành động ngầm.
      expect(find.textContaining('400.000'), findsWidgets);
      expect(find.textContaining('320.000'), findsWidgets);
    });
  });
}
