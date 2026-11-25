import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/report/data/datasources/report_remote_data_source.dart';
import 'package:flutter_riverpod_clean_architecture/features/report/presentation/providers/report_provider.dart';
import 'package:flutter_riverpod_clean_architecture/features/report/presentation/widgets/grouped_transaction_list.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReportSource implements ReportRemoteDataSource {
  final requests = <(DateTime?, DateTime?)>[];
  final responses = <Completer<Map<String, dynamic>>>[];

  @override
  Future<Map<String, dynamic>> getTransactionHistory({
    String? cursor,
    int limit = 30,
    DateTime? startAt,
    DateTime? endAt,
    String? categoryId,
  }) {
    requests.add((startAt, endAt));
    final response = Completer<Map<String, dynamic>>();
    responses.add(response);
    return response.future;
  }

  @override
  Future<Map<String, dynamic>> getReport({
    required String period,
    required DateTime date,
  }) => throw UnimplementedError();
}

void main() {
  testWidgets('chọn tháng đổi khoảng lọc và bỏ phản hồi của tháng cũ', (
    tester,
  ) async {
    final now = DateTime.now();
    final source = _ReportSource();
    final container = ProviderContainer(
      overrides: [reportRemoteDataSourceProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);

    await tester.binding.setSurfaceSize(const Size(393, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: PeriodSelectorWidget())),
      ),
    );
    await tester.pumpAndSettle();

    final initial = 'Tháng ${now.month}/${now.year}';
    await tester.tap(find.text(initial));
    await tester.pumpAndSettle();
    expect(find.text('Chọn tháng · ${now.year}'), findsOneWidget);
    for (var month = 1; month <= 12; month++) {
      expect(find.text('Tháng $month'), findsOneWidget);
    }
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(source.requests, hasLength(1));

    await tester.tap(find.text(initial));
    await tester.pumpAndSettle();
    final month = now.month == 12 ? 2 : 12;
    await tester.tap(find.text('Tháng $month'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Tháng $month/${now.year}'), findsOneWidget);
    expect(source.requests.last, (
      DateTime(now.year, month),
      DateTime(now.year, month + 1),
    ));

    source.responses.last.complete({'items': []});
    await tester.pumpAndSettle();
    source.responses.first.completeError(StateError('stale request'));
    await tester.pumpAndSettle();
    final report = container.read(reportProvider);
    expect(report.selectedMonth, DateTime(now.year, month));
    expect(report.errorMessage, isNull);
    expect(report.isLoading, isFalse);
  });
}
