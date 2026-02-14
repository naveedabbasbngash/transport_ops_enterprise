import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/api_base_url_store.dart';
import '../../../core/config/env.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/providers/api_client_provider.dart';
import '../../auth/data/auth_local_source.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../trips/domain/entities/trip_entity.dart';
import '../domain/entities/order_entity.dart';
import 'orders_view_model.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final OrderEntity order;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  OrderEntity? _latest;
  bool _loading = false;

  OrderEntity get _order => _latest ?? widget.order;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (widget.order.id.isEmpty) return;
    setState(() => _loading = true);
    try {
      final data = await ref
          .read(ordersViewModelProvider.notifier)
          .getOrderById(widget.order.id);
      if (!mounted) return;
      if (data != null) {
        setState(() => _latest = data);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly =
        ref.watch(authViewModelProvider).user?.isOwnerReadOnly ?? true;

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
                    'Order Details',
                    style: TextStyle(
                      fontSize: AppTypography.title,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loading ? null : _refresh,
                  ),
                  if (!isReadOnly)
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () async {
                        final ok = await Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.orderEdit, arguments: _order);
                        if (ok == true && mounted) _refresh();
                      },
                    ),
                  if (!isReadOnly)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: _deleteOrder,
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.page,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _hero(),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (!isReadOnly)
                              FilledButton.icon(
                                onPressed: () async {
                                  final created = await Navigator.of(context)
                                      .pushNamed(
                                        AppRoutes.tripCreate,
                                        arguments: {'orderId': _order.id},
                                      );
                                  if (created == true && mounted) {
                                    _refresh();
                                  }
                                },
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add Trip In This Order'),
                              ),
                            OutlinedButton.icon(
                              onPressed: _showViewSummary,
                              icon: const Icon(Icons.visibility_rounded),
                              label: const Text('View/Copy'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _downloadDocsZip,
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Download Docs ZIP'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _downloadSummaryPdf,
                              icon: const Icon(Icons.picture_as_pdf_rounded),
                              label: const Text('Download Summary PDF'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _downloadSummaryExcel,
                              icon: const Icon(Icons.table_chart_rounded),
                              label: const Text('Download Excel'),
                            ),
                          ],
                        ),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                        const SizedBox(height: 12),
                        _metaCard(),
                        const SizedBox(height: 12),
                        const Text(
                          'Trips',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_order.trips.isEmpty)
                          _emptyTrips()
                        else
                          ..._order.trips.map(
                            (trip) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _tripTile(context, trip),
                            ),
                          ),
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

  Widget _hero() {
    final title = _order.orderNo?.isNotEmpty == true
        ? _order.orderNo!
        : 'Order ${_order.id.substring(0, 8)}';
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
        spacing: 10,
        runSpacing: 10,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          _badge('${_order.tripsCount} trips'),
          _badge(_order.status.replaceAll('_', ' ')),
        ],
      ),
    );
  }

  Widget _metaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Client', _order.clientName ?? '-'),
          _row('From', _order.fromLocation ?? '-'),
          _row('To', _order.toLocation ?? '-'),
          _row('Order date', _order.orderDate ?? '-'),
          _row('Status', _order.status.replaceAll('_', ' ')),
          _row('Revenue', _order.revenueExpected.toStringAsFixed(2)),
          _row('Vendor cost', _order.vendorCost.toStringAsFixed(2)),
          _row('Other cost', _order.companyOtherCost.toStringAsFixed(2)),
          _row('Currency', _order.currency),
          _row(
            'Financial notes',
            (_order.financialNotes?.isNotEmpty ?? false)
                ? _order.financialNotes!
                : '-',
          ),
          _row(
            'Notes',
            (_order.notes?.isNotEmpty ?? false) ? _order.notes! : '-',
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(k, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _emptyTrips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: const Text('No trips in this order yet.'),
    );
  }

  Widget _tripTile(BuildContext context, TripEntity trip) {
    final missingDriverDoc = (trip.driverIqamaAttachment ?? '').trim().isEmpty;
    final missingTruckDoc = (trip.truckRegistrationCardUrl ?? '')
        .trim()
        .isEmpty;
    final missingWaybill = !trip.hasWaybill;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(
          context,
        ).pushNamed(AppRoutes.tripDetail, arguments: trip),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.fromLocation} -> ${trip.toLocation}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trip.tripDate} • ${trip.clientName} • ${trip.plateNo}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _missingChip('Driver doc', missingDriverDoc),
                        _missingChip('Truck doc', missingTruckDoc),
                        _missingChip('Waybill', missingWaybill),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (missingDriverDoc)
                          OutlinedButton.icon(
                            onPressed: () => _uploadDriverIqama(trip),
                            icon: const Icon(
                              Icons.upload_file_rounded,
                              size: 16,
                            ),
                            label: const Text('Upload Driver Doc'),
                          ),
                        if (missingTruckDoc)
                          OutlinedButton.icon(
                            onPressed: () => _uploadTruckDoc(trip),
                            icon: const Icon(
                              Icons.upload_file_rounded,
                              size: 16,
                            ),
                            label: const Text('Upload Truck Doc'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!trip.hasWaybill)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warningYellow,
                    size: 18,
                  ),
                ),
              Text(
                (trip.status ?? 'open').toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _missingChip(String label, bool missing) {
    final bg = missing ? AppColors.dangerLight : AppColors.successLight;
    final fg = missing ? AppColors.dangerDark : AppColors.successDark;
    final text = missing ? '$label: Missing' : '$label: OK';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Future<void> _showViewSummary() async {
    final sections = _summarySections();
    final text = _buildSummaryVerticalText(sections);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order View Summary'),
        content: SizedBox(
          width: 820,
          child: sections.isEmpty
              ? const Text('No trips found.')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: sections
                        .map(
                          (section) => Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black26),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF4F6F8),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    section.$1,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Table(
                                  border: TableBorder.all(
                                    color: Colors.black26,
                                    width: 1,
                                  ),
                                  columnWidths: const {
                                    0: FlexColumnWidth(1.2),
                                    1: FlexColumnWidth(2.0),
                                  },
                                  children: [
                                    const TableRow(
                                      decoration: BoxDecoration(
                                        color: Color(0xFFEFEFEF),
                                      ),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            'Field',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            'Value',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ...section.$2.map(
                                      (row) => TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(
                                              row.$1,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(row.$2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: sections.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard.')),
                    );
                  },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<(String, List<(String, String)>)> _summarySections() {
    String v(String data) => data.trim().isEmpty ? '-' : data.trim();
    final sections = <(String, List<(String, String)>)>[];

    for (var i = 0; i < _order.trips.length; i++) {
      final trip = _order.trips[i];
      sections.add((
        'Truck ${i + 1}',
        [
          ('Vehicle Plate #', v(trip.plateNo)),
          ('Owner Name', v(trip.truckOwnerName)),
          ('Company Name', v(trip.truckCompanyName)),
          ('Vehicle Type', v(trip.vehicleType)),
          ('Mobile No', v(trip.driverPhone)),
          ('Model Name', v(trip.truckModel)),
          ('Driver Name', v(trip.driverName)),
          ('Resident ID', v(trip.driverResidentId)),
          ('Color', v(trip.truckColor)),
          ('Make Years', v(trip.truckMakeYear)),
        ],
      ));
    }

    return sections;
  }

  String _buildSummaryVerticalText(
    List<(String, List<(String, String)>)> sections,
  ) {
    final lines = <String>[];
    for (final section in sections) {
      lines.add(section.$1);
      for (final row in section.$2) {
        lines.add('${row.$1}\t${row.$2}');
      }
      lines.add('');
    }
    if (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }
    return lines.join('\n');
  }

  Future<void> _downloadDocsZip() async {
    final token = await AuthLocalSource.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login token missing. Please login again.'),
        ),
      );
      return;
    }
    final base = await ApiBaseUrlStore.get() ?? Env.apiBaseUrl;
    final rawBase = base.endsWith('/api')
        ? base.substring(0, base.length - 4)
        : base;
    final uri = Uri.parse(
      '$rawBase/api/orders/${_order.id}/docs-zip-download',
    ).replace(queryParameters: {'token': token});
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start download.')),
      );
    }
  }

  Future<void> _downloadSummaryPdf() async {
    final token = await AuthLocalSource.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login token missing. Please login again.'),
        ),
      );
      return;
    }
    final base = await ApiBaseUrlStore.get() ?? Env.apiBaseUrl;
    final rawBase = base.endsWith('/api')
        ? base.substring(0, base.length - 4)
        : base;
    final uri = Uri.parse(
      '$rawBase/api/orders/${_order.id}/summary-pdf-download',
    ).replace(queryParameters: {'token': token});
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open summary PDF.')),
      );
    }
  }

  Future<void> _downloadSummaryExcel() async {
    final token = await AuthLocalSource.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login token missing. Please login again.'),
        ),
      );
      return;
    }
    final base = await ApiBaseUrlStore.get() ?? Env.apiBaseUrl;
    final rawBase = base.endsWith('/api')
        ? base.substring(0, base.length - 4)
        : base;
    final uri = Uri.parse(
      '$rawBase/api/orders/${_order.id}/summary-excel-download',
    ).replace(queryParameters: {'token': token});
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Excel export.')),
      );
    }
  }

  Future<void> _uploadDriverIqama(TripEntity trip) async {
    if ((trip.driverId ?? '').isEmpty) return;
    final selected = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (selected == null || selected.files.isEmpty) return;
    final file = selected.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) return;

    final api = ref.read(apiClientProvider);
    final response = await api.postMultipart(
      'drivers/${trip.driverId}/iqama',
      headers: const {'Accept': 'application/json'},
      files: [
        http.MultipartFile.fromBytes(
          'iqama_attachment',
          file.bytes!,
          filename: file.name,
        ),
      ],
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver document uploaded.')),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload failed (${response.statusCode}).')),
    );
  }

  Future<void> _uploadTruckDoc(TripEntity trip) async {
    if ((trip.truckId ?? '').isEmpty) return;
    final selected = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (selected == null || selected.files.isEmpty) return;
    final file = selected.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) return;

    final api = ref.read(apiClientProvider);
    final response = await api.postMultipart(
      'trucks/${trip.truckId}/registration-card',
      headers: const {'Accept': 'application/json'},
      files: [
        http.MultipartFile.fromBytes(
          'registration_card',
          file.bytes!,
          filename: file.name,
        ),
      ],
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Truck document uploaded.')));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload failed (${response.statusCode}).')),
    );
  }

  Future<void> _deleteOrder() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text(
          'Delete this order? It will fail if trips are linked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final done = await ref
        .read(ordersViewModelProvider.notifier)
        .deleteOrder(_order.id);
    if (!mounted) return;
    if (done) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not delete order (likely linked trips).'),
      ),
    );
  }
}
