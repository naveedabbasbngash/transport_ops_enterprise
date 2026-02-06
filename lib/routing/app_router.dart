import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_routes.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/owner_dashboard_screen.dart';
import '../features/auth/presentation/auth_view_model.dart';
import '../features/imports/presentation/import_upload_screen.dart';
import '../features/notifications/presentation/daily_summary_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/trips/presentation/trips_list_screen.dart';
import '../features/drivers/presentation/driver_list_screen.dart';
import '../features/trucks/presentation/truck_list_screen.dart';
import '../features/expenses/presentation/expense_form_screen.dart';
import '../features/expenses/presentation/expense_list_screen.dart';
import '../features/expenses/presentation/expense_detail_screen.dart';
import '../features/expenses/domain/entities/expense_entity.dart';
import 'route_guards.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(
      RouteSettings settings,
      WidgetRef ref,
      ) {
    final authState = ref.read(authViewModelProvider);
    if (authState.isBootstrapping) {
      return _route(const _StartupGateScreen(), '/startup');
    }

    final routeName = settings.name ?? AppRoutes.dashboard;
    final isAuthenticated = RouteGuards.isAuthenticated(authState);

    if (!isAuthenticated && routeName != AppRoutes.login) {
      return _route(const LoginScreen(), AppRoutes.login);
    }

    if (isAuthenticated && routeName == AppRoutes.login) {
      return _route(const OwnerDashboardScreen(), AppRoutes.dashboard);
    }

    switch (routeName) {
      case AppRoutes.login:
        return _route(const LoginScreen(), AppRoutes.login);
      case AppRoutes.dashboard:
        return _route(const OwnerDashboardScreen(), AppRoutes.dashboard);
      case AppRoutes.trips:
        return _route(const TripsListScreen(), AppRoutes.trips);
      case AppRoutes.imports:
        return _route(const ImportUploadScreen(), AppRoutes.imports);
      case AppRoutes.reports:
        return _route(const ReportsScreen(), AppRoutes.reports);
      case AppRoutes.dailySummary:
        return _route(const DailySummaryScreen(), AppRoutes.dailySummary);
      case AppRoutes.drivers:
        return _route(const DriverListScreen(), AppRoutes.drivers);
      case AppRoutes.trucks:
        return _route(const TruckListScreen(), AppRoutes.trucks);
      case AppRoutes.expenses:
        return _route(const ExpenseListScreen(), AppRoutes.expenses);
      case AppRoutes.expenseCreate:
        return _route(const ExpenseFormScreen(), AppRoutes.expenseCreate);
      case AppRoutes.expenseDetail:
        final expense = settings.arguments;
        if (expense is ExpenseEntity) {
          return _route(
            ExpenseDetailScreen(expense: expense),
            AppRoutes.expenseDetail,
          );
        }
        return _route(const ExpenseListScreen(), AppRoutes.expenses);
      case AppRoutes.expenseEdit:
        final expense = settings.arguments;
        if (expense is ExpenseEntity) {
          return _route(
            ExpenseFormScreen(expense: expense),
            AppRoutes.expenseEdit,
          );
        }
        return _route(const ExpenseListScreen(), AppRoutes.expenses);
      default:
        return _route(const OwnerDashboardScreen(), AppRoutes.dashboard);
    }
  }

  static MaterialPageRoute<dynamic> _route(Widget page, String name) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: RouteSettings(name: name),
    );
  }
}

class _StartupGateScreen extends ConsumerWidget {
  const _StartupGateScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    if (authState.isBootstrapping) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (RouteGuards.isAuthenticated(authState)) {
      return const OwnerDashboardScreen();
    }

    return const LoginScreen();
  }
}
