import '../../trips/data/trip_mapper.dart';
import '../domain/entities/order_entity.dart';

OrderEntity orderFromApi(Map<String, dynamic> map) {
  final client = _asMap(map['client']);
  final rawTrips = map['trips'] is List ? (map['trips'] as List) : const [];
  final trips = rawTrips
      .whereType<Map>()
      .map((raw) => raw.cast<String, dynamic>())
      .map(tripFromApi)
      .toList();

  return OrderEntity(
    id: _s(map['id']),
    clientId: _n(map['client_id']),
    clientName: _n(map['client_name']) ?? _n(client?['name']),
    fromLocation: _n(map['from_location']),
    toLocation: _n(map['to_location']),
    orderNo: _n(map['order_no']),
    status: _n(map['status']) ?? 'draft',
    orderDate: _normalizeDate(_n(map['order_date'])),
    notes: _n(map['notes']),
    revenueExpected: _d(map['revenue_expected']),
    vendorCost: _d(map['vendor_cost']),
    companyOtherCost: _d(map['company_other_cost']),
    currency: _n(map['currency']) ?? 'SAR',
    financialNotes: _n(map['financial_notes']),
    tripsCount: _i(map['trips_count']) > 0
        ? _i(map['trips_count'])
        : trips.length,
    trips: trips,
  );
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

String _s(Object? value) => (value ?? '').toString().trim();

String? _n(Object? value) {
  final v = _s(value);
  return v.isEmpty ? null : v;
}

int _i(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  final raw = value.toString().trim();
  if (raw.isEmpty) return 0;
  return int.tryParse(raw) ?? double.tryParse(raw)?.toInt() ?? 0;
}

double _d(Object? value) => double.tryParse((value ?? '').toString()) ?? 0;

String? _normalizeDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return raw;
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) {
    final simple = raw.split(' ').first;
    return simple;
  }
  return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
}
