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
    required String driverType,
    String? phone,
    String? residentId,
    String? vendorId,
    String? licenseNo,
    String? licenseExpiry,
    String? notes,
  }) async {
    final companyId = await AuthLocalSource.getCompanyId();
    final fields = <String, String>{
      if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
      'name': name,
      'driver_type': driverType,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (residentId != null && residentId.isNotEmpty) 'resident_id': residentId,
      if (vendorId != null && vendorId.isNotEmpty) 'vendor_id': vendorId,
      if (licenseNo != null && licenseNo.isNotEmpty) 'license_no': licenseNo,
      if (licenseExpiry != null && licenseExpiry.isNotEmpty)
        'license_expiry': licenseExpiry,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _apiClient.postMultipart(
      'drivers',
      fields: fields,
    );

    if (response.body.isEmpty) {
      throw Exception('Driver creation failed with empty response.');
    }

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
      'driver_type': driverType,
      'phone': phone,
      'resident_id': residentId,
      'vendor_id': vendorId,
      'license_no': licenseNo,
      'license_expiry': licenseExpiry,
      'status': 'active',
      'notes': notes,
    });
  }
}
