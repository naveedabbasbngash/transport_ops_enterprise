import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../domain/entities/expense_report_models.dart';
import 'reports_state.dart';
import 'reports_view_model.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsViewModelProvider);
    final vm = ref.read(reportsViewModelProvider.notifier);
    final money = NumberFormat.currency(symbol: 'SAR ', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: AppSpacing.topBar,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Text(
                    'Reports',
                    style: TextStyle(
                      fontSize: AppTypography.title,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: state.isLoading ? null : vm.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoading && state.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: AppSpacing.page,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1280),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Hero(state: state),
                              const SizedBox(height: AppSpacing.md),
                              _Filters(state: state, vm: vm),
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: AppSpacing.md,
                                runSpacing: AppSpacing.md,
                                children: [
                                  _KpiCard(
                                    title: 'Revenue',
                                    value: money.format(state.kpis.revenue),
                                    color: AppColors.infoBlue,
                                  ),
                                  _KpiCard(
                                    title: 'Trips',
                                    value: state.kpis.tripCount.toString(),
                                    color: AppColors.successGreen,
                                  ),
                                  _KpiCard(
                                    title: 'Net Profit',
                                    value: money.format(state.kpis.netProfitAfterExpenses),
                                    color: AppColors.accentOrange,
                                  ),
                                  _KpiCard(
                                    title: 'Total Expense',
                                    value: money.format(state.kpis.totalExpense),
                                    color: AppColors.dangerRed,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _BusinessPanels(state: state, formatter: money),
                              const SizedBox(height: AppSpacing.md),
                              _OperationalPanels(state: state, vm: vm, formatter: money),
                              const SizedBox(height: AppSpacing.md),
                              _TypeTotals(
                                totals: state.totals,
                                formatter: money,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _ItemsTable(items: state.items, formatter: money),
                              if (state.error != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                _ErrorBanner(message: state.error!),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.state});

  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.page,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.heroDarkStart, AppColors.heroDarkEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          const Text(
            'Operational Expense Intelligence',
            style: TextStyle(
              color: Colors.white,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w700,
            ),
          ),
          _Pill(text: state.periodLabel.isEmpty ? 'No period selected' : state.periodLabel),
          _Pill(text: 'Rows: ${state.items.length}'),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.vm});

  final ReportsState state;
  final ReportsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.panel,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<ExpenseReportPeriod>(
            segments: const [
              ButtonSegment(value: ExpenseReportPeriod.day, label: Text('Day')),
              ButtonSegment(value: ExpenseReportPeriod.week, label: Text('Week')),
              ButtonSegment(value: ExpenseReportPeriod.month, label: Text('Month')),
              ButtonSegment(value: ExpenseReportPeriod.range, label: Text('Range')),
            ],
            selected: {state.period},
            onSelectionChanged: (selection) => vm.setPeriod(selection.first),
          ),
          _PeriodPicker(state: state, vm: vm),
          _Dropdown(
            label: 'Driver',
            value: state.selectedDriverId,
            options: state.drivers,
            onChanged: vm.setDriver,
          ),
          _Dropdown(
            label: 'Truck',
            value: state.selectedTruckId,
            options: state.trucks,
            onChanged: vm.setTruck,
          ),
          _Dropdown(
            label: 'Provider',
            value: state.selectedVendorId,
            options: state.vendors,
            onChanged: vm.setVendor,
          ),
          _Dropdown(
            label: 'Client',
            value: state.selectedClientId,
            options: state.clients,
            onChanged: vm.setClient,
          ),
          _TypeDropdown(
            value: state.selectedType,
            onChanged: vm.setType,
          ),
          OutlinedButton.icon(
            onPressed: vm.clearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('All'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final uri = await vm.buildExportUri();
              if (uri == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Login token missing. Please login again.')),
                );
                return;
              }

              final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (!launched && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not start CSV export.')),
                );
              }
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({
    required this.state,
    required this.vm,
  });

  final ReportsState state;
  final ReportsViewModel vm;

  @override
  Widget build(BuildContext context) {
    switch (state.period) {
      case ExpenseReportPeriod.day:
        return OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: state.selectedDay,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              await vm.setDay(picked);
            }
          },
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(DateFormat('yyyy-MM-dd').format(state.selectedDay)),
        );
      case ExpenseReportPeriod.week:
        return OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: state.selectedWeekAnchor,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              await vm.setWeekAnchor(picked);
            }
          },
          icon: const Icon(Icons.date_range_outlined),
          label: Text('Week of ${DateFormat('yyyy-MM-dd').format(state.selectedWeekAnchor)}'),
        );
      case ExpenseReportPeriod.month:
        return OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: state.selectedMonth,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              initialDatePickerMode: DatePickerMode.year,
            );
            if (picked != null) {
              await vm.setMonth(picked);
            }
          },
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(DateFormat('yyyy-MM').format(state.selectedMonth)),
        );
      case ExpenseReportPeriod.range:
        return OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              initialDateRange: state.selectedRange,
            );
            if (picked != null) {
              await vm.setRange(picked);
            }
          },
          icon: const Icon(Icons.event_note_outlined),
          label: Text(
            '${DateFormat('yyyy-MM-dd').format(state.selectedRange.start)} -> '
            '${DateFormat('yyyy-MM-dd').format(state.selectedRange.end)}',
          ),
        );
    }
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<ExpenseReportOption> options;
  final Future<void> Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: DropdownButtonFormField<String?>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('All'),
          ),
          ...options.map(
            (option) => DropdownMenuItem<String?>(
              value: option.id,
              child: Text(option.label),
            ),
          ),
        ],
        onChanged: (next) => onChanged(next),
      ),
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({required this.value, required this.onChanged});

  final String? value;
  final Future<void> Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String?>(
        initialValue: value,
        decoration: const InputDecoration(labelText: 'Type'),
        items: const [
          DropdownMenuItem<String?>(value: null, child: Text('All')),
          DropdownMenuItem<String?>(value: 'fuel', child: Text('Fuel')),
          DropdownMenuItem<String?>(value: 'toll', child: Text('Toll')),
          DropdownMenuItem<String?>(value: 'repair', child: Text('Repair')),
          DropdownMenuItem<String?>(value: 'parking', child: Text('Parking')),
          DropdownMenuItem<String?>(value: 'penalty', child: Text('Penalty')),
          DropdownMenuItem<String?>(value: 'office_misc', child: Text('Office Misc')),
        ],
        onChanged: (next) => onChanged(next),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Container(
        padding: AppSpacing.panel,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.pie_chart_outline_rounded, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppTypography.caption,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppTypography.section,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTotals extends StatelessWidget {
  const _TypeTotals({
    required this.totals,
    required this.formatter,
  });

  final ExpenseReportTotals totals;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    final values = <MapEntry<String, double>>[
      MapEntry('Fuel', totals.fuel),
      MapEntry('Toll', totals.toll),
      MapEntry('Repair', totals.repair),
      MapEntry('Parking', totals.parking),
      MapEntry('Penalty', totals.penalty),
      MapEntry('Office Misc', totals.officeMisc),
    ];

    return Container(
      width: double.infinity,
      padding: AppSpacing.panel,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: values
            .map(
              (entry) => Chip(
                backgroundColor: AppColors.panelBlueBg,
                side: const BorderSide(color: AppColors.panelBlueBorder),
                label: Text('${entry.key}: ${formatter.format(entry.value)}'),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({
    required this.items,
    required this.formatter,
  });

  final List<ExpenseReportItem> items;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text(
          'No expenses found for selected filters.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Driver')),
            DataColumn(label: Text('Truck')),
            DataColumn(label: Text('Provider')),
            DataColumn(label: Text('Trip')),
            DataColumn(label: Text('Notes')),
          ],
          rows: items
              .map(
                (item) => DataRow(
                  cells: [
                    DataCell(Text(item.expenseDate)),
                    DataCell(Text(_typeLabel(item.type))),
                    DataCell(Text(formatter.format(item.amount))),
                    DataCell(Text(item.driverName ?? '-')),
                    DataCell(Text(item.truckPlateNo ?? '-')),
                    DataCell(Text(item.vendorName ?? '-')),
                    DataCell(Text(item.tripId ?? '-')),
                    DataCell(SizedBox(
                      width: 300,
                      child: Text(
                        item.notes?.trim().isNotEmpty == true ? item.notes! : '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String _typeLabel(String raw) {
    switch (raw) {
      case 'office_misc':
        return 'Office Misc';
      default:
        if (raw.isEmpty) return '-';
        return raw[0].toUpperCase() + raw.substring(1);
    }
  }
}

class _BusinessPanels extends StatelessWidget {
  const _BusinessPanels({
    required this.state,
    required this.formatter,
  });

  final ReportsState state;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _CompactPanel(
          title: 'Finance Snapshot',
          lines: [
            'Vendor Cost: ${formatter.format(state.kpis.vendorCost)}',
            'Other Cost: ${formatter.format(state.kpis.otherCost)}',
            'Expected Profit: ${formatter.format(state.kpis.expectedProfit)}',
            'Payments Received: ${formatter.format(state.kpis.paymentsReceived)}',
            'Invoice Total: ${formatter.format(state.kpis.invoiceTotal)}',
            'Invoice Paid: ${formatter.format(state.kpis.invoicePaid)}',
            'Invoice Outstanding: ${formatter.format(state.kpis.invoiceOutstanding)}',
          ],
        ),
        _CompactPanel(
          title: 'Trip Status',
          lines: state.tripsByStatus
              .map((s) => '${s.status.toUpperCase()}: ${s.total}')
              .toList(),
        ),
        _GroupPanel(
          title: 'Top Clients',
          rows: state.topClients,
          formatter: formatter,
        ),
        _GroupPanel(
          title: 'Top Providers',
          rows: state.topVendors,
          formatter: formatter,
        ),
        _GroupPanel(
          title: 'Top Drivers',
          rows: state.topDrivers,
          formatter: formatter,
        ),
        _GroupPanel(
          title: 'Top Trucks',
          rows: state.topTrucks,
          formatter: formatter,
        ),
      ],
    );
  }
}

class _OperationalPanels extends StatelessWidget {
  const _OperationalPanels({
    required this.state,
    required this.vm,
    required this.formatter,
  });

  final ReportsState state;
  final ReportsViewModel vm;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        Container(
          width: 620,
          padding: AppSpacing.panel,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Driver Performance (Select Driver in filters)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: AppTypography.section,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Trips: ${state.driverPerformance.tripCount}'),
              Text('Revenue: ${formatter.format(state.driverPerformance.revenue)}'),
              Text('Expected Profit: ${formatter.format(state.driverPerformance.expectedProfit)}'),
              Text('Driver Expenses: ${formatter.format(state.driverPerformance.driverExpenseTotal)}'),
              Text(
                'Profit After Driver Expenses: ${formatter.format(state.driverPerformance.profitAfterDriverExpenses)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (state.driverPerformance.expenseByType.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.driverPerformance.expenseByType
                      .map((e) => Chip(label: Text(e.label)))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        Container(
          width: 620,
          padding: AppSpacing.panel,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Provider Khata (Select Provider in filters)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: AppTypography.section,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Trips: ${state.vendorStatement.tripCount}'),
              Text('Gross Payable: ${formatter.format(state.vendorStatement.grossPayable)}'),
              Text('Paid: ${formatter.format(state.vendorStatement.paid)}'),
              Text(
                'Balance: ${formatter.format(state.vendorStatement.balance)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: state.selectedVendorId == null || state.isPostingVendorPayment
                        ? null
                        : () async {
                            final amountCtrl = TextEditingController();
                            final notesCtrl = TextEditingController();
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Post Provider Payment'),
                                content: SizedBox(
                                  width: 380,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: amountCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          labelText: 'Amount',
                                          hintText: 'e.g. 5000',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: notesCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Notes (optional)',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Post'),
                                  ),
                                ],
                              ),
                            );

                            if (ok != true) return;
                            try {
                              await vm.postVendorPayment(
                                amount: amountCtrl.text,
                                notes: notesCtrl.text,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Provider payment posted.')),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(state.isPostingVendorPayment ? 'Posting...' : 'Post Payment'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: state.selectedVendorId == null
                        ? null
                        : () async {
                            final uri = await vm.buildVendorStatementExportUri();
                            if (uri == null) return;
                            final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                            if (!launched && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not export provider statement.')),
                              );
                            }
                          },
                    icon: const Icon(Icons.download_for_offline_outlined),
                    label: const Text('Export Provider CSV'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Posts payment against selected provider trips for selected period (oldest trips first).',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (state.vendorStatement.items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                ...state.vendorStatement.items.take(8).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('Bal: ${formatter.format(item.amount)}'),
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactPanel extends StatelessWidget {
  const _CompactPanel({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 408,
      padding: AppSpacing.panel,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: AppTypography.section,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...(lines.isEmpty
              ? const [Text('No data')]
              : lines.map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line),
                  ))),
        ],
      ),
    );
  }
}

class _GroupPanel extends StatelessWidget {
  const _GroupPanel({
    required this.title,
    required this.rows,
    required this.formatter,
  });

  final String title;
  final List<ReportGroupRow> rows;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 408,
      padding: AppSpacing.panel,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: AppTypography.section,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (rows.isEmpty) const Text('No data'),
          ...rows.take(6).map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('${row.tripCount} trips'),
                      const SizedBox(width: 8),
                      Text(
                        formatter.format(row.amount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.panel,
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.dangerDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
