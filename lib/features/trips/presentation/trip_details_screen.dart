import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_routes.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../domain/entities/trip_entity.dart';
import 'trips_view_model.dart';

class TripDetailsScreen extends ConsumerStatefulWidget {
  const TripDetailsScreen({super.key, required this.trip});

  final TripEntity trip;

  @override
  ConsumerState<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends ConsumerState<TripDetailsScreen> {
  TripEntity? _latestTrip;
  bool _loading = false;
  bool _busyAction = false;

  TripEntity get _trip => _latestTrip ?? widget.trip;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final id = widget.trip.id;
    if (id.isEmpty) return;
    setState(() => _loading = true);
    try {
      final fetched = await ref
          .read(tripsViewModelProvider.notifier)
          .getTripById(id);
      if (!mounted) return;
      if (fetched != null) {
        setState(() => _latestTrip = fetched);
      }
    } catch (_) {
      // keep old snapshot if request fails
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(String status) async {
    if (_trip.id.isEmpty) return;
    setState(() => _busyAction = true);
    final ok = await ref
        .read(tripsViewModelProvider.notifier)
        .updateTripStatus(id: _trip.id, status: status);
    if (!mounted) return;
    if (ok) {
      await _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update trip status.')),
      );
    }
    setState(() => _busyAction = false);
  }

  Future<void> _uploadWaybill() async {
    if (_trip.id.isEmpty) return;
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read selected file.')),
      );
      return;
    }

    setState(() => _busyAction = true);
    final ok = await ref
        .read(tripsViewModelProvider.notifier)
        .uploadWaybill(
          tripId: _trip.id,
          bytes: file.bytes!,
          fileName: file.name,
        );
    if (!mounted) return;
    if (ok) {
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Waybill uploaded.')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Waybill upload failed.')));
    }
    setState(() => _busyAction = false);
  }

  Future<void> _deleteWaybill(TripWaybillFile file) async {
    setState(() => _busyAction = true);
    final ok = await ref
        .read(tripsViewModelProvider.notifier)
        .deleteWaybill(tripId: _trip.id, fileId: file.id);
    if (!mounted) return;
    if (ok) {
      await _refresh();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not remove file.')));
    }
    setState(() => _busyAction = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isReadOnly = authState.user?.isOwnerReadOnly ?? true;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              loading: _loading,
              actionLoading: _busyAction,
              isReadOnly: isReadOnly,
              onRefresh: _refresh,
              onEdit: () async {
                final updated = await Navigator.of(
                  context,
                ).pushNamed(AppRoutes.tripEdit, arguments: _trip);
                if (updated == true && mounted) {
                  await _refresh();
                }
              },
              onDelete: _deleteTrip,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroCard(
                          route: '${_trip.fromLocation} -> ${_trip.toLocation}',
                          tripDate: _trip.tripDate,
                          status: (_trip.status ?? 'open').toLowerCase(),
                          source: _trip.source ?? 'other',
                        ),
                        const SizedBox(height: 10),
                        _StatusActions(
                          status: (_trip.status ?? 'open').toLowerCase(),
                          isReadOnly: isReadOnly,
                          busy: _busyAction,
                          onSetOpen: () => _setStatus('open'),
                          onSetInProgress: () => _setStatus('in_progress'),
                          onSetCompleted: () => _setStatus('completed'),
                          onSetCancelled: () => _setStatus('cancelled'),
                        ),
                        const SizedBox(height: 10),
                        _WaybillPanel(
                          waybillNo: _trip.waybillNo,
                          files: _trip.waybills,
                          canEdit: !isReadOnly,
                          onUpload: _busyAction ? null : _uploadWaybill,
                          onDelete: _busyAction ? null : _deleteWaybill,
                        ),
                        if (_loading) ...[
                          const SizedBox(height: 10),
                          const LinearProgressIndicator(minHeight: 2),
                        ],
                        const SizedBox(height: 12),
                        _Panel(
                          title: 'Assignment',
                          children: [
                            _DetailRow(
                              label: 'Client',
                              value: _trip.clientName,
                              icon: Icons.business_rounded,
                            ),
                            _DetailRow(
                              label: 'Driver',
                              value: _trip.driverName,
                              icon: Icons.person_rounded,
                            ),
                            _DetailRow(
                              label: 'Truck',
                              value: '${_trip.plateNo} • ${_trip.vehicleType}',
                              icon: Icons.local_shipping_rounded,
                            ),
                            _DetailRow(
                              label: 'Provider',
                              value: _trip.vendorName.isEmpty
                                  ? (_trip.vendorId ?? '-')
                                  : _trip.vendorName,
                              icon: Icons.storefront_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _Panel(
                          title: 'References',
                          children: [
                            _DetailRow(
                              label: 'Reference',
                              value: _trip.referenceNo ?? '-',
                              icon: Icons.confirmation_number_outlined,
                            ),
                            _DetailRow(
                              label: 'Booking',
                              value: _trip.bookingNo ?? '-',
                              icon: Icons.book_online_outlined,
                            ),
                            _DetailRow(
                              label: 'Waybill',
                              value: _trip.waybillNo.isEmpty
                                  ? '-'
                                  : _trip.waybillNo,
                              icon: Icons.receipt_long_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _Panel(
                          title: 'Notes',
                          children: [
                            _DetailRow(
                              label: 'Remarks',
                              value: _trip.remarks.isEmpty
                                  ? '-'
                                  : _trip.remarks,
                              icon: Icons.notes_rounded,
                            ),
                          ],
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

  Future<void> _deleteTrip() async {
    if (_trip.id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete trip?'),
        content: const Text(
          'This action is blocked if expenses or invoice links exist.',
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

    setState(() => _busyAction = true);
    final success = await ref
        .read(tripsViewModelProvider.notifier)
        .deleteTrip(_trip.id);
    if (!mounted) return;
    setState(() => _busyAction = false);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Trip deleted.')));
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not delete trip (likely linked expenses/invoice).',
          ),
        ),
      );
    }
  }
}

class _TopBar extends StatelessWidget {
  final bool loading;
  final bool actionLoading;
  final bool isReadOnly;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TopBar({
    required this.loading,
    required this.actionLoading,
    required this.isReadOnly,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: AppSpacing.topBar,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Text(
            'Trip Details',
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: (loading || actionLoading) ? null : onRefresh,
          ),
          if (!isReadOnly)
            IconButton(icon: const Icon(Icons.edit_rounded), onPressed: onEdit),
          if (!isReadOnly)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String route;
  final String tripDate;
  final String status;
  final String source;

  const _HeroCard({
    required this.route,
    required this.tripDate,
    required this.status,
    required this.source,
  });

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
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            route,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          _StatusPill(text: status.toUpperCase()),
          _MetaPill(text: tripDate),
          _MetaPill(text: source),
        ],
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  final String status;
  final bool isReadOnly;
  final bool busy;
  final VoidCallback onSetOpen;
  final VoidCallback onSetInProgress;
  final VoidCallback onSetCompleted;
  final VoidCallback onSetCancelled;

  const _StatusActions({
    required this.status,
    required this.isReadOnly,
    required this.busy,
    required this.onSetOpen,
    required this.onSetInProgress,
    required this.onSetCompleted,
    required this.onSetCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Trip status',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          _StatusButton(
            label: 'Open',
            selected: status == 'open',
            onTap: (isReadOnly || busy) ? null : onSetOpen,
          ),
          _StatusButton(
            label: 'In Progress',
            selected: status == 'in_progress',
            onTap: (isReadOnly || busy) ? null : onSetInProgress,
          ),
          _StatusButton(
            label: 'Completed',
            selected: status == 'completed' || status == 'closed',
            onTap: (isReadOnly || busy) ? null : onSetCompleted,
          ),
          _StatusButton(
            label: 'Cancelled',
            selected: status == 'cancelled',
            onTap: (isReadOnly || busy) ? null : onSetCancelled,
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _StatusButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: onTap == null ? null : (_) => onTap?.call(),
      selectedColor: AppColors.primaryBlueLight,
      side: BorderSide(
        color: selected ? AppColors.primaryBlue : Colors.black12,
      ),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? AppColors.primaryBlueText : Colors.black87,
      ),
    );
  }
}

class _WaybillPanel extends StatelessWidget {
  final String waybillNo;
  final List<TripWaybillFile> files;
  final bool canEdit;
  final VoidCallback? onUpload;
  final ValueChanged<TripWaybillFile>? onDelete;

  const _WaybillPanel({
    required this.waybillNo,
    required this.files,
    required this.canEdit,
    required this.onUpload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasAny = waybillNo.trim().isNotEmpty || files.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasAny ? Colors.black12 : AppColors.warningYellow,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Waybill',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (canEdit)
                FilledButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Attach'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (waybillNo.trim().isNotEmpty)
            Text(
              'Waybill No: $waybillNo',
              style: const TextStyle(fontWeight: FontWeight.w600),
            )
          else
            const Text(
              'Waybill No: -',
              style: TextStyle(color: Colors.black54),
            ),
          const SizedBox(height: 8),
          if (!hasAny)
            const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warningYellow,
                  size: 18,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'No waybill attached yet. You can still complete trip, but this is flagged in list.',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          if (files.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...files.map(
              (file) => _WaybillFileTile(
                file: file,
                canEdit: canEdit,
                onDelete: onDelete,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WaybillFileTile extends StatelessWidget {
  final TripWaybillFile file;
  final bool canEdit;
  final ValueChanged<TripWaybillFile>? onDelete;

  const _WaybillFileTile({
    required this.file,
    required this.canEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.insert_drive_file_outlined),
      title: Text(file.fileName),
      subtitle: Text('${(file.fileSize / 1024).toStringAsFixed(1)} KB'),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () async {
              if (file.fileUrl.isEmpty) return;
              final uri = Uri.tryParse(file.fileUrl);
              if (uri == null) return;
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: onDelete == null ? null : () => onDelete!(file),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Panel({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;

  const _StatusPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryBlueLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryBlueText,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String text;

  const _MetaPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
