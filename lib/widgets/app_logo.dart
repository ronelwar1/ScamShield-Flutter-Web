import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// App mark + name. [light] is for use on dark gradient backgrounds.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF818CF8), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: light ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ],
      );
}
