import '../domain/entities/trip_entity.dart';

class TripsState {
  final bool isLoading;
  final bool isSubmitting;
  final List<TripEntity> trips;
  final String query;
  final String statusFilter;
  final bool missingWaybillOnly;
  final String? error;
  final String? successMessage;

  const TripsState({
    required this.isLoading,
    this.isSubmitting = false,
    this.trips = const [],
    this.query = '',
    this.statusFilter = 'all',
    this.missingWaybillOnly = false,
    this.error,
    this.successMessage,
  });

  factory TripsState.initial() {
    return const TripsState(isLoading: false);
  }

  TripsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<TripEntity>? trips,
    String? query,
    String? statusFilter,
    bool? missingWaybillOnly,
    Object? error = _sentinel,
    Object? successMessage = _sentinel,
  }) {
    return TripsState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      trips: trips ?? this.trips,
      query: query ?? this.query,
      statusFilter: statusFilter ?? this.statusFilter,
      missingWaybillOnly: missingWaybillOnly ?? this.missingWaybillOnly,
      error: identical(error, _sentinel) ? this.error : error as String?,
      successMessage: identical(successMessage, _sentinel)
          ? this.successMessage
          : successMessage as String?,
    );
  }

  static const _sentinel = Object();
}
