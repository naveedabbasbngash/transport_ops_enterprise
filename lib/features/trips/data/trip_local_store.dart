import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

import '../domain/entities/trip_entity.dart';

class TripLocalStore {
  TripLocalStore();

  static const _dbName = 'transport_ops_trips.db';
  static const _storeName = 'trips';
  final _tripsStore = stringMapStoreFactory.store(_storeName);
  Database? _db;

  Future<void> upsertFromNormalized(
    Map<String, dynamic> normalized, {
    required DateTime reportingMonth,
  }) async {
    final db = await _database;
    final tripDate = _read(normalized, 'trip_date');
    final waybillNo = _read(normalized, 'waybill_no');
    final plateNo = _read(normalized, 'plate_no');
    final fromLocation = _read(normalized, 'from_location');
    final toLocation = _read(normalized, 'to_location');
    final uniqueId = _buildId(
      tripDate: tripDate,
      waybillNo: waybillNo,
      plateNo: plateNo,
      fromLocation: fromLocation,
      toLocation: toLocation,
    );

    await _tripsStore.record(uniqueId).put(db, <String, dynamic>{
      'id': uniqueId,
      'tripDate': tripDate,
      'waybillNo': waybillNo,
      'plateNo': plateNo,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'clientName': _read(normalized, 'client_name'),
      'vehicleType': _read(normalized, 'vehicle_type'),
      'driverName': _read(normalized, 'driver_name'),
      'tripAmount': _toDouble(normalized['trip_amount']),
      'vendorCost': _toDouble(normalized['vendor_cost']),
      'companyOtherCost': _toDouble(normalized['company_other_cost']),
      'remarks': _read(normalized, 'remarks'),
      'reportingMonth': '${reportingMonth.year.toString().padLeft(4, '0')}-${reportingMonth.month.toString().padLeft(2, '0')}',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<TripEntity>> getTrips({
    String query = '',
  }) async {
    final db = await _database;
    final snapshots = await _tripsStore.find(
      db,
      finder: Finder(sortOrders: [SortOrder('tripDate', false)]),
    );

    final lowerQuery = query.trim().toLowerCase();
    final result = <TripEntity>[];
    for (final snapshot in snapshots) {
      final entity = _fromMap(snapshot.value);
      if (lowerQuery.isNotEmpty && !_matches(entity, lowerQuery)) continue;
      result.add(entity);
    }
    return result;
  }

  Future<Database> get _database async {
    final cached = _db;
    if (cached != null) return cached;

    if (kIsWeb) {
      _db = await databaseFactoryWeb.openDatabase(_dbName);
      return _db!;
    }

    final dir = await getApplicationDocumentsDirectory();
    _db = await databaseFactoryIo.openDatabase(p.join(dir.path, _dbName));
    return _db!;
  }

  TripEntity _fromMap(Map<String, dynamic> map) {
    final reportingMonth = (map['reportingMonth'] ?? '').toString().trim();
    final derivedReportingMonth = _deriveReportingMonth(
      tripDate: (map['tripDate'] ?? '').toString(),
      fallbackCreatedAt: (map['createdAt'] ?? '').toString(),
    );

    return TripEntity(
      id: (map['id'] ?? '').toString(),
      reportingMonth:
          reportingMonth.isNotEmpty ? reportingMonth : derivedReportingMonth,
      tripDate: (map['tripDate'] ?? '').toString(),
      waybillNo: (map['waybillNo'] ?? '').toString(),
      plateNo: (map['plateNo'] ?? '').toString(),
      fromLocation: (map['fromLocation'] ?? '').toString(),
      toLocation: (map['toLocation'] ?? '').toString(),
      clientName: (map['clientName'] ?? '').toString(),
      vehicleType: (map['vehicleType'] ?? '').toString(),
      driverName: (map['driverName'] ?? '').toString(),
      tripAmount: _toDouble(map['tripAmount']),
      vendorCost: _toDouble(map['vendorCost']),
      companyOtherCost: _toDouble(map['companyOtherCost']),
      remarks: (map['remarks'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now().toUtc(),
    );
  }

  String _buildId({
    required String tripDate,
    required String waybillNo,
    required String plateNo,
    required String fromLocation,
    required String toLocation,
  }) {
    if (waybillNo.isNotEmpty) {
      return '${tripDate}_${waybillNo}_$plateNo';
    }
    return '${tripDate}_${plateNo}_${fromLocation}_$toLocation';
  }

  bool _matches(TripEntity entity, String query) {
    final haystack = [
      entity.clientName,
      entity.tripDate,
      entity.waybillNo,
      entity.plateNo,
      entity.fromLocation,
      entity.toLocation,
      entity.driverName,
      entity.vehicleType,
    ].join(' ').toLowerCase();

    return haystack.contains(query);
  }

  String _read(Map<String, dynamic> map, String key) {
    return (map[key] ?? '').toString().trim();
  }

  double _toDouble(Object? value) {
    if (value == null) return 0;
    final cleaned = value.toString().replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  String _deriveReportingMonth({
    required String tripDate,
    required String fallbackCreatedAt,
  }) {
    final parsed = _parseTripDateToDateOnly(tripDate);
    if (parsed != null) {
      return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}';
    }

    final created = DateTime.tryParse(fallbackCreatedAt) ?? DateTime.now();
    return '${created.year.toString().padLeft(4, '0')}-${created.month.toString().padLeft(2, '0')}';
  }

  DateTime? _parseTripDateToDateOnly(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);

    final normalized = trimmed.replaceAll('/', '-');
    final parts = normalized.split('-');
    if (parts.length != 3) return null;

    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    final third = int.tryParse(parts[2]);
    if (first == null || second == null || third == null) return null;

    // Default to dd-MM-yyyy for legacy entries without explicit reporting month.
    if (third >= 1900 && second >= 1 && second <= 12 && first >= 1 && first <= 31) {
      return DateTime(third, second, first);
    }

    if (third >= 1900 && first >= 1 && first <= 12 && second >= 1 && second <= 31) {
      return DateTime(third, first, second);
    }

    return null;
  }
}
