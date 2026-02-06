import 'package:flutter_riverpod/legacy.dart';

import '../../../shared/providers/expense_repository_provider.dart';
import '../../../core/logging/expense_log_buffer.dart';
import '../domain/entities/expense_entity.dart';
import '../domain/repositories/expense_repository.dart';
import 'expense_list_state.dart';

class ExpenseListViewModel extends StateNotifier<ExpenseListState> {
  final ExpenseRepository _repository;

  ExpenseListViewModel(this._repository) : super(ExpenseListState.initial()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final expenses = await _repository.getExpenses(
        driverId: state.driverId,
        truckId: state.truckId,
        driverName: (state.driverId == null || state.driverId!.isEmpty)
            ? state.driverName
            : null,
        plateNo: (state.truckId == null || state.truckId!.isEmpty)
            ? state.plateNo
            : null,
        type: state.type == 'all' ? null : state.type,
        fromDate: state.startDate,
        toDate: state.endDate,
      );
      state = state.copyWith(isLoading: false, expenses: expenses, error: null);
    } catch (e) {
      final message = _readError(e);
      ExpenseLogBuffer.add('ERROR: list expenses failed: $message');
      state = state.copyWith(
        isLoading: false,
        error: message,
      );
    }
  }

  void updateSearch(String value) {
    state = state.copyWith(search: value);
  }

  void updateType(String value) {
    state = state.copyWith(type: value);
  }

  void updateDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void updateTruck(String? truckId, String? plateNo) {
    if (truckId == null || truckId.isEmpty) {
      state = state.copyWith(truckId: null, plateNo: null);
      return;
    }
    state = state.copyWith(truckId: truckId, plateNo: plateNo?.trim());
  }

  void updateDriver(String? driverId, String? driverName) {
    if (driverId == null || driverId.isEmpty) {
      state = state.copyWith(driverId: null, driverName: null);
      return;
    }
    state = state.copyWith(driverId: driverId, driverName: driverName?.trim());
  }

  void updateDriverName(String? driverName) {
    final normalized = driverName?.trim();
    if (normalized == null || normalized.isEmpty) {
      state = state.copyWith(driverName: null, driverId: null);
      return;
    }
    if (state.driverId != null && state.driverId!.isNotEmpty) {
      if ((state.driverName ?? '').trim() == normalized) {
        state = state.copyWith(driverName: normalized);
        return;
      }
      state = state.copyWith(driverName: normalized, driverId: null);
      return;
    }
    state = state.copyWith(driverName: normalized);
  }

  void updatePlateNo(String? plateNo) {
    final normalized = plateNo?.trim();
    if (normalized == null || normalized.isEmpty) {
      state = state.copyWith(plateNo: null, truckId: null);
      return;
    }
    if (state.truckId != null && state.truckId!.isNotEmpty) {
      if ((state.plateNo ?? '').trim() == normalized) {
        state = state.copyWith(plateNo: normalized);
        return;
      }
      state = state.copyWith(plateNo: normalized, truckId: null);
      return;
    }
    state = state.copyWith(plateNo: normalized);
  }

  Future<void> applyFilters() async {
    await loadExpenses();
  }

  void clearFilters() {
    state = state.copyWith(
      search: '',
      type: 'all',
      startDate: null,
      endDate: null,
      truckId: null,
      driverId: null,
      driverName: null,
      plateNo: null,
      error: null,
    );
  }

  List<ExpenseEntity> get filtered {
    var results = state.expenses;

    if (state.type != 'all') {
      results = results.where((e) => e.type == state.type).toList();
    }

    if (state.driverId != null && state.driverId!.isNotEmpty) {
      results = results
          .where((e) => (e.driverId ?? '') == state.driverId)
          .toList();
    } else if (state.driverName != null && state.driverName!.trim().isNotEmpty) {
      final query = state.driverName!.trim().toLowerCase();
      results = results.where((e) {
        final noteDriver = _driverFromNotes(e.notes)?.toLowerCase();
        return noteDriver?.contains(query) == true;
      }).toList();
    }

    if (state.truckId != null && state.truckId!.isNotEmpty) {
      results =
          results.where((e) => (e.truckId ?? '') == state.truckId).toList();
    } else if (state.plateNo != null && state.plateNo!.trim().isNotEmpty) {
      // Fallback only if backend doesn't support plate_no filtering.
      // We can only match by truck_id locally, so leave as-is.
    }

    if (state.startDate != null || state.endDate != null) {
      final start = state.startDate;
      final end = state.endDate;
      results = results.where((e) {
        final parsed = _tryParseDate(e.expenseDate);
        if (parsed == null) return false;
        final afterStart = start == null || !parsed.isBefore(start);
        final beforeEnd = end == null || !parsed.isAfter(end);
        return afterStart && beforeEnd;
      }).toList();
    }
    return results;
  }
}

final expenseListViewModelProvider =
    StateNotifierProvider<ExpenseListViewModel, ExpenseListState>(
  (ref) => ExpenseListViewModel(ref.watch(expenseRepositoryProvider)),
);

String _readError(Object e) {
  final raw = e.toString();
  return raw.replaceFirst('Exception: ', '').trim();
}

DateTime? _tryParseDate(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final parsed = DateTime.tryParse(trimmed);
  if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);
  return null;
}

String? _driverFromNotes(String? notes) {
  if (notes == null || notes.isEmpty) return null;
  final lower = notes.toLowerCase();
  final marker = 'driver:';
  final index = lower.indexOf(marker);
  if (index == -1) return null;
  final raw = notes.substring(index + marker.length).trim();
  if (raw.isEmpty) return null;
  final stop = raw.indexOf('|');
  return stop == -1 ? raw.trim() : raw.substring(0, stop).trim();
}
