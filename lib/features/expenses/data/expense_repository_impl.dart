import 'dart:developer';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_list_parser.dart';
import '../../../core/logging/expense_log_buffer.dart';
import '../../auth/data/auth_local_source.dart';
import '../domain/entities/expense_entity.dart';
import '../domain/repositories/expense_repository.dart';
import 'expense_mapper.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ApiClient _apiClient;

  const ExpenseRepositoryImpl(this._apiClient);

  void _ensureSuccess(Map<String, dynamic> response, String context) {
    if (response.isEmpty) return;
    final status = response['status']?.toString();
    if (status != null && status.isNotEmpty && status != 'success') {
      final message = (response['message'] ?? 'Request failed').toString();
      ExpenseLogBuffer.add('ERROR $context: $message');
      throw Exception(message);
    }
  }

  @override
  @override
  Future<List<ExpenseEntity>> getExpenses({
    int page = 1,
    String? driverId,
    String? truckId,
    String? driverName,
    String? plateNo,
    String? type,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = <String, dynamic>{
      if (page > 1) 'page': page,
      if (driverId != null && driverId.isNotEmpty) 'driver_id': driverId,
      if (truckId != null && truckId.isNotEmpty) 'truck_id': truckId,
      if (driverName != null && driverName.isNotEmpty) 'driver_name': driverName,
      if (plateNo != null && plateNo.isNotEmpty) 'plate_no': plateNo,
      if (type != null && type.isNotEmpty) 'type': type,
      if (fromDate != null) 'from_date': _fmtDate(fromDate),
      if (toDate != null) 'to_date': _fmtDate(toDate),
    };

    log('EXPENSE list request', name: 'Expense', error: query);
    ExpenseLogBuffer.add('List expenses: $query');
    final response = await _apiClient.getJson(
      'expenses',
      query: query,
    );
    log('EXPENSE list response', name: 'Expense', error: response);
    ExpenseLogBuffer.add('List response: ${response['code'] ?? 'OK'}');
    _ensureSuccess(response, 'list');
    final items = extractListFromResponse(response);
    return items.map(expenseFromApi).toList();
  }

  @override
  Future<ExpenseEntity?> getExpenseById(String id) async {
    log('EXPENSE detail request', name: 'Expense', error: {'id': id});
    ExpenseLogBuffer.add('Get expense detail: $id');
    final response = await _apiClient.getJson('expenses/$id');
    log('EXPENSE detail response', name: 'Expense', error: response);
    ExpenseLogBuffer.add('Detail response: ${response['code'] ?? 'OK'}');
    _ensureSuccess(response, 'detail');
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return expenseFromApi(data);
    }
    if (data is Map) {
      return expenseFromApi(data.cast<String, dynamic>());
    }
    return null;
  }

  @override
  Future<void> createExpense({
    required String expenseDate,
    required String type,
    required String amount,
    String? tripId,
    String? truckId,
    String? driverId,
    String? vendorId,
    String? notes,
  }) async {
    final companyId = await AuthLocalSource.getCompanyId();
    final payload = <String, dynamic>{
      if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
      'expense_date': expenseDate,
      'type': type,
      'amount': amount,
      if (tripId != null && tripId.isNotEmpty) 'trip_id': tripId,
      if (truckId != null && truckId.isNotEmpty) 'truck_id': truckId,
      if (driverId != null && driverId.isNotEmpty) 'driver_id': driverId,
      if (vendorId != null && vendorId.isNotEmpty) 'vendor_id': vendorId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    log('EXPENSE create payload', name: 'Expense', error: payload);
    ExpenseLogBuffer.add('Create expense payload: $payload');
    final response = await _apiClient.postJson(
      'expenses',
      body: payload,
    );
    log('EXPENSE create response', name: 'Expense', error: response);
    ExpenseLogBuffer.add('Create response: ${response['code'] ?? 'OK'}');
    _ensureSuccess(response, 'create');
  }

  @override
  Future<void> updateExpense({
    required String id,
    String? expenseDate,
    String? type,
    String? amount,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      if (expenseDate != null && expenseDate.isNotEmpty)
        'expense_date': expenseDate,
      if (type != null && type.isNotEmpty) 'type': type,
      if (amount != null && amount.isNotEmpty) 'amount': amount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    log('EXPENSE update payload', name: 'Expense', error: {'id': id, ...payload});
    ExpenseLogBuffer.add('Update expense $id: $payload');
    final response = await _apiClient.putJson(
      'expenses/$id',
      body: payload,
    );
    _ensureSuccess(response, 'update');
    ExpenseLogBuffer.add('Update response: OK');
  }

  @override
  Future<void> deleteExpense(String id) async {
    log('EXPENSE delete request', name: 'Expense', error: {'id': id});
    ExpenseLogBuffer.add('Delete expense: $id');
    final response = await _apiClient.deleteJson('expenses/$id');
    _ensureSuccess(response, 'delete');
    ExpenseLogBuffer.add('Delete response: OK');
  }
}

String _fmtDate(DateTime date) {
  final yyyy = date.year.toString().padLeft(4, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd';
}
