import '../domain/entities/truck_entity.dart';

TruckEntity truckFromApi(Map<String, dynamic> map) {
  return TruckEntity(
    id: (map['id'] ?? '').toString(),
    plateNo: (map['plate_no'] ?? '').toString(),
    truckType: map['truck_type']?.toString(),
    status: (map['status'] ?? '').toString(),
    color: map['color']?.toString(),
    model: map['model']?.toString(),
    makeYear: map['make_year']?.toString(),
    registrationNumber: map['registration_number']?.toString(),
    ownership: map['ownership']?.toString(),
    vendorId: map['vendor_id']?.toString(),
    notes: map['notes']?.toString(),
  );
}
