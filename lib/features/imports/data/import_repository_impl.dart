import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../../shared/services/excel_parser_service.dart';
import '../domain/entities/import_entity.dart';
import '../domain/entities/import_row_entity.dart';
import '../domain/repositories/import_repository.dart';
import 'import_dto.dart';
import 'import_local_store.dart';
import 'import_pipeline.dart';
import '../../trips/data/trip_local_store.dart';

class ImportRepositoryImpl implements ImportRepository {
  ImportRepositoryImpl({
    required CsvParserService csvParserService,
    required ImportLocalStore importLocalStore,
    required TripLocalStore tripLocalStore,
  })  : _csvParserService = csvParserService,
        _importLocalStore = importLocalStore,
        _tripLocalStore = tripLocalStore,
        _columnMapper = ImportColumnMapper(),
        _rowNormalizer = ImportRowNormalizer(),
        _rowValidator = ImportRowValidator();

  final CsvParserService _csvParserService;
  final ImportLocalStore _importLocalStore;
  final TripLocalStore _tripLocalStore;
  final ImportColumnMapper _columnMapper;
  final ImportRowNormalizer _rowNormalizer;
  final ImportRowValidator _rowValidator;

  final Uuid _uuid = const Uuid();

  // V1 in-memory snapshot for duplicate detection during import.
  // Later versions should replace this with persistent query-backed matching.
  final List<NormalizedTripRecord> _existingTrips = <NormalizedTripRecord>[];

  @override
  Future<ImportEntity> runImport({
    required String fileName,
    required Uint8List bytes,
    required DateTime reportingMonth,
  }) async {
    final parsed = _csvParserService.parse(
      bytes: bytes,
      fileName: fileName,
    );

    final mapping = _columnMapper.resolve(parsed.headers);
    final duplicateMatcher = ImportDuplicateMatcher(_existingTrips);

    final rows = <ImportRowEntity>[];
    for (var index = 0; index < parsed.rows.length; index++) {
      final rowNumber = index + 2; // +2 because row 1 is header
      final raw = parsed.rows[index];

      if (_isCompletelyEmpty(raw)) {
        rows.add(
          ImportRowEntity(
            rowNumber: rowNumber,
            rawJson: raw,
            normalizedJson: null,
            status: ImportRowStatus.skipped,
            errorMessage: 'Row is empty.',
          ),
        );
        continue;
      }

      final normalized = _rowNormalizer.normalize(
        rawRow: raw,
        mapping: mapping,
      );

      if (_isLikelyNonTripRow(normalized)) {
        rows.add(
          ImportRowEntity(
            rowNumber: rowNumber,
            rawJson: raw,
            normalizedJson: null,
            status: ImportRowStatus.skipped,
            errorMessage: 'Skipped non-trip/footer row.',
          ),
        );
        continue;
      }

      final validationError = _rowValidator.validate(
        normalized: normalized,
        mapping: mapping,
      );
      if (validationError != null) {
        rows.add(
          ImportRowEntity(
            rowNumber: rowNumber,
            rawJson: raw,
            normalizedJson: null,
            status: ImportRowStatus.error,
            errorMessage: validationError,
          ),
        );
        continue;
      }

      final match = duplicateMatcher.match(normalized);
      if (match.status == ImportRowStatus.newRow) {
        await _tripLocalStore.upsertFromNormalized(
          normalized,
          reportingMonth: DateTime(reportingMonth.year, reportingMonth.month, 1),
        );
        _existingTrips.add(
          NormalizedTripRecord(
            id: _uuid.v4(),
            tripDate:
                (normalized[ImportCanonicalFields.tripDate] ?? '').toString(),
            waybillNo:
                (normalized[ImportCanonicalFields.waybillNo] ?? '').toString(),
            plateNo:
                (normalized[ImportCanonicalFields.plateNo] ?? '').toString(),
            fromLocation:
                (normalized[ImportCanonicalFields.fromLocation] ?? '').toString(),
            toLocation:
                (normalized[ImportCanonicalFields.toLocation] ?? '').toString(),
          ),
        );
      }

      rows.add(
        ImportRowEntity(
          rowNumber: rowNumber,
          rawJson: raw,
          normalizedJson: normalized,
          status: match.status,
          matchedEntityId: match.matchedEntityId,
          errorMessage: match.note,
        ),
      );
    }

    final importEntity = ImportEntity(
      id: _uuid.v4(),
      fileName: fileName,
      importedAt: DateTime.now().toUtc(),
      reportingMonth: DateTime(reportingMonth.year, reportingMonth.month, 1),
      columnMapping: mapping,
      rows: List.unmodifiable(rows),
    );
    await _importLocalStore.saveImport(importEntity);
    return importEntity;
  }

  @override
  Future<List<ImportEntity>> getImportHistory() {
    return _importLocalStore.getImportHistory();
  }

  bool _isCompletelyEmpty(Map<String, String> raw) {
    for (final value in raw.values) {
      if (value.trim().isNotEmpty) return false;
    }
    return true;
  }

  bool _isLikelyNonTripRow(Map<String, dynamic> normalized) {
    final tripDate = (normalized[ImportCanonicalFields.tripDate] ?? '')
        .toString()
        .trim();
    final waybill = (normalized[ImportCanonicalFields.waybillNo] ?? '')
        .toString()
        .trim();
    final plate = (normalized[ImportCanonicalFields.plateNo] ?? '')
        .toString()
        .trim();
    final from = (normalized[ImportCanonicalFields.fromLocation] ?? '')
        .toString()
        .trim();
    final to = (normalized[ImportCanonicalFields.toLocation] ?? '')
        .toString()
        .trim();

    return tripDate.isEmpty &&
        waybill.isEmpty &&
        plate.isEmpty &&
        from.isEmpty &&
        to.isEmpty;
  }
}
