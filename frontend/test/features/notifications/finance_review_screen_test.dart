import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/data/datasources/timeline_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/presentation/screens/timeline_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod_clean_architecture/core/ui/finance_screen_style.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/presentation/widgets/weekly_review_card.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/domain/models/review_analytics.dart';

class _ReviewSource implements TimelineRemoteDataSource {
  ({String id, String rating, String? note})? saved;
  String? selectedStart;

  static const firstStart = '2026-09-28T00:00:00.000Z';
  static const secondStart = '2026-10-05T00:00:00.000Z';

  @override
  Future<Map<String, dynamic>> getReviewScreen({
    String? startAt,
    String? endAt,
  }) async {
    selectedStart = startAt;
    final emptyWeek = startAt == secondStart;
    return {
      'week': {
        'startAt': emptyWeek ? secondStart : firstStart,
        'endAt': emptyWeek ? '2026-10-12T00:00:00Z' : secondStart,
        'expense': emptyWeek ? '0' : '225000',
        'previousExpense': emptyWeek ? '225000' : '830000',
        'trend': 'down',
        'expenseChangePercent': emptyWeek ? -100 : -73,
        'categories': [
          if (!emptyWeek)
            {
              'name': 'Đồ dùng cá nhân và vật dụng cho gia đình',
              'amount': '225000',
              'percent': 100,
              'count': 2,
            },
        ],
      },
      'weeks': [
        {
          'startAt': firstStart,
          'endAt': secondStart,
          'label': '28/09 – 04/10/2026',
        },
        {
          'startAt': secondStart,
          'endAt': '2026-10-12T00:00:00Z',
          'label': '05/10 – 11/10/2026',
        },
      ],
      'journal': [
        for (final (id, title) in [('one', 'Ăn sáng'), ('two', 'Đổ xăng')])
          {
            '_id': 'reflection-$id',
            'transactionId': id,
            'state': saved?.id == id ? 'rated' : 'awaiting_review',
            'transaction': {
              'note': title,
              'amount': '50000',
              'occurredAt': firstStart,
            },
          },
      ],
      'journalSummary': {'awaitingReview': saved == null ? 2 : 1},
    };
  }

  @override
  Future<Map<String, dynamic>> rateReflection({
    required String id,
    required String rating,
    String? note,
  }) async {
    saved = (id: id, rating: rating, note: note);
    return {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [360.0, 412.0]) {
    testWidgets(
      '${width.toInt()} px: giữ bản nháp và cập nhật đúng tuần, đúng số chờ',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 852));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final source = _ReviewSource();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              timelineRemoteDataSourceProvider.overrideWithValue(source),
            ],
            child: const MaterialApp(home: TimelineScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('225.000 đ'), findsOneWidget);
        final segment = find.descendant(
          of: find.byType(WeeklyReviewCard),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is ColoredBox &&
                widget.color == FinanceScreenStyle.green,
          ),
        );
        expect(tester.getSize(segment).height, greaterThan(0));

        expect(find.text('Giảm 73%'), findsOneWidget);
        expect(find.text('2 khoản chờ đánh giá'), findsOneWidget);
        await _tap(tester, find.text('Đáng tiền'));
        await tester.enterText(find.byType(TextFormField), 'Bản nháp bữa sáng');
        await _tap(tester, find.text('Đổ xăng'));
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.text('Bản nháp bữa sáng'), findsNothing);
        await _tap(tester, find.text('Ăn sáng'));
        expect(find.text('Bản nháp bữa sáng'), findsOneWidget);
        expect(source.saved, isNull);
        await _tap(tester, find.text('Lưu cảm nhận'));
        expect(source.saved, (
          id: 'one',
          rating: 'worth_it',
          note: 'Bản nháp bữa sáng',
        ));
        expect(find.text('1 khoản chờ đánh giá'), findsOneWidget);

        await _tap(tester, find.text('Đổi tuần'));
        await _tap(tester, find.byType(CheckedPopupMenuItem<ReviewWeek>).last);
        expect(source.selectedStart, _ReviewSource.secondStart);
        expect(
          find.text('Tuần này chưa có giao dịch chi tiêu.'),
          findsOneWidget,
        );
        expect(find.text('Giảm 100%'), findsOneWidget);
        expect(
          find.text('Đồ dùng cá nhân và vật dụng cho gia đình'),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
