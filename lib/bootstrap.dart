// bootstrap.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';

/// bootstrap is the only place allowed to:
/// - initialize global services
/// - wrap ProviderScope
/// - configure error handling
void bootstrap(AppConfig config) {
  runApp(
    ProviderScope(
      observers: config.enableLogs ? [_AppLogger()] : const [],
      child: TransportOpsApp(config: config),
    ),
  );
}



final class _AppLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
      ProviderObserverContext context,
      Object? previousValue,
      Object? newValue,
      ) {
    debugPrint(
      '[PROVIDER] ${context.provider.name ?? context.provider.runtimeType} '
          'prev=$previousValue next=$newValue',
    );
  }
}