import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/presentation/auth_view_model.dart';
import 'driver_state.dart';
import 'driver_view_model.dart';

class DriverListScreen extends ConsumerWidget {
  const DriverListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final isReadOnly = authState.user?.isOwnerReadOnly ?? true;

    final activeCount = state.drivers.where((d) => d.status == 'active').length;
    final blockedCount = state.drivers
        .where((d) => d.status == 'blocked')
        .length;
    final vendorTypeCount = state.drivers
        .where((d) => d.driverType == 'vendor')
        .length;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      floatingActionButton: isReadOnly
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              onPressed: () => _openCreateDriver(context, ref),
              label: const Text('Add Driver'),
              icon: const Icon(Icons.add_rounded),
            ),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: 'Drivers',
              isLoading: state.isLoading,
              onRefresh: () =>
                  ref.read(driverViewModelProvider.notifier).loadDrivers(),
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
                          title: 'Driver Directory',
                          subtitle: isReadOnly
                              ? 'Read only access'
                              : 'Edit enabled',
                          tag: '${state.drivers.length} total drivers',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Filters(
                          search: state.search,
                          status: state.status,
                          onSearchChanged: (value) => ref
                              .read(driverViewModelProvider.notifier)
                              .updateSearch(value),
                          onStatusChanged: (value) => ref
                              .read(driverViewModelProvider.notifier)
                              .updateStatus(value),
                          onApply: () => ref
                              .read(driverViewModelProvider.notifier)
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
                                      label: 'Blocked',
                                      value: '$blockedCount',
                                      color: AppColors.dangerRed,
                                      icon: Icons.block_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MetricCard(
                                      label: 'Vendor Type',
                                      value: '$vendorTypeCount',
                                      color: AppColors.primaryBlue,
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
                                  label: 'Blocked',
                                  value: '$blockedCount',
                                  color: AppColors.dangerRed,
                                  icon: Icons.block_rounded,
                                ),
                                const SizedBox(height: 10),
                                _MetricCard(
                                  label: 'Vendor Type',
                                  value: '$vendorTypeCount',
                                  color: AppColors.primaryBlue,
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

  Future<void> _openCreateDriver(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateDriverSheet(
        onSubmit: (payload) async {
          await ref
              .read(driverViewModelProvider.notifier)
              .createDriver(
                name: payload.name,
                phone: payload.phone,
                residentId: payload.residentId,
                iqamaBytes: payload.iqamaBytes,
                iqamaFileName: payload.iqamaFileName,
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
  final DriverState state;

  const _ListPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.drivers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.drivers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text(
          'No drivers found.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Column(
      children: state.drivers.map((driver) {
        final phone = driver.phone?.isNotEmpty == true
            ? driver.phone!
            : 'No phone';
        final typeLabel = driver.driverType == 'vendor' ? 'Vendor' : 'Company';
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
                    Icons.badge_rounded,
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
                        driver.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$phone • $typeLabel',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusTag(status: driver.status),
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
    late Color bg;
    late Color fg;
    switch (status) {
      case 'active':
        bg = AppColors.successLight;
        fg = AppColors.successDark;
        break;
      case 'blocked':
        bg = AppColors.dangerLight;
        fg = AppColors.dangerDark;
        break;
      default:
        bg = AppColors.primaryBlueLight;
        fg = AppColors.primaryBlueText;
    }

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
                labelText: 'Search driver',
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
                DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
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

class _CreateDriverPayload {
  final String name;
  final String phone;
  final String residentId;
  final List<int> iqamaBytes;
  final String iqamaFileName;

  const _CreateDriverPayload({
    required this.name,
    required this.phone,
    required this.residentId,
    required this.iqamaBytes,
    required this.iqamaFileName,
  });
}

class _CreateDriverSheet extends StatefulWidget {
  final Future<void> Function(_CreateDriverPayload payload) onSubmit;

  const _CreateDriverSheet({required this.onSubmit});

  @override
  State<_CreateDriverSheet> createState() => _CreateDriverSheetState();
}

class _CreateDriverSheetState extends State<_CreateDriverSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _residentIdController = TextEditingController();
  String? _iqamaFileName;
  List<int>? _iqamaBytes;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _residentIdController.dispose();
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
              Text('New Driver', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Driver name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Mobile no'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _residentIdController,
                decoration: const InputDecoration(labelText: 'Iqama no'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickIqamaFile,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(
                  _iqamaFileName == null
                      ? 'Attach Iqama (PDF/Image)'
                      : 'Iqama: $_iqamaFileName',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (_iqamaBytes == null ||
                            _iqamaBytes!.isEmpty ||
                            _iqamaFileName == null ||
                            _iqamaFileName!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Iqama file is required.'),
                            ),
                          );
                          return;
                        }
                        setState(() => _isSubmitting = true);
                        await widget.onSubmit(
                          _CreateDriverPayload(
                            name: _nameController.text.trim(),
                            phone: _phoneController.text.trim(),
                            residentId: _residentIdController.text.trim(),
                            iqamaBytes: _iqamaBytes!,
                            iqamaFileName: _iqamaFileName!,
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
                    : const Text('Save Driver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickIqamaFile() async {
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
      _iqamaBytes = file.bytes;
      _iqamaFileName = file.name;
    });
  }
}
