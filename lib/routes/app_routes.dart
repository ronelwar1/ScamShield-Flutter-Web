import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/register_screen.dart';

/// Route names and route generation.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _page(const HomeScreen(), settings);
      case login:
        return _page(const LoginScreen(), settings);
      case register:
        return _page(const RegisterScreen(), settings);
      default:
        return _page(const NotFoundScreen(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget page, RouteSettings s) =>
      MaterialPageRoute<dynamic>(builder: (_) => page, settings: s);
}
