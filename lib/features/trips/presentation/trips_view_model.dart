import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/trip_local_store.dart';
import '../data/trips_repository_impl.dart';
import '../domain/repositories/trips_repository.dart';
import '../domain/usecases/get_trips.dart';
import 'trips_state.dart';

final _tripLocalStoreProvider = Provider<TripLocalStore>((ref) {
  return TripLocalStore();
});

final _tripsRepositoryProvider = Provider<TripsRepository>((ref) {
  return TripsRepositoryImpl(
    tripLocalStore: ref.watch(_tripLocalStoreProvider),
  );
});

final _getTripsProvider = Provider<GetTrips>((ref) {
  return GetTrips(ref.watch(_tripsRepositoryProvider));
});

final tripsViewModelProvider = StateNotifierProvider<TripsViewModel, TripsState>(
  (ref) => TripsViewModel(
    getTrips: ref.watch(_getTripsProvider),
  ),
);

class TripsViewModel extends StateNotifier<TripsState> {
  TripsViewModel({
    required GetTrips getTrips,
  })  : _getTrips = getTrips,
        super(TripsState.initial()) {
    loadTrips();
  }

  final GetTrips _getTrips;

  Future<void> loadTrips() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final trips = await _getTrips(query: state.query);
      state = state.copyWith(
        isLoading: false,
        trips: trips,
        error: null,
      );
    } catch (e) {
      debugPrint('Failed to load trips: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load trips.',
      );
    }
  }

  Future<void> onQueryChanged(String value) async {
    state = state.copyWith(query: value);
    await loadTrips();
  }
}
