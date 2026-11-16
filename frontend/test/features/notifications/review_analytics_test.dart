import 'package:flutter_riverpod_clean_architecture/features/notifications/domain/models/review_analytics.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/domain/models/timeline_item.dart';
import 'package:flutter_riverpod_clean_architecture/features/notifications/presentation/providers/timeline_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeekStats', () {
    test('parse số liệu thật và nhãn xu hướng', () {
      final w = WeekStats.fromJson({
        'startAt': '2026-11-09T00:00:00+07:00',
        'endAt': '2026-11-16T00:00:00+07:00',
        'income': '0',
        'expense': '330000',
        'previousExpense': '900000',
        'expenseChangePercent': -63.33,
        'trend': 'down',
        'hasData': true,
        'narrative': ['Chi tiêu tuần này giảm 63% so với tuần trước.'],
        'topCategory': {
          'name': 'Học tập',
          'amount': '330000',
          'count': 3,
          'percent': 100,
        },
        'categories': [
          {
            'name': 'Học tập',
            'amount': '330000',
            'count': 3,
            'percent': 100,
          },
        ],
      });
      expect(w.expense, 330000);
      expect(w.previousExpense, 900000);
      expect(w.trend, 'down');
      expect(w.changeLabel, 'Giảm 63%');
      expect(w.hasData, isTrue);
      expect(w.narrative, hasLength(1));
      expect(w.topCategory?.name, 'Học tập');
      expect(w.categories.single.count, 3);
    });

    test('tuần không dữ liệu: hasData=false, narrative rỗng', () {
      final w = WeekStats.fromJson({
        'expense': '0',
        'previousExpense': '0',
        'trend': 'flat',
        'hasData': false,
        'narrative': <String>[],
        'categories': <dynamic>[],
      });
      expect(w.hasData, isFalse);
      expect(w.narrative, isEmpty);
      expect(w.changeLabel, 'Chưa có dữ liệu tuần trước');
    });
  });

  group('SelfInsight', () {
    test('chưa đủ mẫu thì không có luận điểm', () {
      final s = SelfInsight.fromJson({
        'sampleCount': 1,
        'hasEnoughData': false,
        'minimumSamples': 3,
        'statements': <dynamic>[],
        'groups': <dynamic>[],
      });
      expect(s.hasEnoughData, isFalse);
      expect(s.statements, isEmpty);
      expect(s.minimumSamples, 3);
    });

    test('parse luận điểm kèm tỷ lệ, số mẫu và căn cứ', () {
      final s = SelfInsight.fromJson({
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
            'rating': 'reconsider',
            'evidenceTransactionIds': ['a', 'b', 'c'],
          },
        ],
        'groups': [
          {
            'name': 'Mua sắm cá nhân',
            'sampleCount': 3,
            'reconsider': 3,
            'reconsiderPercent': 100,
          },
        ],
      });
      expect(s.hasEnoughData, isTrue);
      final st = s.statements.single;
      expect(st.isPositive, isFalse);
      expect(st.percent, 100);
      expect(st.sampleCount, 3);
      expect(st.evidenceTransactionIds, hasLength(3));
      expect(s.groups.single.reconsiderPercent, 100);
    });
  });

  group('BudgetSuggestionSet', () {
    test('không có ngân sách → rỗng, không bịa gợi ý', () {
      final set = BudgetSuggestionSet.fromJson({
        'hasBudget': false,
        'suggestions': <dynamic>[],
      });
      expect(set.hasBudget, isFalse);
      expect(set.suggestions, isEmpty);
    });

    test('parse gợi ý có lý do, hạn mức và căn cứ', () {
      final set = BudgetSuggestionSet.fromJson({
        'budgetId': 'b1',
        'hasBudget': true,
        'suggestions': [
          {
            'kind': 'decrease_limit',
            'categoryName': 'Mua sắm cá nhân',
            'budgetId': 'b1',
            'currentLimit': '400000',
            'proposedLimit': '320000',
            'usedPercent': 52,
            'reason': '100% trong 3 đánh giá là Muốn cân nhắc lại.',
            'evidenceTransactionIds': ['x', 'y'],
          },
        ],
      });
      expect(set.suggestions, hasLength(1));
      final s = set.suggestions.single;
      expect(s.isIncrease, isFalse);
      expect(s.currentLimit, 400000);
      expect(s.proposedLimit, 320000);
      expect(s.proposedLimit < s.currentLimit, isTrue);
      expect(s.reason, contains('Muốn cân nhắc lại'));
      expect(s.evidenceTransactionIds, hasLength(2));
    });
  });

  group('ReflectionRecord', () {
    test('nhãn đánh giá đúng', () {
      ReflectionRecord make(String status, String? rating) =>
          ReflectionRecord.fromJson({
            '_id': 'r',
            'status': status,
            'rating': rating,
            'transactionId': 't',
            'transaction': {
              'amount': '100000',
              'occurredAt': '2026-11-10T00:00:00+07:00',
              'note': 'Học tập',
            },
            'categoryName': 'Học tập',
          });
      expect(make('rated', 'worth_it').ratingLabel, 'Đáng tiền');
      expect(make('rated', 'neutral').ratingLabel, 'Bình thường');
      expect(make('rated', 'reconsider').ratingLabel, 'Muốn cân nhắc lại');
      expect(make('skipped', null).ratingLabel, 'Đã bỏ qua');
      expect(make('pending', null).ratingLabel, 'Chưa đánh giá');
      expect(make('rated', 'worth_it').amount, 100000);
      expect(make('rated', 'worth_it').categoryName, 'Học tập');
    });
  });

  group('JournalEntry', () {
    test('parse trạng thái suy ra từ backend', () {
      JournalEntry make(String state) => JournalEntry.fromJson({
            '_id': 'r1',
            'transactionId': 't1',
            'state': state,
            'status': 'pending',
            'dueAt': '2026-11-05T00:00:00+07:00',
            'daysRemaining': 3,
            'transaction': {
              'amount': '120000',
              'occurredAt': '2026-11-01T00:00:00+07:00',
              'note': 'Sách kỹ năng',
              'categoryId': 'c1',
              'categoryName': 'Học tập',
            },
          });

      final tracking = make('tracking');
      expect(tracking.state, JournalState.tracking);
      expect(tracking.isTracking, isTrue);
      expect(tracking.daysRemaining, 3);
      expect(tracking.countdownLabel, 'Còn 3 ngày trước khi đánh giá');
      expect(tracking.title, 'Sách kỹ năng');
      expect(tracking.categoryLabel, 'Học tập');
      expect(tracking.amount, 120000);

      final due = make('awaiting_review');
      expect(due.state, JournalState.awaitingReview);
      expect(due.isAwaitingReview, isTrue);
      expect(due.countdownLabel, 'Chờ đánh giá');

      expect(make('rated').isRated, isTrue);
      expect(make('skipped').isSkipped, isTrue);
    });

    test('tiêu đề fallback về tên danh mục khi không có ghi chú', () {
      final e = JournalEntry.fromJson({
        '_id': 'r',
        'transactionId': 't',
        'state': 'rated',
        'rating': 'worth_it',
        'transaction': {
          'amount': '50000',
          'categoryName': 'Ăn uống',
          'note': '',
        },
      });
      expect(e.title, 'Ăn uống');
      expect(e.ratingLabel, 'Đáng tiền');
    });
  });

  group('JournalSummary', () {
    test('phân biệt còn chờ xử lý và đã xử lý hết', () {
      final pending = JournalSummary.fromJson({
        'total': 3,
        'tracking': 2,
        'awaitingReview': 1,
        'rated': 0,
        'skipped': 0,
      });
      expect(pending.hasUnresolved, isTrue);
      expect(pending.reviewed, 0);

      final done = JournalSummary.fromJson({
        'total': 2,
        'tracking': 0,
        'awaitingReview': 0,
        'rated': 1,
        'skipped': 1,
      });
      expect(done.hasUnresolved, isFalse);
      expect(done.reviewed, 2);
    });
  });

  group('timelineProvider state helpers', () {
    test('tách nhóm chờ đánh giá / đang theo dõi / đã xử lý', () {
      const state = TimelineState(
        journal: [
          JournalEntry(
            id: 'a',
            transactionId: 't1',
            state: JournalState.awaitingReview,
          ),
          JournalEntry(
            id: 'b',
            transactionId: 't2',
            state: JournalState.tracking,
            daysRemaining: 5,
          ),
          JournalEntry(
            id: 'c',
            transactionId: 't3',
            state: JournalState.rated,
            rating: 'worth_it',
          ),
          JournalEntry(
            id: 'd',
            transactionId: 't4',
            state: JournalState.skipped,
          ),
        ],
        summary: JournalSummary(
          total: 4,
          tracking: 1,
          awaitingReview: 1,
          rated: 1,
          skipped: 1,
        ),
      );
      expect(state.awaitingReview.single.id, 'a');
      expect(state.tracking.single.id, 'b');
      expect(state.ratedCount, 1);
      expect(state.skippedCount, 1);
      expect(state.allJournalHandled, isFalse);
    });

    test('chỉ báo đã xử lý hết khi không còn mục chưa xử lý', () {
      const state = TimelineState(
        journal: [
          JournalEntry(
            id: 'c',
            transactionId: 't3',
            state: JournalState.rated,
          ),
        ],
        summary: JournalSummary(total: 1, rated: 1),
      );
      expect(state.allJournalHandled, isTrue);
    });
  });

  group('emotion rating mapping', () {
    test('map rating sang API value', () {
      expect(emotionRatingApiValue(EmotionRating.worthIt), 'worth_it');
      expect(emotionRatingApiValue(EmotionRating.normal), 'neutral');
      expect(
          emotionRatingApiValue(EmotionRating.considerAgain), 'reconsider');
      expect(emotionRatingLabel(EmotionRating.considerAgain),
          'Muốn cân nhắc lại');
    });
  });
}
