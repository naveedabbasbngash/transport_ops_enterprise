import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_routes.dart';
import '../../auth/presentation/auth_view_model.dart';

enum _HomeLanguage { english, arabic }

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  _HomeLanguage _language = _HomeLanguage.english;

  bool get _isArabic => _language == _HomeLanguage.arabic;

  @override
  Widget build(BuildContext context) {
    final t = _DashboardText(_language);
    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.ownerDashboard),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _language = _isArabic
                      ? _HomeLanguage.english
                      : _HomeLanguage.arabic;
                });
              },
              child: Text(
                _isArabic ? 'EN' : 'AR',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: t.logout,
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
            Text(
              t.dashboardReadOnly,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _NavCard(
              title: t.trips,
              subtitle: t.tripsSubtitle,
              isArabic: _isArabic,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.trips),
            ),
            _NavCard(
              title: t.imports,
              subtitle: t.importsSubtitle,
              isArabic: _isArabic,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.imports),
            ),
            _NavCard(
              title: t.reports,
              subtitle: t.reportsSubtitle,
              isArabic: _isArabic,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.reports),
            ),
            _NavCard(
              title: t.drivers,
              subtitle: t.driversSubtitle,
              isArabic: _isArabic,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.drivers),
            ),
            _NavCard(
              title: t.trucks,
              subtitle: t.trucksSubtitle,
              isArabic: _isArabic,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.trucks),
            ),
            _NavCard(
              title: t.expenses,
              subtitle: t.expensesSubtitle,
              isArabic: _isArabic,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.expenses),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isArabic;
  final VoidCallback onTap;

  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(
          isArabic ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _DashboardText {
  final _HomeLanguage language;

  const _DashboardText(this.language);

  bool get _isArabic => language == _HomeLanguage.arabic;

  String get ownerDashboard =>
      _isArabic ? 'لوحة تحكم المالك' : 'Owner Dashboard';
  String get logout => _isArabic ? 'تسجيل الخروج' : 'Logout';
  String get dashboardReadOnly => _isArabic
      ? 'لوحة تحكم المالك (عرض فقط)'
      : 'Owner Dashboard (Read-Only)';
  String get trips => _isArabic ? 'الرحلات' : 'Trips';
  String get tripsSubtitle => _isArabic
      ? 'فتح قائمة الرحلات'
      : 'Open the trips list view';
  String get imports => _isArabic ? 'الاستيراد' : 'Imports';
  String get importsSubtitle => _isArabic
      ? 'فتح تدفق استيراد CSV/Excel'
      : 'Open CSV/Excel import flow';
  String get reports => _isArabic ? 'التقارير' : 'Reports';
  String get reportsSubtitle => _isArabic
      ? 'ملخص يومي وشهري مع المشاركة عبر واتساب'
      : 'Daily + monthly summary with WhatsApp share';
  String get drivers => _isArabic ? 'السائقون' : 'Drivers';
  String get driversSubtitle => _isArabic
      ? 'إدارة ملفات السائقين والحالات'
      : 'Manage driver profiles and statuses';
  String get trucks => _isArabic ? 'الشاحنات' : 'Trucks';
  String get trucksSubtitle =>
      _isArabic ? 'إدارة أسطول الشاحنات' : 'Manage fleet inventory';
  String get expenses => _isArabic ? 'المصروفات' : 'Expenses';
  String get expensesSubtitle => _isArabic
      ? 'تسجيل الوقود والصيانة والإصلاحات'
      : 'Log fuel, maintenance, and repairs';
}
