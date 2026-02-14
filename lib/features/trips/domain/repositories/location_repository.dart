import '../entities/location_entity.dart';

abstract class LocationRepository {
  Future<List<LocationEntity>> getLocations({
    String status = 'active',
    String search = '',
    int limit = 300,
  });

  Future<LocationEntity> createLocation({
    required String name,
    String status = 'active',
  });
}

