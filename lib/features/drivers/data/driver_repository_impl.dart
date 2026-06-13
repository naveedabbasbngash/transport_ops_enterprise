import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_list_parser.dart';
import '../../auth/data/auth_local_source.dart';
import '../domain/entities/driver_entity.dart';
import '../domain/repositories/driver_repository.dart';
import 'driver_mapper.dart';

class DriverRepositoryImpl implements DriverRepository {
  final ApiClient _apiClient;

  const DriverRepositoryImpl(this._apiClient);

  @override
  Future<List<DriverEntity>> getDrivers({
    String? status,
    String? search,
  }) async {
    final companyId = await AuthLocalSource.getCompanyId();
    final response = await _apiClient.getJson(
      'drivers',
      query: {
        if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final items = extractListFromResponse(response);
    return items.map(driverFromApi).toList();
  }

  @override
  Future<DriverEntity> createDriver({
    required String name,
    required String phone,
    required String residentId,
    required List<int> iqamaBytes,
    required String iqamaFileName,
  }) async {
    final companyId = await AuthLocalSource.getCompanyId();
    final fields = <String, String>{
      if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
      'name': name,
      'driver_type': 'company',
      'phone': phone,
      'resident_id': residentId,
    };

    final iqamaFile = http.MultipartFile.fromBytes(
      'iqama_attachment',
      iqamaBytes,
      filename: iqamaFileName,
    );

    final response = await _apiClient.postMultipart(
      'drivers',
      fields: fields,
      files: [iqamaFile],
    );
    final decodedBody = _decodeBody(response.body);
    final data = decodedBody['data'];
    if (data is Map<String, dynamic>) return driverFromApi(data);
    if (data is Map) return driverFromApi(data.cast<String, dynamic>());

    try {
      final decoded = await _apiClient.getJson(
        'drivers',
        query: {
          if (companyId != null && companyId.isNotEmpty)
            'company_id': companyId,
          'search': name,
        },
      );
      final items = extractListFromResponse(decoded);
      if (items.isNotEmpty) {
        return driverFromApi(items.first);
      }
    } catch (_) {
      // ignore and fall back to optimistic result below
    }

    return driverFromApi({
      'id': '',
      'name': name,
      'driver_type': 'company',
      'phone': phone,
      'resident_id': residentId,
      'status': 'active',
    });
  }

  @override
  Future<DriverEntity> updateDriver({
    required String id,
    String? name,
    String? phone,
    String? residentId,
    String? driverType,
    String? status,
    String? vendorId,
    List<int>? iqamaBytes,
    String? iqamaFileName,
  }) async {
    final Map<String, String> body = {};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (residentId != null) body['resident_id'] = residentId;
    if (driverType != null) body['driver_type'] = driverType;
    if (status != null) body['status'] = status;
    if (vendorId != null) body['vendor_id'] = vendorId;

    // First PUT JSON for scalar fields
    Map<String, dynamic> response = await _apiClient.putJson(
      'drivers/$id',
      body: body,
    );

    // Optional iqama upload via dedicated endpoint
    if (iqamaBytes != null && iqamaFileName != null) {
      await _apiClient.postMultipart(
        'drivers/$id/iqama',
        headers: const {'Accept': 'application/json'},
        files: [
          http.MultipartFile.fromBytes(
            'iqama_attachment',
            iqamaBytes,
            filename: iqamaFileName,
          ),
        ],
      );
      // refresh driver detail after upload
      response = await _apiClient.getJson('drivers/$id');
    }

    final data = response['data'];
    if (data is Map<String, dynamic>) return driverFromApi(data);
    if (data is Map) return driverFromApi(data.cast<String, dynamic>());

    final items = extractListFromResponse(response);
    if (items.isNotEmpty) return driverFromApi(items.first);

    return driverFromApi({'id': id, 'name': name ?? '', 'status': status ?? ''});
  }

  @override
  Future<void> deleteDriver(String id) async {
    await _apiClient.deleteJson('drivers/$id');
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      final dynamic parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) return parsed;
      if (parsed is Map) return parsed.cast<String, dynamic>();
      return <String, dynamic>{'data': parsed};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
