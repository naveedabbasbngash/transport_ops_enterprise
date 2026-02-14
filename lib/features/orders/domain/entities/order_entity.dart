import '../../../trips/domain/entities/trip_entity.dart';

class OrderEntity {
  final String id;
  final String? clientId;
  final String? clientName;
  final String? fromLocation;
  final String? toLocation;
  final String? orderNo;
  final String status;
  final String? orderDate;
  final String? notes;
  final double revenueExpected;
  final double vendorCost;
  final double companyOtherCost;
  final String currency;
  final String? financialNotes;
  final int tripsCount;
  final List<TripEntity> trips;

  const OrderEntity({
    required this.id,
    this.clientId,
    this.clientName,
    this.fromLocation,
    this.toLocation,
    this.orderNo,
    required this.status,
    this.orderDate,
    this.notes,
    this.revenueExpected = 0,
    this.vendorCost = 0,
    this.companyOtherCost = 0,
    this.currency = 'SAR',
    this.financialNotes,
    this.tripsCount = 0,
    this.trips = const [],
  });
}
