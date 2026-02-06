import 'package:flutter_riverpod/legacy.dart';
import '../domain/repositories/driver_repository.dart';
import '../../../shared/providers/driver_repository_provider.dart';
import 'driver_state.dart';

class DriverViewModel extends StateNotifier<DriverState> {
  final DriverRepository _repository;

  DriverViewModel(this._repository) : super(DriverState.initial()) {
    loadDrivers();
  }

  Future<void> loadDrivers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final drivers = await _repository.getDrivers(
        status: state.status,
        search: state.search,
      );
      state = state.copyWith(isLoading: false, drivers: drivers, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load drivers.',
      );
    }
  }

  void updateSearch(String value) {
    state = state.copyWith(search: value);
  }

  void updateStatus(String value) {
    state = state.copyWith(status: value);
  }

  Future<void> applyFilters() async {
    await loadDrivers();
  }

  Future<void> createDriver({
    required String name,
    required String driverType,
    String? phone,
    String? residentId,
    String? vendorId,
    String? licenseNo,
    String? licenseExpiry,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createDriver(
        name: name,
        driverType: driverType,
        phone: phone,
        residentId: residentId,
        vendorId: vendorId,
        licenseNo: licenseNo,
        licenseExpiry: licenseExpiry,
        notes: notes,
      );
      await loadDrivers();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to create driver.',
      );
    }
  }
}

final driverViewModelProvider =
    StateNotifierProvider<DriverViewModel, DriverState>(
  (ref) => DriverViewModel(ref.watch(driverRepositoryProvider)),
);
