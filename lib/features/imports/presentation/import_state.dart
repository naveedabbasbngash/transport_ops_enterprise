import '../domain/entities/import_entity.dart';

class ImportState {
  final bool isLoading;
  final String? selectedFileName;
  final DateTime reportingMonth;
  final ImportEntity? lastReport;
  final List<ImportEntity> history;
  final String? error;
  final String? importLog;

  const ImportState({
    required this.isLoading,
    this.selectedFileName,
    required this.reportingMonth,
    this.lastReport,
    this.history = const [],
    this.error,
    this.importLog,
  });

  factory ImportState.initial() {
    final now = DateTime.now();
    return ImportState(
      isLoading: false,
      reportingMonth: DateTime(now.year, now.month, 1),
    );
  }

  ImportState copyWith({
    bool? isLoading,
    String? selectedFileName,
    DateTime? reportingMonth,
    ImportEntity? lastReport,
    List<ImportEntity>? history,
    Object? error = _sentinel,
    Object? importLog = _sentinel,
  }) {
    return ImportState(
      isLoading: isLoading ?? this.isLoading,
      selectedFileName: selectedFileName ?? this.selectedFileName,
      reportingMonth: reportingMonth ?? this.reportingMonth,
      lastReport: lastReport ?? this.lastReport,
      history: history ?? this.history,
      error: identical(error, _sentinel) ? this.error : error as String?,
      importLog: identical(importLog, _sentinel)
          ? this.importLog
          : importLog as String?,
    );
  }

  static const _sentinel = Object();
}
