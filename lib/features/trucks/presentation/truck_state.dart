import '../domain/entities/truck_entity.dart';

class TruckState {
  final bool isLoading;
  final String? error;
  final List<TruckEntity> trucks;
  final String search;
  final String status;

  const TruckState({
    required this.isLoading,
    required this.trucks,
    required this.search,
    required this.status,
    this.error,
  });

  factory TruckState.initial() {
    return const TruckState(
      isLoading: false,
      trucks: [],
      search: '',
      status: 'active',
    );
  }

  TruckState copyWith({
    bool? isLoading,
    List<TruckEntity>? trucks,
    String? search,
    String? status,
    String? error,
  }) {
    return TruckState(
      isLoading: isLoading ?? this.isLoading,
      trucks: trucks ?? this.trucks,
      search: search ?? this.search,
      status: status ?? this.status,
      error: error,
    );
  }
}
