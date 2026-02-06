import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/services/clipboard_service.dart';
import '../domain/entities/import_entity.dart';
import 'import_report_screen.dart';
import 'import_view_model.dart';

class ImportUploadScreen extends ConsumerWidget {
  const ImportUploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importViewModelProvider);
    final vm = ref.read(importViewModelProvider.notifier);
    final clipboardService = ClipboardService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Data'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enterprise Import Pipeline',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Upload -> Parse -> Normalize -> Validate -> Match -> Store -> Report',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: state.isLoading
                                ? null
                                : () => _selectMonth(context, vm, state.reportingMonth),
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(
                              'Reporting Month: ${DateFormat('yyyy-MM').format(state.reportingMonth)}',
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: state.isLoading
                                ? null
                                : () => _startImportFlow(context, vm, state.reportingMonth),
                            icon: state.isLoading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.upload_file_rounded),
                            label: Text(state.isLoading ? 'Processing...' : 'Upload CSV / Excel'),
                          ),
                          if (state.selectedFileName != null)
                            Chip(
                              avatar: const Icon(Icons.description_outlined, size: 18),
                              label: Text(state.selectedFileName!),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  if (state.importLog != null && state.importLog!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Import Log',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    await clipboardService.copyText(state.importLog!);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Import log copied to clipboard'),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copy Log'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SelectableText(
                                state.importLog!,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (state.lastReport != null) ...[
                    const SizedBox(height: 12),
                    _ImportSummary(report: state.lastReport!),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ImportReportScreen(report: state.lastReport!),
                            ),
                          );
                        },
                        icon: const Icon(Icons.table_view_outlined),
                        label: const Text('Open Detailed Report'),
                      ),
                    ),
                  ],
                  if (state.history.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Local Import History',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (isWide)
                      _HistoryTable(items: state.history)
                    else
                      for (final item in state.history.take(10))
                        Card(
                          child: ListTile(
                            title: Text(item.fileName),
                            subtitle: Text(
                              '${DateFormat('yyyy-MM-dd HH:mm').format(item.importedAt.toLocal())} • '
                              'month ${DateFormat('yyyy-MM').format(item.reportingMonth)}\n'
                              'rows ${item.totalRows} • errors ${item.errorRows}',
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _startImportFlow(
    BuildContext context,
    ImportViewModel vm,
    DateTime month,
  ) async {
    final pickedMonth = await showDatePicker(
      context: context,
      initialDate: month,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select reporting month',
    );
    if (pickedMonth == null) return;

    final reportingMonth = DateTime(pickedMonth.year, pickedMonth.month, 1);
    vm.setReportingMonth(reportingMonth);
    await vm.pickAndImportCsv(reportingMonth: reportingMonth);
  }

  Future<void> _selectMonth(
    BuildContext context,
    ImportViewModel vm,
    DateTime month,
  ) async {
    final pickedMonth = await showDatePicker(
      context: context,
      initialDate: month,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select reporting month',
    );
    if (pickedMonth == null) return;
    vm.setReportingMonth(DateTime(pickedMonth.year, pickedMonth.month, 1));
  }
}

class _ImportSummary extends StatelessWidget {
  const _ImportSummary({required this.report});

  final ImportEntity report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Text('File: ${report.fileName}'),
            Text('Month: ${DateFormat('yyyy-MM').format(report.reportingMonth)}'),
            Text('Total: ${report.totalRows}'),
            Text('New: ${report.successfulRows}'),
            Text('Updated: ${report.updatedRows}'),
            Text('Review: ${report.needsReviewRows}'),
            Text('Skipped: ${report.skippedRows}'),
            Text('Errors: ${report.errorRows}'),
          ],
        ),
      ),
    );
  }
}

class _HistoryTable extends StatelessWidget {
  const _HistoryTable({required this.items});

  final List<ImportEntity> items;

  @override
  Widget build(BuildContext context) {
    final rows = items.take(12).toList(growable: false);
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Imported At')),
            DataColumn(label: Text('Reporting Month')),
            DataColumn(label: Text('File')),
            DataColumn(label: Text('Rows')),
            DataColumn(label: Text('Errors')),
          ],
          rows: rows.map((item) {
            return DataRow(cells: [
              DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(item.importedAt.toLocal()))),
              DataCell(Text(DateFormat('yyyy-MM').format(item.reportingMonth))),
              DataCell(Text(item.fileName)),
              DataCell(Text('${item.totalRows}')),
              DataCell(Text('${item.errorRows}')),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
