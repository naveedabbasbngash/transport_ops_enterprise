import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../../../core/config/api_base_url_store.dart';
import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_list_parser.dart';
import '../../../shared/providers/api_client_provider.dart';
import '../../auth/data/auth_local_source.dart';
import '../domain/entities/expense_report_models.dart';
import 'reports_state.dart';

final reportsViewModelProvider =
    StateNotifierProvider<ReportsViewModel, ReportsState>(
  (ref) => ReportsViewModel(
    apiClient: ref.watch(apiClientProvider),
  )..initialize(),
);

class ReportsViewModel extends StateNotifier<ReportsState> {
  ReportsViewModel({
    required ApiClient apiClient,
  })  : _apiClient = apiClient,
        super(ReportsState.initial());

  final ApiClient _apiClient;

  static const List<String> expenseTypes = <String>[
    'fuel',
    'toll',
    'repair',
    'parking',
    'penalty',
    'office_misc',
  ];

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([
        _loadFilterOptions(),
        loadReport(),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _toMessage(e),
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await loadReport();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _toMessage(e),
      );
    }
  }

  Future<void> setPeriod(ExpenseReportPeriod period) async {
    state = state.copyWith(period: period);
    await refresh();
  }

  Future<void> setDay(DateTime date) async {
    state = state.copyWith(selectedDay: _toDate(date));
    await refresh();
  }

  Future<void> setWeekAnchor(DateTime date) async {
    state = state.copyWith(selectedWeekAnchor: _toDate(date));
    await refresh();
  }

  Future<void> setMonth(DateTime month) async {
    state = state.copyWith(selectedMonth: DateTime(month.year, month.month, 1));
    await refresh();
  }

  Future<void> setRange(DateTimeRange range) async {
    state = state.copyWith(
      selectedRange: DateTimeRange(
        start: _toDate(range.start),
        end: _toDate(range.end),
      ),
    );
    await refresh();
  }

  Future<void> setDriver(String? value) async {
    state = state.copyWith(selectedDriverId: value);
    await refresh();
  }

  Future<void> setTruck(String? value) async {
    state = state.copyWith(selectedTruckId: value);
    await refresh();
  }

  Future<void> setVendor(String? value) async {
    state = state.copyWith(selectedVendorId: value);
    await refresh();
  }

  Future<void> setClient(String? value) async {
    state = state.copyWith(selectedClientId: value);
    await refresh();
  }

  Future<void> setType(String? value) async {
    state = state.copyWith(selectedType: value);
    await refresh();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      selectedDriverId: null,
      selectedTruckId: null,
      selectedVendorId: null,
      selectedClientId: null,
      selectedType: null,
    );
    await refresh();
  }

  Future<Uri?> buildExportUri() async {
    final token = await AuthLocalSource.getToken();
    if (token == null || token.isEmpty) return null;

    final baseUrl = await ApiBaseUrlStore.get() ?? Env.apiBaseUrl;
    final rawBase = baseUrl.endsWith('/api')
        ? baseUrl.substring(0, baseUrl.length - 4)
        : baseUrl;

    return Uri.parse('$rawBase/api/reports/expenses/export-download').replace(
      queryParameters: <String, String>{
        ..._buildQuery().map((k, v) => MapEntry(k, v.toString())),
        'token': token,
      },
    );
  }

  Future<Uri?> buildVendorStatementExportUri() async {
    final vendorId = state.selectedVendorId;
    if (vendorId == null || vendorId.isEmpty) return null;
    final token = await AuthLocalSource.getToken();
    if (token == null || token.isEmpty) return null;

    final baseUrl = await ApiBaseUrlStore.get() ?? Env.apiBaseUrl;
    final rawBase = baseUrl.endsWith('/api')
        ? baseUrl.substring(0, baseUrl.length - 4)
        : baseUrl;

    return Uri.parse('$rawBase/api/reports/vendors/statement/export-download').replace(
      queryParameters: <String, String>{
        ..._buildQuery().map((k, v) => MapEntry(k, v.toString())),
        'vendor_id': vendorId,
        'token': token,
      },
    );
  }

  Future<void> loadReport() async {
    final response = await _apiClient.getJson(
      'reports/expenses',
      query: _buildQuery(),
    );

    final data = _asMap(response['data']);
    final totalsMap = _asMap(data['totals']);
    final byType = _asMap(totalsMap['by_type']);
    final itemsRaw = data['items'] is List
        ? (data['items'] as List)
        : extractListFromResponse(response);

    final items = itemsRaw
        .whereType<Map>()
        .map((raw) => raw.cast<String, dynamic>())
        .map(_mapItem)
        .toList();

    state = state.copyWith(
      items: items,
      periodLabel: _asMap(data['period'])['label']?.toString() ?? '',
      totals: ExpenseReportTotals(
        count: _toInt(totalsMap['count']),
        totalAmount: _toDouble(totalsMap['total_amount']),
        fuel: _toDouble(byType['fuel']),
        toll: _toDouble(byType['toll']),
        repair: _toDouble(byType['repair']),
        parking: _toDouble(byType['parking']),
        penalty: _toDouble(byType['penalty']),
        officeMisc: _toDouble(byType['office_misc']),
      ),
      error: null,
    );

    await _loadBusinessOverview();
    await _loadOperationalDetails();
  }

  Future<void> postVendorPayment({
    required String amount,
    String? notes,
  }) async {
    final vendorId = state.selectedVendorId;
    if (vendorId == null || vendorId.isEmpty) {
      throw Exception('Select provider first.');
    }
    final parsed = double.tryParse(amount.trim());
    if (parsed == null || parsed <= 0) {
      throw Exception('Enter valid amount.');
    }

    state = state.copyWith(isPostingVendorPayment: true, error: null);
    try {
      final body = <String, dynamic>{
        ..._buildQuery(),
        'vendor_id': vendorId,
        'amount': parsed,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };
      await _apiClient.postJson('reports/vendors/settlements', body: body);
      await refresh();
    } finally {
      state = state.copyWith(isPostingVendorPayment: false);
    }
  }

  Map<String, dynamic> _buildQuery() {
    final query = <String, dynamic>{};
    switch (state.period) {
      case ExpenseReportPeriod.day:
        query['period'] = 'day';
        query['day'] = _fmtDate(state.selectedDay);
        break;
      case ExpenseReportPeriod.week:
        query['period'] = 'week';
        query['week_date'] = _fmtDate(state.selectedWeekAnchor);
        break;
      case ExpenseReportPeriod.month:
        query['period'] = 'month';
        query['month'] = DateFormat('yyyy-MM').format(state.selectedMonth);
        break;
      case ExpenseReportPeriod.range:
        query['period'] = 'range';
        query['from_date'] = _fmtDate(state.selectedRange.start);
        query['to_date'] = _fmtDate(state.selectedRange.end);
        break;
    }

    if (state.selectedDriverId != null && state.selectedDriverId!.isNotEmpty) {
      query['driver_id'] = state.selectedDriverId!;
    }
    if (state.selectedTruckId != null && state.selectedTruckId!.isNotEmpty) {
      query['truck_id'] = state.selectedTruckId!;
    }
    if (state.selectedVendorId != null && state.selectedVendorId!.isNotEmpty) {
      query['vendor_id'] = state.selectedVendorId!;
    }
    if (state.selectedClientId != null && state.selectedClientId!.isNotEmpty) {
      query['client_id'] = state.selectedClientId!;
    }
    if (state.selectedType != null && state.selectedType!.isNotEmpty) {
      query['type'] = state.selectedType!;
    }

    return query;
  }

  Future<void> _loadFilterOptions() async {
    final responses = await Future.wait([
      _apiClient.getJson('drivers', query: const {'status': 'active'}),
      _apiClient.getJson('trucks', query: const {'status': 'active'}),
      _apiClient.getJson('vendors', query: const {'status': 'active'}),
      _apiClient.getJson('clients', query: const {'status': 'active'}),
    ]);

    final drivers = extractListFromResponse(responses[0])
        .map((item) => ExpenseReportOption(
              id: item['id']?.toString() ?? '',
              label: item['name']?.toString() ?? '',
            ))
        .where((item) => item.id.isNotEmpty && item.label.isNotEmpty)
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    final trucks = extractListFromResponse(responses[1])
        .map((item) => ExpenseReportOption(
              id: item['id']?.toString() ?? '',
              label: item['plate_no']?.toString() ?? '',
            ))
        .where((item) => item.id.isNotEmpty && item.label.isNotEmpty)
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    final vendors = extractListFromResponse(responses[2])
        .map((item) => ExpenseReportOption(
              id: item['id']?.toString() ?? '',
              label: item['name']?.toString() ?? '',
            ))
        .where((item) => item.id.isNotEmpty && item.label.isNotEmpty)
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    final clients = extractListFromResponse(responses[3])
        .map((item) => ExpenseReportOption(
              id: item['id']?.toString() ?? '',
              label: item['name']?.toString() ?? '',
            ))
        .where((item) => item.id.isNotEmpty && item.label.isNotEmpty)
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    state = state.copyWith(
      drivers: drivers,
      trucks: trucks,
      vendors: vendors,
      clients: clients,
    );
  }

  Future<void> _loadBusinessOverview() async {
    final response = await _apiClient.getJson(
      'reports/overview',
      query: _buildQuery(),
    );
    final data = _asMap(response['data']);
    final kpis = _asMap(data['kpis']);
    final breakdowns = _asMap(data['breakdowns']);

    final expenseByTypeRaw = breakdowns['expense_by_type'] is List
        ? (breakdowns['expense_by_type'] as List)
        : const <dynamic>[];
    final expenseByType = expenseByTypeRaw
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .map(
          (e) => ExpenseReportOption(
            id: e['type']?.toString() ?? '',
            label:
                '${e['type']?.toString() ?? 'unknown'}: ${_toDouble(e['amount']).toStringAsFixed(2)}',
          ),
        )
        .toList();

    state = state.copyWith(
      kpis: BusinessKpis(
        tripCount: _toInt(kpis['trip_count']),
        revenue: _toDouble(kpis['revenue']),
        vendorCost: _toDouble(kpis['vendor_cost']),
        otherCost: _toDouble(kpis['other_cost']),
        expectedProfit: _toDouble(kpis['expected_profit']),
        expenseCount: _toInt(kpis['expense_count']),
        totalExpense: _toDouble(kpis['total_expense']),
        paymentsReceived: _toDouble(kpis['payments_received']),
        invoiceTotal: _toDouble(kpis['invoice_total']),
        invoicePaid: _toDouble(kpis['invoice_paid']),
        invoiceOutstanding: _toDouble(kpis['invoice_outstanding']),
        netProfitAfterExpenses: _toDouble(kpis['net_profit_after_expenses']),
      ),
      tripsByStatus: _mapStatusRows(breakdowns['trips_by_status']),
      expenseTypeBreakdown: expenseByType,
      topClients: _mapGroupRows(breakdowns['top_clients']),
      topVendors: _mapGroupRows(breakdowns['top_vendors']),
      topDrivers: _mapGroupRows(breakdowns['top_drivers']),
      topTrucks: _mapGroupRows(breakdowns['top_trucks']),
    );
  }

  Future<void> _loadOperationalDetails() async {
    DriverPerformanceSummary driverPerformance = DriverPerformanceSummary.zero;
    VendorStatementSummary vendorStatement = VendorStatementSummary.zero;

    if (state.selectedDriverId != null && state.selectedDriverId!.isNotEmpty) {
      final response = await _apiClient.getJson(
        'reports/drivers/performance',
        query: <String, dynamic>{
          ..._buildQuery(),
          'driver_id': state.selectedDriverId!,
        },
      );
      final data = _asMap(response['data']);
      final summary = _asMap(data['summary']);
      final expenseByTypeRaw = data['expense_by_type'] is List
          ? (data['expense_by_type'] as List)
          : const <dynamic>[];
      final expenseByType = expenseByTypeRaw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .map(
            (e) => ExpenseReportOption(
              id: e['type']?.toString() ?? '',
              label:
                  '${e['type']?.toString() ?? 'unknown'}: ${_toDouble(e['amount']).toStringAsFixed(2)}',
            ),
          )
          .toList();
      driverPerformance = DriverPerformanceSummary(
        tripCount: _toInt(summary['trip_count']),
        revenue: _toDouble(summary['revenue']),
        vendorCost: _toDouble(summary['vendor_cost']),
        otherCost: _toDouble(summary['other_cost']),
        expectedProfit: _toDouble(summary['expected_profit']),
        driverExpenseTotal: _toDouble(summary['driver_expense_total']),
        profitAfterDriverExpenses: _toDouble(summary['profit_after_driver_expenses']),
        expenseByType: expenseByType,
      );
    }

    if (state.selectedVendorId != null && state.selectedVendorId!.isNotEmpty) {
      final response = await _apiClient.getJson(
        'reports/vendors/statement',
        query: <String, dynamic>{
          ..._buildQuery(),
          'vendor_id': state.selectedVendorId!,
        },
      );
      final data = _asMap(response['data']);
      final summary = _asMap(data['summary']);
      final rawItems = data['items'] is List ? (data['items'] as List) : const <dynamic>[];
      final mapped = rawItems
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .map(
            (e) => ReportGroupRow(
              id: e['trip_id']?.toString(),
              label:
                  '${e['trip_date']?.toString() ?? ''} | ${(e['route']?.toString() ?? '').trim()}',
              tripCount: 1,
              amount: _toDouble(e['balance']),
            ),
          )
          .toList();
      vendorStatement = VendorStatementSummary(
        tripCount: _toInt(summary['trip_count']),
        grossPayable: _toDouble(summary['gross_payable']),
        paid: _toDouble(summary['paid']),
        balance: _toDouble(summary['balance']),
        items: mapped,
      );
    }

    state = state.copyWith(
      driverPerformance: driverPerformance,
      vendorStatement: vendorStatement,
    );
  }

  List<StatusRow> _mapStatusRows(dynamic raw) {
    if (raw is! List) return const <StatusRow>[];
    return raw
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .map(
          (e) => StatusRow(
            status: e['status']?.toString() ?? 'unknown',
            total: _toInt(e['total']),
          ),
        )
        .toList();
  }

  List<ReportGroupRow> _mapGroupRows(dynamic raw) {
    if (raw is! List) return const <ReportGroupRow>[];
    return raw
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .map(
          (e) => ReportGroupRow(
            id: e['id']?.toString(),
            label: e['label']?.toString() ?? 'Unknown',
            tripCount: _toInt(e['trip_count']),
            amount: _toDouble(e['amount']),
          ),
        )
        .toList();
  }

  ExpenseReportItem _mapItem(Map<String, dynamic> raw) {
    return ExpenseReportItem(
      id: raw['id']?.toString() ?? '',
      expenseDate: raw['expense_date']?.toString() ?? '',
      type: raw['type']?.toString() ?? '',
      amount: _toDouble(raw['amount']),
      driverName: raw['driver_name']?.toString(),
      truckPlateNo: raw['truck_plate_no']?.toString(),
      vendorName: raw['vendor_name']?.toString(),
      tripId: raw['trip_id']?.toString(),
      notes: raw['notes']?.toString(),
    );
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  DateTime _toDate(DateTime raw) => DateTime(raw.year, raw.month, raw.day);

  String _fmtDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  int _toInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic raw) {
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  String _toMessage(Object error) {
    final raw = error.toString();
    final compact = raw.replaceAll('\n', ' ');
    log('Reports error', name: 'Reports', error: compact);
    return compact.length > 180 ? '${compact.substring(0, 180)}...' : compact;
  }
}
