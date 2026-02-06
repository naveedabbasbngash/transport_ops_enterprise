class TripEntity {
  final String id;
  final String reportingMonth; // yyyy-MM
  final String tripDate;
  final String waybillNo;
  final String plateNo;
  final String fromLocation;
  final String toLocation;
  final String clientName;
  final String vehicleType;
  final String driverName;
  final double tripAmount;
  final double vendorCost;
  final double companyOtherCost;
  final String remarks;
  final DateTime createdAt;

  const TripEntity({
    required this.id,
    required this.reportingMonth,
    required this.tripDate,
    required this.waybillNo,
    required this.plateNo,
    required this.fromLocation,
    required this.toLocation,
    required this.clientName,
    required this.vehicleType,
    required this.driverName,
    required this.tripAmount,
    required this.vendorCost,
    required this.companyOtherCost,
    required this.remarks,
    required this.createdAt,
  });

  double get profit => tripAmount - vendorCost - companyOtherCost;
}
