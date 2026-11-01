import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'services/scam_analysis_service.dart';
import 'theme/app_theme.dart';

class ScamShieldApp extends StatelessWidget {
  const ScamShieldApp({super.key, this.service});

  final ScamAnalysisService? service;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScamShield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AppShell(service: service),
    );
  }
}
