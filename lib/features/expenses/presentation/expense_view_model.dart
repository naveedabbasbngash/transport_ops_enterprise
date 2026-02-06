import 'package:flutter_riverpod/legacy.dart';
import '../../../shared/providers/expense_repository_provider.dart';
import '../../../core/logging/expense_log_buffer.dart';
import '../domain/repositories/expense_repository.dart';
import 'expense_state.dart';

class ExpenseViewModel extends StateNotifier<ExpenseState> {
  final ExpenseRepository _repository;

  ExpenseViewModel(this._repository) : super(ExpenseState.initial());

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
    state = state.copyWith(isSubmitting: true, success: false, error: null);
    try {
      await _repository.createExpense(
        expenseDate: expenseDate,
        type: type,
        amount: amount,
        tripId: tripId,
        truckId: truckId,
        driverId: driverId,
        vendorId: vendorId,
        notes: notes,
      );
      state = state.copyWith(isSubmitting: false, success: true, error: null);
    } catch (e) {
      final message = _readError(e);
      ExpenseLogBuffer.add('ERROR: create expense failed: $message');
      state = state.copyWith(
        isSubmitting: false,
        success: false,
        error: message,
      );
    }
  }

  Future<void> updateExpense({
    required String id,
    String? expenseDate,
    String? type,
    String? amount,
    String? notes,
  }) async {
    state = state.copyWith(isSubmitting: true, success: false, error: null);
    try {
      await _repository.updateExpense(
        id: id,
        expenseDate: expenseDate,
        type: type,
        amount: amount,
        notes: notes,
      );
      state = state.copyWith(isSubmitting: false, success: true, error: null);
    } catch (e) {
      final message = _readError(e);
      ExpenseLogBuffer.add('ERROR: update expense failed: $message');
      state = state.copyWith(
        isSubmitting: false,
        success: false,
        error: message,
      );
    }
  }

  Future<void> deleteExpense(String id) async {
    state = state.copyWith(isSubmitting: true, success: false, error: null);
    try {
      await _repository.deleteExpense(id);
      state = state.copyWith(isSubmitting: false, success: true, error: null);
    } catch (e) {
      final message = _readError(e);
      ExpenseLogBuffer.add('ERROR: delete expense failed: $message');
      state = state.copyWith(
        isSubmitting: false,
        success: false,
        error: message,
      );
    }
  }
}

String _readError(Object e) {
  final raw = e.toString();
  return raw.replaceFirst('Exception: ', '').trim();
}

final expenseViewModelProvider =
    StateNotifierProvider<ExpenseViewModel, ExpenseState>(
  (ref) => ExpenseViewModel(ref.watch(expenseRepositoryProvider)),
);
