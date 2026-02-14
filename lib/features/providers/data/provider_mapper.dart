import '../domain/entities/provider_entity.dart';

ProviderEntity providerFromApi(Map<String, dynamic> map) {
  return ProviderEntity(
    id: (map['id'] ?? '').toString(),
    name: (map['name'] ?? '').toString(),
    status: (map['status'] ?? 'active').toString(),
    type: (map['type'] ?? 'regular_vendor').toString(),
    phone: map['phone']?.toString(),
    externalRef: map['external_ref']?.toString(),
    notes: map['notes']?.toString(),
  );
}
