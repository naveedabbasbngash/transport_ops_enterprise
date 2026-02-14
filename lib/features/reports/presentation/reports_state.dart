import 'package:flutter/material.dart';

import '../domain/entities/expense_report_models.dart';

enum ExpenseReportPeriod {
  day,
  week,
  month,
  range,
}

class ReportsState {
  final bool isLoading;
  final ExpenseReportPeriod period;
  final DateTime selectedDay;
  final DateTime selectedWeekAnchor;
  final DateTime selectedMonth;
  final DateTimeRange selectedRange;
  final String? selectedDriverId;
  final String? selectedTruckId;
  final String? selectedVendorId;
  final String? selectedClientId;
  final String? selectedType;
  final List<ExpenseReportOption> drivers;
  final List<ExpenseReportOption> trucks;
  final List<ExpenseReportOption> vendors;
  final List<ExpenseReportOption> clients;
  final List<ExpenseReportItem> items;
  final ExpenseReportTotals totals;
  final BusinessKpis kpis;
  final List<StatusRow> tripsByStatus;
  final List<ExpenseReportOption> expenseTypeBreakdown;
  final List<ReportGroupRow> topClients;
  final List<ReportGroupRow> topVendors;
  final List<ReportGroupRow> topDrivers;
  final List<ReportGroupRow> topTrucks;
  final DriverPerformanceSummary driverPerformance;
  final VendorStatementSummary vendorStatement;
  final bool isPostingVendorPayment;
  final String periodLabel;
  final String? error;

  const ReportsState({
    required this.isLoading,
    required this.period,
    required this.selectedDay,
    required this.selectedWeekAnchor,
    required this.selectedMonth,
    required this.selectedRange,
    this.selectedDriverId,
    this.selectedTruckId,
    this.selectedVendorId,
    this.selectedClientId,
    this.selectedType,
    this.drivers = const <ExpenseReportOption>[],
    this.trucks = const <ExpenseReportOption>[],
    this.vendors = const <ExpenseReportOption>[],
    this.clients = const <ExpenseReportOption>[],
    this.items = const <ExpenseReportItem>[],
    this.totals = ExpenseReportTotals.zero,
    this.kpis = BusinessKpis.zero,
    this.tripsByStatus = const <StatusRow>[],
    this.expenseTypeBreakdown = const <ExpenseReportOption>[],
    this.topClients = const <ReportGroupRow>[],
    this.topVendors = const <ReportGroupRow>[],
    this.topDrivers = const <ReportGroupRow>[],
    this.topTrucks = const <ReportGroupRow>[],
    this.driverPerformance = DriverPerformanceSummary.zero,
    this.vendorStatement = VendorStatementSummary.zero,
    this.isPostingVendorPayment = false,
    this.periodLabel = '',
    this.error,
  });

  factory ReportsState.initial() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return ReportsState(
      isLoading: false,
      period: ExpenseReportPeriod.month,
      selectedDay: today,
      selectedWeekAnchor: today,
      selectedMonth: DateTime(now.year, now.month, 1),
      selectedRange: DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
    );
  }

  ReportsState copyWith({
    bool? isLoading,
    ExpenseReportPeriod? period,
    DateTime? selectedDay,
    DateTime? selectedWeekAnchor,
    DateTime? selectedMonth,
    DateTimeRange? selectedRange,
    Object? selectedDriverId = _sentinel,
    Object? selectedTruckId = _sentinel,
    Object? selectedVendorId = _sentinel,
    Object? selectedClientId = _sentinel,
    Object? selectedType = _sentinel,
    List<ExpenseReportOption>? drivers,
    List<ExpenseReportOption>? trucks,
    List<ExpenseReportOption>? vendors,
    List<ExpenseReportOption>? clients,
    List<ExpenseReportItem>? items,
    ExpenseReportTotals? totals,
    BusinessKpis? kpis,
    List<StatusRow>? tripsByStatus,
    List<ExpenseReportOption>? expenseTypeBreakdown,
    List<ReportGroupRow>? topClients,
    List<ReportGroupRow>? topVendors,
    List<ReportGroupRow>? topDrivers,
    List<ReportGroupRow>? topTrucks,
    DriverPerformanceSummary? driverPerformance,
    VendorStatementSummary? vendorStatement,
    bool? isPostingVendorPayment,
    String? periodLabel,
    Object? error = _sentinel,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      period: period ?? this.period,
      selectedDay: selectedDay ?? this.selectedDay,
      selectedWeekAnchor: selectedWeekAnchor ?? this.selectedWeekAnchor,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedRange: selectedRange ?? this.selectedRange,
      selectedDriverId: identical(selectedDriverId, _sentinel)
          ? this.selectedDriverId
          : selectedDriverId as String?,
      selectedTruckId: identical(selectedTruckId, _sentinel)
          ? this.selectedTruckId
          : selectedTruckId as String?,
      selectedVendorId: identical(selectedVendorId, _sentinel)
          ? this.selectedVendorId
          : selectedVendorId as String?,
      selectedClientId: identical(selectedClientId, _sentinel)
          ? this.selectedClientId
          : selectedClientId as String?,
      selectedType: identical(selectedType, _sentinel)
          ? this.selectedType
          : selectedType as String?,
      drivers: drivers ?? this.drivers,
      trucks: trucks ?? this.trucks,
      vendors: vendors ?? this.vendors,
      clients: clients ?? this.clients,
      items: items ?? this.items,
      totals: totals ?? this.totals,
      kpis: kpis ?? this.kpis,
      tripsByStatus: tripsByStatus ?? this.tripsByStatus,
      expenseTypeBreakdown: expenseTypeBreakdown ?? this.expenseTypeBreakdown,
      topClients: topClients ?? this.topClients,
      topVendors: topVendors ?? this.topVendors,
      topDrivers: topDrivers ?? this.topDrivers,
      topTrucks: topTrucks ?? this.topTrucks,
      driverPerformance: driverPerformance ?? this.driverPerformance,
      vendorStatement: vendorStatement ?? this.vendorStatement,
      isPostingVendorPayment: isPostingVendorPayment ?? this.isPostingVendorPayment,
      periodLabel: periodLabel ?? this.periodLabel,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}
