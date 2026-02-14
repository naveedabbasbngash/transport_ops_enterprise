class CreateTripInput {
  final String clientId;
  final String? orderId;
  final String tripDate; // yyyy-MM-dd
  final String fromLocation;
  final String toLocation;
  final String plateNo;
  final String truckType;
  final String? referenceNo;
  final String? bookingNo;
  final String? waybillNo;
  final String? truckId;
  final String? driverId;
  final String? driverName;
  final String? vendorId;
  final String? source;
  final double revenueExpected;
  final double vendorCost;
  final double companyOtherCost;
  final String currency;
  final String? remarks;

  const CreateTripInput({
    required this.clientId,
    this.orderId,
    required this.tripDate,
    required this.fromLocation,
    required this.toLocation,
    required this.plateNo,
    required this.truckType,
    this.referenceNo,
    this.bookingNo,
    this.waybillNo,
    this.truckId,
    this.driverId,
    this.driverName,
    this.vendorId,
    this.source,
    this.revenueExpected = 0,
    this.vendorCost = 0,
    this.companyOtherCost = 0,
    this.currency = 'SAR',
    this.remarks,
  });
}
