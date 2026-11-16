import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/data_management_remote_data_source.dart';

final dataManagementProvider = AsyncNotifierProvider<DataManagementNotifier, void>(() {
  return DataManagementNotifier();
});

class DataManagementNotifier extends AsyncNotifier<void> {
  late DataManagementRemoteDataSource _dataSource;

  @override
  Future<void> build() async {
    _dataSource = ref.watch(dataManagementRemoteDataSourceProvider);
  }

  Future<Map<String, dynamic>> previewImport(File file) async {
    state = const AsyncValue.loading();
    try {
      final result = await _dataSource.previewImport(file);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> commitImport(String previewId, List<int> selectedRows, bool includeSuspectedDuplicates) async {
    state = const AsyncValue.loading();
    try {
      final result = await _dataSource.commitImport(
        previewId: previewId,
        selectedRows: selectedRows,
        includeSuspectedDuplicates: includeSuspectedDuplicates,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<List<int>> exportTransactionsCsv({String? startAt, String? endAt, String? walletId}) async {
    state = const AsyncValue.loading();
    try {
      final result = await _dataSource.exportTransactionsCsv(startAt: startAt, endAt: endAt, walletId: walletId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createBackup() async {
    state = const AsyncValue.loading();
    try {
      final result = await _dataSource.createBackup();
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> previewRestore(Map<String, dynamic> backupData) async {
    state = const AsyncValue.loading();
    try {
      final result = await _dataSource.previewRestore(backupData);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> restoreBackup(String previewId, String confirmation) async {
    state = const AsyncValue.loading();
    try {
      final result = await _dataSource.restoreBackup(previewId: previewId, confirmation: confirmation);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> previewErase() async {
    state = const AsyncValue.loading();
    try {
      final result = await _dataSource.previewErase();
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> eraseData(String previewId, String confirmation) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.eraseData(previewId: previewId, confirmation: confirmation);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
