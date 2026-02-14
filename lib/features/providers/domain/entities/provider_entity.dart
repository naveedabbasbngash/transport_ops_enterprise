class ProviderEntity {
  final String id;
  final String name;
  final String status; // active | inactive
  final String type; // regular_vendor | spot_market_vendor
  final String? phone;
  final String? externalRef;
  final String? notes;

  const ProviderEntity({
    required this.id,
    required this.name,
    required this.status,
    required this.type,
    this.phone,
    this.externalRef,
    this.notes,
  });
}
