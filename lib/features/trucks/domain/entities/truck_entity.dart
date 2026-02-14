class TruckEntity {
  final String id;
  final String plateNo;
  final String? truckType;
  final String status; // active | inactive
  final String? color;
  final String? model;
  final String? makeYear;
  final String? registrationNumber;
  final String? registrationCardUrl;
  final String? ownership;
  final String? vendorId;
  final String? ownerName;
  final String? companyName;
  final String? notes;

  const TruckEntity({
    required this.id,
    required this.plateNo,
    required this.status,
    this.truckType,
    this.color,
    this.model,
    this.makeYear,
    this.registrationNumber,
    this.registrationCardUrl,
    this.ownership,
    this.vendorId,
    this.ownerName,
    this.companyName,
    this.notes,
  });
}
