import '../domain/entities/expense_entity.dart';

ExpenseEntity expenseFromApi(Map<String, dynamic> map) {
  final amountRaw = map['amount'];
  final amount = amountRaw is num
      ? amountRaw.toDouble()
      : double.tryParse(amountRaw?.toString() ?? '') ?? 0.0;
  return ExpenseEntity(
    id: (map['id'] ?? '').toString(),
    companyId: (map['company_id'] ?? '').toString(),
    expenseDate: (map['expense_date'] ?? '').toString(),
    type: (map['type'] ?? '').toString(),
    amount: amount,
    tripId: map['trip_id']?.toString(),
    truckId: map['truck_id']?.toString(),
    driverId: map['driver_id']?.toString(),
    vendorId: map['vendor_id']?.toString(),
    notes: map['notes']?.toString(),
    paidByUserId: map['paid_by_user_id']?.toString(),
    createdAt: map['created_at']?.toString(),
    updatedAt: map['updated_at']?.toString(),
  );
}
