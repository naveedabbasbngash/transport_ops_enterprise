import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../domain/entities/dashboard_period.dart';
import '../domain/entities/dashboard_summary.dart';
import 'dashboard_view_model.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  static final Uri _designReferenceUri = Uri.parse(
    'https://assets.justinmind.com/wp-content/uploads/2020/02/dashboard-design-example-fireart-studio.png',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final isReadOnly = user?.isOwnerReadOnly ?? true;
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final summary = dashboardState.summary ?? DashboardSummary.empty();
    final period = dashboardState.period;

    final modules = <_ModuleItem>[
      const _ModuleItem(
        title: 'Trips',
        subtitle: 'Create and manage trip lifecycle',
        route: AppRoutes.trips,
        icon: Icons.alt_route_rounded,
        accent: AppColors.accentOrange,
      ),
      const _ModuleItem(
        title: 'Orders',
        subtitle: 'Group trips under customer orders',
        route: AppRoutes.orders,
        icon: Icons.inventory_2_rounded,
        accent: AppColors.primaryBlue,
      ),
      const _ModuleItem(
        title: 'Clients',
        subtitle: 'Customer accounts and status',
        route: AppRoutes.clients,
        icon: Icons.groups_rounded,
        accent: AppColors.successBright,
      ),
      const _ModuleItem(
        title: 'Providers',
        subtitle: 'Vendors used in trip assignment',
        route: AppRoutes.providers,
        icon: Icons.storefront_rounded,
        accent: AppColors.warningYellow,
      ),
      const _ModuleItem(
        title: 'Drivers',
        subtitle: 'Driver profiles and availability',
        route: AppRoutes.drivers,
        icon: Icons.badge_rounded,
        accent: AppColors.infoBlue,
      ),
      const _ModuleItem(
        title: 'Trucks',
        subtitle: 'Fleet inventory and readiness',
        route: AppRoutes.trucks,
        icon: Icons.local_shipping_rounded,
        accent: AppColors.accentPurple,
      ),
      const _ModuleItem(
        title: 'Expenses',
        subtitle: 'Fuel, maintenance, and repair spend',
        route: AppRoutes.expenses,
        icon: Icons.receipt_long_rounded,
        accent: AppColors.dangerRed,
      ),
      const _ModuleItem(
        title: 'Reports',
        subtitle: 'Daily and monthly analytics',
        route: AppRoutes.reports,
        icon: Icons.query_stats_rounded,
        accent: AppColors.primaryBlue,
      ),
      const _ModuleItem(
        title: 'Imports',
        subtitle: 'Excel and CSV ingestion',
        route: AppRoutes.imports,
        icon: Icons.upload_file_rounded,
        accent: AppColors.successDark,
      ),
    ];

    final highlights = <_HighlightItem>[
      _HighlightItem(
        title: 'Total Trips',
        value: '${summary.totalTrips}',
        trend: 'Updated ${_formatTime(summary.refreshedAt)}',
        color: AppColors.accentOrange,
      ),
      _HighlightItem(
        title: 'Active Drivers',
        value: '${summary.activeDrivers}/${summary.totalDrivers}',
        trend: '${summary.totalDrivers} total drivers',
        color: AppColors.successBright,
      ),
      _HighlightItem(
        title: 'Active Trucks',
        value: '${summary.activeTrucks}/${summary.totalTrucks}',
        trend: '${summary.totalExpenses} expenses logged',
        color: AppColors.primaryBlue,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1180;
            final isTablet = constraints.maxWidth >= 760;

            if (isDesktop) {
              return Row(
                children: [
                  SizedBox(
                    width: 248,
                    child: _SideRail(
                      userName: user?.name ?? 'User',
                      isReadOnly: isReadOnly,
                      modules: modules,
                      onOpenModule: (route) =>
                          Navigator.of(context).pushNamed(route),
                      onOpenReference: () => _openReference(context),
                      onRefresh: () => ref
                          .read(dashboardViewModelProvider.notifier)
                          .loadSummary(),
                      onLogout: () => _logout(context, ref),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: AppSpacing.page,
                      child: Row(
                        children: [
                          Expanded(
                            child: _MainBoard(
                              isReadOnly: isReadOnly,
                              roleLabel: (user?.role ?? 'unknown').replaceAll(
                                '_',
                                ' ',
                              ),
                              modules: modules,
                              highlights: highlights,
                              period: period,
                              recentTrips: summary.recentTrips,
                              loadError: dashboardState.error,
                              isRefreshing: dashboardState.isLoading,
                              onSelectPeriod: (value) => ref
                                  .read(dashboardViewModelProvider.notifier)
                                  .setPeriod(value),
                              onOpenModule: (route) =>
                                  Navigator.of(context).pushNamed(route),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 280,
                            child: _InsightPanel(
                              modules: modules,
                              summary: summary,
                              onOpenModule: (route) =>
                                  Navigator.of(context).pushNamed(route),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return _MobileBoard(
              userName: user?.name ?? 'User',
              roleLabel: (user?.role ?? 'unknown').replaceAll('_', ' '),
              isReadOnly: isReadOnly,
              modules: modules,
              highlights: highlights,
              period: period,
              recentTrips: summary.recentTrips,
              loadError: dashboardState.error,
              isRefreshing: dashboardState.isLoading,
              isTablet: isTablet,
              onSelectPeriod: (value) => ref
                  .read(dashboardViewModelProvider.notifier)
                  .setPeriod(value),
              onOpenModule: (route) => Navigator.of(context).pushNamed(route),
              onOpenReference: () => _openReference(context),
              onRefresh: () =>
                  ref.read(dashboardViewModelProvider.notifier).loadSummary(),
              onLogout: () => _logout(context, ref),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openReference(BuildContext context) async {
    final opened = await launchUrl(
      _designReferenceUri,
      mode: LaunchMode.platformDefault,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open reference link')),
      );
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authViewModelProvider.notifier).logout();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ModuleItem {
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final Color accent;

  const _ModuleItem({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.accent,
  });
}

class _HighlightItem {
  final String title;
  final String value;
  final String trend;
  final Color color;

  const _HighlightItem({
    required this.title,
    required this.value,
    required this.trend,
    required this.color,
  });
}

class _SideRail extends StatelessWidget {
  final String userName;
  final bool isReadOnly;
  final List<_ModuleItem> modules;
  final ValueChanged<String> onOpenModule;
  final VoidCallback onOpenReference;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const _SideRail({
    required this.userName,
    required this.isReadOnly,
    required this.modules,
    required this.onOpenModule,
    required this.onOpenReference,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.railDark,
      padding: const EdgeInsets.fromLTRB(16, 18, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.space_dashboard_rounded,
                color: AppColors.accentOrange,
              ),
              SizedBox(width: 8),
              Text(
                'Transport Ops',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isReadOnly ? 'Owner view (read only)' : 'Admin access',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: modules.length,
              separatorBuilder: (_, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = modules[index];
                return _RailItem(
                  item: item,
                  onTap: () => onOpenModule(item.route),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _RailActionButton(
            icon: Icons.open_in_new_rounded,
            text: 'Reference',
            onTap: onOpenReference,
          ),
          const SizedBox(height: 8),
          _RailActionButton(
            icon: Icons.refresh_rounded,
            text: 'Refresh',
            onTap: onRefresh,
          ),
          const SizedBox(height: 8),
          _RailActionButton(
            icon: Icons.logout_rounded,
            text: 'Logout',
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final _ModuleItem item;
  final VoidCallback onTap;

  const _RailItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: item.accent.withValues(alpha: 0.2),
                  ),
                  child: Icon(item.icon, size: 16, color: item.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _RailActionButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _MainBoard extends StatelessWidget {
  final bool isReadOnly;
  final String roleLabel;
  final List<_ModuleItem> modules;
  final List<_HighlightItem> highlights;
  final DashboardPeriod period;
  final List<DashboardRecentTrip> recentTrips;
  final String? loadError;
  final bool isRefreshing;
  final ValueChanged<DashboardPeriod> onSelectPeriod;
  final ValueChanged<String> onOpenModule;

  const _MainBoard({
    required this.isReadOnly,
    required this.roleLabel,
    required this.modules,
    required this.highlights,
    required this.period,
    required this.recentTrips,
    required this.loadError,
    required this.isRefreshing,
    required this.onSelectPeriod,
    required this.onOpenModule,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroBlock(roleLabel: roleLabel, isReadOnly: isReadOnly),
          const SizedBox(height: 10),
          _PeriodSelector(value: period, onChanged: onSelectPeriod),
          if (isRefreshing) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (loadError != null) ...[
            const SizedBox(height: 10),
            _ErrorBanner(message: loadError!),
          ],
          const SizedBox(height: 14),
          Row(
            children: highlights
                .map(
                  (h) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _HighlightCard(item: h),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          _RecentTripsPanel(recentTrips: recentTrips),
          const SizedBox(height: 16),
          _SectionTitle(
            title: 'Operations Modules',
            subtitle: 'Quick access to all operational workflows',
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modules.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.32,
            ),
            itemBuilder: (context, index) {
              final item = modules[index];
              return _ModuleCard(
                item: item,
                onTap: () => onOpenModule(item.route),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MobileBoard extends StatelessWidget {
  final String userName;
  final String roleLabel;
  final bool isReadOnly;
  final List<_ModuleItem> modules;
  final List<_HighlightItem> highlights;
  final DashboardPeriod period;
  final List<DashboardRecentTrip> recentTrips;
  final String? loadError;
  final bool isRefreshing;
  final bool isTablet;
  final ValueChanged<DashboardPeriod> onSelectPeriod;
  final ValueChanged<String> onOpenModule;
  final VoidCallback onOpenReference;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const _MobileBoard({
    required this.userName,
    required this.roleLabel,
    required this.isReadOnly,
    required this.modules,
    required this.highlights,
    required this.period,
    required this.recentTrips,
    required this.loadError,
    required this.isRefreshing,
    required this.isTablet,
    required this.onSelectPeriod,
    required this.onOpenModule,
    required this.onOpenReference,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final columns = isTablet ? 2 : 1;

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
          child: Row(
            children: [
              const Icon(Icons.space_dashboard_rounded),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transport Ops Dashboard',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded),
                tooltip: 'Reference',
                onPressed: onOpenReference,
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: onRefresh,
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Logout',
                onPressed: onLogout,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              _HeroBlock(roleLabel: roleLabel, isReadOnly: isReadOnly),
              const SizedBox(height: 10),
              _PeriodSelector(value: period, onChanged: onSelectPeriod),
              if (isRefreshing) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (loadError != null) ...[
                const SizedBox(height: 10),
                _ErrorBanner(message: loadError!),
              ],
              const SizedBox(height: 12),
              ...highlights.map(
                (h) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HighlightCard(item: h),
                ),
              ),
              const SizedBox(height: 6),
              _RecentTripsPanel(recentTrips: recentTrips),
              const SizedBox(height: 10),
              _SectionTitle(
                title: 'Operations Modules',
                subtitle: 'Tap a module to continue',
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: modules.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: isTablet ? 1.5 : 2.5,
                ),
                itemBuilder: (context, index) {
                  final item = modules[index];
                  return _ModuleCard(
                    item: item,
                    onTap: () => onOpenModule(item.route),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroBlock extends StatelessWidget {
  final String roleLabel;
  final bool isReadOnly;

  const _HeroBlock({required this.roleLabel, required this.isReadOnly});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.page,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.heroDarkStart, AppColors.heroDarkEndAlt],
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
            'Operations Control Center',
            style: TextStyle(
              color: Colors.white,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w700,
            ),
          ),
          _Tag(
            text: roleLabel,
            background: Colors.white.withValues(alpha: 0.16),
            foreground: Colors.white,
          ),
          _Tag(
            text: isReadOnly ? 'Read only mode' : 'Edit enabled',
            background: isReadOnly
                ? AppColors.darkDangerChip
                : AppColors.darkSuccessChip,
            foreground: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Tag({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final _HighlightItem item;

  const _HighlightCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                item.title,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            item.trend,
            style: TextStyle(
              color: item.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _ModuleItem item;
  final VoidCallback onTap;

  const _ModuleCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.accent, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    item.subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Text(
                      'Open module',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final DashboardPeriod value;
  final ValueChanged<DashboardPeriod> onChanged;

  const _PeriodSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DashboardPeriod.values.map((item) {
        final selected = item == value;
        return ChoiceChip(
          selected: selected,
          label: Text(item.label),
          onSelected: (_) => onChanged(item),
          selectedColor: AppColors.primaryBlue.withValues(alpha: 0.18),
          side: BorderSide(
            color: selected ? AppColors.primaryBlue : Colors.black12,
          ),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primaryBlueText : Colors.black87,
          ),
        );
      }).toList(),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  final List<_ModuleItem> modules;
  final DashboardSummary summary;
  final ValueChanged<String> onOpenModule;

  const _InsightPanel({
    required this.modules,
    required this.summary,
    required this.onOpenModule,
  });

  @override
  Widget build(BuildContext context) {
    final spotlight = modules.take(4).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Priority Access',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'High frequency actions',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 10),
            ...spotlight.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onOpenModule(item.route),
                    child: Ink(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: item.accent.withValues(alpha: 0.1),
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon, size: 18, color: item.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.panelBlueBg,
                border: Border.all(color: AppColors.panelBlueBorder),
              ),
              child: Text(
                'Live totals: ${summary.totalTrips} trips, ${summary.totalClients} clients, ${summary.totalProviders} providers, ${summary.totalExpenses} expenses.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryBlueText,
                ),
              ),
            ),
          ],
        ),
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

class _RecentTripsPanel extends StatelessWidget {
  final List<DashboardRecentTrip> recentTrips;

  const _RecentTripsPanel({required this.recentTrips});

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
          const Text(
            'Recent Trips',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (recentTrips.isEmpty)
            const Text(
              'No trips found yet.',
              style: TextStyle(color: Colors.black54),
            )
          else
            ...recentTrips.map(
              (trip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.route,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      trip.status.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      trip.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
