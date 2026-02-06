import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/services/clipboard_service.dart';
import '../domain/entities/import_entity.dart';
import '../domain/entities/import_row_entity.dart';

class ImportReportScreen extends StatelessWidget {
  const ImportReportScreen({
    super.key,
    required this.report,
  });

  final ImportEntity report;

  @override
  Widget build(BuildContext context) {
    final clipboardService = ClipboardService();
    return Scaffold(
      appBar: AppBar(title: const Text('Import Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () async {
                await clipboardService.copyText(_buildIssueLog(report));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Issue log copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Issue Log'),
            ),
          ),
          const SizedBox(height: 8),
          _SummaryCard(report: report),
          const SizedBox(height: 16),
          Text(
            'Row-Level Results',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final row in report.rows) _RowTile(row: row),
        ],
      ),
    );
  }

  String _buildIssueLog(ImportEntity report) {
    final buffer = StringBuffer();
    buffer.writeln('Import Issue Log - ${report.fileName}');
    for (final row in report.rows) {
      if (row.status == ImportRowStatus.newRow) continue;
      buffer.writeln(
        'Row ${row.rowNumber} | ${_statusLabel(row.status)} | '
        'matched=${row.matchedEntityId ?? '-'} | '
        'message=${row.errorMessage ?? '-'}',
      );
    }
    return buffer.toString();
  }

  String _statusLabel(ImportRowStatus status) {
    switch (status) {
      case ImportRowStatus.newRow:
        return 'new';
      case ImportRowStatus.updatedNotApplied:
        return 'updated (not applied)';
      case ImportRowStatus.needsReview:
        return 'needs review';
      case ImportRowStatus.skipped:
        return 'skipped';
      case ImportRowStatus.error:
        return 'error';
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final ImportEntity report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: ${report.fileName}'),
            Text('Reporting month: ${DateFormat('yyyy-MM').format(report.reportingMonth)}'),
            const SizedBox(height: 12),
            Text('Total rows: ${report.totalRows}'),
            Text('New rows: ${report.successfulRows}'),
            Text('Updated (not applied): ${report.updatedRows}'),
            Text('Needs review: ${report.needsReviewRows}'),
            Text('Skipped rows: ${report.skippedRows}'),
            Text('Error rows: ${report.errorRows}'),
          ],
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row});

  final ImportRowEntity row;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text('Row ${row.rowNumber} - ${_label(row.status)}'),
        subtitle: row.errorMessage == null ? null : Text(row.errorMessage!),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Raw JSON'),
                Text(row.rawJson.toString()),
                if (row.normalizedJson != null) ...[
                  const SizedBox(height: 8),
                  const Text('Normalized JSON'),
                  Text(row.normalizedJson.toString()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _label(ImportRowStatus status) {
    switch (status) {
      case ImportRowStatus.newRow:
        return 'new';
      case ImportRowStatus.updatedNotApplied:
        return 'updated (not applied)';
      case ImportRowStatus.needsReview:
        return 'needs review';
      case ImportRowStatus.skipped:
        return 'skipped';
      case ImportRowStatus.error:
        return 'error';
    }
  }
}
