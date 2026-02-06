import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_routes.dart';
import '../../auth/presentation/auth_view_model.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authViewModelProvider.notifier).logout();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Owner Dashboard (Read-Only)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _NavCard(
            title: 'Trips',
            subtitle: 'Open the trips list view',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.trips),
          ),
          _NavCard(
            title: 'Imports',
            subtitle: 'Open CSV/Excel import flow',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.imports),
          ),
          _NavCard(
            title: 'Reports',
            subtitle: 'Daily + monthly summary with WhatsApp share',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.reports),
          ),
          _NavCard(
            title: 'Drivers',
            subtitle: 'Manage driver profiles and statuses',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.drivers),
          ),
          _NavCard(
            title: 'Trucks',
            subtitle: 'Manage fleet inventory',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.trucks),
          ),
          _NavCard(
            title: 'Expenses',
            subtitle: 'Log fuel, maintenance, and repairs',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.expenses),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
