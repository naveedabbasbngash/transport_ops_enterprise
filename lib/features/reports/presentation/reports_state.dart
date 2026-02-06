import 'package:flutter/material.dart';

import '../../trips/domain/entities/trip_entity.dart';
import '../domain/entities/report_models.dart';

enum ReportPeriod {
  today,
  day,
  month,
  range,
}

class ReportsState {
  final bool isLoading;
  final ReportPeriod period;
  final DateTime selectedDate;
  final DateTime selectedMonth;
  final DateTimeRange selectedRange;
  final String query;
  final String? selectedClient;
  final String? selectedPlate;
  final String? selectedRoute;
  final List<String> availableClients;
  final List<String> availablePlates;
  final List<String> availableRoutes;
  final List<TripEntity> filteredTrips;
  final ReportTotals todayTotals;
  final ReportTotals selectedDayTotals;
  final ReportTotals selectedMonthTotals;
  final ReportTotals filteredTotals;
  final MonthlyComparisonReport? monthlyReport;
  final ReportDataQuality dataQuality;
  final String? error;

  const ReportsState({
    required this.isLoading,
    required this.period,
    required this.selectedDate,
    required this.selectedMonth,
    required this.selectedRange,
    required this.query,
    this.selectedClient,
    this.selectedPlate,
    this.selectedRoute,
    this.availableClients = const <String>[],
    this.availablePlates = const <String>[],
    this.availableRoutes = const <String>[],
    this.filteredTrips = const <TripEntity>[],
    this.todayTotals = ReportTotals.zero,
    this.selectedDayTotals = ReportTotals.zero,
    this.selectedMonthTotals = ReportTotals.zero,
    this.filteredTotals = ReportTotals.zero,
    this.monthlyReport,
    this.dataQuality = ReportDataQuality.zero,
    this.error,
  });

  factory ReportsState.initial() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return ReportsState(
      isLoading: false,
      period: ReportPeriod.today,
      selectedDate: today,
      selectedMonth: DateTime(now.year, now.month, 1),
      selectedRange: DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      query: '',
    );
  }

  ReportsState copyWith({
    bool? isLoading,
    ReportPeriod? period,
    DateTime? selectedDate,
    DateTime? selectedMonth,
    DateTimeRange? selectedRange,
    String? query,
    Object? selectedClient = _sentinel,
    Object? selectedPlate = _sentinel,
    Object? selectedRoute = _sentinel,
    List<String>? availableClients,
    List<String>? availablePlates,
    List<String>? availableRoutes,
    List<TripEntity>? filteredTrips,
    ReportTotals? todayTotals,
    ReportTotals? selectedDayTotals,
    ReportTotals? selectedMonthTotals,
    ReportTotals? filteredTotals,
    Object? monthlyReport = _sentinel,
    ReportDataQuality? dataQuality,
    Object? error = _sentinel,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      period: period ?? this.period,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedRange: selectedRange ?? this.selectedRange,
      query: query ?? this.query,
      selectedClient: identical(selectedClient, _sentinel)
          ? this.selectedClient
          : selectedClient as String?,
      selectedPlate: identical(selectedPlate, _sentinel)
          ? this.selectedPlate
          : selectedPlate as String?,
      selectedRoute: identical(selectedRoute, _sentinel)
          ? this.selectedRoute
          : selectedRoute as String?,
      availableClients: availableClients ?? this.availableClients,
      availablePlates: availablePlates ?? this.availablePlates,
      availableRoutes: availableRoutes ?? this.availableRoutes,
      filteredTrips: filteredTrips ?? this.filteredTrips,
      todayTotals: todayTotals ?? this.todayTotals,
      selectedDayTotals: selectedDayTotals ?? this.selectedDayTotals,
      selectedMonthTotals: selectedMonthTotals ?? this.selectedMonthTotals,
      filteredTotals: filteredTotals ?? this.filteredTotals,
      monthlyReport: identical(monthlyReport, _sentinel)
          ? this.monthlyReport
          : monthlyReport as MonthlyComparisonReport?,
      dataQuality: dataQuality ?? this.dataQuality,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}
