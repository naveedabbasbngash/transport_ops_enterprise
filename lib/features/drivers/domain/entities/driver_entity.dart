class DriverEntity {
  final String id;
  final String name;
  final String? phone;
  final String? residentId;
  final String driverType; // company | vendor
  final String? vendorId;
  final String? licenseNo;
  final String? licenseExpiry; // YYYY-MM-DD
  final String status; // active | inactive | blocked
  final String? notes;

  const DriverEntity({
    required this.id,
    required this.name,
    required this.driverType,
    required this.status,
    this.phone,
    this.residentId,
    this.vendorId,
    this.licenseNo,
    this.licenseExpiry,
    this.notes,
  });
}
