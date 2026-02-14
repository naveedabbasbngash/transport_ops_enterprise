class VendorEntity {
  final String id;
  final String name;
  final String status;
  final String? type;

  const VendorEntity({
    required this.id,
    required this.name,
    required this.status,
    this.type,
  });
}
