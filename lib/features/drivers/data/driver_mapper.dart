import '../domain/entities/driver_entity.dart';

DriverEntity driverFromApi(Map<String, dynamic> map) {
  return DriverEntity(
    id: (map['id'] ?? '').toString(),
    name: (map['name'] ?? '').toString(),
    phone: map['phone']?.toString(),
    residentId: map['resident_id']?.toString(),
    driverType: (map['driver_type'] ?? '').toString(),
    vendorId: map['vendor_id']?.toString(),
    licenseNo: map['license_no']?.toString(),
    licenseExpiry: map['license_expiry']?.toString(),
    status: (map['status'] ?? '').toString(),
    notes: map['notes']?.toString(),
  );
}
