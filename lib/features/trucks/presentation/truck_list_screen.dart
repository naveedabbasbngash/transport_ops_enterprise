import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/presentation/auth_view_model.dart';
import 'truck_state.dart';
import 'truck_view_model.dart';

class TruckListScreen extends ConsumerWidget {
  const TruckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(truckViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final isReadOnly = authState.user?.isOwnerReadOnly ?? true;

    final activeCount = state.trucks.where((t) => t.status == 'active').length;
    final vendorOwnedCount = state.trucks
        .where((t) => t.ownership == 'vendor')
        .length;
    final companyOwnedCount = state.trucks
        .where((t) => t.ownership == 'company')
        .length;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      floatingActionButton: isReadOnly
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              onPressed: () => _openCreateTruck(context, ref),
              label: const Text('Add Truck'),
              icon: const Icon(Icons.add_rounded),
            ),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: 'Trucks',
              isLoading: state.isLoading,
              onRefresh: () =>
                  ref.read(truckViewModelProvider.notifier).loadTrucks(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.page,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Hero(
                          title: 'Fleet Directory',
                          subtitle: isReadOnly
                              ? 'Read only access'
                              : 'Edit enabled',
                          tag: '${state.trucks.length} total trucks',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Filters(
                          search: state.search,
                          status: state.status,
                          onSearchChanged: (value) => ref
                              .read(truckViewModelProvider.notifier)
                              .updateSearch(value),
                          onStatusChanged: (value) => ref
                              .read(truckViewModelProvider.notifier)
                              .updateStatus(value),
                          onApply: () => ref
                              .read(truckViewModelProvider.notifier)
                              .applyFilters(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 760;
                            if (wide) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: _MetricCard(
                                      label: 'Active',
                                      value: '$activeCount',
                                      color: AppColors.successGreen,
                                      icon: Icons.check_circle_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MetricCard(
                                      label: 'Company Owned',
                                      value: '$companyOwnedCount',
                                      color: AppColors.primaryBlue,
                                      icon: Icons.apartment_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MetricCard(
                                      label: 'Vendor Owned',
                                      value: '$vendorOwnedCount',
                                      color: AppColors.accentOrange,
                                      icon: Icons.storefront_rounded,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _MetricCard(
                                  label: 'Active',
                                  value: '$activeCount',
                                  color: AppColors.successGreen,
                                  icon: Icons.check_circle_rounded,
                                ),
                                const SizedBox(height: 10),
                                _MetricCard(
                                  label: 'Company Owned',
                                  value: '$companyOwnedCount',
                                  color: AppColors.primaryBlue,
                                  icon: Icons.apartment_rounded,
                                ),
                                const SizedBox(height: 10),
                                _MetricCard(
                                  label: 'Vendor Owned',
                                  value: '$vendorOwnedCount',
                                  color: AppColors.accentOrange,
                                  icon: Icons.storefront_rounded,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (state.error != null)
                          _ErrorBanner(message: state.error!),
                        if (state.isLoading) ...[
                          const SizedBox(height: 10),
                          const LinearProgressIndicator(minHeight: 2),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        _ListPanel(state: state),
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

  Future<void> _openCreateTruck(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateTruckSheet(
        onSubmit: (payload) async {
          await ref
              .read(truckViewModelProvider.notifier)
              .createTruck(
                plateNo: payload.plateNo,
                truckType: payload.truckType,
                color: payload.color,
                model: payload.model,
                makeYear: payload.makeYear,
                registrationNumber: payload.registrationNumber,
                registrationCardBytes: payload.registrationCardBytes,
                registrationCardFileName: payload.registrationCardFileName,
                ownership: payload.ownership,
                vendorId: payload.vendorId,
                ownerName: payload.ownerName,
                companyName: payload.companyName,
                notes: payload.notes,
              );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _TopBar({
    required this.title,
    required this.isLoading,
    required this.onRefresh,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: isLoading ? null : onRefresh,
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;

  const _Hero({required this.title, required this.subtitle, required this.tag});

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
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w700,
            ),
          ),
          _Pill(text: subtitle),
          _Pill(text: tag),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill({required this.text});

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
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.panel,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListPanel extends StatelessWidget {
  final TruckState state;

  const _ListPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.trucks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.trucks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text(
          'No trucks found.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Column(
      children: state.trucks.map((truck) {
        final ownership = truck.ownership == 'vendor' ? 'Vendor' : 'Company';
        final truckType = (truck.truckType?.isNotEmpty ?? false)
            ? truck.truckType!
            : 'Unknown type';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: AppSpacing.panel,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        truck.plateNo,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$truckType • $ownership',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(truck.ownerName?.isNotEmpty ?? false) ? truck.ownerName : '-'} • '
                        '${(truck.companyName?.isNotEmpty ?? false) ? truck.companyName : '-'}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusTag(status: truck.status),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String status;

  const _StatusTag({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status == 'active';
    final bg = active ? AppColors.successLight : AppColors.dangerLight;
    final fg = active ? AppColors.successDark : AppColors.dangerDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(10),
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

class _Filters extends StatelessWidget {
  final String search;
  final String status;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onApply;

  const _Filters({
    required this.search,
    required this.status,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.panel,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 420,
            child: TextField(
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                labelText: 'Search plate',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (value) {
                if (value == null) return;
                onStatusChanged(value);
              },
            ),
          ),
          FilledButton(
            onPressed: onApply,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _CreateTruckPayload {
  final String plateNo;
  final String? truckType;
  final String? color;
  final String? model;
  final String? makeYear;
  final String? registrationNumber;
  final List<int>? registrationCardBytes;
  final String? registrationCardFileName;
  final String? ownership;
  final String? vendorId;
  final String? ownerName;
  final String? companyName;
  final String? notes;

  const _CreateTruckPayload({
    required this.plateNo,
    this.truckType,
    this.color,
    this.model,
    this.makeYear,
    this.registrationNumber,
    this.registrationCardBytes,
    this.registrationCardFileName,
    this.ownership,
    this.vendorId,
    this.ownerName,
    this.companyName,
    this.notes,
  });
}

class _CreateTruckSheet extends StatefulWidget {
  final Future<void> Function(_CreateTruckPayload payload) onSubmit;

  const _CreateTruckSheet({required this.onSubmit});

  @override
  State<_CreateTruckSheet> createState() => _CreateTruckSheetState();
}

class _CreateTruckSheetState extends State<_CreateTruckSheet> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _typeController = TextEditingController();
  final _colorController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _regController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();
  String? _registrationCardFileName;
  List<int>? _registrationCardBytes;
  String _ownership = 'company';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _plateController.dispose();
    _typeController.dispose();
    _colorController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _regController.dispose();
    _ownerNameController.dispose();
    _companyNameController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New Truck', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(labelText: 'Plate number'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Truck type'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _ownership,
                decoration: const InputDecoration(labelText: 'Ownership'),
                items: const [
                  DropdownMenuItem(value: 'company', child: Text('Company')),
                  DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _ownership = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vendorController,
                decoration: const InputDecoration(
                  labelText: 'Vendor ID (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(labelText: 'Owner name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(labelText: 'Company name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Make year'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _regController,
                decoration: const InputDecoration(
                  labelText: 'Registration number',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickRegistrationCard,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(
                  _registrationCardFileName == null
                      ? 'Attach Istimara (PDF/Image)'
                      : 'Istimara: $_registrationCardFileName',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _isSubmitting = true);
                        await widget.onSubmit(
                          _CreateTruckPayload(
                            plateNo: _plateController.text.trim(),
                            truckType: _typeController.text.trim(),
                            color: _colorController.text.trim(),
                            model: _modelController.text.trim(),
                            makeYear: _yearController.text.trim(),
                            registrationNumber: _regController.text.trim(),
                            registrationCardBytes: _registrationCardBytes,
                            registrationCardFileName: _registrationCardFileName,
                            ownership: _ownership,
                            vendorId: _vendorController.text.trim(),
                            ownerName: _ownerNameController.text.trim(),
                            companyName: _companyNameController.text.trim(),
                            notes: _notesController.text.trim(),
                          ),
                        );
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Truck'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickRegistrationCard() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) return;
    setState(() {
      _registrationCardBytes = file.bytes;
      _registrationCardFileName = file.name;
    });
  }
}
