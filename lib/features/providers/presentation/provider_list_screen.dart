import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_view_model.dart';
import 'provider_state.dart';
import 'provider_view_model.dart';

class ProviderListScreen extends ConsumerWidget {
  const ProviderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final isReadOnly = authState.user?.isOwnerReadOnly ?? true;

    final activeCount = state.providers
        .where((p) => p.status == 'active')
        .length;
    final regularCount = state.providers
        .where((p) => p.type == 'regular_vendor')
        .length;
    final spotCount = state.providers
        .where((p) => p.type == 'spot_market_vendor')
        .length;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      floatingActionButton: isReadOnly
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              onPressed: () => _openCreateProvider(context, ref),
              label: const Text('Add Provider'),
              icon: const Icon(Icons.add_rounded),
            ),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: 'Providers',
              isLoading: state.isLoading,
              onRefresh: () =>
                  ref.read(providerViewModelProvider.notifier).loadProviders(),
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
                          title: 'Provider Directory',
                          subtitle: isReadOnly
                              ? 'Read only access'
                              : 'Edit enabled',
                          tag: '${state.providers.length} total providers',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Filters(
                          search: state.search,
                          status: state.status,
                          onSearchChanged: (value) => ref
                              .read(providerViewModelProvider.notifier)
                              .updateSearch(value),
                          onStatusChanged: (value) => ref
                              .read(providerViewModelProvider.notifier)
                              .updateStatus(value),
                          onApply: () => ref
                              .read(providerViewModelProvider.notifier)
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
                                      label: 'Regular',
                                      value: '$regularCount',
                                      color: AppColors.primaryBlue,
                                      icon: Icons.storefront_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MetricCard(
                                      label: 'Spot Market',
                                      value: '$spotCount',
                                      color: AppColors.accentOrange,
                                      icon: Icons.flash_on_rounded,
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
                                  label: 'Regular',
                                  value: '$regularCount',
                                  color: AppColors.primaryBlue,
                                  icon: Icons.storefront_rounded,
                                ),
                                const SizedBox(height: 10),
                                _MetricCard(
                                  label: 'Spot Market',
                                  value: '$spotCount',
                                  color: AppColors.accentOrange,
                                  icon: Icons.flash_on_rounded,
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

  Future<void> _openCreateProvider(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateProviderSheet(
        onSubmit: (payload) async {
          await ref
              .read(providerViewModelProvider.notifier)
              .createProvider(
                name: payload.name,
                type: payload.type,
                status: payload.status,
                phone: payload.phone,
                externalRef: payload.externalRef,
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
      padding: const EdgeInsets.all(16),
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
              fontSize: 20,
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
      padding: const EdgeInsets.all(12),
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
  final ProviderState state;

  const _ListPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.providers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.providers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text(
          'No providers found.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Column(
      children: state.providers.map((provider) {
        final providerType = provider.type == 'spot_market_vendor'
            ? 'Spot Market'
            : 'Regular Vendor';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
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
                    color: AppColors.accentOrange.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 18,
                    color: AppColors.accentOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$providerType${provider.phone?.isNotEmpty == true ? ' • ${provider.phone}' : ''}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusTag(status: provider.status),
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
      padding: const EdgeInsets.all(12),
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
                labelText: 'Search provider',
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

class _CreateProviderPayload {
  final String name;
  final String type;
  final String status;
  final String? phone;
  final String? externalRef;
  final String? notes;

  const _CreateProviderPayload({
    required this.name,
    required this.type,
    required this.status,
    this.phone,
    this.externalRef,
    this.notes,
  });
}

class _CreateProviderSheet extends StatefulWidget {
  final Future<void> Function(_CreateProviderPayload payload) onSubmit;

  const _CreateProviderSheet({required this.onSubmit});

  @override
  State<_CreateProviderSheet> createState() => _CreateProviderSheetState();
}

class _CreateProviderSheetState extends State<_CreateProviderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _externalRefController = TextEditingController();
  final _notesController = TextEditingController();
  String _status = 'active';
  String _type = 'regular_vendor';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _externalRefController.dispose();
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
              Text(
                'New Provider',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Provider name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                    value: 'regular_vendor',
                    child: Text('Regular Vendor'),
                  ),
                  DropdownMenuItem(
                    value: 'spot_market_vendor',
                    child: Text('Spot Market Vendor'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _type = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _status = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _externalRefController,
                decoration: const InputDecoration(
                  labelText: 'External Ref (optional)',
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
                          _CreateProviderPayload(
                            name: _nameController.text.trim(),
                            type: _type,
                            status: _status,
                            phone: _phoneController.text.trim(),
                            externalRef: _externalRefController.text.trim(),
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
                    : const Text('Save Provider'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
