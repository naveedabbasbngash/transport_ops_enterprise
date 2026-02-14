import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../domain/entities/trip_entity.dart';
import 'trips_view_model.dart';

class TripsListScreen extends ConsumerStatefulWidget {
  const TripsListScreen({super.key});

  @override
  ConsumerState<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends ConsumerState<TripsListScreen> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripsViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final isReadOnly = authState.user?.isOwnerReadOnly ?? true;

    final filteredTrips = state.trips;
    final totalRevenue = filteredTrips.fold<double>(
      0,
      (sum, item) => sum + item.tripAmount,
    );
    final totalProfit = filteredTrips.fold<double>(
      0,
      (sum, item) => sum + item.profit,
    );

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      floatingActionButton: isReadOnly
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              onPressed: () async {
                final created = await Navigator.of(
                  context,
                ).pushNamed(AppRoutes.tripCreate);
                if (created == true && context.mounted) {
                  ref.read(tripsViewModelProvider.notifier).loadTrips();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Trip'),
            ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;

            return Column(
              children: [
                _TopBar(
                  isLoading: state.isLoading,
                  onRefresh: () =>
                      ref.read(tripsViewModelProvider.notifier).loadTrips(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSpacing.page,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1320),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TripsHero(
                              isReadOnly: isReadOnly,
                              totalTrips: filteredTrips.length,
                              query: state.query,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _SearchAndFilters(
                              controller: _searchController,
                              statusFilter: state.statusFilter,
                              missingWaybillOnly: state.missingWaybillOnly,
                              onStatusChanged: (value) {
                                ref
                                    .read(tripsViewModelProvider.notifier)
                                    .setStatusFilter(value);
                              },
                              onMissingWaybillChanged: (value) {
                                ref
                                    .read(tripsViewModelProvider.notifier)
                                    .setMissingWaybillOnly(value);
                              },
                              onSearchChanged: (value) {
                                _debounce?.cancel();
                                _debounce = Timer(
                                  const Duration(milliseconds: 350),
                                  () {
                                    if (!mounted) return;
                                    ref
                                        .read(tripsViewModelProvider.notifier)
                                        .onQueryChanged(value);
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (wide)
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'Trips',
                                      value: '${filteredTrips.length}',
                                      subtitle: 'Current list',
                                      color: AppColors.primaryBlue,
                                      icon: Icons.alt_route_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'Revenue',
                                      value: _currency(totalRevenue),
                                      subtitle: 'Expected',
                                      color: AppColors.successGreen,
                                      icon: Icons.payments_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MetricCard(
                                      title: 'Profit',
                                      value: _currency(totalProfit),
                                      subtitle: 'After costs',
                                      color: AppColors.accentOrange,
                                      icon: Icons.trending_up_rounded,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _MetricCard(
                                    title: 'Trips',
                                    value: '${filteredTrips.length}',
                                    subtitle: 'Current list',
                                    color: AppColors.primaryBlue,
                                    icon: Icons.alt_route_rounded,
                                  ),
                                  const SizedBox(height: 10),
                                  _MetricCard(
                                    title: 'Revenue',
                                    value: _currency(totalRevenue),
                                    subtitle: 'Expected',
                                    color: AppColors.successGreen,
                                    icon: Icons.payments_rounded,
                                  ),
                                  const SizedBox(height: 10),
                                  _MetricCard(
                                    title: 'Profit',
                                    value: _currency(totalProfit),
                                    subtitle: 'After costs',
                                    color: AppColors.accentOrange,
                                    icon: Icons.trending_up_rounded,
                                  ),
                                ],
                              ),
                            const SizedBox(height: AppSpacing.md),
                            if (state.error != null)
                              _ErrorBanner(message: state.error!),
                            if (state.isLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                            const SizedBox(height: AppSpacing.md),
                            _TripList(
                              trips: filteredTrips,
                              isReadOnly: isReadOnly,
                              onDelete: _deleteTrip,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _currency(double value) {
    return NumberFormat.currency(
      symbol: 'SAR ',
      decimalDigits: 0,
    ).format(value);
  }

  Future<void> _deleteTrip(String tripId) async {
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

    final success = await ref
        .read(tripsViewModelProvider.notifier)
        .deleteTrip(tripId);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Trip deleted.')));
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
  final bool isLoading;
  final VoidCallback onRefresh;

  const _TopBar({required this.isLoading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: AppSpacing.topBar,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          const Text(
            'Trips',
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: isLoading ? null : onRefresh,
          ),
        ],
      ),
    );
  }
}

class _TripsHero extends StatelessWidget {
  final bool isReadOnly;
  final int totalTrips;
  final String query;

  const _TripsHero({
    required this.isReadOnly,
    required this.totalTrips,
    required this.query,
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
          const Text(
            'Trip Operations Board',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          _Badge(
            text: '$totalTrips items',
            bg: const Color(0x33FFFFFF),
            fg: Colors.white,
          ),
          _Badge(
            text: isReadOnly ? 'Read only' : 'Edit enabled',
            bg: isReadOnly
                ? AppColors.darkDangerChip
                : AppColors.darkSuccessChip,
            fg: Colors.white,
          ),
          if (query.isNotEmpty)
            _Badge(
              text: 'Query: $query',
              bg: AppColors.darkChip,
              fg: Colors.white,
            ),
        ],
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  final TextEditingController controller;
  final String statusFilter;
  final bool missingWaybillOnly;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<bool> onMissingWaybillChanged;

  const _SearchAndFilters({
    required this.controller,
    required this.statusFilter,
    required this.missingWaybillOnly,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onMissingWaybillChanged,
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
              controller: controller,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search route, client, plate, waybill...',
              ),
            ),
          ),
          _FilterChip(
            label: 'All',
            selected: statusFilter == 'all',
            onTap: () => onStatusChanged('all'),
          ),
          _FilterChip(
            label: 'Open',
            selected: statusFilter == 'open',
            onTap: () => onStatusChanged('open'),
          ),
          _FilterChip(
            label: 'In Progress',
            selected: statusFilter == 'in_progress',
            onTap: () => onStatusChanged('in_progress'),
          ),
          _FilterChip(
            label: 'Completed',
            selected: statusFilter == 'completed',
            onTap: () => onStatusChanged('completed'),
          ),
          _FilterChip(
            label: 'Cancelled',
            selected: statusFilter == 'cancelled',
            onTap: () => onStatusChanged('cancelled'),
          ),
          FilterChip(
            label: const Text('Missing waybill only'),
            selected: missingWaybillOnly,
            onSelected: onMissingWaybillChanged,
            selectedColor: AppColors.warningYellow.withValues(alpha: 0.25),
            side: BorderSide(
              color: missingWaybillOnly
                  ? AppColors.warningYellow
                  : Colors.black12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryBlue.withValues(alpha: 0.16),
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TripList extends ConsumerWidget {
  final List<TripEntity> trips;
  final bool isReadOnly;
  final ValueChanged<String> onDelete;

  const _TripList({
    required this.trips,
    required this.isReadOnly,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (trips.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: const Column(
          children: [
            Icon(Icons.inbox_rounded, size: 34, color: Colors.black38),
            SizedBox(height: 10),
            Text(
              'No trips found for selected filters.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return Column(
      children: trips
          .map(
            (trip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TripCard(
                trip: trip,
                isReadOnly: isReadOnly,
                onDelete: () => onDelete(trip.id),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripEntity trip;
  final bool isReadOnly;
  final VoidCallback onDelete;

  const _TripCard({
    required this.trip,
    required this.isReadOnly,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final revenue = NumberFormat.currency(
      symbol: 'SAR ',
      decimalDigits: 0,
    ).format(trip.tripAmount);
    final profit = NumberFormat.currency(
      symbol: 'SAR ',
      decimalDigits: 0,
    ).format(trip.profit);
    final status = (trip.status ?? 'open').toLowerCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(
          context,
        ).pushNamed(AppRoutes.tripDetail, arguments: trip),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${trip.fromLocation} -> ${trip.toLocation}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusTag(status: status),
                  if (!isReadOnly)
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      tooltip: 'Edit trip',
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.tripEdit, arguments: trip);
                      },
                    ),
                  if (!isReadOnly)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      tooltip: 'Delete trip',
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    icon: Icons.business_rounded,
                    text: trip.clientName,
                  ),
                  _InfoPill(
                    icon: Icons.local_shipping_rounded,
                    text: trip.plateNo,
                  ),
                  _InfoPill(icon: Icons.person_rounded, text: trip.driverName),
                  _InfoPill(
                    icon: Icons.calendar_today_rounded,
                    text: trip.tripDate,
                  ),
                  if (!trip.hasWaybill)
                    const _InfoPill(
                      icon: Icons.warning_amber_rounded,
                      text: 'Waybill missing',
                      color: AppColors.warningYellow,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _AmountBlock(
                    label: 'Revenue',
                    value: revenue,
                    color: AppColors.successGreen,
                  ),
                  const SizedBox(width: 10),
                  _AmountBlock(
                    label: 'Profit',
                    value: profit,
                    color: trip.profit >= 0
                        ? AppColors.primaryBlue
                        : AppColors.dangerRed,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _InfoPill({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.black54),
          const SizedBox(width: 5),
          Text(
            text.isEmpty ? '-' : text,
            style: TextStyle(fontSize: 12, color: color ?? Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withValues(alpha: 0.09),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String status;

  const _StatusTag({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'completed':
      case 'closed':
        bg = AppColors.successLight;
        fg = AppColors.successDark;
        break;
      case 'in_progress':
        bg = const Color(0xFFFFF7E0);
        fg = const Color(0xFF8A5A00);
        break;
      case 'cancelled':
        bg = AppColors.dangerLight;
        fg = AppColors.dangerDark;
        break;
      default:
        bg = AppColors.primaryBlueLight;
        fg = AppColors.primaryBlueText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _Badge({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
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
