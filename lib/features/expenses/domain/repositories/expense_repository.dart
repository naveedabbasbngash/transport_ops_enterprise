import '../entities/expense_entity.dart';

abstract class ExpenseRepository {
  Future<List<ExpenseEntity>> getExpenses({
    int page = 1,
    String? driverId,
    String? truckId,
    String? driverName,
    String? plateNo,
    String? type,
    DateTime? fromDate,
    DateTime? toDate,
  });

  Future<ExpenseEntity?> getExpenseById(String id);

  Future<void> createExpense({
    required String expenseDate,
    required String type,
    required String amount,
    String? tripId,
    String? truckId,
    String? driverId,
    String? vendorId,
    String? notes,
  });

  Future<void> updateExpense({
    required String id,
    String? expenseDate,
    String? type,
    String? amount,
    String? notes,
  });

  Future<void> deleteExpense(String id);
}
