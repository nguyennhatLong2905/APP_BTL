import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_clean_architecture/features/report/data/datasources/report_remote_data_source.dart';

class ReportState {
  final bool isLoading;
  final Map<String, dynamic>? reportData;
  final List<Map<String, dynamic>> transactions;
  final DateTime selectedDate;
  final String selectedPeriod; // 'month' | 'week' | 'year'
  final String? errorMessage;

  const ReportState({
    this.isLoading = false,
    this.reportData,
    this.transactions = const [],
    required this.selectedDate,
    this.selectedPeriod = 'month',
    this.errorMessage,
  });

  ReportState copyWith({
    bool? isLoading,
    Map<String, dynamic>? reportData,
    List<Map<String, dynamic>>? transactions,
    DateTime? selectedDate,
    String? selectedPeriod,
    String? errorMessage,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      reportData: reportData ?? this.reportData,
      transactions: transactions ?? this.transactions,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      errorMessage: errorMessage,
    );
  }
}

class ReportNotifier extends Notifier<ReportState> {
  @override
  ReportState build() {
    Future.microtask(() => loadReport());
    return ReportState(isLoading: true, selectedDate: DateTime.now());
  }

  Future<void> loadReport() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ds = ref.read(reportRemoteDataSourceProvider);
      final data = await ds.getReport(
        period: state.selectedPeriod,
        date: state.selectedDate,
      );
      state = state.copyWith(isLoading: false, reportData: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void changePeriod(String period) {
    state = state.copyWith(selectedPeriod: period);
    loadReport();
  }

  void changeDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    loadReport();
  }

  Future<void> loadTransactionHistory({String? cursor}) async {
    state = state.copyWith(isLoading: true);
    try {
      final ds = ref.read(reportRemoteDataSourceProvider);
      final data = await ds.getTransactionHistory(cursor: cursor, limit: 30);
      final items = data['items'] as List<dynamic>? ?? [];
      state = state.copyWith(
        isLoading: false,
        transactions: items.cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final reportProvider =
    NotifierProvider<ReportNotifier, ReportState>(ReportNotifier.new);
