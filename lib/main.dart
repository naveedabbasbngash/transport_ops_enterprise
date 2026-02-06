// main.dart

import 'package:flutter/material.dart';
import 'bootstrap.dart';
import 'core/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 Choose config here (can be switched via --dart-define later)
  const config = AppConfig.development;

  bootstrap(config);
}