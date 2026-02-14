import '../domain/entities/provider_entity.dart';

class ProviderState {
  final bool isLoading;
  final String? error;
  final List<ProviderEntity> providers;
  final String search;
  final String status;

  const ProviderState({
    required this.isLoading,
    required this.providers,
    required this.search,
    required this.status,
    this.error,
  });

  factory ProviderState.initial() {
    return const ProviderState(
      isLoading: false,
      providers: [],
      search: '',
      status: 'active',
    );
  }

  ProviderState copyWith({
    bool? isLoading,
    List<ProviderEntity>? providers,
    String? search,
    String? status,
    String? error,
  }) {
    return ProviderState(
      isLoading: isLoading ?? this.isLoading,
      providers: providers ?? this.providers,
      search: search ?? this.search,
      status: status ?? this.status,
      error: error,
    );
  }
}
