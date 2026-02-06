import '../domain/entities/driver_entity.dart';

class DriverState {
  final bool isLoading;
  final String? error;
  final List<DriverEntity> drivers;
  final String search;
  final String status;

  const DriverState({
    required this.isLoading,
    required this.drivers,
    required this.search,
    required this.status,
    this.error,
  });

  factory DriverState.initial() {
    return const DriverState(
      isLoading: false,
      drivers: [],
      search: '',
      status: 'active',
    );
  }

  DriverState copyWith({
    bool? isLoading,
    List<DriverEntity>? drivers,
    String? search,
    String? status,
    String? error,
  }) {
    return DriverState(
      isLoading: isLoading ?? this.isLoading,
      drivers: drivers ?? this.drivers,
      search: search ?? this.search,
      status: status ?? this.status,
      error: error,
    );
  }
}
