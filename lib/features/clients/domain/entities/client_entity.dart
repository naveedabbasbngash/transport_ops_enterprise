class ClientEntity {
  final String id;
  final String name;
  final String status; // active | inactive
  final String? externalRef;

  const ClientEntity({
    required this.id,
    required this.name,
    required this.status,
    this.externalRef,
  });
}
