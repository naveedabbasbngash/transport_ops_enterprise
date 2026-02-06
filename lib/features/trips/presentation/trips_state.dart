import '../domain/entities/trip_entity.dart';

class TripsState {
  final bool isLoading;
  final List<TripEntity> trips;
  final String query;
  final String? error;

  const TripsState({
    required this.isLoading,
    this.trips = const [],
    this.query = '',
    this.error,
  });

  factory TripsState.initial() {
    return const TripsState(isLoading: false);
  }

  TripsState copyWith({
    bool? isLoading,
    List<TripEntity>? trips,
    String? query,
    Object? error = _sentinel,
  }) {
    return TripsState(
      isLoading: isLoading ?? this.isLoading,
      trips: trips ?? this.trips,
      query: query ?? this.query,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}
