import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_list_parser.dart';
import '../../auth/data/auth_local_source.dart';
import '../domain/entities/truck_entity.dart';
import '../domain/repositories/truck_repository.dart';
import 'truck_mapper.dart';

class TruckRepositoryImpl implements TruckRepository {
  final ApiClient _apiClient;

  const TruckRepositoryImpl(this._apiClient);

  @override
  Future<List<TruckEntity>> getTrucks({
    String? status,
    String? search,
  }) async {
    final companyId = await AuthLocalSource.getCompanyId();
    final response = await _apiClient.getJson(
      'trucks',
      query: {
        if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final items = extractListFromResponse(response);
    return items.map(truckFromApi).toList();
  }

  @override
  Future<TruckEntity> createTruck({
    required String plateNo,
    String? truckType,
    String? color,
    String? model,
    String? makeYear,
    String? registrationNumber,
    List<int>? registrationCardBytes,
    String? registrationCardFileName,
    String? ownership,
    String? vendorId,
    String? ownerName,
    String? companyName,
    String? notes,
  }) async {
    final companyId = await AuthLocalSource.getCompanyId();
    final body = {
      if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
      'plate_no': plateNo,
      if (truckType != null && truckType.isNotEmpty) 'truck_type': truckType,
      if (color != null && color.isNotEmpty) 'color': color,
      if (model != null && model.isNotEmpty) 'model': model,
      if (makeYear != null && makeYear.isNotEmpty) 'make_year': makeYear,
      if (registrationNumber != null && registrationNumber.isNotEmpty)
        'registration_number': registrationNumber,
      if (ownership != null && ownership.isNotEmpty) 'ownership': ownership,
      if (vendorId != null && vendorId.isNotEmpty) 'vendor_id': vendorId,
      if (ownerName != null && ownerName.isNotEmpty) 'owner_name': ownerName,
      if (companyName != null && companyName.isNotEmpty)
        'company_name': companyName,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    Map<String, dynamic> response;
    if (registrationCardBytes != null &&
        registrationCardBytes.isNotEmpty &&
        registrationCardFileName != null &&
        registrationCardFileName.isNotEmpty) {
      final multipart = http.MultipartFile.fromBytes(
        'registration_card',
        registrationCardBytes,
        filename: registrationCardFileName,
      );
      final raw = await _apiClient.postMultipart(
        'trucks',
        headers: const {'Accept': 'application/json'},
        fields: body.map((k, v) => MapEntry(k, v.toString())),
        files: [multipart],
      );
      response = _decodeBody(raw.body);
    } else {
      response = await _apiClient.postJson('trucks', body: body);
    }

    final items = extractListFromResponse(response);
    if (items.isNotEmpty) {
      return truckFromApi(items.first);
    }

    return truckFromApi({
      'id': '',
      'plate_no': plateNo,
      'truck_type': truckType,
      'status': 'active',
      'color': color,
      'model': model,
      'make_year': makeYear,
      'registration_number': registrationNumber,
      'registration_card_url': null,
      'ownership': ownership,
      'vendor_id': vendorId,
      'owner_name': ownerName,
      'company_name': companyName,
      'notes': notes,
    });
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
