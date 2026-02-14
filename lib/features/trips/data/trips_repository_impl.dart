import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_list_parser.dart';
import '../../auth/data/auth_local_source.dart';
import 'package:http/http.dart' as http;
import '../domain/entities/client_entity.dart';
import '../domain/entities/create_trip_input.dart';
import '../domain/entities/trip_entity.dart';
import '../domain/entities/vendor_entity.dart';
import '../domain/repositories/trips_repository.dart';
import 'trip_mapper.dart';
import 'trip_local_store.dart';

class TripsRepositoryImpl implements TripsRepository {
  final ApiClient _apiClient;
  final TripLocalStore _tripLocalStore;

  const TripsRepositoryImpl({
    required ApiClient apiClient,
    required TripLocalStore tripLocalStore,
  }) : _apiClient = apiClient,
       _tripLocalStore = tripLocalStore;

  @override
  Future<List<TripEntity>> getTrips({
    String query = '',
    String? status,
    bool missingWaybillOnly = false,
  }) async {
    final companyId = await AuthLocalSource.getCompanyId();
    try {
      final response = await _apiClient.getJson(
        'trips',
        query: {
          if (companyId != null && companyId.isNotEmpty)
            'company_id': companyId,
          if (query.trim().isNotEmpty) 'search': query.trim(),
          if (status != null && status.trim().isNotEmpty)
            'status': status.trim(),
          if (missingWaybillOnly) 'missing_waybill_only': 1,
        },
      );
      final items = extractListFromResponse(response);
      if (items.isEmpty) {
        return _tripLocalStore.getTrips(query: query);
      }

      return items.map(tripFromApi).toList();
    } catch (_) {
      return _tripLocalStore.getTrips(query: query);
    }
  }

  @override
  Future<TripEntity?> getTripById(String id) async {
    if (id.trim().isEmpty) return null;
    final response = await _apiClient.getJson('trips/$id');
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return tripFromApi(data);
    }
    if (data is Map) {
      return tripFromApi(data.cast<String, dynamic>());
    }
    final items = extractListFromResponse(response);
    if (items.isNotEmpty) return tripFromApi(items.first);
    return null;
  }

  @override
  Future<List<ClientEntity>> getClients({
    String status = 'active',
    String search = '',
  }) async {
    final companyId = await AuthLocalSource.getCompanyId();
    final response = await _apiClient.getJson(
      'clients',
      query: {
        if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
        if (status.isNotEmpty) 'status': status,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final items = extractListFromResponse(response);
    return items.map(clientFromApi).toList();
  }

  @override
  Future<List<VendorEntity>> getVendors({
    String status = 'active',
    String search = '',
  }) async {
    final companyId = await AuthLocalSource.getCompanyId();
    final response = await _apiClient.getJson(
      'vendors',
      query: {
        if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
        if (status.isNotEmpty) 'status': status,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final items = extractListFromResponse(response);
    return items.map(vendorFromApi).toList();
  }

  @override
  Future<TripEntity> createTrip(CreateTripInput input) async {
    final companyId = await AuthLocalSource.getCompanyId();
    final response = await _apiClient.postJson(
      'trips',
      body: {
        if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
        'client_id': input.clientId,
        if (input.orderId != null && input.orderId!.isNotEmpty)
          'order_id': input.orderId,
        'trip_date': input.tripDate,
        if (input.referenceNo != null && input.referenceNo!.isNotEmpty)
          'reference_no': input.referenceNo,
        if (input.bookingNo != null && input.bookingNo!.isNotEmpty)
          'booking_no': input.bookingNo,
        if (input.waybillNo != null && input.waybillNo!.isNotEmpty)
          'waybill_no': input.waybillNo,
        'from_location': input.fromLocation,
        'to_location': input.toLocation,
        'truck_type': input.truckType,
        'plate_no': input.plateNo,
        if (input.truckId != null && input.truckId!.isNotEmpty)
          'truck_id': input.truckId,
        if (input.driverId != null && input.driverId!.isNotEmpty)
          'driver_id': input.driverId,
        if (input.driverName != null && input.driverName!.isNotEmpty)
          'driver_name': input.driverName,
        if (input.vendorId != null && input.vendorId!.isNotEmpty)
          'vendor_id': input.vendorId,
        if (input.source != null && input.source!.isNotEmpty)
          'source': input.source,
        if (input.remarks != null && input.remarks!.isNotEmpty)
          'remarks': input.remarks,
        'revenue_expected': input.revenueExpected,
        'vendor_cost': input.vendorCost,
        'company_other_cost': input.companyOtherCost,
        'currency': input.currency,
        'trip_financials': {
          'revenue_expected': input.revenueExpected,
          'vendor_cost': input.vendorCost,
          'company_other_cost': input.companyOtherCost,
          'currency': input.currency,
          if (input.remarks != null && input.remarks!.isNotEmpty)
            'remarks': input.remarks,
        },
      },
    );

    final items = extractListFromResponse(response);
    final created = items.isNotEmpty
        ? tripFromApi(items.first)
        : TripEntity(
            id: '',
            companyId: companyId,
            clientId: input.clientId,
            orderId: input.orderId,
            truckId: input.truckId,
            driverId: input.driverId,
            vendorId: input.vendorId,
            driverIqamaAttachment: null,
            truckRegistrationCardUrl: null,
            status: 'open',
            source: input.source ?? 'other',
            referenceNo: input.referenceNo,
            bookingNo: input.bookingNo,
            currency: input.currency,
            reportingMonth: input.tripDate.substring(0, 7),
            tripDate: input.tripDate,
            waybillNo: input.waybillNo ?? '',
            plateNo: input.plateNo,
            fromLocation: input.fromLocation,
            toLocation: input.toLocation,
            clientName: '',
            vehicleType: input.truckType,
            driverName: input.driverName ?? '',
            tripAmount: input.revenueExpected,
            vendorCost: input.vendorCost,
            companyOtherCost: input.companyOtherCost,
            remarks: input.remarks ?? '',
            hasWaybill: (input.waybillNo ?? '').trim().isNotEmpty,
            waybillCount: 0,
            waybills: const [],
            createdAt: DateTime.now().toUtc(),
          );

    if (created.id.isNotEmpty) {
      await _upsertTripFinancials(created.id, input);
    }

    final month =
        DateTime.tryParse('${created.tripDate}T00:00:00') ??
        DateTime.now().toUtc();
    await _tripLocalStore.upsertFromNormalized(
      tripToLocalNormalized(created),
      reportingMonth: DateTime(month.year, month.month),
    );

    return created;
  }

  @override
  Future<TripEntity> updateTrip(String id, CreateTripInput input) async {
    final response = await _apiClient.putJson(
      'trips/$id',
      body: {
        'client_id': input.clientId,
        if (input.orderId != null && input.orderId!.isNotEmpty)
          'order_id': input.orderId,
        'trip_date': input.tripDate,
        if (input.referenceNo != null && input.referenceNo!.isNotEmpty)
          'reference_no': input.referenceNo,
        if (input.bookingNo != null && input.bookingNo!.isNotEmpty)
          'booking_no': input.bookingNo,
        if (input.waybillNo != null && input.waybillNo!.isNotEmpty)
          'waybill_no': input.waybillNo,
        'from_location': input.fromLocation,
        'to_location': input.toLocation,
        'truck_type': input.truckType,
        'plate_no': input.plateNo,
        if (input.truckId != null && input.truckId!.isNotEmpty)
          'truck_id': input.truckId,
        if (input.driverId != null && input.driverId!.isNotEmpty)
          'driver_id': input.driverId,
        if (input.driverName != null && input.driverName!.isNotEmpty)
          'driver_name': input.driverName,
        if (input.vendorId != null && input.vendorId!.isNotEmpty)
          'vendor_id': input.vendorId,
        if (input.source != null && input.source!.isNotEmpty)
          'source': input.source,
        if (input.remarks != null && input.remarks!.isNotEmpty)
          'remarks': input.remarks,
      },
    );

    final data = response['data'];
    final updated = data is Map<String, dynamic>
        ? tripFromApi(data)
        : (data is Map
              ? tripFromApi(data.cast<String, dynamic>())
              : TripEntity(
                  id: id,
                  clientId: input.clientId,
                  orderId: input.orderId,
                  truckId: input.truckId,
                  driverId: input.driverId,
                  vendorId: input.vendorId,
                  driverIqamaAttachment: null,
                  truckRegistrationCardUrl: null,
                  source: input.source ?? 'other',
                  referenceNo: input.referenceNo,
                  bookingNo: input.bookingNo,
                  currency: input.currency,
                  reportingMonth: input.tripDate.substring(0, 7),
                  tripDate: input.tripDate,
                  waybillNo: input.waybillNo ?? '',
                  plateNo: input.plateNo,
                  fromLocation: input.fromLocation,
                  toLocation: input.toLocation,
                  clientName: '',
                  vehicleType: input.truckType,
                  driverName: input.driverName ?? '',
                  tripAmount: input.revenueExpected,
                  vendorCost: input.vendorCost,
                  companyOtherCost: input.companyOtherCost,
                  remarks: input.remarks ?? '',
                  hasWaybill: (input.waybillNo ?? '').trim().isNotEmpty,
                  waybillCount: 0,
                  waybills: const [],
                  createdAt: DateTime.now().toUtc(),
                ));

    await _upsertTripFinancials(id, input);

    final month =
        DateTime.tryParse('${updated.tripDate}T00:00:00') ??
        DateTime.now().toUtc();
    await _tripLocalStore.upsertFromNormalized(
      tripToLocalNormalized(updated),
      reportingMonth: DateTime(month.year, month.month),
    );

    return updated;
  }

  Future<void> _upsertTripFinancials(
    String tripId,
    CreateTripInput input,
  ) async {
    final body = <String, dynamic>{
      'trip_id': tripId,
      'revenue_expected': input.revenueExpected,
      'vendor_cost': input.vendorCost,
      'company_other_cost': input.companyOtherCost,
      'profit_expected':
          input.revenueExpected - input.vendorCost - input.companyOtherCost,
      'currency': input.currency,
      if (input.remarks != null && input.remarks!.isNotEmpty)
        'remarks': input.remarks,
    };

    try {
      await _apiClient.postJson('trip-financials', body: body);
      return;
    } catch (_) {
      // fallback endpoints for varying backend conventions
    }

    try {
      await _apiClient.postJson('trip_financials', body: body);
      return;
    } catch (_) {}

    try {
      await _apiClient.putJson('trip-financials/$tripId', body: body);
      return;
    } catch (_) {}

    await _apiClient.putJson('trip_financials/$tripId', body: body);
  }

  @override
  Future<TripEntity> updateTripStatus(String id, String status) async {
    final response = await _apiClient.putJson(
      'trips/$id',
      body: {'status': status},
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) return tripFromApi(data);
    if (data is Map) return tripFromApi(data.cast<String, dynamic>());
    throw Exception('Invalid update status response');
  }

  @override
  Future<void> deleteTrip(String id) async {
    if (id.trim().isEmpty) return;
    await _apiClient.deleteJson('trips/$id');
  }

  @override
  Future<TripWaybillFile> uploadTripWaybill({
    required String tripId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final file = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    );
    final response = await _apiClient.postMultipart(
      'trips/$tripId/waybills',
      headers: const {'Accept': 'application/json'},
      files: [file],
    );

    final decoded = extractListFromResponse(_decodeBody(response.body));
    if (decoded.isNotEmpty) {
      final map = decoded.first;
      return TripWaybillFile(
        id: map['id']?.toString() ?? '',
        fileName: map['file_name']?.toString() ?? fileName,
        fileUrl: map['file_url']?.toString() ?? '',
        mimeType: map['mime_type']?.toString() ?? '',
        fileSize: int.tryParse(map['file_size']?.toString() ?? '') ?? 0,
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      );
    }

    final data = _decodeBody(response.body)['data'];
    final map = data is Map
        ? data.cast<String, dynamic>()
        : <String, dynamic>{};
    return TripWaybillFile(
      id: map['id']?.toString() ?? '',
      fileName: map['file_name']?.toString() ?? fileName,
      fileUrl: map['file_url']?.toString() ?? '',
      mimeType: map['mime_type']?.toString() ?? '',
      fileSize: int.tryParse(map['file_size']?.toString() ?? '') ?? 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }

  @override
  Future<void> deleteTripWaybill({
    required String tripId,
    required String fileId,
  }) async {
    await _apiClient.deleteJson('trips/$tripId/waybills/$fileId');
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      final value = body;
      final dynamic parsed = value.isNotEmpty
          ? jsonDecode(value)
          : <String, dynamic>{};
      if (parsed is Map<String, dynamic>) return parsed;
      if (parsed is Map) return parsed.cast<String, dynamic>();
      return <String, dynamic>{'data': parsed};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
