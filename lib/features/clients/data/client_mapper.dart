import '../domain/entities/client_entity.dart';

ClientEntity clientFromApi(Map<String, dynamic> map) {
  return ClientEntity(
    id: (map['id'] ?? '').toString(),
    name: (map['name'] ?? '').toString(),
    status: (map['status'] ?? 'active').toString(),
    externalRef: map['external_ref']?.toString(),
  );
}
