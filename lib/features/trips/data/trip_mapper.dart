import '../domain/entities/client_entity.dart';
import '../domain/entities/trip_entity.dart';
import '../domain/entities/vendor_entity.dart';

TripEntity tripFromApi(Map<String, dynamic> map) {
  final tripDateRaw = _string(map['trip_date']);
  final createdAtRaw = _string(map['created_at']);
  final parsedTripDate = _parseDate(tripDateRaw);
  final parsedCreatedAt = DateTime.tryParse(createdAtRaw)?.toUtc();
  final reportingMonth = _buildReportingMonth(
    parsedTripDate ?? parsedCreatedAt,
  );

  final client = _asMap(map['client']);
  final driver = _asMap(map['driver']);
  final truck = _asMap(map['truck']);
  final vendor = _asMap(map['vendor']);
  final tripFinancials = _asMap(map['trip_financials']);
  final rawWaybills = map['waybills'] is List
      ? (map['waybills'] as List)
      : const [];
  final waybills = rawWaybills
      .whereType<Map>()
      .map((raw) => raw.cast<String, dynamic>())
      .map(
        (raw) => TripWaybillFile(
          id: _string(raw['id']),
          fileName: _string(raw['file_name']),
          fileUrl: _string(raw['file_url']),
          mimeType: _string(raw['mime_type']),
          fileSize: _toInt(raw['file_size']),
          createdAt: DateTime.tryParse(_string(raw['created_at'])),
        ),
      )
      .toList();
  final waybillNo = _string(map['waybill_no']);
  final waybillCount = _toInt(map['waybill_count']);
  final hasWaybill =
      _toBool(map['has_waybill']) ||
      waybillCount > 0 ||
      waybills.isNotEmpty ||
      waybillNo.isNotEmpty;

  final plateNo = _firstNonEmpty([
    _string(map['plate_no']),
    _string(truck?['plate_no']),
  ]);
  final truckType = _firstNonEmpty([
    _string(map['truck_type']),
    _string(truck?['truck_type']),
  ]);
  final driverName = _firstNonEmpty([
    _string(map['driver_name']),
    _string(driver?['name']),
  ]);
  final driverPhone = _string(driver?['phone']);
  final driverResidentId = _string(driver?['resident_id']);
  final truckOwnerName = _string(truck?['owner_name']);
  final truckCompanyName = _string(truck?['company_name']);
  final truckModel = _string(truck?['model']);
  final truckColor = _string(truck?['color']);
  final truckMakeYear = _string(truck?['make_year']);
  final clientName = _firstNonEmpty([
    _string(map['client_name']),
    _string(client?['name']),
  ]);
  final vendorName = _firstNonEmpty([
    _string(map['vendor_name']),
    _string(vendor?['name']),
  ]);

  final normalizedTripDate = parsedTripDate != null
      ? '${parsedTripDate.year.toString().padLeft(4, '0')}-${parsedTripDate.month.toString().padLeft(2, '0')}-${parsedTripDate.day.toString().padLeft(2, '0')}'
      : tripDateRaw;

  return TripEntity(
    id: _string(map['id']),
    companyId: _stringOrNull(map['company_id']),
    clientId: _stringOrNull(map['client_id']),
    truckId: _stringOrNull(map['truck_id']),
    driverId: _stringOrNull(map['driver_id']),
    vendorId: _stringOrNull(map['vendor_id']),
    vendorName: vendorName,
    driverIqamaAttachment: _stringOrNull(driver?['iqama_attachment']),
    truckRegistrationCardUrl: _stringOrNull(truck?['registration_card_url']),
    status: _stringOrNull(map['status']),
    orderId: _stringOrNull(map['order_id']),
    source: _stringOrNull(map['source']),
    referenceNo: _stringOrNull(map['reference_no']),
    bookingNo: _stringOrNull(map['booking_no']),
    currency: _stringOrNull(map['currency'] ?? tripFinancials?['currency']),
    reportingMonth: reportingMonth,
    tripDate: normalizedTripDate,
    waybillNo: waybillNo,
    plateNo: plateNo,
    fromLocation: _string(map['from_location']),
    toLocation: _string(map['to_location']),
    clientName: clientName,
    vehicleType: truckType,
    driverName: driverName,
    driverPhone: driverPhone,
    driverResidentId: driverResidentId,
    truckOwnerName: truckOwnerName,
    truckCompanyName: truckCompanyName,
    truckModel: truckModel,
    truckColor: truckColor,
    truckMakeYear: truckMakeYear,
    tripAmount: _toDouble(
      map['trip_amount'] ??
          tripFinancials?['revenue_expected'] ??
          map['revenue_expected'],
    ),
    vendorCost: _toDouble(
      map['vendor_cost'] ??
          tripFinancials?['vendor_cost'] ??
          map['trip_rate_driver'],
    ),
    companyOtherCost: _toDouble(
      map['company_other_cost'] ?? tripFinancials?['company_other_cost'],
    ),
    remarks: _string(map['remarks']),
    hasWaybill: hasWaybill,
    waybillCount: waybillCount > 0 ? waybillCount : waybills.length,
    waybills: waybills,
    createdAt: parsedCreatedAt ?? DateTime.now().toUtc(),
  );
}

ClientEntity clientFromApi(Map<String, dynamic> map) {
  return ClientEntity(
    id: _string(map['id']),
    name: _string(map['name']),
    status: _string(map['status']).isEmpty ? 'active' : _string(map['status']),
  );
}

VendorEntity vendorFromApi(Map<String, dynamic> map) {
  return VendorEntity(
    id: _string(map['id']),
    name: _string(map['name']),
    status: _string(map['status']).isEmpty ? 'active' : _string(map['status']),
    type: _stringOrNull(map['type']),
  );
}

Map<String, dynamic> tripToLocalNormalized(TripEntity trip) {
  return <String, dynamic>{
    'trip_date': trip.tripDate,
    'reference_no': trip.referenceNo ?? '',
    'booking_no': trip.bookingNo ?? '',
    'waybill_no': trip.waybillNo,
    'plate_no': trip.plateNo,
    'from_location': trip.fromLocation,
    'to_location': trip.toLocation,
    'client_name': trip.clientName,
    'vehicle_type': trip.vehicleType,
    'driver_name': trip.driverName,
    'trip_amount': trip.tripAmount,
    'vendor_cost': trip.vendorCost,
    'company_other_cost': trip.companyOtherCost,
    'currency': trip.currency ?? 'SAR',
    'remarks': trip.remarks,
  };
}

DateTime? _parseDate(String raw) {
  if (raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) {
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
  return null;
}

String _buildReportingMonth(DateTime? date) {
  final source = date ?? DateTime.now();
  return '${source.year.toString().padLeft(4, '0')}-${source.month.toString().padLeft(2, '0')}';
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

String _string(Object? value) {
  return (value ?? '').toString().trim();
}

String? _stringOrNull(Object? value) {
  final data = _string(value);
  return data.isEmpty ? null : data;
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    if (value.isNotEmpty) return value;
  }
  return '';
}

double _toDouble(Object? value) {
  if (value == null) return 0;
  final cleaned = value.toString().replaceAll(RegExp(r'[^0-9.-]'), '');
  return double.tryParse(cleaned) ?? 0;
}

int _toInt(Object? value) {
  if (value == null) return 0;
  return int.tryParse(value.toString()) ?? 0;
}

bool _toBool(Object? value) {
  if (value is bool) return value;
  final raw = _string(value).toLowerCase();
  return raw == '1' || raw == 'true' || raw == 'yes';
}
