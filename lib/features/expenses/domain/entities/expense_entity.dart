class ExpenseEntity {
  final String id;
  final String companyId;
  final String expenseDate; // YYYY-MM-DD
  final String type;
  final double amount;
  final String? tripId;
  final String? truckId;
  final String? driverId;
  final String? vendorId;
  final String? notes;
  final String? paidByUserId;
  final String? createdAt;
  final String? updatedAt;

  const ExpenseEntity({
    required this.id,
    required this.companyId,
    required this.expenseDate,
    required this.type,
    required this.amount,
    this.tripId,
    this.truckId,
    this.driverId,
    this.vendorId,
    this.notes,
    this.paidByUserId,
    this.createdAt,
    this.updatedAt,
  });
}
