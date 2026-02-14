import '../domain/entities/dashboard_summary.dart';
import '../domain/entities/dashboard_period.dart';

class DashboardState {
  final bool isLoading;
  final DashboardPeriod period;
  final DashboardSummary? summary;
  final String? error;

  const DashboardState({
    required this.isLoading,
    required this.period,
    required this.summary,
    required this.error,
  });

  factory DashboardState.initial() {
    return const DashboardState(
      isLoading: false,
      period: DashboardPeriod.last30Days,
      summary: null,
      error: null,
    );
  }

  DashboardState copyWith({
    bool? isLoading,
    DashboardPeriod? period,
    DashboardSummary? summary,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      period: period ?? this.period,
      summary: summary ?? this.summary,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
