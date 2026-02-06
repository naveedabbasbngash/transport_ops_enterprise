import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/foundation.dart';

import '../../../shared/services/excel_parser_service.dart';
import '../../../shared/services/file_picker_service.dart';
import '../data/import_local_store.dart';
import '../data/import_repository_impl.dart';
import '../domain/entities/import_entity.dart';
import '../domain/usecases/get_import_history.dart';
import '../domain/repositories/import_repository.dart';
import '../domain/usecases/run_import.dart';
import '../../trips/data/trip_local_store.dart';
import 'import_state.dart';

final _filePickerServiceProvider = Provider<FilePickerService>((ref) {
  return FilePickerService();
});

final _csvParserServiceProvider = Provider<CsvParserService>((ref) {
  return CsvParserService();
});

final _importLocalStoreProvider = Provider<ImportLocalStore>((ref) {
  return ImportLocalStore();
});

final _importRepositoryProvider = Provider<ImportRepository>((ref) {
  return ImportRepositoryImpl(
    csvParserService: ref.watch(_csvParserServiceProvider),
    importLocalStore: ref.watch(_importLocalStoreProvider),
    tripLocalStore: ref.watch(_tripLocalStoreProvider),
  );
});

final _tripLocalStoreProvider = Provider<TripLocalStore>((ref) {
  return TripLocalStore();
});

final _runImportProvider = Provider<RunImport>((ref) {
  return RunImport(ref.watch(_importRepositoryProvider));
});

final _getImportHistoryProvider = Provider<GetImportHistory>((ref) {
  return GetImportHistory(ref.watch(_importRepositoryProvider));
});

final importViewModelProvider = StateNotifierProvider<ImportViewModel, ImportState>(
  (ref) => ImportViewModel(
    filePickerService: ref.watch(_filePickerServiceProvider),
    runImport: ref.watch(_runImportProvider),
    getImportHistory: ref.watch(_getImportHistoryProvider),
  ),
);

class ImportViewModel extends StateNotifier<ImportState> {
  ImportViewModel({
    required FilePickerService filePickerService,
    required RunImport runImport,
    required GetImportHistory getImportHistory,
  })  : _filePickerService = filePickerService,
        _runImport = runImport,
        _getImportHistory = getImportHistory,
        super(ImportState.initial()) {
    loadHistory();
  }

  final FilePickerService _filePickerService;
  final RunImport _runImport;
  final GetImportHistory _getImportHistory;

  Future<void> loadHistory() async {
    try {
      final history = await _getImportHistory();
      state = state.copyWith(history: history);
    } catch (e) {
      debugPrint('Failed to load import history: $e');
    }
  }

  void setReportingMonth(DateTime month) {
    state = state.copyWith(
      reportingMonth: DateTime(month.year, month.month, 1),
    );
  }

  Future<void> pickAndImportCsv({
    required DateTime reportingMonth,
  }) async {
    final file = await _filePickerService.pickCsvFile();
    if (file == null) return;

    state = state.copyWith(
      isLoading: true,
      selectedFileName: file.name,
      error: null,
      importLog: 'Starting import for ${file.name}...',
    );

    try {
      final report = await _runImport(
        fileName: file.name,
        bytes: file.bytes,
        reportingMonth: reportingMonth,
      );
      final log = _buildImportLog(report);
      debugPrint(log);

      state = state.copyWith(
        isLoading: false,
        selectedFileName: file.name,
        lastReport: report,
        error: null,
        importLog: log,
      );
      await loadHistory();
    } catch (e, st) {
      debugPrint('Import failed: $e');
      debugPrint('$st');
      state = state.copyWith(
        isLoading: false,
        error: 'Import failed. Please verify CSV format and try again.',
        importLog:
            'Import failed for ${file.name}\nError: $e\nStack: $st',
      );
    }
  }

  String _buildImportLog(ImportEntity report) {
    final buffer = StringBuffer();
    buffer.writeln('Import Log');
    buffer.writeln('File: ${report.fileName}');
    buffer.writeln('Imported At (UTC): ${report.importedAt.toIso8601String()}');
    buffer.writeln(
      'Reporting Month: ${report.reportingMonth.year.toString().padLeft(4, '0')}-${report.reportingMonth.month.toString().padLeft(2, '0')}',
    );
    buffer.writeln('Total: ${report.totalRows}');
    buffer.writeln('New: ${report.successfulRows}');
    buffer.writeln('Updated (not applied): ${report.updatedRows}');
    buffer.writeln('Needs review: ${report.needsReviewRows}');
    buffer.writeln('Skipped: ${report.skippedRows}');
    buffer.writeln('Errors: ${report.errorRows}');
    buffer.writeln('');
    buffer.writeln('Column Mapping');
    report.columnMapping.forEach((key, value) {
      buffer.writeln('- $key -> ${value ?? 'NOT FOUND'}');
    });
    buffer.writeln('');
    buffer.writeln('Row Issues');
    for (final row in report.rows) {
      if (row.status.name == 'newRow') continue;
      buffer.writeln(
        'Row ${row.rowNumber} | ${row.status.name} | '
        'matched=${row.matchedEntityId ?? '-'} | '
        'message=${row.errorMessage ?? '-'}',
      );
    }
    return buffer.toString();
  }
}
