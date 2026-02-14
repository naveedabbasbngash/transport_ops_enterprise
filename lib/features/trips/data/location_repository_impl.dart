import '../../../core/network/api_client.dart';
import '../../../core/network/api_list_parser.dart';
import '../domain/entities/location_entity.dart';
import '../domain/repositories/location_repository.dart';
import 'location_mapper.dart';

class LocationRepositoryImpl implements LocationRepository {
  final ApiClient _apiClient;

  const LocationRepositoryImpl(this._apiClient);

  @override
  Future<List<LocationEntity>> getLocations({
    String status = 'active',
    String search = '',
    int limit = 300,
  }) async {
    final response = await _apiClient.getJson(
      'locations',
      query: {
        if (status.isNotEmpty) 'status': status,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (limit > 0) 'limit': limit,
      },
    );
    final items = extractListFromResponse(response);
    return items.map(locationFromApi).toList();
  }

  @override
  Future<LocationEntity> createLocation({
    required String name,
    String status = 'active',
  }) async {
    final response = await _apiClient.postJson(
      'locations',
      body: {
        'name': name.trim(),
        if (status.isNotEmpty) 'status': status,
      },
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return locationFromApi(data);
    }
    if (data is Map) {
      return locationFromApi(data.cast<String, dynamic>());
    }
    return LocationEntity(id: '', name: name.trim(), status: status);
  }
}

