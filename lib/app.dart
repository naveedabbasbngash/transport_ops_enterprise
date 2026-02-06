import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/material3_theme.dart';
import 'routing/app_router.dart';

/// WHY THIS EXISTS
/// ----------------
/// This is the SINGLE root widget of the application.
/// - Receives AppConfig from bootstrap
/// - Wires theme, routing, localization
/// - Does NOT initialize services
///
/// bootstrap.dart owns setup
/// TransportOpsApp owns UI composition
///
class TransportOpsApp extends ConsumerWidget {
  final AppConfig config;

  const TransportOpsApp({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TransportOps',

      theme: Material3Theme.light(),
      initialRoute: AppRoutes.dashboard,

      onGenerateRoute: (settings) =>
          AppRouter.onGenerateRoute(settings, ref),

      // Future-proofing
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // enterprise consistency
          ),
          child: child!,
        );
      },
    );
  }
}
