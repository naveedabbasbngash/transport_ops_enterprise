import 'package:flutter_riverpod/legacy.dart';
import '../../../shared/providers/truck_repository_provider.dart';
import '../domain/repositories/truck_repository.dart';
import 'truck_state.dart';

class TruckViewModel extends StateNotifier<TruckState> {
  final TruckRepository _repository;

  TruckViewModel(this._repository) : super(TruckState.initial()) {
    loadTrucks();
  }

  Future<void> loadTrucks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final trucks = await _repository.getTrucks(
        status: state.status,
        search: state.search,
      );
      state = state.copyWith(isLoading: false, trucks: trucks, error: null);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load trucks.',
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
    await loadTrucks();
  }

  Future<void> createTruck({
    required String plateNo,
    String? truckType,
    String? color,
    String? model,
    String? makeYear,
    String? registrationNumber,
    List<int>? registrationCardBytes,
    String? registrationCardFileName,
    String? ownership,
    String? vendorId,
    String? ownerName,
    String? companyName,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createTruck(
        plateNo: plateNo,
        truckType: truckType,
        color: color,
        model: model,
        makeYear: makeYear,
        registrationNumber: registrationNumber,
        registrationCardBytes: registrationCardBytes,
        registrationCardFileName: registrationCardFileName,
        ownership: ownership,
        vendorId: vendorId,
        ownerName: ownerName,
        companyName: companyName,
        notes: notes,
      );
      await loadTrucks();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to create truck.',
      );
    }
  }
}

final truckViewModelProvider =
    StateNotifierProvider<TruckViewModel, TruckState>(
  (ref) => TruckViewModel(ref.watch(truckRepositoryProvider)),
);
