import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../widgets/app_button.dart';

/// Shown for unknown routes.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              const Text('We could not find that page.'),
              const SizedBox(height: 16),
              AppButton(
                label: 'Go to Home',
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.home, (_) => false),
              ),
            ],
          ),
        ),
      );
}
