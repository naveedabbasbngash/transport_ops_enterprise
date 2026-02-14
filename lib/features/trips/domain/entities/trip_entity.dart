class TripWaybillFile {
  final String id;
  final String fileName;
  final String fileUrl;
  final String mimeType;
  final int fileSize;
  final DateTime? createdAt;

  const TripWaybillFile({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.mimeType,
    required this.fileSize,
    required this.createdAt,
  });
}

class TripEntity {
  final String id;
  final String? companyId;
  final String? clientId;
  final String? truckId;
  final String? driverId;
  final String? vendorId;
  final String vendorName;
  final String? driverIqamaAttachment;
  final String? truckRegistrationCardUrl;
  final String? status;
  final String? orderId;
  final String? source;
  final String? referenceNo;
  final String? bookingNo;
  final String? currency;
  final String reportingMonth; // yyyy-MM
  final String tripDate;
  final String waybillNo;
  final String plateNo;
  final String fromLocation;
  final String toLocation;
  final String clientName;
  final String vehicleType;
  final String driverName;
  final String driverPhone;
  final String driverResidentId;
  final String truckOwnerName;
  final String truckCompanyName;
  final String truckModel;
  final String truckColor;
  final String truckMakeYear;
  final double tripAmount;
  final double vendorCost;
  final double companyOtherCost;
  final String remarks;
  final bool hasWaybill;
  final int waybillCount;
  final List<TripWaybillFile> waybills;
  final DateTime createdAt;

  const TripEntity({
    required this.id,
    this.companyId,
    this.clientId,
    this.truckId,
    this.driverId,
    this.vendorId,
    this.vendorName = '',
    this.driverIqamaAttachment,
    this.truckRegistrationCardUrl,
    this.status,
    this.orderId,
    this.source,
    this.referenceNo,
    this.bookingNo,
    this.currency,
    required this.reportingMonth,
    required this.tripDate,
    required this.waybillNo,
    required this.plateNo,
    required this.fromLocation,
    required this.toLocation,
    required this.clientName,
    required this.vehicleType,
    required this.driverName,
    this.driverPhone = '',
    this.driverResidentId = '',
    this.truckOwnerName = '',
    this.truckCompanyName = '',
    this.truckModel = '',
    this.truckColor = '',
    this.truckMakeYear = '',
    required this.tripAmount,
    required this.vendorCost,
    required this.companyOtherCost,
    required this.remarks,
    required this.hasWaybill,
    required this.waybillCount,
    required this.waybills,
    required this.createdAt,
  });

  double get profit => tripAmount - vendorCost - companyOtherCost;
}
