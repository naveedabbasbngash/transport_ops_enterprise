import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../shared/providers/api_client_provider.dart';
import '../data/trip_local_store.dart';
import '../data/trips_repository_impl.dart';
import '../domain/entities/client_entity.dart';
import '../domain/entities/create_trip_input.dart';
import '../domain/entities/trip_entity.dart';
import '../domain/entities/vendor_entity.dart';
import '../domain/repositories/trips_repository.dart';
import '../domain/usecases/get_trips.dart';
import 'trips_state.dart';

final _tripLocalStoreProvider = Provider<TripLocalStore>((ref) {
  return TripLocalStore();
});

final _tripsRepositoryProvider = Provider<TripsRepository>((ref) {
  return TripsRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    tripLocalStore: ref.watch(_tripLocalStoreProvider),
  );
});

final _getTripsProvider = Provider<GetTrips>((ref) {
  return GetTrips(ref.watch(_tripsRepositoryProvider));
});

final tripsViewModelProvider =
    StateNotifierProvider<TripsViewModel, TripsState>(
      (ref) => TripsViewModel(
        getTrips: ref.watch(_getTripsProvider),
        tripsRepository: ref.watch(_tripsRepositoryProvider),
      ),
    );

class TripsViewModel extends StateNotifier<TripsState> {
  TripsViewModel({
    required GetTrips getTrips,
    required TripsRepository tripsRepository,
  }) : _getTrips = getTrips,
       _tripsRepository = tripsRepository,
       super(TripsState.initial()) {
    loadTrips();
  }

  final GetTrips _getTrips;
  final TripsRepository _tripsRepository;

  Future<void> loadTrips() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final status = state.statusFilter == 'all' ? null : state.statusFilter;
      final trips = await _getTrips(
        query: state.query,
        status: status,
        missingWaybillOnly: state.missingWaybillOnly,
      );
      state = state.copyWith(isLoading: false, trips: trips, error: null);
    } catch (e) {
      debugPrint('Failed to load trips: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to load trips.');
    }
  }

  Future<void> onQueryChanged(String value) async {
    state = state.copyWith(query: value);
    await loadTrips();
  }

  Future<void> setStatusFilter(String value) async {
    state = state.copyWith(statusFilter: value);
    await loadTrips();
  }

  Future<void> setMissingWaybillOnly(bool value) async {
    state = state.copyWith(missingWaybillOnly: value);
    await loadTrips();
  }

  Future<List<ClientEntity>> getClients({
    String status = 'active',
    String search = '',
  }) {
    return _tripsRepository.getClients(status: status, search: search);
  }

  Future<List<VendorEntity>> getVendors({
    String status = 'active',
    String search = '',
  }) {
    return _tripsRepository.getVendors(status: status, search: search);
  }

  Future<TripEntity?> getTripById(String id) {
    return _tripsRepository.getTripById(id);
  }

  Future<bool> updateTripStatus({
    required String id,
    required String status,
  }) async {
    try {
      await _tripsRepository.updateTripStatus(id, status);
      await loadTrips();
      return true;
    } catch (e) {
      debugPrint('Failed to update trip status: $e');
      return false;
    }
  }

  Future<bool> uploadWaybill({
    required String tripId,
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      await _tripsRepository.uploadTripWaybill(
        tripId: tripId,
        bytes: bytes,
        fileName: fileName,
      );
      await loadTrips();
      return true;
    } catch (e) {
      debugPrint('Failed to upload waybill: $e');
      return false;
    }
  }

  Future<bool> deleteWaybill({
    required String tripId,
    required String fileId,
  }) async {
    try {
      await _tripsRepository.deleteTripWaybill(tripId: tripId, fileId: fileId);
      await loadTrips();
      return true;
    } catch (e) {
      debugPrint('Failed to delete waybill: $e');
      return false;
    }
  }

  Future<bool> createTrip(CreateTripInput input) async {
    state = state.copyWith(
      isSubmitting: true,
      error: null,
      successMessage: null,
    );
    try {
      await _tripsRepository.createTrip(input);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Trip created successfully.',
      );
      await loadTrips();
      return true;
    } catch (e) {
      debugPrint('Failed to create trip: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Unable to create trip.',
      );
      return false;
    }
  }

  Future<bool> updateTrip({
    required String id,
    required CreateTripInput input,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      error: null,
      successMessage: null,
    );
    try {
      await _tripsRepository.updateTrip(id, input);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Trip updated successfully.',
      );
      await loadTrips();
      return true;
    } catch (e) {
      debugPrint('Failed to update trip: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Unable to update trip.',
      );
      return false;
    }
  }

  Future<bool> deleteTrip(String id) async {
    if (id.trim().isEmpty) return false;
    state = state.copyWith(
      isSubmitting: true,
      error: null,
      successMessage: null,
    );
    try {
      await _tripsRepository.deleteTrip(id);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Trip deleted successfully.',
      );
      await loadTrips();
      return true;
    } catch (e) {
      debugPrint('Failed to delete trip: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Unable to delete trip.',
      );
      return false;
    }
  }
}
