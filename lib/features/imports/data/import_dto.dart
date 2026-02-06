class NormalizedTripRecord {
  final String id;
  final String tripDate;
  final String waybillNo;
  final String plateNo;
  final String fromLocation;
  final String toLocation;

  const NormalizedTripRecord({
    required this.id,
    required this.tripDate,
    required this.waybillNo,
    required this.plateNo,
    required this.fromLocation,
    required this.toLocation,
  });
}
