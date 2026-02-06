// core/config/app_config.dart

import 'package:flutter/foundation.dart';

/// AppConfig holds immutable, app-wide configuration.
/// This exists so we never hardcode environment values
/// across UI or business logic.
@immutable
class AppConfig {
  final String appName;
  final String environment;
  final String timezone;
  final String defaultCurrency;
  final bool enableLogs;

  const AppConfig({
    required this.appName,
    required this.environment,
    required this.timezone,
    required this.defaultCurrency,
    required this.enableLogs,
  });

  /// Production configuration
  static const production = AppConfig(
    appName: 'TransportOps Enterprise',
    environment: 'production',
    timezone: 'Asia/Riyadh',
    defaultCurrency: 'SAR',
    enableLogs: false,
  );

  /// Staging configuration
  static const staging = AppConfig(
    appName: 'TransportOps (Staging)',
    environment: 'staging',
    timezone: 'Asia/Riyadh',
    defaultCurrency: 'SAR',
    enableLogs: true,
  );

  /// Development configuration
  static const development = AppConfig(
    appName: 'TransportOps (Dev)',
    environment: 'development',
    timezone: 'Asia/Riyadh',
    defaultCurrency: 'SAR',
    enableLogs: true,
  );
}