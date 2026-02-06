import 'import_row_entity.dart';

class ImportEntity {
  final String id;
  final String fileName;
  final DateTime importedAt;
  final DateTime reportingMonth;
  final Map<String, String?> columnMapping;
  final List<ImportRowEntity> rows;

  const ImportEntity({
    required this.id,
    required this.fileName,
    required this.importedAt,
    required this.reportingMonth,
    required this.columnMapping,
    required this.rows,
  });

  int get totalRows => rows.length;

  int get successfulRows =>
      rows.where((row) => row.status == ImportRowStatus.newRow).length;

  int get updatedRows =>
      rows.where((row) => row.status == ImportRowStatus.updatedNotApplied).length;

  int get needsReviewRows =>
      rows.where((row) => row.status == ImportRowStatus.needsReview).length;

  int get skippedRows =>
      rows.where((row) => row.status == ImportRowStatus.skipped).length;

  int get errorRows =>
      rows.where((row) => row.status == ImportRowStatus.error).length;
}
