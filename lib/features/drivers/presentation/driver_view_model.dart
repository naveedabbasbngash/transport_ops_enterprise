import 'package:flutter/foundation.dart';
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
    debugPrint('[DriverViewModel] load start');
    try {
      final drivers = await _repository.getDrivers(
        status: state.status,
        search: state.search,
      );
      state = state.copyWith(isLoading: false, drivers: drivers, error: null);
      debugPrint('[DriverViewModel] load ok count=${drivers.length}');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load drivers.',
      );
      debugPrint('[DriverViewModel] load failed $e');
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
    required String phone,
    required String residentId,
    required List<int> iqamaBytes,
    required String iqamaFileName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createDriver(
        name: name,
        phone: phone,
        residentId: residentId,
        iqamaBytes: iqamaBytes,
        iqamaFileName: iqamaFileName,
      );
      await loadDrivers();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to create driver.',
      );
    }
  }

  Future<void> updateDriver({
    required String id,
    String? name,
    String? phone,
    String? residentId,
    String? driverType,
    String? status,
    String? vendorId,
    List<int>? iqamaBytes,
    String? iqamaFileName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    debugPrint('[DriverViewModel] update start id=$id');
    try {
      await _repository.updateDriver(
        id: id,
        name: name,
        phone: phone,
        residentId: residentId,
        driverType: driverType,
        status: status,
        vendorId: vendorId,
        iqamaBytes: iqamaBytes,
        iqamaFileName: iqamaFileName,
      );
      await loadDrivers();
      debugPrint('[DriverViewModel] update ok id=$id');
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to update driver.',
      );
      debugPrint('[DriverViewModel] update failed id=$id');
    }
  }

  Future<void> deleteDriver(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    debugPrint('[DriverViewModel] delete start id=$id');
    try {
      await _repository.deleteDriver(id);
      await loadDrivers();
      debugPrint('[DriverViewModel] delete ok id=$id');
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to delete driver.',
      );
      debugPrint('[DriverViewModel] delete failed id=$id');
    }
  }
}

final driverViewModelProvider =
    StateNotifierProvider<DriverViewModel, DriverState>(
  (ref) => DriverViewModel(ref.watch(driverRepositoryProvider)),
);
