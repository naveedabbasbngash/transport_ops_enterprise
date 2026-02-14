import '../domain/entities/location_entity.dart';

LocationEntity locationFromApi(Map<String, dynamic> json) {
  return LocationEntity(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    status: (json['status'] ?? 'active').toString(),
  );
}

