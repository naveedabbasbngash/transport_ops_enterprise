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
    String? ownership,
    String? vendorId,
    String? notes,
  }) async {
    final companyId = await AuthLocalSource.getCompanyId();
    final response = await _apiClient.postJson(
      'trucks',
      body: {
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
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

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
      'ownership': ownership,
      'vendor_id': vendorId,
      'notes': notes,
    });
  }
}
