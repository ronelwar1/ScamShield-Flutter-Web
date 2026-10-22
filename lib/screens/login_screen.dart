import 'package:flutter/material.dart';

import '../widgets/app_button.dart';

class ReportFormHomeButton extends StatelessWidget {
  const ReportFormHomeButton({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Report Form',
      icon: Icons.assignment_outlined,
      compact: compact,
      expand: false,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF6F1628),
      onPressed: () {
        Navigator.of(context).pushNamed('/report');
      },
    );
  }
}
