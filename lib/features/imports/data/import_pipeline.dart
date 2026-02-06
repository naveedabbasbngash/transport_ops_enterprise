import '../domain/entities/import_row_entity.dart';
import 'import_dto.dart';

class ImportCanonicalFields {
  ImportCanonicalFields._();

  static const tripDate = 'trip_date';
  static const waybillNo = 'waybill_no';
  static const plateNo = 'plate_no';
  static const fromLocation = 'from_location';
  static const toLocation = 'to_location';
  static const clientName = 'client_name';
  static const vehicleType = 'vehicle_type';
  static const driverName = 'driver_name';
  static const tripAmount = 'trip_amount';
  static const vendorCost = 'vendor_cost';
  static const companyOtherCost = 'company_other_cost';
  static const remarks = 'remarks';
}

class ImportColumnMapper {
  static const requiredFields = <String>[
    ImportCanonicalFields.tripDate,
    ImportCanonicalFields.plateNo,
    ImportCanonicalFields.fromLocation,
    ImportCanonicalFields.toLocation,
  ];

  static const aliases = <String, List<String>>{
    ImportCanonicalFields.clientName: [
      'client',
      'client name',
      'customer',
      'customer name',
    ],
    ImportCanonicalFields.tripDate: [
      'loading date',
      'trip date',
      'date',
    ],
    ImportCanonicalFields.fromLocation: [
      'from',
      'from location',
      'origin',
    ],
    ImportCanonicalFields.toLocation: [
      'to',
      'to location',
      'destination',
    ],
    ImportCanonicalFields.waybillNo: [
      'waybill no',
      'waybill',
      'waybill number',
      'wb no',
    ],
    ImportCanonicalFields.plateNo: [
      'vehicle plate no',
      'plate number',
      'plate no',
      'plate',
      'truck plate',
      'vehicle no',
    ],
    ImportCanonicalFields.vehicleType: [
      'vehicle type',
      'truck type',
    ],
    ImportCanonicalFields.driverName: [
      'driver name',
      'driver',
    ],
    ImportCanonicalFields.tripAmount: [
      'trip charges',
      'trip charge company',
      'revenue',
      'amount',
      'company total',
    ],
    ImportCanonicalFields.vendorCost: [
      'vendor charges',
      'vendor cost',
      'trip rate driver',
      'driver total',
      'vendor amount',
    ],
    ImportCanonicalFields.companyOtherCost: [
      'company other cost',
      'other cost',
      'wc company',
      'wc driver',
    ],
    ImportCanonicalFields.remarks: [
      'remarks',
      'notes',
    ],
  };

  Map<String, String?> resolve(List<String> headers) {
    final normalizedHeaders = <String, String>{};
    for (final header in headers) {
      normalizedHeaders[_normalize(header)] = header;
    }

    final mapping = <String, String?>{};
    for (final entry in aliases.entries) {
      String? source;
      for (final candidate in entry.value) {
        source = normalizedHeaders[_normalize(candidate)];
        if (source != null) break;
      }
      mapping[entry.key] = source;
    }

    return Map.unmodifiable(mapping);
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class ImportRowNormalizer {
  Map<String, dynamic> normalize({
    required Map<String, String> rawRow,
    required Map<String, String?> mapping,
  }) {
    final normalized = <String, dynamic>{};
    for (final entry in mapping.entries) {
      final sourceHeader = entry.value;
      final value = sourceHeader == null ? '' : (rawRow[sourceHeader] ?? '');
      normalized[entry.key] = value.trim();
    }
    return Map.unmodifiable(normalized);
  }
}

class ImportRowValidator {
  String? validate({
    required Map<String, dynamic> normalized,
    required Map<String, String?> mapping,
  }) {
    for (final field in ImportColumnMapper.requiredFields) {
      if (mapping[field] == null) {
        return 'Required column "$field" was not found in file header.';
      }
      final value = (normalized[field] ?? '').toString().trim();
      if (value.isEmpty) {
        return 'Required field "$field" is empty.';
      }
    }

    final tripDate = (normalized[ImportCanonicalFields.tripDate] ?? '')
        .toString()
        .trim();
    if (!_isValidDate(tripDate)) {
      return 'Invalid trip_date "$tripDate".';
    }

    return null;
  }

  bool _isValidDate(String value) {
    if (value.isEmpty) return false;
    if (DateTime.tryParse(value) != null) return true;

    final normalized = value.replaceAll('/', '-');
    final parts = normalized.split('-');
    if (parts.length != 3) return false;
    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    final third = int.tryParse(parts[2]);
    if (first == null || second == null || third == null) return false;

    // Accept dd-mm-yyyy and mm-dd-yyyy style inputs from manual Excel exports.
    final looksLikeDmy = third >= 1900 &&
        second >= 1 &&
        second <= 12 &&
        first >= 1 &&
        first <= 31;
    final looksLikeMdy = third >= 1900 &&
        first >= 1 &&
        first <= 12 &&
        second >= 1 &&
        second <= 31;

    return looksLikeDmy || looksLikeMdy;
  }
}

class ImportMatchResult {
  final ImportRowStatus status;
  final String? matchedEntityId;
  final String? note;

  const ImportMatchResult({
    required this.status,
    this.matchedEntityId,
    this.note,
  });
}

class ImportDuplicateMatcher {
  final List<NormalizedTripRecord> _existingTrips;

  const ImportDuplicateMatcher(this._existingTrips);

  ImportMatchResult match(Map<String, dynamic> normalized) {
    final tripDate = (normalized[ImportCanonicalFields.tripDate] ?? '').toString();
    final waybillNo = (normalized[ImportCanonicalFields.waybillNo] ?? '').toString();
    final plateNo = (normalized[ImportCanonicalFields.plateNo] ?? '').toString();
    final fromLocation =
        (normalized[ImportCanonicalFields.fromLocation] ?? '').toString();
    final toLocation = (normalized[ImportCanonicalFields.toLocation] ?? '').toString();

    if (waybillNo.isNotEmpty) {
      for (final existing in _existingTrips) {
        if (existing.tripDate == tripDate &&
            existing.waybillNo == waybillNo &&
            existing.plateNo == plateNo) {
          return ImportMatchResult(
            status: ImportRowStatus.updatedNotApplied,
            matchedEntityId: existing.id,
            note: 'Primary match found. Update not auto-applied in V1.',
          );
        }
      }
    }

    final fallbackMatches = <NormalizedTripRecord>[];
    for (final existing in _existingTrips) {
      if (existing.tripDate == tripDate &&
          existing.plateNo == plateNo &&
          existing.fromLocation == fromLocation &&
          existing.toLocation == toLocation) {
        fallbackMatches.add(existing);
      }
    }

    if (fallbackMatches.length == 1) {
      return ImportMatchResult(
        status: ImportRowStatus.updatedNotApplied,
        matchedEntityId: fallbackMatches.first.id,
        note: 'Fallback match found. Update not auto-applied in V1.',
      );
    }

    if (fallbackMatches.length > 1) {
      return const ImportMatchResult(
        status: ImportRowStatus.needsReview,
        note: 'Multiple fallback matches. Manual review is required.',
      );
    }

    return const ImportMatchResult(status: ImportRowStatus.newRow);
  }
}
